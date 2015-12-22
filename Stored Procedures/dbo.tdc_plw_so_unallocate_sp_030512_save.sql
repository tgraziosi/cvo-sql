SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Stored Procedure      
-- v1.0 CB 20/02/2012 -- Allow SC Hold to be unallocated
-- v1.1 CB 20/02/2012 -- When unallocating - remove custom frame break lines
-- v1.2 CB 02/03/2012 -- When unallocating an order reset the status back to NEW
-- v1.3 tg March 5, 2012 -- comment out 1.2 reset stuff
      
CREATE PROCEDURE  [dbo].[tdc_plw_so_unallocate_sp_030512_save]       
 @user_id     VARCHAR(50),      
 @con_no  int        
AS      
      
DECLARE       
 @trans_source  VARCHAR(5),       
 @trans  VARCHAR(10),       
 @trans_type_no INT,      
 @order_no INT,       
 @order_ext INT,       
 @location VARCHAR(10),       
 @line_no INT,            
 @part_no VARCHAR(30),            
 @lot_ser VARCHAR(25),          
 @bin_no  VARCHAR(12),         
 @queue_qty DECIMAL(20,8),      
 @alloc_qty DECIMAL(20,8),      
 @tx_lock CHAR(2),      
 @next_op VARCHAR(50),      
 @target_bin     VARCHAR(12),      
 @tran_id INT,
 @mfg_batch varchar(25) -- v1.0      
----------------------------------------------------------------------------------------------      
---- If nothing selected to unallocate, exit      
----------------------------------------------------------------------------------------------      
IF NOT EXISTS(SELECT *       
  FROM #so_alloc_management      
        WHERE sel_flg2 <> 0)      
RETURN      
      
------------------------------------------------------------------------------------------------------------------------      
---- Build the cursor for unallocation of STDPICK's and SO-CDOCKS      
------------------------------------------------------------------------------------------------------------------------      
IF EXISTS(SELECT line_no FROM #so_soft_alloc_byline_tbl)      
BEGIN      
 DECLARE unalloc_cur CURSOR FAST_FORWARD FOR      
  SELECT p.trans_source, p.trans,  p.trans_type_no, s.order_no, s.order_ext, p.location, s.line_no,            
         p.part_no,      p.lot,    p.bin_no,        p.qty_to_process, s.qty,      p.tx_lock, p.next_op      
    FROM tdc_pick_queue       p (NOLOCK),      
         tdc_soft_alloc_tbl   s (NOLOCK),      
         #so_alloc_management t,      
         #so_soft_alloc_byline_tbl u      
  WHERE p.trans               IN('STDPICK', 'SO-CDOCK', 'PKGBLD')      
    AND t.sel_flg2     != 0      
    AND s.order_no      = t.order_no      
    AND s.order_ext           = t.order_ext      
    AND s.location       = t.location      
    AND s.order_type      = 'S'      
    AND s.part_no      = p.part_no      
    AND p.location      = t.location      
    AND p.line_no      = s.line_no        
    AND ISNULL(p.bin_no,'')   = ISNULL(s.bin_no ,'')      
    AND ISNULL(p.lot,   '')   = ISNULL(s.lot_ser ,'')      
    AND p.trans_type_no       = t.order_no       
    AND p.trans_type_ext      = t.order_ext      
    AND s.line_no      = u.line_no      
    AND s.part_no      = u.part_no      
END      
ELSE      
BEGIN      
 DECLARE unalloc_cur CURSOR FAST_FORWARD FOR      
  SELECT p.trans_source, p.trans,  p.trans_type_no, s.order_no, s.order_ext, p.location, s.line_no,            
         p.part_no,      p.lot,    p.bin_no,        p.qty_to_process, s.qty,      p.tx_lock, p.next_op      
  FROM tdc_pick_queue       p (NOLOCK),      
       tdc_soft_alloc_tbl   s (NOLOCK),      
       #so_alloc_management t      
  WHERE p.trans              IN ('STDPICK', 'SO-CDOCK', 'PKGBLD')      
    AND t.sel_flg2     != 0      
    AND s.order_no      = t.order_no      
    AND s.order_ext           = t.order_ext      
    AND s.location       = t.location      
    AND s.order_type      = 'S'      
    AND s.part_no      = p.part_no      
    AND p.location      = t.location      
    AND p.line_no      = s.line_no        
    AND ISNULL(p.bin_no,'')   = ISNULL(s.bin_no ,'')      
    AND ISNULL(p.lot,'')      = ISNULL(s.lot_ser ,'')      
    AND p.trans_type_no = t.order_no       
    AND p.trans_type_ext = t.order_ext       
END      
      
OPEN unalloc_cur      
FETCH NEXT FROM unalloc_cur INTO @trans_source, @trans,  @trans_type_no, @order_no, @order_ext, @location,  @line_no,            
            @part_no,      @lot_ser,    @bin_no,    @queue_qty, @alloc_qty, @tx_lock, @next_op      
WHILE @@FETCH_STATUS = 0      
BEGIN      
       
 ----------------------------------------------------------------------------------------------      
 ---- Make sure the transaction is not locked or in progress      
 ----------------------------------------------------------------------------------------------      
--BEGIN SED008 -- AutoAllocation      
--JVM 07/09/2010   
-- v1.0 Start
SELECT	@mfg_batch = mfg_batch
FROM	tdc_pick_queue (NOLOCK)
WHERE	trans_source = @trans_source
AND		trans = @trans
AND		trans_type_no = @trans_type_no
AND		trans_type_ext = @order_ext
AND		line_no = @line_no

IF NOT (@tx_lock = 'H' AND (PATINDEX('%SHIP_COMP%',@mfg_batch) > 0))
BEGIN
	 --IF ((@tx_lock NOT IN ('R', '3', 'P', 'V', 'L', 'G')) OR (@queue_qty < @alloc_qty))       
	 IF ((@tx_lock NOT IN ('R', '3', 'P', 'V', 'L', 'G', 'E')) OR (@queue_qty < @alloc_qty))  
	--END   SED008 -- AutoAllocation            
	 OR EXISTS (SELECT * FROM tdc_bin_master (NOLOCK)      
			 WHERE location = @location      
			AND bin_no   = @bin_no      
			AND (   usage_type_code = 'RECEIPT'       
		  OR usage_type_code = 'PRODOUT'))      
	 BEGIN      
	  CLOSE unalloc_cur      
	  DEALLOCATE unalloc_cur      
	  RAISERROR ('Pending Queue transaction on Sales Order %d-%d.', 16, 1, @order_no,@order_ext)      
	  RETURN      
	 END      
END -- v1.0 END       
      
 ----------------------------------------------------------------------------------------------      
 ---- Make sure NOTHING has been packed for the order ID PREPACK      
 ----------------------------------------------------------------------------------------------      
 IF EXISTS(SELECT *      
      FROM tdc_soft_alloc_tbl (NOLOCK)      
     WHERE order_no  = @order_no      
       AND order_ext = @order_ext      
       AND alloc_type = 'PR')      
 BEGIN      
  IF EXISTS(SELECT *       
       FROM tdc_carton_detail_tx (NOLOCK)      
      WHERE order_no  = @order_no      
        AND order_ext = @order_ext      
        AND pack_qty  > 0)      
  BEGIN      
   CLOSE unalloc_cur      
   DEALLOCATE unalloc_cur      
   RAISERROR ('Packing has started on Sales Order %d-%d.  You must unpick', 16, 1, @order_no,@order_ext)      
  END      
  ELSE      
  BEGIN      
   IF EXISTS(SELECT line_no FROM #so_soft_alloc_byline_tbl)      
   BEGIN      
    DELETE FROM tdc_carton_detail_tx       
    FROM tdc_carton_detail_tx a, #so_soft_alloc_byline_tbl b      
            WHERE a.order_no  = @order_no      
              AND a.order_ext = @order_ext      
       AND a.line_no      = b.line_no      
       AND a.part_no      = b.part_no      
       AND a.pack_qty = 0      
      
    DELETE FROM tdc_carton_tx      
     WHERE order_no  = @order_no      
       AND order_ext = @order_ext       
       AND carton_no NOT IN (SELECT carton_no FROM tdc_carton_detail_tx  (NOLOCK)      
               WHERE order_no  = @order_no      
                 AND order_ext = @order_ext)      
   END      
   ELSE      
   BEGIN      
    DELETE FROM tdc_carton_detail_tx       
            WHERE order_no  = @order_no      
              AND order_ext = @order_ext      
       AND pack_qty  = 0      
                
    DELETE FROM tdc_carton_tx      
     WHERE order_no  = @order_no      
       AND order_ext = @order_ext       
       AND carton_no NOT IN (SELECT carton_no FROM tdc_carton_detail_tx  (NOLOCK)      
               WHERE order_no  = @order_no      
                 AND order_ext = @order_ext)      
   END       
  END      
 END      
      
 ----------------------------------------------------------------------------------------------      
 ---- Lot/Bin Tracked parts       
 ----------------------------------------------------------------------------------------------       
 IF @lot_ser IS NOT NULL AND @bin_no IS NOT NULL      
 BEGIN      
      
  IF (@queue_qty - @alloc_qty) = 0      
  BEGIN        
   IF EXISTS(SELECT line_no FROM #so_soft_alloc_byline_tbl)      
   BEGIN      
    DELETE FROM tdc_pick_queue      
    FROM tdc_pick_queue a, #so_soft_alloc_byline_tbl b      
    WHERE  a.trans         = @trans           
    AND  a.trans_type_no  = @order_no       
    AND  a.trans_type_ext = @order_ext            
    AND  a.location       = @location           
    AND  a.part_no        = @part_no      
    AND  a.lot           = @lot_ser      
    AND  a.bin_no         = @bin_no           
    AND a.line_no        = @line_no      
    AND     a.trans_source   = @trans_source       
    AND  a.line_no   = b.line_no      
    AND  a.part_no   = b.part_no      
   END   
   ELSE      
   BEGIN      
    DELETE FROM tdc_pick_queue      
    WHERE  trans         = @trans           
    AND  trans_type_no  = @order_no       
    AND  trans_type_ext = @order_ext            
    AND  location       = @location           
    AND  part_no        = @part_no      
    AND  lot           = @lot_ser      
    AND  bin_no         = @bin_no           
    AND line_no        = @line_no      
    AND     trans_source   = @trans_source     
   END      
   INSERT INTO tdc_log (tran_date, UserID, trans_source, module, trans, tran_no,       
           tran_ext, part_no, lot_ser, bin_no, location, quantity, data)      
   SELECT getdate(), @user_id , 'VB', 'PLW', 'UNALLOCATION',@trans_type_no,      
          0, @part_no, @lot_ser, @bin_no, @location, @alloc_qty, 'REMOVED from tdc_pick_queue. Line number = ' + CONVERT(VARCHAR(10),@line_no)  

	-- v1.2 Remove custom frame breaks
	DELETE	tdc_pick_queue
	WHERE	trans         = 'MGTB2B'           
    AND		trans_type_no  = @order_no       
    AND		trans_type_ext = @order_ext            
    AND		location       = @location           
    AND		line_no        = @line_no      
    AND		trans_source   = 'MGT'  
    
               
  END --(@queue_qty - @alloc_qty) = 0      
  ELSE      
  BEGIN  --(@queue_qty - @alloc_qty) != 0      
   IF EXISTS(SELECT line_no FROM #so_soft_alloc_byline_tbl)      
   BEGIN      
    UPDATE tdc_pick_queue      
      SET qty_to_process =  (@queue_qty - @alloc_qty)      
    FROM tdc_pick_queue a, #so_soft_alloc_byline_tbl b      
    WHERE a.trans          = @trans           
    AND a.trans_type_no     = @order_no       
    AND a.trans_type_ext  = @order_ext      
    AND a.location         = @location       
    AND a.part_no  = @part_no      
    AND a.lot        = @lot_ser      
    AND a.bin_no     = @bin_no      
    AND a.line_no  = @line_no      
    AND a.trans_Source   = @trans_source       
    AND a.line_no   = b.line_no      
    AND a.part_no   = b.part_no      
   END      
   ELSE      
   BEGIN      
    UPDATE tdc_pick_queue      
    SET qty_to_process =  (@queue_qty - @alloc_qty)      
    WHERE trans          = @trans           
    AND trans_type_no     = @order_no       
    AND trans_type_ext  = @order_ext      
    AND location         = @location       
    AND part_no  = @part_no      
    AND lot        = @lot_ser      
    AND bin_no     = @bin_no      
    AND line_no  = @line_no      
    AND trans_Source   = @trans_source       
   END      
   INSERT INTO tdc_log (tran_date, UserID, trans_source, module, trans, tran_no,       
           tran_ext, part_no, lot_ser, bin_no, location, quantity, data)      
   SELECT getdate(), @user_id , 'VB', 'PLW', 'UNALLOCATION',@order_no,      
          @order_ext, @part_no, @lot_ser, @bin_no, @location, @alloc_qty, 'UPDATE the tdc_pick_queue. Line number = ' + CONVERT(VARCHAR(10),@line_no)      

	-- v1.2 Remove custom frame breaks
    UPDATE	tdc_pick_queue      
    SET		qty_to_process =  (@queue_qty - @alloc_qty)      
    WHERE	trans          = 'MGTB2B'           
    AND		trans_type_no     = @order_no       
    AND		trans_type_ext  = @order_ext      
    AND		location         = @location       
    AND		line_no  = @line_no      
    AND		trans_Source   = 'MGT' 
      
  END --(@queue_qty - @alloc_qty) != 0        
      
  IF EXISTS(SELECT line_no FROM #so_soft_alloc_byline_tbl)      
  BEGIN      
   DELETE tdc_soft_alloc_tbl      
   FROM tdc_soft_alloc_tbl a, #so_soft_alloc_byline_tbl b      
   WHERE a.order_no  = @order_no      
     AND a.order_ext = @order_ext      
     AND a.order_type = 'S'      
     AND a.location  = @location      
     AND a.line_no   = @line_no      
     AND a.part_no   = @part_no      
     AND a.lot_ser = @lot_ser      
     AND a.bin_no = @bin_no      
     AND a.line_no = b.line_no      
     AND a.part_no = b.part_no      
  END      
  ELSE      
  BEGIN      
   DELETE tdc_soft_alloc_tbl         
   WHERE order_no  = @order_no      
     AND order_ext = @order_ext      
     AND order_type = 'S'      
     AND location  = @location      
     AND line_no   = @line_no      
     AND part_no   = @part_no      
     AND lot_ser = @lot_ser      
     AND bin_no = @bin_no      
  END      
 END --LOT/BIN tracked part      
 ELSE      
 BEGIN --NON LOT/BIN tracked part      
 ----------------------------------------------------------------------------------------------      
 ---- NON Lot/Bin Tracked parts       
 ----------------------------------------------------------------------------------------------       
  IF (@queue_qty - @alloc_qty) = 0 --Delete from the queue      
  BEGIN          
   IF EXISTS(SELECT line_no FROM #so_soft_alloc_byline_tbl)      
   BEGIN      
    DELETE FROM tdc_pick_queue      
    FROM tdc_pick_queue a, #so_soft_alloc_byline_tbl b      
    WHERE  a.trans         = @trans           
    AND  a.trans_type_no  = @order_no       
    AND  a.trans_type_ext = @order_ext            
    AND  a.location       = @location           
    AND  a.part_no        = @part_no      
    AND  a.lot             IS NULL      
    AND  a.bin_no           IS NULL          
    AND a.line_no        = @line_no      
    AND  a.trans_source   = @trans_source       
    AND  a.line_no   = b.line_no      
    AND  a.part_no   = b.part_no      
   END      
   ELSE      
   BEGIN      
    DELETE FROM tdc_pick_queue      
    WHERE  trans         = @trans           
    AND  trans_type_no = @order_no       
    AND  trans_type_ext = @order_ext            
    AND  location       = @location           
    AND  part_no        = @part_no      
    AND  lot             IS NULL      
    AND  bin_no           IS NULL          
    AND line_no        = @line_no      
    AND  trans_source   = @trans_source       
   END      
      
   INSERT INTO tdc_log (tran_date, UserID, trans_source, module, trans, tran_no,       
           tran_ext, part_no, location, quantity, data)      
   SELECT getdate(), @user_id , 'VB', 'PLW', 'UNALLOCATION',@order_no,      
          @order_ext, @part_no, @location, @alloc_qty, 'REMOVED from tdc_pick_queue. Line number = ' + CONVERT(VARCHAR(10),@line_no)               
  END --(@queue_qty - @alloc_qty) = 0      
  ELSE      
  BEGIN  --(@queue_qty - @alloc_qty) != 0      
   --Update the Qty_To_Process            
   IF EXISTS(SELECT line_no FROM #so_soft_alloc_byline_tbl)      
   BEGIN      
    UPDATE tdc_pick_queue      
    SET qty_to_process =  (@queue_qty - @alloc_qty)      
    FROM tdc_pick_queue a, #so_soft_alloc_byline_tbl b      
    WHERE a.trans          = @trans           
    AND a.trans_type_no     = @order_no       
    AND a.trans_type_ext  = @order_ext      
    AND a.location         = @location       
    AND a.part_no  = @part_no      
    AND a.lot          IS NULL      
    AND a.bin_no       IS NULL      
    AND a.line_no  = @line_no      
    AND a.trans_Source   = @trans_source       
    AND a.line_no   = b.line_no      
    AND a.part_no   = b.part_no      
   END      
   ELSE      
   BEGIN      
    UPDATE tdc_pick_queue      
    SET qty_to_process =  (@queue_qty - @alloc_qty)      
    WHERE trans          = @trans           
    AND trans_type_no     = @order_no       
    AND trans_type_ext  = @order_ext      
    AND location         = @location       
    AND part_no  = @part_no      
    AND lot          IS NULL      
    AND bin_no       IS NULL      
    AND line_no  = @line_no      
    AND trans_Source   = @trans_source       
   END      
   INSERT INTO tdc_log (tran_date, UserID, trans_source, module, trans, tran_no,       
           tran_ext, part_no, location, quantity, data)      
   SELECT getdate(), @user_id , 'VB', 'PLW', 'UNALLOCATION',@order_no,      
          @order_ext, @part_no, @location, @alloc_qty, 'UPDATE the tdc_pick_queue. Line number = ' + CONVERT(VARCHAR(10),@line_no)      
      
  END --(@queue_qty - @alloc_qty) != 0       
      
  IF EXISTS(SELECT line_no FROM #so_soft_alloc_byline_tbl)      
  BEGIN      
   DELETE FROM tdc_soft_alloc_tbl      
   FROM tdc_soft_alloc_tbl a, #so_soft_alloc_byline_tbl b      
   WHERE a.order_no  = @order_no      
     AND a.order_ext = @order_ext      
     AND a.order_type = 'S'      
     AND a.location  = @location      
     AND a.line_no   = @line_no      
     AND a.part_no   = @part_no      
     AND a.lot_ser IS NULL      
     AND a.bin_no IS NULL      
     AND a.line_no = b.line_no      
     AND a.part_no = b.part_no      
  END      
  ELSE      
  BEGIN      
   DELETE FROM tdc_soft_alloc_tbl         
   WHERE order_no  = @order_no      
     AND order_ext = @order_ext      
     AND order_type = 'S'      
     AND location  = @location      
     AND line_no   = @line_no      
     AND part_no   = @part_no      
     AND lot_ser IS NULL      
     AND bin_no IS NULL      
  END      
 END --NON lb tracked      
-- 
--  -- v1.2 Reset the order status
--  UPDATE	orders_all 
--  SET		status = 'N', printed = 'N'
--  WHERE		order_no = @order_no
--  AND		ext = @order_ext
--  AND		status <> 'N'

      
 FETCH NEXT FROM unalloc_cur INTO @trans_source, @trans, @trans_type_no,  @order_no, @order_ext, @location,  @line_no,            
                    @part_no,      @lot_ser,    @bin_no,    @queue_qty, @alloc_qty, @tx_lock, @next_op      
      
END --@@FETCH_STATUS = 0      
      
CLOSE      unalloc_cur      
DEALLOCATE unalloc_cur      
       
------------------------------------------------------------------------------------------------------------------------      
---- Build the cursor for unallocation of PLWB2B's      
------------------------------------------------------------------------------------------------------------------------      
IF @con_no > 0      
BEGIN      
      
 DECLARE b2b_queue_cur CURSOR        
 FAST_FORWARD FOR      
  SELECT tran_id, location, part_no, lot, bin_no, SUM(qty_to_process)      
    FROM tdc_pick_queue (NOLOCK)      
   WHERE trans_type_no = @con_no      
     AND trans       = 'PLWB2B'      
   GROUP BY tran_id, location, part_no, lot, bin_no      
      
 OPEN b2b_queue_cur      
 FETCH NEXT FROM b2b_queue_cur INTO @tran_id, @location, @part_no, @lot_ser, @bin_no, @queue_qty      
      
 WHILE (@@FETCH_STATUS = 0)      
 BEGIN      
  IF EXISTS(SELECT line_no FROM #so_soft_alloc_byline_tbl)      
  BEGIN      
   DECLARE b2b_alloc_cur CURSOR      
   FAST_FORWARD FOR      
    SELECT a.order_no, a.order_ext, a.line_no, a.qty, a.target_bin      
      FROM tdc_soft_alloc_tbl   a (NOLOCK),      
           #so_alloc_management b,      
     #so_soft_alloc_byline_tbl c      
     WHERE a.order_no   = b.order_no      
       AND a.order_ext  = b.order_ext      
       AND a.order_type = 'S'      
       AND a.location   = b.location      
       AND a.location   = @location      
       AND a.part_no    = @part_no      
       AND a.lot_ser    = @lot_ser      
       AND a.bin_no     = @bin_no      
       AND b.sel_flg2  != 0      
       AND a.line_no = c.line_no      
       AND a.part_no = c.part_no      
  END      
  ELSE      
  BEGIN      
   DECLARE b2b_alloc_cur CURSOR      
   FAST_FORWARD FOR      
    SELECT a.order_no, a.order_ext, a.line_no, a.qty, a.target_bin      
      FROM tdc_soft_alloc_tbl   a (NOLOCK),      
           #so_alloc_management b      
     WHERE a.order_no   = b.order_no      
       AND a.order_ext  = b.order_ext      
       AND a.order_type = 'S'      
       AND a.location   = b.location      
       AND a.location   = @location      
       AND a.part_no    = @part_no      
       AND a.lot_ser    = @lot_ser      
       AND a.bin_no     = @bin_no      
       AND b.sel_flg2  != 0      
  END      
  OPEN b2b_alloc_cur      
  FETCH NEXT FROM b2b_alloc_cur INTO @order_no, @order_ext, @line_no, @alloc_qty, @target_bin      
      
  WHILE (@@FETCH_STATUS = 0 AND @queue_qty > 0)      
  BEGIN      
    IF @queue_qty > @alloc_qty      
   BEGIN      
    IF EXISTS(SELECT line_no FROM #so_soft_alloc_byline_tbl)      
    BEGIN      
     DELETE FROM tdc_soft_alloc_tbl      
      FROM tdc_soft_alloc_tbl a, #so_soft_alloc_byline_tbl b      
      WHERE a.order_no   = @order_no      
        AND a.order_ext  = @order_ext      
        AND a.order_type = 'S'      
        AND a.location   = @location      
        AND a.line_no    = @line_no      
        AND a.part_no    = @part_no      
        AND a.lot_ser    = @lot_ser      
        AND a.bin_no     = @bin_no      
         AND a.target_bin = @target_bin       
        AND a.line_no    = b.line_no      
        AND a.part_no    = b.part_no      
    END      
    ELSE      
    BEGIN      
     DELETE FROM tdc_soft_alloc_tbl      
      WHERE order_no   = @order_no      
        AND order_ext  = @order_ext      
        AND order_type = 'S'      
        AND location   = @location      
        AND line_no    = @line_no      
        AND part_no    = @part_no      
        AND lot_ser    = @lot_ser      
        AND bin_no     = @bin_no      
         AND target_bin = @target_bin       
    END      
    UPDATE tdc_pick_queue      
 SET qty_to_process = qty_to_process - @alloc_qty      
     WHERE tran_id = @tran_id      
      
    SELECT @queue_qty = @queue_qty - @alloc_qty      
   END      
   ELSE IF @queue_qty < @alloc_qty      
   BEGIN      
    IF EXISTS(SELECT line_no FROM #so_soft_alloc_byline_tbl)      
    BEGIN      
     UPDATE tdc_soft_alloc_tbl      
        SET qty        = qty - @queue_qty,      
            trg_off    = 1      
     FROM tdc_soft_alloc_tbl a, #so_soft_alloc_byline_tbl b      
      WHERE a.order_no   = @order_no      
        AND a.order_ext  = @order_ext      
        AND a.order_type = 'S'      
        AND a.location   = @location      
        AND a.line_no    = @line_no      
        AND a.part_no    = @part_no      
        AND a.lot_ser    = @lot_ser      
        AND a.bin_no     = @bin_no      
        AND a.target_bin = @target_bin       
        AND a.line_no    = b.line_no      
        AND a.part_no    = b.part_no      
           
     UPDATE tdc_soft_alloc_tbl      
        SET trg_off    = NULL      
     FROM tdc_soft_alloc_tbl a, #so_soft_alloc_byline_tbl b       
      WHERE a.order_no   = @order_no      
     AND a.order_ext  = @order_ext      
        AND a.order_type = 'S'      
        AND a.location   = @location      
        AND a.line_no    = @line_no      
        AND a.part_no    = @part_no      
        AND a.lot_ser    = @lot_ser      
        AND a.bin_no     = @bin_no      
        AND a.target_bin = @target_bin       
        AND a.line_no    = b.line_no      
        AND a.part_no    = b.part_no      
    END      
    ELSE      
    BEGIN      
     UPDATE tdc_soft_alloc_tbl      
        SET qty        = qty - @queue_qty,      
            trg_off    = 1      
      WHERE order_no   = @order_no      
        AND order_ext  = @order_ext      
        AND order_type = 'S'      
        AND location   = @location      
        AND line_no    = @line_no      
        AND part_no    = @part_no      
        AND lot_ser    = @lot_ser      
        AND bin_no     = @bin_no      
        AND target_bin = @target_bin       
      
     UPDATE tdc_soft_alloc_tbl      
        SET trg_off    = NULL      
      WHERE order_no   = @order_no      
        AND order_ext  = @order_ext      
        AND order_type = 'S'      
        AND location   = @location      
        AND line_no    = @line_no      
        AND part_no    = @part_no      
        AND lot_ser    = @lot_ser      
        AND bin_no     = @bin_no      
        AND target_bin = @target_bin       
    END      
      
    DELETE FROM tdc_pick_queue       
     WHERE tran_id = @tran_id      
      
    SELECT @queue_qty = 0      
   END      
   ELSE IF @queue_qty = @alloc_qty       
   BEGIN      
    IF EXISTS(SELECT line_no FROM #so_soft_alloc_byline_tbl)      
    BEGIN      
     DELETE FROM tdc_soft_alloc_tbl      
     FROM tdc_soft_alloc_tbl a , #so_soft_alloc_byline_tbl b      
      WHERE a.order_no   = @order_no      
        AND a.order_ext  = @order_ext      
        AND a.order_type = 'S'      
        AND a.location   = @location      
        AND a.line_no    = @line_no      
        AND a.part_no    = @part_no      
        AND a.lot_ser    = @lot_ser      
        AND a.bin_no     = @bin_no      
        AND a.target_bin = @target_bin       
        AND a.line_no    = b.line_no      
        AND a.part_no    = b.part_no      
    END      
    ELSE      
    BEGIN      
     DELETE FROM tdc_soft_alloc_tbl      
      WHERE order_no   = @order_no      
        AND order_ext  = @order_ext      
        AND order_type = 'S'      
        AND location   = @location      
        AND line_no    = @line_no      
        AND part_no    = @part_no      
        AND lot_ser    = @lot_ser      
        AND bin_no     = @bin_no      
        AND target_bin = @target_bin       
    END      
    DELETE FROM tdc_pick_queue       
     WHERE tran_id = @tran_id      
      
    SELECT @queue_qty = 0      
   END       
      
--	  -- v1.2 Reset the order status
--	  UPDATE	orders_all 
--	  SET		status = 'N', printed = 'N'
--	  WHERE		order_no = @order_no
--	  AND		ext = @order_ext
--	  AND		status <> 'N'


   FETCH NEXT FROM b2b_alloc_cur INTO @order_no, @order_ext, @line_no, @alloc_qty, @target_bin      
  END      
     
  CLOSE b2b_alloc_cur      
  DEALLOCATE b2b_alloc_cur      
      
  FETCH NEXT FROM b2b_queue_cur INTO @tran_id, @location, @part_no, @lot_ser, @bin_no, @queue_qty      
 END      
      
 CLOSE b2b_queue_cur      
 DEALLOCATE b2b_queue_cur      
END      
      
-- If One for One is selected during unallocation then lets remove those records from the tdc_cons_ords table      
-- and ALWAYS remove records from the       
-- 1.) tdc_cons_filter_set       
-- 2.) tdc_main       
-- tables where the consolidation_no no longer exists in tdc_cons_ords      
ELSE      
BEGIN      
 DELETE tdc_cons_ords       
   FROM tdc_cons_ords,      
        #so_alloc_management,      
        orders      
  WHERE tdc_cons_ords.order_no         = #so_alloc_management.order_no      
    AND tdc_cons_ords.order_ext        = #so_alloc_management.order_ext      
    AND tdc_cons_ords.location         = #so_alloc_management.location      
    AND tdc_cons_ords.order_type       = 'S'      
    AND #so_alloc_management.sel_flg2 != 0      
    AND orders.order_no         = #so_alloc_management.order_no      
    AND orders.ext        = #so_alloc_management.order_ext      
    AND orders.status        IN ('N', 'Q')      
    AND NOT EXISTS(select * from tdc_soft_alloc_tbl (NOLOCK) where order_no = #so_alloc_management.order_no and order_ext = #so_alloc_management.order_ext and location = #so_alloc_management.location)      
END      
      
UPDATE tdc_alloc_history_tbl       
SET fill_pct = curr_alloc_pct      
FROM #so_alloc_management      
WHERE #so_alloc_management.order_no = tdc_alloc_history_tbl.order_no      
AND #so_alloc_management.order_ext  = tdc_alloc_history_tbl.order_ext      
AND order_type = 'S'      
AND #so_alloc_management.location   = tdc_alloc_history_tbl.location      
      
IF NOT EXISTS(SELECT * FROM tdc_cons_ords(NOLOCK) WHERE consolidation_no = @con_no)      
BEGIN      
  DELETE FROM tdc_cons_filter_set WHERE consolidation_no = @con_no      
END      
RETURN 
GO
