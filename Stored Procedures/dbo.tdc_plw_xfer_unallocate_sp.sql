SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 14/03/2013 - Issue #1167 - Allow ship comp holds to be unallocated  
-- v1.1 CB 04/12/2018 - #1687 Box Type Update
CREATE PROCEDURE  [dbo].[tdc_plw_xfer_unallocate_sp]   
 @user_id varchar(50)  
AS  
  
DECLARE @xfer_no  int,   
 @line_no  int,  
 @from_loc   varchar(10),  
 @to_loc   varchar(10),  
 @part_no  varchar(30),  
 @lot_ser  varchar(25),  
 @bin_no   varchar(12),  
 @qty_to_unallocate decimal(20,8),  
 @qty_to_process  decimal(20,8),  
 @tx_lock   char(2),  
 @prev_pct  decimal(20,8),
 @mfg_batch varchar(25) -- v1.0  
  
----------------------------------------------------------------------------------------------  
---- If nothing selected to unallocate, exit  
----------------------------------------------------------------------------------------------  
IF NOT EXISTS(SELECT *   
  FROM #xfer_alloc_management  
        WHERE sel_flg2 <> 0)  
RETURN  
  
IF EXISTS(SELECT line_no FROM #xfer_soft_alloc_byline_tbl)  
BEGIN  
 DECLARE UnAllocate_Cursor CURSOR FOR  
   
 SELECT order_no, b.from_loc, b.to_loc, a.line_no, a.part_no, lot_ser, bin_no, qty  
   FROM tdc_soft_alloc_tbl a (NOLOCK), #xfer_alloc_management b  
  WHERE a.order_no   = b.xfer_no  
    AND a.order_ext  = 0  
    AND a.location   = b.from_loc  
    AND a.order_type = 'T'  
    AND b.sel_flg2  != 0  
    AND a.line_no IN (SELECT line_no FROM #xfer_soft_alloc_byline_tbl)  
 END  
ELSE  
BEGIN  
 DECLARE UnAllocate_Cursor CURSOR FOR  
   
 SELECT order_no, b.from_loc, b.to_loc, a.line_no, a.part_no, lot_ser, bin_no, qty  
   FROM tdc_soft_alloc_tbl a (NOLOCK), #xfer_alloc_management b  
  WHERE a.order_no   = b.xfer_no  
    AND a.order_ext  = 0  
    AND a.location   = b.from_loc  
    AND a.order_type = 'T'  
    AND b.sel_flg2  != 0   
END  
  
OPEN UnAllocate_Cursor  
FETCH NEXT FROM UnAllocate_Cursor INTO @xfer_no, @from_loc, @to_loc, @line_no, @part_no, @lot_ser, @bin_no, @qty_to_unallocate  
       
WHILE (@@FETCH_STATUS = 0)   
BEGIN    
  
 IF EXISTS(SELECT line_no FROM #xfer_soft_alloc_byline_tbl)  
 BEGIN  
  SELECT @qty_to_process   = qty_to_process,  
         @tx_lock          = tx_lock,
		 @mfg_batch  = ISNULL(mfg_batch,'') -- v1.0
    FROM tdc_pick_queue (NOLOCK)  
   WHERE trans             IN('XFERPICK', 'XFER-CDOCK')  
     AND trans_type_no   = @xfer_no  
     AND trans_type_ext    = 0  
     AND location   = @from_loc   
     AND part_no       = @part_no  
     AND ISNULL(bin_no,'') = ISNULL(@bin_no, '')  
     AND ISNULL(lot,   '') = ISNULL(@lot_ser,'')  
     AND line_no      = @line_no  
     AND line_no IN (SELECT line_no FROM #xfer_soft_alloc_byline_tbl)  
 END  
 ELSE  
 BEGIN  
  SELECT @qty_to_process   = qty_to_process,  
         @tx_lock          = tx_lock,
		 @mfg_batch  = ISNULL(mfg_batch,'') -- v1.0   
    FROM tdc_pick_queue (NOLOCK)  
   WHERE trans             IN('XFERPICK', 'XFER-CDOCK')  
     AND trans_type_no   = @xfer_no  
     AND trans_type_ext    = 0  
     AND location   = @from_loc   
     AND part_no       = @part_no  
     AND ISNULL(bin_no,'') = ISNULL(@bin_no, '')  
     AND ISNULL(lot,   '') = ISNULL(@lot_ser,'')  
     AND line_no      = @line_no  
 END  
-- v1.0 Start
 IF NOT (@tx_lock = 'H' AND @mfg_batch = 'SHIP_COMP')
  BEGIN
	 IF @tx_lock NOT IN('R', 'V') OR (@qty_to_process < @qty_to_unallocate) 
	 BEGIN  
	  CLOSE      UnAllocate_Cursor  
	  DEALLOCATE UnAllocate_Cursor  
	  RAISERROR ('The queue has a pending transaction that is locked for Transfer# %d. You CANNOT unallocate this transfer.', 16, 1, @xfer_no)  
	  RETURN  
	 END  
 END
 -- v1.0 End 
 IF (@qty_to_process = @qty_to_unallocate)   
 BEGIN  
  IF EXISTS(SELECT line_no FROM #xfer_soft_alloc_byline_tbl)  
  BEGIN  
   DELETE FROM tdc_pick_queue  
    WHERE trans             IN('XFERPICK', 'XFER-CDOCK')  
                    AND trans_type_no   = @xfer_no  
      AND trans_type_ext    = 0       
      AND location   = @from_loc   
      AND part_no       = @part_no  
      AND ISNULL(bin_no,'') = ISNULL(@bin_no, '')  
      AND ISNULL(lot,   '') = ISNULL(@lot_ser,'')  
      AND line_no      = @line_no  
      AND line_no IN (SELECT line_no FROM #xfer_soft_alloc_byline_tbl)  
  END  
  ELSE  
  BEGIN  
   DELETE FROM tdc_pick_queue  
    WHERE trans             IN('XFERPICK', 'XFER-CDOCK')  
                    AND trans_type_no   = @xfer_no  
      AND trans_type_ext    = 0       
      AND location   = @from_loc   
      AND part_no       = @part_no  
      AND ISNULL(bin_no,'') = ISNULL(@bin_no, '')  
      AND ISNULL(lot,   '') = ISNULL(@lot_ser,'')  
      AND line_no      = @line_no  
  END  
  INSERT INTO tdc_log (tran_date, userid, trans_source, module, trans, tran_no, tran_ext,   
         part_no, lot_ser, bin_no, location, quantity, data)  
  SELECT getdate(), @user_id , 'VB', 'PLW', 'XFER UNALLOC', @xfer_no, 0,  
         @part_no, @lot_ser, @bin_no, @from_loc, @qty_to_unallocate, 'REMOVED from tdc_pick_queue. Line number = ' + CONVERT(VARCHAR(10), @line_no)  
  
 END  
 ELSE --@qty_to_process > @qty_to_unallocate  
 BEGIN  --Update the Qty_To_Process        
  IF EXISTS(SELECT line_no FROM #xfer_soft_alloc_byline_tbl)  
  BEGIN  
   UPDATE tdc_pick_queue  
      SET qty_to_process   = @qty_to_process - @qty_to_unallocate  
    WHERE trans             IN('XFERPICK', 'XFER-CDOCK')  
      AND trans_type_no   = @xfer_no  
      AND trans_type_ext    = 0       
      AND location   = @from_loc   
      AND part_no       = @part_no  
      AND ISNULL(bin_no,'') = ISNULL(@bin_no, '')  
      AND ISNULL(lot,   '') = ISNULL(@lot_ser,'')  
      AND line_no      = @line_no  
      AND line_no IN (SELECT line_no FROM #xfer_soft_alloc_byline_tbl)  
  END  
  ELSE  
  BEGIN  
   UPDATE tdc_pick_queue  
      SET qty_to_process   = @qty_to_process - @qty_to_unallocate  
    WHERE trans             IN('XFERPICK', 'XFER-CDOCK')  
      AND trans_type_no   = @xfer_no  
      AND trans_type_ext    = 0       
      AND location   = @from_loc   
      AND part_no       = @part_no  
      AND ISNULL(bin_no,'') = ISNULL(@bin_no, '')  
      AND ISNULL(lot,   '') = ISNULL(@lot_ser,'')  
      AND line_no      = @line_no  
  END  
  INSERT INTO tdc_log (tran_date, userid, trans_source, module, trans, tran_no, tran_ext,   
         part_no, lot_ser, bin_no, location, quantity, data)  
  SELECT getdate(), @user_id , 'VB', 'PLW', 'XFER UNALLOC', @xfer_no, 0,  
         @part_no, @lot_ser, @bin_no, @from_loc, @qty_to_unallocate, 'UPDATE tdc_pick_queue. Line number = ' + CONVERT(VARCHAR(10), @line_no)  
 END  
 IF EXISTS(SELECT line_no FROM #xfer_soft_alloc_byline_tbl)  
 BEGIN  
  DELETE FROM tdc_soft_alloc_tbl   
   WHERE order_no           = @xfer_no  
     AND order_ext          = 0  
     AND order_type         = 'T'  
     AND location    = @from_loc   
     AND line_no       = @line_no  
     AND part_no        = @part_no  
     AND ISNULL(bin_no, '') = ISNULL(@bin_no, '')  
     AND ISNULL(lot_ser,'') = ISNULL(@lot_ser,'')  
     AND line_no IN (SELECT line_no FROM #xfer_soft_alloc_byline_tbl)  
 END  
 ELSE  
 BEGIN  
  DELETE FROM tdc_soft_alloc_tbl   
   WHERE order_no           = @xfer_no  
     AND order_ext          = 0  
     AND order_type         = 'T'  
     AND location    = @from_loc   
     AND line_no       = @line_no  
     AND part_no        = @part_no  
     AND ISNULL(bin_no, '') = ISNULL(@bin_no, '')  
     AND ISNULL(lot_ser,'') = ISNULL(@lot_ser,'')  
 END  
 UPDATE tdc_alloc_history_tbl   
    SET fill_pct = curr_alloc_pct  
   FROM #xfer_alloc_management  
  WHERE #xfer_alloc_management.xfer_no   = @xfer_no  
    AND #xfer_alloc_management.from_loc  = @from_loc  
    AND #xfer_alloc_management.xfer_no   = tdc_alloc_history_tbl.order_no  
    AND #xfer_alloc_management.from_loc  = tdc_alloc_history_tbl.location  
    AND order_type = 'T'  

	-- v1.1 Start
	EXEC dbo. cvo_calculate_packaging_sp @xfer_no, 0, 'T'
	-- v1.1 End
  
 FETCH NEXT FROM UnAllocate_Cursor INTO @xfer_no, @from_loc, @to_loc, @line_no, @part_no, @lot_ser, @bin_no, @qty_to_unallocate  
END  
  
CLOSE     UnAllocate_Cursor  
DEALLOCATE UnAllocate_Cursor  
  
RETURN  
GO
GRANT EXECUTE ON  [dbo].[tdc_plw_xfer_unallocate_sp] TO [public]
GO
