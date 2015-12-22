SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
  
/*AMENDEZ: This sp follows the next formula  
  
(on hand + N days of Ordered + Qty in Cuarentine) / ( X weeks / 52)  
  
exec CT_SearchStock_sp 'ALBA','001',0,'','',2,'BCBG'  
exec Cvo_SearchStock_sp 'ALBA','001',0,'','',2,'BCBG'  

  
*/  
-- v1.1 CB 12/21/2010 - Implement virtual stock. If no stock is available then use virtual stock  
-- Virtual stock is determined by the number of items sold  
  
-- v1.2 CB 01/07/2011 - Code the color and size changes as these were never done  
-- v1.3 CB 01/14/2011 - Remove the qty check on colour and size balancing  
-- v1.4 CB 12/04/2011 - Matrix Further Modifications  
-- v1.5 CT 19/05/2011 - Matrix screen modification, display results in a table (size by color)  
-- v1.6 CB 26/05/2011 - Exclude obsolete and un sellable items  
-- v1.7 CT 01/06/2011 - Corrected length of color field in #sizes table   
-- v1.8 CT 01/06/2011 - Corrected an issue which caused duplicate parts to be selected when there are more than 1 quarantine bins containing a part  
-- v1.9 CT 01/06/2011 - Corrected issue with figure being returned for stock on back order  
-- v2.0 CB 09/06/2011 - Use the backorder date  
-- v2.1 CB 01/07/2011 - 68668-014 - Add group  
-- v2.2 CB 12/07/2011 - Add in sales order history  
-- v2.3 CT 31/08/2011 - Amended join to include index  
-- v2.4 CB 07/09/2011 - Performance Changes  
-- v2.5 CB 20/10/2011 - Performance changes  
-- v2.6 CT 24/10/2011 - When calculatiing backorder amount, ignore orders with allocation date > today, or blank or 00/00/00  
-- v2.7 CB 11/06/2012 - Exclude obsolete stock  
-- v2.8 CB 15/06/2012 - Include obsolete stock if stock available  
-- v2.9 CT 02/07/2012 - Subtract qty on replenishment moves from available qty  
-- v3.0 CT 09/07/2012 - Cater for NULL replen qty    
  
CREATE PROCEDURE  [dbo].[CT_SearchStock_sp] @stile VARCHAR(100),     
            @location VARCHAR(20),     
            @qty DECIMAL(20, 8),     
            @GpoColor VARCHAR(MAX),    
            @GpoSize VARCHAR(MAX),  
            @UseVirtualStock INT = 0, -- v1.1 -- v1.4 Now used as Type Option  
            @group VARCHAR(20)  
AS    
BEGIN    
 DECLARE  @id        INT,    
    @part_no      VARCHAR(50),    
    @loc       VARCHAR(25),    
    @qty_available     decimal(20,8), -- v1.4  
    @qty_on_order     decimal(20,8), -- v1.4  
    @qty_on_backorder    decimal(20,8), -- v1.4  
    @qty_sold      decimal(20,8), -- v1.4  
    @sold_weeks      decimal(20,8), -- v1.4  
    @date_52_weeks     DATETIME,    
    @timefence      INT,  
    @MinWeeks      INT,    
    @oldest_shipment_date   DATETIME,  
    @weeks_supply     decimal(20,8), -- v1.4  
    @colour_count     int,  
    @colour       varchar(255),  
    @last_colour     varchar(255),  
    @eye_count      int,  
    @loop_count      int,  
    @old_part      varchar(30),  
    @eye_size      int,  
    @last_eye      int,  
    @qty_selected     int,  
    @qty_needed      int,  
    @weeks       decimal(20,8), -- v1.4  
    @temp_loop      int,  
    @last_id      int,  
    @temp_id      int,  
    @temp_colour     varchar(20),  
    @temp_size      int,  
    @temp_weeks      int,  
    @max_id       int,  
    @first       int,  
    @temp_loop_count    int,  
    @best_id      int,  
    @temp       int,  
    @minus_sum      int,  
    @minus_count     int,  
    @minus_avg      float,  
    @qty_alloc      decimal(20,8),  
    @config_str      varchar(100) -- v2.5  
  
  
 CREATE TABLE #temp (    
   id    INT IDENTITY (1,1),    
   part_no   VARCHAR(50),    
   color   VARCHAR(255),    
   eye_size  DECIMAL(20, 8),    
   qty_availa  DECIMAL(20, 8),    
   qty_sugest  DECIMAL(20, 8),    
   style   VARCHAR(50),    
   location  VARCHAR(20),    
   uom    VARCHAR(10),    
   price   DECIMAL(20,8),    
   status   VARCHAR(10),    
   [description] VARCHAR(250),    
   part_type  VARCHAR(10),    
   weeks   DECIMAL(20, 8),    
   ratio   DECIMAL(20, 8),    
   remaining  DECIMAL(20, 8),    
   qty_on_sales DECIMAL(20, 8),    
   qty_total  DECIMAL(20, 8),    
   qty_qc   DECIMAL(20, 8),  
   virtual_stock smallint,  
   priority  DECIMAL(20, 8),  
   average   FLOAT default 0, -- v1.4  
   backorder  DECIMAL(20,8) default 0, -- v1.4  
   quantity  DECIMAL(20,8) default 0, -- v1.4    
   obsolete  INT) -- v2.8  
  
 CREATE INDEX #temp_ind0 ON #temp(id)  
 CREATE INDEX #temp_ind1 ON #temp(location, part_no)  
  
 CREATE TABLE #temp2 (  
   id   int identity,   
   part_no  varchar(30))  
  
 CREATE TABLE #eye_size (  
   size  int,   
   used  int)  
  
 CREATE TABLE #colour (  
   colours  varchar(255),   
   used  int)  
  
 CREATE TABLE #results (  
   id   int,   
   score  int,   
   dev   float,   
   min_val  float)  
  
 -- v2.5  
 CREATE TABLE #excluded_stock (  
   location varchar(10),  
   part_no  varchar(30),  
   qty   decimal(20,8))   
  
 CREATE INDEX #excluded_stock_ind1 ON #excluded_stock(location, part_no)  
    
 SELECT @location = @location + '%'    
 SELECT @stile = @stile --+ '%'    
    
 -- v2.5 Use base tables instead of inventory view  
 -- v2.8 Add obsolete  
 INSERT INTO #temp (part_no, color, eye_size, qty_availa, qty_sugest, style, location, uom, price, status, [description], part_type, remaining, qty_qc, virtual_stock, priority, obsolete)    
 SELECT  a.part_no,   
    a.field_3,   
    a.field_17,   
    case when (m.status='C' or m.status='V') then (0 - s.commit_ed - p.sch_alloc - x.commit_ed)    
    else (l.in_stock + l.issued_mtd + p.produced_mtd - p.usage_mtd - s.sales_qty_mtd + r.recv_mtd + x.xfer_mtd) end, -- v2.9 & v3.0  
    0,   
    a.field_2,   
    l.location,   
    m.uom,   
    pr.price_a,   
    l.status,   
    m.[description],   
    m.type_code,   
    0,   
    isnull(qty_qc, 0),  
    0,   
    0,  
    ISNULL(m.obsolete,0) -- v2.8     
 FROM  inv_master_add a (NOLOCK)  
 JOIN  inv_master m (NOLOCK) ON a.part_no = m.part_no  
 JOIN  inv_list l (NOLOCK) ON m.part_no = l.part_no  
 JOIN  inv_sales s (NOLOCK) ON l.location = s.location AND l.part_no = s.part_no  
 JOIN  inv_produce p (NOLOCK) ON l.location = p.location AND l.part_no = p.part_no  
 JOIN  inv_recv r (NOLOCK) ON l.location = r.location AND l.part_no = r.part_no  
 JOIN  inv_xfer x (NOLOCK) ON l.location = x.location AND l.part_no = x.part_no  
 JOIN  glco g (NOLOCK) ON 1=1    
 LEFT JOIN part_price pr (NOLOCK) ON m.part_no = pr.part_no AND g.home_currency = pr.curr_key    
 LEFT JOIN ( SELECT SUM(lbs.qty) qty_qc, -- v1.8  
       lbs.location,   
       lbs.part_no    
     FROM lot_bin_stock lbs (NOLOCK)  
     INNER JOIN tdc_bin_master tbm (NOLOCK)    
     ON  lbs.bin_no = tbm.bin_no   
     AND  tbm.location = lbs.location   
     WHERE tbm.usage_type_code = 'QUARANTINE'  
     GROUP BY lbs.location,  -- v1.8  
        lbs.part_no) t2 -- v1.8  
 ON   l.part_no = t2.part_no    
 AND   l.location = t2.location  
 -- START v2.9  

 -- END v2.9  
 WHERE  l.status IN ('M', 'P')  
 AND   l.location LIKE @location  
 AND   a.field_2 LIKE @stile  
 AND   (@GpoColor = '' or a.field_3 in (SELECT * FROM fs_cParsing(@GpoColor)))  
 AND   m.category = @group  
 AND   ISNULL(m.non_sellable_flag,'N') <> 'Y' -- v1.6  
 AND   (UPPER(m.type_code) = 'FRAME' or UPPER(m.type_code) = 'SUN')    -- Added 9/15/10 RL   
 AND   (@GpoSize = '' or a.field_17 in (SELECT * FROM fs_cParsing(@GpoSize)))    
 --AND   ISNULL(m.obsolete,0) = 0 -- v2.7   
  
 -- v2.0  
 DELETE a  
 FROM #temp a  
 JOIN inv_master_add b (NOLOCK)  
 ON  a.part_no = b.part_no  
 LEFT JOIN lot_bin_stock c (NOLOCK)  
 ON  a.part_no = c.part_no  
 WHERE b.datetime_2 <= GETDATE()  
 AND  c.part_no IS NULL  
  
 -- v2.5 Start  
 SELECT @config_str = ISNULL(value_str,'') FROM dbo.tdc_config (NOLOCK) WHERE [function] = 'INV_EXCLUDED_BINS'  
  
 INSERT #excluded_stock  
 SELECT a.location, a.part_no, SUM(b.qty)  
 FROM #temp a  
 JOIN dbo.lot_bin_stock b (NOLOCK)  
 ON  a.part_no = b.part_no  
 AND  a.location = b.location  
 WHERE b.bin_no IN (SELECT * FROM fs_cParsing(@config_str))  
 GROUP BY a.location, a.part_no  
  
 UPDATE a  
 SET  qty_availa = qty_availa - b.qty  
 FROM #temp a  
 JOIN #excluded_stock b  
 ON  a.location = b.location  
 AND  a.part_no = b.part_no  
  
 DROP TABLE #excluded_stock  
 -- v2.5 End  
  
 SELECT @date_52_weeks = dateadd(week, -52, getdate())    
    
 SELECT @timefence = CAST( value_str AS INT) FROM CONFIG WHERE flag = 'TIMEFENCE'    
  
 -- Getting the MinWeeks  
 SELECT @MinWeeks = CAST( value_str AS INT) FROM CONFIG WHERE flag = 'MinWeeks'  
    
       
 SELECT @id = MIN(id) FROM #temp    
     
 WHILE @id IS NOT NULL    
 BEGIN    
  SELECT @part_no = part_no,   
    @loc = location    
  FROM #temp    
  WHERE id = @id    
    
  -- Get the quantity available  
  EXEC @qty_available = CVO_CheckAvailabilityInStock_sp  @part_no, @loc    
  
  -- Get the quantity on sales orders  
  SET @qty_on_order = 0  
  
  if @timefence <> 0  
  BEGIN  
   SELECT @qty_on_order = ISNULL(SUM(quantity - received),0.0)  
   FROM dbo.releases (NOLOCK)  
   WHERE location = @loc  
   AND  part_no = @part_no  
   AND  status = 'O'  
   AND  due_date <= DATEADD(DAY, @timefence, GETDATE())    
  END  
  
  -- Get the quantity on backorder  
  SET @qty_on_backorder = 0  
  -- START v2.6  
  SELECT @qty_on_backorder = ISNULL(SUM(a.ordered - a.shipped),0.0)   
  FROM dbo.ord_list a (NOLOCK)   
  INNER JOIN dbo.cvo_orders_all b (NOLOCK)  
  ON a.order_no = b.order_no  
  AND a.order_ext = b.ext  
  WHERE a.status IN ('N','A','C')   
  AND a.location = @loc  -- v1.9  
  AND a.part_no = @part_no -- v1.9  
  AND NOT (b.allocation_date > GETDATE() OR b.allocation_date IS NULL)  
  
  /*  
  SELECT @qty_on_backorder = ISNULL(SUM(ordered - shipped),0.0)   
  FROM dbo.ord_list (NOLOCK)   
  WHERE status IN ('N','A','C')   
  --AND  order_ext > 0  
  AND location = @loc  -- v1.9  
  AND  part_no = @part_no -- v1.9  
  */  
  -- END v2.6  
  
  SELECT @qty_alloc = ISNULL(SUM(qty),0.0)  
  FROM dbo.tdc_soft_alloc_tbl (NOLOCK)  
  WHERE location = @loc  
  AND  part_no = @part_no  
  AND  order_type = 'S'  
  AND  order_no <> 0  
   
  IF @qty_alloc IS NULL  
   SET @qty_alloc = 0  
  
  SET @qty_on_backorder = @qty_on_backorder - @qty_alloc  
  
  -- Get the quantity sold  
  -- v2.2 Start  
  SET @oldest_shipment_date = NULL  
  
  -- v2.4  
--  SELECT @oldest_shipment_date = MIN(a.date_shipped)  
--  FROM cvo_orders_all_hist a (NOLOCK)     
--  JOIN cvo_ord_list_hist b (NOLOCK)  
--  ON  a.order_no = b.order_no  
--  AND  a.ext = b.order_ext -- v2.3  
--  WHERE b.part_no = @part_no   
--  AND  b.location = @loc    
--  AND  b.shipped > 0  
  
  -- v2.4  
  SELECT @oldest_shipment_date = date_shipped  
  FROM CVO_order_shipped_hist_summary (NOLOCK)     
  WHERE part_no = @part_no   
  AND  location = @loc    
  
  IF @oldest_shipment_date IS NULL  
  BEGIN  
   SELECT @oldest_shipment_date = MIN(date_shipped)  
   FROM shippers     
   WHERE part_no = @part_no   
   AND  location = @loc    
   AND  shipped > 0  
  END   
  
  IF @oldest_shipment_date IS NULL  
   SET @oldest_shipment_date = @date_52_weeks  
  
  IF @oldest_shipment_date < @date_52_weeks  
   SET @oldest_shipment_date = @date_52_weeks  
  
  SET @oldest_shipment_date = DATEADD(WEEK, ISNULL(@MinWeeks,0), @oldest_shipment_date)  
  
  SET @qty_sold = 0  
  
  -- v2.4  
--  SELECT @qty_sold = ISNULL(SUM(b.shipped),0.0)  
--  FROM cvo_orders_all_hist a (NOLOCK)  
--  JOIN cvo_ord_list_hist b (NOLOCK)  
--  ON  a.order_no = b.order_no  
--  AND  a.ext = b.order_ext  
--  WHERE b.shipped > 0  
--  AND  a.date_shipped >= @oldest_shipment_date  
--  AND  b.location = @loc  
--  AND  b.part_no = @part_no  
  
  -- v2.4  
  SELECT @qty_sold = ISNULL(SUM(shipped),0.0)  
  FROM CVO_order_qty_hist_summary (NOLOCK)  
  WHERE date_shipped >= @oldest_shipment_date  
  AND  location = @loc  
  AND  part_no = @part_no  
   
  SELECT @qty_sold = ISNULL(@qty_sold,0.00) + ISNULL(SUM(shipped),0.0)  
  FROM dbo.shippers (NOLOCK)  
  WHERE shipped > 0  
  AND  date_shipped >= @oldest_shipment_date  
  AND  location = @loc  
  AND  part_no = @part_no  
   
  -- v2.2 End  
  
  IF @qty_sold < 1  
   SET @qty_sold = 1  
  
  SELECT @sold_weeks = DATEDIFF(week, @oldest_shipment_date, getdate())   
  IF @sold_weeks < 1  
   SET @sold_weeks = 1  
  
  -- Calculate the weeks  
  SET @weeks_supply = ((@qty_available + @qty_on_order - @qty_on_backorder) / (@qty_sold / @sold_weeks))   
  
--  if @part_no = 'CVCLIGUN5418'  
--  begin  
--  select @qty_available  
--  select @qty_on_order  
--  select @qty_on_backorder  
--  select @qty_sold  
--  select @sold_weeks  
--  end  
  
  UPDATE #temp  
  SET  qty_availa = @qty_available,  
    qty_on_sales = @qty_on_order,  
    backorder = @qty_on_backorder,  
    qty_total = @qty_sold,  
    weeks = CASE WHEN @weeks_supply < -99 THEN -99   
          WHEN @weeks_supply > 99 THEN 99  
        ELSE @weeks_supply END   
  WHERE id = @id  
    
  SELECT @id = MIN(id)     
  FROM #temp    
  WHERE id > @id    
 END    
  
 -- v2.8 Remove any obsolete items that do not have available stock  
 DELETE #temp  
 WHERE qty_availa <= 0  
 AND  obsolete = 1  
  
 -- v1.4 New Matrix Calculation  
 IF @UseVirtualStock = 2 -- Balanced  
 BEGIN  
  
  CREATE TABLE #sizes (colour varchar(255)) -- v1.7  
  
  INSERT #sizes   
  SELECT color   
  FROM #temp   
  GROUP BY color   
  HAVING COUNT(DISTINCT eye_size) = 1  
  
  UPDATE a  
  SET  priority = 5  
  FROM #temp a  
  JOIN #sizes b   
  ON  a.color = b.colour  
  
  DROP TABLE #sizes  
  
  CREATE TABLE #colours (size int)  
    
  INSERT #colours   
  SELECT eye_size   
  FROM #temp   
  GROUP BY eye_size   
  HAVING COUNT(DISTINCT color) = 1  
  
  UPDATE a  
  SET  priority = 5  
  FROM #temp a  
  JOIN #colours b   
  ON  a.eye_size = b.size  
  
  DROP TABLE #colours  
  
  SELECT @eye_count = COUNT(DISTINCT eye_size) FROM #temp  
  SELECT  @colour_count = COUNT(DISTINCT color) FROM #temp  
  
  IF @colour_count >= @eye_count  
  BEGIN  
  
   UPDATE a  
   SET  priority = 4  
   FROM #temp a  
   JOIN (SELECT color, COUNT(DISTINCT eye_size) num FROM #temp WHERE priority = 0 GROUP BY color) b  
   ON  a.color = b.color  
   WHERE b.num <> @eye_count  
   AND  a.priority = 0  
  
  
   UPDATE a  
   SET  priority = 3  
   FROM #temp a  
   JOIN (SELECT eye_size, MAX(weeks) num FROM #temp WHERE priority = 0 GROUP BY eye_size) b  
   ON  a.eye_size = b.eye_size  
   AND  a.weeks = b.num  
   AND  a.quantity = 0  
   AND  b.num <= 0  
   AND  a.priority = 0  
  
  END  
  ELSE  
  BEGIN  
  
   UPDATE a  
   SET  priority = 4  
   FROM #temp a  
   JOIN (SELECT eye_size, COUNT(DISTINCT color) num FROM #temp WHERE priority = 0 GROUP BY eye_size) b  
   ON  a.eye_size = b.eye_size  
   WHERE b.num <> @colour_count  
   AND  a.priority = 0  
  
  
   UPDATE a  
   SET  priority = 3  
   FROM #temp a  
   JOIN (SELECT color, MAX(weeks) num FROM #temp WHERE priority = 0 GROUP BY color) b  
   ON  a.color = b.color  
   AND  a.weeks = b.num  
   AND  a.quantity = 0  
   AND  b.num <= 0  
   AND  a.priority = 0  
  
  END  
  
  DELETE #eye_size  
  DELETE #colour  
  
  INSERT #colour  
  SELECT color, 0   
  FROM #temp   
  WHERE quantity = 1  
  
  INSERT #eye_size  
  SELECT eye_size, 0   
  FROM #temp   
  WHERE quantity = 1  
  
  IF @colour_count >= @eye_count  
  BEGIN  
   SELECT @loop_count = @colour_count - (SELECT COUNT(DISTINCT colours) FROM #colour)  
  
   UPDATE a   
   SET  average = b.average   
   FROM #temp a   
   JOIN (SELECT color, SUM(CAST (weeks AS FLOAT)) average FROM #temp GROUP BY color) b   
   ON  a.color = b.color    
  
  END  
  ELSE  
  BEGIN  
   SELECT @loop_count = @eye_count - (SELECT COUNT(DISTINCT size) FROM #eye_size)  
    
   UPDATE a   
   SET  average = b.average   
   FROM #temp a   
   JOIN (SELECT eye_size, SUM(CAST (weeks AS FLOAT)) average FROM #temp GROUP BY eye_size) b   
   ON  a.eye_size = b.eye_size   
  END  
  
  INSERT #temp2 (part_no)  
  SELECT part_no   
  FROM #temp   
  ORDER BY priority DESC, weeks DESC, average ASC  
  
  
  SET @id = 1  
  SET @last_id = 0  
  SET @temp_id = 0  
  SELECT @max_id = max(id) FROM #temp2  
  SET @temp_loop_count = @loop_count  
  
  WHILE @id <= @max_id  
  BEGIN  
  
   DELETE #eye_size  
   DELETE #colour  
  
   SET @last_id = @id - 1  
   SET @first = 1  
   SET @loop_count = @temp_loop_count  
  
   WHILE @loop_count > 0  
   BEGIN  
  
    SET @colour = null  
  
    SELECT TOP 1 @colour = a.color,   
      @eye_size = a.eye_size,   
      @weeks = a.weeks,  
      @part_no = a.part_no  
    FROM #temp a   
    LEFT JOIN #colour b   
    ON  a.color = b.colours  
    LEFT JOIN #eye_size c   
    ON  a.eye_size = c.size   
    JOIN #temp2 e   
    ON  a.part_no = e.part_no   
    WHERE a.quantity = 0  
    AND  b.colours IS NULL  
    AND  c.size IS NULL  
    AND  e.id > @last_id  
    ORDER BY priority DESC, weeks DESC, average ASC  
  
  
    IF @first = 1  
    BEGIN  
     SET @last_id = 0  
     SET @first = 0    
    END  
  
--    select '@colour',@colour  
--    select '@eye_size',@eye_size  
--    select '@weeks',@weeks  
--    select '@part_no',@part_no  
  
    UPDATE #temp  
    SET  quantity = 1  
    WHERE color = @colour  
    AND  eye_size = @eye_size  
    AND  weeks = @weeks  
    AND  part_no = @part_no  
  
    INSERT #colour   
    SELECT @colour,0  
     
    INSERT #eye_size   
    SELECT @eye_size,0  
  
    IF ((SELECT COUNT(DISTINCT size) FROM #eye_size) = @eye_count)  
    BEGIN  
     SET @last_eye = 0  
     SET @temp_loop = @eye_count  
     WHILE @temp_loop > 0  
     BEGIN   
      SET @temp_size = null  
      SELECT TOP 1 @temp_size = size   
      FROM #eye_size   
      WHERE size > @last_eye   
      ORDER BY size ASC  
       
      SET ROWCOUNT 1  
      DELETE #eye_size WHERE size = @temp_size  
      SET ROWCOUNT 0  
       
      SET @last_eye = @temp_size  
      SET @temp_loop = @temp_loop - 1  
     END  
    END  
  
    IF (SELECT COUNT(DISTINCT colours) FROM #colour) = @colour_count  
    BEGIN   
     SET @last_colour = ''  
     SET @temp_loop = @colour_count  
     WHILE @temp_loop > 0  
     BEGIN   
      SET @temp_colour = null  
      SELECT TOP 1 @temp_colour = colours   
      FROM #colour   
      WHERE colours > @last_colour   
      ORDER BY colours ASC  
    
      SET ROWCOUNT 1  
      DELETE #colour WHERE colours = @temp_colour  
      SET ROWCOUNT 0  
       
      SET @last_colour = @temp_colour  
      SET @temp_loop = @temp_loop - 1  
     END  
    END  
  
    SET @loop_count = @loop_count -1  
  
   END  
    
   SELECT @temp = COUNT(quantity)   
   FROM #temp   
   WHERE quantity = 1  
  
   IF @temp = @temp_loop_count  
   BEGIN   
    INSERT #results   
    select @id,   
      SUM(weeks),   
      STDEV(weeks), 0   
    FROM #temp   
    WHERE quantity = 1  
     
    SELECT @minus_sum = SUM(weeks)   
    FROM #temp   
    WHERE quantity = 1   
    AND  weeks > 0  
     
    UPDATE #results   
    SET  min_val = @minus_sum   
    WHERE id = @id  
     
   END  
    
   UPDATE #temp   
   set  quantity = 0   
    
   SET @id = @id + 1  
  END  
  
  IF NOT EXISTS (select 1 from #results)  
  BEGIN  
   UPDATE #temp set quantity = 1 WHERE priority = 5  
  END  
  
  SELECT TOP 1 @best_id = id   
  FROM #results   
  ORDER BY min_val DESC, score DESC, dev ASC  
  
  SET @best_id = @best_id - 1   
  SET @loop_count = @temp_loop_count  
  SET @first = 1  
  
  DELETE #eye_size  
  DELETE #colour  
  
  WHILE @loop_count > 0  
  BEGIN   
  
   SET @colour = null  
  
   SELECT TOP 1 @colour = a.color,   
     @eye_size = a.eye_size,   
     @weeks = a.weeks,  
     @part_no = a.part_no  
   FROM #temp a   
   LEFT JOIN #colour b   
   ON  a.color = b.colours  
   LEFT JOIN #eye_size c   
   ON  a.eye_size = c.size   
   JOIN #temp2 e   
   ON  a.part_no = e.part_no   
   WHERE a.quantity = 0  
   AND  b.colours IS NULL  
   AND  c.size IS NULL  
   AND  e.id > @best_id  
   ORDER BY priority DESC, weeks DESC, average ASC  
  
   IF @first = 1  
   BEGIN  
    SET @best_id = 0  
    SET @first = 0    
   END  
    
   UPDATE #temp  
   SET  quantity = 1  
   WHERE color = @colour  
   AND  eye_size = @eye_size  
   AND  weeks = @weeks  
   AND  part_no = @part_no  
  
   INSERT #colour SELECT @colour,0  
   INSERT #eye_size SELECT @eye_size,0  
  
   IF ((SELECT COUNT(DISTINCT size) FROM #eye_size) = @eye_count)  
   BEGIN  
    SET @last_eye = 0  
    SET @temp_loop = @eye_count  
    WHILE @temp_loop > 0  
    BEGIN   
     SET @temp_size = null  
     SELECT TOP 1 @temp_size = size   
     FROM #eye_size   
     WHERE size > @last_eye   
     ORDER BY size ASC  
      
     SET ROWCOUNT 1  
     DELETE #eye_size WHERE size = @temp_size  
     SET ROWCOUNT 0  
    
     SET @last_eye = @temp_size  
     SET @temp_loop = @temp_loop - 1  
    END   
   END  
  
  
   IF (SELECT COUNT(DISTINCT colours) FROM #colour) = @colour_count  
   BEGIN   
    SET @last_colour = ''  
    SET @temp_loop = @colour_count  
    WHILE @temp_loop > 0  
    BEGIN  
     SET @temp_colour = null  
     SELECT TOP 1 @temp_colour = colours   
     FROM #colour   
     WHERE colours > @last_colour   
     ORDER BY colours ASC  
      
     SET ROWCOUNT 1  
     DELETE #colour WHERE colours = @temp_colour  
     SET ROWCOUNT 0  
  
     SET @last_colour = @temp_colour  
     SET @temp_loop = @temp_loop - 1  
    END  
   END  
  
   SET @loop_count = @loop_count -1  
  END  
  
 END  
  
 IF @UseVirtualStock = 1  
 BEGIN  
  UPDATE #temp  
  set  quantity = 1  
 END  
  
 -- START v1.5  
 /*  
 SELECT part_no,   
   location,   
   color,   
   eye_size,   
   qty_availa,   
   weeks qty_on_sales,   
   quantity qty_sugest,   
   style,   
   uom,   
   price,   
   status,   
   [description],   
   part_type,   
   qty_qc    
 FROM #temp   
 */  
 --select * from #temp  
  
 EXEC dbo.CVO_Transform_Matrix_sp  
 -- END v1.5  
    
 DROP TABLE #temp    
 DROP TABLE #temp2  
 DROP TABLE #eye_size   
 DROP TABLE #colour  
 DROP TABLE #results   
  
RETURN  
  
END  
GO
