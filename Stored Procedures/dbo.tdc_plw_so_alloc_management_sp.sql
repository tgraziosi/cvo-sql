SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Stored Procedure      
-- v1.0 CB Always Evaluate and show either consolidated shipments or not depending on the checkbox.    
-- v1.1 CB 29/03/2011 - 18.RDOCK Inventory - Excluded specified bins    
-- v1.2 CB 22/03/2011 19.Rel Date - Routine to determine if any stock is prior to its release date    
-- v1.3 CB 23/03/2011 13.Ship Complete - Routine to determine if items will go on back order for an order set as ship complete    
-- v1.4 CB 13/04/2011 Future Allocations and Promo ID    
-- v1.5 CB 10/08/2011 - Case Part - Consolidation    
-- v1.6 CB 21/09/2011 Optimise    
-- v1.7 CB 26/01/2012 Clear up hold_reasons when allocating    
-- v1.8 CB 28/02/2012 Performance updates    
-- v10.1 CB 11/07/2012 CVO-CF-1 - Custom Frame Processing - Reduce the 5 available when custom frame parts not available    
-- v10.2 CB 24/07/2012 implement non allocatable bins    
-- v10.3 CB 04/09/2012 Remove case consolidation as this is now done at order entry    
-- v10.4 CB 14/09/2012 Force frame and suns to allocated first to fix issue with case balancing    
-- v10.5 CB 04/10/2012 - Remove any reference to tdc_soft_alloc_tbl. Only need qty from cvo_soft_alloc_det.    
-- v10.6 CB 10/10/2012 - Due to changes in the bin return function     
-- v10.7 CB 25/10/2012 - Fix issue with custom frames not reporting the correct % allocated    
-- v10.8 CB 13/12/2012 - Issue #1023 - If order pre-soft alloc then call case consolidation    
-- v10.9 CB 16/04/2013 - Issue #1204 - The quantity available needs to exclude soft alloc qty    
-- v11.0 CB 18/04/2013 - Issue #1225 - Custom Frames - if avail qty < 0 then make 0    
-- v11.1 CB 19/04/2013 - Fix to v10.9 - so not include -3    
-- v11.2 CB 08/05/2013 - Performance    
-- v11.3 CB 10/05/2013 - When checking soft alloc use soft alloc no    
-- v11.4 CB 13/05/2013 - Issue #1265 - Fix to available figure   
-- v11.5 CB 17/05/2103 - Issue #1265 - When allocating a range of orders go through them in soft alloc number order
-- v11.6 CB 20/05/2013 - Issue #1265 - Fix for when no soft alloc hdr exists
-- v11.7 CB 18/06/2013 - Issue #1265 - Additional fix for in stock figure
-- v11.8 CB 18/06/2013 - Issue #1346 - Additional fix for in stock figure
-- v11.9 CB 20/11/2013 - Issye #1422 - Issue with available stock for custom frames
-- v12.0 CB 20/05/2014 - Issue #1481 - Include -3 status on soft alloc
    
 CREATE PROCEDURE [dbo].[tdc_plw_so_alloc_management_sp]      
 @criteria_template varchar(50),      
 @method   varchar(20),      
 @where_clause1   varchar(255),       
 @where_clause2   varchar(255),       
 @where_clause3   varchar(255),       
 @where_clause4   varchar(255),       
 @order_by_clause varchar(255),      
 @pct_filter   decimal(20,2),      
 @con_no   int,      
 @show_only_set  int,      
 @con_type  varchar(255),      
 @user_id  varchar(50)      
--BEGIN SED009 -- Pick Ticket Printing     
--JVM 08/23/2010     
 ,@consolidate_shipment_check INT = 0    
--END   SED009 -- Pick Ticket Printing      
WITH RECOMPILE    
AS      
      
SET NOCOUNT ON    
--SCR#051203  Call 3824202MPS  02/20/09      
      
DECLARE @insert_clause  varchar (2000),      
 @select_clause   varchar (2000),      
 @from_clause   varchar (1000),      
 @where_clause   varchar (1000),      
 @declare_clause  varchar (1000)      
      
DECLARE @order_no   int,      
 @order_ext   int,      
 @location   varchar(10),      
 @part_no  varchar(30),      
 @line_no      int,      
 @lb_tracking  char(1),      
 @part_type  char(1)      
      
DECLARE @part_filter_clause varchar(2000),      
 @part_filter_parts varchar(500),      
 @part_filter_kits varchar(2000)      
      
DECLARE @qty_in_stock   decimal(20,8),      
 @qty_ordered_for_part_line_no decimal(24,8),      
 @qty_alloc_for_part_total decimal(20,8),       
 @qty_alloc_for_part_line_no decimal(20,8),      
 @qty_avail_for_part_total decimal(20,8),      
 @qty_avail_for_part_line_no decimal(24,8),      
 @qty_pre_allocated_total   decimal(20,8),      
 @qty_pre_alloc_for_part_on_order decimal(20,8),      
 @qty_picked_for_part_line_no decimal(24,8),      
 @qty_needed_for_part_line_no  decimal(24,8),      
 @qty_to_alloc    int,      
 @ret    int ,    
 @qty_alloc_sa decimal(20,8)     
      
DECLARE @alloc_pct_for_order  decimal(20,2),      
 @alloc_pct_for_part_line_no decimal(20,2),      
 @cur_fill_pct_for_order  decimal(20,2),      
 @avail_pct_for_part_line_no  decimal(20,2)      
      
DECLARE @calc_ordered_dollars  decimal(20,8),      
 @cal_ordered_dollars_flg int,      
 @shippable_margin_dollars decimal(20,8),      
 @calc_shippable_dollars_flg int,      
 @calc_shippable_dollars  decimal(20,8),      
 @calc_margin_pct  decimal(20,8),      
 @calc_margin_flg  int,       
 @total_avail   decimal(20,8),      
 @total_price   decimal(20,8),      
 @total_cost   decimal(20,8),      
 @currency   varchar(20),      
 @alloc_type   varchar(20)      
      
DECLARE @temp_fill_pct           decimal(20, 8),      
 @temp_alloc_pct          decimal(20, 8),      
 @temp_aval_pct   decimal(20, 8),      
 @temp    varchar(20),      
 @filter_postal_code_str  varchar(200),      
 @filter_carrier_code_str varchar(200)      
     
-- v10.1 Start    
DECLARE @id   int,    
  @last_id int,    
  @alloc_qty decimal(20,8),    
  @quar_qty decimal(20,8),    
  @sa_qty  decimal(20,8),    
  @av_qty  decimal(20,8),    
  @in_stock decimal(20,8),    
  @avg_avail  decimal(20,8),    
  @avg_order decimal(20,8),    
  @act_alloc decimal(20,8) -- v10.7    
-- v10.1 End    
    
-- v11.2 Start    
DECLARE @row_id    int,    
  @last_row_id  int,    
  @line_row_id  int,    
  @last_line_row_id int    
-- v11.2 End    
    
DECLARE @max_soft_alloc int -- v11.3    
    
TRUNCATE TABLE #so_allocation_detail_view      
TRUNCATE TABLE #so_alloc_management      
TRUNCATE TABLE #so_pre_allocation_table      
TRUNCATE TABLE #temp_sia_working_tbl      
      
-- v11.2 Move to further down and ref temp table    
-- v1.7 Clean up hold_reason    
--UPDATE orders_all    
--SET  hold_reason = ''    
--WHERE status in ('N','P','Q')    
--AND  hold_reason <> ''    
      
------------------------------------------------------------------------------------------------------------------      
--  Get flags for additional calculations        --      
------------------------------------------------------------------------------------------------------------------      
IF EXISTS (SELECT * FROM tdc_config (NOLOCK)       
     WHERE [function] = 'calc_ordered_dollars'       
       AND active = 'Y')      
 SELECT @cal_ordered_dollars_flg = 1      
ELSE      
 SELECT @cal_ordered_dollars_flg = 0      
      
IF EXISTS (SELECT * FROM tdc_config (NOLOCK)       
     WHERE [function] = 'calc_shippable_dollars'       
       AND active = 'Y')      
 SELECT @calc_shippable_dollars_flg = 1      
ELSE      
 SELECT @calc_shippable_dollars_flg = 0      
      
IF EXISTS (SELECT * FROM tdc_config (NOLOCK)       
     WHERE [function] = 'calc_margin_pct'       
       AND active = 'Y')      
 SELECT @calc_margin_flg = 1      
ELSE      
 SELECT @calc_margin_flg = 0      
      
      
------------------------------------------------------------------------------------------------------------------------------------      
-- Add the postal code and carrier code filters if they are setup.      
------------------------------------------------------------------------------------------------------------------------------------      
SELECT @filter_postal_code_str = '', @filter_carrier_code_str = ''      
IF ISNULL(@criteria_template, '') = ''      
BEGIN      
 IF EXISTS(SELECT * FROM tdc_postal_code_filter_tbl (NOLOCK) WHERE userid = @user_id)      
 BEGIN      
  SELECT @filter_postal_code_str = ' AND orders.ship_to_zip IN (SELECT postal_code FROM tdc_postal_code_filter_tbl (NOLOCK) WHERE userid = ''' + @user_id + ''') '      
 END      
      
       
 IF EXISTS(SELECT * FROM tdc_carrier_code_filter_tbl (NOLOCK) WHERE userid = @user_id)      
 BEGIN      
  SELECT @filter_carrier_code_str = ' AND orders.routing IN (SELECT carrier_code FROM tdc_carrier_code_filter_tbl (NOLOCK) WHERE userid = ''' + @user_id + ''') '      
 END      
END      
ELSE      
BEGIN      
 IF EXISTS(SELECT * FROM tdc_sia_postal_code_filter_tbl (NOLOCK) WHERE userid = @user_id AND template_code = @criteria_template)      
 BEGIN      
  SELECT @filter_postal_code_str = ' AND orders.ship_to_zip IN (SELECT postal_code FROM tdc_sia_postal_code_filter_tbl (NOLOCK) WHERE userid = ''' + @user_id + ''' AND template_code = ''' + @criteria_template + ''') '      
 END      
       
 IF EXISTS(SELECT * FROM tdc_sia_carrier_code_filter_tbl (NOLOCK) WHERE userid = @user_id AND template_code = @criteria_template)      
 BEGIN      
  SELECT @filter_carrier_code_str = ' AND orders.routing IN (SELECT carrier_code FROM tdc_sia_carrier_code_filter_tbl (NOLOCK) WHERE userid = ''' + @user_id + ''' AND template_code = ''' + @criteria_template + ''') '      
 END      
      
END      
------------------------------------------------------------------------------------------------------------------------------------      
      
-- First we get all the data we can get for the #so_alloc_management table.      
-- Later we'll update the the feilds that have to be calculated      
-- v1.4 Add new columns    
SELECT @insert_clause = ' INSERT INTO #so_alloc_management      
    (sel_flg, sel_flg2, prev_alloc_pct, curr_alloc_pct,      
    curr_fill_pct, order_no, order_ext, location,      
    order_status, sch_ship_date, consolidation_no,      
    cust_type, cust_type2, cust_type3, cust_name,      
    cust_flg, cust_code, territory_code, carrier_code,      
    dest_zone_code, ship_to, so_priority_code,      
    ordered_dollars, shippable_dollars,shippable_margin_dollars,       
    alloc_type, user_code, user_category, load_no, cust_po, postal_code, allocation_date, promo_id, consolidate_shipment, cf) '  -- v10.1    
      
-- v1.4 Add new columns    
SELECT @select_clause = ' SELECT DISTINCT 0 AS sel_flg, 0 AS sel_flg2,       
            prev_alloc_pct = ISNULL((SELECT MAX(fill_pct)      
          FROM tdc_alloc_history_tbl  (NOLOCK)       
             WHERE order_no = ord_list.order_no      
              AND order_ext = ord_list.order_ext      
              AND location = ord_list.location       
              AND order_type = ''S''), 0),      
     0 AS curr_alloc_pct, 0 AS curr_fill_pct, ord_list.order_no,       
            ord_list.order_ext, ord_list.location, orders.status, orders.sch_ship_date,       
            consolidation_no = ISNULL((SELECT consolidation_no      
                           FROM tdc_cons_ords (NOLOCK)      
                         WHERE tdc_cons_ords.order_no = ord_list.order_no        
                     AND tdc_cons_ords.order_ext = ord_list.order_ext      
                     AND tdc_cons_ords.location = ord_list.location      
              AND tdc_cons_ords.order_type = ''S''), 0),      
            armaster.addr_sort1, armaster.addr_sort2, armaster.addr_sort3,      
            armaster.address_name, orders.back_ord_flag, orders.cust_code,      
            orders.ship_to_region, orders.routing, orders.dest_zone_code,      
            orders.ship_to_name, orders.so_priority_code, NULL, NULL, NULL, NULL, orders.user_code, orders.user_category,      
     load_no = (SELECT DISTINCT load_no FROM load_list(NOLOCK) WHERE order_no = orders.order_no AND order_ext = orders.ext),      
     orders.cust_po, LEFT(orders.ship_to_zip,10), ISNULL(cvo.allocation_date,GETDATE()-1), cvo.promo_id ' -- v10.1    
    
-- v1.4 Add new columns    
SELECT @from_clause   = '   FROM orders_all orders (NOLOCK),       
            ord_list(NOLOCK),       
            armaster(NOLOCK),      
     tdc_order(NOLOCK), cvo_orders_all cvo (NOLOCK) '     
      
--BEGIN SED009 -- Pick Ticket Printing     
--JVM 08/23/2010     
-- v1.0 CB Always Evaluate    
--IF @consolidate_shipment_check  = 1     
-- BEGIN    
    SET @select_clause = @select_clause  + ' , CVO_armaster_all.consol_ship_flag '      
    SET @from_clause   = @from_clause    + ' , CVO_armaster_all (NOLOCK) '      
-- END       
--ELSE    
-- BEGIN    
--    SET @select_clause = @select_clause  + ', 0 AS consol_ship_flag '            
-- END         
--END  SED009 -- Pick Ticket Printing      
    
-- v10.1    
   SET @select_clause = @select_clause  + ' , ''N'' '      
    
-- v1.4 Add new columns     
SELECT @where_clause  = '  WHERE orders.order_no     = ord_list.order_no       
        AND orders.ext          = ord_list.order_ext       
        AND orders.cust_code    = armaster.customer_code      
        AND orders.cust_code    = armaster.customer_code      
        AND orders.ship_to      = armaster.ship_to_code      
        AND orders.type         = ''I''      
        AND (ord_list.create_po_flag <> 1 OR ord_list.create_po_flag IS NULL)      
        AND tdc_order.order_no  = orders.order_no      
        AND tdc_order.order_ext = orders.ext     
  AND orders.order_no = cvo.order_no    
  AND orders.ext = cvo.ext     
        AND armaster.address_type = (SELECT MAX(address_type)       
                  FROM armaster (NOLOCK)       
              WHERE customer_code = orders.cust_code       
    AND ship_to_code  = orders.ship_to) ' + @filter_postal_code_str + @filter_carrier_code_str      
      
      
      
--  INSERT INTO #so_alloc_management      
EXEC (@insert_clause + ' ' +      
      @select_clause + ' ' +      
      @from_clause   + ' ' +      
      @where_clause  + ' ' +       
      @where_clause1 +        
      @where_clause2 +        
      @where_clause3 +        
      @where_clause4 )      
      
    
-- v11.2 Start    
UPDATE a    
SET  hold_reason = ''    
FROM orders_all a    
JOIN #so_alloc_management b    
ON  a.order_no = b.order_no    
AND  a.ext = b.order_ext    
WHERE a.status in ('N','P','Q')    
AND  a.hold_reason <> ''    
-- v11.2 End    
    
--If ONE_FOR_ONE, remove all orders that are bound to consolidation numbers      
IF @con_no = 0 --ONE_FOR_ONES      
BEGIN      
 DELETE FROM #so_alloc_management       
        FROM tdc_cons_ords (NOLOCK)      
  WHERE #so_alloc_management.order_no = tdc_cons_ords.order_no      
    AND #so_alloc_management.order_ext = tdc_cons_ords.order_ext       
    AND #so_alloc_management.location = tdc_cons_ords.location       
    AND #so_alloc_management.consolidation_no IN (SELECT consolidation_no       
                 FROM tdc_cons_ords (NOLOCK)      
                GROUP BY consolidation_no HAVING count(*) > 1 )       
        
END      
ELSE --Consolidation Sets      
BEGIN      
 IF @show_only_set = 1 --The user wants to see only orders in the consolidation set that were assigned      
 BEGIN        
  DELETE FROM #so_alloc_management       
  WHERE NOT EXISTS (SELECT * FROM tdc_cons_ords (NOLOCK)      
       WHERE #so_alloc_management.order_no         = tdc_cons_ords.order_no      
         AND #so_alloc_management.order_ext        = tdc_cons_ords.order_ext      
         AND #so_alloc_management.location         = tdc_cons_ords.location       
         AND #so_alloc_management.consolidation_no = @con_no)      
          
       
 END       
 ELSE      
 BEGIN --Remove all other sets that have been assigned.      
  DELETE FROM #so_alloc_management       
  WHERE consolidation_no NOT IN (0, @con_no)      
 END      
END      
      
--Filter out what the user wants to see      
--PrePack orders only or Non-Prepack orders or All      
IF @con_type = 'PRE-PACKED'      
BEGIN      
 DELETE FROM  #so_alloc_management      
        FROM tdc_cons_ords (NOLOCK)      
  WHERE #so_alloc_management.order_no =  tdc_cons_ords.order_no      
    AND #so_alloc_management.order_ext = tdc_cons_ords.order_ext       
    AND #so_alloc_management.location =  tdc_cons_ords.location       
    AND tdc_cons_ords.alloc_type <> 'PR'      
      
       
END      
ELSE IF @con_type = 'NON PRE-PACKED'      
BEGIN      
      
 DELETE FROM  #so_alloc_management      
        FROM tdc_cons_ords (NOLOCK)      
  WHERE #so_alloc_management.order_no =  tdc_cons_ords.order_no      
    AND #so_alloc_management.order_ext = tdc_cons_ords.order_ext       
    AND #so_alloc_management.location =  tdc_cons_ords.location       
    AND tdc_cons_ords.alloc_type NOT IN ('PT' , 'HO' )      
END      
      
IF ISNULL(@criteria_template, '') = ''      
BEGIN      
 --Remove unwanted parts      
 IF EXISTS (SELECT * FROM tdc_part_filter_tbl(NOLOCK)       
      WHERE alloc_filter = 'N'      
        AND userid = @user_id       
        AND order_type = 'S')        
 BEGIN      
       
  DELETE FROM #so_alloc_management      
   WHERE CAST(order_no AS VARCHAR(20)) + '-' + CAST(order_ext AS VARCHAR(10)) + '-' + location        
     NOT IN (      
    SELECT CAST(order_no AS VARCHAR(20)) + '-' + CAST(order_ext AS VARCHAR(10)) + '-' + location        
      FROM ord_list ol(NOLOCK)      
     WHERE part_no IN (SELECT part_no       
          FROM tdc_part_filter_tbl (NOLOCK)       
         WHERE alloc_filter = 'N'      
           AND userid = @user_id      
           AND order_type = 'S'      
           AND location = ol.location)      
    UNION       
    SELECT CAST(order_no AS VARCHAR(20)) + '-' + CAST(order_ext AS VARCHAR(10)) + '-' + location       
      FROM ord_list_kit olk(NOLOCK)      
     WHERE part_no IN (SELECT part_no       
           FROM tdc_part_filter_tbl (NOLOCK)       
          WHERE alloc_filter = 'N'      
            AND userid = @user_id      
            AND order_type = 'S'      
            AND location = olk.location)      
   )      
         
 END      
END      
ELSE      
BEGIN      
  IF EXISTS(SELECT * FROM tdc_sia_part_filter_tbl (NOLOCK)       
      WHERE userid = @user_id      
        AND template_code = @criteria_template)      
  BEGIN      
   DELETE FROM #so_alloc_management      
    WHERE CAST(order_no AS VARCHAR(20)) + '-' + CAST(order_ext AS VARCHAR(10)) + '-' + location        
      NOT IN (      
     SELECT CAST(order_no AS VARCHAR(20)) + '-' + CAST(order_ext AS VARCHAR(10)) + '-' + location        
       FROM ord_list ol(NOLOCK)      
      WHERE part_no IN (SELECT part_no       
           FROM tdc_sia_part_filter_tbl (NOLOCK)       
          WHERE userid = @user_id      
             AND template_code = @criteria_template      
            AND location = ol.location)      
     UNION       
     SELECT CAST(order_no AS VARCHAR(20)) + '-' + CAST(order_ext AS VARCHAR(10)) + '-' + location       
       FROM ord_list_kit olk(NOLOCK)      
      WHERE part_no IN (SELECT part_no       
            FROM tdc_sia_part_filter_tbl (NOLOCK)       
           WHERE userid = @user_id      
             AND template_code = @criteria_template      
             AND location = olk.location)      
    )      
  END      
END      
      
-------------------------------------------------------------------------------------------------------------------------------------------------------      
-- Even and Weighted Allocation Method      
-------------------------------------------------------------------------------------------------------------------------------------------------------      
IF @method != 'Default'      
BEGIN      
      
 INSERT INTO #temp_sia_working_tbl(order_no, order_ext, location, part_no, lb_tracking, qty_ordered, qty_assigned, qty_needed, qty_to_alloc)      
 SELECT a.order_no, a.order_ext, a.location, b.part_no, b.lb_tracking, FLOOR(SUM(b.ordered)),       
  CEILING(SUM(b.shipped)) + ISNULL((SELECT CEILING(SUM(qty))      
     FROM tdc_soft_alloc_tbl(NOLOCK)      
     WHERE order_no = a.order_no      
       AND order_ext = a.order_ext      
       AND location = a.location      
       AND part_no = b.part_no), 0),      
  FLOOR(SUM(b.ordered)) - CEILING(sum(b.shipped)) - ISNULL((SELECT CEILING(SUM(qty))      
     FROM tdc_soft_alloc_tbl(NOLOCK)      
     WHERE order_no = a.order_no      
       AND order_ext = a.order_ext      
       AND location = a.location      
       AND part_no = b.part_no), 0),      
  0      
      
   FROM #so_alloc_management a,      
  ord_list b(NOLOCK)      
  WHERE a.order_no = b.order_no      
    AND a.order_ext = b.order_ext      
    AND a.location = b.location      
    AND b.part_type = 'P'      
  GROUP BY a.order_no, a.order_ext, a.location, b.part_no, b.lb_tracking       
      
 INSERT INTO #temp_sia_working_tbl(order_no, order_ext, location, part_no, lb_tracking, qty_ordered, qty_assigned, qty_needed, qty_to_alloc)      
 SELECT a.order_no, a.order_ext, a.location, b.kit_part_no, c.lb_tracking, FLOOR(SUM(b.ordered * b.qty_per_kit)),       
  CEILING(SUM(b.kit_picked)) + ISNULL((SELECT CEILING(SUM(qty))      
     FROM tdc_soft_alloc_tbl(NOLOCK)      
     WHERE order_no = a.order_no      
       AND order_ext = a.order_ext      
       AND location = a.location      
       AND part_no = b.kit_part_no), 0),      
  FLOOR(SUM(b.ordered * b.qty_per_kit)) - CEILING(sum(b.kit_picked)) - ISNULL((SELECT CEILING(SUM(qty))      
     FROM tdc_soft_alloc_tbl(NOLOCK)      
     WHERE order_no = a.order_no      
       AND order_ext = a.order_ext      
       AND location = a.location      
       AND part_no = b.part_no), 0),      
  0      
      
   FROM #so_alloc_management a,      
  tdc_ord_list_kit b(NOLOCK),      
  inv_master c (NOLOCK)      
  WHERE a.order_no = b.order_no      
    AND a.order_ext = b.order_ext      
    AND a.location = b.location      
    AND b.kit_part_no = c.part_no      
  GROUP BY a.order_no, a.order_ext, a.location, b.part_no, b.kit_part_no, c.lb_tracking       
       
      
 IF @method = 'Even'      
 BEGIN      
  EXEC tdc_plw_sia_even_sp      
 END      
 ELSE IF @method = 'Weighted'      
 BEGIN      
  SELECT @ret = 0      
  WHILE @ret = 0      
  BEGIN      
   EXEC @ret = tdc_plw_sia_weighted_sp      
  END      
 END      
      
-- v11.2 Start    
CREATE TABLE #tdc_selected_detail_cursor_nodef(    
  row_id   int IDENTITY(1,1),    
  order_no  int,    
  order_ext  int,    
  location  varchar(10),    
  part_no   varchar(30),    
  qty_to_alloc decimal(20,8),    
  currency  varchar(20))    
    
CREATE TABLE #tdc_detail_cursor_nodef (    
  line_row_id  int IDENTITY(1,1),    
  line_no   int,     
  qty_ordered  decimal(20,8),     
  qty_picked  decimal(20,8),     
  lb_tracking  char(1))    
    
CREATE INDEX #tdc_detail_cursor_nodef_ind0 ON #tdc_detail_cursor_nodef(line_row_id)    
    
    
INSERT #tdc_selected_detail_cursor_nodef (order_no, order_ext, location, part_no, qty_to_alloc, currency)    
SELECT order_no, order_ext, location, part_no, qty_to_alloc,       
    (SELECT curr_key FROM orders a(nolock)         
      WHERE a.order_no = #temp_sia_working_tbl.order_no      
        AND a.ext = #temp_sia_working_tbl.order_ext)             
      FROM #temp_sia_working_tbl       
    
CREATE INDEX #tdc_selected_detail_cursor_nodef_ind0 ON #tdc_selected_detail_cursor_nodef(row_id)    
    
SET @last_row_id = 0    
    
SELECT TOP 1 @row_id = row_id,    
  @order_no = order_no,     
  @order_ext =order_ext,     
  @location = location,     
  @part_no = part_no,     
  @qty_to_alloc = qty_to_alloc,     
  @currency = currency    
FROM #tdc_selected_detail_cursor_nodef    
WHERE row_id > @last_row_id    
    
WHILE (@@ROWCOUNT <> 0)    
BEGIN    
      
-- DECLARE selected_detail_cursor CURSOR FOR       
--    SELECT order_no, order_ext, location, part_no, qty_to_alloc,       
--    (SELECT curr_key FROM orders a(nolock)         
--      WHERE a.order_no = #temp_sia_working_tbl.order_no      
--        AND a.ext = #temp_sia_working_tbl.order_ext)             
--      FROM #temp_sia_working_tbl       
       
-- OPEN selected_detail_cursor      
-- FETCH NEXT FROM selected_detail_cursor INTO @order_no, @order_ext, @location, @part_no, @qty_to_alloc, @currency      
       
-- WHILE (@@FETCH_STATUS = 0)      
-- BEGIN      
-- v11.2 End       
  ------------------------------------------------------------------------------------------------------------------------------------      
  -- Now we'll get all the data we can get for the #so_allocation_detail_view table.      
  -- Later we'll update the the feilds that have to be calculated.      
  INSERT INTO #so_allocation_detail_view (order_no, order_ext, location, line_no, part_no, part_desc, lb_tracking,       
       qty_ordered, qty_avail, qty_picked, qty_alloc, avail_pct, alloc_pct)      
  SELECT order_no, order_ext, location, line_no, part_no, [description], lb_tracking, ordered * conv_factor, 0, shipped * conv_factor, 0, 0, 0      
    FROM ord_list (NOLOCK)      
   WHERE order_no  = @order_no      
     AND order_ext = @order_ext      
     AND location  = @location      
     AND part_no   = @part_no      
     AND (create_po_flag <> 1 OR create_po_flag IS NULL)      
     AND part_type != 'C'      
   UNION      
  SELECT ol.order_no, ol.order_ext, ol.location, ol.line_no, olk.part_no, olk.[description],       
         olk.lb_tracking, olk.ordered * olk.qty_per * olk.conv_factor, 0, olk.shipped * olk.qty_per * olk.conv_factor, 0, 0, 0      
    FROM ord_list ol(NOLOCK),      
         ord_list_kit olk (NOLOCK)      
   WHERE ol.order_no  = @order_no      
     AND ol.order_ext = @order_ext      
     AND ol.location  = @location      
     AND olk.part_no  = @part_no      
     AND ol.order_no  = olk.order_no       
     AND ol.order_ext = olk.order_ext       
     AND ol.location  = olk.location       
     AND ol.line_no   = olk.line_no           
     AND ol.part_type = 'C'      
    
 -- v10.4 Start    
 UPDATE a    
 SET  type_code = CASE WHEN b.type_code IN ('SUN','FRAME') THEN '0' ELSE '1' END     
 FROM #so_allocation_detail_view a    
 JOIN inv_master b (NOLOCK)    
 ON  a.part_no = b.part_no    
 -- v10.4 End    
    
  -- v11.2 Start    
  DELETE #tdc_detail_cursor_nodef    
    
  INSERT #tdc_detail_cursor_nodef (line_no, qty_ordered, qty_picked, lb_tracking)    
 SELECT line_no, qty_ordered, qty_picked, lb_tracking       
     FROM #so_allocation_detail_view       
    WHERE order_no  = @order_no      
      AND order_ext = @order_ext      
      AND location  = @location      
      AND part_no   = @part_no      
    ORDER BY type_code ASC     
       
 SET @last_line_row_id = 0    
     
 SELECT TOP 1 @line_row_id = line_row_id,    
   @line_no = line_no,     
   @qty_ordered_for_part_line_no = qty_ordered,     
   @qty_picked_for_part_line_no = qty_picked,     
   @lb_tracking = lb_tracking    
 FROM #tdc_detail_cursor_nodef    
 WHERE line_row_id > @last_line_row_id    
 ORDER BY line_row_id ASC    
    
 WHILE (@@ROWCOUNT <> 0)    
 BEGIN    
    
--  DECLARE detail_cursor CURSOR FOR       
--   SELECT line_no, qty_ordered, qty_picked, lb_tracking       
--     FROM #so_allocation_detail_view       
--    WHERE order_no  = @order_no      
--      AND order_ext = @order_ext      
--      AND location  = @location      
--      AND part_no   = @part_no      
--    ORDER BY type_code ASC -- v10.4 line_no      
--        
--  OPEN detail_cursor       
     
       
--  SELECT @qty_ordered_for_part_line_no = 0       
--  FETCH NEXT FROM detail_cursor INTO @line_no, @qty_ordered_for_part_line_no, @qty_picked_for_part_line_no, @lb_tracking      
--        
--  WHILE (@@FETCH_STATUS = 0)      
--  BEGIN      
-- v11.2 End    
   ------------------------------------------------------------------------------------------------------------------      
   --  Get part type      
   ------------------------------------------------------------------------------------------------------------------      
   SELECT @part_type = part_type      
     FROM ord_list (NOLOCK)      
    WHERE order_no  = @order_no       
      AND order_ext = @order_ext      
      AND line_no   = @line_no       
       
   ------------------------------------------------------------------------------------------------------------------      
   --  Get allocated qty and qty to be allocated for the part / line_no    --      
   ------------------------------------------------------------------------------------------------------------------      
   IF @part_type NOT IN ('M', 'V')      
   BEGIN      
    --  Get allocated qty for the part_no/line_no on the order remove any reference to cross dock bins             
    SELECT @qty_alloc_for_part_line_no = 0      
    SELECT @qty_alloc_for_part_line_no = ISNULL(( SELECT SUM(qty)      
            FROM tdc_soft_alloc_tbl (NOLOCK)      
           WHERE order_no   = @order_no      
             AND order_ext  = @order_ext      
                AND order_type = 'S'      
             AND location   = @location      
             AND line_no    = @line_no      
             AND part_no    = @part_no      
             AND ((lot_ser != 'CDOCK' AND bin_no != 'CDOCK') OR (lot_ser IS NULL AND bin_no IS NULL))      
           GROUP BY location), 0)      
   END      
   ELSE      
   BEGIN      
    SELECT @qty_alloc_for_part_line_no = @qty_ordered_for_part_line_no      
   END      
    
 --BEGIN SED003 -- Case Part    
 --JVM 04/05/2010    
 IF @part_type = 'V' -- Non-Quantity Bearing    
    SET @qty_alloc_for_part_line_no = 0     
 --END   SED003 -- Case Part    
    
   ------------------------------------------------------------------------------------------------------------------      
   --  Get qty that is needed for the part_no/line_no on the order     --      
   ------------------------------------------------------------------------------------------------------------------      
   SELECT @qty_needed_for_part_line_no = 0      
   SELECT @qty_needed_for_part_line_no = ISNULL(@qty_ordered_for_part_line_no, 0) -       
             ISNULL(@qty_picked_for_part_line_no,  0) -       
             ISNULL(@qty_alloc_for_part_line_no,   0)      
       
       
      
       
   ------------------------------------------------------------------------------------------------------------------      
   --  Calculate available qty for the part / line_no on the order     --      
   ------------------------------------------------------------------------------------------------------------------      
   SELECT @qty_avail_for_part_line_no = 0      
       
   IF ISNULL(@qty_to_alloc, 0) < ISNULL(@qty_needed_for_part_line_no, 0)      
    SELECT @qty_avail_for_part_line_no = ISNULL(@qty_to_alloc, 0)      
   ELSE      
    SELECT @qty_avail_for_part_line_no = ISNULL(@qty_needed_for_part_line_no, 0)      
       
      
   ------------------------------------------------------------------------------------------------------------------      
   --  Calculate current allocated % for the part_no / line_no on the order    --      
   ------------------------------------------------------------------------------------------------------------------      
   SELECT @alloc_pct_for_part_line_no = 0      
   SELECT @temp_alloc_pct             = 0      
       
   SELECT @temp_alloc_pct = 100 * (ISNULL(@qty_alloc_for_part_line_no, 0) + ISNULL(@qty_picked_for_part_line_no, 0))      
            / @qty_ordered_for_part_line_no       
   --Call 1557806ESC 07/01/2008      
--    SELECT @temp = ''      
--    SELECT @temp = CAST(@temp_alloc_pct AS varchar(20))      
--    SELECT @alloc_pct_for_part_line_no = CAST (LEFT(@temp, LEN(@temp) - 6) AS decimal (20,2))      
   SELECT @alloc_pct_for_part_line_no = CAST (@temp_alloc_pct AS decimal (20,2))      
   --Call 1557806ESC 07/01/2008      
       
   ------------------------------------------------------------------------------------------------------------------      
   --  Calculate currently available % for the part_no/line_no on the order    --      
   ------------------------------------------------------------------------------------------------------------------      
   SELECT @avail_pct_for_part_line_no = 0      
       
   IF @qty_avail_for_part_line_no > 0       
   BEGIN      
    SELECT @temp_aval_pct = 0      
       
    SELECT @temp_aval_pct = 100 * ISNULL(@qty_avail_for_part_line_no, 0) / @qty_needed_for_part_line_no       
    --Call 1557806ESC 07/01/2008      
--     SELECT @temp = ''      
--     SELECT @temp = CAST(@temp_aval_pct AS varchar(20))      
--     SELECT @avail_pct_for_part_line_no = CAST (LEFT(@temp, LEN(@temp) - 6) AS decimal (20,2))      
    SELECT @avail_pct_for_part_line_no = CAST (@temp_aval_pct AS decimal (20,2))      
    --Call 1557806ESC 07/01/2008      
   END      
   ELSE      
    SELECT @avail_pct_for_part_line_no = ISNULL(@alloc_pct_for_part_line_no, 0)      
       
   ------------------------------------------------------------------------------------------------------------------      
   --  Make final update to the #so_allocation_detail_view table     --      
   ------------------------------------------------------------------------------------------------------------------      
      
   UPDATE #so_allocation_detail_view      
      SET qty_avail  = CASE WHEN @qty_avail_for_part_line_no <= 0      
       THEN 0      
       ELSE @qty_avail_for_part_line_no      
        END,      
          qty_picked = @qty_picked_for_part_line_no,      
          qty_alloc  = @qty_alloc_for_part_line_no,      
          avail_pct  = CASE WHEN @avail_pct_for_part_line_no >= 100      
        THEN 100      
       WHEN @avail_pct_for_part_line_no <= 0      
        THEN 0      
       ELSE  @avail_pct_for_part_line_no      
                                     END,      
          alloc_pct  = CASE WHEN @alloc_pct_for_part_line_no >= 100      
       THEN 100      
       ELSE  @alloc_pct_for_part_line_no      
                                     END      
    WHERE order_no   = @order_no       
      AND order_ext  = @order_ext      
      AND location   = @location      
      AND part_no    = @part_no      
      AND line_no   = @line_no      
      
   SELECT @qty_to_alloc = @qty_to_alloc - ISNULL(@qty_needed_for_part_line_no, 0)      
      
 SET @last_line_row_id = @line_row_id    
     
 SELECT TOP 1 @line_row_id = line_row_id,    
   @line_no = line_no,     
   @qty_ordered_for_part_line_no = qty_ordered,     
   @qty_picked_for_part_line_no = qty_picked,     
   @lb_tracking = lb_tracking    
 FROM #tdc_detail_cursor_nodef    
 WHERE line_row_id > @last_line_row_id    
 ORDER BY line_row_id ASC    
    
--   FETCH NEXT FROM detail_cursor INTO @line_no, @qty_ordered_for_part_line_no, @qty_picked_for_part_line_no, @lb_tracking      
  END      
      
--  CLOSE detail_cursor      
--  DEALLOCATE detail_cursor      
      
      
      
------------------------------------------------------------------------------------------------------------------      
  --  Calculate current fill percentage for the order       --      
  --  Calculate current allocated percentage for the order      --      
  ------------------------------------------------------------------------------------------------------------------      
  SELECT @cur_fill_pct_for_order = 0      
  SELECT @alloc_pct_for_order    = 0      
  SELECT @temp_fill_pct          = 0      
  SELECT @temp_alloc_pct         = 0      
  SELECT @qty_alloc_sa = 0    
       
  SELECT @temp_fill_pct  = 100 * AVG(qty_avail + qty_picked + qty_alloc) / AVG(qty_ordered),      
         @temp_alloc_pct = 100 * AVG(qty_alloc + qty_picked) / AVG(qty_ordered)      
           FROM #so_allocation_detail_view      
   WHERE order_no  = @order_no      
     AND order_ext = @order_ext      
            AND location = @location      
   GROUP BY location      
        
  --Call 1557806ESC 07/01/2008      
--   SELECT @temp = ''      
--   SELECT @temp = CAST(@temp_fill_pct AS varchar(20))      
--   SELECT @cur_fill_pct_for_order = CAST (LEFT(@temp, LEN(@temp) - 6) AS decimal (20,2))      
  SELECT @cur_fill_pct_for_order = CAST (@temp_fill_pct AS decimal (20,2))      
        
--   SELECT @temp = ''      
--   SELECT @temp = CAST(@temp_alloc_pct AS varchar(20))      
--   SELECT @alloc_pct_for_order = CAST (LEFT(@temp, LEN(@temp) - 6) AS decimal (20,2))      
  SELECT @alloc_pct_for_order = CAST (@temp_alloc_pct AS decimal (20,2))      
  --Call 1557806ESC 07/01/2008      
  ------------------------------------------------------------------------------------------------------------------      
  --  If either flag is on requiring a top-level part list for kits,      --      
  --              Build a temp table containing the required information      --      
  ------------------------------------------------------------------------------------------------------------------      
  IF @calc_shippable_dollars_flg = 1 or @calc_margin_flg = 1      
  BEGIN      
   TRUNCATE TABLE #top_level_parts      
       
   INSERT INTO #top_level_parts(line_no, part_no, qty_alloc, qty_avail)      
   SELECT a.line_no, a.part_no, a.qty_alloc, a.qty_avail       
     FROM #so_allocation_detail_view a,       
          ord_list b (NOLOCK)      
    WHERE a.order_no  = b.order_no        
      AND a.order_ext = b.order_ext        
      AND a.location  = b.location        
      AND a.line_no   = b.line_no      
      AND a.order_no  = @order_no      
      AND a.order_ext = @order_ext      
      AND a.location  = @location      
      AND b.part_type = 'P'      
   UNION      
   SELECT b.line_no, b.part_no, FLOOR(a.qty_alloc / c.qty_per), FLOOR(a.qty_avail / c.qty_per)      
     FROM #so_allocation_detail_view a,       
          ord_list b (NOLOCK),       
          ord_list_kit c(NOLOCK)      
    WHERE a.order_no  = b.order_no        
      AND a.order_ext = b.order_ext        
      AND a.location  = b.location        
      AND a.line_no   = b.line_no      
      AND a.order_no  = c.order_no      
      AND a.order_ext = c.order_ext      
      AND a.location  = c.location      
      AND a.line_no   = c.line_no      
      AND a.order_no  = @order_no      
      AND a.order_ext = @order_ext      
      AND a.location  = @location      
      AND b.part_type = 'C'      
  END      
       
  ------------------------------------------------------------------------------------------------------------------      
  --  Calculate Ordered Dollars         --      
  ------------------------------------------------------------------------------------------------------------------      
  IF @cal_ordered_dollars_flg = 1      
  BEGIN        
   SELECT @calc_ordered_dollars = ISNULL(( SELECT SUM((ordered * price) -       
           ((ordered * price) * discount / 100))      
                            FROM ord_list (NOLOCK)      
                          WHERE order_no  = @order_no      
                       AND order_ext = @order_ext      
                       AND location  = @location), 0)      
          
  END      
  ELSE      
   SELECT @calc_ordered_dollars = NULL      
       
  ------------------------------------------------------------------------------------------------------------------      
  --  Calculate Margin Percent         --      
  --              The calculation is (total price (including discount) - cost) / total price    --      
  ------------------------------------------------------------------------------------------------------------------      
       
  IF @calc_margin_flg = 1      
  BEGIN      
   SELECT @total_price = 0      
          SELECT @total_price = SUM(((qty_alloc + qty_avail) * price) -       
             (((qty_alloc + qty_avail) * price) * (discount / 100)))      
            FROM ord_list a (NOLOCK), #top_level_parts t      
              WHERE a.order_no  = @order_no      
             AND a.order_ext = @order_ext      
             AND a.location  = @location      
             AND a.line_no   = t.line_no      
       
       
   SELECT @total_cost = NULL      
   SELECT @total_cost =  (SELECT SUM((i.std_cost + i.std_direct_dolrs + i.std_ovhd_dolrs + i.std_util_dolrs) * (qty_avail + t.qty_alloc)) --ordered)      
       FROM inventory i(NOLOCK), #top_level_parts t      
      WHERE i.location   = @location      
        AND i.part_no    = t.part_no       
        AND i.inv_cost_method = 'S')       
       
   IF @total_cost IS NULL      
   BEGIN      
    SELECT @total_cost = SUM((i.avg_cost + i.avg_direct_dolrs + i.avg_ovhd_dolrs + i.avg_util_dolrs) * (qty_avail + t.qty_alloc)) --ordered)      
      FROM inventory i(NOLOCK),       
           #top_level_parts t      
     WHERE i.location         = @location      
       AND i.part_no          = t.part_no       
       AND i.inv_cost_method != 'S'        
   END      
       
   IF @total_price > 0       
    SET @shippable_margin_dollars = (((@total_price - @total_cost) / @total_price) * 100)      
   ELSE      
    SELECT @shippable_margin_dollars = 0      
  END      
  ELSE        
   SELECT @shippable_margin_dollars = NULL      
       
  ------------------------------------------------------------------------------------------------------------------      
  --  Calculate Shippable Dollars         --      
  ------------------------------------------------------------------------------------------------------------------      
       
  -- Create logic to calculate the total shippable dollar amount at the order/ext/location level        
  IF @calc_shippable_dollars_flg = 1      
  BEGIN        
   SELECT @calc_shippable_dollars = ISNULL((SELECT SUM(((qty_alloc + a.qty_avail) * b.price) -       
                                                      (((qty_alloc + a.qty_avail) * b.price) * b.discount / 100))      
                FROM ord_list b (NOLOCK),      
         #top_level_parts a      
              WHERE b.order_no  = @order_no       
                  AND b.order_ext = @order_ext      
                  AND a.line_no   = b.line_no      
                  AND b.location  = @location      
                  AND a.part_no   = b.part_no ), 0)      
  END      
  ELSE      
   SELECT @calc_shippable_dollars = NULL      
       
       
  ------------------------------------------------------------------------------------------------------------------      
  --  Get distribution process type         --      
  ------------------------------------------------------------------------------------------------------------------       
  SET @alloc_type = NULL      
  SELECT @alloc_type = CASE alloc_type                              
                                 WHEN 'PR' THEN 'Pre-Pack'                 
                                 WHEN 'PT' THEN 'Console Pick'             
                                 WHEN 'PP' THEN 'Pick/Pack'                
                                 WHEN 'PB' THEN 'Package Builder'          
     ELSE NULL      
                              END           
    FROM tdc_cons_ords (NOLOCK)      
          WHERE order_no  = @order_no       
     AND order_ext = @order_ext      
     AND location  = @location       
        
  ------------------------------------------------------------------------------------------------------------------      
  --  Do Update           --      
  ------------------------------------------------------------------------------------------------------------------       
  UPDATE #so_alloc_management      
     SET curr_fill_pct     = CASE WHEN @cur_fill_pct_for_order > 100      
               THEN 100      
             WHEN @cur_fill_pct_for_order <= 0      
               THEN 0      
             ELSE @cur_fill_pct_for_order            
        END,      
         curr_alloc_pct    = CASE WHEN @alloc_pct_for_order > 100      
             THEN 100      
             ELSE @alloc_pct_for_order       
        END,       
         ordered_dollars   = CAST(CAST(ROUND(@calc_ordered_dollars,2)     AS DECIMAL(20,2)) AS VARCHAR(20)) + ' ' + @currency,      
         shippable_margin_dollars = @shippable_margin_dollars,      
         shippable_dollars = CAST(CAST(ROUND(@calc_shippable_dollars,2)   AS DECIMAL(20,2)) AS VARCHAR(20)) + ' ' + @currency,      
         alloc_type  = @alloc_type      
          WHERE order_no     = @order_no       
     AND order_ext    = @order_ext      
     AND location     = @location       
      
 -- v11.2 Start    
 SET @last_row_id = @row_id    
    
 SELECT TOP 1 @row_id = row_id,    
   @order_no = order_no,     
   @order_ext =order_ext,     
   @location = location,     
   @part_no = part_no,     
   @qty_to_alloc = qty_to_alloc,     
   @currency = currency    
 FROM #tdc_selected_detail_cursor_nodef    
 WHERE row_id > @last_row_id    
    
    
--  FETCH NEXT FROM selected_detail_cursor INTO @order_no, @order_ext, @location, @part_no, @qty_to_alloc, @currency      
 END      
 --CLOSE selected_detail_cursor      
 --DEALLOCATE selected_detail_cursor      
 DROP TABLE #tdc_selected_detail_cursor_nodef    
 DROP TABLE #tdc_detail_cursor_nodef    
 -- v11.2 End    
      
 RETURN      
END      
ELSE      
-------------------------------------------------------------------------------------------------------------------------------------------------------      
-- Default Allocation Method      
-------------------------------------------------------------------------------------------------------------------------------------------------------      
BEGIN      
      
 ------------------------------------------------------------------------------------------------------------------------------------      
       
 -- Now we'll loop through the Sales Orders and populate the #so_allocation_detail_view,      
 -- and calculate all the data we need for the #so_alloc_management table      
       
 ----------------------------------------------------------------------------------------------------------      
 -- selected_detail_cursor declaration is being executed as a string so the order by clause that is sent by  --      
 -- the VB app can be applied this process is important in that it will determine what orders get rights --      
 -- to the inventory first.                                                                              --      
 ----------------------------------------------------------------------------------------------------------      
    
-- v1.8 Start    
CREATE TABLE #excluded_bins (bin_no varchar(20))    
CREATE INDEX #ind0 ON #excluded_bins(bin_no)    
    
-- v10.2 INSERT #excluded_bins SELECT bins FROM dbo.f_get_excluded_bins(2)    
-- v10.6 INSERT #excluded_bins SELECT bins FROM dbo.f_get_excluded_bins(3) -- v10.2    
INSERT #excluded_bins SELECT bins FROM dbo.f_get_excluded_bins(2) -- v10.6    
-- v1.8 End    
    
-- v11.2 Start    

-- v11.5 Start 
CREATE TABLE #cvo_selected_sa (  
 soft_alloc_no int,  
 order_no   int,  
 order_ext   int)  

  
INSERT #cvo_selected_sa  
SELECT  MAX(CASE WHEN b.soft_alloc_no IS NULL THEN 999999999 ELSE b.soft_alloc_no END), a.order_no, a.order_ext  
FROM #so_alloc_management a  
LEFT JOIN cvo_soft_alloc_hdr b (NOLOCK)  
ON  a.order_no = b.order_no  
AND  a.order_ext = b.order_ext  
--WHERE (b.status IN (0,1,-1) OR b.status IS NULL) -- v11.6
GROUP BY a.order_no, a.order_ext  
 -- v11.5 End
    
CREATE TABLE #tdc_selected_detail_cursor(    
  row_id   int IDENTITY(1,1),    
  soft_alloc_no int,  
  order_no  int,    
  order_ext  int,    
  location  varchar(10),    
  currency  varchar(20))    
    
CREATE TABLE #tdc_detail_cursor (    
  line_row_id  int IDENTITY(1,1),    
  part_no   varchar(30),    
  line_no   int,     
  qty_ordered  decimal(20,8),     
  qty_picked  decimal(20,8),     
  lb_tracking  char(1))    
    
CREATE INDEX #tdc_detail_cursor_ind0 ON #tdc_detail_cursor(line_row_id)    
   
 SELECT @declare_clause = 'INSERT #tdc_selected_detail_cursor (order_no, order_ext, location, currency)      
       SELECT order_no, order_ext, location, (SELECT curr_key FROM orders a(nolock)         
            WHERE a.order_no = #so_alloc_management.order_no      
              AND a.ext = #so_alloc_management.order_ext)      
         FROM #so_alloc_management '   
  
 EXEC (@declare_clause + @order_by_clause)       
 
-- v11.5 Start
CREATE TABLE #tdc_selected_detail_cursor_copy (    
  soft_alloc_no int,  
  order_no  int,    
  order_ext  int,    
  location  varchar(10),    
  currency  varchar(20))  
  
INSERT #tdc_selected_detail_cursor_copy  
SELECT a.soft_alloc_no, b.order_no, b.order_ext, b.location, b.currency  
FROM #cvo_selected_sa a  
JOIN #tdc_selected_detail_cursor b  
ON  a.order_no = b.order_no  
AND  a.order_ext =  b.order_ext  
  
DELETE  #tdc_selected_detail_cursor  
  
INSERT  #tdc_selected_detail_cursor (order_no, order_ext, location, currency)  
SELECT order_no, order_ext, location, currency  
FROM #tdc_selected_detail_cursor_copy  
ORDER BY soft_alloc_no ASC  
  
DROP TABLE #cvo_selected_sa  
DROP TABLE #tdc_selected_detail_cursor_copy  
-- v11.5 End  
   
CREATE INDEX #tdc_selected_detail_cursor_ind0 ON #tdc_selected_detail_cursor(row_id)    
CREATE INDEX #tdc_selected_detail_cursor_ind1 ON #tdc_selected_detail_cursor(order_no)    
    
SET @last_row_id = 0    
    
SELECT TOP 1 @row_id = row_id,    
  @order_no = order_no,     
  @order_ext =order_ext,     
  @location = location,    
  @currency = currency    
FROM #tdc_selected_detail_cursor    
WHERE row_id > @last_row_id    
    
WHILE (@@ROWCOUNT <> 0)    
BEGIN    
    
--       
-- SELECT @declare_clause = 'DECLARE selected_detail_cursor CURSOR FOR       
--       SELECT order_no, order_ext, location, (SELECT curr_key FROM orders a(nolock)         
--            WHERE a.order_no = #so_alloc_management.order_no      
--              AND a.ext = #so_alloc_management.order_ext)      
--         FROM #so_alloc_management '      
-- EXEC (@declare_clause + @order_by_clause)       
--       
-- OPEN selected_detail_cursor      
-- FETCH NEXT FROM selected_detail_cursor INTO @order_no, @order_ext, @location, @currency      
--       
-- WHILE (@@FETCH_STATUS = 0)      
-- BEGIN      
   -- v11.2 End    
 ------------------------------------------------------------------------------------------------------------------------------------      
  -- Now we'll get all the data we can get for the #so_allocation_detail_view table.      
  -- Later we'll update the the feilds that have to be calculated.      
  INSERT INTO #so_allocation_detail_view (order_no, order_ext, location, line_no, part_no, part_desc, lb_tracking,       
       qty_ordered, qty_avail, qty_picked, qty_alloc, avail_pct, alloc_pct)      
  SELECT order_no, order_ext, location, line_no, part_no, [description], lb_tracking, ordered * conv_factor, 0, shipped * conv_factor, 0, 0, 0      
    FROM ord_list (NOLOCK)      
   WHERE order_no  = @order_no      
     AND order_ext = @order_ext      
     AND location  = @location      
     AND (create_po_flag IS NULL OR create_po_flag <> 1)      
     AND part_type != 'C'      
     AND part_type IS NOT NULL      
      
  INSERT INTO #so_allocation_detail_view (order_no, order_ext, location, line_no, part_no, part_desc, lb_tracking,       
       qty_ordered, qty_avail, qty_picked, qty_alloc, avail_pct, alloc_pct)      
  SELECT ol.order_no, ol.order_ext, ol.location, ol.line_no, olk.part_no, olk.[description],       
         olk.lb_tracking, olk.ordered * olk.qty_per * olk.conv_factor, 0, olk.shipped * olk.qty_per * olk.conv_factor, 0, 0, 0      
    FROM ord_list ol(NOLOCK),      
         ord_list_kit olk (NOLOCK)      
   WHERE ol.order_no  = @order_no      
     AND ol.order_ext = @order_ext      
     AND ol.location  = @location      
     AND ol.order_no  = olk.order_no       
     AND ol.order_ext = olk.order_ext       
     AND ol.location  = olk.location       
     AND ol.line_no   = olk.line_no      
     AND ol.part_type = 'C'      
       
    
 -- v10.4 Start    
 UPDATE a    
 SET  type_code = CASE WHEN b.type_code IN ('SUN','FRAME') THEN '0' ELSE '1' END     
 FROM #so_allocation_detail_view a    
 JOIN inv_master b (NOLOCK)    
 ON  a.part_no = b.part_no    
 -- v10.4 End    
    
 -- v11.3 Start    
 SET @max_soft_alloc = 0    
     
 SELECT @max_soft_alloc = MAX(soft_alloc_no)    
 FROM dbo.cvo_soft_alloc_det (NOLOCK)    
 WHERE order_no = @order_no    
 AND  order_ext = @order_ext    
 AND  status IN (0,1,-1,-3,-4) -- v11.9 Include -4  -- v12.0  

 -- v11.3 End    
    
-- v11.2 Start    
   DELETE #tdc_detail_cursor    
     
 INSERT #tdc_detail_cursor (part_no, line_no, qty_ordered, qty_picked, lb_tracking)    
   SELECT part_no, line_no, qty_ordered, qty_picked, lb_tracking       
     FROM #so_allocation_detail_view       
    WHERE order_no  = @order_no      
      AND order_ext = @order_ext      
      AND location  = @location      
    ORDER BY type_code ASC -- v10.4 line_no      
    
--  DECLARE detail_cursor CURSOR FOR       
--   SELECT part_no, line_no, qty_ordered, qty_picked, lb_tracking       
--     FROM #so_allocation_detail_view       
--    WHERE order_no  = @order_no      
--      AND order_ext = @order_ext      
--      AND location  = @location      
--    ORDER BY type_code ASC -- v10.4 line_no      
--        
--  OPEN detail_cursor       
--        
--    SELECT @qty_ordered_for_part_line_no = 0       
--  FETCH NEXT FROM detail_cursor INTO @part_no, @line_no, @qty_ordered_for_part_line_no, @qty_picked_for_part_line_no, @lb_tracking      
--        
--  WHILE (@@FETCH_STATUS = 0)      
--  BEGIN       
    
 SET @last_line_row_id = 0    
     
 SELECT TOP 1 @line_row_id = line_row_id,    
   @part_no = part_no,    
   @line_no = line_no,     
   @qty_ordered_for_part_line_no = qty_ordered,     
   @qty_picked_for_part_line_no = qty_picked,     
   @lb_tracking = lb_tracking    
 FROM #tdc_detail_cursor    
 WHERE line_row_id > @last_line_row_id    
 ORDER BY line_row_id ASC    
    
 WHILE (@@ROWCOUNT <> 0)    
 BEGIN    
 -- v11.2 End    
   ------------------------------------------------------------------------------------------------------------------      
   --  Get part type      
   ------------------------------------------------------------------------------------------------------------------      
   SELECT @part_type = part_type      
     FROM ord_list (NOLOCK)      
    WHERE order_no  = @order_no       
      AND order_ext = @order_ext      
      AND line_no   = @line_no       
       
   ------------------------------------------------------------------------------------------------------------------      
   --  Get allocated qty and qty to be allocated for the part / line_no    --      
   ------------------------------------------------------------------------------------------------------------------      
   SELECT @qty_alloc_for_part_line_no = 0      
   IF @part_type NOT IN ('M', 'V')      
   BEGIN      
    
    --  Get allocated qty for the part_no/line_no on the order remove any reference to cross dock bins      
    SELECT @qty_alloc_for_part_line_no = ISNULL((SELECT SUM(qty)      
            FROM tdc_soft_alloc_tbl (NOLOCK)      
           WHERE order_no   = @order_no      
             AND order_ext  = @order_ext      
                AND order_type = 'S'      
              AND location   = @location      
             AND line_no    = @line_no      
             AND part_no    = @part_no      
             AND ((lot_ser != 'CDOCK' AND bin_no != 'CDOCK') OR (lot_ser IS NULL AND bin_no IS NULL))      
           GROUP BY location), 0)      
   END      
   ELSE      
   BEGIN      
    SELECT @qty_alloc_for_part_line_no = @qty_ordered_for_part_line_no      
   END      
    
 --BEGIN SED003 -- Case Part    
 --JVM 04/05/2010    
 IF @part_type = 'V' -- Non-Quantity Bearing    
    SET @qty_alloc_for_part_line_no = 0     
 --END   SED003 -- Case Part    
       
   ------------------------------------------------------------------------------------------------------------------      
   --  Get qty that is needed for the part_no/line_no on the order     --      
   ------------------------------------------------------------------------------------------------------------------         
   SELECT @qty_needed_for_part_line_no = ISNULL(@qty_ordered_for_part_line_no, 0) -       
             ISNULL(@qty_picked_for_part_line_no,  0) -       
             ISNULL(@qty_alloc_for_part_line_no,   0)      
      
   IF @qty_needed_for_part_line_no IS NULL       
    SELECT @qty_needed_for_part_line_no = 0      
   --------------------------------------------------------------------------------------------------------------------------      
       
   -- Get In Stock qty for the part_no from all the BINs except the receipt BINs      
   SELECT @qty_in_stock = 0      
      
   --  Get allocated qty for the part_no for all the orders. Remove any reference to cross dock BINs.                 
   SELECT @qty_alloc_for_part_total = 0      
      
   IF @lb_tracking = 'N'       
   BEGIN      
    SELECT @qty_in_stock = 0      
 -- v1.6     
    
    SELECT @qty_in_stock = in_stock       
      FROM inventory (NOLOCK)       
     WHERE part_no = @part_no       
       AND location = @location      
    
    
    SELECT @qty_in_stock = ISNULL(@qty_in_stock, 0) -       
             ISNULL((SELECT SUM(pick_qty - used_qty)       
                 FROM tdc_wo_pick (NOLOCK)      
                WHERE part_no = @part_no       
                  AND location = @location), 0)      
      
    SELECT @qty_alloc_for_part_total = ISNULL((SELECT SUM(qty)      
              FROM tdc_soft_alloc_tbl (NOLOCK)      
             WHERE location = @location      
               AND part_no  = @part_no), 0)      
      
   END      
   ELSE         
   BEGIN      

-- v11.7 Start
--	EXEC dbo.CVO_AvailabilityInStock_tdc_sp @part_no, @location, @qty_in_stock OUTPUT
	EXEC dbo.CVO_AvailabilityInStock_sp @part_no, @location, @qty_in_stock OUTPUT
    
/*
    SELECT @qty_in_stock = ISNULL(( SELECT SUM(qty)       
                   FROM lot_bin_stock  a (NOLOCK),       
               tdc_bin_master b (NOLOCK)       
                       WHERE a.location = @location       
           AND a.part_no  = @part_no                       
              AND a.bin_no   = b.bin_no       
              AND a.location = b.location       
              AND b.usage_type_code IN ('OPEN', 'REPLENISH')     
--     AND a.bin_no NOT IN (SELECT bins FROM dbo.f_get_excluded_bins(0) WHERE part_no = @part_no) -- v1.1     
-- v1.8     AND a.bin_no NOT IN (SELECT bins FROM dbo.f_get_excluded_bins(2)) -- v1.6     
     AND a.bin_no NOT IN (SELECT bin_no FROM #excluded_bins) -- v1.8 #excluded_bins    
     GROUP BY a.part_no), 0)      
*/
-- v11.7 End

	-- v11.8 Start Double counting allocated stock
    SELECT @qty_alloc_for_part_total = 0 --ISNULL((SELECT SUM(a.qty)      
--              FROM tdc_soft_alloc_tbl a(NOLOCK),      
--                   tdc_bin_master b(NOLOCK)      
--             WHERE a.location   = @location      
--               AND a.part_no    = @part_no      
--               AND a.location   = b.location      
--               AND a.bin_no     = b.bin_no      
--               AND (a.lot_ser != 'CDOCK' AND a.bin_no != 'CDOCK')      
--               AND b.usage_type_code IN ('OPEN', 'REPLENISH')      
--            GROUP BY a.location ), 0)      
-- v11.8 End
   END      
      
   -- Get pre-allocated qty for the part on all the Sales Orders      
   SELECT @qty_pre_allocated_total = ISNULL((SELECT SUM(pre_allocated_qty)      
            FROM #so_pre_allocation_table       
           WHERE part_no  = @part_no      
             AND location = @location      
          GROUP BY location) , 0)      
    

    
-- v10.9 Start    
 SELECT @qty_alloc_sa = ISNULL((SELECT SUM(a.quantity)      
            FROM cvo_soft_alloc_det a (NOLOCK)       
   LEFT JOIN #tdc_selected_detail_cursor b    
   ON a.order_no = b.order_no    
   AND a.order_ext = b.order_ext    
           WHERE a.part_no  = @part_no      
             AND a.location = @location    
    AND a.soft_alloc_no < @max_soft_alloc -- v11.3    
-- v11.3    AND a.order_no < @order_no    
    AND a.status IN (0,1,-1,-4) -- v11.1 v11.9 Include -4     
     AND b.order_no IS NULL    
          GROUP BY a.location) , 0)     
  
 
   SELECT @qty_pre_allocated_total = @qty_pre_allocated_total + ISNULL(@qty_alloc_sa,0)    
-- v10.9 End    

    
       
   ------------------------------------------------------------------------------------------------------------------      
   --  Calculate total available qty for the part        --      
   ------------------------------------------------------------------------------------------------------------------      
   SELECT @qty_avail_for_part_total = 0      
   SELECT @qty_avail_for_part_total = ISNULL(@qty_in_stock,       0) -       
          ISNULL(@qty_alloc_for_part_total, 0) -       
          ISNULL(@qty_pre_allocated_total,  0)      
   
   
   -- v11.4 Start    
 IF (@qty_avail_for_part_total < 0)    
  SET @qty_avail_for_part_total = 0    
 -- v11.4 End    
    

   -- Get pre-allocated qty for the part on the current order      
   SELECT @qty_pre_alloc_for_part_on_order = ISNULL((SELECT SUM(pre_allocated_qty)      
           FROM #so_pre_allocation_table       
          WHERE order_no  = @order_no      
            AND order_ext = @order_ext      
            AND location  = @location      
            AND part_no   = @part_no      
          GROUP BY location), 0)      
    
     
   ------------------------------------------------------------------------------------------------------------------      
   --  Calculate available qty for the part / line_no on the order     --      
   ------------------------------------------------------------------------------------------------------------------      
   SELECT @qty_avail_for_part_line_no = 0      
       
   IF ISNULL(@qty_avail_for_part_total, 0) < ISNULL(@qty_needed_for_part_line_no, 0)      
    SELECT @qty_avail_for_part_line_no = ISNULL(@qty_avail_for_part_total, 0)      
   ELSE      
    SELECT @qty_avail_for_part_line_no = ISNULL(@qty_needed_for_part_line_no, 0)      
      
    

   ------------------------------------------------------------------------------------------------------------------      
   --  Calculate current allocated % for the part_no / line_no on the order    --      
   ------------------------------------------------------------------------------------------------------------------      
   SELECT @alloc_pct_for_part_line_no = 0      
   SELECT @temp_alloc_pct             = 0      
       
   SELECT @temp_alloc_pct = 100 * (ISNULL(@qty_alloc_for_part_line_no, 0) + ISNULL(@qty_picked_for_part_line_no, 0))      
            / @qty_ordered_for_part_line_no       
        
   --Call 1557806ESC 07/01/2008      
--    SELECT @temp = ''      
--    SELECT @temp = CAST(@temp_alloc_pct AS varchar(20))      
--    SELECT @alloc_pct_for_part_line_no = CAST (LEFT(@temp, LEN(@temp) - 6) AS decimal (20,2))      
   SELECT @alloc_pct_for_part_line_no = CAST (@temp_alloc_pct AS decimal (20,2))      
   --Call 1557806ESC 07/01/2008      
      
   ------------------------------------------------------------------------------------------------------------------      
   --  Calculate currently available % for the part_no/line_no on the order    --      
   ------------------------------------------------------------------------------------------------------------------      
   SELECT @avail_pct_for_part_line_no = 0      
       
   IF @qty_avail_for_part_line_no > 0       
   BEGIN      
    SELECT @temp_aval_pct = 0      
       
    SELECT @temp_aval_pct = 100 * ISNULL(@qty_avail_for_part_line_no, 0) / @qty_needed_for_part_line_no       
       
    --Call 1557806ESC 07/01/2008      
--     SELECT @temp = ''      
--     SELECT @temp = CAST(@temp_aval_pct AS varchar(20))      
--     SELECT @avail_pct_for_part_line_no = CAST (LEFT(@temp, LEN(@temp) - 6) AS decimal (20,2))      
    SELECT @avail_pct_for_part_line_no = CAST (@temp_aval_pct AS decimal (20,2))      
    --Call 1557806ESC 07/01/2008      
   END      
   ELSE      
    SELECT @avail_pct_for_part_line_no = ISNULL(@alloc_pct_for_part_line_no, 0)      
       
   ------------------------------------------------------------------------------------------------------------------      
   --  Make final update to the #so_allocation_detail_view table     --      
   ------------------------------------------------------------------------------------------------------------------      
     UPDATE #so_allocation_detail_view      
      SET qty_avail  = CASE WHEN @qty_avail_for_part_line_no <= 0      
       THEN 0      
       ELSE @qty_avail_for_part_line_no      
         END,      
          qty_picked = @qty_picked_for_part_line_no,      
          qty_alloc  = @qty_alloc_for_part_line_no,      
          avail_pct  = CASE WHEN @avail_pct_for_part_line_no >= 100      
        THEN 100      
       WHEN @avail_pct_for_part_line_no <= 0      
        THEN 0      
       ELSE  @avail_pct_for_part_line_no      
                                     END,      
          alloc_pct  = CASE WHEN @alloc_pct_for_part_line_no >= 100      
       THEN 100      
       ELSE  @alloc_pct_for_part_line_no      
                                     END      
    WHERE order_no   = @order_no       
      AND order_ext  = @order_ext      
      AND location   = @location      
      AND part_no    = @part_no      
      AND line_no   = @line_no      
       
        
 -------------------------------------------------------------------------------------------------------------------------------      
       
   INSERT INTO #so_pre_allocation_table (order_no, order_ext, location, part_no, line_no, pre_allocated_qty)      
   VALUES(@order_no, @order_ext, @location, @part_no, @line_no, @qty_avail_for_part_line_no)      
      
 SET @last_line_row_id = @line_row_id    
     
 SELECT TOP 1 @line_row_id = line_row_id,    
   @part_no = part_no,    
   @line_no = line_no,     
   @qty_ordered_for_part_line_no = qty_ordered,     
   @qty_picked_for_part_line_no = qty_picked,     
   @lb_tracking = lb_tracking    
 FROM #tdc_detail_cursor    
 WHERE line_row_id > @last_line_row_id    
 ORDER BY line_row_id ASC    
     
--   FETCH NEXT FROM detail_cursor       
--    INTO @part_no, @line_no, @qty_ordered_for_part_line_no, @qty_picked_for_part_line_no, @lb_tracking      
  END      
        
--  CLOSE      detail_cursor       
--  DEALLOCATE detail_cursor       
       
       
 -------------------------------------------------------------------------------------------------------------------------------      
  ------------------------------------------------------------------------------------------------------------------      
  --  Calculate current fill percentage for the order       --      
  --  Calculate current allocated percentage for the order      --      
  ------------------------------------------------------------------------------------------------------------------      
    
  SELECT @cur_fill_pct_for_order = 0      
  SELECT @alloc_pct_for_order    = 0      
       
  SELECT @temp_fill_pct  = 100 * AVG(qty_avail + qty_picked + qty_alloc) / AVG(qty_ordered),      
         @temp_alloc_pct = 100 * AVG(qty_alloc + qty_picked) / AVG(qty_ordered)      
           FROM #so_allocation_detail_view      
   WHERE order_no  = @order_no      
     AND order_ext = @order_ext      
            AND location = @location      
   GROUP BY location      
    
        
  IF @temp_fill_pct IS NULL SELECT @temp_fill_pct = 0      
  IF @temp_alloc_pct IS NULL SELECT @temp_alloc_pct = 0      
      
  --Call 1557806ESC 07/01/2008      
--   SELECT @temp = ''      
--   SELECT @temp = CAST(@temp_fill_pct AS varchar(20))      
--   SELECT @cur_fill_pct_for_order = CAST (LEFT(@temp, LEN(@temp) - 6) AS decimal (20,2))      
  SELECT @cur_fill_pct_for_order = CAST (@temp_fill_pct AS decimal (20,2))      
        
--   SELECT @temp = ''      
--   SELECT @temp = CAST(@temp_alloc_pct AS varchar(20))      
--   SELECT @alloc_pct_for_order = CAST (LEFT(@temp, LEN(@temp) - 6) AS decimal (20,2))      
  SELECT @alloc_pct_for_order = CAST (@temp_alloc_pct AS decimal (20,2))      
  --Call 1557806ESC 07/01/2008      
    
-- v10.1     
 IF EXISTS (SELECT 1 FROM cvo_ord_list (NOLOCK) WHERE is_customized = 'S' AND order_no = @order_no AND order_ext = @order_ext)    
 BEGIN    
  IF OBJECT_ID('tempdb..#CFParts') IS NOT NULL    
   DROP TABLE #CFParts    
    
  CREATE TABLE #CFParts (    
   id    int identity(1,1),    
   location  varchar(10),    
   part_no   varchar(30),    
   qty_required decimal(20,8),    
   qty_available decimal(20,8))        
  IF OBJECT_ID('tempdb..#wms_ret') IS NOT NULL    
   DROP TABLE #wms_ret    
    
  CREATE TABLE #wms_ret ( location  varchar(10),    
        part_no   varchar(30),    
        allocated_qty decimal(20,8),    
        quarantined_qty decimal(20,8),    
        apptype   varchar(20))     
    
  INSERT #CFParts (location, part_no, qty_required, qty_available)    
  SELECT DISTINCT a.location, a.part_no, b.ordered, 0    
  FROM cvo_ord_list_kit a (NOLOCK)    
  JOIN ord_list_kit b (NOLOCK)    
  ON  a.order_no = b.order_no    
  AND  a.order_ext = b.order_ext    
  AND  a.line_no = b.line_no    
  AND  a.replaced = 'S'    
  AND  a.order_no = @order_no    
  AND  a.order_ext = @order_ext    
  AND  b.location = @location    
    
  SET @last_id = 0    
    
  SELECT TOP 1 @id = id,    
    @location = location,    
    @part_no = part_no    
  FROM #CFParts    
  WHERE id > @last_id    
  ORDER BY id ASC    
    
  WHILE @@ROWCOUNT <> 0    
  BEGIN    
    
   -- v11.0 Start    
   SET @in_stock = 0    
   SET @alloc_qty = 0    
   SET @quar_qty = 0    
   SET @act_alloc = 0    
   SET @sa_qty = 0    
   SET @av_qty = 0    
   -- v11.0 End    
    
   SELECT @in_stock = in_stock    
   FROM inventory (NOLOCK)    
   WHERE location = @location    
   AND  part_no = @part_no    
    
   -- WMS - allocated and quarantined    
   INSERT #wms_ret    
   EXEC tdc_get_alloc_qntd_sp @location, @part_no    
    
   SELECT @alloc_qty = allocated_qty,    
     @quar_qty = quarantined_qty    
   FROM #wms_ret    
    
   IF (@alloc_qty IS NULL)    
    SET @alloc_qty = 0    
    
   IF (@quar_qty IS NULL)    
    SET @quar_qty = 0    
    
   DELETE #wms_ret    
    
   -- v10.7 Start    
   SELECT @act_alloc = qty_to_process    
   FROM tdc_pick_queue (NOLOCK)    
   WHERE trans_type_no = @order_no    
   AND  trans_type_ext = @order_ext    
   AND  location = @location    
   AND  part_no = @part_no    
    
   IF (@act_alloc IS NULL)    
    SET @act_alloc = 0    
   -- v10.7 End      
    
   -- Soft Allocation - commited quantity    
   /* v10.5 Start    
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
   AND  CAST(a.order_no AS varchar(10)) + CAST(a.order_ext AS varchar(5)) <> CAST(@order_no AS varchar(10)) + CAST(@order_ext AS varchar(5))     
   AND  a.location = @location    
   AND  a.part_no = @part_no    
   AND  ISNULL(b.order_type,'S') = 'S' */    
    
   SELECT @sa_qty = ISNULL(SUM(CASE WHEN a.deleted = 1 THEN (a.quantity * -1) ELSE a.quantity END),0)    
   FROM dbo.cvo_soft_alloc_det a (NOLOCK)    
   WHERE a.status IN (0, 1, -1)    
   AND  CAST(a.order_no AS varchar(10)) + CAST(a.order_ext AS varchar(5)) <> CAST(@order_no AS varchar(10)) + CAST(@order_ext AS varchar(5))     
   AND  a.location = @location    
   AND  a.part_no = @part_no    
   -- v10.5 End    
    
   IF (@sa_qty IS NULL)    
    SET @sa_qty = 0    
    
   SET @av_qty = (@in_stock - (@alloc_qty + @quar_qty + @sa_qty) + @act_alloc) -- v10.7     
    
    
   -- v11.0 Start    
   IF (@av_qty < 0)    
    SET @av_qty = 0    
   -- v1.0 End    
    
   UPDATE #CFParts    
   SET  qty_available = CASE WHEN @av_qty >= qty_required THEN qty_required ELSE @av_qty END    
   WHERE id = @id    
    
   SET @last_id = @id    
    
   SELECT TOP 1 @id = id,    
     @location = location,    
     @part_no = part_no    
   FROM #CFParts    
   WHERE id > @last_id    
   ORDER BY id ASC    
  END    
      
  -- @temp_fill_pct    
  SELECT @avg_avail = SUM(qty_avail + qty_picked + qty_alloc),    
    @avg_order = SUM(qty_ordered)    
        FROM #so_allocation_detail_view      
  WHERE order_no  = @order_no      
  AND  order_ext = @order_ext      
        AND  location = @location      
  GROUP BY location      
    
  SELECT @avg_avail = @avg_avail + SUM(qty_available) FROM #CFParts    
  SELECT @avg_order = @avg_order + SUM(qty_required) FROM #CFParts    
    
  SELECT @temp_fill_pct  = 100 * AVG(@avg_avail) / AVG(@avg_order)      
       
  IF @temp_fill_pct IS NULL SELECT @temp_fill_pct = 0      
      
  SELECT @cur_fill_pct_for_order = CAST (@temp_fill_pct AS decimal (20,2))      
    
  UPDATE #so_alloc_management    
  SET  cf = 'Y'    
  WHERE order_no  = @order_no      
  AND  order_ext = @order_ext        
    
  DROP TABLE #CFParts    
 END    
       
  ------------------------------------------------------------------------------------------------------------------      
  --  If either flag is on requiring a top-level part list for kits,      --      
  --              Build a temp table containing the required information      --      
  ------------------------------------------------------------------------------------------------------------------      
  IF @calc_shippable_dollars_flg = 1 OR @calc_margin_flg = 1      
  BEGIN      
   TRUNCATE TABLE #top_level_parts      
       
   INSERT INTO #top_level_parts(line_no, part_no, qty_alloc, qty_avail)      
   SELECT a.line_no, a.part_no, a.qty_alloc, a.qty_avail       
     FROM #so_allocation_detail_view a,       
          ord_list b (NOLOCK)      
    WHERE a.order_no  = b.order_no        
      AND a.order_ext = b.order_ext        
      AND a.location  = b.location        
      AND a.line_no   = b.line_no      
      AND a.order_no  = @order_no      
      AND a.order_ext = @order_ext      
      AND a.location  = @location      
      AND b.part_type = 'P'      
   UNION      
   SELECT b.line_no, b.part_no, FLOOR(a.qty_alloc / c.qty_per), FLOOR(a.qty_avail / c.qty_per)      
     FROM #so_allocation_detail_view a,       
          ord_list b (NOLOCK),       
          ord_list_kit c(NOLOCK)      
    WHERE a.order_no  = b.order_no        
      AND a.order_ext = b.order_ext        
      AND a.location  = b.location        
      AND a.line_no   = b.line_no      
      AND a.order_no  = c.order_no      
      AND a.order_ext = c.order_ext      
      AND a.location  = c.location      
      AND a.line_no   = c.line_no      
      AND a.order_no  = @order_no      
      AND a.order_ext = @order_ext      
      AND a.location  = @location      
      AND b.part_type = 'C'      
  END      
       
  ------------------------------------------------------------------------------------------------------------------      
  --  Calculate Ordered Dollars         --      
  ------------------------------------------------------------------------------------------------------------------      
  IF @cal_ordered_dollars_flg = 1      
  BEGIN        
   SELECT @calc_ordered_dollars = ISNULL(( SELECT SUM((ordered * price) -       
           ((ordered * price) * discount / 100))      
                            FROM ord_list (NOLOCK)      
                          WHERE order_no  = @order_no      
                       AND order_ext = @order_ext      
                       AND location  = @location), 0)      
          
  END      
  ELSE      
   SELECT @calc_ordered_dollars = NULL      
       
  ------------------------------------------------------------------------------------------------------------------      
  --  Calculate Margin Percent         --      
  --              The calculation is (total price (including discount) - cost) / total price    --      
  ------------------------------------------------------------------------------------------------------------------      
       
  IF @calc_margin_flg = 1      
  BEGIN      
   SELECT @total_price = 0      
          SELECT @total_price = ISNULL(( SELECT SUM(((qty_alloc + qty_avail) * price) -       
               (((qty_alloc + qty_avail) * price) * (discount / 100)))      
                FROM ord_list a (NOLOCK), #top_level_parts t      
                  WHERE a.order_no  = @order_no      
                 AND a.order_ext = @order_ext      
                 AND a.location  = @location      
                 AND a.line_no   = t.line_no), 0)      
       
       
   SELECT @total_cost = NULL      
   SELECT @total_cost = SUM((i.std_cost + i.std_direct_dolrs + i.std_ovhd_dolrs + i.std_util_dolrs) * (qty_avail + t.qty_alloc)) --ordered)      
    FROM inventory i(NOLOCK), #top_level_parts t      
   WHERE i.location   = @location      
     AND i.part_no    = t.part_no       
     AND i.inv_cost_method = 'S'      
       
   IF @total_cost IS NULL      
   BEGIN      
    SELECT @total_cost = ISNULL(( SELECT SUM((i.avg_cost + i.avg_direct_dolrs + i.avg_ovhd_dolrs + i.avg_util_dolrs) * (qty_avail + t.qty_alloc)) --ordered)      
          FROM inventory i(NOLOCK),       
               #top_level_parts t      
         WHERE i.location         = @location      
           AND i.part_no          = t.part_no       
           AND i.inv_cost_method != 'S'), 0)      
   END      
       
   IF @total_price > 0       
    SET @shippable_margin_dollars = (((@total_price - @total_cost) / @total_price) * 100)      
   ELSE      
    SELECT @shippable_margin_dollars = 0      
  END      
  ELSE        
   SELECT @shippable_margin_dollars = NULL      
       
  ------------------------------------------------------------------------------------------------------------------      
  --  Calculate Shippable Dollars         --      
  ------------------------------------------------------------------------------------------------------------------      
       
  -- Create logic to calculate the total shippable dollar amount at the order/ext/location level        
  IF @calc_shippable_dollars_flg = 1      
  BEGIN        
   SELECT @calc_shippable_dollars = ISNULL((SELECT SUM(((qty_alloc + a.qty_avail) * b.price) -       
                                                      (((qty_alloc + a.qty_avail) * b.price) * b.discount / 100))      
                FROM ord_list b (NOLOCK),      
         #top_level_parts a      
              WHERE b.order_no  = @order_no       
                  AND b.order_ext = @order_ext      
 AND a.line_no   = b.line_no      
                  AND b.location  = @location      
                  AND a.part_no   = b.part_no ), 0)      
  END      
  ELSE      
   SELECT @calc_shippable_dollars = NULL      
       
       
  ------------------------------------------------------------------------------------------------------------------      
  --  Get distribution process type         --      
  ------------------------------------------------------------------------------------------------------------------       
  SET @alloc_type = NULL      
  SELECT @alloc_type = CASE alloc_type                              
                                 WHEN 'PR' THEN 'Pre-Pack'                 
                                 WHEN 'PT' THEN 'Console Pick'             
                                 WHEN 'PP' THEN 'Pick/Pack'                
                                 WHEN 'PB' THEN 'Package Builder'          
     ELSE NULL      
                              END           
    FROM tdc_cons_ords (NOLOCK)      
          WHERE order_no  = @order_no       
     AND order_ext = @order_ext      
     AND location  = @location       
        
  ------------------------------------------------------------------------------------------------------------------      
  --  Do Update           --      
  ------------------------------------------------------------------------------------------------------------------       
  UPDATE #so_alloc_management      
     SET curr_fill_pct     = CASE WHEN @cur_fill_pct_for_order > 100      
               THEN 100      
             WHEN @cur_fill_pct_for_order <= 0      
               THEN 0      
             ELSE @cur_fill_pct_for_order            
        END,      
         curr_alloc_pct    = CASE WHEN @alloc_pct_for_order > 100      
             THEN 100      
             ELSE @alloc_pct_for_order               END,       
         ordered_dollars   = CAST(CAST(ROUND(@calc_ordered_dollars,2)     AS DECIMAL(20,2)) AS VARCHAR(20)) + ' ' + @currency,      
         shippable_margin_dollars = @shippable_margin_dollars,      
         shippable_dollars = CAST(CAST(ROUND(@calc_shippable_dollars,2)   AS DECIMAL(20,2)) AS VARCHAR(20)) + ' ' + @currency,      
         alloc_type  = @alloc_type      
          WHERE order_no     = @order_no       
     AND order_ext    = @order_ext      
     AND location     = @location       
    
    
    
 -- v11.2 Start    
 -- v1.2 Start    
-- EXEC dbo.cvo_hold_rel_date_allocations_sp @order_no, @order_ext -- moved to tdc_plw_so_save    
 -- v1.2 End    
    
 -- v1.3 Start    
-- EXEC dbo.cvo_hold_ship_complete_allocations_sp @order_no, @order_ext -- moved to tdc_plw_so_save    
 -- v1.3 End    
    
    
 SET @last_row_id = @row_id    
    
 SELECT TOP 1 @row_id = row_id,    
   @order_no = order_no,     
   @order_ext =order_ext,     
   @location = location,    
   @currency = currency    
 FROM #tdc_selected_detail_cursor    
 WHERE row_id > @last_row_id    
       
 -------------------------------------------------------------------------------------------------------------------------------      
       
--  FETCH NEXT FROM selected_detail_cursor INTO @order_no, @order_ext, @location, @currency      
 END      
       
 --CLOSE    selected_detail_cursor      
 --DEALLOCATE selected_detail_cursor      
DROP TABLE #tdc_selected_detail_cursor    
DROP TABLE #tdc_detail_cursor    
-- v11.2 End    
       
 -------------------------------------------------------------------------------------------------------------------------------      
       
 -- Remove all records from #so_alloc_management with fill percentages below what was passed-in by the VB app       
 IF @pct_filter > 0      
  DELETE FROM #so_alloc_management WHERE curr_fill_pct <  @pct_filter      
       
 TRUNCATE TABLE #so_pre_allocation_table      
 TRUNCATE TABLE #top_level_parts      
END    
    
    
--BEGIN SED003 -- Case Part    
--JVM 04/05/2010    
--include new colums (from_line_no,is_case,is_pattern,is_polarized)     
-- UPDATE  d     
-- SET   d.qty_to_alloc =  0    
--   ,d.from_line_no = ol.from_line_no    
--   ,d.type_code    = inv.type_code    
-- FROM #so_allocation_detail_view  d, cvo_ord_list ol (NOLOCK), inv_master inv (NOLOCK) -- v1.6    
-- WHERE d.part_no   = inv.part_no   AND    
--   d.order_no = ol.order_no AND     
--   d.order_ext = ol.order_ext AND     
--   d.line_no = ol.line_no    
--     
-- UPDATE #so_allocation_detail_view     
-- SET  order_by_frame =     
--   CASE     
--    WHEN from_line_no = 0 THEN line_no    
--   ELSE    
--    from_line_no    
--   END    
 /*IF OBJECT_ID('tempdb..#so_alloc_management_Header') IS NOT NULL DROP TABLE #so_alloc_management_Header    
 IF OBJECT_ID('tempdb..#so_allocation_detail_view_Detail') IS NOT NULL DROP TABLE #so_allocation_detail_view_Detail*/      
    
 --backup Non-Quantity Bearing from to exclude them from process qty to alloc    
 IF OBJECT_ID('tempdb..#so_non_quantity_bearing') IS NOT NULL DROP TABLE #so_non_quantity_bearing    
 SELECT d.* INTO #so_non_quantity_bearing FROM   ord_list ol (NOLOCK),  #so_allocation_detail_view d -- v1.6    
            WHERE  ol.order_no = d.order_no AND     
                ol.order_ext = d.order_ext AND    
                ol.location  = d.location AND    
                ol.line_no = d.line_no  AND    
                ol.part_type = 'V'    
 DELETE d    
 FROM   ord_list ol (NOLOCK),  #so_allocation_detail_view d -- v1.6    
 WHERE  ol.order_no = d.order_no AND     
     ol.order_ext = d.order_ext AND    
     ol.location  = d.location AND    
     ol.line_no = d.line_no  AND    
     ol.part_type = 'V'    
     
     
 TRUNCATE TABLE #so_alloc_management_Header    
 TRUNCATE TABLE #so_allocation_detail_view_Detail    
    
 INSERT INTO #so_alloc_management_Header       SELECT * FROM #so_alloc_management      
 INSERT INTO #so_allocation_detail_view_Detail SELECT * FROM #so_allocation_detail_view        
     
-- UPDATE a    
-- SET  qty_to_alloc = b.qty_avail    
-- FROM CVO_qty_to_alloc_tbl a    
-- JOIN #so_allocation_detail_view b    
-- ON  a.order_no = b.order_no    
-- AND  a.order_ext = b.order_ext    
-- AND  a.line_no = b.line_no    
    
    
-- IF OBJECT_ID('tempdb..##Header2') IS NOT NULL DROP TABLE ##Header2     
-- IF OBJECT_ID('tempdb..##Detail2') IS NOT NULL DROP TABLE ##Detail2     
-- IF OBJECT_ID('tempdb..##Detail3') IS NOT NULL DROP TABLE ##Detail3     
-- SELECT * INTO ##Header2 FROM #so_alloc_management      
-- SELECT * INTO ##Detail2 FROM #so_allocation_detail_view    
-- SELECT * INTO ##Detail3 FROM #so_allocation_detail_view_Detail    
    
    
 EXEC CVO_Calculate_qty_to_alloc_sp -- works with #so_alloc_management_Header & #so_allocation_detail_view_Detail temp tables    
    
    
 IF EXISTS(SELECT * FROM tdc_user_filter_set (NOLOCK) WHERE userid = @user_id AND frame_case_match = 1 )    
  EXEC CVO_frame_case_match_sp      
    
 --return Non-Quantity Bearing to detail table    
 INSERT INTO #so_allocation_detail_view SELECT * FROM #so_non_quantity_bearing    
    
 --BEGIN SED007 -- Promo Kit    
 --JVM 07/23/2010    
  EXEC CVO_validate_promo_kits_sp 0, 0    
 --END   SED007 -- Promo Kit    
    
 -- v1.5    
-- v10.3    
-- v10.8 Start    
-- v11.2 EXEC dbo.CVO_Consolidate_Pick_queue_sp -- moved to tdc_plw_so_save    
    
    
--IF OBJECT_ID('dbo.cbtemp') IS NULL    
-- SELECT * INTO dbo.cbtemp FROM #so_allocation_detail_view    
    
 --debug tables    
-- IF OBJECT_ID('tempdb..##Header2') IS NOT NULL DROP TABLE ##Header2     
-- IF OBJECT_ID('tempdb..##Detail2') IS NOT NULL DROP TABLE ##Detail2     
-- SELECT * INTO ##Header2 FROM #so_alloc_management      
-- SELECT * INTO ##Detail2 FROM #so_allocation_detail_view    
--END   SED003 -- Case Part    
        
    
--DELETE tdc_cons_filter_set WHERE consolidation_no NOT IN (SELECT consolidation_no FROM tdc_cons_ords (NOLOCK))      
      
--DELETE tdc_main WHERE consolidation_no NOT IN (SELECT consolidation_no  FROM tdc_cons_ords (NOLOCK))      
RETURN 
GO
GRANT EXECUTE ON  [dbo].[tdc_plw_so_alloc_management_sp] TO [public]
GO
