SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

--exec [CVO_unallocate_cases_sp] 167, 0

CREATE PROCEDURE [dbo].[CVO_unallocate_patterns_sp] @order_no INT, @ext INT AS
BEGIN
	IF (object_id('tempdb..#so_alloc_management')       IS NOT NULL) 
		DROP TABLE #so_alloc_management

	IF OBJECT_ID('tempdb..#so_soft_alloc_byline_tbl')   IS NOT NULL 
		DROP TABLE #so_soft_alloc_byline_tbl

	CREATE TABLE #so_alloc_management (                                                         
		sel_flg						INT NOT NULL,      
		sel_flg2					INT NOT NULL,
		prev_alloc_pct				DECIMAL(24,8) NOT NULL,      
		curr_alloc_pct				DECIMAL(24,8) NOT NULL,      
		curr_fill_pct				DECIMAL(24,8) NOT NULL,      
		order_no					INT NOT NULL,      
		order_ext					INT NOT NULL,
		location					VARCHAR(10) NOT NULL,      
		order_status				CHAR(1) NOT NULL,
		sch_ship_date				DATETIME NOT NULL,
		consolidation_no			INT NULL,      
		cust_type					VARCHAR(40) NULL,      
		cust_type2					VARCHAR(40) NULL,
		cust_type3					VARCHAR(40) NULL,      
		cust_name					VARCHAR(40) NULL,      
		cust_flg					CHAR(1) NULL,      
		cust_code					VARCHAR(10) NOT NULL, 
		territory_code				VARCHAR(10) NULL,      
		carrier_code				VARCHAR(20) NULL,      
		dest_zone_code				VARCHAR(8) NULL,
		ordered_dollars				VARCHAR(20) NULL,      
		shippable_dollars			VARCHAR(20) NULL,
		shippable_margin_dollars	VARCHAR(20) NULL,
		ship_to						VARCHAR(40) NULL,      
		postal_code					VARCHAR(10) NULL, 
		so_priority_code			INT NULL,      
		alloc_type					VARCHAR(20) NULL,      
		user_code					VARCHAR(8)  NOT NULL,      
		user_category				VARCHAR(10) NULL,
		load_no						INT NULL,      
		cust_po						VARCHAR(20) NULL)

		CREATE TABLE #so_soft_alloc_byline_tbl(
			order_no    int         NOT NULL,
			order_ext   int         NOT NULL,           
			line_no     int         NOT NULL,
			part_no     varchar(30) NOT NULL )
		 
		INSERT INTO #so_alloc_management
				(	sel_flg,					sel_flg2,			prev_alloc_pct,		curr_alloc_pct,
					curr_fill_pct,				order_no,			order_ext,			location,
					order_status,				sch_ship_date,		consolidation_no,	cust_type, 
					cust_type2,					cust_type3,			cust_name,			cust_flg, 
					cust_code,					territory_code,		carrier_code,		dest_zone_code, 
					ship_to,					so_priority_code,	ordered_dollars,	shippable_dollars,
					shippable_margin_dollars, 	alloc_type,			user_code,			user_category, 
					load_no,					cust_po,			postal_code )   
				SELECT 
					DISTINCT 0 AS sel_flg,		1 AS sel_flg2,      prev_alloc_pct = ISNULL((SELECT MAX(fill_pct)
																							   FROM tdc_alloc_history_tbl  (NOLOCK) 
					  	  																	  WHERE order_no = ord_list.order_no
						   																		AND order_ext = ord_list.order_ext
						   																		AND location = ord_list.location 
						   																		AND order_type = 'S'), 0),
					0 AS curr_alloc_pct,		0 AS curr_fill_pct,	ord_list.order_no,	ord_list.order_ext, 
					ord_list.location,			orders.status,		orders.sch_ship_date,    
					consolidation_no = ISNULL((SELECT consolidation_no
					               				FROM tdc_cons_ords (NOLOCK)
					              				WHERE tdc_cons_ords.order_no = ord_list.order_no  
												AND tdc_cons_ords.order_ext = ord_list.order_ext
												AND tdc_cons_ords.location = ord_list.location
												AND tdc_cons_ords.order_type = 'S'), 0),

												armaster.addr_sort1,		armaster.addr_sort2,					
					armaster.addr_sort3,        armaster.address_name,		orders.back_ord_flag,
					orders.cust_code,	        orders.ship_to_region,		orders.routing,
					orders.dest_zone_code,      orders.ship_to_name,		orders.so_priority_code,				
					NULL,						NULL,						NULL,									
					NULL,						orders.user_code,			orders.user_category,					
					load_no = (SELECT DISTINCT load_no FROM load_list(NOLOCK) WHERE order_no = orders.order_no AND order_ext = orders.ext),
												orders.cust_po,				orders.ship_to_zip      
				FROM	orders (NOLOCK), 
						ord_list(NOLOCK), 
						armaster(NOLOCK),
						tdc_order(NOLOCK)   
				WHERE	orders.order_no     = ord_list.order_no 
						AND orders.ext          = ord_list.order_ext 
						AND orders.cust_code    = armaster.customer_code
						AND orders.cust_code    = armaster.customer_code
						AND orders.ship_to      = armaster.ship_to_code
						AND (ord_list.create_po_flag <> 1 OR ord_list.create_po_flag IS NULL)
						AND tdc_order.order_no  = orders.order_no
						AND tdc_order.order_ext = orders.ext
						AND armaster.address_type = (SELECT MAX(address_type) 
						            FROM armaster (NOLOCK) 
						    	   WHERE customer_code = orders.cust_code 
						     	     AND ship_to_code  = orders.ship_to)   
						AND orders.order_no = @order_no 
						AND orders.ext = @ext

		INSERT #so_soft_alloc_byline_tbl (order_no, order_ext, line_no, part_no)
		SELECT	l.order_no,	l.order_ext, l.line_no, l.part_no
		FROM	ord_list l (NOLOCK)
			INNER JOIN CVO_ord_list c (NOLOCK) ON l.order_no = c.order_no AND l.order_ext = c.order_ext AND l.line_no = c.line_no
		WHERE l.order_no = @order_no AND l.order_ext = @ext AND c.is_pattern = '1'

		
		BEGIN TRAN
			EXEC tdc_plw_so_unallocate_sp 'manager', 1 
		COMMIT TRAN

		SELECT 0, 'OK'
END
GO
GRANT EXECUTE ON  [dbo].[CVO_unallocate_patterns_sp] TO [public]
GO
