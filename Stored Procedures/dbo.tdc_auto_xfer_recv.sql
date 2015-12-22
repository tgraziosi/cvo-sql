SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/************************************************************************************************/
/* If a flag called AUTO_REC_XFER in epicor configuration list is set to yes 			*/
/* this stored procedure will be called. 							*/
/* Three transactions Picking, Ship verify, and xfer receipt are processing all at once.   	*/
/* The shipped quantity must be equal to its ordered quantity for every line item.	      	*/
/* Different line item can have different to bin value.					   	*/
/* No unpick is possible.									*/
/************************************************************************************************/

CREATE PROC [dbo].[tdc_auto_xfer_recv] 
 AS 

	SET NOCOUNT ON

	DECLARE @xfer_no int, 
		@line_no int, 
		@recid int, 
		@seq_no int, 
		@row_id int, 
		@count int

	DECLARE	@from_loc varchar(10), 
		@to_loc varchar(10), 
		@from_bin varchar(12),
		@to_bin varchar(12), 
		@mask_code varchar(15), 
		@language varchar(10), 
		@serial_no varchar(40),
		@lot varchar(25), 
		@part_no varchar(30), 
		@who varchar(50), 
		@user_name varchar(50),
		@msg varchar(255) 

	DECLARE	@qty decimal(20,8), 
		@conv_factor decimal(20,8),
		@ordered decimal(20,8),
		@in_stock decimal(20,8)

	DECLARE	@lbtrack char(1), 
		@status char(1)

	DECLARE	@date_expires datetime
		
		
	/* Find the first record */
  	SELECT @recid = 0, @msg = 'Error message not found'
	SELECT @who = MIN(who), @xfer_no = MIN(xfer_no) FROM #tdc_auto_xfer_recv
	SELECT @language = ISNULL((SELECT Language FROM tdc_sec (nolock) WHERE userid = @who), 'us_english')
	SELECT @user_name = login_id FROM #temp_who

      	/* Make sure transfer number exists and has valid status */
      	SELECT @from_loc = from_loc, @to_loc = to_loc 
	  FROM xfers (nolock) 
	 WHERE xfer_no = @xfer_no 
	   AND status IN ('N', 'P', 'Q')

	IF (@@ROWCOUNT = 0)
        BEGIN
		-- Error: Transfer number %d is not valid.          		
		SELECT @msg = err_msg 
		  FROM tdc_lookup_error (nolock) 
		 WHERE module = 'SPR' 
		   AND trans = 'tdc_auto_xfer_recv' 
		   AND language = @language 
		   AND err_no = -101

		RAISERROR (@msg, 16, 1, @xfer_no)
          	RETURN -101
        END
 
	/* Make sure all line items has not been picked */
	IF EXISTS (SELECT * FROM xfer_list (nolock) WHERE xfer_no = @xfer_no AND shipped > 0)
	BEGIN
		-- Error: Some line items on xfer %d had been picked.			
		SELECT @msg = err_msg 
		  FROM tdc_lookup_error (nolock) 
		 WHERE module = 'SPR' 
		   AND trans = 'tdc_auto_xfer_recv' 
		   AND language = @language 
		   AND err_no = -102

		RAISERROR (@msg, 16, 1, @xfer_no)
		RETURN -102
	END

	/* Look at each record... */
  	WHILE (@recid >= 0)
	BEGIN
      		SELECT @recid = ISNULL((SELECT MIN(row_id) FROM #tdc_auto_xfer_recv WHERE row_id > @recid), -1)
      		IF @recid = -1 BREAK

	      	SELECT @line_no = line_no, @part_no = part_no, @from_bin = from_bin,
		       @qty = qty, @lot = lot_ser, @to_bin = to_bin 
		  FROM #tdc_auto_xfer_recv 
		 WHERE row_id = @recid 

		SELECT @lbtrack = lb_tracking, @status = status 
		  FROM inv_master (nolock) 
		 WHERE part_no = @part_no

		/* Make sure part number exists */
		IF (@@ROWCOUNT = 0)
         	BEGIN
		--	IF @@TRANCOUNT > 0 ROLLBACK TRAN

			-- Error: Part number %s is not valid.            		        		
			SELECT @msg = err_msg 
			  FROM tdc_lookup_error (nolock) 
			 WHERE module = 'SPR' 
			   AND trans = 'tdc_auto_xfer_recv' 
			   AND language = @language 
			   AND err_no = -103

			RAISERROR (@msg, 16, 1, @part_no)			
            		RETURN -103
          	END
 
            	SELECT @ordered = ordered * conv_factor, @conv_factor = conv_factor 
		  FROM xfer_list (nolock) 
		 WHERE xfer_no = @xfer_no 
		   AND part_no = @part_no 
		   AND line_no = @line_no

		/* Make sure part number is on transfer */
		IF (@@ROWCOUNT = 0)
		BEGIN
		--	IF @@TRANCOUNT > 0 ROLLBACK TRAN

			-- Error: Item not on this line number %d.			
			SELECT @msg = err_msg 
			  FROM tdc_lookup_error (nolock) 
			 WHERE module = 'SPR' 
			   AND trans = 'tdc_auto_xfer_recv' 
			   AND language = @language 
			   AND err_no = -104

			RAISERROR (@msg, 16, 1, @line_no)
			RETURN -104
            	END

		IF ((SELECT SUM(qty) 
		       FROM #tdc_auto_xfer_recv 
		      WHERE part_no = @part_no 
		        AND line_no = @line_no) <> @ordered)
		BEGIN
		--	IF @@TRANCOUNT > 0 ROLLBACK TRAN

			-- Error: Picked quantity for Line %d must be equal to its ordered quantity.			
			SELECT @msg = err_msg 
			  FROM tdc_lookup_error (nolock) 
			 WHERE module = 'SPR' 
			   AND trans = 'tdc_auto_xfer_recv' 
			   AND language = @language 
			   AND err_no = -108

			RAISERROR (@msg, 16, 1, @line_no)
			RETURN -108
		END

		/* For lot/bin tracked items... */
		IF (@lbtrack = 'Y')
		BEGIN
			/* Make sure all the information is there */
			IF (@lot IS NULL) OR (@from_bin IS NULL) OR (@to_bin IS NULL)
			BEGIN
			--	IF @@TRANCOUNT > 0 ROLLBACK TRAN

				-- Error: Lot/bin information is required for this item %s.				
				SELECT @msg = err_msg 
				  FROM tdc_lookup_error (nolock) 
				 WHERE module = 'SPR' 
				   AND trans = 'tdc_auto_xfer_recv' 
				   AND language = @language 
				   AND err_no = -105

				RAISERROR (@msg, 16, 1, @part_no)
				RETURN -105
			END

			/* Make sure the item exists in the bin for picking */
            		SELECT @date_expires = date_expires, @in_stock = qty
			  FROM lot_bin_stock (nolock) 
			 WHERE location = @from_loc 
			   AND part_no = @part_no 
			   AND lot_ser = @lot 
			   AND bin_no = @from_bin

			IF (@@ROWCOUNT = 0)
            		BEGIN
			--	IF @@TRANCOUNT > 0 ROLLBACK TRAN

				-- Error: Specified item %s does not appear in lot/bin stock.            				
 				SELECT @msg = err_msg 
				  FROM tdc_lookup_error (nolock) 
				 WHERE module = 'SPR' 
				   AND trans = 'tdc_auto_xfer_recv' 
				   AND language = @language 
				   AND err_no = -106

				RAISERROR (@msg, 16, 1, @part_no)
                		RETURN -106
            		END

			IF (@qty > @in_stock)
			BEGIN
			--	IF @@TRANCOUNT > 0 ROLLBACK TRAN

				-- Error: There is not enough of item %s in stock.				
 				SELECT @msg = err_msg 
				  FROM tdc_lookup_error 
				 WHERE module = 'SPR' 
				   AND trans = 'tdc_auto_xfer_recv' 
				   AND language = @language 
				   AND err_no = -107

				RAISERROR (@msg, 16, 1, @part_no)
				RETURN -107
			END
		END
		ELSE
		BEGIN	-- not lb tracked item
			IF (@status != 'K')
			BEGIN
				IF (@qty > ( SELECT in_stock 
					       FROM inventory 
					      WHERE part_no = @part_no 
						AND location = @from_loc))
				BEGIN
				--	IF @@TRANCOUNT > 0 ROLLBACK TRAN

					-- Error: There is not enough of item %s in stock.					
 					SELECT @msg = err_msg 
					  FROM tdc_lookup_error (nolock) 
					 WHERE module = 'SPR' 
					   AND trans = 'tdc_auto_xfer_recv' 
					   AND language = @language 
					   AND err_no = -107

					RAISERROR (@msg, 16, 1, @part_no)
					RETURN -107	
				END
			END
		END
	END -- end while loop

/*moved updates to xfer and xfer_list after the updates to lot_bin_xfer to comply with the changes in eBO for lot serial costing KMH */
BEGIN TRAN 

	UPDATE tdc_xfers 
	   SET tdc_status = 'R1' 
	 WHERE xfer_no = @xfer_no

	UPDATE xfers 
	   SET status = 'R', date_shipped = getdate(), who_picked = @user_name, who_shipped = @user_name 
	 WHERE xfer_no = @xfer_no
	   AND status < 'R'

	DECLARE line_cursor CURSOR FOR 
		SELECT part_no, from_bin, lot_ser, line_no, to_bin, qty 
		  FROM #tdc_auto_xfer_recv 
		 WHERE lot_ser IS NOT NULL 
 		   AND from_bin IS NOT NULL
		
	OPEN line_cursor
	FETCH NEXT FROM line_cursor INTO @part_no, @from_bin, @lot, @line_no, @to_bin, @qty

	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		IF NOT EXISTS (SELECT * 
				 FROM lot_bin_xfer (nolock) 
				WHERE tran_no = @xfer_no 
				  AND lot_ser = @lot 
				  AND bin_no = @from_bin 
				  AND line_no = @line_no)
		BEGIN
            		SELECT @date_expires = date_expires 
			  FROM lot_bin_stock (nolock) 
			 WHERE location = @from_loc 
			   AND part_no = @part_no 
			   AND lot_ser = @lot 
			   AND bin_no = @from_bin

			INSERT lot_bin_xfer (location, part_no, bin_no, lot_ser, tran_code, tran_no, tran_ext, date_tran, date_expires, qty, direction, cost, uom, uom_qty, conv_factor, line_no, who, to_bin)
				SELECT 	@from_loc, @part_no, @from_bin, @lot, 'R', @xfer_no, 0, getdate(), @date_expires,
					@qty, -1, cost, uom, @qty/conv_factor, conv_factor, @line_no, @user_name, 'IN TRANSIT'
				  FROM xfer_list (nolock)
				 WHERE xfer_no = @xfer_no 
				   AND line_no = @line_no
		END
		ELSE
		BEGIN
			UPDATE lot_bin_xfer 
			   SET qty = qty + @qty, uom_qty = uom_qty + @qty / conv_factor, date_tran = getdate(), who = @user_name		
			 WHERE tran_no = @xfer_no 
			   AND line_no = @line_no 
			   AND lot_ser = @lot 
			   AND bin_no = @from_bin 
		END

		FETCH NEXT FROM line_cursor INTO @part_no, @from_bin, @lot, @line_no, @to_bin, @qty
	END

	DEALLOCATE line_cursor

	UPDATE xfer_list 
	   SET shipped = ordered, status = 'R', to_bin = 'N/A'
	 WHERE xfer_no = @xfer_no 
	   AND lb_tracking = 'N' 
	   AND status < 'R'

	UPDATE xfer_list 
	   SET shipped = lst.ordered, status = 'R', to_bin = rev.to_bin
	  FROM #tdc_auto_xfer_recv rev, xfer_list lst
	 WHERE lst.xfer_no = @xfer_no 
	   AND lst.lb_tracking = 'Y' 
	   AND lst.status < 'R'
	   AND lst.xfer_no = rev.xfer_no
	   AND lst.line_no = rev.line_no
	   AND rev.to_bin IS NOT NULL

	UPDATE tdc_dist_item_list 
	   SET shipped = quantity
	 WHERE order_no = @xfer_no 
	   AND [function] = 'T'

	-- receiving
	DECLARE line_cursor CURSOR FOR 
		SELECT line_no, part_no, to_bin
		  FROM #tdc_auto_xfer_recv 
		ORDER BY line_no

	OPEN line_cursor
	FETCH NEXT FROM line_cursor INTO @line_no, @part_no, @to_bin

	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		--SCR#37977 By Jim On 7/24/07
		IF @to_bin IS NOT NULL
		BEGIN
			UPDATE lot_bin_xfer 
			   SET tran_code ='S', date_tran = GETDATE(), to_bin = @to_bin, qty_received = uom_qty
			 WHERE tran_no = @xfer_no 
			   AND line_no = @line_no
			   AND qty_received IS NULL
		END
		--SCR#37977 By Jim On 7/24/07

		UPDATE xfer_list 
		   SET qty_rcvd = shipped, amt_variance = 0 
		 WHERE xfer_no = @xfer_no
		   AND line_no = @line_no
		   AND qty_rcvd IS NULL

		FETCH NEXT FROM line_cursor INTO @line_no, @part_no, @to_bin
	END

	DEALLOCATE line_cursor

	UPDATE xfers 
	   SET status = 'S', who_recvd = @user_name, date_recvd = getdate() 
       	 WHERE xfer_no = @xfer_no

	DECLARE line_cursor CURSOR FOR 
		SELECT part_no, lot_ser, to_bin, sum(qty) 
		  FROM lot_bin_xfer 
		 WHERE tran_no = @xfer_no 
		GROUP BY part_no, lot_ser, to_bin
	OPEN line_cursor
	FETCH NEXT FROM line_cursor INTO @part_no, @lot, @to_bin, @qty

	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		IF EXISTS (SELECT * 
			     FROM #auto_xfer_recv_sn a, tdc_serial_no_track b (nolock) 
		 	    WHERE a.part_no = @part_no 
			      AND a.lot_ser = @lot 
			      AND a.serial_no = b.serial_no
			      AND a.part_no = b.part_no
			      AND a.lot_ser = b.lot_ser)
		BEGIN
			UPDATE tdc_serial_no_track 
			   SET IO_Count = IO_Count + a.dir,
			       location = @to_loc,
			       transfer_location = @to_loc,
			       last_trans = 'AUTOXFRECV',
			       last_control_type = 'T', 
			       last_tx_control_no = @xfer_no,
			       date_time = getdate(), 
			       [User_id] = @who
			  FROM #auto_xfer_recv_sn a, tdc_serial_no_track b (nolock)
			 WHERE a.part_no = @part_no 
		      	   AND a.lot_ser = @lot 
		      	   AND a.serial_no = b.serial_no
		      	   AND a.part_no = b.part_no
		      	   AND a.lot_ser = b.lot_ser
		
			DELETE FROM #auto_xfer_recv_sn
			  FROM #auto_xfer_recv_sn a, tdc_serial_no_track b (nolock) 
			 WHERE a.part_no = @part_no 
			   AND a.lot_ser = @lot 
			   AND a.serial_no = b.serial_no
			   AND a.part_no = b.part_no
			   AND a.lot_ser = b.lot_ser
		END
		ELSE
		BEGIN
			SELECT @mask_code = mask_code FROM tdc_inv_master (nolock) WHERE part_no = @part_no
			INSERT INTO tdc_serial_no_track (location, transfer_location, part_no, lot_ser, mask_code, serial_no, serial_no_raw, IO_count, init_control_type, init_trans, init_tx_control_no, last_control_type, last_trans, last_tx_control_no, date_time, [User_id], ARBC_No)
						  SELECT @to_loc, @to_loc, 	     @part_no, @lot,   @mask_code, serial_no, serial_no,     dir, 	'T', 		  'AUTOXFRECV', @xfer_no, 	  'T', 		     'AUTOXFRECV', @xfer_no, 	     getdate(), @who,      NULL
					  	    FROM #auto_xfer_recv_sn a 
						   WHERE a.part_no = @part_no
						     AND a.lot_ser = @lot 
						     AND NOT EXISTS (SELECT * 
								       FROM tdc_serial_no_track b (nolock)
								      WHERE a.serial_no = b.serial_no
						     			AND a.part_no = b.part_no
						     			AND a.lot_ser = b.lot_ser)
		
			DELETE FROM #auto_xfer_recv_sn 
			       FROM #auto_xfer_recv_sn a
			      WHERE a.part_no = @part_no
				AND a.lot_ser = @lot 
				AND NOT EXISTS (SELECT * 
			       			  FROM tdc_serial_no_track b (nolock)
			      			 WHERE a.serial_no = b.serial_no
						   AND a.part_no = b.part_no
						   AND a.lot_ser = b.lot_ser)
		END
 
		IF EXISTS (SELECT * FROM tdc_bin_master (nolock) WHERE bin_no = @to_bin AND status = 'A' AND location = @to_loc AND usage_type_code = 'RECEIPT')
		BEGIN
			EXEC @seq_no = tdc_queue_get_next_seq_num  'tdc_put_queue', 5

			INSERT INTO tdc_put_queue (trans_source, trans, priority, seq_no, company_no, location, warehouse_no, 
			trans_type_no, trans_type_ext, tran_receipt_no, line_no, pcsn, part_no, eco_no, lot, mfg_lot, mfg_batch, 
			serial_no, bin_no, qty_to_process, qty_processed, qty_short, next_op, tran_id_link, date_time, assign_group, assign_user_id, [user_id], status, tx_status, tx_control, tx_lock)
			VALUES('CO', 'XPTWY', 5, @seq_no, NULL, @to_loc, NULL, @xfer_no, NULL, NULL, NULL, NULL, @part_no, NULL, @lot, NULL, NULL, NULL, @to_bin, @qty, 0, 0, NULL, NULL, GETDATE(), 'PUTAWAY', NULL, NULL, NULL, NULL, 'M', 'R')
		END

		FETCH NEXT FROM line_cursor INTO @part_no, @lot, @to_bin, @qty
	END

	DEALLOCATE line_cursor

COMMIT TRAN

INSERT INTO tdc_bkp_dist_item_list(order_no, order_ext, line_no, part_no, quantity, shipped, [function], bkp_status, bkp_date)
	SELECT order_no, 0, line_no, part_no, quantity, shipped, 'T', 'C', GETDATE() 
	  FROM tdc_dist_item_list (nolock)
	 WHERE order_no = @xfer_no
	   AND [function] = 'T' 	

DELETE FROM tdc_dist_item_list 
      WHERE order_no = @xfer_no 
	AND [function] = 'T' 

INSERT INTO tdc_bkp_dist_item_pick ( method, order_no, order_ext, line_no, part_no, lot_ser, bin_no, quantity, child_serial_no, [function], type, status, bkp_status, bkp_date )
	SELECT '01', @xfer_no, 0, line_no, part_no, NULL, NULL, shipped * conv_factor, 0, 'T', 'O1', 'V', 'C', GETDATE() 
	  FROM xfer_list (nolock)
	 WHERE xfer_no = @xfer_no 
	   AND lb_tracking = 'N'

-- SCR #34740
INSERT INTO tdc_bkp_dist_item_pick 
      ( method, order_no, order_ext, line_no, part_no, lot_ser, bin_no, quantity, child_serial_no, [function], type, status, bkp_status, bkp_date )
SELECT '01',    @xfer_no, 0,         line_no, part_no, lot_ser, bin_no, qty,  0, 		'T',   'O1', 'V', 	'C',     GETDATE() 
  FROM lot_bin_xfer (nolock)
 WHERE tran_no = @xfer_no 

DELETE FROM tdc_soft_alloc_tbl WHERE order_no = @xfer_no AND order_ext = 0 AND order_type = 'T'
DELETE FROM tdc_pick_queue WHERE trans_type_no = @xfer_no AND trans_type_ext = 0 AND trans = 'XFERPICK'

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_auto_xfer_recv] TO [public]
GO
