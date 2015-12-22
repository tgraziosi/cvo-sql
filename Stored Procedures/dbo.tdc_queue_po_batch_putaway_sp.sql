SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/********************************************************************************/
/* Name:	tdc_queue_putaway_sp		      	      			*/
/*										*/
/* Module:	WMS								*/
/*						      				*/
/* Input:						      			*/
/*	PO_no   - 	PO Number			      			*/
/*	part_no - 	Part Number			    			*/
/*	mod	-	Module that stored procedure is called from		*/
/*	qty	- 	qty to be putaway					*/
/*	bin_no	-	receipt bin where inventory is waiting			*/
/* Output:        					     	 		*/
/*	tran_id	-	Neg. # if errors occured	     	 		*/
/*										*/
/* Description:									*/
/*	This SP places a bin to bin transaction on the put_queue after		*/
/*	a PO, Xfer, Credit Return or a manufacturing transaction   		*/
/*	has been completed. The bin_no is set equal to the receipt bin.		*/
/*										*/
/* Revision History:								*/
/* 	Date		Who	Description					*/
/*	----		---	-----------					*/
/* 	12/14/1999	KMH	Initial						*/
/* 	3/28/2000	KMH	added a check for QC parts - insert		*/
/*				tx_lock = 'Q'					*/
/*	5/16/2000	KMH	changed the return value to equal 		*/
/*				tran_id						*/
/*	5/23/2000	KMH	added check for QC parts on PO Receipt		*/
/*				at the line level				*/
/*	5/31/2000	KMH	added a check for qty in Xfer putaways  	*/
/*										*/
/*	6/14/2000	IA	Deleted putaway for 'WOPTWY'. Replaced  	*/
/*				into separate SP tdc_queue_wo_putaway_sp	*/
/*	8/14/2000	IA	Deleted putaway for 'XPTWY'. Replaced   	*/
/*				into separate SP tdc_queue_xfer_putaway 	*/
/*	8/14/2000	IA	Renamed into tdc_queue_po_putaway 		*/
/*				because of one transaction left in this SP	*/
/*										*/
/********************************************************************************/

CREATE PROCEDURE [dbo].[tdc_queue_po_batch_putaway_sp] 
	@last_receipt_no 	int,
	@part_no 		varchar (30),
	@bin_no 		varchar (12),
	@total_qty 		decimal(20, 8),
	@badlot 		varchar (20)
AS


DECLARE @location varchar (10),
	@assign_group char (30),
	@po_no varchar(16),
	@priority int,
	@seq_no int,
	@tran_id int,
	@tx_lock varchar(2),
	@order_type char(1),
	@cd_qty decimal(20, 8),
	@po_qty decimal(20, 8),
	@order_no int,
	@order_ext int, 
	@count int, 
	@line_no int,
	@target_bin varchar(12), 
	@dest_bin varchar(12), 
	@trg_off bit,
	@filled_ind char(1),
	@who varchar(50),
	@tran_type varchar(10),
	@qty decimal(20, 8),
	@lot varchar (20),
	@receipt_no int,
	@bintype int,
	@rowid int

	SELECT @priority = ISNULL((SELECT value_str FROM tdc_config (nolock) WHERE [function] = 'Put_Q_Priority'), '5')
	IF @priority = '0' SELECT @priority = '5'

	SELECT @assign_group = 'PUTAWAY'
	SELECT @tx_lock = 'R'
	SELECT @filled_ind = 'N'

	SELECT @who = who FROM #temp_who
	SELECT @qty = 1

	IF (SELECT qc_flag FROM receipts (NOLOCK) WHERE receipt_no = @receipt_no AND part_no = @part_no) = 'Y'
	BEGIN
		SELECT @tx_lock = 'Q'
		SELECT @receipt_no = @last_receipt_no - @total_qty + 1 --Get first receipt number
	END
	ELSE
	BEGIN
		SELECT @receipt_no = @last_receipt_no
	END

	SELECT @location = location, @po_no = po_no FROM receipts (nolock) WHERE receipt_no = @receipt_no AND part_no = @part_no
	SELECT @bintype = (SELECT count(*) FROM tdc_bin_master (nolock) WHERE location = @location AND bin_no = @bin_no AND usage_type_code = 'RECEIPT' AND status = 'A')

	DECLARE sn_cursor CURSOR FOR SELECT serial FROM #serial_no

	OPEN sn_cursor
	FETCH NEXT FROM sn_cursor INTO @lot

	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		IF(@bintype > 0)
			EXEC @seq_no = tdc_queue_get_next_seq_num  'tdc_put_queue', @priority
		
		SELECT @count = count(*) 
		  FROM tdc_soft_alloc_tbl (NOLOCK) 
		 WHERE location = @location
		   AND part_no = @part_no
		   AND lot_ser = 'CDOCK'
		   AND bin_no = 'CDOCK'

-------------------------------------------

		IF EXISTS (SELECT * 
			     FROM tdc_cdock_mgt (nolock)
			    WHERE from_tran_type = 'P'
			      AND from_tran_no   = @po_no
			      AND (from_tran_ext IS NULL OR from_tran_ext = 0)
			      AND location = @location
			      AND part_no  = @part_no)
		BEGIN
			EXEC @tran_id = tdc_cross_dock_management @location, @part_no, @lot, @bin_no, 1, 'P', @po_no, 0, @qty OUTPUT

			IF @qty <= 0
			BEGIN
				FETCH NEXT FROM sn_cursor INTO @lot
				CONTINUE
			END
		END

--------------------------------------------

		-- Cross dock commitments found for inbound inventory
		IF (@count <> 0 AND @tx_lock != 'Q')
		BEGIN
			DECLARE next_cd CURSOR FOR
				SELECT trans_type_no, trans_type_ext, qty_to_process, line_no, trans, tran_id
				  FROM tdc_pick_queue (NOLOCK)
				 WHERE location = @location
				   AND part_no = @part_no
				   AND lot = 'CDOCK'
				   AND bin_no = 'CDOCK'
				   AND NOT EXISTS (SELECT * 
						     FROM tdc_cdock_mgt (nolock)
						    WHERE tran_type = trans
						      AND trans_type_no = tran_no
						      AND ISNULL(trans_type_ext, 0) = ISNULL(tran_ext, 0)
						      AND location = @location 
						      AND part_no  = @part_no)
				ORDER BY priority, date_time
	
			OPEN next_cd
			FETCH NEXT FROM next_cd INTO @order_no, @order_ext, @cd_qty, @line_no, @tran_type, @tran_id

			WHILE (@@FETCH_STATUS = 0)
			BEGIN
				SELECT @target_bin = target_bin, @dest_bin = dest_bin, @trg_off = trg_off, @order_type = order_type 
				  FROM tdc_soft_alloc_tbl (NOLOCK)
				 WHERE order_no = @order_no
				   AND ISNULL(order_ext, 0) = ISNULL(@order_ext, 0)
				   AND location = @location
				   AND part_no = @part_no
				   AND lot_ser = 'CDOCK'
				   AND bin_no = 'CDOCK'
	
				--all inbound inventory will be used for sales order pick... no putaway inserted
				UPDATE tdc_soft_alloc_tbl 
				   SET qty = (qty - 1) 
				 WHERE order_no = @order_no
				   AND ISNULL(order_ext, 0) = ISNULL(@order_ext, 0)
				   AND line_no = @line_no
				   AND lot_ser = 'CDOCK'
				   AND bin_no = 'CDOCK'
				   AND part_no = @part_no
				   AND order_type = @order_type

				IF (@cd_qty = 1)
				BEGIN
					DELETE FROM tdc_pick_queue
					 WHERE trans_type_no = @order_no
					   AND ISNULL(trans_type_ext, 0) = ISNULL(@order_ext, 0)
					   AND line_no = @line_no
					   AND lot = 'CDOCK'
					   AND bin_no = 'CDOCK'
					   AND part_no = @part_no
					   AND trans = @tran_type
					   AND tran_id = @tran_id
				END
				ELSE
				BEGIN
					UPDATE tdc_pick_queue 
					   SET qty_to_process = (qty_to_process - 1) 
					 WHERE trans_type_no = @order_no 
					   AND ISNULL(trans_type_ext, 0) = ISNULL(@order_ext, 0)
					   AND line_no = @line_no
					   AND lot = 'CDOCK'
					   AND bin_no = 'CDOCK'
					   AND part_no = @part_no
					   AND trans = @tran_type
					   AND tran_id = @tran_id
				END

				IF EXISTS (SELECT * 
					     FROM tdc_soft_alloc_tbl
					    WHERE order_no = @order_no
					      AND ISNULL(order_ext, 0) = ISNULL(@order_ext, 0)
					      AND location = @location
					      AND part_no = @part_no
					      AND line_no = @line_no
					      AND lot_ser = @lot
					      AND bin_no = @bin_no)
				BEGIN
					UPDATE tdc_soft_alloc_tbl
					   SET qty = qty + 1
					 WHERE order_no = @order_no
					   AND ISNULL(order_ext, 0) = ISNULL(@order_ext, 0)
					   AND location = @location
					   AND part_no = @part_no
					   AND line_no = @line_no
					   AND lot_ser = @lot
				           AND bin_no = @bin_no
				END
				ELSE
				BEGIN
					INSERT INTO tdc_soft_alloc_tbl (order_no, order_ext, location, line_no, part_no, lot_ser, bin_no, qty, target_bin, dest_bin, trg_off, order_type, q_priority) 
						VALUES(@order_no, @order_ext, @location, @line_no, @part_no, @lot, @bin_no, 1, @bin_no, @dest_bin, @trg_off, @order_type, @priority)
				END
				
				SELECT @filled_ind = 'Y'

				BREAK		
			END

			CLOSE next_cd
			DEALLOCATE next_cd
			
			IF (@filled_ind = 'N') AND (@bintype > 0)
			BEGIN				
				INSERT INTO tdc_put_queue (trans_source, trans, priority, seq_no, company_no, location, warehouse_no, 
					trans_type_no, trans_type_ext, tran_receipt_no, line_no, pcsn, part_no, eco_no,
					lot, mfg_lot, mfg_batch, serial_no, bin_no, qty_to_process, qty_processed, qty_short, next_op,
					tran_id_link, date_time, assign_group, assign_user_id, [user_id], status, tx_status, tx_control, tx_lock) 
				VALUES('CO', 'POPTWY', @priority, @seq_no, NULL, @location, NULL, @po_no, NULL, 
					@receipt_no, NULL, NULL, @part_no, NULL, @lot, NULL, NULL, NULL, @bin_no, 1, 0, 0, NULL,
					NULL, GETDATE(), @assign_group, NULL, @who, NULL, NULL, 'M', @tx_lock)
	
				SELECT @tran_id = MAX(tran_id) FROM tdc_put_queue				
			END
		END
		-- No cross dock commitments found for inbound inventory, so total qty should be inserted in queue for putaway.
		ELSE IF (@bintype > 0)
		BEGIN			
			INSERT INTO tdc_put_queue (trans_source, trans, priority, seq_no, company_no, location, warehouse_no, 
				trans_type_no, trans_type_ext, tran_receipt_no, line_no, pcsn, part_no, eco_no,
				lot, mfg_lot, mfg_batch, serial_no, bin_no, qty_to_process, qty_processed, qty_short, next_op,
				tran_id_link, date_time, assign_group, assign_user_id, [user_id], status, tx_status, tx_control, tx_lock)
			VALUES('CO', 'POPTWY', @priority, @seq_no, NULL, @location, NULL, @po_no, NULL, 
				@receipt_no, NULL, NULL, @part_no, NULL, @lot, NULL, NULL, NULL, @bin_no, 1, 0, 0, NULL, 
				NULL, GETDATE(), @assign_group, NULL, @who, NULL, NULL, 'M', @tx_lock)
	
			SELECT @tran_id = MAX(tran_id) FROM tdc_put_queue			
		END

		FETCH NEXT FROM sn_cursor INTO @lot
		
		IF (@tx_lock = 'Q')
			SELECT @receipt_no = @receipt_no + 1
	END

	CLOSE sn_cursor
	DEALLOCATE sn_cursor

RETURN @tran_id
GO
GRANT EXECUTE ON  [dbo].[tdc_queue_po_batch_putaway_sp] TO [public]
GO
