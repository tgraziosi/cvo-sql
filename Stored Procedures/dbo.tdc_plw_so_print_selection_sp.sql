SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 12/14/2010 - Exclude orders where there are kits (promo and standard) but no frames available
-- v1.1 CB 04/04/2011 - 6.Consolidation
-- v1.2 CB 12/04/2011 - 68668-U52658ENT - Future Allocations and Promo ID
-- v1.3 CB 05/03/2012 - Fix the hiding of pick tickets when order has kits or promos
-- v1.4 CT 20/06/2012 - Print pick tickets for orders on credit hold
-- v1.5 CT 08/05/2013 - Issue #1259 - Allow print of pick ticket if order only contains custom frames 
-- v1.6 CT 19/02/2015 - When checking for orders with kits/promos where frames are not available, don't include fully picked order lines
-- v1.7 CB 14/04/2016 - #1596 - Add promo level
-- v1.8 CB 15/11/2017 - Fix issue with temp table

CREATE PROCEDURE [dbo].[tdc_plw_so_print_selection_sp]    
 @con_no     int,  
 @in_where_clause1  varchar(255),   
 @in_where_clause2  varchar(255),   
 @in_where_clause3  varchar(255),  
 @in_where_clause4  varchar(255)  
AS  
  
DECLARE @test varchar(4000),  
 @user_id varchar(50)  
  
DECLARE @insert_into_clause  varchar(500),  
 @select_clause_B2B  varchar(500),  
 @from_clause_B2B    varchar(500),  
 @union_clause   varchar(10),   
 @from_clause_stdpick   varchar(4000),  
 @from_clause_one4one  varchar(2000),  
 @select_clause_stdpick  varchar(2000)  
  
DECLARE @cur_alloc_pct  decimal(20,2),  
 @qty_ordered   decimal(24,8),  
 @qty_alloc   decimal(24,8),  
 @qty_picked  decimal(24,8)  
  
DECLARE @order_no   int,  
  @order_ext  int,  
  @location  varchar(10),  
  @template_code varchar(50)  
  
DECLARE @total_allocated_pct    decimal(20,2),  
 @total_number_orders int  

DECLARE @DEF_RES_TYPE_PROMO_KITS varchar(25) -- v1.0

	-- v1.0
SELECT	@DEF_RES_TYPE_PROMO_KITS = ISNULL((SELECT value_str FROM tdc_config (nolock)  
			WHERE [function] = 'DEF_RES_TYPE_PROMO_KITS' AND active = 'Y'), 'FRAME')

  
--SCR#318838 By Jim On 10/04/07  
SELECT @template_code = ISNULL(cust_name, '') FROM #so_pick_ticket_details  
TRUNCATE TABLE #so_pick_ticket_details  

-- v1.1 Add new columns to insert statement  
-- v1.2  Add new column to insert statement  
SELECT @insert_into_clause    = 'INSERT INTO #so_pick_ticket_details   
            (order_no, order_ext, con_no, status, location, sch_ship_date, cust_name, curr_alloc_pct, sel_flg, alloc_type, cust_code, consolidate_shipment, promo_id, promo_level)'  -- v1.7

-- v1.1 Add new columns to select statement    
-- v1.2  Add new column to insert statement      
SELECT @select_clause_B2B     = 'SELECT DISTINCT NULL, NULL, trans_type_no, '''', '''', NULL, NULL, 0, 0, NULL, NULL, 0, '''', '''' ' -- v1.7              
               
SELECT @from_clause_B2B       = '  FROM tdc_pick_queue (NOLOCK)  
                                  WHERE trans_type_no = ' + CAST (@con_no AS varchar(10)) +   
                                '   AND trans        IN (''PLWB2B'', ''MGTB2B'')  
                                    AND tx_lock      IN (''R'', ''P'', ''3'') '  
  
SELECT @union_clause          = ' UNION '  

-- v1.1 Add new columns to select statement  
-- v1.5 Removed '-- SCR #35108' comment from WHERE clause
SELECT @select_clause_stdpick = 'SELECT DISTINCT  
                   trans_type_no, trans_type_ext, consolidation_no, orders.status,  
                                         tdc_pick_queue.location, orders.sch_ship_date, orders.ship_to_name, 0, 0,   
      alloc_type = (SELECT top 1 alloc_type   
        FROM tdc_cons_ords   
              WHERE order_no  = tdc_pick_queue.trans_type_no  
         AND order_ext = tdc_pick_queue.trans_type_ext   
         AND location  = tdc_pick_queue.location), orders.cust_code, 0, isnull(cvo.promo_id, ''''), isnull(cvo.promo_level, '''') '  -- v1.7
 
-- v1.2  Add new column to from clause
-- v1.4  Added logic to deal with tx_lock status for orders on credit hold
-- v1.5	 Added join to cvo_ord_list to allow priniting of orders which only contain custom frames
SELECT @from_clause_stdpick   = ' FROM tdc_pick_queue(NOLOCK), tdc_cons_ords (NOLOCK), orders (NOLOCK), armaster(NOLOCK), cvo_orders_all cvo(NOLOCK), cvo_ord_list (NOLOCK)                                       
                                 WHERE tdc_pick_queue.trans_type_no   = tdc_cons_ords.order_no  
                                   AND tdc_pick_queue.trans_type_ext  = tdc_cons_ords.order_ext  
       AND tdc_pick_queue.trans          IN (''STDPICK'', ''PKGBLD'')  
       AND ((tdc_pick_queue.tx_lock        IN (''R'',  ''G'', ''3'')) OR (orders.status = ''C'' AND tdc_pick_queue.tx_lock IN (''R'',  ''G'', ''3'', ''E'')) OR ( tdc_pick_queue.tx_lock = ''H'' AND cvo_ord_list.is_customized = ''S''))
       AND tdc_cons_ords.order_no       = orders.order_no                                         
       AND tdc_cons_ords.order_ext       = orders.ext  
       AND tdc_cons_ords.consolidation_no = ' + CAST (@con_no AS varchar(10)) +   
    '  AND orders.cust_code               = armaster.customer_code  
       AND orders.ship_to                 = armaster.ship_to_code  
		AND orders.order_no = cvo.order_no
		AND orders.ext = cvo.ext
		AND tdc_pick_queue.trans_type_no       = cvo_ord_list.order_no                                                    
		AND tdc_pick_queue.trans_type_ext       = cvo_ord_list.order_ext
		AND tdc_pick_queue.line_no       = cvo_ord_list.line_no
       AND armaster.address_type          = (SELECT MAX(address_type)   
                          FROM armaster (NOLOCK)   
                  WHERE customer_code = orders.cust_code   
                    AND ship_to_code  = orders.ship_to) '
                    
--BEGIN SED009 -- Pick Ticket Printing 
--JVM 08/23/2010  
/*SELECT @from_clause_stdpick   = ' FROM tdc_pick_queue(NOLOCK), tdc_cons_ords (NOLOCK), orders (NOLOCK), armaster(NOLOCK)                                       
                                 WHERE tdc_pick_queue.trans_type_no   = tdc_cons_ords.order_no  
                                   AND tdc_pick_queue.trans_type_ext  = tdc_cons_ords.order_ext  
       AND tdc_pick_queue.trans          IN (''STDPICK'', ''PKGBLD'')  
       AND tdc_pick_queue.tx_lock        IN (''R'',  ''G'', ''3'')             
       AND tdc_cons_ords.order_no       = orders.order_no                                         
       AND tdc_cons_ords.order_ext       = orders.ext  
       AND tdc_cons_ords.consolidation_no = ' + CAST (@con_no AS varchar(10)) +   
    '  AND orders.cust_code               = armaster.customer_code  
       AND orders.ship_to                 = armaster.ship_to_code  
       AND armaster.address_type          = (SELECT MAX(address_type)   
                          FROM armaster (NOLOCK)   
                  WHERE customer_code = orders.cust_code   
                    AND ship_to_code  = orders.ship_to) '
                    
SELECT @from_clause_one4one  = '  FROM tdc_pick_queue (NOLOCK), tdc_cons_ords (NOLOCK), orders (NOLOCK), armaster (NOLOCK)  
      WHERE tdc_pick_queue.trans   IN (''STDPICK'', ''PKGBLD'')  
       AND tdc_pick_queue.tx_lock IN (''R'', ''G'', ''3'')    
       AND tdc_pick_queue.trans_type_no  = tdc_cons_ords.order_no  
       AND tdc_pick_queue.trans_type_ext = tdc_cons_ords.order_ext  
       AND orders.order_no               = tdc_cons_ords.order_no  
       AND orders.ext                    = tdc_cons_ords.order_ext  
       AND tdc_pick_queue.trans_type_no IN (  
        SELECT order_no   
                          FROM tdc_cons_ords   
                                            WHERE consolidation_no IN (  
         SELECT consolidation_no  
                                  FROM tdc_cons_ords (NOLOCK)  
                  GROUP BY consolidation_no   
                                            HAVING COUNT(order_no) = 1))  
       AND orders.cust_code               = armaster.customer_code  
       AND orders.ship_to                 = armaster.ship_to_code  
       AND armaster.address_type          = (SELECT MAX(address_type)   
                          FROM armaster (NOLOCK)   
                  WHERE customer_code = orders.cust_code   
                    AND ship_to_code  = orders.ship_to) '*/

-- v1.2  Add new column to from clause
-- v1.4  Added logic to deal with tx_lock status for orders on credit hold
-- v1.5	 Added join to cvo_ord_list to allow priniting of orders which only contain custom frames
SELECT @from_clause_stdpick   = ' FROM tdc_pick_queue(NOLOCK), tdc_cons_ords (NOLOCK), orders (NOLOCK), armaster(NOLOCK), CVO_armaster_all (NOLOCK), cvo_orders_all cvo(NOLOCK), cvo_ord_list (NOLOCK)                                         
                                 WHERE tdc_pick_queue.trans_type_no   = tdc_cons_ords.order_no  
                                   AND tdc_pick_queue.trans_type_ext  = tdc_cons_ords.order_ext  
       AND tdc_pick_queue.trans          IN (''STDPICK'', ''PKGBLD'')  
	   AND ((tdc_pick_queue.tx_lock        IN (''R'',  ''G'', ''3'')) OR (orders.status = ''C'' AND tdc_pick_queue.tx_lock IN (''R'',  ''G'', ''3'', ''E'')) OR ( tdc_pick_queue.tx_lock = ''H'' AND cvo_ord_list.is_customized = ''S''))
       AND tdc_cons_ords.order_no       = orders.order_no                                         
       AND tdc_cons_ords.order_ext       = orders.ext  
       AND tdc_cons_ords.consolidation_no = ' + CAST (@con_no AS varchar(10)) +   
    '  AND orders.cust_code               = armaster.customer_code  
       AND orders.ship_to                 = armaster.ship_to_code  
		AND orders.order_no = cvo.order_no
		AND orders.ext = cvo.ext
		AND tdc_pick_queue.trans_type_no       = cvo_ord_list.order_no                                                    
		AND tdc_pick_queue.trans_type_ext       = cvo_ord_list.order_ext
		AND tdc_pick_queue.line_no       = cvo_ord_list.line_no
       AND armaster.address_type          = (SELECT MAX(address_type)   
                          FROM armaster (NOLOCK)   
                  WHERE customer_code = orders.cust_code   
                    AND ship_to_code  = orders.ship_to) '

-- v1.2  Add new column to from clause
-- v1.4  Added logic to deal with tx_lock status for orders on credit hold
-- v1.5	 Added join to cvo_ord_list to allow priniting of orders which only contain custom frames                    
SELECT @from_clause_one4one  = '  FROM tdc_pick_queue (NOLOCK), tdc_cons_ords (NOLOCK), orders (NOLOCK), armaster (NOLOCK), CVO_armaster_all (NOLOCK), cvo_orders_all cvo(NOLOCK), cvo_ord_list (NOLOCK)    
      WHERE tdc_pick_queue.trans   IN (''STDPICK'', ''PKGBLD'') 
	   AND ((tdc_pick_queue.tx_lock IN (''R'',  ''G'', ''3'')) OR (orders.status = ''C'' AND tdc_pick_queue.tx_lock IN (''R'',  ''G'', ''3'', ''E'')) OR ( tdc_pick_queue.tx_lock = ''H'' AND cvo_ord_list.is_customized = ''S'')) 
       AND tdc_pick_queue.trans_type_no  = tdc_cons_ords.order_no  
       AND tdc_pick_queue.trans_type_ext = tdc_cons_ords.order_ext  
       AND orders.order_no               = tdc_cons_ords.order_no  
       AND orders.ext                    = tdc_cons_ords.order_ext  
       AND tdc_pick_queue.trans_type_no IN (  
        SELECT order_no   
                          FROM tdc_cons_ords   
                                            WHERE consolidation_no IN (  
         SELECT consolidation_no  
                                  FROM tdc_cons_ords (NOLOCK)  
                  GROUP BY consolidation_no   
                                            HAVING COUNT(order_no) = 1))  
       AND orders.cust_code               = armaster.customer_code  
       AND orders.ship_to                 = armaster.ship_to_code  
		AND orders.order_no = cvo.order_no
		AND orders.ext = cvo.ext
		AND tdc_pick_queue.trans_type_no       = cvo_ord_list.order_no                                                    
		AND tdc_pick_queue.trans_type_ext       = cvo_ord_list.order_ext
		AND tdc_pick_queue.line_no       = cvo_ord_list.line_no
       AND armaster.address_type          = (SELECT MAX(address_type)   
                          FROM armaster (NOLOCK)   
                  WHERE customer_code = orders.cust_code   
                    AND ship_to_code  = orders.ship_to) '                      
--END   SED009 -- Pick Ticket Printing   
---------------------------------------------------  
-- Consolidation Set  
---------------------------------------------------  
IF @con_no > 0  
BEGIN  
 EXEC (@insert_into_clause    +   
       @select_clause_B2B     +   
       @from_clause_B2B       +   
       @union_clause          +    
       @select_clause_stdpick +   
       @from_clause_stdpick   +  
       @in_where_clause1      +   
       @in_where_clause2      +   
       @in_where_clause3      +  
       @in_where_clause4)  
  
 --------------------------------------------------  
 -- Calculate currently allocated % For non/PLWB2B  
 --------------------------------------------------  
 DECLARE selected_orders_cursor CURSOR FOR   
  SELECT order_no, order_ext, location   
    FROM #so_pick_ticket_details   
                 WHERE location IS NOT NULL  
   
 OPEN selected_orders_cursor  
 FETCH NEXT FROM selected_orders_cursor INTO @order_no, @order_ext, @location  
   
 WHILE (@@FETCH_STATUS = 0)  
 BEGIN  
  -- Get ordered and shipped qty  
  SELECT @qty_ordered = 0, @qty_picked = 0   
  SELECT @qty_ordered = SUM(ordered * conv_factor),  
         @qty_picked  = SUM(shipped * conv_factor)  
    FROM ord_list (NOLOCK)  
   WHERE order_no  = @order_no  
     AND order_ext = @order_ext  
     AND location  = @location  
     AND part_type = 'P'  
    GROUP BY location  
   
  SELECT @qty_ordered = ISNULL(@qty_ordered, 0) + SUM(b.ordered * b.conv_factor * b.qty_per),  
         @qty_picked  = ISNULL(@qty_picked, 0)  + SUM(b.shipped * b.conv_factor * b.qty_per)  
    FROM ord_list a (NOLOCK),  
         ord_list_kit b(NOLOCK)  
   WHERE a.order_no  = @order_no  
     AND a.order_ext = @order_ext  
     AND a.location  = @location  
     AND a.part_type = 'C'  
     AND b.order_no  = a.order_no  
     AND b.order_ext = a.order_ext  
     AND b.location  = a.location  
     AND b.line_no   = a.line_no  
    GROUP BY a.location  
   
  -- Get allocated qty for all the parts on the order.  
  SELECT @qty_alloc = 0  
  SELECT @qty_alloc = SUM(qty)  
    FROM tdc_soft_alloc_tbl (NOLOCK)  
   WHERE order_no   = @order_no  
     AND order_ext  = @order_ext  
     AND location   = @location  
        AND order_type = 'S'      
     AND ((lot_ser != 'CDOCK' AND bin_no != 'CDOCK') OR (lot_ser IS NULL AND bin_no IS NULL))          
    GROUP BY location  
   
   
  -- Calculate the currently allocated %  
  SELECT @cur_alloc_pct = 0  
  IF @qty_ordered <> 0  
  BEGIN  
   SELECT @cur_alloc_pct = 100 * (ISNULL(@qty_alloc,0) + ISNULL(@qty_picked,0))/ @qty_ordered   
  END  
   
  UPDATE #so_pick_ticket_details  
     SET curr_alloc_pct = @cur_alloc_pct  
   WHERE order_no  = @order_no  
     AND order_ext = @order_ext  
     AND location  = @location  
   
  FETCH NEXT FROM selected_orders_cursor INTO @order_no, @order_ext, @location  
 END  
   
 CLOSE     selected_orders_cursor  
 DEALLOCATE selected_orders_cursor  
  
 --------------------------------------------------  
 -- Calculate currently allocated % For non/PLWB2B  
 --------------------------------------------------  
 DECLARE selected_orders_cursor CURSOR FOR   
  SELECT a.order_no, a.order_ext, a.location   
    FROM tdc_soft_alloc_tbl a (NOLOCK),  
         tdc_cons_ords      b (NOLOCK)  
   WHERE a.order_no = b.order_no  
     AND a.order_ext = b.order_ext  
     AND a.location = b.location  
     AND a.target_bin != a.bin_no  
     AND a.bin_no IS NOT NULL  
     AND b.consolidation_no = @con_no   
  
 OPEN selected_orders_cursor  
 FETCH NEXT FROM selected_orders_cursor INTO @order_no, @order_ext, @location  
   
 WHILE (@@FETCH_STATUS = 0)  
 BEGIN  
  
  -- Get ordered and shipped qty  
  SELECT @qty_ordered = 0, @qty_picked = 0   
  SELECT @qty_ordered = SUM(ordered * conv_factor),  
         @qty_picked  = SUM(shipped * conv_factor)  
    FROM ord_list (NOLOCK)  
   WHERE order_no  = @order_no  
     AND order_ext = @order_ext  
     AND location  = @location  
     AND part_type = 'P'  
    GROUP BY location  
   
  SELECT @qty_ordered = ISNULL(@qty_ordered, 0) + SUM(b.ordered * b.conv_factor * b.qty_per),  
         @qty_picked  = ISNULL(@qty_picked, 0)  + SUM(b.shipped * b.conv_factor * b.qty_per)  
    FROM ord_list a (NOLOCK),  
         ord_list_kit b(NOLOCK)  
   WHERE a.order_no  = @order_no  
     AND a.order_ext = @order_ext  
     AND a.location  = @location  
     AND a.part_type = 'C'  
     AND b.order_no  = a.order_no  
     AND b.order_ext = a.order_ext  
     AND b.location  = a.location  
     AND b.line_no   = a.line_no  
    GROUP BY a.location  
   
  -- Get allocated qty for all the parts on the order.  
  SELECT @qty_alloc = 0  
  SELECT @qty_alloc = SUM(qty)  
    FROM tdc_soft_alloc_tbl (NOLOCK)  
   WHERE order_no   = @order_no  
     AND order_ext  = @order_ext  
     AND location   = @location  
        AND order_type = 'S'      
     AND (lot_ser != 'CDOCK' AND bin_no != 'CDOCK')          
    GROUP BY location  
    
  -- Calculate the currently allocated %  
  SELECT @cur_alloc_pct = 0  
  IF @qty_ordered <> 0  
  BEGIN  
   SELECT @cur_alloc_pct = 100 * (ISNULL(@qty_alloc,0) + ISNULL(@qty_picked,0))/ @qty_ordered   
  END  
  
    
  SELECT @total_allocated_pct = ISNULL(@total_allocated_pct, 0) + @cur_alloc_pct,   
         @total_number_orders = ISNULL(@total_number_orders, 0) + 1  
   
  FETCH NEXT FROM selected_orders_cursor INTO @order_no, @order_ext, @location  
 END  
   
 CLOSE     selected_orders_cursor  
 DEALLOCATE selected_orders_cursor  
  
  
 ------------------------------------------------------------------------------------  
 -- Calculate average  
 ------------------------------------------------------------------------------------  
 IF ISNULL(@total_number_orders, 0) > 0  
 BEGIN  
  SELECT @cur_alloc_pct = @total_allocated_pct / @total_number_orders  
  UPDATE #so_pick_ticket_details  
     SET curr_alloc_pct = @cur_alloc_pct  
   WHERE order_no  = @con_no  
     AND ISNULL(location, '')  IS NULL  
 END    
END  
ELSE  
BEGIN  
-- One-for-One  
 EXEC (@insert_into_clause    +   
       @select_clause_stdpick +   
       @from_clause_one4one           +   
       @in_where_clause1      +   
       @in_where_clause2      +   
       @in_where_clause3      +  
       @in_where_clause4)  
  
 --------------------------------------------------  
 -- Calculate currently allocated %  --  
 --------------------------------------------------  
 DECLARE selected_orders_cursor CURSOR FOR   
  SELECT order_no, order_ext, location   
    FROM #so_pick_ticket_details WHERE location IS NOT NULL  
   
 OPEN selected_orders_cursor  
 FETCH NEXT FROM selected_orders_cursor INTO @order_no, @order_ext, @location  
   
 WHILE (@@FETCH_STATUS = 0)  
 BEGIN  
  -- Get ordered and shipped qty  
  SELECT @qty_ordered = 0, @qty_picked = 0   
  SELECT @qty_ordered = SUM(ordered * conv_factor),  
         @qty_picked  = SUM(shipped * conv_factor)  
    FROM ord_list (NOLOCK)  
   WHERE order_no  = @order_no  
     AND order_ext = @order_ext  
     AND location  = @location  
     AND part_type = 'P'  
    GROUP BY location   
   
  SELECT @qty_ordered = ISNULL(@qty_ordered, 0) + SUM(b.ordered * b.conv_factor * b.qty_per),  
         @qty_picked  = ISNULL(@qty_picked, 0)  + SUM(b.shipped * b.conv_factor * b.qty_per)  
    FROM ord_list a (NOLOCK),  
         ord_list_kit b(NOLOCK)  
   WHERE a.order_no  = @order_no  
     AND a.order_ext = @order_ext  
     AND a.location  = @location  
     AND a.part_type = 'C'  
     AND b.order_no  = a.order_no  
     AND b.order_ext = a.order_ext  
     AND b.location  = a.location  
     AND b.line_no   = a.line_no  
    GROUP BY a.location  
   
  -- Get allocated qty for all the parts on the order.  
  SELECT @qty_alloc = 0  
  SELECT @qty_alloc = SUM(qty)  
    FROM tdc_soft_alloc_tbl (NOLOCK)  
   WHERE order_no   = @order_no  
     AND order_ext  = @order_ext  
     AND location   = @location  
        AND order_type = 'S'      
     AND ((lot_ser != 'CDOCK' AND bin_no != 'CDOCK') OR (lot_ser IS NULL AND bin_no IS NULL))          
    GROUP BY location  
   
   
  -- Calculate the currently allocated %  
  SELECT @cur_alloc_pct = 0  
  IF @qty_ordered <> 0  
  BEGIN  
   SELECT @cur_alloc_pct = 100 * (ISNULL(@qty_alloc,0) + ISNULL(@qty_picked,0))/ @qty_ordered   
  END  
   
  UPDATE #so_pick_ticket_details  
     SET curr_alloc_pct = @cur_alloc_pct  
   WHERE order_no  = @order_no  
     AND order_ext = @order_ext  
     AND location  = @location  
   
  FETCH NEXT FROM selected_orders_cursor INTO @order_no, @order_ext, @location  
 END  
   
 CLOSE     selected_orders_cursor  
 DEALLOCATE selected_orders_cursor  
  
  
END  
  
--SCR#38168 By Jim On 9/28/07 Begin  
SELECT @user_id = who FROM #temp_who  
  
--Remove unwanted postal code  
IF EXISTS (SELECT * FROM tdc_postal_code_filter_tbl WHERE userid = @user_id AND order_type = 'S')  
BEGIN  
 DELETE FROM #so_pick_ticket_details  
   FROM #so_pick_ticket_details d, orders o  
  WHERE d.order_no = o.order_no  
    AND d.order_ext = o.ext  
    AND o.posting_code NOT IN (SELECT postal_code      
         FROM tdc_postal_code_filter_tbl (NOLOCK)  
         WHERE userid = @user_id   
           AND order_type = 'S')  
END  
  
--Remove unwanted carrier  
IF EXISTS (SELECT * FROM tdc_carrier_code_filter_tbl WHERE userid = @user_id AND order_type = 'S')  
BEGIN  
 DELETE FROM #so_pick_ticket_details  
   FROM #so_pick_ticket_details d, orders o  
  WHERE d.order_no = o.order_no  
    AND d.order_ext = o.ext  
    AND o.routing NOT IN (SELECT carrier_code      
          FROM tdc_carrier_code_filter_tbl (NOLOCK)  
         WHERE userid = @user_id   
           AND order_type = 'S')  
  
END  
--SCR#38168 By Jim On 9/28/07 End  
  
--Remove unwanted parts  
IF EXISTS (SELECT * FROM tdc_part_filter_tbl(NOLOCK)   
     WHERE alloc_filter = 'N'  
       AND userid = @user_id   
       AND order_type = 'S')    
BEGIN  
 DELETE FROM #so_pick_ticket_details  
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
  
--SCR#318838 By Jim On 10/04/07 Begin  
--Remove unwanted postal code  
IF EXISTS (SELECT * FROM tdc_sia_postal_code_filter_tbl WHERE userid = @user_id AND template_code = @template_code)  
BEGIN  
 DELETE FROM #so_pick_ticket_details  
   FROM #so_pick_ticket_details d, orders o  
  WHERE d.order_no = o.order_no  
    AND d.order_ext = o.ext  
    AND o.posting_code NOT IN (SELECT a.postal_code      
         FROM tdc_sia_postal_code_filter_tbl a (NOLOCK)  
           WHERE a.userid = @user_id   
          AND a.template_code = @template_code)  
END  
  
--Remove unwanted carrier  
IF EXISTS (SELECT * FROM tdc_sia_carrier_code_filter_tbl WHERE userid = @user_id AND template_code = @template_code)  
BEGIN  
 DELETE FROM #so_pick_ticket_details  
   FROM #so_pick_ticket_details d, orders o  
  WHERE d.order_no = o.order_no  
    AND d.order_ext = o.ext  
    AND o.routing NOT IN (SELECT a.carrier_code      
          FROM tdc_sia_carrier_code_filter_tbl a (NOLOCK)  
         WHERE a.userid = @user_id       
        AND a.template_code = @template_code)  
END  
  
--Remove unwanted parts  
IF EXISTS (SELECT 1  
   FROM tdc_sia_part_filter_tbl a (NOLOCK), tdc_plw_criteria_templates b (nolock)  
   WHERE a.template_code = b.template_code   
   AND a.userid = b.userid  
   AND a.userid = @user_id  
   AND a.template_code = @template_code   
   AND (b.location = 'ALL' or b.location = a.location))  
BEGIN  
 DELETE FROM #so_pick_ticket_details  
  WHERE CAST(order_no AS VARCHAR(20)) + '-' + CAST(order_ext AS VARCHAR(10)) + '-' + location    
    NOT IN (  
   SELECT CAST(order_no AS VARCHAR(20)) + '-' + CAST(order_ext AS VARCHAR(10)) + '-' + location    
     FROM ord_list ol(NOLOCK)  
    WHERE ol.part_no IN (SELECT a.part_no   
         FROM tdc_sia_part_filter_tbl a (NOLOCK), tdc_plw_criteria_templates b (nolock)  
         WHERE a.template_code = b.template_code  
         AND a.template_code = @template_code  
         AND a.userid = b.userid  
         AND a.userid = @user_id  
         AND a.location = ol.location  
         AND (a.location = b.location or b.location = 'ALL'))  
   UNION   
   SELECT CAST(order_no AS VARCHAR(20)) + '-' + CAST(order_ext AS VARCHAR(10)) + '-' + location   
     FROM ord_list_kit olk (NOLOCK)  
    WHERE olk.part_no IN (SELECT a.part_no   
         FROM tdc_sia_part_filter_tbl a (NOLOCK), tdc_plw_criteria_templates b (nolock)  
         WHERE a.template_code = b.template_code  
         AND a.template_code = @template_code  
         AND a.userid = b.userid  
         AND a.userid = @user_id  
         AND a.location = olk.location  
         AND (a.location = b.location or b.location = 'ALL'))  
  )  
    
END  
--SCR#318838 By Jim On 10/04/07 End  
  
-- v1.0 Remove orders with kits where no frames are avalable
-- v1.3 Start

-- Create working table
IF OBJECT_ID('tempdb..#orders') IS NOT NULL -- v1.8
	DROP TABLE #orders  

CREATE TABLE #orders (
		order_no	int, 
		order_ext	int, 
		is_kit		int, 
		is_promo	int,
		has_frame	int,
		frame_alloc int)

INSERT	#orders SELECT distinct order_no, order_ext, 0 , 0, 0, 0
FROM	#so_pick_ticket_details

-- Get standard kits
UPDATE	#orders
set		is_kit = 1 
FROM	#orders a
JOIN	ord_list b (NOLOCK)
ON		a.order_no = b.order_no
AND		a.order_ext = b.order_ext
WHERE	b.part_type = 'C'

-- Get the promo kits
UPDATE	#orders
set		is_promo = 1 
FROM	#orders a
JOIN	cvo_ord_list b (NOLOCK)
ON		a.order_no = b.order_no
AND		a.order_ext = b.order_ext
WHERE	b.promo_item = 'Y'

-- Check if a frame is on the order and available
UPDATE	#orders
set		has_frame = 1, frame_alloc = 1 
FROM	#orders a
JOIN	ord_list b (NOLOCK)
ON		a.order_no = b.order_no
AND		a.order_ext = b.order_ext
JOIN	tdc_soft_alloc_tbl c (NOLOCK)
ON		b.order_no = c.order_no
AND		b.order_ext = c.order_ext
AND		b.line_no = c.line_no
JOIN	inv_master d (NOLOCK)
ON		b.part_no = d.part_no
WHERE	d.type_code in (select * from fs_cParsing (@DEF_RES_TYPE_PROMO_KITS))

-- Check if a frame is on the order and not available
UPDATE	#orders
set		has_frame = 1, frame_alloc = 0 
FROM	orders a (NOLOCK)
JOIN	ord_list b (NOLOCK)
ON		a.order_no = b.order_no
AND		a.ext = b.order_ext
LEFT JOIN tdc_soft_alloc_tbl c (NOLOCK)
ON		b.order_no = c.order_no
AND		b.order_ext = c.order_ext
AND		b.line_no = c.line_no
JOIN	inv_master d (NOLOCK)
ON		b.part_no = d.part_no
JOIN	#orders e
ON		a.order_no = e.order_no
AND		a.ext = e.order_ext
WHERE	d.type_code in  (select * from fs_cParsing (@DEF_RES_TYPE_PROMO_KITS))
AND		(e.is_kit = 1 OR e.is_promo = 1)
AND		c.order_no IS NULL
AND		c.order_ext IS NULL
AND		e.frame_alloc = 0
-- START v1.6 
-- Ignore order lines which are fully picked
AND		b.ordered > b.shipped
-- END v1.6

-- Remove orders with kits where no frames are avalable
DELETE	#so_pick_ticket_details
FROM	#so_pick_ticket_details so
JOIN	#orders a (NOLOCK)
ON		so.order_no = a.order_no
AND		so.order_ext = a.order_ext
WHERE	(a.is_kit = 1 OR a.is_promo = 1)
AND		a.has_frame = 1
AND		a.frame_alloc = 0

DROP TABLE #orders
-- v1.3 End

-- v1.1 Mark records that are already set as condolidated
UPDATE	a
SET		consolidate_shipment = 1
FROM	#so_pick_ticket_details a
JOIN	dbo.cvo_consolidate_shipments b (NOLOCK)
ON		a.order_no = b.order_no
AND		a.order_ext = b.order_ext
JOIN	dbo.tdc_pick_queue c (NOLOCK)
ON		b.order_no = c.trans_type_no
AND		b.order_ext = c.trans_type_ext
WHERE	c.trans NOT IN ('XFERPICK', 'WOPPICK', 'SO-CDOCK')

RETURN  
GO
GRANT EXECUTE ON  [dbo].[tdc_plw_so_print_selection_sp] TO [public]
GO
