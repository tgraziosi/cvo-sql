SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**********************************************************************************************/
/*											      */
/* This procedure requests transfer items   						      */
/*											      */
/**********************************************************************************************/
CREATE PROC [dbo].[tdc_req_xfer] AS

DECLARE @xfer_no int, 
	@line_no int, 
	@err int,
	@language varchar(10),
	@msg varchar(255)

SELECT  @err = 0		/* Initialize the error code to 'No errors' */
SELECT	@line_no = 0  		/* Find the first line number */

SELECT @language = ISNULL((SELECT Language FROM tdc_sec (nolock) WHERE userid = (SELECT MIN(who) FROM #adm_req_xfer)), 'us_english')

UPDATE #adm_req_xfer SET who = (SELECT login_id FROM #temp_who)

WHILE (@line_no >= 0)		/* Look at each line number... */
BEGIN
	SELECT @line_no = (select min(line_no) from #adm_req_xfer where line_no > @line_no)

      	IF @line_no is null	/* No more line numbers */        
        BEGIN
          	/* If the table is error-free */
        	IF NOT EXISTS  (select * from #adm_req_xfer where err_msg is not null)
            	BEGIN
              		BEGIN TRAN
                		/* Get the next transfer number */
                		SELECT @xfer_no = (select last_no from next_xfer_no) + 1
                		UPDATE next_xfer_no SET last_no = @xfer_no
                	
				/* Add the transfer to xfers and xfer_list */
				INSERT INTO xfers ( xfer_no, from_loc, to_loc, req_ship_date, sch_ship_date, date_entered, 
						    who_entered, status, freight, printed, label_no, no_cartons, 
						    to_loc_name, to_loc_addr1, to_loc_addr2, rec_no, no_pallets, 
						    to_loc_addr3, to_loc_addr4, to_loc_addr5 ) 
                			     SELECT @xfer_no, t.from_loc, t.to_loc, getdate(), getdate(), getdate(), t.who,
                    				    'N', 0, 'N', 0, 0, l.[name], l.addr1, l.addr2,0, 0, l.addr3, l.addr4, l.addr5 
                  			     FROM  #adm_req_xfer t, locations l
                  			     WHERE l.location = t.to_loc AND
						   t.line_no  = 1

		--If the part is epicor serialized then...
			IF EXISTS (SELECT a.* FROM #adm_req_xfer a, inv_master i (NOLOCK) WHERE a.part_no = i.part_no AND i.serial_flag = 1) 
			AND (SELECT COUNT(DISTINCT part_no) FROM #adm_req_xfer) = 1
			BEGIN
				SELECT TOP 1 @line_no = line_no FROM #adm_req_xfer
				INSERT INTO xfer_list ( xfer_no, line_no, from_loc, to_loc, part_no, [description], 
									time_entered, ordered, shipped, status, cost, who_entered, 
									temp_cost, uom, conv_factor, std_cost, to_bin, lot_ser, 
									date_expires, lb_tracking, labor, direct_dolrs, ovhd_dolrs, 
									util_dolrs, display_line ) 
		                		SELECT @xfer_no, @line_no, t.from_loc, t.to_loc, t.part_no, i.[description],
		                    					getdate(), SUM(t.qty), 0, 'N', inv.cost, t.who, 0, t.uom, t.conv_factor,
		                    					i.std_cost, 'IN TRANSIT', 'N/A', getdate(), i.lb_tracking, 
									inv.labor, inv.std_direct_dolrs, inv.std_ovhd_dolrs, 
									inv.std_util_dolrs, @line_no 
		                  			FROM #adm_req_xfer t, inv_master i, inventory inv
		                  				 WHERE i.part_no = t.part_no AND t.part_no = inv.part_no AND t.from_loc = inv.location
							GROUP BY t.from_loc, t.to_loc, t.part_no, i.[description], inv.cost, t.who,
								 t.uom, t.conv_factor, i.std_cost, i.lb_tracking, inv.labor, inv.std_direct_dolrs, inv.std_ovhd_dolrs, inv.std_util_dolrs

				SELECT @line_no = -1
			END
			ELSE
			
			BEGIN
				INSERT INTO xfer_list ( xfer_no, line_no, from_loc, to_loc, part_no, [description], 
							time_entered, ordered, shipped, status, cost, who_entered, 
							temp_cost, uom, conv_factor, std_cost, to_bin, lot_ser, 
							date_expires, lb_tracking, labor, direct_dolrs, ovhd_dolrs, 
							util_dolrs, display_line ) 
                				 SELECT @xfer_no, t.line_no, t.from_loc, t.to_loc, t.part_no, i.[description],
                    					getdate(), t.qty, 0, 'N', inv.cost, t.who, 0, t.uom, t.conv_factor,
                    					i.std_cost, 'IN TRANSIT', 'N/A', getdate(), i.lb_tracking, 
							inv.labor, inv.std_direct_dolrs, inv.std_ovhd_dolrs, 
							inv.std_util_dolrs, t.line_no 
                  				 FROM #adm_req_xfer t, inv_master i, inventory inv
                  				 WHERE i.part_no = t.part_no
						 AND   t.part_no = inv.part_no
						 AND   t.from_loc = inv.location
			END
                		UPDATE #adm_req_xfer SET xfer_no = @xfer_no
                	COMMIT TRAN
        	END
        END

	ELSE			/* if the @line_no is not null */
	BEGIN
        	/* Make sure there are no duplicate line numbers */
        	IF ((SELECT COUNT(*) FROM #adm_req_xfer WHERE line_no = @line_no) > 1)
          	BEGIN            		
            	--	UPDATE #adm_req_xfer SET err_msg = 'Duplicate line number %d.' WHERE line_no = @line_no
			SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_req_xfer' AND err_no = -101 AND language = @language
			RAISERROR (@msg, 16, 1, @line_no)
            		RETURN -101
          	END
  
          	/* Make sure there are no transfer numbers assigned yet */
          	IF EXISTS (SELECT * FROM #adm_req_xfer WHERE xfer_no is not null)
            	BEGIN              		
              	--	UPDATE #adm_req_xfer SET err_msg = 'Transfer already processed.' WHERE line_no = @line_no
			SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_req_xfer' AND err_no = -102 AND language = @language
			RAISERROR (@msg, 16, 1)
            		RETURN -102
            	END

            	/* Make sure to location exists */
            	IF NOT EXISTS (SELECT * FROM locations l, #adm_req_xfer t WHERE l.location = t.to_loc AND t.line_no = @line_no)
              	BEGIN
                -- 	UPDATE #adm_req_xfer SET err_msg = 'To location does not exist.' WHERE line_no = @line_no
			SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_req_xfer' AND err_no = -103 AND language = @language
			RAISERROR (@msg, 16, 1)
            		RETURN -103
              	END

              	/* Make sure from location exists */
              	IF NOT EXISTS (SELECT * FROM  locations l, #adm_req_xfer t WHERE l.location = t.from_loc AND t.line_no = @line_no)
                BEGIN
                --  	UPDATE #adm_req_xfer SET err_msg = 'From location does not exist.' WHERE line_no = @line_no
			SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_req_xfer' AND err_no = -104 AND language = @language
			RAISERROR (@msg, 16, 1)
            		RETURN -104
                END
          
                /* Make sure part number exists */
                IF NOT EXISTS (SELECT * FROM inv_master i, #adm_req_xfer t WHERE i.part_no = t.part_no AND t.line_no = @line_no)
                BEGIN
                --    	UPDATE #adm_req_xfer SET err_msg = 'Part number is not valid.' WHERE line_no = @line_no
			SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_req_xfer' AND err_no = -105 AND language = @language
			RAISERROR (@msg, 16, 1)
            		RETURN -105
                END
             
                /* Make sure quantity is positive */
                IF ((SELECT qty FROM #adm_req_xfer WHERE line_no = @line_no) <= 0.0)
                BEGIN
                --     	UPDATE #adm_req_xfer SET err_msg = 'Quantity must be positive.' WHERE line_no = @line_no
			SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_req_xfer' AND err_no = -106 AND language = @language
			RAISERROR (@msg, 16, 1)
            		RETURN -106
                END
	END
END

RETURN @err
GO
GRANT EXECUTE ON  [dbo].[tdc_req_xfer] TO [public]
GO
