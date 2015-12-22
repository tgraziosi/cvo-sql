SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE  [dbo].[cvo_plw_xfer_unallocate_sp]   
  @xfer_no INT, 
  @user_id varchar(50) 
AS  
  
DECLARE @line_no  int,  
		@from_loc   varchar(10),  
		@to_loc   varchar(10),  
		@part_no  varchar(30),  
		@lot_ser  varchar(25),  
		@bin_no   varchar(12),  
		@qty_to_unallocate decimal(20,8),  
		@qty_to_process  decimal(20,8),  
		@tx_lock   char(2),  
		@prev_pct  decimal(20,8),
		@mfg_batch	VARCHAR(25)  
    
 
 DECLARE UnAllocate_Cursor CURSOR FOR  
   
 SELECT 
	b.from_loc, b.to_loc, a.line_no, a.part_no, lot_ser, bin_no, qty  
 FROM 
	tdc_soft_alloc_tbl a (NOLOCK)
 INNER JOIN 
	dbo.xfers b (NOLOCK)
 ON 
	a.order_no   = b.xfer_no		 
 WHERE   
	a.order_ext  = 0  
	AND a.location   = b.from_loc  
	AND a.order_type = 'T'  
	AND b.xfer_no = @xfer_no
     
  
OPEN UnAllocate_Cursor  
FETCH NEXT FROM UnAllocate_Cursor INTO @from_loc, @to_loc, @line_no, @part_no, @lot_ser, @bin_no, @qty_to_unallocate  
       
WHILE (@@FETCH_STATUS = 0)   
BEGIN    
  
	SELECT 
		@qty_to_process   = qty_to_process,  
		@tx_lock          = tx_lock,
		@mfg_batch		  = mfg_batch   
	FROM 
		tdc_pick_queue (NOLOCK)  
	WHERE 
		trans             IN('XFERPICK', 'XFER-CDOCK')  
		AND trans_type_no   = @xfer_no  
		AND trans_type_ext    = 0  
		AND location   = @from_loc   
		AND part_no       = @part_no  
		AND ISNULL(bin_no,'') = ISNULL(@bin_no, '')  
		AND ISNULL(lot,   '') = ISNULL(@lot_ser,'')  
		AND line_no      = @line_no  
  
	--IF @tx_lock NOT IN('R', 'V') OR (@qty_to_process < @qty_to_unallocate)  
	IF (@tx_lock NOT IN('R', 'V') AND @mfg_batch <> 'SHIP_COMP') OR (@qty_to_process < @qty_to_unallocate)  
	BEGIN  
		CLOSE      UnAllocate_Cursor  
		DEALLOCATE UnAllocate_Cursor  
		RAISERROR ('The queue has a pending transaction that is locked for Transfer# %d. You CANNOT unallocate this transfer.', 16, 1, @xfer_no)  
		RETURN  
	END  
  
	IF (@qty_to_process = @qty_to_unallocate)   
	BEGIN  
		 
		DELETE FROM 
			tdc_pick_queue  
		WHERE 
			trans IN('XFERPICK', 'XFER-CDOCK')  
			AND trans_type_no   = @xfer_no  
			AND trans_type_ext    = 0       
			AND location   = @from_loc   
			AND part_no       = @part_no  
			AND ISNULL(bin_no,'') = ISNULL(@bin_no, '')  
			AND ISNULL(lot,   '') = ISNULL(@lot_ser,'')  
			AND line_no      = @line_no  

		INSERT INTO tdc_log (tran_date, userid, trans_source, module, trans, tran_no, tran_ext,   
		 part_no, lot_ser, bin_no, location, quantity, data)  
		SELECT getdate(), @user_id , 'VB', 'PLW', 'XFER UNALLOC', @xfer_no, 0,  
		 @part_no, @lot_ser, @bin_no, @from_loc, @qty_to_unallocate, 'REMOVED from tdc_pick_queue. Line number = ' + CONVERT(VARCHAR(10), @line_no)  
  
	END  
	ELSE --@qty_to_process > @qty_to_unallocate  
	BEGIN  --Update the Qty_To_Process        
	    
		UPDATE 
			tdc_pick_queue  
		SET 
			qty_to_process   = @qty_to_process - @qty_to_unallocate  
		WHERE 
			trans IN('XFERPICK', 'XFER-CDOCK')  
			AND trans_type_no   = @xfer_no  
			AND trans_type_ext    = 0       
			AND location   = @from_loc   
			AND part_no       = @part_no  
			AND ISNULL(bin_no,'') = ISNULL(@bin_no, '')  
			AND ISNULL(lot,   '') = ISNULL(@lot_ser,'')  
			AND line_no      = @line_no  

		INSERT INTO tdc_log (tran_date, userid, trans_source, module, trans, tran_no, tran_ext,   
		 part_no, lot_ser, bin_no, location, quantity, data)  
		SELECT getdate(), @user_id , 'VB', 'PLW', 'XFER UNALLOC', @xfer_no, 0,  
		 @part_no, @lot_ser, @bin_no, @from_loc, @qty_to_unallocate, 'UPDATE tdc_pick_queue. Line number = ' + CONVERT(VARCHAR(10), @line_no)  
	END  


	 
	DELETE FROM 
		tdc_soft_alloc_tbl   
	WHERE 
		order_no = @xfer_no  
		AND order_ext          = 0  
		AND order_type         = 'T'  
		AND location    = @from_loc   
		AND line_no       = @line_no  
		AND part_no        = @part_no  
		AND ISNULL(bin_no, '') = ISNULL(@bin_no, '')  
		AND ISNULL(lot_ser,'') = ISNULL(@lot_ser,'')  
 

	UPDATE 
		tdc_alloc_history_tbl   
	SET 
		fill_pct = 0  
	WHERE 
		order_no = @xfer_no
		AND location =  @from_loc
		AND order_type = 'T'  
			
  
	FETCH NEXT FROM UnAllocate_Cursor INTO @from_loc, @to_loc, @line_no, @part_no, @lot_ser, @bin_no, @qty_to_unallocate  
END  
  
CLOSE     UnAllocate_Cursor  
DEALLOCATE UnAllocate_Cursor  
  
RETURN  
GO
GRANT EXECUTE ON  [dbo].[cvo_plw_xfer_unallocate_sp] TO [public]
GO
