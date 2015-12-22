SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/************************************************************************************************/
/* This procedure picks finished goods to ship.						      	*/
/* A negative quantity unpicks that much of the line item.				   	*/
/* Overpicking is allowed								      	*/
/* New ERA70 : 	When printing the picking form, the status changes to 'Q', so I update the     	*/
/*		status to 'Q'instead of 'P'							*/
/************************************************************************************************/

CREATE PROC [dbo].[tdc_pick_xfer]
AS 

	SET NOCOUNT ON

	DECLARE @xfer_no int, 
		@line_no int, 
		@recid int,
		@from_loc varchar(10), 
		@bin varchar(12), 
		@lot varchar(25), 
		@part_no varchar(30), 
		@qty decimal(20,8), 
		@date datetime, 
		@lbtrack char(1),
		@status char(1),
       		@conv_factor decimal(20,8),
		@adm_qty decimal(20,8),
		@who varchar(50),
		@err_msg varchar(255),
		@language varchar(10)

	/* Find the first record */
  	SELECT @recid = 0, @err_msg = 'Error message not found'

	SELECT 	@xfer_no = MAX(xfer_no), @who = MAX(who) FROM #adm_pick_xfer GROUP BY xfer_no, who
	SELECT @language = ISNULL((SELECT Language FROM tdc_sec (nolock) WHERE userid = @who), 'us_english')

	SELECT @who = login_id FROM #temp_who

     	/* Make sure transfer number exists */
      	IF NOT EXISTS (SELECT * FROM xfers (nolock) WHERE xfer_no = @xfer_no)
        BEGIN
		-- Error: Transfer number %d is not valid.          		
		SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pick_xfer' AND err_no = -101 AND language = @language
		RAISERROR (@err_msg, 16, 1, @xfer_no)
          	RETURN -101
        END
 
	/* Make sure the status is new or picked/printed */
	IF NOT EXISTS (SELECT * FROM xfers (nolock) WHERE xfer_no = @xfer_no AND status IN ('N', 'P', 'Q'))
	BEGIN
		-- Error: Transfer %d must be new or printed.			
		SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pick_xfer' AND err_no = -106 AND language = @language
		RAISERROR (@err_msg, 16, 1, @xfer_no)
		RETURN -106
	END

BEGIN TRAN

	UPDATE xfers SET status = 'Q', who_picked = @who WHERE xfer_no = @xfer_no 

	/* Look at each record... */
  	WHILE (@recid >= 0)
	BEGIN
      		SELECT @recid = ISNULL((SELECT MIN(row_id) FROM #adm_pick_xfer WHERE row_id > @recid), -1)
      		IF @recid = -1 BREAK

	      	SELECT 	@line_no = line_no, @part_no = part_no, @from_loc = from_loc,
			@qty = ISNULL(qty,0), @lot = lot_ser, @bin = bin_no, @date = date_exp 
		  FROM #adm_pick_xfer 
		 WHERE row_id = @recid 

		/* if order has been picked by ADM we can not pick it again */
		/* when making warehouse move tdc_status flag is set to W1  */
		IF ((SELECT tdc_status FROM tdc_xfers (nolock) WHERE xfer_no = @xfer_no) <> 'W1')
		BEGIN
			IF (@qty > 0.0) AND ((SELECT SUM(shipped) FROM xfer_list (nolock) WHERE xfer_no = @xfer_no) > 0)
			BEGIN
				IF NOT EXISTS (SELECT * FROM tdc_dist_item_pick (nolock) WHERE order_no = @xfer_no AND order_ext = 0 AND [function] = 'T')
				BEGIN
					ROLLBACK TRAN

					-- Error: Order %d is controlled by ADM             				
 					SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pick_xfer' AND err_no = -102 AND language = @language
					RAISERROR (@err_msg, 16, 1, @xfer_no)					
					RETURN -102
				END
			END
		END

		SELECT @lbtrack = lb_tracking, @status = status FROM inv_master (nolock) WHERE part_no = @part_no

		/* Make sure part number exists */
		IF (@@ROWCOUNT = 0)
         	BEGIN
			ROLLBACK TRAN

			-- Error: Part number %s is not valid.            		        		
			SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pick_xfer' AND err_no = -103 AND language = @language
			RAISERROR (@err_msg, 16, 1, @part_no)			
            		RETURN -103
          	END
 
            	SELECT @conv_factor = conv_factor FROM xfer_list (nolock) WHERE xfer_no = @xfer_no AND part_no = @part_no AND line_no = @line_no

		/* Make sure part number is on transfer */
		IF (@@ROWCOUNT = 0)
		BEGIN
			ROLLBACK TRAN

			-- Error: Item not on this line number %d			
			SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pick_xfer' AND err_no = -104 AND language = @language
			RAISERROR (@err_msg, 16, 1, @line_no)			
			RETURN -104
            	END
 
		/* If quantity is negative (unpicking), don't unpick more than was picked */
		IF EXISTS (SELECT * FROM xfer_list (nolock) WHERE (shipped * conv_factor + @qty < 0.0) AND xfer_no = @xfer_no AND line_no = @line_no)
		BEGIN
			ROLLBACK TRAN

			-- Error: Cannot unpick more than was picked.
			SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pick_xfer' AND err_no = -105 AND language = @language
			RAISERROR (@err_msg, 16, 1)			
			RETURN -105
		END

		/* For lot/bin tracked items... */
		IF (@lbtrack = 'Y')
		BEGIN
			/* Make sure all the information is there */
			IF (@lot IS NULL) OR (@bin IS NULL) OR (@date IS NULL)
			BEGIN
				ROLLBACK TRAN

				-- Error: Lot/bin information is required for this item %s.				
				SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pick_xfer' AND err_no = -107 AND language = @language
				RAISERROR (@err_msg, 16, 1, @part_no)				
				RETURN -107
			END

			IF (@qty > 0.0)
			BEGIN
				/* Make sure the item exists in the bin for picking */
            			IF NOT EXISTS (SELECT * FROM lot_bin_stock (nolock) WHERE location = @from_loc AND part_no = @part_no AND lot_ser = @lot AND bin_no = @bin )
            			BEGIN
					ROLLBACK TRAN

					-- Error: Specified item %s does not appear in lot/bin stock.            				
 					SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pick_xfer' AND err_no = -108 AND language = @language
					RAISERROR (@err_msg, 16, 1, @part_no)
                			RETURN -108
            			END

				IF (@qty > (SELECT qty 
					      FROM lot_bin_stock (nolock) 
					     WHERE part_no = @part_no 
					       AND location = @from_loc 
					       AND lot_ser = @lot
					       AND bin_no = @bin ))
				BEGIN
					ROLLBACK TRAN

					-- Error: There is not enough of item %s in stock.				
 					SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pick_xfer' AND err_no = -110 AND language = @language
					RAISERROR (@err_msg, 16, 1, @part_no)
					RETURN -110
				END
			END
			ELSE
			BEGIN 	
				/* Make sure the lot/bin returning to is the one picked from, if unpicking */
				IF NOT EXISTS (SELECT * 
						 FROM lot_bin_xfer (nolock) 
						WHERE tran_no = @xfer_no 
						  AND line_no = @line_no
                                            	  AND @part_no = part_no
						  AND lot_ser = @lot
						  AND bin_no = @bin)                                       
				BEGIN
					ROLLBACK TRAN

					-- Error: Item %s was not picked from this lot/bin: %s/%s.                        		
 					SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pick_xfer' AND err_no = -109 AND language = @language
					RAISERROR (@err_msg, 16, 1, @part_no, @lot, @bin)
					RETURN -109
                		END

				IF (SELECT qty 
				      FROM lot_bin_xfer (nolock) 
				     WHERE tran_no = @xfer_no 
				       AND line_no = @line_no
				       AND lot_ser = @lot 
				       AND bin_no = @bin ) < -@qty                        
				BEGIN
					ROLLBACK TRAN

					-- Error: Cannot unpick more than was picked.                      		
 					SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pick_xfer' AND err_no = -109 AND language = @language
					RAISERROR (@err_msg, 16, 1)
					RETURN -111
                		END
			END
		END
		ELSE
		BEGIN	-- not lb tracked item
			IF (@status != 'K') AND (@qty > 0)
			BEGIN
				IF (@qty > (SELECT in_stock FROM inventory (nolock) WHERE part_no = @part_no AND location = @from_loc))
				BEGIN
					ROLLBACK TRAN

					-- Error: There is not enough of item %s in stock.					
 					SELECT @err_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_pick_xfer' AND err_no = -110 AND language = @language
					RAISERROR (@err_msg, 16, 1, @part_no)
					RETURN -110			
				END
			END
		END

		UPDATE dbo.xfer_list 
		   SET shipped = shipped + @qty/conv_factor, status = 'Q'
		 WHERE xfer_no = @xfer_no AND line_no = @line_no

		UPDATE dbo.xfer_list SET status = 'Q' WHERE xfer_no = @xfer_no AND status <> 'Q'

		IF (@lbtrack = 'Y')
		BEGIN
			UPDATE dbo.xfer_list 
			   SET to_bin = 'IN TRANSIT'
			 WHERE xfer_no = @xfer_no AND lb_tracking = 'Y' AND to_bin <> 'IN TRANSIT'

			IF EXISTS (SELECT * 
				     FROM lot_bin_xfer (nolock) 
				    WHERE tran_no = @xfer_no
				      AND lot_ser = @lot 
				      AND bin_no = @bin 
				      AND location = @from_loc
				      AND line_no = @line_no)
			BEGIN
				UPDATE lot_bin_xfer 
				   SET qty = qty + @qty, uom_qty = uom_qty + @qty/conv_factor, date_tran = getdate(), who = @who		
				 WHERE tran_no = @xfer_no 
				   AND line_no = @line_no
				   AND location = @from_loc 
				   AND lot_ser = @lot 
				   AND bin_no = @bin 

				DELETE FROM lot_bin_xfer 
				WHERE tran_no = @xfer_no 
				  AND line_no = @line_no 
				  AND location = @from_loc 
				  AND lot_ser = @lot 
				  AND bin_no = @bin
				  AND qty <= 0.0
			END
			ELSE
			BEGIN
				INSERT lot_bin_xfer (location, part_no, bin_no, lot_ser, tran_code, tran_no, tran_ext, date_tran, date_expires, qty, direction, cost, uom, uom_qty, conv_factor, line_no, who, to_bin)
					SELECT 	@from_loc, @part_no, @bin, @lot, 'Q', @xfer_no, 0, getdate(), @date,
						@qty, -1, cost, uom, @qty/conv_factor, conv_factor, @line_no, @who, 'IN TRANSIT'
					  FROM xfer_list (nolock)
					 WHERE xfer_no = @xfer_no AND line_no = @line_no
			END
		END

		/* update shipped for tdc_xfer_list_change sp to distinguish 	*/
		/* who coming to pick either adm or tdc 			*/
		UPDATE tdc_dist_item_list 
		   SET shipped = shipped + @qty 
		 WHERE order_no = @xfer_no AND line_no = @line_no AND [function] = 'T'
	END

COMMIT TRAN

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_pick_xfer] TO [public]
GO
