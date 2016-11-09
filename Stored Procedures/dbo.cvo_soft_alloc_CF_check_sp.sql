SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_soft_alloc_CF_check_sp]	@PWB int = 0
AS
BEGIN  
  
 -- Directives  
 SET NOCOUNT ON  
  
   
 -- Declarations  
 DECLARE @order_no   int,  
		@order_ext   int,  
		@soft_alloc_no  int,  
		@last_soft_alloc_no int,  
		@id     int,  
		@last_id   int,  
		@line_no   int,  
		@location   varchar(10),  
		@part_no   varchar(30),  
		@in_stock   decimal(20,8), 
		@in_stock_ex decimal(20,8), -- v1.9
		@alloc_qty   decimal(20,8),  
		@quar_qty   decimal(20,8),  
		@sa_qty    decimal(20,8),  
		@qty    decimal(20,8), -- v1.1  
		@replen_qty	DECIMAL(20,8), -- v2.2
		@part_type varchar(5) -- v2.5
  
 -- Create Working Table  
 CREATE TABLE #cf_break (id    int identity(1,1),  
       soft_alloc_no int,  
       location  varchar(10),  
       line_no   int,  
       part_no   varchar(30),  
       qty    decimal(20,8),
	   part_type varchar(5), -- v2.5  
       no_stock  int)  

 CREATE INDEX #cf_break_ind0 ON #cf_break(id,soft_alloc_no,line_no,no_stock) -- v1.9
  
 CREATE TABLE #cf_break_kit   
         (id    int identity(1,1),  
       soft_alloc_no int,  
       location  varchar(10),  
       qty    decimal(20,8), -- v1.1  
       kit_line_no  int,  
       kit_part_no  varchar(30),  
       no_stock  int)  

CREATE INDEX #cf_break_kit_ind0 ON #cf_break_kit(id,soft_alloc_no,kit_line_no,no_stock) -- v1.9
  
 CREATE TABLE #wms_ret ( location  varchar(10),  
       part_no   varchar(30),  
       allocated_qty decimal(20,8),  
       quarantined_qty decimal(20,8),  
       apptype   varchar(20))  
  
 CREATE TABLE #cf_allocs (  
       soft_alloc_no int,  
       order_no  int,  
       order_ext  int,  
       no_stock  int)  

 CREATE index #cf_allocs_ind0 ON #cf_allocs (soft_alloc_no) -- v1.9
   
 -- v1.2 Start  
 CREATE TABLE #cf_allocs_line (  
       order_no  int,  
       order_ext  int,  
       line_no   int,  
       no_stock  int)   
 -- v1.2 End  
  
CREATE INDEX #cf_allocs_line_ind0 ON #cf_allocs_line(order_no,order_ext,line_no,no_stock) -- v1.9

 -- Run through the soft allocations where there are custom frames  
 -- v1.3 Start  
 IF (@PWB = 0)  
 BEGIN  
  INSERT #cf_allocs (soft_alloc_no, order_no, order_ext, no_stock)  
  SELECT DISTINCT a.soft_alloc_no,  
    a.order_no,  
    a.order_ext,  
    0  
  FROM cvo_soft_alloc_hdr a (NOLOCK)  
  JOIN cvo_ord_list b (NOLOCK)  
  ON  a.order_no = b.order_no  
  AND  a.order_ext = b.order_ext  
  WHERE a.status = 0  
  AND  a.bo_hold = 0  
  AND  b.is_customized = 'S'  
 END  
 ELSE  
 BEGIN  
  CREATE TABLE #ord (id int IDENTITY(1,1), order_no int, order_ext int, no_stock int)  
  
  INSERT #ord (order_no, order_ext, no_stock)  
  SELECT DISTINCT a.order_no,  
    a.order_ext,  
    0  
  FROM #so_alloc_management a (NOLOCK)  
  JOIN cvo_ord_list b (NOLOCK)  
  ON  a.order_no = b.order_no  
  AND  a.order_ext = b.order_ext  
  WHERE a.sel_flg = -1  
  AND  b.is_customized = 'S'  
  
  INSERT #cf_allocs (soft_alloc_no, order_no, order_ext, no_stock)  
  SELECT id, order_no, order_ext, no_stock  
  FROM #ord  
  
  DROP TABLE #ord  
  
 END  
 -- v1.3 End  
  
 SET @last_soft_alloc_no = 0  
  
 SELECT TOP 1 @soft_alloc_no = soft_alloc_no,  
   @order_no = order_no,  
   @order_ext = order_ext  
 FROM #cf_allocs  
 WHERE soft_alloc_no > @last_soft_alloc_no  
 ORDER BY soft_alloc_no ASC  
  
 WHILE @@ROWCOUNT <> 0  
 BEGIN  
  
  DELETE #cf_break  
  DELETE #cf_break_kit  
  
  -- Get a list of the custom frame breaks from the order  
  INSERT #cf_break (soft_alloc_no, location, line_no, part_no, qty, part_type, no_stock) -- v2.5
  SELECT DISTINCT @soft_alloc_no,  
    a.location,  
    a.line_no,  
    a.part_no,  
    a.ordered, 
	a.part_type, -- v2.5 
    0  
  FROM ord_list a (NOLOCK)  
  JOIN cvo_ord_list_kit b (NOLOCK)  
  ON  a.order_no = b.order_no  
  AND  a.order_ext = b.order_ext  
  AND  a.line_no = b.line_no  
  WHERE a.order_no = @order_no  
  AND  a.order_ext = @order_ext  
  AND  b.replaced = 'S'  
-- v2.5  AND  a.part_type <> 'C' -- v2.4 


  INSERT #cf_break_kit (soft_alloc_no, location, qty, kit_line_no, kit_part_no, no_stock) -- v1.1 add qty  
  SELECT @soft_alloc_no,  
    b.location,  
    b.ordered, -- v1.1  
    a.line_no,  
    a.part_no,  
    0  
  FROM cvo_ord_list_kit a (NOLOCK)  
  JOIN ord_list b (NOLOCK)  
  ON  a.order_no = b.order_no  
  AND  a.order_ext = b.order_ext  
  AND  a.line_no = b.line_no  
  WHERE a.order_no = @order_no  
  AND  a.order_ext = @order_ext  
  AND  a.replaced = 'S'  
  
  IF EXISTS (SELECT 1 FROM #cf_break) -- Test for substitution at frame level  
  BEGIN  
   SET @last_id = 0  
  
   SELECT TOP 1 @id = id,  
     @location = location,  
     @line_no = line_no,  
     @part_no = part_no, 
	 @part_type = part_type, -- v2.5
     @qty = qty -- v1.1  
   FROM #cf_break  
   WHERE id > @last_id  
   ORDER BY id ASC  
  
   WHILE @@ROWCOUNT <> 0  
   BEGIN  
    -- v1.8 Start  
    SET @in_stock = 0  
	SET @in_stock_ex = 0 -- v1.9
    SET @alloc_qty = 0  
    SET @quar_qty = 0  
    SET @sa_qty = 0  
    -- v1.8 End  
  
    -- Inventory - in stock  
	-- v1.9 Start
--    SELECT @in_stock = in_stock  
--    FROM inventory (NOLOCK)  
--    WHERE location = @location  
--    AND  part_no = @part_no  

	-- v2.5 Start
	IF (@part_type = 'C')
	BEGIN
		SET @last_id = @id  
	  
		SELECT TOP 1 @id = id,  
		  @location = location,  
		  @line_no = line_no,  
		  @part_no = part_no,  
		  @part_type = part_type, -- v2.5
		  @qty = qty -- v1.1  
		FROM #cf_break  
		WHERE id > @last_id  
		ORDER BY id ASC  

		CONTINUE
	END
	-- v2.5 End

    SELECT	@in_stock = SUM(qty)
    FROM	lot_bin_stock (NOLOCK)
    WHERE	location = @location  
    AND		part_no = @part_no  

    SELECT	@in_stock_ex = SUM(qty)
    FROM	cvo_lot_bin_stock_exclusions (NOLOCK)
    WHERE	location = @location  
    AND		part_no = @part_no  

	SET	 @in_stock = ISNULL(@in_stock,0) - ISNULL(@in_stock_ex,0)
	-- v1.9 End	

	-- START v2.2
	SET @replen_qty = 0
	SELECT	@replen_qty = ISNULL(replen_qty,0) 
    FROM cvo_inventory2 (NOLOCK) -- v2.3 
    WHERE location = @location  
    AND  part_no = @part_no 

	SET @in_stock = @in_stock - @replen_qty
	-- END v2.2

  
    -- WMS - allocated and quarantined  
    DELETE #wms_ret  
  
    INSERT #wms_ret  
    EXEC tdc_get_alloc_qntd_sp @location, @part_no  
  
    SELECT @alloc_qty = allocated_qty,  
      @quar_qty = quarantined_qty  
    FROM #wms_ret  
  
    IF (@alloc_qty IS NULL)  
     SET @alloc_qty = 0  
  
    IF (@quar_qty IS NULL)  
     SET @quar_qty = 0  
  
    -- Soft Allocation - commited quantity  
    /* v1.4 Start  
    SELECT @sa_qty = ISNULL(CASE WHEN SUM(b.qty) IS NULL   
          THEN SUM(CASE WHEN a.deleted = 1 THEN (a.quantity * -1) ELSE a.quantity END)   
          ELSE SUM(CASE WHEN a.deleted = 1 THEN (a.quantity * -1) ELSE a.quantity END) - SUM(b.qty) END,0)  
    FROM dbo.cvo_soft_alloc_det a (NOLOCK)  
    LEFT JOIN  
      dbo.tdc_soft_alloc_tbl b (NOLOCK)  
    ON  a.order_no = b.order_no  
    AND  a.order_ext = b.order_ext  
    AND  a.line_no = b.line_no  
    AND  a.part_no = b.part_no  
    WHERE a.status IN (0, 1, -1, -3)  
    AND  (CAST(a.order_no AS varchar(10)) + CAST(a.order_ext AS varchar(5))) <> (CAST(b.order_no AS varchar(10)) + CAST(b.order_ext AS varchar(5)))    
    AND  a.location = @location  
    AND  a.part_no = @part_no  
    AND  ISNULL(b.order_type,'S') = 'S' */  
  
    SELECT @sa_qty = ISNULL(SUM(CASE WHEN a.deleted = 1 THEN (a.quantity * -1) ELSE a.quantity END),0)  
    FROM dbo.cvo_soft_alloc_det a (NOLOCK)  
    WHERE a.status IN (0, 1, -1, -4) -- v2.1 include -4  
    AND  a.soft_alloc_no < @soft_alloc_no -- v2.1 
-- v2.1    AND  (CAST(a.order_no AS varchar(10)) + CAST(a.order_ext AS varchar(5))) <> (CAST(@order_no AS varchar(10)) + CAST(@order_ext AS varchar(5)))    
    AND  a.location = @location  
    AND  a.part_no = @part_no  
    -- v1.4 End  
  
    IF (@sa_qty IS NULL)  
     SET @sa_qty = 0  
  
    -- Compare - if no stock available then mark the record  
    IF ((@in_stock - (@alloc_qty + @quar_qty + @sa_qty)) < @qty) -- <= 0) v1.1 Check against order quantity  
    BEGIN  
     UPDATE #cf_break  
     SET  no_stock = 1  
     WHERE id = @id  
   
     -- v1.2 Start  
     INSERT #cf_allocs_line (order_no, order_ext, line_no, no_stock)  
     SELECT @order_no, @order_ext, @line_no, 1  
     -- v1.2 End  
  
    END  
  
    SET @last_id = @id  
  
    SELECT TOP 1 @id = id,  
      @location = location,  
      @line_no = line_no,  
      @part_no = part_no,  
	  @part_type = part_type, -- v2.5
      @qty = qty -- v1.1  
    FROM #cf_break  
    WHERE id > @last_id  
    ORDER BY id ASC  
  
   END  
  END  
    
  IF EXISTS (SELECT 1 FROM #cf_break_kit) -- Test for substitution at kit level  
  BEGIN  
   SET @last_id = 0  
  
   SELECT TOP 1 @id = id,  
     @location = location,  
     @qty = qty, -- v1.1  
     @line_no = kit_line_no,  
     @part_no = kit_part_no  
   FROM #cf_break_kit  
   WHERE id > @last_id  
   ORDER BY id ASC  
  
   WHILE @@ROWCOUNT <> 0  
   BEGIN  
  
    -- v1.8 Start  
    SET @in_stock = 0  
	SET @in_stock_ex = 0 -- v1.9
    SET @alloc_qty = 0  
    SET @quar_qty = 0  
    SET @sa_qty = 0  
    -- v1.8 End  
  
    -- Inventory - in stock  
	-- v1.9 Start
--    SELECT @in_stock = in_stock  
--    FROM inventory (NOLOCK)  
--    WHERE location = @location  
--    AND  part_no = @part_no  

    SELECT	@in_stock = SUM(qty)
    FROM	lot_bin_stock (NOLOCK)
    WHERE	location = @location  
    AND		part_no = @part_no  

    SELECT	@in_stock_ex = SUM(qty)
    FROM	cvo_lot_bin_stock_exclusions (NOLOCK)
    WHERE	location = @location  
    AND		part_no = @part_no  

	SET	 @in_stock = ISNULL(@in_stock,0) - ISNULL(@in_stock_ex,0)
	-- v1.9 End	

	-- START v2.2
	SET @replen_qty = 0
	SELECT	@replen_qty = ISNULL(replen_qty,0) 
    FROM cvo_inventory2 (NOLOCK)  -- v2.3
    WHERE location = @location  
    AND  part_no = @part_no 

	SET @in_stock = @in_stock - @replen_qty
	-- END v2.2
  
    -- WMS - allocated and quarantined  
    DELETE #wms_ret  
    
    INSERT #wms_ret  
    EXEC tdc_get_alloc_qntd_sp @location, @part_no  
  
    SELECT @alloc_qty = allocated_qty,  
      @quar_qty = quarantined_qty  
    FROM #wms_ret  
  
    IF (@alloc_qty IS NULL)  
     SET @alloc_qty = 0  
  
    IF (@quar_qty IS NULL)  
     SET @quar_qty = 0  
  
    -- Soft Allocation - commited quantity  
    /* v1.4 Start  
    SELECT @sa_qty = ISNULL(CASE WHEN SUM(b.qty) IS NULL   
          THEN SUM(CASE WHEN a.deleted = 1 THEN (a.quantity * -1) ELSE a.quantity END)   
          ELSE SUM(CASE WHEN a.deleted = 1 THEN (a.quantity * -1) ELSE a.quantity END) - SUM(b.qty) END,0)  
    FROM dbo.cvo_soft_alloc_det a (NOLOCK)  
    LEFT JOIN  
      dbo.tdc_soft_alloc_tbl b (NOLOCK)  
    ON  a.order_no = b.order_no  
    AND  a.order_ext = b.order_ext  
    AND  a.line_no = b.line_no  
    AND  a.part_no = b.part_no  
    WHERE a.status IN (0, 1, -1, -3)  
    AND  (CAST(a.order_no AS varchar(10)) + CAST(a.order_ext AS varchar(5))) <> (CAST(b.order_no AS varchar(10)) + CAST(b.order_ext AS varchar(5)))    
    AND  a.location = @location  
    AND  a.part_no = @part_no  
    AND  ISNULL(b.order_type,'S') = 'S' */  
  
    SELECT @sa_qty = ISNULL(SUM(CASE WHEN a.deleted = 1 THEN (a.quantity * -1) ELSE a.quantity END),0)  
    FROM dbo.cvo_soft_alloc_det a (NOLOCK)  
    WHERE a.status IN (0, 1, -1, -4) -- v2.1 include -4  
    AND  a.soft_alloc_no < @soft_alloc_no -- v2.1 
-- v2.1    AND  (CAST(a.order_no AS varchar(10)) + CAST(a.order_ext AS varchar(5))) <> (CAST(@order_no AS varchar(10)) + CAST(@order_ext AS varchar(5)))    
    AND  a.location = @location  
    AND  a.part_no = @part_no  
    -- v1.4 End  
  
    IF (@sa_qty IS NULL)  
     SET @sa_qty = 0  
  
    -- Compare - if no stock available then mark the record  
    IF ((@in_stock - (@alloc_qty + @quar_qty + @sa_qty)) < @qty) --<= 0) v1.1 Check against order qty  
    BEGIN  
     UPDATE #cf_break_kit  
     SET  no_stock = 1  
     WHERE id = @id  
  
     -- v1.2 Start  
     INSERT #cf_allocs_line (order_no, order_ext, line_no, no_stock)  
     SELECT @order_no, @order_ext, @line_no, 1  
     -- v1.2 End  
  
    END  
  
    SET @last_id = @id  
  
    SELECT TOP 1 @id = id,  
      @location = location,  
      @qty = qty, -- v1.1  
      @line_no = kit_line_no,  
      @part_no = kit_part_no  
    FROM #cf_break_kit  
    WHERE id > @last_id  
    ORDER BY id ASC  
  
   END  
  END  
  
  -- Mark the frame record if no stock available for the substitution  
  UPDATE a  
  SET  no_stock = 1  
  FROM #cf_break a  
  JOIN #cf_break_kit b  
  ON  a.soft_alloc_no = b.soft_alloc_no  
  AND  a.line_no = b.kit_line_no  
  WHERE b.no_stock = 1  
  
  -- Mark the data to be returned to show no stock is available  
  UPDATE a  
  SET  no_stock = 1  
  FROM #cf_allocs a  
  JOIN #cf_break b  
  ON  a.soft_alloc_no = b.soft_alloc_no  
  WHERE b.no_stock = 1  
  
  SET @last_soft_alloc_no = @soft_alloc_no  
  
  SELECT TOP 1 @soft_alloc_no = soft_alloc_no,  
    @order_no = order_no,  
    @order_ext = order_ext  
  FROM #cf_allocs  
  WHERE soft_alloc_no > @last_soft_alloc_no  
  ORDER BY soft_alloc_no ASC  
   
 END   
  
 INSERT #exclusions (order_no, order_ext)  
 SELECT order_no, order_ext FROM #cf_allocs WHERE no_stock = 1  
  
 -- v1.2 Start - Does the order have regular frames and is ship complete  
 UPDATE a  
 SET  has_line_exc = 1  
 FROM #exclusions a  
 JOIN #cf_allocs b  
 ON  a.order_no = b.order_no  
 AND  a.order_ext = b.order_ext  
 JOIN cvo_ord_list c (NOLOCK)  
 ON  a.order_no = c.order_no  
 AND  a.order_ext = c.order_ext  
 JOIN orders_all o (NOLOCK)  
 ON  a.order_no = o.order_no  
 AND  a.order_ext = o.ext  
 WHERE c.is_case = 0   
 AND  c.is_pattern = 0   
 AND  c.is_polarized = 0   
 AND  c.is_pop_gif = 0   
 AND  c.is_customized = 'N'  
 AND  o.back_ord_flag = 1  
  
 -- Record which lines need to be excluded from the allocation  
 INSERT #line_exclusions (order_no, order_ext, line_no)  
 SELECT DISTINCT a.order_no, a.order_ext, a.line_no  
 FROM cvo_ord_list a (NOLOCK)  
 JOIN #exclusions b  
 ON  a.order_no = b.order_no  
 AND  a.order_ext = b.order_ext  
 JOIN #cf_allocs_line c  
 ON  a.order_no = c.order_no  
 AND  a.order_ext = c.order_ext  
 AND  a.line_no = c.line_no  
 WHERE a.is_case = 0   
 AND  a.is_pattern = 0   
 AND  a.is_polarized = 0   
 AND  a.is_pop_gif = 0   
 AND  a.is_customized = 'S'  
 --AND  ISNULL(b.has_line_exc,0) = 1  -- v2.0
 AND  c.no_stock = 1  
  
 -- v1.7 Start  
 -- v1.6 Start  
-- IF OBJECT_ID('tempdb..#no_stock_orders') IS NOT NULL  
-- BEGIN  
--  -- v1.5 Start  
--  INSERT #no_stock_orders (order_no, order_ext, line_no, no_stock)  
--  SELECT DISTINCT a.order_no, a.order_ext, a.line_no, 1  
--  FROM cvo_ord_list a (NOLOCK)  
--  JOIN #exclusions b  
--  ON  a.order_no = b.order_no  
--  AND  a.order_ext = b.order_ext  
--  JOIN #cf_allocs_line c  
--  ON  a.order_no = c.order_no  
--  AND  a.order_ext = c.order_ext  
--  AND  a.line_no = c.line_no  
--  WHERE a.is_case = 0   
--  AND  a.is_pattern = 0   
--  AND  a.is_polarized = 0   
--  AND  a.is_pop_gif = 0   
--  AND  a.is_customized = 'S'  
--  AND  ISNULL(b.has_line_exc,0) = 1  
--  AND  c.no_stock = 1   
--  -- v1.5 End  
-- END  
 -- v1.6  
-- v1.7 End  
  
 DELETE #exclusions  
 WHERE ISNULL(has_line_exc,0) = 1  
  
 -- v1.2 End  
  
 DROP TABLE #cf_allocs  
 DROP TABLE #cf_break  
 DROP TABLE #cf_break_kit  
 DROP TABLE #wms_ret  
 DROP TABLE #cf_allocs_line -- v1.2  
  
END  
GO
GRANT EXECUTE ON  [dbo].[cvo_soft_alloc_CF_check_sp] TO [public]
GO
