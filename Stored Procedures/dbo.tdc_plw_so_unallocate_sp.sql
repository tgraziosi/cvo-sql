SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Stored Procedure      
-- v1.0 CB 20/02/2012 -- Allow SC Hold to be unallocated
-- v1.2 CB 20/02/2012 -- When unallocating - remove custom frame break lines
-- v1.3 CB 02/03/2012 -- When unallocating an order reset the status back to NEW
-- v10.1 CB 12/07/2012 - CVO-CF-1 - Custom Frame Processing
-- v10.2 CB 04/09/2012 - Issue #839 Alloc / UnAlloc associated cases etc when running by line
-- v1.5 CT 16/08/2012 -- Call new routine for autopack stock orders
-- v1.6 CB 10/10/2012 - Fix issue of tdc_soft_alloc record not being deleted when qty left = 0
-- v1.7 CB 15/10/2012 -- When unallocating the tdc_log is not being populated with the correct ext number
-- v1.8 CB 21/12/2012 - When unallocating reinstate the cvo_soft_alloc_records
-- v1.9 CB 02/01/2013 - When unallocating ensure the status is reset correctly
-- v2.0 CB 20/03/2013 - add case flag to cvo_soft_alloc_det
-- v2.1 CB 21/03/2013 - add case adjust to cvo_soft_alloc_det
-- v2.2 CB 22/03/2013 - fix issue when unallocating by line, associated cases not being added back into soft alloc
-- v2.3 CB 22/03/2013 - for audit purposes - identify if the unallocation was by line
-- v2.4 CB 09/05/2013 - Performance
-- v2.5 CB 06/06/2013 - Issue #1286 - Ship complete processing
-- v2.6 CB 11/06/2013 - Issue #965 - Tax Calculation
-- v2.7 CB 04/07/2013 - Issue #1325 - Keep soft alloc no
-- v2.8 CB 26/07/2013 - Issue when unallocating a line on a part picked order - need to take into account shipped qty
-- v2.9 CB 04/02/2014 - Issue #1358 - Remove call to ship complete hold
-- v3.0 CB 22/09/2014 - #572 Masterpack - Stock Order Consolidation
-- v3.1 CB 31/07/2015 - Rebuild consolidated picks
-- v3.2 CB 24/08/2016 - CVO-CF-49 - Dynamic Custom Frames
      
CREATE PROCEDURE  [dbo].[tdc_plw_so_unallocate_sp]       
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
 @mfg_batch varchar(25), -- v1.0      
 @unalloc_type varchar(30), -- v2.3
 @iret int, -- v2.5
 @err_ret int, -- v2.6
 @consolidation_no int -- v3.1

-- v10.1
DECLARE	@t_bin_no	varchar(12),
		@t_next_op	varchar(12),
		@t_qty		decimal(20,8),
		@qty_override decimal(20,8), -- v10.2
		@sa_qty		decimal(20,8), -- v10.2
		@cur_status int -- v1.9
		
-- v2.4 Start
DECLARE	@row_id				int,
		@last_row_id		int,
		@line_row_id		int,
		@last_line_row_id	int
-- v2.4 End
----------------------------------------------------------------------------------------------      
---- If nothing selected to unallocate, exit      
----------------------------------------------------------------------------------------------      
IF NOT EXISTS(SELECT *       
  FROM #so_alloc_management      
        WHERE sel_flg2 <> 0)      
RETURN      


-- v2.4 Start
CREATE TABLE #plw_unalloc_cur (
	row_id			int IDENTITY(1,1),
	trans_source	varchar(5),
	trans			varchar(10),
	trans_type_no	int,
	order_no		int,
	order_ext		int,
	location		varchar(10),
	line_no			int,
	part_no			varchar(30),
	lot				varchar(25),
	bin_no			varchar(12),
	qty_to_process	decimal(20,8),
	qty				decimal(20,8),
	tx_lock			char(2),
	next_op			varchar(30))	

------------------------------------------------------------------------------------------------------------------------      
---- Build the cursor for unallocation of STDPICK's and SO-CDOCKS      
------------------------------------------------------------------------------------------------------------------------      

IF EXISTS(SELECT line_no FROM #so_soft_alloc_byline_tbl)      
BEGIN      

 SET @unalloc_type = 'UnAllocate By Line: ' -- v2.3


 -- v10.2 Use override quantity if set
-- DECLARE unalloc_cur CURSOR FAST_FORWARD FOR      
INSERT	#plw_unalloc_cur (trans_source, trans, trans_type_no, order_no, order_ext, location, line_no, part_no, 
							lot, bin_no, qty_to_process, qty, tx_lock, next_op)
  SELECT p.trans_source, p.trans,  p.trans_type_no, s.order_no, s.order_ext, p.location, s.line_no,            
         p.part_no,      p.lot,    p.bin_no,        p.qty_to_process, s.qty,      
		 p.tx_lock, p.next_op      
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

 SET @unalloc_type = 'UnAllocate Order: ' -- v2.3
  
 --DECLARE unalloc_cur CURSOR FAST_FORWARD FOR      
INSERT	#plw_unalloc_cur (trans_source, trans, trans_type_no, order_no, order_ext, location, line_no, part_no, 
							lot, bin_no, qty_to_process, qty, tx_lock, next_op)
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
      
--OPEN unalloc_cur      
--FETCH NEXT FROM unalloc_cur INTO @trans_source, @trans,  @trans_type_no, @order_no, @order_ext, @location,  @line_no,            
--            @part_no,      @lot_ser,    @bin_no,    @queue_qty, @alloc_qty, @tx_lock, @next_op      
--WHILE @@FETCH_STATUS = 0      
--BEGIN      
  
SET @last_row_id = 0 

SELECT	TOP 1 @row_id = row_id,
		@trans_source = trans_source, 
		@trans = trans,  
		@trans_type_no = trans_type_no, 
		@order_no = order_no, 
		@order_ext = order_ext, 
		@location = location,  
		@line_no = line_no,            
		@part_no = part_no,
		@lot_ser = lot,    
		@bin_no = bin_no, 
		@queue_qty = qty_to_process, 
		@alloc_qty = qty, 
		@tx_lock = tx_lock, 
		@next_op = next_op
FROM	#plw_unalloc_cur
WHERE	row_id > @last_row_id
ORDER BY row_id ASC

WHILE (@@ROWCOUNT <> 0)
BEGIN

-- v2.4 End     
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

-- v10.2
IF NOT EXISTS (SELECT 1 FROM #so_soft_alloc_byline_tbl WHERE order_no = @order_no AND order_ext = @order_ext AND line_no = @line_no AND qty_override <> 0)
BEGIN
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
		  -- v2.4 Start  
--		  CLOSE unalloc_cur      
--		  DEALLOCATE unalloc_cur      
		  DROP TABLE #plw_unalloc_cur
		  -- v2.4 End
		  RAISERROR ('Pending Queue transaction on Sales Order %d-%d.', 16, 1, @order_no,@order_ext)      
		  RETURN      
		 END      
	END -- v1.0 END       
END -- v10.2 End      
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
  -- v2.4 Start
--   CLOSE unalloc_cur      
--   DEALLOCATE unalloc_cur      
	-- v2.4 End
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

 -- v10.2 Get override qty
	IF EXISTS(SELECT line_no FROM #so_soft_alloc_byline_tbl)      
	BEGIN
		SELECT	@alloc_qty = qty_override
		FROM	#so_soft_alloc_byline_tbl
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext
		AND		line_no = @line_no
		AND		qty_override <> 0
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
          @order_ext, @part_no, @lot_ser, @bin_no, @location, @alloc_qty, @unalloc_type + 'REMOVED from tdc_pick_queue. Line number = ' + CONVERT(VARCHAR(10),@line_no)  -- v1.7 v2.3

	-- v1.2 Remove custom frame breaks
	-- v10.1 Start
	IF EXISTS (SELECT 1 FROM tdc_pick_queue (NOLOCK) WHERE trans_type_no = @order_no AND trans_type_ext = @order_ext 
				AND part_no = @part_no AND line_no = @line_no AND trans = 'MGTB2B')
	BEGIN			
		UPDATE	a
		SET		qty = a.qty - b.qty_to_process
		FROM	tdc_soft_alloc_tbl a
		JOIN	tdc_pick_queue b (NOLOCK)
		ON		a.location = b.location
		AND		a.part_no = b.part_no
		AND		a.bin_no = b.bin_no
		AND		a.target_bin = b.next_op
		WHERE	b.trans_type_no = @order_no 
		AND		b.trans_type_ext = @order_ext 
		AND		b.trans = 'MGTB2B'
		AND		b.line_no = @line_no
		AND		a.order_type = 'S'
		AND		a.order_no = 0

		DELETE	tdc_soft_alloc_tbl
		WHERE	location = @location
		AND		order_no = 0
		AND		order_type = 'S'
		AND		qty <= 0

	END
	-- v10.1 End

	DELETE	tdc_pick_queue
	WHERE	trans         = 'MGTB2B'           
    AND		trans_type_no  = @order_no       
    AND		trans_type_ext = @order_ext            
    AND		location       = @location           
    AND		line_no        = @line_no      
    AND		trans_source   = 'MGT'  

	-- v3.2 Start
	DELETE	tdc_pick_queue
	WHERE	trans         = 'STDPICK'           
    AND		trans_type_no  = @order_no       
    AND		trans_type_ext = @order_ext            
    AND		location       = @location           
    AND		line_no        = @line_no      
    AND		trans_source   = 'PLW'
	AND		company_no = 'CF'
	-- v3.2 End
               
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
          @order_ext, @part_no, @lot_ser, @bin_no, @location, @alloc_qty, @unalloc_type + 'UPDATE the tdc_pick_queue. Line number = ' + CONVERT(VARCHAR(10),@line_no) -- v2.3    

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
	 AND b.qty_override = 0 -- v10.2

	-- v10.2 Need to update the qtys in tdc_soft_alloc but it may come from multiple bins
	SELECT	@qty_override = qty_override
	FROM	#so_soft_alloc_byline_tbl
	WHERE	order_no  = @order_no      
    AND		order_ext = @order_ext      
    AND		line_no = @line_no      
    AND		part_no = @part_no  

	IF (@qty_override <> 0)
	BEGIN

		SELECT	@sa_qty = qty 
		FROM	tdc_soft_alloc_tbl (NOLOCK) 
		WHERE	order_no = @order_no 
		AND		order_ext = @order_ext 
		AND		line_no = @line_no 
		AND		part_no = @part_no
		AND		bin_no = @bin_no

-- v1.6		IF (@qty_override > @sa_qty AND @qty_override <> 0) -- Consume all
		IF (@qty_override >= @sa_qty AND @qty_override <> 0) -- Consume all -- v1.6
		BEGIN
			DELETE	tdc_soft_alloc_tbl      
			FROM	tdc_soft_alloc_tbl a, #so_soft_alloc_byline_tbl b      
			WHERE	a.order_no  = @order_no      
			AND		a.order_ext = @order_ext      
			AND		a.order_type = 'S'      
			AND		a.location  = @location      
			AND		a.line_no   = @line_no      
			AND		a.part_no   = @part_no      
			AND		a.lot_ser = @lot_ser      
			AND		a.bin_no = @bin_no      
			AND		a.line_no = b.line_no      
			AND		a.part_no = b.part_no		
		
			UPDATE	#so_soft_alloc_byline_tbl
			SET		qty_override = qty_override - @qty_override -- v2.2 @sa_qty
			WHERE	order_no  = @order_no      
			AND		order_ext = @order_ext      
			AND		line_no = @line_no      
			AND		part_no = @part_no 
		END
		ELSE -- Consume partial
		BEGIN
			UPDATE	a
			SET		qty = qty - @qty_override,
					trg_off    = 1   
			FROM	tdc_soft_alloc_tbl a, #so_soft_alloc_byline_tbl b      
			WHERE	a.order_no  = @order_no      
			AND		a.order_ext = @order_ext      
			AND		a.order_type = 'S'      
			AND		a.location  = @location      
			AND		a.line_no   = @line_no      
			AND		a.part_no   = @part_no      
			AND		a.lot_ser = @lot_ser      
			AND		a.bin_no = @bin_no      
			AND		a.line_no = b.line_no      
			AND		a.part_no = b.part_no		

			UPDATE	a
			SET		trg_off    = NULL
			FROM	tdc_soft_alloc_tbl a, #so_soft_alloc_byline_tbl b      
			WHERE	a.order_no  = @order_no      
			AND		a.order_ext = @order_ext      
			AND		a.order_type = 'S'      
			AND		a.location  = @location      
			AND		a.line_no   = @line_no      
			AND		a.part_no   = @part_no      
			AND		a.lot_ser = @lot_ser      
			AND		a.bin_no = @bin_no      
			AND		a.line_no = b.line_no      
			AND		a.part_no = b.part_no		

		
			UPDATE	#so_soft_alloc_byline_tbl
			SET		qty_override = qty_override - @qty_override -- v2.2 @sa_qty
			WHERE	order_no  = @order_no      
			AND		order_ext = @order_ext      
			AND		line_no = @line_no      
			AND		part_no = @part_no 
		END


	END
		-- v10.2 End
      
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
          @order_ext, @part_no, @location, @alloc_qty, @unalloc_type + 'REMOVED from tdc_pick_queue. Line number = ' + CONVERT(VARCHAR(10),@line_no) -- v2.3              
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
          @order_ext, @part_no, @location, @alloc_qty, @unalloc_type + 'UPDATE the tdc_pick_queue. Line number = ' + CONVERT(VARCHAR(10),@line_no) -- v2.3      
      
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
 
  -- v1.3 Reset the order status
  UPDATE	orders_all 
  SET		status = 'N', printed = 'N'
  FROM		orders_all a (NOLOCK)
  LEFT JOIN tdc_soft_alloc_tbl b (NOLOCK)
  ON		a.order_no = b.order_no
  AND		a.ext = b.order_ext
  WHERE		a.order_no = @order_no
  AND		a.ext = @order_ext
  AND		a.status = 'Q'
  AND		b.order_no IS NULL
      
 -- START v1.5 - rebuild cartons for this order
 EXEC dbo.CVO_build_autopack_carton_sp @order_no, @order_ext
 -- END v1.5

	-- v2.6 Start
	IF NOT EXISTS (SELECT 1 FROM tdc_pick_queue (NOLOCK) WHERE trans_type_no = @order_no AND trans_type_ext = @order_ext AND trans = 'STDPICK')
		AND EXISTS (SELECT 1 FROM orders_all (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext AND status = 'P')
	BEGIN
		 EXEC dbo.fs_calculate_oetax @order_no, @order_ext, @err_ret OUT  	   
		   
		 EXEC dbo.fs_updordtots @order_no, @order_ext     
	END
	-- v2.6 End  



 -- v2.4 Start

	SET @last_row_id = @row_id 

	SELECT	TOP 1 @row_id = row_id,
			@trans_source = trans_source, 
			@trans = trans,  
			@trans_type_no = trans_type_no, 
			@order_no = order_no, 
			@order_ext = order_ext, 
			@location = location,  
			@line_no = line_no,            
			@part_no = part_no,
			@lot_ser = lot,    
			@bin_no = bin_no, 
			@queue_qty = qty_to_process, 
			@alloc_qty = qty, 
			@tx_lock = tx_lock, 
			@next_op = next_op
	FROM	#plw_unalloc_cur
	WHERE	row_id > @last_row_id
	ORDER BY row_id ASC

-- FETCH NEXT FROM unalloc_cur INTO @trans_source, @trans, @trans_type_no,  @order_no, @order_ext, @location,  @line_no,            
--                    @part_no,      @lot_ser,    @bin_no,    @queue_qty, @alloc_qty, @tx_lock, @next_op      
      
END --@@FETCH_STATUS = 0      
      
--CLOSE      unalloc_cur      
--DEALLOCATE unalloc_cur      
DROP TABLE #plw_unalloc_cur
-- v2.4 End

      
------------------------------------------------------------------------------------------------------------------------      
---- Build the cursor for unallocation of PLWB2B's      
------------------------------------------------------------------------------------------------------------------------      
IF @con_no > 0      
BEGIN      

-- v2.4 Start
CREATE TABLE #plw_b2b_queue_cur (
	row_id			int IDENTITY(1,1),
	tran_id			int, 
	location		varchar(10), 
	part_no			varchar(30), 
	lot				varchar(25), 
	bin_no			varchar(20), 
	qty_to_process	decimal(20,8))

CREATE TABLE #plw_b2b_alloc_cur (
	line_row_id		int IDENTITY(1,1),
	order_no		int,
	order_ext		int,
	line_no			int,
	qty				decimal(20,8),
	target_bin		varchar(20))


INSERT #plw_b2b_queue_cur (tran_id, location, part_no, lot, bin_no, qty_to_process) 
  SELECT tran_id, location, part_no, lot, bin_no, SUM(qty_to_process)      
    FROM tdc_pick_queue (NOLOCK)      
   WHERE trans_type_no = @con_no      
     AND trans       = 'PLWB2B'      
   GROUP BY tran_id, location, part_no, lot, bin_no      

CREATE INDEX #plw_b2b_queue_cur_ind0 ON #plw_b2b_queue_cur(row_id)
      
-- DECLARE b2b_queue_cur CURSOR        
-- FAST_FORWARD FOR      
--  SELECT tran_id, location, part_no, lot, bin_no, SUM(qty_to_process)      
--    FROM tdc_pick_queue (NOLOCK)      
--   WHERE trans_type_no = @con_no      
--     AND trans       = 'PLWB2B'      
--   GROUP BY tran_id, location, part_no, lot, bin_no      
--      
-- OPEN b2b_queue_cur      
-- FETCH NEXT FROM b2b_queue_cur INTO @tran_id, @location, @part_no, @lot_ser, @bin_no, @queue_qty      
--      
-- WHILE (@@FETCH_STATUS = 0)      
-- BEGIN      

SET @last_row_id = 0

SELECT	TOP 1 @row_id = row_id,
		@tran_id = tran_id, 
		@location = location, 
		@part_no = part_no, 
		@lot_ser = lot, 
		@bin_no = bin_no, 
		@queue_qty = qty_to_process
FROM	#plw_b2b_queue_cur  
WHERE	row_id > @last_row_id
ORDER BY row_id ASC

WHILE (@@ROWCOUNT <> 0)
BEGIN

	DELETE #plw_b2b_alloc_cur


  IF EXISTS(SELECT line_no FROM #so_soft_alloc_byline_tbl)      
  BEGIN   
	INSERT #plw_b2b_alloc_cur (order_no, order_ext, line_no, qty, target_bin)
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
   
--   DECLARE b2b_alloc_cur CURSOR      
--   FAST_FORWARD FOR      
--    SELECT a.order_no, a.order_ext, a.line_no, a.qty, a.target_bin      
--      FROM tdc_soft_alloc_tbl   a (NOLOCK),      
--           #so_alloc_management b,      
--     #so_soft_alloc_byline_tbl c      
--     WHERE a.order_no   = b.order_no      
--       AND a.order_ext  = b.order_ext      
--       AND a.order_type = 'S'      
--       AND a.location   = b.location      
--       AND a.location   = @location      
--       AND a.part_no    = @part_no      
--       AND a.lot_ser    = @lot_ser      
--       AND a.bin_no     = @bin_no      
--       AND b.sel_flg2  != 0      
--       AND a.line_no = c.line_no      
--       AND a.part_no = c.part_no      
  END      
  ELSE      
  BEGIN      
	INSERT #plw_b2b_alloc_cur (order_no, order_ext, line_no, qty, target_bin)
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

--   DECLARE b2b_alloc_cur CURSOR      
--   FAST_FORWARD FOR      
--    SELECT a.order_no, a.order_ext, a.line_no, a.qty, a.target_bin      
--      FROM tdc_soft_alloc_tbl   a (NOLOCK),      
--           #so_alloc_management b      
--     WHERE a.order_no   = b.order_no      
--       AND a.order_ext  = b.order_ext      
--       AND a.order_type = 'S'      
--       AND a.location   = b.location      
--       AND a.location   = @location      
--       AND a.part_no    = @part_no      
--       AND a.lot_ser    = @lot_ser      
--       AND a.bin_no     = @bin_no      
--       AND b.sel_flg2  != 0      
  END   

	SET @last_line_row_id = 0

	SELECT	TOP 1 @line_row_id = line_row_id,
			@order_no = order_no, 
			@order_ext = order_ext, 
			@line_no = line_no, 
			@alloc_qty = qty, 
			@target_bin = target_bin
	FROM	#plw_b2b_alloc_cur
	WHERE	line_row_id > @last_line_row_id
	ORDER BY line_row_id ASC

	WHILE ((@@ROWCOUNT <> 0) AND @queue_qty > 0)
	BEGIN
   
--  OPEN b2b_alloc_cur      
--  FETCH NEXT FROM b2b_alloc_cur INTO @order_no, @order_ext, @line_no, @alloc_qty, @target_bin      
      
--  WHILE (@@FETCH_STATUS = 0 AND @queue_qty > 0)      
--  BEGIN  
	-- v2.4 End

    
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
      
	  -- v1.3 Reset the order status
  UPDATE	orders_all 
  SET		status = 'N', printed = 'N'
  FROM		orders_all a (NOLOCK)
  LEFT JOIN tdc_soft_alloc_tbl b (NOLOCK)
  ON		a.order_no = b.order_no
  AND		a.ext = b.order_ext
  WHERE		a.order_no = @order_no
  AND		a.ext = @order_ext
  AND		a.status = 'Q'
  AND		b.order_no IS NULL

	-- v2.4 Start
	SET @last_line_row_id = @line_row_id

	SELECT	TOP 1 @line_row_id = line_row_id,
			@order_no = order_no, 
			@order_ext = order_ext, 
			@line_no = line_no, 
			@alloc_qty = qty, 
			@target_bin = target_bin
	FROM	#plw_b2b_alloc_cur
	WHERE	line_row_id > @last_line_row_id
	ORDER BY line_row_id ASC

--   FETCH NEXT FROM b2b_alloc_cur INTO @order_no, @order_ext, @line_no, @alloc_qty, @target_bin      
  END      
     
--  CLOSE b2b_alloc_cur      
--  DEALLOCATE b2b_alloc_cur      

	SET @last_row_id = @row_id

	SELECT	TOP 1 @row_id = row_id,
			@tran_id = tran_id, 
			@location = location, 
			@part_no = part_no, 
			@lot_ser = lot, 
			@bin_no = bin_no, 
			@queue_qty = qty_to_process
	FROM	#plw_b2b_queue_cur  
	WHERE	row_id > @last_row_id
	ORDER BY row_id ASC
      
--  FETCH NEXT FROM b2b_queue_cur INTO @tran_id, @location, @part_no, @lot_ser, @bin_no, @queue_qty      
 END      
      

-- CLOSE b2b_queue_cur      
-- DEALLOCATE b2b_queue_cur      
	DROP TABLE #plw_b2b_queue_cur
	DROP TABLE #plw_b2b_alloc_cur
-- v2.4 End
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

-- v1.8 Start 
DECLARE	@sa_count	int, 
		@new_soft_alloc_no int,
		@id			int,
		@last_id	int

CREATE TABLE #tmp_alloc (
		line_no		int,
		qty			decimal(20,8))

CREATE TABLE #tmp_orders_to_process (
		id			int IDENTITY(1,1),
		order_no	int,
		order_ext	int,
		location	varchar(10))

-- v3.0 Start
-- Remove stock consolidated pick record
DELETE	a
FROM	tdc_pick_queue a
JOIN	cvo_masterpack_consolidation_picks b (NOLOCK)
ON		a.tran_id = b.parent_tran_id
JOIN	#so_alloc_management c
ON		c.mp_consolidation_no = b.consolidation_no
WHERE	c.sel_flg2 != 0      

DELETE	b
FROM	cvo_masterpack_consolidation_picks b (NOLOCK)
JOIN	#so_alloc_management c
ON		c.mp_consolidation_no = b.consolidation_no
WHERE	c.sel_flg2 != 0      
-- v3.0 End

-- v3.1 Start
IF OBJECT_ID('tempdb..#consolidate_picks') IS NOT NULL
	DROP TABLE #consolidate_picks

CREATE TABLE #consolidate_picks(  
	consolidation_no	int,  
	order_no			int,  
	ext					int) 
-- v3.1 End

INSERT	#tmp_orders_to_process (order_no, order_ext, location)
SELECT	order_no, order_ext, location
FROM	#so_alloc_management
WHERE	sel_flg2 != 0      
ORDER BY order_no, order_ext

SET @last_id = 0

SELECT	TOP 1 @id = id,
		@order_no = order_no,
		@order_ext = order_ext,
		@location = location
FROM	#tmp_orders_to_process
WHERE	id > @last_id
ORDER BY id ASC

WHILE @@ROWCOUNT <> 0
BEGIN

	-- v1.9 Start
	SET @cur_status = 0

	IF EXISTS (SELECT 1 FROM cvo_soft_alloc_hdr (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND status = -3)
		SET @cur_status = -3
	-- v1.9 End

	TRUNCATE TABLE #tmp_alloc

	INSERT	#tmp_alloc
	SELECT	line_no, SUM(qty)
	FROM	tdc_soft_alloc_tbl (NOLOCK)
	WHERE	order_no = @order_no
	AND		order_ext= @order_ext
	GROUP BY line_no

--	SELECT @sa_count = COUNT(1) FROM cvo_soft_alloc_hdr (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext
--	IF (@sa_count = 1)
--	BEGIN
--		IF EXISTS(SELECT line_no FROM #so_soft_alloc_byline_tbl)  -- Only selected lines
--		BEGIN
--			UPDATE	a
--			SET		a.status = @cur_status, -- v1.9
--					quantity = quantity + b.qty_override
--			FROM	cvo_soft_alloc_det a
--			JOIN	#so_soft_alloc_byline_tbl b
--			ON		a.order_no = b.order_no
--			AND		a.order_ext = b.order_ext
--			AND		a.line_no = b.line_no
--			WHERE	a.order_no = @order_no
--			AND		a.order_ext = @order_ext	
--		
--		END
--		ELSE
--		BEGIN
--			UPDATE	cvo_soft_alloc_det
--			SET		status = @cur_status -- v1.9
--			WHERE	order_no = @order_no
--			AND		order_ext = @order_ext	
--		END
--		
--		UPDATE	cvo_soft_alloc_hdr
--		SET		status = @cur_status -- v1.9
--		WHERE	order_no = @order_no
--		AND		order_ext = @order_ext	
--
--	END
--	IF (@sa_count <> 1 AND NOT EXISTS (SELECT 1 FROM cvo_soft_alloc_start (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext)) -- Ignore pre-soft alloc
	BEGIN -- no soft alloc exists so create one

		UPDATE	cvo_soft_alloc_hdr
		SET		status = -2
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext	

		UPDATE	cvo_soft_alloc_det
		SET		status = -2
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext	

		-- v2.7 Start
		DELETE	cvo_soft_alloc_hdr 
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext
		AND		status = -2 

		DELETE	cvo_soft_alloc_det
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext
		AND		status = -2 

		SET	@new_soft_alloc_no = NULL

		SELECT	@new_soft_alloc_no = soft_alloc_no
		FROM	cvo_soft_alloc_no_assign (NOLOCK)
		WHERE	order_no = @order_no
		AND		order_ext = @order_ext

		IF (@new_soft_alloc_no IS NULL)
		BEGIN
			BEGIN TRAN
				UPDATE	dbo.cvo_soft_alloc_next_no
				SET		next_no = next_no + 1
			COMMIT TRAN	
			SELECT	@new_soft_alloc_no = next_no
			FROM	dbo.cvo_soft_alloc_next_no
		END
		-- v2.7 End

		-- Insert cvo_soft_alloc header
		INSERT INTO cvo_soft_alloc_hdr (soft_alloc_no, order_no, order_ext, location, bo_hold, status)
		VALUES (@new_soft_alloc_no, @order_no, @order_ext, @location, 0, @cur_status) -- v1.9

		-- Insert cvo_soft_alloc detail
		IF EXISTS(SELECT line_no FROM #so_soft_alloc_byline_tbl)  -- Only selected lines
		BEGIN

			INSERT INTO	dbo.cvo_soft_alloc_det (soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
										kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status, add_case_flag) -- v2.0			
			SELECT	@new_soft_alloc_no, @order_no, @order_ext, a.line_no, a.location, a.part_no, (((a.ordered - a.shipped) + ISNULL(c.qty_override,0)) - ISNULL(d.qty,0)), -- v2.8
					0, 0, 0, b.is_case, b.is_pattern, b.is_pop_gif, @cur_status, b.add_case -- v1.9 v2.0
			FROM	ord_list a (NOLOCK)
			JOIN	cvo_ord_list b (NOLOCK)
			ON		a.order_no = b.order_no
			AND		a.order_ext = b.order_ext
			AND		a.line_no = b.line_no
			LEFT JOIN	#so_soft_alloc_byline_tbl c
			ON		a.order_no = c.order_no
			AND		a.order_ext = c.order_ext
			AND		a.line_no = c.line_no
			LEFT JOIN
					#tmp_alloc d (NOLOCK)
			ON		a.line_no = d.line_no
			WHERE	a.order_no = @order_no
			AND		a.order_ext = @order_ext
			AND		(((a.ordered - a.shipped) + ISNULL(c.qty_override,0)) - ISNULL(d.qty,0)) > 0 -- v2.8

			-- v2.1
			EXEC dbo.cvo_update_soft_alloc_case_adjust_sp @new_soft_alloc_no, @order_no, @order_ext
		END
		ELSE
		BEGIN
			INSERT INTO	dbo.cvo_soft_alloc_det (soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
										kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status, add_case_flag) -- v2.0			
			SELECT	@new_soft_alloc_no, @order_no, @order_ext, a.line_no, a.location, a.part_no, ((a.ordered - a.shipped) - ISNULL(d.qty,0)), -- v2.8
					0, 0, 0, b.is_case, b.is_pattern, b.is_pop_gif, @cur_status, b.add_case -- v1.9 v2.0
			FROM	ord_list a (NOLOCK)
			JOIN	cvo_ord_list b (NOLOCK)
			ON		a.order_no = b.order_no
			AND		a.order_ext = b.order_ext
			AND		a.line_no = b.line_no
			LEFT JOIN
					#tmp_alloc d (NOLOCK)
			ON		a.line_no = d.line_no
			WHERE	a.order_no = @order_no
			AND		a.order_ext = @order_ext
			AND		((a.ordered - a.shipped) - ISNULL(d.qty,0)) > 0 -- v2.8


			-- v2.1
			EXEC dbo.cvo_update_soft_alloc_case_adjust_sp @new_soft_alloc_no, @order_no, @order_ext
		END
		
		-- Insert cvo_soft_alloc for any kit items
		IF EXISTS(SELECT line_no FROM #so_soft_alloc_byline_tbl)  -- Only selected lines
		BEGIN
			INSERT INTO	dbo.cvo_soft_alloc_det (soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
										kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status)			
			SELECT	@new_soft_alloc_no, @order_no, @order_ext, a.line_no, a.location, b.part_no, (((a.ordered - a.shipped) + ISNULL(c.qty_override,0)) - ISNULL(d.qty,0)), -- v2.8
					1, 0, 0, 0, 0, 0, @cur_status -- v1.9
			FROM	ord_list a (NOLOCK)
			JOIN	cvo_ord_list_kit b (NOLOCK)
			ON		a.order_no = b.order_no
			AND		a.order_ext = b.order_ext
			AND		a.line_no = b.line_no
			LEFT JOIN	#so_soft_alloc_byline_tbl c
			ON		a.order_no = c.order_no
			AND		a.order_ext = c.order_ext
			AND		a.line_no = c.line_no
			LEFT JOIN
					#tmp_alloc d (NOLOCK)
			ON		a.line_no = d.line_no
			WHERE	a.order_no = @order_no
			AND		a.order_ext = @order_ext	
			AND		b.replaced = 'S'		
			AND		(((a.ordered - a.shipped) + ISNULL(c.qty_override,0)) - ISNULL(d.qty,0)) > 0 -- v2.8
		END
		ELSE
		BEGIN
			INSERT INTO	dbo.cvo_soft_alloc_det (soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
										kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status)			
			SELECT	@new_soft_alloc_no, @order_no, @order_ext, a.line_no, a.location, b.part_no, ((a.ordered - a.shipped) - ISNULL(d.qty,0)), -- v2.8
					1, 0, 0, 0, 0, 0, @cur_status -- v1.9
			FROM	ord_list a (NOLOCK)
			JOIN	cvo_ord_list_kit b (NOLOCK)
			ON		a.order_no = b.order_no
			AND		a.order_ext = b.order_ext
			AND		a.line_no = b.line_no
			LEFT JOIN
					#tmp_alloc d (NOLOCK)
			ON		a.line_no = d.line_no
			WHERE	a.order_no = @order_no
			AND		a.order_ext = @order_ext	
			AND		b.replaced = 'S'	
			AND		((a.ordered - a.shipped) - ISNULL(d.qty,0)) > 0 -- v2.8	
		END
	END

	-- v2.5 Start
-- v2.9	EXEC @iret = dbo.cvo_hold_ship_complete_allocations_sp @order_no, @order_ext
	-- v2.5 End

	-- v3.1 Start
	SET @consolidation_no = 0
	SELECT	@consolidation_no = consolidation_no 
	FROM	cvo_masterpack_consolidation_det (NOLOCK) 
	WHERE	order_no = @order_no
	AND		order_ext = @order_ext

	IF (ISNULL(@consolidation_no,0) <> 0)
	BEGIN
		INSERT	#consolidate_picks
		SELECT	consolidation_no, order_no, order_ext
		FROM	cvo_masterpack_consolidation_det
		WHERE	consolidation_no = @consolidation_no	 
		AND		consolidation_no NOT IN (SELECT consolidation_no FROM #consolidate_picks)
	END 
	-- v3.1 End


	SET @last_id = @id

	SELECT	TOP 1 @id = id,
			@order_no = order_no,
			@order_ext = order_ext,
			@location = location	
	FROM	#tmp_orders_to_process
	WHERE	id > @last_id
	ORDER BY id ASC	
END

DROP TABLE #tmp_orders_to_process
DROP TABLE #tmp_alloc
	-- v1.8 End

-- v3.1 Start
 SET @consolidation_no = 0	 
 WHILE 1=1
 BEGIN
	SELECT TOP 1
		@consolidation_no = consolidation_no
	FROM
		#consolidate_picks
	WHERE
		consolidation_no > @consolidation_no
	ORDER BY
		consolidation_no

	IF @@ROWCOUNT = 0
		BREAK

	EXEC dbo.cvo_masterpack_consolidate_pick_records_sp @consolidation_no	
END

DROP TABLE #consolidate_picks
-- v3.1 End


  
RETURN 
GO
GRANT EXECUTE ON  [dbo].[tdc_plw_so_unallocate_sp] TO [public]
GO
