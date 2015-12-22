SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 25/07/2012 - Add ship complete hold to transfer
-- v1.1 CB 07/10/2013 - Issue #1389 - Available qty needs to function the same as sales orders
  
CREATE PROCEDURE [dbo].[tdc_plw_xfer_alloc_management_sp]   
 @where_clause1   varchar(255),   
 @where_clause2   varchar(255),   
 @where_clause3   varchar(255),   
 @where_clause4   varchar(255),   
 @order_by_clause varchar(255),  
 @pct_filter   decimal(15,2),  
 @user_id  varchar(50)  
AS  
  
DECLARE @insert_clause  varchar (255),  
 @select_clause   varchar (255),  
 @from_clause   varchar (255),  
 @where_clause   varchar (255),  
 @groupby_clause  varchar (255),  
 @declare_clause  varchar (255)  
  
DECLARE @xfer_no   int,  
 @to_loc   varchar(10),  
 @from_loc   varchar(10),  
 @part_no  varchar(30),  
 @line_no      int,  
 @lb_tracking  char(1)   
  
DECLARE @qty_in_stock   decimal(20,8),  
 @qty_ordered_for_part_line_no decimal(24,8),  
 @qty_alloc_for_part_total decimal(20,8),   
 @qty_alloc_for_part_line_no decimal(20,8),  
 @qty_avail_for_part_total decimal(20,8),  
 @qty_avail_for_part_line_no decimal(24,8),  
 @qty_pre_allocated_total   decimal(20,8),  
 @qty_pre_alloc_for_part_on_xfer decimal(20,8),  
 @qty_picked_for_part_line_no decimal(24,8),  
 @qty_needed_for_part_line_no  decimal(24,8)  
  
DECLARE @alloc_pct_for_xfer  decimal(24,8),  
 @alloc_pct_for_part_line_no decimal(24,8),  
 @cur_fill_pct_for_xfer  decimal(24,8),  
 @avail_pct_for_part_line_no  decimal(24,8)  
  
-- v1.1 Start
DECLARE @non_alloc decimal(20,8),
		@sa_alloc decimal(20,8),
		@non_alloc_alloc decimal(20,8)
-- v1.1 End
  
TRUNCATE TABLE #xfer_allocation_detail_view  
TRUNCATE TABLE #xfer_alloc_management  
TRUNCATE TABLE #xfer_pre_allocation_table  
  
------------------------------------------------------------------------------------------------------------------------------------  
  
-- First we get all the data we can get for the #xfer_alloc_management table.  
-- Later we'll update the the feilds that have to be calculated  
  
SELECT @insert_clause   = 'INSERT INTO #xfer_alloc_management  
      (sel_flg, sel_flg2, prev_alloc_pct, curr_alloc_pct, curr_fill_pct,   
            xfer_no, to_loc, from_loc, status, sch_ship_date, carrier_code) '  
SELECT @select_clause   = 'SELECT 0, 0, 0, 0, 0, xfer_list.xfer_no, xfer_list.to_loc, xfer_list.from_loc,    
      xfers.status, xfers.sch_ship_date, xfers.routing '  
SELECT @from_clause = '  FROM xfers (NOLOCK), xfer_list(NOLOCK)'  
SELECT @where_clause = ' WHERE xfers.xfer_no  = xfer_list.xfer_no   
         AND xfers.from_loc = xfer_list.from_loc   
         AND xfers.to_loc   = xfer_list.to_loc '  
SELECT @groupby_clause = ' GROUP BY xfer_list.xfer_no, xfer_list.to_loc, xfer_list.from_loc,    
         xfers.status, xfers.sch_ship_date, xfers.routing '  
  
--  INSERT INTO #xfer_alloc_management  
EXEC (@insert_clause + ' ' +  
      @select_clause + ' ' +  
      @from_clause   + ' ' +  
      @where_clause  + ' ' +   
      @where_clause1 +    
      @where_clause2 +   
      @where_clause3 +    
      @where_clause4 + ' ' +  
      @groupby_clause)  
  
  
IF EXISTS (SELECT *  
      FROM tdc_part_filter_tbl(NOLOCK)   
     WHERE alloc_filter = 'N'  
       AND userid = @user_id   
       AND order_type = 'T')    
BEGIN  
 DELETE FROM #xfer_alloc_management   
 WHERE xfer_no NOT IN (SELECT xfer_no   
    FROM xfer_list(NOLOCK)  
          WHERE part_no IN (SELECT part_no   
                FROM tdc_part_filter_tbl(NOLOCK)   
                   WHERE alloc_filter = 'N'  
       AND userid = @user_id    
        AND order_type = 'T'  
        AND location IN (SELECT location  
                FROM tdc_part_filter_tbl b(NOLOCK)          
              WHERE alloc_filter = 'N'  
             AND part_no = b.part_no  
                  AND userid = @user_id    
                  AND order_type = 'T'))   
             AND from_loc IN (SELECT location    
                FROM tdc_part_filter_tbl(NOLOCK)   
                  WHERE alloc_filter = 'N'  
        AND userid = @user_id    
               AND order_type = 'T'  
               AND part_no IN (SELECT part_no  
             FROM tdc_part_filter_tbl b(NOLOCK)  
           WHERE alloc_filter = 'N'  
             AND location = b.location  
               AND userid = @user_id    
               AND order_type = 'T')))  
END  
  
-- Update previously allocated percentage field  
UPDATE #xfer_alloc_management  
   SET prev_alloc_pct = fill_pct  
  FROM tdc_alloc_history_tbl a (NOLOCK),  
       #xfer_alloc_management b  
 WHERE a.order_no = b.xfer_no  
   AND a.order_ext = 0  
   AND a.location = b.from_loc   
   AND a.order_type = 'T'  
  

-- v1.0 Start
CREATE TABLE #excluded_bins (bin_no varchar(20))
CREATE INDEX #ind0 ON #excluded_bins(bin_no)

INSERT #excluded_bins SELECT bins FROM dbo.f_get_excluded_bins(3)
-- v1.0 End

------------------------------------------------------------------------------------------------------------------------------------  
  
-- Now we'll loop through the Work Orders and populate the #xfer_allocation_detail_view,  
-- and calculate all the data we need for the #xfer_alloc_management table  
  
----------------------------------------------------------------------------------------------------------  
-- selected_detail_cursor declaration is being executed as a string so the order by clause that is sent by  --  
-- the VB app can be applied this process is important in that it will determine what orders get rights --  
-- to the inventory first.                                                                              --  
----------------------------------------------------------------------------------------------------------  
SELECT @declare_clause = 'DECLARE selected_detail_cursor CURSOR FOR SELECT xfer_no, from_loc, to_loc FROM #xfer_alloc_management '  
  
EXEC (@declare_clause + @order_by_clause)   
  
OPEN selected_detail_cursor  
FETCH NEXT FROM selected_detail_cursor INTO @xfer_no, @from_loc, @to_loc  
  
WHILE (@@FETCH_STATUS = 0)  
BEGIN  
  
------------------------------------------------------------------------------------------------------------------------------------  
 -- Now we'll get all the data we can get for the #xfer_allocation_detail_view table.  
 -- Later we'll update the the feilds that have to be calculated.  
 INSERT INTO #xfer_allocation_detail_view (xfer_no, from_loc, to_loc, line_no, part_no, part_desc, lb_tracking,   
      qty_ordered, qty_avail, qty_picked, qty_alloc, avail_pct, alloc_pct)  
 SELECT xfer_no, from_loc, to_loc, line_no, part_no, [description], lb_tracking, ordered * conv_factor, 0, shipped * conv_factor, 0, 0, 0  
   FROM xfer_list (NOLOCK)  
  WHERE xfer_no  = @xfer_no  
    AND from_loc = @from_loc  
    AND to_loc = @to_loc  
  
  
 DECLARE detail_cursor CURSOR FOR   
  SELECT part_no, line_no, qty_ordered, qty_picked, lb_tracking   
    FROM #xfer_allocation_detail_view   
   WHERE xfer_no  = @xfer_no  
     AND from_loc = @from_loc  
     AND to_loc = @to_loc  
   ORDER BY line_no  
   
 OPEN detail_cursor   
   
 SELECT @qty_ordered_for_part_line_no = 0   
 FETCH NEXT FROM detail_cursor INTO @part_no, @line_no, @qty_ordered_for_part_line_no, @qty_picked_for_part_line_no, @lb_tracking  
   
 WHILE (@@FETCH_STATUS = 0)  
 BEGIN  
  
  ------------------------------------------------------------------------------------------------------------------  
  --  Get allocated qty and qty to be allocated for the part / line_no    --  
  ------------------------------------------------------------------------------------------------------------------  
  
  --  Get allocated qty for the part_no/line_no on the order remove any reference to cross dock bins         
  SELECT @qty_alloc_for_part_line_no = 0  
  SELECT @qty_alloc_for_part_line_no = SUM(qty)  
    FROM tdc_soft_alloc_tbl (NOLOCK)  
   WHERE order_no   = @xfer_no  
     AND order_ext  = 0  
        AND order_type = 'T'  
     AND location   = @from_loc  
     AND line_no    = @line_no  
     AND part_no    = @part_no  
     AND ((lot_ser != 'CDOCK' AND bin_no != 'CDOCK') OR (lot_ser IS NULL AND bin_no IS NULL))          
   GROUP BY location  
  
  ------------------------------------------------------------------------------------------------------------------  
  --  Get qty that is needed for the part_no/line_no on the order     --  
  ------------------------------------------------------------------------------------------------------------------  
  SELECT @qty_needed_for_part_line_no = 0  
  SELECT @qty_needed_for_part_line_no = @qty_ordered_for_part_line_no   -   
            @qty_picked_for_part_line_no - @qty_alloc_for_part_line_no  
  
  
  --------------------------------------------------------------------------------------------------------------------------  
  
  -- Get In Stock qty for the part_no from all the BINs except the receipt BINs  
  SELECT @qty_in_stock = 0  
  IF @lb_tracking = 'N'   
  BEGIN  
   SELECT @qty_in_stock = in_stock FROM inventory (NOLOCK) WHERE part_no = @part_no AND location = @from_loc  
   SELECT @qty_in_stock = ISNULL(@qty_in_stock, 0) -   
   ISNULL((SELECT SUM(pick_qty - used_qty)   
       FROM tdc_wo_pick (NOLOCK)  
      WHERE part_no = @part_no   
        AND location = @from_loc), 0)  
  
  END  
  ELSE     
  BEGIN  

   SELECT @qty_in_stock = SUM(qty)   
              FROM lot_bin_stock a (NOLOCK), tdc_bin_master b (NOLOCK)   
                  WHERE a.location = @from_loc   
      AND a.part_no  = @part_no                   
         AND a.bin_no   = b.bin_no   
         AND a.location = b.location   
         AND b.usage_type_code IN ('OPEN', 'REPLENISH')  
         AND a.bin_no NOT IN (SELECT bin_no FROM #excluded_bins) -- v1.0 #excluded_bins
           GROUP BY a.part_no  
  


  END  
  
  
  --  Get allocated qty for the part_no for all the orders. Remove any reference to cross dock BINs.         
  SELECT @qty_alloc_for_part_total  = 0  
  SELECT @qty_alloc_for_part_total  = SUM(qty)  
    FROM tdc_soft_alloc_tbl (NOLOCK)  
   WHERE location   = @from_loc  
     AND part_no    = @part_no  
     AND ((lot_ser != 'CDOCK' AND bin_no != 'CDOCK') OR (lot_ser IS NULL AND bin_no IS NULL))          
   GROUP BY location  
  
  -- v1.1 Start

  -- Remove non allocatable stock
  SELECT	@non_alloc = SUM(a.qty) - ISNULL(SUM(b.qty),0.0),
			@non_alloc_alloc = ISNULL(SUM(b.qty),0.0)
  FROM	cvo_lot_bin_stock_exclusions a (NOLOCK)
  LEFT JOIN (SELECT SUM(qty) qty, location, part_no, bin_no FROM tdc_soft_alloc_tbl (NOLOCK) GROUP BY location, part_no, bin_no) b 
  ON		a.location = b.location
  AND		a.part_no = b.part_no
  AND		a.bin_no = b.bin_no
  WHERE	a.location = @from_loc  
  AND		a.part_no = @part_no  

  -- Remove soft alloc stock
  SELECT @sa_alloc = ISNULL(SUM(CASE WHEN a.deleted = 1 THEN (a.quantity * -1) ELSE a.quantity END),0)  
  FROM dbo.cvo_soft_alloc_det a (NOLOCK)  
  WHERE a.status IN (0, 1, -1)  
  AND  a.location = @from_loc 
  AND  a.part_no = @part_no  

  SET @qty_in_stock = @qty_in_stock - (ISNULL(@non_alloc,0.0) + ISNULL(@sa_alloc,0.0))
  -- v1.1 End

  -- Get pre-allocated qty for the part on all the Work Orders  
  SELECT @qty_pre_allocated_total   = 0  
  SELECT @qty_pre_allocated_total   = SUM(pre_allocated_qty)  
    FROM #xfer_pre_allocation_table   
   WHERE part_no  = @part_no  
     AND from_loc = @from_loc  
   GROUP BY from_loc  
  

  ------------------------------------------------------------------------------------------------------------------  
  --  Calculate total available qty for the part        --  
  ------------------------------------------------------------------------------------------------------------------  
  SELECT @qty_avail_for_part_total = 0  
  SELECT @qty_avail_for_part_total = @qty_in_stock - @qty_alloc_for_part_total - @qty_pre_allocated_total    
  

  -- Get pre-allocated qty for the part on the current order  
  SELECT @qty_pre_alloc_for_part_on_xfer = 0  
  SELECT @qty_pre_alloc_for_part_on_xfer = SUM(pre_allocated_qty)  
    FROM #xfer_pre_allocation_table   
   WHERE xfer_no  = @xfer_no  
     AND from_loc = @from_loc  
     AND to_loc   = @to_loc  
     AND part_no  = @part_no  
   GROUP BY from_loc  
  

  ------------------------------------------------------------------------------------------------------------------  
  --  Calculate available qty for the part / line_no on the order     --  
  ------------------------------------------------------------------------------------------------------------------  
  SELECT @qty_avail_for_part_line_no = 0  
  
  IF @qty_avail_for_part_total < @qty_needed_for_part_line_no  
   SELECT @qty_avail_for_part_line_no = @qty_avail_for_part_total  
  ELSE  
   SELECT @qty_avail_for_part_line_no = @qty_needed_for_part_line_no  
  
 
  ------------------------------------------------------------------------------------------------------------------  
  --  Calculate current allocated % for the part_no / line_no on the order    --  
  ------------------------------------------------------------------------------------------------------------------  
  SELECT @alloc_pct_for_part_line_no = 0  
  SELECT @alloc_pct_for_part_line_no = 100 * (@qty_alloc_for_part_line_no + @qty_picked_for_part_line_no)  
           / @qty_ordered_for_part_line_no   
  
  ------------------------------------------------------------------------------------------------------------------  
  --  Calculate currently available % for the part_no/line_no on the order    --  
  ------------------------------------------------------------------------------------------------------------------  
  SELECT @avail_pct_for_part_line_no = 0  
  IF @qty_avail_for_part_line_no > 0   
   SELECT @avail_pct_for_part_line_no = 100 * @qty_avail_for_part_line_no / @qty_needed_for_part_line_no   
  ELSE  
   SELECT @avail_pct_for_part_line_no = @alloc_pct_for_part_line_no  
  
  
  ------------------------------------------------------------------------------------------------------------------  
  --  Make final update to the #xfer_allocation_detail_view table     --  
  ------------------------------------------------------------------------------------------------------------------  
  UPDATE #xfer_allocation_detail_view  
     SET qty_avail  = CASE WHEN @qty_avail_for_part_line_no < 0   
      THEN 0  
      ELSE @qty_avail_for_part_line_no  
        END,  
         qty_picked = @qty_picked_for_part_line_no,  
         qty_alloc  = @qty_alloc_for_part_line_no,  
         avail_pct  = CASE WHEN @avail_pct_for_part_line_no > 100  
                                         THEN 100  
      WHEN @avail_pct_for_part_line_no < 0  
                                         THEN 0  
             ELSE @avail_pct_for_part_line_no  
        END,  
         alloc_pct  = CASE WHEN @alloc_pct_for_part_line_no > 100  
                                         THEN 100  
             ELSE @alloc_pct_for_part_line_no  
        END  
   WHERE xfer_no    = @xfer_no   
     AND from_loc   = @from_loc  
     AND to_loc     = @to_loc  
     AND part_no    = @part_no  
     AND line_no   = @line_no  
   
-------------------------------------------------------------------------------------------------------------------------------  
  
  INSERT INTO #xfer_pre_allocation_table (xfer_no, from_loc, to_loc, part_no, line_no, pre_allocated_qty)  
  VALUES(@xfer_no, @from_loc, @to_loc, @part_no, @line_no, @qty_avail_for_part_line_no)  
  
  FETCH NEXT FROM detail_cursor INTO @part_no, @line_no, @qty_ordered_for_part_line_no, @qty_picked_for_part_line_no, @lb_tracking  
 END  
   
 CLOSE      detail_cursor   
 DEALLOCATE detail_cursor   
  
-------------------------------------------------------------------------------------------------------------------------------  
 ------------------------------------------------------------------------------------------------------------------  
 --  Calculate current fill percentage for the order       --  
 ------------------------------------------------------------------------------------------------------------------  
 SELECT @cur_fill_pct_for_xfer = 0  
 SELECT @cur_fill_pct_for_xfer = 100 * AVG(qty_avail + qty_picked + qty_alloc) / AVG(qty_ordered)  
          FROM #xfer_allocation_detail_view  
  WHERE xfer_no  = @xfer_no  
           AND from_loc = @from_loc  
    AND to_loc   = @to_loc  
  GROUP BY from_loc  
  
 ------------------------------------------------------------------------------------------------------------------  
 --  Calculate current allocated percentage for the order      --  
 ------------------------------------------------------------------------------------------------------------------  
 SELECT @alloc_pct_for_xfer = 0  
 SELECT @alloc_pct_for_xfer = 100 * AVG(qty_alloc + qty_picked) / AVG(qty_ordered)  
          FROM #xfer_allocation_detail_view  
  WHERE xfer_no  = @xfer_no  
           AND from_loc = @from_loc  
    AND to_loc   = @to_loc  
  GROUP BY from_loc  
  
 UPDATE #xfer_alloc_management  
    SET curr_fill_pct  = CASE WHEN @cur_fill_pct_for_xfer > 100  
          THEN 100  
         WHEN @cur_fill_pct_for_xfer < 0  
          THEN 0  
         ELSE @cur_fill_pct_for_xfer  
     END,  
         curr_alloc_pct = CASE WHEN @alloc_pct_for_xfer > 100  
          THEN 100  
          ELSE @alloc_pct_for_xfer  
     END  
         WHERE xfer_no    = @xfer_no   
    AND from_loc   = @from_loc   
    AND to_loc     = @to_loc   
  
-------------------------------------------------------------------------------------------------------------------------------  
  
 FETCH NEXT FROM selected_detail_cursor INTO @xfer_no, @from_loc, @to_loc  
END  
  
CLOSE    selected_detail_cursor  
DEALLOCATE selected_detail_cursor  
  
-------------------------------------------------------------------------------------------------------------------------------  
  
   
-- Remove all records from #xfer_alloc_management with fill percentages below what was passed-in by the VB app   
DELETE FROM #xfer_alloc_management WHERE curr_fill_pct <  @pct_filter  
  
TRUNCATE TABLE #xfer_pre_allocation_table  
  
RETURN  
GO
GRANT EXECUTE ON  [dbo].[tdc_plw_xfer_alloc_management_sp] TO [public]
GO
