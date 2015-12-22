SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/************************************************************************/
/* Name:	tdc_queue_wo_putaway_sp		      	      		*/
/*									*/
/* Module:	WMS							*/
/*						      			*/
/* Input:						      		*/
/*	prod_no   - 	Production Number		      		*/
/*	prod_ext   - 	Production Extention		      		*/
/*	part_no - 	Part Number			    		*/
/*	qty	- 	qty to be putaway				*/
/*	bin_no	-	from bin where produced from			*/
/*	lot	-	lot where produced to				*/
/*	line	-	Line Number					*/
/* Output:        					     	 	*/
/*	tran_id	-	Neg. # if errors occured	     	 	*/
/*									*/
/* Description:								*/
/*	This SP places a bin to bin transaction on the tdc_put_queue 	*/
/*	after a manufacturing transaction WO Prod Output	  	*/
/*	has been completed. The bin_no is set equal to the receipt bin.	*/
/*									*/
/* Revision History:							*/
/* 	Date		Who	Description				*/
/*	----		---	-----------				*/
/* 	06/14/2000	IA	Initial					*/
/*									*/
/************************************************************************/

CREATE PROCEDURE [dbo].[tdc_queue_wo_putaway_sp] 
	@prod_no int,
	@prod_ext int,
	@part_no varchar (30),
	@bin_no varchar (12),
	@qty decimal(20, 8),
	@lot varchar (25),
	@line int
AS


DECLARE @tran_id int,
	@location varchar (10),
	@assign_group char (30),
	@priority int,
	@seq_no int,
	@tx_lock varchar(2),
	@qc_flag varchar(2),
	@qc_no int,
	@cd_qty decimal(20, 8), 
	@order_no int,
	@order_ext int, 
	@count int, 
	@line_no int,
	@target_bin varchar(12), 
	@dest_bin varchar(12), 
	@trg_off bit,
	@order_type varchar(1),
	@tran_type varchar(10),
	@from_tran_no varchar(16)

BEGIN
	SELECT @priority = 5
	SELECT @assign_group = 'PUTAWAY'
	SELECT @tx_lock = 'R'
	SELECT @tran_id = 0
	SELECT @count = -1
	
	SELECT @qc_flag  = qc_flag  FROM inv_master (nolock) WHERE part_no = @part_no
	SELECT @location = location FROM produce (nolock)    WHERE prod_no = @prod_no 
		
-------------------------------------------

	IF EXISTS (SELECT * 
		     FROM tdc_cdock_mgt (nolock)
		    WHERE from_tran_type = 'W'
		      AND from_tran_no   = CAST(@prod_no AS VARCHAR(16))
		      AND ISNULL(from_tran_ext, 0) = 0
		      AND location = @location
		      AND part_no  = @part_no)
	BEGIN
		SELECT @from_tran_no = CAST(@prod_no AS VARCHAR(16))
		EXEC @tran_id = tdc_cross_dock_management @location, @part_no, @lot, @bin_no, @qty, 'W', @from_tran_no, 0, @qty OUTPUT
	END

	IF @qty <= 0 RETURN @tran_id

--------------------------------------------

	SELECT @count = count(*) 
	  FROM tdc_soft_alloc_tbl
	 WHERE location = @location
	   AND part_no = @part_no
	   AND lot_ser = 'CDOCK'
	   AND bin_no = 'CDOCK'

	-- Cross dock commitments found for inbound inventory
	IF (@count > 0 AND @qc_flag != 'Y')
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

		WHILE (@@FETCH_STATUS = 0)
		BEGIN
			SELECT @target_bin = target_bin, @dest_bin = dest_bin, @trg_off = trg_off, @order_type = order_type 
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

				IF (@cd_qty = @qty)
				BEGIN
					DELETE FROM tdc_pick_queue
					 WHERE trans_type_no = @order_no
					   AND trans_type_ext = @order_ext
					   AND line_no = @line_no
					   AND lot = 'CDOCK'
					   AND bin_no = 'CDOCK' 
					   AND trans = @tran_type
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
					     FROM tdc_soft_alloc_tbl (nolock)
					    WHERE order_no = @order_no
					      AND order_ext = @order_ext
					      AND location = @location
					      AND part_no = @part_no
					      AND line_no = @line_no
					      AND lot_ser = @lot
					      AND bin_no = @bin_no
					      AND order_type = @order_type)
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

				SELECT @qty = 0
			END

			IF (@cd_qty < @qty) --putaway inserted for left over qty
			BEGIN
				DELETE FROM tdc_soft_alloc_tbl 
				WHERE order_no = @order_no
				  AND order_ext = @order_ext
				  AND location = @location
				  AND part_no = @part_no
				  AND line_no = @line_no
				  AND lot_ser = 'CDOCK'
				  AND order_type = @order_type
				  AND bin_no = 'CDOCK' 

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

			FETCH NEXT FROM next_cd INTO @order_no, @order_ext, @cd_qty, @line_no, @tran_type			
		END

		DEALLOCATE next_cd				
	END

	IF (@qty > 0)
	BEGIN
		IF (@qc_flag = 'Y')
		BEGIN
			SELECT @tx_lock = 'Q'
			SELECT @qc_no = max(qc_no) 
			  FROM prod_list (nolock) 
			 WHERE prod_no = @prod_no
			   AND prod_ext = @prod_ext
			   AND part_no = @part_no
		END
 		ELSE
		BEGIN
			SELECT @tran_id = tran_id
			  FROM tdc_put_queue (nolock)
			 WHERE trans = 'WOPTWY'
			   AND location = @location 
			   AND trans_type_no = @prod_no
			   AND trans_type_ext = @prod_ext
			   AND part_no = @part_no 
			   AND lot = @lot 
			   AND bin_no = @bin_no
			   AND line_no = @line
			   AND tx_lock = 'R'
		END

		IF (@tran_id = 0)
		BEGIN
			EXEC @seq_no = tdc_queue_get_next_seq_num 'tdc_put_queue', @priority

			INSERT INTO tdc_put_queue (trans_source, trans, priority, seq_no, company_no, location, warehouse_no, 
						trans_type_no, trans_type_ext, tran_receipt_no, line_no, pcsn, part_no, eco_no,
						lot, mfg_lot, mfg_batch, serial_no, bin_no, qty_to_process, qty_processed, qty_short, next_op,
						tran_id_link, date_time, assign_group, assign_user_id, [user_id], status, tx_status, tx_control, tx_lock)
					VALUES('CO', 'WOPTWY', @priority, @seq_no, NULL, @location, NULL,
						@prod_no, @prod_ext, NULL, @line, NULL, @part_no, NULL, @lot, NULL, 
						NULL, NULL, @bin_no, @qty, 0, 0, NULL, @qc_no, GETDATE(), @assign_group,
						NULL, NULL, NULL, NULL, 'M', @tx_lock)
	
			SELECT @tran_id = MAX(tran_id) FROM tdc_put_queue (nolock)
		END
		ELSE
		BEGIN
			UPDATE tdc_put_queue 
			   SET qty_to_process = (qty_to_process + @qty), date_time = GETDATE() 
			 WHERE tran_id = @tran_id
		END
	END

RETURN @tran_id

END
GO
GRANT EXECUTE ON  [dbo].[tdc_queue_wo_putaway_sp] TO [public]
GO
