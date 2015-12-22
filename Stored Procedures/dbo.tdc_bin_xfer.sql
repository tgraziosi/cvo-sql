SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/********************************************************************************************/
/* This procedure transfers an item FROM bin to bin by creating two issues:		    */
/* one to remove it FROM the old bin, and one to insert it into the new bin.                */
/* The normal insert issue trigger takes care of populating the lot-bin tables.             */
/********************************************************************************************/
-- v1.1 CT 23/10/2013 - Issue #695 - split transaction around getting issue number and writing issue into two
CREATE PROC [dbo].[tdc_bin_xfer] AS

	DECLARE @issid int, @issue_no1 int, @issue_no2 int, @err int, @serial_flag int
	DECLARE @language varchar(10), @msg varchar(255), @part varchar(30), @who varchar(50) 
	DECLARE @from_bin varchar(12), @to_bin varchar(12), @loc varchar(10), @reason_code varchar(10)
	DECLARE @qty decimal(20,8), @lot_ser varchar(25), @date_expires datetime
 	DECLARE @cost decimal(20,8), @date_tran datetime

  	/* Initialize the error code to 'No errors' */
  	SELECT @err = 0

 	/* Find the first record */
  	SELECT @issid = 0
	SELECT @language = ISNULL((SELECT Language FROM tdc_sec (nolock) WHERE userid = (SELECT MIN(who_entered) FROM #adm_bin_xfer)), 'us_english')

  	/* Look at each record... */
  	WHILE (@issid >= 0)
    	BEGIN
      		SELECT @issid = isnull((SELECT min(row_id) FROM #adm_bin_xfer WHERE row_id > @issid and issue_no is null),-1)
      		IF @issid     = -1 BREAK

		SELECT @part = part_no, @loc = location, @from_bin = bin_from, @to_bin = bin_to, @qty = qty,
			@date_expires = date_expires, @lot_ser = lot_ser, @reason_code = reason_code, @who = who_entered
			FROM #adm_bin_xfer 
				WHERE row_id = @issid

		SELECT @who = login_id FROM #temp_who

      		/* Make sure part number exists */
      		SELECT @serial_flag = serial_flag FROM inv_master (nolock) WHERE part_no = @part AND lb_tracking = 'Y'

		IF (@@ROWCOUNT = 0)
        	BEGIN
          		-- UPDATE #adm_bin_xfer SET err_msg = 'Part number is not valid.' WHERE row_id = @issid
			SELECT @msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_bin_xfer' AND err_no = -101 AND language = @language
			RAISERROR (@msg, 16, 1)
          		RETURN -101
        	END

        	/* Make sure bin FROM and bin to are dIFferent */
        	IF (@to_bin = @from_bin)
          	BEGIN
            		-- UPDATE #adm_bin_xfer SET err_msg = 'To Bin and From Bin must be different.' WHERE row_id = @issid
			SELECT @msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_bin_xfer' AND err_no = -102 AND language = @language
			RAISERROR (@msg, 16, 1)            		
			RETURN -102
          	END

          	/* Make sure location exists */
          	IF not exists (SELECT * FROM locations (nolock) WHERE location = @loc and void = 'N')
            	BEGIN              		
              		-- UPDATE #adm_bin_xfer SET err_msg = 'Location is not valid.' WHERE row_id = @issid
			SELECT @msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_bin_xfer' AND err_no = -103 AND language = @language
			RAISERROR (@msg, 16, 1)
              		RETURN -103
            	END

            	/* Make sure quantity is positive */
            	IF (@qty <= 0.0)
              	BEGIN
                	-- UPDATE #adm_bin_xfer SET err_msg = 'Transfer quantity must be positive.' WHERE row_id = @issid
			SELECT @msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_bin_xfer' AND err_no = -104 AND language = @language
			RAISERROR (@msg, 16, 1)
                	RETURN -104
              	END

                /* Make sure item is at location */
                IF not exists (SELECT * FROM lot_bin_stock (nolock) WHERE part_no = @part AND location = @loc)
                BEGIN                    	
                    	-- UPDATE #adm_bin_xfer SET err_msg = 'The part does not exist at this location.' WHERE row_id = @issid
			SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_bin_xfer' AND err_no = -106 AND language = @language
			RAISERROR (@msg, 16, 1) 
                    	RETURN -106
                END

                /* Make sure enough of item is in bin */
                IF( SELECT isnull(qty, 0) FROM lot_bin_stock 
					 WHERE bin_no = @from_bin and lot_ser = @lot_ser and
                                 	 location = @loc and part_no = @part ) < @qty 
                BEGIN
                      	-- UPDATE #adm_bin_xfer SET err_msg = 'There is not enough of item in from bin.' WHERE row_id = @issid
			SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_bin_xfer' AND err_no = -107 AND language = @language
			RAISERROR (@msg, 16, 1) 
                      	RETURN -107
                END
 
		SELECT @cost = cost, @date_tran = date_tran 
		  FROM lot_bin_stock (nolock) 
		 WHERE location = @loc 
		   AND part_no = @part 
		   AND lot_ser = @lot_ser 
		   AND bin_no = @from_bin

 		/* Insert the record into issues */
                BEGIN TRAN

                /* Get the next issue number */
		UPDATE next_iss_no SET @issue_no1 = last_no = last_no + 1

                /* Get the next issue number */
		UPDATE next_iss_no SET @issue_no2 = last_no = last_no + 1

		-- START v1.1
		COMMIT TRAN
		BEGIN TRAN
		-- END v1.1


	-- The inserts into lot_serial_bin_issue were moved in front of the inserts in to issues to comply with the lot serial costin changes in eBO - KMH 01/10/2005
		INSERT INTO dbo.lot_serial_bin_issue  
			( line_no, tran_no,   part_no, location, bin_no,    tran_code, date_tran,  date_expires, qty,  direction, uom,  who,  cost,   lot_ser, tran_ext ) 
			SELECT 	1, @issue_no1, @part,   @loc,     @from_bin, 'I',     @date_tran, @date_expires, @qty, -1,    inv.uom, @who, @cost, @lot_ser, 0 
			  FROM inventory inv (nolock)
			 WHERE inv.location = @loc AND inv.part_no = @part

		INSERT INTO dbo.lot_serial_bin_issue  
			( line_no, tran_no,   part_no, location, bin_no, tran_code, date_tran,  date_expires, qty,  direction, uom,  who,  cost,   lot_ser, tran_ext ) 
			SELECT 	1, @issue_no2, @part,   @loc,    @to_bin, 'I',     @date_tran, @date_expires, @qty, 1,     inv.uom, @who, @cost, @lot_ser, 0 
			  FROM inventory inv (nolock)
			 WHERE inv.location = @loc AND inv.part_no = @part


		INSERT INTO issues ( issue_no,  part_no, location_from, avg_cost,  who_entered, code, issue_date, qty, direction, lb_tracking, direct_dolrs,         ovhd_dolrs,         util_dolrs,         labor,  reason_code,     serial_flag ) 
			SELECT 	    @issue_no1, @part,   @loc,       inv.avg_cost, @who,        'XFR', getdate(), @qty, -1,        'Y',     inv.avg_direct_dolrs, inv.avg_ovhd_dolrs, inv.avg_util_dolrs, inv.labor, @reason_code, @serial_flag 
			  FROM inv_list inv (nolock)
			 WHERE inv.location = @loc AND inv.part_no = @part

		IF @@ERROR <> 0
		BEGIN
			ROLLBACK TRAN
			RAISERROR ('INSERT INTO issues failed', 16, 1)
			RETURN -108
		END

		INSERT INTO issues ( issue_no,  part_no, location_from, avg_cost,  who_entered, code, issue_date, qty, direction, lb_tracking, direct_dolrs,         ovhd_dolrs,         util_dolrs,         labor,  reason_code,     serial_flag ) 
			SELECT 	    @issue_no2, @part,   @loc,       inv.avg_cost, @who,        'XFR', getdate(), @qty, 1,         'Y',     inv.avg_direct_dolrs, inv.avg_ovhd_dolrs, inv.avg_util_dolrs, inv.labor, @reason_code, @serial_flag 
			  FROM inv_list inv (nolock)
			 WHERE inv.location = @loc AND inv.part_no = @part

		IF @@ERROR <> 0
		BEGIN
			ROLLBACK TRAN
			RAISERROR ('INSERT INTO issues failed', 16, 1)
			RETURN -109
		END


		COMMIT TRAN
		
		/* Update the record in the temp table */
                UPDATE #adm_bin_xfer SET issue_no = @issue_no1 WHERE row_id = @issid                
	END
RETURN @issue_no1
GO
GRANT EXECUTE ON  [dbo].[tdc_bin_xfer] TO [public]
GO
