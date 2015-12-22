SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[tdc_auto_alloc_get_fill_pct_sp]
	@order_no int,
	@order_ext int,
	@location varchar(10) 
AS

DECLARE @ret int,
	@where_clause varchar(255)

	-----------------------------------------------------------------------------------------------------------------------
	-- Create the necessary temp tables
	-----------------------------------------------------------------------------------------------------------------------
	IF OBJECT_ID('tempdb..#temp_sia_working_tbl') IS NOT NULL DROP TABLE #temp_sia_working_tbl
	 
	CREATE TABLE #temp_sia_working_tbl
	(
		order_no 	int		NOT NULL,
		order_ext 	int		NOT NULL,
		location	varchar(10)	NOT NULL,
		part_no		varchar(30)	NOT NULL,	
		lb_tracking	char(1)		NOT NULL,
		qty_ordered	int		NOT NULL,
		qty_assigned	int		NOT NULL,
		qty_needed	int		NOT NULL,
		qty_to_alloc	int		NOT NULL
	)
	
	CREATE INDEX #temp_sia_working_tbl_idx1 on #temp_sia_working_tbl (order_no, order_ext, location, part_no)
	
	CREATE INDEX #temp_sia_working_tbl_idx2 on #temp_sia_working_tbl (qty_to_alloc)
	
	CREATE INDEX #temp_sia_working_tbl_idx3 on #temp_sia_working_tbl (location, part_no)
	
	CREATE INDEX #temp_sia_working_tbl_idx4 on #temp_sia_working_tbl (qty_needed)
	
	
	IF (object_id('tempdb..#so_alloc_management')	    IS NOT NULL) DROP TABLE #so_alloc_management 
	IF (object_id('tempdb..#so_allocation_detail_view') IS NOT NULL) DROP TABLE #so_allocation_detail_view 
	IF (object_id('tempdb..#so_pre_allocation_table')   IS NOT NULL) DROP TABLE #so_pre_allocation_table 
	
	
	-- For the PLW SO allocation management grid
	CREATE TABLE #so_alloc_management
	(              
		sel_flg             		int             NOT NULL, 
		sel_flg2            		int             NOT NULL, 
		prev_alloc_pct      		decimal(5,2)    NOT NULL, 
		curr_alloc_pct      		decimal(5,2)    NOT NULL, 
		curr_fill_pct       		decimal(5,2)    NOT NULL, 
		order_no            		int             NOT NULL, 
		order_ext           		int             NOT NULL, 
		location            		varchar(10)     NOT NULL, 
		order_status           		char(1)         NOT NULL, 
		sch_ship_date  	    		datetime        NOT NULL, 
		consolidation_no		int		    NULL,	
		cust_type 			varchar(40)	    NULL,
		cust_type2 			varchar(40) 	    NULL,
		cust_type3 			varchar(40) 	    NULL,
		cust_name 			varchar(40) 	    NULL,
		cust_flg 			char(1) 	    NULL,	
		cust_code 			varchar(10) 	NOT NULL,
		territory_code 			varchar(10) 	    NULL,
		carrier_code 			varchar(20) 	    NULL,
		dest_zone_code 			varchar(8) 	    NULL,
		ordered_dollars 		varchar(20)   	    NULL,
		shippable_dollars 		varchar(20)   	    NULL,
		shippable_margin_dollars 	varchar(20)   	    NULL,
		ship_to 			varchar(40) 	    NULL,
		so_priority_code		int 		    NULL,
		user_code 			varchar(8) 	NOT NULL,
		user_catery 			varchar(10) 	    NULL,
		alloc_type			varchar(20)	    NULL,
		user_category            	varchar(10)         NULL,   
		load_no				int		    NULL,
		cust_po                  varchar(20)         NULL,	-- SCR 34450
		postal_code              	varchar(10)         NULL --SCR 36323 TR 03-17-06
	) 
	
	CREATE INDEX #so_alloc_management_idx1
	ON #so_alloc_management (order_no, order_ext, location) 
	
	
	-- For the PLW SO detail grid
	CREATE TABLE #so_allocation_detail_view
	( 
		order_no       	int             NOT NULL, 
		order_ext       int     	NOT NULL, 
		location        varchar(10)     NOT NULL, 
		line_no		int		NOT NULL,
		part_no     	varchar(30)     NOT NULL,
		part_desc	varchar(278)	    NULL,
		lb_tracking	char(1)         NOT NULL,
		qty_ordered    	decimal(24, 8)  NOT NULL,
		qty_avail   	decimal(24, 8)  NOT NULL,
		qty_picked   	decimal(24, 8)  NOT NULL,
		qty_alloc   	decimal(24, 8)  NOT NULL,
		avail_pct   	decimal(5, 2)   NOT NULL,
		alloc_pct   	decimal(5, 2)   NOT NULL
	)  
	
	CREATE INDEX #so_allocation_detail_view_idx1
	ON #so_allocation_detail_view (order_no, order_ext, location, part_no, line_no) 
	
	
	-- This is a temporary table used only for this SP. 
	CREATE TABLE #so_pre_allocation_table 
	(
		order_no               	int             NOT NULL, 
		order_ext  		int		NOT NULL,
		location		varchar(10)	NOT NULL, 
		part_no			varchar(30)	NOT NULL, 
		line_no			int		NOT NULL,
		pre_allocated_qty	decimal(24,8)   NOT NULL
	)
	
	
	CREATE INDEX #so_pre_allocation_table_idx1
	ON #so_pre_allocation_table (order_no, order_ext, location, part_no, pre_allocated_qty) 
	
	
	IF OBJECT_ID('tempdb..#top_level_parts') IS NOT NULL DROP TABLE #top_level_parts
	
	CREATE TABLE #top_level_parts
	(
		line_no			int		NOT NULL,
		part_no 		varchar(30) 	NOT NULL,
		qty_alloc 		decimal(20, 8) 	NOT NULL,
		qty_avail 		decimal(20, 8) 	NOT NULL
	)
	
	CREATE INDEX #top_level_parts_ix01                              
	ON #top_level_parts  (line_no, part_no, qty_alloc, qty_avail)   
	
	    
	CREATE INDEX #top_level_parts_ix02                             
	ON #top_level_parts  (part_no )   

		
	-----------------------------------------------------------------------------------------------------------------------
	-- Call ship fill stored procedure passing criteria for only this order.
	-----------------------------------------------------------------------------------------------------------------------
	SELECT @where_clause = ' AND orders.order_no = ' + CAST(@order_no AS VARCHAR) + ' AND orders.ext = ' + CAST(@order_ext AS VARCHAR)

	EXEC tdc_plw_so_alloc_management_sp '', 
		'Default', 
		@where_clause, 
		'', 
		'', 
		'', 
		'', 
		0, 
		0,
		0,
		'ALL', 
		'auto_alloc'


	SELECT @ret = 0
	SELECT @ret = curr_fill_pct
	  FROM #so_alloc_management
	 WHERE order_no = @order_no
	   AND order_ext = @order_ext
	   AND location = @location

	RETURN @ret

GO
GRANT EXECUTE ON  [dbo].[tdc_auto_alloc_get_fill_pct_sp] TO [public]
GO
