SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE  [dbo].[tdc_plw_wo_unallocate_sp] 
	@user_id varchar(50)
AS

DECLARE	@order_no		int,
	@order_ext		int,
	@line_no		int,
	@location 		varchar(10),
	@part_no		varchar(30),
	@lot_ser		varchar(25),
	@bin_no			varchar(12),
	@qty_to_unallocate	decimal(20,8),
	@qty_to_process 	decimal(20,8),
	@tx_lock 		char(2) 

----------------------------------------------------------------------------------------------
---- If nothing selected to unallocate, exit
----------------------------------------------------------------------------------------------
IF NOT EXISTS(SELECT * 
		FROM #wo_alloc_management
	       WHERE sel_flg2 <> 0)
RETURN

IF EXISTS(SELECT line_no FROM #wo_soft_alloc_byline_tbl)
	BEGIN
		DECLARE UnAllocate_Cursor CURSOR FOR
		
		SELECT order_no, order_ext, a.location, a.line_no, part_no, lot_ser, bin_no, qty
		  FROM tdc_soft_alloc_tbl a (NOLOCK), #wo_alloc_management b
		 WHERE a.order_no   = b.prod_no
		   AND a.order_ext  = b.prod_ext
		   AND a.location   = b.location
		   AND a.order_type = 'W'
		   AND b.sel_flg2  != 0
		   AND a.line_no IN (SELECT line_no FROM #wo_soft_alloc_byline_tbl)
	END
ELSE
	BEGIN
		DECLARE UnAllocate_Cursor CURSOR FOR
		
		SELECT order_no, order_ext, a.location, a.line_no, part_no, lot_ser, bin_no, qty
		  FROM tdc_soft_alloc_tbl a (NOLOCK), #wo_alloc_management b
		 WHERE a.order_no   = b.prod_no
		   AND a.order_ext  = b.prod_ext
		   AND a.location   = b.location
		   AND a.order_type = 'W'
		   AND b.sel_flg2  != 0
	END
OPEN UnAllocate_Cursor
FETCH NEXT FROM UnAllocate_Cursor INTO @order_no, @order_ext, @location, @line_no, @part_no, @lot_ser, @bin_no, @qty_to_unallocate
					
WHILE (@@FETCH_STATUS = 0) 
BEGIN  
	IF EXISTS(SELECT line_no FROM #wo_soft_alloc_byline_tbl)
	BEGIN
		SELECT @qty_to_process   = qty_to_process,
		       @tx_lock          = tx_lock 
		  FROM tdc_pick_queue (NOLOCK)
		 WHERE trans             IN('WOPPICK', 'WO-CDOCK')
		   AND trans_type_no 	 = @order_no
		   AND trans_type_ext    = @order_ext	    
		   AND location 	 = @location 
		   AND part_no 	   	 = @part_no
		   AND ISNULL(bin_no,'') = ISNULL(@bin_no, '')
		   AND ISNULL(lot,   '') = ISNULL(@lot_ser,'')
		   AND line_no	   	 = @line_no
		   AND line_no IN (SELECT line_no FROM #wo_soft_alloc_byline_tbl)
	END
	ELSE
	BEGIN
		SELECT @qty_to_process   = qty_to_process,
		       @tx_lock          = tx_lock 
		  FROM tdc_pick_queue (NOLOCK)
		 WHERE trans             IN('WOPPICK', 'WO-CDOCK')
		   AND trans_type_no 	 = @order_no
		   AND trans_type_ext    = @order_ext	    
		   AND location 	 = @location 
		   AND part_no 	   	 = @part_no
		   AND ISNULL(bin_no,'') = ISNULL(@bin_no, '')
		   AND ISNULL(lot,   '') = ISNULL(@lot_ser,'')
		   AND line_no	   	 = @line_no
	END

	IF @tx_lock NOT IN('R', 'V') OR (@qty_to_process < @qty_to_unallocate)
	BEGIN
		CLOSE      UnAllocate_Cursor
		DEALLOCATE UnAllocate_Cursor
		RAISERROR ('The queue has a pending transaction that is locked for Work Order# %d. You CANNOT unallocate this order.', 16, 1, @order_no)
		RETURN
	END

	IF (@qty_to_process = @qty_to_unallocate) 
	BEGIN
		IF EXISTS(SELECT line_no FROM #wo_soft_alloc_byline_tbl)
		BEGIN
			DELETE FROM tdc_pick_queue
			 WHERE  trans            IN('WOPPICK', 'WO-CDOCK')
			   AND trans_type_no 	 = @order_no
			   AND trans_type_ext    = @order_ext		   
			   AND location 	 = @location 
			   AND part_no 	   	 = @part_no
			   AND ISNULL(bin_no,'') = ISNULL(@bin_no, '')
			   AND ISNULL(lot,   '') = ISNULL(@lot_ser,'')
			   AND line_no	   	 = @line_no
			   AND line_no IN (SELECT line_no FROM #wo_soft_alloc_byline_tbl)
		END
		ELSE
		BEGIN
			DELETE FROM tdc_pick_queue
			 WHERE  trans            IN('WOPPICK', 'WO-CDOCK')
			   AND trans_type_no 	 = @order_no
			   AND trans_type_ext    = @order_ext		   
			   AND location 	 = @location 
			   AND part_no 	   	 = @part_no
			   AND ISNULL(bin_no,'') = ISNULL(@bin_no, '')
			   AND ISNULL(lot,   '') = ISNULL(@lot_ser,'')
			   AND line_no	   	 = @line_no
		END

		INSERT INTO tdc_log (tran_date, userid, trans_source, module, trans, tran_no, tran_ext, 
				     part_no, lot_ser, bin_no, location, quantity, data)
		SELECT getdate(), @user_id , 'VB', 'PLW', 'WO UNALLOC', @order_no, @order_ext,
		       @part_no, @lot_ser, @bin_no, @location, @qty_to_unallocate, 'REMOVED from tdc_pick_queue. Line number = ' + CONVERT(VARCHAR(10), @line_no)

	END
	ELSE --@qty_to_process > @qty_to_unallocate
	BEGIN  --Update the Qty_To_Process						
		IF EXISTS(SELECT line_no FROM #wo_soft_alloc_byline_tbl)
		BEGIN
			UPDATE tdc_pick_queue
			   SET qty_to_process 	 = @qty_to_process - @qty_to_unallocate
			 WHERE trans_type_no 	 = @order_no
			   AND trans_type_ext    = @order_ext
			   AND trans             IN('WOPPICK', 'WO-CDOCK')
			   AND location 	 = @location 
			   AND part_no 	   	 = @part_no
			   AND line_no	   	 = @line_no
			   AND ISNULL(bin_no,'') = ISNULL(@bin_no, '')
			   AND ISNULL(lot,   '') = ISNULL(@lot_ser,'')
			   AND line_no IN (SELECT line_no FROM #wo_soft_alloc_byline_tbl)
		END
		ELSE
		BEGIN
			UPDATE tdc_pick_queue
			   SET qty_to_process 	 = @qty_to_process - @qty_to_unallocate
			 WHERE trans_type_no 	 = @order_no
			   AND trans_type_ext    = @order_ext
			   AND trans             IN('WOPPICK', 'WO-CDOCK')
			   AND location 	 = @location 
			   AND part_no 	   	 = @part_no
			   AND line_no	   	 = @line_no
			   AND ISNULL(bin_no,'') = ISNULL(@bin_no, '')
			   AND ISNULL(lot,   '') = ISNULL(@lot_ser,'')
		END
		INSERT INTO tdc_log (tran_date, userid, trans_source, module, trans, tran_no, tran_ext, 
				     part_no, lot_ser, bin_no, location, quantity, data)
		SELECT getdate(), @user_id , 'VB', 'PLW', 'WO UNALLOC', @order_no, @order_ext,
		       @part_no, @lot_ser, @bin_no, @location, @qty_to_unallocate, 'UPDATE tdc_pick_queue. Line number = ' + CONVERT(VARCHAR(10), @line_no)
	END
	IF EXISTS(SELECT line_no FROM #wo_soft_alloc_byline_tbl)
	BEGIN
		DELETE FROM tdc_soft_alloc_tbl 
		 WHERE order_no           = @order_no
		   AND order_ext          = @order_ext
		   AND order_type         = 'W'
		   AND location 	  = @location 
		   AND line_no	   	  = @line_no
		   AND part_no 	   	  = @part_no
		   AND ISNULL(bin_no, '') = ISNULL(@bin_no, '')
		   AND ISNULL(lot_ser,'') = ISNULL(@lot_ser,'')
		   AND line_no IN (SELECT line_no FROM #wo_soft_alloc_byline_tbl)
	END
	ELSE
	BEGIN
		DELETE FROM tdc_soft_alloc_tbl 
		 WHERE order_no           = @order_no
		   AND order_ext          = @order_ext
		   AND order_type         = 'W'
		   AND location 	  = @location 
		   AND line_no	   	  = @line_no
		   AND part_no 	   	  = @part_no
		   AND ISNULL(bin_no, '') = ISNULL(@bin_no, '')
		   AND ISNULL(lot_ser,'') = ISNULL(@lot_ser,'')
	END

	UPDATE tdc_alloc_history_tbl 
	   SET fill_pct = curr_alloc_pct
	  FROM #wo_alloc_management
	 WHERE #wo_alloc_management.prod_no  = @order_no
	   AND #wo_alloc_management.prod_ext = @order_ext
	   AND #wo_alloc_management.location = @location
	   AND #wo_alloc_management.prod_no  = tdc_alloc_history_tbl.order_no
	   AND #wo_alloc_management.prod_ext = tdc_alloc_history_tbl.order_ext
	   AND #wo_alloc_management.location = tdc_alloc_history_tbl.location
	   AND order_type = 'W'

	FETCH NEXT FROM UnAllocate_Cursor INTO @order_no, @order_ext, @location, @line_no, @part_no, @lot_ser, @bin_no, @qty_to_unallocate
END

CLOSE 	   UnAllocate_Cursor
DEALLOCATE UnAllocate_Cursor

RETURN
GO
GRANT EXECUTE ON  [dbo].[tdc_plw_wo_unallocate_sp] TO [public]
GO
