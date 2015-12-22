SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v1.1 CT 31/07/2012 - Issue 733: Exclude transfers with pick records on SC-Hold
-- v1.2 CT 15/03/2013 - Exclude transfers which are autopack or autoship

CREATE PROCEDURE [dbo].[tdc_plw_xfer_print_selection_sp] 	
		@in_where_clause1  varchar(255), 
		@in_where_clause2  varchar(255), 
		@in_where_clause3  varchar(255),
		@in_where_clause4  varchar(255)
AS

DECLARE @select_clause 		varchar(255),
	@groupby_clause 	varchar(255),
	@from_clause 		varchar(255),
	@insert_into_clause 	varchar(255),
	-- START v1.2
	@generic_where_clause  varchar(1000) 
	--@generic_where_clause 	varchar(255)
	-- END v1.2

DECLARE @cur_alloc_pct		decimal(20,2),
	@qty_ordered 		decimal(24,8),
	@qty_alloc 		decimal(24,8),
	@qty_picked		decimal(24,8)

DECLARE @xfer_no 		int,
	@from_loc		varchar(10),
	@to_loc			varchar(10)

TRUNCATE TABLE #pick_ticket_details

SELECT @insert_into_clause   = 'INSERT INTO #pick_ticket_details 
				       (xfer_no, status, from_loc, to_loc, sch_ship_date, curr_alloc_pct, sel_flg)'
SELECT @select_clause        = 'SELECT xfer_no, status, from_loc, to_loc, sch_ship_date, 0, 0'
SELECT @from_clause          = '  FROM xfers (NOLOCK), tdc_soft_alloc_tbl (NOLOCK)'
SELECT @generic_where_clause = ' WHERE xfer_no  = order_no
				   AND from_loc = location
				   AND order_type = ''T'''
-- START v1.1
SELECT @generic_where_clause = @generic_where_clause + ' AND xfer_no NOT IN (SELECT trans_type_no FROM dbo.tdc_pick_queue (NOLOCK) WHERE mfg_batch = ''SHIP_COMP'' 
															AND tx_lock = ''H'' AND trans = ''XFERPICK'')'
-- END v1.1

-- START v1.2  
SELECT @generic_where_clause = @generic_where_clause + ' AND ISNULL(autopack,0) = 0 AND ISNULL(autoship,0) = 0'
-- END v1.2

SELECT @groupby_clause       = ' GROUP BY xfer_no, status, from_loc, to_loc, sch_ship_date'	

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
	SELECT xfer_no, from_loc FROM #pick_ticket_details 

OPEN selected_orders_cursor
FETCH NEXT FROM selected_orders_cursor INTO @xfer_no, @from_loc

WHILE (@@FETCH_STATUS = 0)
BEGIN
	-- Get ordered and shipped qty
	SELECT @qty_ordered = 0, @qty_picked = 0 
	SELECT @qty_ordered = SUM(ordered * conv_factor),
	       @qty_picked  = SUM(shipped * conv_factor)
	  FROM xfer_list (NOLOCK)
	 WHERE xfer_no  = @xfer_no
	   AND from_loc = @from_loc
 	 GROUP BY from_loc

	-- Get allocated qty for all the parts on the order.
	SELECT @qty_alloc = 0
	SELECT @qty_alloc = SUM(qty)
	  FROM tdc_soft_alloc_tbl (NOLOCK)
	 WHERE order_no   = @xfer_no
	   AND order_ext  = 0
   	   AND order_type = 'T'
	   AND location   = @from_loc
	   AND ((lot_ser != 'CDOCK' AND bin_no != 'CDOCK') OR (lot_ser IS NULL AND bin_no IS NULL))								
 	 GROUP BY location

	-- Calculate the currently allocated %
	SELECT @cur_alloc_pct = 0
	SELECT @cur_alloc_pct = 100 * (@qty_alloc + @qty_picked)/ @qty_ordered 
		
	UPDATE #pick_ticket_details
	   SET curr_alloc_pct = @cur_alloc_pct
	 WHERE xfer_no  = @xfer_no
	   AND from_loc = @from_loc

	FETCH NEXT FROM selected_orders_cursor INTO @xfer_no, @from_loc
END

CLOSE 	   selected_orders_cursor
DEALLOCATE selected_orders_cursor

RETURN
GO
GRANT EXECUTE ON  [dbo].[tdc_plw_xfer_print_selection_sp] TO [public]
GO
