SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_plw_wo_print_selection_sp] 	
		@in_where_clause1  varchar(255), 
		@in_where_clause2  varchar(255), 
		@in_where_clause3  varchar(255),
		@in_where_clause4  varchar(255)
AS

DECLARE @select_clause 		varchar(255),
	@groupby_clause 	varchar(255),
	@from_clause 		varchar(255),
	@insert_into_clause 	varchar(255),
	@generic_where_clause 	varchar(255)

DECLARE @cur_alloc_pct		decimal(20,2),
	@qty_used 		decimal(24,8),
	@qty_alloc 		decimal(24,8),
	@qty_picked		decimal(24,8),
	@qty_plan 		decimal(24,8)

DECLARE @prod_no 		int,
	@prod_ext		int,
	@location		varchar(10)

TRUNCATE TABLE #plw_wo_print_sel

SELECT @insert_into_clause   = 'INSERT INTO #plw_wo_print_sel 
				       (prod_no, prod_ext, status, location, sch_date, staging_area, shift, curr_alloc_pct, sel_flg)'
SELECT @select_clause        = 'SELECT prod_no, prod_ext, status, a.location , sch_date, staging_area, shift, 0, 0            					'
SELECT @from_clause          = '  FROM produce a (NOLOCK), tdc_soft_alloc_tbl b (NOLOCK)'
SELECT @generic_where_clause = ' WHERE a.prod_no  = b.order_no
			       	   AND a.prod_ext = b.order_ext 
				   AND order_type = ''W''
				   AND a.location = b.location '
SELECT @groupby_clause       = ' GROUP BY prod_no, prod_ext, status, a.location, sch_date, staging_area, shift'	


EXEC (@insert_into_clause   + 
      @select_clause        + 
      @from_clause          + 
      @generic_where_clause +  
      @in_where_clause1     + @in_where_clause2 + @in_where_clause3 + @in_where_clause4 + 
      @groupby_clause)


--------------------------------------------------
-- Calculate currently allocated %		--
--------------------------------------------------
DECLARE selected_orders_cursor CURSOR FOR 
	SELECT prod_no, prod_ext, location FROM #plw_wo_print_sel 

OPEN selected_orders_cursor
FETCH NEXT FROM selected_orders_cursor INTO @prod_no, @prod_ext, @location

WHILE (@@FETCH_STATUS = 0)
BEGIN
	-- Get planned and used qty for all the raw materials on the order.
	SELECT @qty_plan = 0, @qty_used = 0
	SELECT @qty_plan = SUM(plan_qty * conv_factor),
	       @qty_used = SUM(used_qty * conv_factor)
	  FROM prod_list (NOLOCK)
	 WHERE prod_no  = @prod_no
	   AND prod_ext = @prod_ext
	   AND line_no  > 1
	   AND location = @location
	   AND part_type IN ('M','P')
 	 GROUP BY location

	-- Get allocated qty for all the parts on the order.
	SELECT @qty_alloc = 0
	SELECT @qty_alloc = SUM(qty)
	  FROM tdc_soft_alloc_tbl (NOLOCK)
	 WHERE order_no   = @prod_no
	   AND order_ext  = @prod_ext
   	   AND order_type = 'W'
	   AND location   = @location
	   AND ((lot_ser != 'CDOCK' AND bin_no != 'CDOCK') OR (lot_ser IS NULL AND bin_no IS NULL))								
 	 GROUP BY location

	-- Get picked qty for all the parts on the order.
	SELECT @qty_picked = 0
	SELECT @qty_picked = SUM(pick_qty) 
	  FROM tdc_wo_pick (NOLOCK)
	 WHERE prod_no  = @prod_no
	   AND prod_ext = @prod_ext
	   AND location = @location
	 GROUP BY location

	SELECT @cur_alloc_pct = 0

	IF ISNULL(@qty_plan, 0) = 0
		SELECT @cur_alloc_pct = 100
	ELSE
		SELECT @cur_alloc_pct = 100 * (@qty_used + @qty_alloc + @qty_picked)/ @qty_plan 
		
	UPDATE #plw_wo_print_sel
	   SET curr_alloc_pct = @cur_alloc_pct
	 WHERE prod_no  = @prod_no
	   AND prod_ext = @prod_ext
	   AND location = @location

	FETCH NEXT FROM selected_orders_cursor INTO @prod_no, @prod_ext, @location
END

CLOSE 	   selected_orders_cursor
DEALLOCATE selected_orders_cursor

RETURN
GO
GRANT EXECUTE ON  [dbo].[tdc_plw_wo_print_selection_sp] TO [public]
GO
