SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
CREATE PROCEDURE [dbo].[tdc_plw_so_allocbylot_process_sp]  
 @location      varchar(10),  
 @part_no       varchar(30),  
 @line_no       int,  
 @order_no      int,  
 @order_ext     int,  
 @user_id       varchar(50),  
 @con_no_passed_in  int,  
 @template_code  varchar(20)  
  
AS  
  
DECLARE @lot_ser          varchar(25),  
        @bin_no           varchar(12),  
 @name     varchar(100),  
 @desc     varchar(100),  
 @qty_to_alloc     decimal(24,8),  
 @qty_to_unalloc   decimal(24,8),  
 @allocated_qty    decimal(24,8),  
 @in_stock_qty     decimal(24,8),  
 @needed_qty       decimal(24,8),  
 @conv_factor   decimal(20,8),  
 @mgtb2b_qty   decimal(24,8),  
 @plwb2b_qty   decimal(24,8),  
 @con_name   varchar(255),  
 @con_desc   varchar(255),  
 @con_seq_no   int,  
 @con_no_from_temp_table int,  
 @next_con_no   int,  
 @alloc_type varchar(20),  
 @pass_bin varchar(12),  
 @q_priority     int,       
        @user_hold      char(1),  
        @cdock_flg      char(1),  
        @multiple_parts char(1),  
        @replen_group varchar(12),  
        @pkg_code varchar(20),  
        @assigned_user varchar(50),  
 @type           varchar(10),  
 @data  varchar(1000),  
 @pre_pack_flag char(1),
 @sa_qty	decimal(20,8), -- v1.6
 @alloc_qty decimal(20,8), -- v1.6
 @new_soft_alloc_no int, -- v1.6  
 @cur_status int, -- v1.6
 @is_custom int, -- v1.7
 @custom_bin varchar(20), -- v1.7
@unalloc_type varchar(30), -- v2.0
 @iRet int, -- v2.2
@err_ret int, -- v2.3
@consolidation_no int -- v2.9

-- v2.1 Start
DECLARE	@row_id			int,
		@last_row_id	int
-- v2.1 End

-- v1.5 Start
-- v1.1 Start - Unmark any records where the allocation date is in the future
--IF EXISTS (SELECT 1 FROM dbo.cvo_orders_all (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext
--				AND	ISNULL(allocation_date,GETDATE()-1) > GETDATE())
--	RETURN
-- v1.1 End
-- v1.5 End
  
-- v2.4 Start
-- Check if any line items exist in the queue that do not exist on the order
IF EXISTS (SELECT 1 FROM tdc_pick_queue a (NOLOCK) LEFT JOIN ord_list b (NOLOCK) ON a.trans_type_no = b.order_no AND a.trans_type_ext = b.order_ext
			AND	a.line_no = b.line_no WHERE a.trans_type_no = @order_no AND a.trans_type_ext = @order_ext AND a.trans = 'STDPICK' AND b.line_no IS NULL)
BEGIN
	-- Need to unallocate the lines that do not exist on the order
	DELETE	a
	FROM	tdc_soft_alloc_tbl a
	LEFT JOIN	ord_list b (NOLOCK)
	ON		a.order_no = b.order_no 
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no 
	WHERE	a.order_no = @order_no 
	AND		a.order_ext = @order_ext 
	AND		b.line_no IS NULL
	AND		a.order_type = 'S'

	DELETE	a
	FROM	tdc_pick_queue a
	LEFT JOIN	ord_list b (NOLOCK)
	ON		a.trans_type_no = b.order_no 
	AND		a.trans_type_ext = b.order_ext
	AND		a.line_no = b.line_no 
	WHERE	a.trans_type_no = @order_no 
	AND		a.trans_type_ext = @order_ext 
	AND		b.line_no IS NULL
	AND		a.trans IN ('STDPICK','MGTB2B')

END
-- v2.4 End


-- v1.7 Start
IF EXISTS(SELECT 1 FROM CVO_ord_list (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND line_no = @line_no AND is_customized = 'S')
	SET @is_custom = 1
ELSE
	SET @is_custom = 0
-- v1.7 End

BEGIN TRAN  
  
IF @con_no_passed_in > 0  
 SET @type = 'cons'  
ELSE  
 SET @type = 'one4one'  
  
SELECT @con_seq_no = 0  
  
SELECT @q_priority = 5  
SELECT @q_priority = CAST(value_str AS INT) FROM tdc_config(NOLOCK) where [function] = 'Pick_Q_Priority'  
IF @q_priority IN ('', 0) SELECT @q_priority = 5  
  
-- Change the prev alloc %  
IF EXISTS(SELECT * FROM tdc_alloc_history_tbl(NOLOCK)  
    WHERE order_no   = @order_no  
      AND order_ext  = @order_ext  
      AND order_type = 'S'  
      AND location   = @location)  
BEGIN  
 UPDATE tdc_alloc_history_tbl   
    SET fill_pct = a.curr_alloc_pct  
   FROM #so_alloc_management a, tdc_alloc_history_tbl b(NOLOCK)  
  WHERE b.order_no   = @order_no  
    AND b.order_ext  = @order_ext  
    AND b.order_type = 'S'  
    AND b.location   = @location  
    AND a.order_no   = b.order_no  
    AND a.order_ext  = b.order_ext  
    AND a.location   = b.location  
END  
ELSE  
BEGIN  
 INSERT INTO tdc_alloc_history_tbl (order_no, order_ext, location, fill_pct, alloc_date, alloc_by, order_type)  
 VALUES (@order_no, @order_ext, @location, 0, GETDATE(), @user_id, 'S')  
END  
  
IF EXISTS(SELECT *   
   FROM ord_list (NOLOCK)  
  WHERE order_no  = @order_no  
    AND order_ext = @order_ext  
    AND line_no   = @line_no  
    AND part_type = 'C')  
BEGIN  
 SELECT @conv_factor = conv_factor  
   FROM ord_list_kit (NOLOCK)  
  WHERE order_no  = @order_no  
    AND order_ext = @order_ext  
    AND line_no   = @line_no  
    AND part_no   = @part_no  
  
END  
ELSE  
BEGIN  
 SELECT @conv_factor = conv_factor  
   FROM ord_list (NOLOCK)  
  WHERE order_no  = @order_no  
    AND order_ext = @order_ext  
  
    AND line_no   = @line_no  
  
END  
  
--*********************************** Do unallocate first ************************************************  

-- v2.1 Start

CREATE TABLE #lbp_unallocate_cursor (
	row_id			int IDENTITY(1,1),
	lot_ser			varchar(25),
	bin_no			varchar(12),
	qty_to_alloc	decimal(20,8))

INSERT	#lbp_unallocate_cursor (lot_ser, bin_no, qty_to_alloc)
SELECT	lot_ser, bin_no, qty FROM #plw_alloc_by_lot_bin WHERE sel_flg2 <> 0 AND qty > 0  

CREATE INDEX #lbp_unallocate_cursor_ind0 ON #lbp_unallocate_cursor (row_id)
  
-- Loop through all the records with delta_alloc < 0  
--DECLARE unallocate_cursor CURSOR FOR   
 --SELECT lot_ser, bin_no, qty FROM #plw_alloc_by_lot_bin WHERE sel_flg2 <> 0 AND qty > 0  
  
--OPEN unallocate_cursor  
--FETCH NEXT FROM unallocate_cursor INTO @lot_ser, @bin_no, @qty_to_unalloc  
  
--WHILE (@@FETCH_STATUS <> -1)  

SET @last_row_id = 0

SELECT	TOP 1 @row_id = row_id,
		@lot_ser = lot_ser,
		@bin_no = bin_no,
		@qty_to_unalloc = qty_to_alloc
FROM	#lbp_unallocate_cursor
WHERE	row_id > @last_row_id
ORDER BY row_id ASC

WHILE (@@ROWCOUNT <> 0)
-- v2.1 End
BEGIN    
 /* Determine if any of the transactions on the queue are being processed.  */  
 /* If so, then rollback. Otherwise, continue on and change the queue by    */  
 /* updating & deleting all the applicable pick transactions for the        */  
 /* order / part / lot/ bin being unallocated.        */  
 IF EXISTS (SELECT *   
       FROM tdc_pick_queue (NOLOCK) -- v2.1  
      WHERE trans         IN ('STDPICK', 'PKGBLD')  
        AND trans_type_no  = @order_no  
        AND trans_type_ext = @order_ext  
        AND location       = @location  
                      AND part_no        = @part_no  
        AND lot            = @lot_ser  
        AND bin_no         = @bin_no  
        AND tx_lock   NOT IN ('R','3','P', 'G', 'H','E'))  
 BEGIN 
	-- v2.1 Start
	DROP TABLE #lbp_unallocate_cursor       
--  CLOSE      unallocate_cursor  
--  DEALLOCATE unallocate_cursor  
	-- v2.1 End
  ROLLBACK TRANSACTION  
  RAISERROR ('Pick transaction is locked on the Queue.  Unable to unallocate.',16, 1)  
  RETURN  
 END  

 -- v1.7 Start
 IF (@is_custom = 1)
 BEGIN
	SELECT @custom_bin = ISNULL((SELECT value_str FROM tdc_config (nolock)  
									WHERE [function] = 'CVO_CUSTOM_BIN' AND active = 'Y'), 'CUSTOM')
	UPDATE	tdc_soft_alloc_tbl   
    SET		qty = qty  - @qty_to_unalloc,  
			trg_off = 1 --SCR 38010 Jim 8/16/07 : disable tdc_upd_softalloc_tg  
    WHERE	order_no   = @order_no  
    AND		order_ext  = @order_ext  
    AND		order_type = 'S'  
    AND		location   = @location  
    AND		line_no    = @line_no  
    AND		part_no    = @part_no  
    AND		lot_ser    = @lot_ser  
    AND		bin_no     = @custom_bin

 END
 ELSE
 BEGIN  
	UPDATE	tdc_soft_alloc_tbl   
    SET		qty = qty  - @qty_to_unalloc,  
			trg_off = 1 --SCR 38010 Jim 8/16/07 : disable tdc_upd_softalloc_tg  
    WHERE	order_no   = @order_no  
    AND		order_ext  = @order_ext  
    AND		order_type = 'S'  
    AND		location   = @location  
    AND		line_no    = @line_no  
    AND		part_no    = @part_no  
    AND		lot_ser    = @lot_ser  
    AND		bin_no     = @bin_no  
 END

 IF @@ERROR <> 0  
 BEGIN  
	-- v2.1 Start
	DROP TABLE #lbp_unallocate_cursor
--  CLOSE      unallocate_cursor  
--  DEALLOCATE unallocate_cursor  
	-- v2.1 End
  ROLLBACK TRANSACTION  
  RAISERROR ('Update tdc_soft_alloc_tbl table failed.  Unable to unallocate.',16, 1)  
  RETURN  
 END  
  
--/* SCR 38010 Jim 8/16/07 : disable tdc_upd_softalloc_tg  
--JCOLLINS SCR 34166   
 IF (@is_custom = 1)
 BEGIN
	SELECT @custom_bin = ISNULL((SELECT value_str FROM tdc_config (nolock)  
									WHERE [function] = 'CVO_CUSTOM_BIN' AND active = 'Y'), 'CUSTOM')

	UPDATE tdc_pick_queue   
    SET qty_to_process = qty_to_process - @qty_to_unalloc  
         WHERE trans         IN ('STDPICK', 'PKGBLD')  
           AND trans_type_no  = @order_no  
           AND trans_type_ext = @order_ext  
           AND location       = @location  
           AND part_no        = @part_no  
           AND lot            = @lot_ser  
           AND bin_no         = @custom_bin  
		   AND line_no		  = @line_no -- v1.2

 END
 ELSE
 BEGIN
	UPDATE tdc_pick_queue   
    SET qty_to_process = qty_to_process - @qty_to_unalloc  
         WHERE trans         IN ('STDPICK', 'PKGBLD')  
           AND trans_type_no  = @order_no  
           AND trans_type_ext = @order_ext  
           AND location       = @location  
           AND part_no        = @part_no  
           AND lot            = @lot_ser  
           AND bin_no         = @bin_no  
		   AND line_no		  = @line_no -- v1.2
 END
 
 IF @@ERROR <> 0  
 BEGIN          
	-- v2.1 Start
	DROP TABLE #lbp_unallocate_cursor
--  CLOSE      unallocate_cursor  
--  DEALLOCATE unallocate_cursor  
	-- v2.1 End
  ROLLBACK TRANSACTION  
  RAISERROR ('Update tdc_pick_queue table failed.  Unable to unallocate.',16, 1)  
  RETURN  
 END  
--*/  
  
 IF (@is_custom = 1)
 BEGIN
	SELECT @custom_bin = ISNULL((SELECT value_str FROM tdc_config (nolock)  
									WHERE [function] = 'CVO_CUSTOM_BIN' AND active = 'Y'), 'CUSTOM')

	DELETE FROM tdc_pick_queue   
         WHERE trans          IN ('STDPICK', 'PKGBLD')  
           AND trans_type_no   = @order_no  
           AND trans_type_ext  = @order_ext  
           AND location        = @location  
           AND part_no         = @part_no  
           AND lot             = @lot_ser  
           AND bin_no          = @custom_bin  
		   AND line_no		   = @line_no -- v1.2
    AND qty_to_process <= 0  
 END
 ELSE
 BEGIN
	DELETE FROM tdc_pick_queue   
         WHERE trans          IN ('STDPICK', 'PKGBLD')  
           AND trans_type_no   = @order_no  
           AND trans_type_ext  = @order_ext  
           AND location        = @location  
           AND part_no         = @part_no  
           AND lot             = @lot_ser  
           AND bin_no          = @bin_no  
		   AND line_no		   = @line_no -- v1.2
    AND qty_to_process <= 0  
 END
	-- v1.7 Start
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
  
	-- v1.7 End
 IF @con_no_passed_in > 0  
 BEGIN  
  UPDATE tdc_pick_queue   
     SET qty_to_process = qty_to_process  - @qty_to_unalloc  
          WHERE trans           = 'PLWB2B'  
            AND trans_type_no   = @con_no_passed_in  
            AND trans_type_ext  = 0  
            AND location        = @location  
            AND part_no         = @part_no  
            AND lot             = @lot_ser  
            AND bin_no          = @bin_no  
     
  DELETE FROM tdc_pick_queue   
          WHERE trans           = 'PLWB2B'  
            AND trans_type_no   = @con_no_passed_in  
            AND trans_type_ext  = 0  
            AND location        = @location  
            AND part_no         = @part_no  
            AND lot             = @lot_ser  
           AND bin_no          = @bin_no  
    AND qty_to_process <= 0    
 END  
  
 IF (@is_custom = 1)
 BEGIN
	SELECT @custom_bin = ISNULL((SELECT value_str FROM tdc_config (nolock)  
									WHERE [function] = 'CVO_CUSTOM_BIN' AND active = 'Y'), 'CUSTOM')

	UPDATE tdc_soft_alloc_tbl   
    SET trg_off = 0 --SCR 37993 Jim 8/16/07 : enable tdc_upd_softalloc_tg  
         WHERE order_no   = @order_no  
           AND order_ext  = @order_ext  
           AND order_type = 'S'  
    AND location   = @location  
    AND line_no    = @line_no  
    AND part_no    = @part_no  
    AND lot_ser    = @lot_ser  
    AND bin_no     = @custom_bin  

	DELETE	tdc_soft_alloc_tbl
	WHERE	order_no   = @order_no  
    AND		order_ext  = @order_ext  
    AND		order_type = 'S'  
    AND		location   = @location  
    AND		line_no    = @line_no  
    AND		part_no    = @part_no  
    AND		lot_ser    = @lot_ser  
    AND		bin_no     = @custom_bin 
	AND		qty <= 0
 END
 ELSE
 BEGIN
	UPDATE tdc_soft_alloc_tbl   
    SET trg_off = 0 --SCR 37993 Jim 8/16/07 : enable tdc_upd_softalloc_tg  
         WHERE order_no   = @order_no  
           AND order_ext  = @order_ext  
           AND order_type = 'S'  
    AND location   = @location  
    AND line_no    = @line_no  
    AND part_no    = @part_no  
    AND lot_ser    = @lot_ser  
    AND bin_no     = @bin_no  
  END
 -- Log the record  
 SET @unalloc_type = 'UnAllocate By Lot/Bin: ' -- v2.0

 INSERT INTO tdc_log (tran_date, UserID, trans_source, module, trans, tran_no, tran_ext, part_no,   
        lot_ser, bin_no, location, quantity, data)  
 SELECT getdate(), @user_id, 'VB', 'PLWSO', 'UNALLOCATION', @order_no, @order_ext, @part_no,   
        @lot_ser,  @bin_no, @location, @qty_to_unalloc,   
        @unalloc_type + 'line number = ' + RTRIM(CAST(@line_no AS varchar(10))) -- v2.0
  

	-- v2.3 Start
	IF NOT EXISTS (SELECT 1 FROM tdc_pick_queue (NOLOCK) WHERE trans_type_no = @order_no AND trans_type_ext = @order_ext AND trans = 'STDPICK')
		AND EXISTS (SELECT 1 FROM orders_all (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext AND status = 'P')
	BEGIN
		 EXEC dbo.fs_calculate_oetax @order_no, @order_ext, @err_ret OUT  	   
		   
		 EXEC dbo.fs_updordtots @order_no, @order_ext     
	END
	-- v2.3 End  

	-- v2.1 Start
	SET @last_row_id = @row_id

	SELECT	TOP 1 @row_id = row_id,
			@lot_ser = lot_ser,
			@bin_no = bin_no,
			@qty_to_unalloc = qty_to_alloc
	FROM	#lbp_unallocate_cursor
	WHERE	row_id > @last_row_id
	ORDER BY row_id ASC

-- FETCH NEXT FROM unallocate_cursor INTO @lot_ser, @bin_no, @qty_to_unalloc  
END  
  
--CLOSE      unallocate_cursor  
--DEALLOCATE unallocate_cursor  
DROP TABLE #lbp_unallocate_cursor
-- v2.1 End
  
  
--************************* Do allocate **********************************************************  

SET @unalloc_type = 'Allocate By Lot/Bin: ' -- v2.0
  
-- 1. Get template's settings  
SELECT @q_priority       = tran_priority,  
       @user_hold        = on_hold,  
       @pass_bin         = pass_bin,  
       @pkg_code  = pkg_code,  
       @assigned_user    = CASE WHEN user_group = ''   
             OR user_group LIKE '%DEFAULT%'   
           THEN NULL  
           ELSE user_group  
      END,   
       @alloc_type       = CASE dist_type   
           WHEN 'PrePack'   THEN 'PR'  
           WHEN 'ConsolePick'  THEN 'PT'  
           WHEN 'PickPack'  THEN 'PP'  
           WHEN 'PackageBuilder'  THEN 'PB'  
             END  
  FROM tdc_plw_process_templates (NOLOCK)  
 WHERE template_code  = @template_code  
   AND UserID         = @user_id  
   AND location       = @location  
   AND order_type     = 'S'  
   AND type           = @type  
  
SET @data = 'Line: ' + CAST(@line_no as varchar(3)) + '; Order Type: S; ' + 'Alloc Type: ' + @alloc_type +  '; Alloc Template Code: ' + @template_code + '; One4One/Con: ' + @type  
  
-- 2. Get needed qty  
IF EXISTS(SELECT *   
   FROM ord_list (NOLOCK)  
  WHERE order_no  = @order_no  
    AND order_ext = @order_ext  
    AND line_no   = @line_no  
    AND part_type = 'C')  
BEGIN  
  
 SELECT @needed_qty = 0  
 SELECT @needed_qty = ISNULL((SELECT (ordered * qty_per_kit) - picked     -- Ordered - Shipped  
                  FROM tdc_ord_list_kit (NOLOCK)  
               WHERE order_no  = @order_no  
     AND order_ext = @order_ext  
                   AND line_no   = @line_no  
                   AND location  = @location         
                   AND kit_part_no   = @part_no), 0)   
     -   
     (SELECT ISNULL( (SELECT SUM(qty)  -- Allocated Qty  
                 FROM tdc_soft_alloc_tbl (NOLOCK) -- v2.1 
         WHERE order_no   = @order_no  
                  AND order_ext  = @order_ext  
                  AND order_type = 'S'  
                  AND location   = @location  
                  AND line_no    = @line_no  
                  AND part_no    = @part_no  
                GROUP BY location), 0))  
END  
ELSE  
BEGIN  
 SELECT @needed_qty = 0  
 SELECT @needed_qty = ISNULL((SELECT ordered - shipped     -- Ordered - Shipped  
                  FROM ord_list  (NOLOCK) -- v2.1
               WHERE order_no  = @order_no  
     AND order_ext = @order_ext  
                   AND line_no   = @line_no  
                   AND location  = @location         
                   AND part_no   = @part_no), 0)   
     -   
     (SELECT ISNULL( (SELECT SUM(qty)  -- Allocated Qty  
                 FROM tdc_soft_alloc_tbl (NOLOCK) -- v2.1 
         WHERE order_no   = @order_no  
                  AND order_ext  = @order_ext  
                  AND order_type = 'S'  
                  AND location   = @location  
                  AND line_no    = @line_no  
                  AND part_no    = @part_no  
                GROUP BY location), 0))  
 SELECT @needed_qty = @needed_qty * @conv_factor    
END  
  
-- v2.1 Start
CREATE TABLE #lbpa_allocate_cursor (
	row_id			int IDENTITY(1,1),
	lot_ser			varchar(25),
	bin_no			varchar(12),
	qty_to_alloc	decimal(20,8))

INSERT #lbpa_allocate_cursor (lot_ser, bin_no, qty_to_alloc)
SELECT	lot_ser, bin_no, qty FROM #plw_alloc_by_lot_bin WHERE sel_flg1 <> 0 AND qty > 0 

CREATE INDEX #lbpa_allocate_cursor_ind0 ON #lbpa_allocate_cursor(row_id)
  
-- Loop through all the records with sel_flg1 <> 0  
--DECLARE allocate_cursor CURSOR FOR   
-- SELECT lot_ser, bin_no, qty FROM #plw_alloc_by_lot_bin WHERE sel_flg1 <> 0 AND qty > 0  
  
--OPEN allocate_cursor  
--FETCH NEXT FROM allocate_cursor INTO @lot_ser, @bin_no, @qty_to_alloc  
  
--WHILE (@@FETCH_STATUS <> -1)  

SET @last_row_id = 0

SELECT	TOP 1 @row_id = row_id,
		@lot_ser = lot_ser,
		@bin_no = bin_no,
		@qty_to_alloc = qty_to_alloc
FROM	#lbpa_allocate_cursor
WHERE	row_id > @last_row_id
ORDER BY row_id ASC

WHILE (@@ROWCOUNT <> 0)
-- v2.1 End
BEGIN  
 -- 3. Check if we still need to allocate for the part_no / line_no  
 IF @needed_qty < @qty_to_alloc   
 BEGIN  
	-- v2.1 Start  
	DROP TABLE #lbpa_allocate_cursor
--  DEALLOCATE allocate_cursor  
	-- v2.1 End
  ROLLBACK TRANSACTION  
  RAISERROR ('Cannot over allocate part: %s on location: %s.  Unable to allocate.',16, 1, @part_no, @location)    
  RETURN  
 END  
  
 -- 4. Check if we have enough in stock qty  
 SELECT @in_stock_qty = 0  
 SELECT @in_stock_qty = qty  
   FROM lot_bin_stock (NOLOCK)  
  WHERE location  = @location  
    AND part_no   = @part_no  
    AND bin_no    = @bin_no  
    AND lot_ser   = @lot_ser   
  
 -- Get inventory for this part / location /lot / bin that a warehouse manager requested a MGTB2B move on.  
 SELECT @mgtb2b_qty = 0  
 SELECT @mgtb2b_qty =  SUM(qty_to_process)  
   FROM tdc_pick_queue (NOLOCK)  
  WHERE location = @location   
    AND part_no  = @part_no   
    AND lot      = @lot_ser   
    AND bin_no   = @bin_no   
    AND trans    = 'MGTBIN2BIN'  
  GROUP BY location  
  
 -- Get inventory for this part / location /lot / bin that a warehouse manager requested a PLWB2B move on.  
 SELECT @plwb2b_qty = 0  
 SELECT @plwb2b_qty =  SUM(qty_to_process)  
   FROM tdc_pick_queue (NOLOCK)  
  WHERE location = @location   
    AND part_no  = @part_no   
    AND lot      = @lot_ser   
    AND bin_no   = @bin_no   
    AND trans    = 'PLWB2B'  
  GROUP BY location  
  
 SELECT @in_stock_qty = @in_stock_qty - @mgtb2b_qty - @plwb2b_qty  
  
 SELECT @allocated_qty = 0  
 SELECT @allocated_qty = SUM(qty)      
          FROM tdc_soft_alloc_tbl (NOLOCK)  
         WHERE location   = @location  
           AND part_no    = @part_no  
           AND lot_ser    = @lot_ser   
           AND bin_no     = @bin_no  
        GROUP BY location  
  
 IF (@in_stock_qty - @allocated_qty) < @qty_to_alloc  
  
 BEGIN  
	-- v2.1 Start
	DROP TABLE #lbpa_allocate_cursor
--  CLOSE      allocate_cursor  
--  DEALLOCATE allocate_cursor  
	-- v2.1 End
  ROLLBACK TRANSACTION  
  RAISERROR ('Not enough qty of part : %s in LOT: %s; BIN: %s; Location: %s. Unable to allocate.',16, 1, @part_no, @lot_ser, @bin_no, @location)  
  RETURN  
 END  
  
 -- 5. Insert / Update tdc_soft_alloc_tbl  
 IF EXISTS(SELECT * FROM tdc_soft_alloc_tbl (NOLOCK)  
     WHERE order_no   = @order_no  
       AND order_ext  = @order_ext  
       AND order_type = 'S'  
       AND location   = @location  
       AND line_no    = @line_no  
       AND part_no    = @part_no  
       AND lot_ser    = @lot_ser  
                     AND bin_no     = @bin_no)  
 BEGIN    
  UPDATE tdc_soft_alloc_tbl  
     SET qty           = qty  + @qty_to_alloc,  
         dest_bin      = @pass_bin,  
         q_priority    = @q_priority,  
         assigned_user = @assigned_user,  
         user_hold     = @user_hold,  
         pkg_code      = @pkg_code  
   WHERE order_no      = @order_no  
     AND order_ext     = @order_ext  
     AND order_type    = 'S'  
     AND location      = @location  
     AND line_no       = @line_no  
     AND part_no       = @part_no  
     AND lot_ser       = @lot_ser  
                   AND bin_no        = @bin_no  
 END  
 ELSE  
 BEGIN  
  INSERT INTO tdc_soft_alloc_tbl(order_no, order_ext, location, line_no, part_no,lot_ser, bin_no, qty, order_type,   
       target_bin, dest_bin, alloc_type, q_priority, assigned_user, user_hold, pkg_code)  
  VALUES (@order_no, @order_ext, @location, @line_no, @part_no,  @lot_ser,  @bin_no, @qty_to_alloc, 'S',  
   @bin_no, @pass_bin, @alloc_type, @q_priority, @assigned_user, @user_hold, @pkg_code)  
 END  
  
 INSERT INTO tdc_log (tran_date, UserID, trans_source, module, trans, tran_no, tran_ext, part_no, lot_ser, bin_no, location, quantity, data)  
 VALUES(GETDATE(), @user_id, 'VB', 'PLW', 'ALLOCATION', @order_no, @order_ext, @part_no, @lot_ser,  @bin_no, @location, @qty_to_alloc, @unalloc_type + @data) -- v2.0

-- v1.6 Start
 -- v1.4 Start - If a soft allcoation record exists with a status of 0 or -3 then remove them
-- UPDATE	cvo_soft_alloc_det
-- SET	status = -2
-- WHERE	order_no = @order_no
-- AND	order_ext = @order_ext
-- AND	status IN (0,-3) 
--
-- UPDATE	cvo_soft_alloc_hdr
-- SET	status = -2
-- WHERE	order_no = @order_no
-- AND	order_ext = @order_ext
-- AND	status IN (0,-3) 
 -- v1.4 End
-- v1.6 End

-- v2.1 Start
	SET @last_row_id = @row_id

	SELECT	TOP 1 @row_id = row_id,
			@lot_ser = lot_ser,
			@bin_no = bin_no,
			@qty_to_alloc = qty_to_alloc
	FROM	#lbpa_allocate_cursor
	WHERE	row_id > @last_row_id
	ORDER BY row_id ASC

-- FETCH NEXT FROM allocate_cursor INTO @lot_ser, @bin_no, @qty_to_alloc  
END  
  
DROP TABLE #lbpa_allocate_cursor
--CLOSE      allocate_cursor  
--DEALLOCATE allocate_cursor  
-- v2.1 End

-- v1.7 Start
IF EXISTS(SELECT 1 FROM CVO_ord_list (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND line_no = @line_no AND is_customized = 'S') 
BEGIN
	IF EXISTS (SELECT 1 FROM tdc_soft_alloc_tbl (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND order_type = 'S')
	BEGIN

		EXEC dbo.CVO_Create_Frame_Bin_Moves_sp @order_no, @order_ext

		UPDATE dbo.cvo_ord_list_kit SET location = location WHERE order_no = @order_no AND order_ext = @order_ext
		
		IF (OBJECT_ID('tempdb..#PrintData') IS NOT NULL) 
			DROP TABLE #PrintData

		CREATE TABLE #PrintData 
		(row_id			INT IDENTITY (1,1)	NOT NULL
		,data_field		VARCHAR(300)		NOT NULL
		,data_value		VARCHAR(300)			NULL)
		
		EXEC CVO_disassembled_frame_sp @order_no, @order_ext
		
		EXEC CVO_disassembled_inv_adjust_sp @order_no, @order_ext
			
		EXEC CVO_disassembled_print_inv_adjust_sp @order_no, @order_ext		
			
		UPDATE	cvo_orders_all 
		SET		flag_print = 2 
		WHERE	order_no = @order_no 
		AND		 ext = @order_ext
				
		EXEC dbo.cvo_print_pick_ticket_sp @order_no, @order_ext

	END 
END
-- v1.7 End
  
IF @alloc_type = 'PR'  
 SELECT @pre_pack_flag = 'Y'  
ELSE  
 SELECT @pre_pack_flag = 'N'  
  
------------------------------------------------------------------------------------------------------------------  
-- Consolidation Number / ONE_FOR_ONE logic  
------------------------------------------------------------------------------------------------------------------  
IF NOT EXISTS(SELECT *   
         FROM tdc_cons_ords(NOLOCK)  
        WHERE order_no  = @order_no  
   AND order_ext = @order_ext  
          AND location  = @location)  
BEGIN  
 IF @con_no_passed_in = 0 --ONE_FOR_ONE  
 BEGIN  
   
  -- create a new record in tdc_main   
  --get the next available cons number  
  EXEC @next_con_no = tdc_get_next_consol_num_sp  
   
  --our generic description and name   
  SELECT @con_name = 'Ord ' +  CONVERT(VARCHAR(20),@order_no) + ' Ext ' + CONVERT(VARCHAR(4),@order_ext)   
  SELECT @con_desc = 'Ord ' +  CONVERT(VARCHAR(20),@order_no) + ' Ext ' + CONVERT(VARCHAR(4),@order_ext)   
   
   
  INSERT INTO tdc_main ( consolidation_no, consolidation_name, order_type,  
   [description], status, created_by, creation_date, pre_pack  )   
  VALUES (@next_con_no , @con_name, 'S', @con_desc, 'O' , @user_id , GETDATE(), @pre_pack_flag )  
   
  --only one order per consolidation set for ONE_FOR_ONE   
  DELETE FROM tdc_cons_ords   
   WHERE order_no = @order_no  
     AND order_ext = @order_ext  
     AND location = @location  
     AND order_type = 'S'  
  
   INSERT INTO tdc_cons_ords (consolidation_no, order_no, order_ext,location,  
         status, seq_no, print_count, order_type, alloc_type)  
   VALUES ( @next_con_no,@order_no,@order_ext,@location,'O', 1 , 0, 'S', @alloc_type)  
   
  --need to update soft_alloc_tbl and set the target bin = to the bin_no  
  --this is a rule that on one to one the bin_no becomes the picking bin  
  IF EXISTS(SELECT * FROM tdc_cons_filter_set (NOLOCK)   
      WHERE consolidation_no = @next_con_no)  
   DELETE FROM tdc_cons_filter_set   
    WHERE consolidation_no = @next_con_no  
   
  INSERT INTO tdc_cons_filter_set ( consolidation_no, location, order_status, ship_date_start, ship_date_end,  
   order_range_start, order_range_end, ext_range_start, ext_range_end, order_priority_start,  
   order_priority_end, order_priority_range,  
   sold_to, ship_to, territory, carrier, destination_zone, cust_op1, cust_op2, cust_op3, order_no_range,  
   ext_no_range, fill_percent, orderby_1, orderby_2, orderby_3, orderby_4, orderby_5, orderby_6, orderby_7, order_type, -- v1.0
   frame_case_match, orderby_8, orderby_9, order_type_code, consolidate_shipment, delivery_date_start, -- v1.0
   delivery_date_end, user_hold)  -- v1.0  
  SELECT @next_con_no, location, order_status, ship_date_start,   
    ship_date_end, order_range_start, order_range_end, ext_range_start,  
    ext_range_end, order_priority_start, order_priority_end, order_priority_range, sold_to, ship_to, territory,   
    carrier, destination_zone, cust_op1, cust_op2, cust_op3, order_no_range,   
    ext_no_range, fill_percent, orderby_1, orderby_2, orderby_3,  
    orderby_4,orderby_5,orderby_6,orderby_7, 'S', -- v1.0
	frame_case_match, orderby_8, orderby_9, order_type_code, consolidate_shipment, delivery_date_start, -- v1.0
	delivery_date_end, user_hold  -- v1.0  
   FROM tdc_user_filter_set WHERE userid = @user_id AND order_type = 'S'  
   
 END  
 ------------------------------------------------------------------------------------------------------------------  
 ELSE --NOT ONE_FOR_ONE  
 ------------------------------------------------------------------------------------------------------------------  
 BEGIN  
  
  SELECT @con_seq_no = @con_seq_no + 1   
  
  --Make sure the user is some how getting an order already assigned  
  SELECT @con_no_from_temp_table = 0  
  SELECT @con_no_from_temp_table = consolidation_no  
    FROM #so_alloc_management  
          WHERE order_no  = @order_no  
     AND order_ext = @order_ext  
     AND location  = @location  
  
  IF ISNULL(@con_no_from_temp_table, 0) = 0   
  BEGIN  
   --We want to ensure that we are not inserting another record for the same order , ext     
   IF NOT EXISTS(SELECT * FROM tdc_cons_ords (NOLOCK)  
           WHERE order_no = @order_no  
             AND order_ext = @order_ext   
             AND order_type = 'S'  
             AND location = @location )   
   BEGIN   
    INSERT INTO tdc_cons_ords (consolidation_no, order_no,order_ext,location,status,seq_no,print_count,order_type, alloc_type)  
      VALUES ( @con_no_passed_in, @order_no,@order_ext,@location,'O', @con_seq_no , 0, 'S', @alloc_type)  
     
    INSERT INTO tdc_log (tran_date, UserID, trans_source, module, trans,tran_no , tran_ext, part_no, lot_ser, bin_no, location, quantity, data)  
     VALUES (getdate(), @user_id , 'VB', 'PLW' , 'Allocation', @con_no_passed_in, 0, '', '', '', @location, '', @unalloc_type + 'ADD order number = ' + CONVERT(VARCHAR(10),@order_no) + '-' + CONVERT(VARCHAR(10),@order_ext))  -- v2.0
   END  
  END  
  
 END --Not ONE_FOR_ONE    
END  
  
IF @con_no_passed_in != 0  
BEGIN  
 UPDATE tdc_main  
   SET pre_pack = @pre_pack_flag  
 WHERE consolidation_no = @con_no_passed_in  
END  

-- v1.6 Start
SET @cur_status = 0

IF EXISTS (SELECT 1 FROM cvo_soft_alloc_hdr (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND status = -3)
	SET @cur_status = -3

CREATE TABLE #tmp_alloc (
		line_no		int,
		qty			decimal(20,8))

SELECT	@alloc_qty = SUM(qty) 
FROM	tdc_soft_alloc_tbl (NOLOCK)
WHERE	order_no = @order_no
AND		order_ext= @order_ext
AND		line_no = @line_no
AND		part_no = @part_no

IF (@alloc_qty IS NULL)
	SET @alloc_qty = 0

INSERT	#tmp_alloc
SELECT	line_no, SUM(qty)
FROM	tdc_soft_alloc_tbl (NOLOCK)
WHERE	order_no = @order_no
AND		order_ext= @order_ext
GROUP BY line_no

SELECT	@sa_qty = SUM(ordered)
FROM	ord_list (NOLOCK)
WHERE	order_no = @order_no
AND		order_ext= @order_ext
AND		line_no = @line_no
AND		part_no = @part_no

IF	(@sa_qty = @alloc_qty) -- Line Fully allocated
BEGIN

	UPDATE	cvo_soft_alloc_det
	SET		status = -2
	WHERE	order_no = @order_no
	AND		order_ext= @order_ext
	AND		line_no = @line_no
	AND		part_no = @part_no
	AND		status IN (0,-1,-3,1) -- v3.1
	
	UPDATE	cvo_soft_alloc_det
	SET		status = -2
	WHERE	order_no = @order_no
	AND		order_ext= @order_ext
	AND		line_no = @line_no
	AND		kit_part = 1
	AND		status IN (0,-1,-3,1) -- v3.1

	IF NOT EXISTS (SELECT 1 FROM cvo_soft_alloc_det (NOLOCK) WHERE order_no = @order_no AND order_ext= @order_ext AND status IN (0,-1,-3,1)) -- v3.1
	BEGIN
		UPDATE	cvo_soft_alloc_hdr
		SET		status = -2
		WHERE	order_no = @order_no
		AND		order_ext= @order_ext
		AND		status IN (0,-1,-3,1) -- v3.1
	END

	-- v2.5 Start
	DELETE	cvo_soft_alloc_hdr 
	WHERE	order_no = @order_no
	AND		order_ext = @order_ext
	AND		status = -2 

	DELETE	cvo_soft_alloc_det
	WHERE	order_no = @order_no
	AND		order_ext = @order_ext
	AND		status = -2 

	SELECT	@new_soft_alloc_no = soft_alloc_no
	FROM	cvo_soft_alloc_no_assign (NOLOCK)
	WHERE	order_no = @order_no
	AND		order_ext = @order_ext

	IF (@new_soft_alloc_no IS NOT NULL)
		EXEC dbo.cvo_update_soft_alloc_case_adjust_sp @new_soft_alloc_no, @order_no, @order_ext

	-- v2.5 End
END
ELSE
BEGIN
--	IF (@alloc_qty > 0) -- Line partially allocated
	BEGIN

		UPDATE	cvo_soft_alloc_hdr
		SET		status = -2
		WHERE	order_no = @order_no
		AND		order_ext= @order_ext
		AND		status IN (0,-1,-3)

		UPDATE	cvo_soft_alloc_det
		SET		status = -2
		WHERE	order_no = @order_no
		AND		order_ext= @order_ext				
		AND		status IN (0,-1,-3)

		-- v2.5 Start
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
		-- v2.5 End

		-- Insert cvo_soft_alloc header
		INSERT INTO cvo_soft_alloc_hdr (soft_alloc_no, order_no, order_ext, location, bo_hold, status)
		VALUES (@new_soft_alloc_no, @order_no, @order_ext, @location, 0, @cur_status)		

		INSERT INTO	dbo.cvo_soft_alloc_det (soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
									kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status, add_case_flag) -- v1.8			
		SELECT	@new_soft_alloc_no, @order_no, @order_ext, a.line_no, a.location, a.part_no, ((a.ordered - a.shipped) - ISNULL(c.qty,0)), -- v2.6
				0, 0, 0, b.is_case, b.is_pattern, b.is_pop_gif, @cur_status, b.add_case -- v1.8
		FROM	ord_list a (NOLOCK)
		JOIN	cvo_ord_list b (NOLOCK)
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		AND		a.line_no = b.line_no
		LEFT JOIN
				#tmp_alloc c (NOLOCK)
		ON		a.line_no = c.line_no
		WHERE	a.order_no = @order_no
		AND		a.order_ext = @order_ext
		AND		((a.ordered - a.shipped) - ISNULL(c.qty,0)) > 0 -- v2.6

		-- v1.9
		EXEC dbo.cvo_update_soft_alloc_case_adjust_sp @new_soft_alloc_no, @order_no, @order_ext

		INSERT INTO	dbo.cvo_soft_alloc_det (soft_alloc_no, order_no, order_ext, line_no, location, part_no, quantity,  
									kit_part, change, deleted, is_case, is_pattern, is_pop_gift, status)			
		SELECT	@new_soft_alloc_no, @order_no, @order_ext, a.line_no, a.location, b.part_no, ((a.ordered - a.shipped) - ISNULL(c.qty,0)), -- v2.6
				1, 0, 0, 0, 0, 0, @cur_status
		FROM	ord_list a (NOLOCK)
		JOIN	cvo_ord_list_kit b (NOLOCK)
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		AND		a.line_no = b.line_no
		LEFT JOIN
				#tmp_alloc c (NOLOCK)
		ON		a.line_no = c.line_no
		AND		a.line_no = c.line_no
		WHERE	a.order_no = @order_no
		AND		a.order_ext = @order_ext	
		AND		b.replaced = 'S'
		AND		((a.ordered - a.shipped) - ISNULL(c.qty,0)) > 0 -- v2.6
	END

END

DROP TABLE #tmp_alloc
-- v1.2 End

  
DELETE tdc_cons_filter_set WHERE consolidation_no NOT IN (SELECT consolidation_no FROM tdc_cons_ords (NOLOCK))  
  
DELETE tdc_main WHERE consolidation_no NOT IN (SELECT consolidation_no  FROM tdc_cons_ords (NOLOCK))  

-- v1.3 - Call autopack routine
EXEC dbo.CVO_build_autopack_carton_sp @order_no, @order_ext

-- v3.0 Start
EXEC dbo.cvo_update_bo_processing_sp 'A', @order_no, @order_ext
-- v3.0 End

-- v2.9 Start
IF OBJECT_ID('tempdb..#consolidate_picks') IS NOT NULL
	DROP TABLE #consolidate_picks

CREATE TABLE #consolidate_picks(  
	consolidation_no	int,  
	order_no			int,  
	ext					int) 

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

	DELETE	tdc_pick_queue
	WHERE	mp_consolidation_no = @consolidation_no

	DELETE	cvo_masterpack_consolidation_picks
	WHERE	consolidation_no = @consolidation_no	

	EXEC dbo.cvo_masterpack_consolidate_pick_records_sp @consolidation_no	
END

-- v2.9 End

-- v3.2 Start
SET @consolidation_no = NULL
SELECT	@consolidation_no = consolidation_no 
FROM	cvo_masterpack_consolidation_det (NOLOCK) 
WHERE	order_no = @order_no
AND		order_ext = @order_ext

IF (@consolidation_no IS NOT NULL)
BEGIN

	DELETE	cvo_masterpack_consolidation_det
	WHERE	order_no = @order_no
	AND		order_ext = @order_ext

	UPDATE	cvo_orders_all 
	SET		st_consolidate = 0
	WHERE	order_no = @order_no
	AND		ext = @order_ext

	IF NOT EXISTS (SELECT 1 FROM cvo_masterpack_consolidation_det (NOLOCK) WHERE consolidation_no = @consolidation_no)
	BEGIN
		DELETE	cvo_masterpack_consolidation_hdr
		WHERE	consolidation_no = @consolidation_no

		DELETE  cvo_st_consolidate_release
		WHERE	consolidation_no = @consolidation_no
		
	END
END
-- v3.2 End

COMMIT TRAN  

-- v2.2 Start
-- v2.7 EXEC @iret = dbo.cvo_hold_ship_complete_allocations_sp @order_no, @order_ext
-- v2.2 End

  
RETURN   
GO

GRANT EXECUTE ON  [dbo].[tdc_plw_so_allocbylot_process_sp] TO [public]
GO
