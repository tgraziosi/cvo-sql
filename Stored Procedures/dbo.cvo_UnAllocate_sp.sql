
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_UnAllocate_sp]	@order_no	int,
									@order_ext	int,
									@force		int = 0,
									@user_id	varchar(50) = '', -- v1.5
									@recreate	int = 0 -- v2.0
									
AS
BEGIN
  
 -- DECLARATIONS  
 DECLARE @con_no   int,  
   @custom_bin  varchar(12),  
   @qty_to_remove decimal(20,8),  
   @tran_id  int,  
   @last_tran_id int,  
   @part_no  varchar(30),  
   @from_bin  varchar(12),  
   @to_bin   varchar(12),  
   @line_no  int,  
   @last_line  int,
   @consolidation_no int -- v2.2
  
      -- If order# = 0 this is initial creation we exit  
      IF @order_no = 0  
      BEGIN  
            SELECT '0'  
            RETURN 0  
      END  
  
 -- v1.4  
 IF (SELECT COUNT(1) FROM dbo.orders (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext) = 0  
 BEGIN  
            SELECT '0'  
            RETURN 0  
 END  
    
 -- If the order is not on a status of 'N' New or 'V' Void then return  
 IF NOT EXISTS (SELECT 1 FROM dbo.orders (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext AND status IN ('N','V','A','H','B')) -- v1.2  
 BEGIN  
  -- v1.1 Allow line to be deleted if status is P as long as its not allocated, picked or packed  
  IF EXISTS (SELECT 1 FROM dbo.orders (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext AND status IN ('Q','P'))  
  BEGIN  
   IF EXISTS (SELECT 1 FROM dbo.tdc_soft_alloc_tbl (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext)  
   BEGIN  
    SELECT '-1'  
    RETURN -1  
   END  
   IF EXISTS (SELECT 1 FROM dbo.tdc_dist_item_pick (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext)  
   BEGIN  
    SELECT '-1'  
    RETURN -1  
   END  
   IF EXISTS (SELECT 1 FROM dbo.tdc_dist_item_list (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND shipped > 0)  
   BEGIN  
    SELECT '-1'  
    RETURN -1  
   END  
  END  
  ELSE  
  BEGIN  
   IF NOT EXISTS (SELECT 1 FROM dbo.orders (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext AND status IN ('C'))  
   BEGIN  
    SELECT '-1'  
    RETURN -1  
   END  
  END  
 END  
  
 SELECT @con_no = consolidation_no  
 FROM dbo.tdc_cons_ords (NOLOCK)  
 WHERE order_no = @order_no  
 AND  order_ext = @order_ext  
 AND  order_type = 'S'  
  
 IF @con_no IS NULL  
 BEGIN  
  SELECT '0'  
  RETURN 0  
 END  
  
 IF EXISTS (SELECT 1 FROM dbo.tdc_pick_queue (NOLOCK) WHERE trans_type_no = @order_no  
    AND trans_type_ext = @order_ext AND tx_lock NOT IN ('H','R','E'))  
 BEGIN  
  SELECT '-1'  
  RETURN -1  
 END  
  
  
 -- The allocation was created with the auto allocation  
-- IF (EXISTS (SELECT 1 FROM dbo.tdc_main (NOLOCK) WHERE consolidation_no = @con_no AND created_by = 'AUTO_ALLOC') OR @force = 1)  -- v1.6
 BEGIN  
  SET @last_line = 0  
  
  SELECT TOP 1 @line_no = line_no   
  FROM ord_list (NOLOCK)  
  WHERE order_no = @order_no  
  AND  order_ext = @order_ext  
  AND  line_no > @last_line  
  ORDER BY line_no ASC  
  
  WHILE @@ROWCOUNT <> 0  
  BEGIN  
  
   -- Check the tdc_pick_queue - if a record does not exist then the order has been picked  
--   IF NOT EXISTS (SELECT 1 FROM dbo.tdc_pick_queue (NOLOCK) WHERE trans_type_no = @order_no   
--       AND trans_type_ext = @order_ext AND line_no = @line_no  
--       AND trans = 'STDPICK')  
--   BEGIN  
--    SELECT '-1'  
--    RETURN -1  
--   END  
  
  
   -- If any of the order is picked then return  
   IF EXISTS (SELECT 1 FROM dbo.tdc_dist_item_list (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext  
      AND line_no = @line_no AND [function] = 'S' AND shipped > 0)  
   BEGIN  
    SELECT '-1'  
    RETURN -1  
   END  
  
   SELECT @custom_bin = ISNULL(value_str,'CUSTOM') FROM tdc_config (NOLOCK) WHERE [function] = 'CVO_CUSTOM_BIN'  
  
   -- Does the line have any substitutions   
   IF EXISTS (SELECT 1 FROM dbo.tdc_pick_queue (NOLOCK) WHERE trans_type_no = @order_no   
       AND trans_type_ext = @order_ext AND line_no = @line_no  
       AND trans = 'MGTB2B')  
   BEGIN  
    SET @last_tran_id = 0  
  
    SELECT TOP 1 @tran_id = tran_id,  
      @part_no = part_no,  
      @qty_to_remove = qty_to_process,  
      @from_bin = bin_no,  
      @to_bin = next_op  
    FROM dbo.tdc_pick_queue (NOLOCK)  
    WHERE trans_type_no = @order_no   
    AND  trans_type_ext = @order_ext   
    AND  line_no = @line_no  
    AND  trans = 'MGTB2B'  
  
    WHILE @@rowcount <> 0  
    BEGIN  
  
     UPDATE dbo.tdc_soft_alloc_tbl  
     SET  qty = qty - @qty_to_remove  
     WHERE part_no = @part_no  
     AND  bin_no = @from_bin  
     AND  dest_bin = @to_bin  
     AND  order_no = 0  
  
     DELETE dbo.tdc_pick_queue  
     WHERE tran_id = @tran_id  
  
     SET @last_tran_id = @tran_id  
  
     SELECT TOP 1 @tran_id = tran_id,  
       @part_no = part_no,  
       @qty_to_remove = qty_to_process  
     FROM dbo.tdc_pick_queue (NOLOCK)  
     WHERE trans_type_no = @order_no   
     AND  trans_type_ext = @order_ext   
     AND  line_no = @line_no  
     AND  trans = 'MGTB2B'  
  
    END  
  
   END  
  
	-- v1.5
	INSERT	tdc_log (tran_date, userid, trans_source, module, trans, tran_no, tran_ext, part_no, lot_ser, bin_no, quantity, location, data)
	SELECT	getdate(), @user_id, 'VB', 'PLW', 'UNALLOCATION', @order_no, @order_ext, part_no, lot, 
				bin_no, qty_to_process, location, 'REMOVED from tdc_pick_queue. Line number = ' + CAST(line_no as varchar(10))
	FROM	tdc_pick_queue (NOLOCK)
	WHERE	trans_type_no = @order_no 
	AND		trans_type_ext = @order_ext
	AND		line_no = @line_no
	AND		trans = 'STDPICK'
	
	-- START v1.8
	-- v1.7
	--EXEC dbo.cvo_remove_order_from_autopack_carton_sp @order_no, @order_ext
	-- END v1.8

   DELETE dbo.tdc_pick_queue   
   WHERE trans_type_no = @order_no   
   AND  trans_type_ext = @order_ext  
   AND  line_no = @line_no  
   AND  trans = 'STDPICK'  
  
   DELETE dbo.tdc_soft_alloc_tbl  
   WHERE order_no = @order_no   
   AND  order_ext = @order_ext  
   AND  line_no = @line_no  
   AND  order_type = 'S'  
  
   DELETE dbo.tdc_ord_list_kit  
   WHERE order_no = @order_no   
   AND  order_ext = @order_ext  
   AND  line_no = @line_no  
  
   SET @last_line = @line_no  
  
   SELECT TOP 1 @line_no = line_no   
   FROM ord_list (NOLOCK)  
   WHERE order_no = @order_no  
   AND  order_ext = @order_ext  
   AND  line_no > @last_line  
   ORDER BY line_no ASC  
  
  END  
  
 END  

 -- v1.9 Start
 DELETE	tdc_cons_ords
 WHERE	order_no = @order_no
 AND	order_ext = @order_ext
 -- v1.9 End


 -- START v1.8
 EXEC dbo.CVO_build_autopack_carton_sp @order_no, @order_ext
 -- END v1.8  

-- v2.2 Start
IF EXISTS (SELECT 1 FROM cvo_masterpack_consolidation_det (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext)
BEGIN
	SELECT	@consolidation_no = consolidation_no
	FROM	cvo_masterpack_consolidation_det (NOLOCK)
	WHERE	order_no = @order_no 
	AND		order_ext = @order_ext

	EXEC cvo_masterpack_unconsolidate_pick_records_sp @consolidation_no

END
-- v2.2 End

-- v2.0 Start
IF (@recreate <> 0)
BEGIN
	-- v2.1 Start
	DELETE	cvo_soft_alloc_det WHERE order_no = @order_no AND order_ext = @order_ext
	DELETE	cvo_soft_alloc_hdr WHERE order_no = @order_no AND order_ext = @order_ext
	-- v2.1 End
	EXEC dbo.cvo_recreate_sa_sp @order_no, @order_ext
END
-- v2.0 End

 SELECT '0'  
 RETURN 0  
  
END
GO

GRANT EXECUTE ON  [dbo].[cvo_UnAllocate_sp] TO [public]
GO
