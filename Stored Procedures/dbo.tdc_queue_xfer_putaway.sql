SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/************************************************************************/
/* Name:	tdc_queue_xfer_putaway		      	      		*/
/*									*/
/* Module:	WMS							*/
/*						      			*/
/* Input:						      		*/
/*	xfer_no - 	Xfer Number			      		*/
/*	part_no - 	Part Number			    		*/
/* 	lot	- 	Lot Number					*/
/*	qty	- 	qty to be putaway				*/
/*	bin_no	-	receipt bin where inventory is waiting		*/
/*									*/
/* Description:								*/
/*	This SP places a bin to bin transaction on the put_queue after	*/
/*	a Xfer Receipt transaction has been completed. 			*/
/*	The bin_no is set equal to the receipt bin.			*/
/*									*/
/* Revision History:							*/
/* 	Date		Who	Description				*/
/*	----		---	-----------				*/
/*									*/
/*	8/14/2000	IA	Initial					*/
/*									*/
/************************************************************************/

CREATE PROCEDURE [dbo].[tdc_queue_xfer_putaway]
	@xfer_no 	int,
	@location	varchar(10),
	@part_no 	varchar (30),
	@lot 		varchar (25),
	@bin_no 	varchar (12),
	@qty 		decimal(20, 8)
AS

DECLARE @assign_group char (30),
	@priority int,
	@seq_no int,
	@cd_qty decimal(20, 8), 
	@order_no int,
	@order_ext int, 
	@count int,
	@Tran_id int,
	@line_no int,
	@target_bin varchar(12), 
	@dest_bin varchar(12), 
	@trg_off bit,
	@order_type varchar(1),
	@filled_ind char(1),
	@tran_type varchar(10),
	@from_tran_no varchar(16)

	SELECT @priority = 5, @Tran_id = 0
	SELECT @filled_ind = 'N'
	SELECT @assign_group = 'PUTAWAY'

-------------------------------------------

	IF EXISTS (SELECT * 
		     FROM tdc_cdock_mgt (nolock)
		    WHERE from_tran_type = 'X'
		      AND from_tran_no   = CAST(@xfer_no AS VARCHAR(16))
		      AND ISNULL(from_tran_ext, 0) = 0
		      AND location = @location
		      AND part_no  = @part_no)
	BEGIN
		SELECT @from_tran_no = CAST(@xfer_no AS VARCHAR(16))
		EXEC @tran_id = tdc_cross_dock_management @location, @part_no, @lot, @bin_no, @qty, 'X', @from_tran_no, 0, @qty OUTPUT
	END

	IF @qty <= 0 RETURN @tran_id

--------------------------------------------	

	SELECT @count = count(*) FROM tdc_soft_alloc_tbl (nolock) WHERE location = @location AND part_no = @part_no AND lot_ser = 'CDOCK' AND bin_no = 'CDOCK'
		
	-- Cross dock commitments found for inbound inventory
	IF (@count <> 0)
	BEGIN
		DECLARE next_cd CURSOR FOR
			SELECT trans_type_no, trans_type_ext, qty_to_process, line_no, trans
			  FROM tdc_pick_queue (NOLOCK)
			 WHERE location = @location
			   AND part_no = @part_no
			   AND lot = 'CDOCK'
			   AND bin_no = 'CDOCK'
			   AND NOT EXISTS (SELECT * 
					     FROM tdc_cdock_mgt (nolock)
					    WHERE tran_type = trans
					      AND trans_type_no  = tran_no
					      AND ISNULL(trans_type_ext, 0) = ISNULL(tran_ext, 0)
					      AND location = @location 
					      AND part_no  = @part_no)
			ORDER BY priority, date_time

		OPEN next_cd

		FETCH NEXT FROM next_cd INTO @order_no, @order_ext, @cd_qty, @line_no, @tran_type

		WHILE (@@FETCH_STATUS = 0 AND @filled_ind = 'N')
		BEGIN
			SELECT @target_bin = target_bin, @dest_bin = dest_bin, @trg_off =  trg_off, @order_type = order_type 
			  FROM tdc_soft_alloc_tbl (NOLOCK)
			 WHERE order_no = @order_no 
			   AND order_ext = @order_ext 
			   AND location = @location 
			   AND part_no = @part_no 
			   AND lot_ser = 'CDOCK'
			   AND bin_no = 'CDOCK'

			IF (@cd_qty >= @qty) --all inbound inventory will be used for sales order pick... no putaway inserted
			BEGIN
				UPDATE tdc_soft_alloc_tbl 
				   SET qty = (qty - @qty) 
				 WHERE order_no = @order_no 
				   AND order_ext = @order_ext 
				   AND location = @location 
				   AND part_no = @part_no 
				   AND line_no = @line_no 
				   AND lot_ser = 'CDOCK' 
				   AND bin_no = 'CDOCK' 
				   AND order_type = @order_type 

			     	DELETE FROM tdc_soft_alloc_tbl
			         WHERE order_no = @order_no 
			           AND order_ext = @order_ext
			           AND part_no = @part_no
			           AND line_no = @line_no
				   AND lot_ser = 'CDOCK'
				   AND bin_no = 'CDOCK'
				   AND qty <= 0
			           AND order_type = @order_type

				IF (@cd_qty = @qty)
				BEGIN
					DELETE FROM tdc_pick_queue 
					 WHERE trans_type_no = @order_no 
					   AND trans_type_ext = @order_ext
					   AND line_no = @line_no 
					   AND lot = 'CDOCK'
					   AND bin_no = 'CDOCK' 
					   AND  trans = @tran_type
				END
				ELSE
				BEGIN
					UPDATE tdc_pick_queue 
					   SET qty_to_process = (qty_to_process - @qty) 
					 WHERE trans_type_no = @order_no
					   AND trans_type_ext = @order_ext
					   AND line_no = @line_no
					   AND lot = 'CDOCK'
					   AND bin_no = 'CDOCK' 
					   AND trans = @tran_type
				END

				IF EXISTS (SELECT * 
					     FROM tdc_soft_alloc_tbl
					    WHERE order_no = @order_no
					      AND order_ext = @order_ext
					      AND location = @location
					      AND part_no = @part_no
					      AND line_no = @line_no
					      AND lot_ser = @lot
					      AND bin_no = @bin_no
					      AND order_type = @order_type )
				BEGIN
					UPDATE tdc_soft_alloc_tbl
					   SET qty = qty + @qty
					 WHERE order_no = @order_no
					   AND order_ext = @order_ext
					   AND location = @location
					   AND part_no = @part_no
					   AND line_no = @line_no
					   AND lot_ser = @lot
					   AND bin_no = @bin_no
					   AND order_type = @order_type 
				END
				ELSE
				BEGIN
					INSERT INTO tdc_soft_alloc_tbl (order_no, order_ext, location, line_no, part_no, lot_ser, bin_no, qty, target_bin, dest_bin, trg_off, order_type, q_priority) 
								VALUES(@order_no, @order_ext, @location, @line_no, @part_no, @lot, @bin_no, @qty, @bin_no, @dest_bin, @trg_off, @order_type, @priority)
				END

				SELECT @filled_ind = 'Y'
			END
			ELSE --putaway inserted for left over qty
			BEGIN
				DELETE FROM tdc_soft_alloc_tbl 
				 WHERE order_no = @order_no
				   AND order_ext = @order_ext
				   AND location = @location
				   AND part_no = @part_no
				   AND line_no = @line_no
				   AND lot_ser = 'CDOCK'
				   AND bin_no = 'CDOCK'
				   AND order_type = @order_type

				DELETE FROM tdc_pick_queue 
				 WHERE trans_type_no = @order_no
				   AND trans_type_ext = @order_ext
				   AND line_no = @line_no
				   AND lot = 'CDOCK'
				   AND bin_no = 'CDOCK'

				IF EXISTS (SELECT * 
					     FROM tdc_soft_alloc_tbl
					    WHERE order_no = @order_no
					      AND order_ext = @order_ext
					      AND location = @location
					      AND part_no = @part_no
					      AND line_no = @line_no
					      AND lot_ser = @lot
					      AND bin_no = @bin_no)
				BEGIN
					UPDATE tdc_soft_alloc_tbl
					   SET qty = qty + @cd_qty
					 WHERE order_no = @order_no
					   AND order_ext = @order_ext
					   AND location = @location
					   AND part_no = @part_no
					   AND line_no = @line_no
					   AND lot_ser = @lot
					   AND bin_no = @bin_no
				END
				ELSE
				BEGIN
					INSERT INTO tdc_soft_alloc_tbl (order_no, order_ext, location, line_no, part_no, lot_ser, bin_no, qty, target_bin, dest_bin, trg_off, order_type, q_priority) 
								VALUES(@order_no, @order_ext, @location, @line_no, @part_no, @lot, @bin_no, @cd_qty, @bin_no, @dest_bin, @trg_off, @order_type, @priority)
				END

				SELECT @qty = (@qty - @cd_qty)
			END

			FETCH NEXT FROM next_cd into @order_no, @order_ext, @cd_qty, @line_no, @tran_type		
		END

		CLOSE next_cd
		DEALLOCATE next_cd
	END

	IF (@qty > 0 and @filled_ind = 'N')
	BEGIN
		IF EXISTS (SELECT * FROM tdc_bin_master (nolock) WHERE usage_type_code = 'RECEIPT' AND location = @location AND bin_no = @bin_no AND status = 'A')
		BEGIN
			EXEC @seq_no = tdc_queue_get_next_seq_num 'tdc_put_queue', @priority

			INSERT INTO tdc_put_queue (trans_source, trans, priority, seq_no, company_no, location, warehouse_no, 
					trans_type_no, trans_type_ext, tran_receipt_no, line_no, pcsn, part_no, eco_no,
					lot, mfg_lot, mfg_batch, serial_no, bin_no, qty_to_process, qty_processed, qty_short, next_op,
					tran_id_link, date_time, assign_group, assign_user_id, user_id, status, tx_status, tx_control, tx_lock) 
				VALUES('CO', 'XPTWY', @priority, @seq_no, NULL, @location, NULL, @xfer_no, NULL, NULL, NULL, 
					NULL, @part_no, NULL, @lot, NULL, NULL, NULL, @bin_no, @qty, 0, 0, NULL, NULL, GETDATE(), @assign_group, 
					NULL, NULL, NULL, NULL, 'M', 'R')
	
			SELECT @Tran_id = MAX(Tran_id) FROM tdc_put_queue
		END
	END

RETURN @Tran_id
GO
GRANT EXECUTE ON  [dbo].[tdc_queue_xfer_putaway] TO [public]
GO
