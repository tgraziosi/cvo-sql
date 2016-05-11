SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[cvo_process_soft_alloc_changes_sp] @order_no INT, @ext INT
AS
BEGIN

	SET NOCOUNT ON

	-- Create temporary tables
	CREATE TABLE #so_allocation_detail_view     (                                             
		order_no        INT             NOT NULL,   
		order_ext       INT             NOT NULL,   
		location        VARCHAR(10)     NOT NULL,   
		line_no         INT             NOT NULL,   
		part_no         VARCHAR(30)     NOT NULL,   
		part_desc       VARCHAR(278)        NULL,   
		lb_tracking     CHAR(1)         NOT NULL,   
		qty_ordered     DECIMAL(24, 8)  NOT NULL,   
		qty_avail       DECIMAL(24, 8)  NOT NULL,   
		qty_picked      DECIMAL(24, 8)  NOT NULL,   
		qty_alloc       DECIMAL(24, 8)  NOT NULL,   
		avail_pct       DECIMAL(24,8)   NOT NULL,   
		alloc_pct       DECIMAL(24,8)   NOT NULL,   
		qty_to_alloc    INT                 NULL,   
		type_code       VARCHAR(10)         NULL,   
		from_line_no    INT                 NULL,   
		order_by_frame  INT                 NULL  )   
	
	CREATE INDEX #so_allocation_detail_view_idx1 ON #so_allocation_detail_view                       
		(order_no, order_ext, location, part_no, line_no)  

	CREATE TABLE #so_alloc_management                       (                                                         
		sel_flg                  int             NOT NULL,      
		sel_flg2                 int             NOT NULL,      
		prev_alloc_pct           decimal(24,8)   NOT NULL,      
		curr_alloc_pct           decimal(24,8)   NOT NULL,      
		curr_fill_pct            decimal(24,8)   NOT NULL,      
		order_no                 int             NOT NULL,      
		order_ext                int             NOT NULL,      
		location                 varchar(10)     NOT NULL,      
		order_status             char(1)         NOT NULL,      
		sch_ship_date            datetime        NOT NULL,      
		consolidation_no         int                 NULL,      
		cust_type                varchar(40)         NULL,      
		cust_type2               varchar(40)         NULL,      
		cust_type3               varchar(40)         NULL,      
		cust_name                varchar(40)         NULL,      
		cust_flg                 char(1)             NULL,      
		cust_code                varchar(10)     NOT NULL,      
		territory_code           varchar(10)         NULL,      
		carrier_code             varchar(20)         NULL,      
		dest_zone_code           varchar(8)          NULL,      
		ordered_dollars          varchar(20)         NULL,      
		shippable_dollars        varchar(20)         NULL,      
		shippable_margin_dollars varchar(20)         NULL,      
		ship_to                  varchar(40)         NULL,      
		postal_code              varchar(10)         NULL,      
		so_priority_code         int                 NULL,      
		alloc_type               varchar(20)         NULL,      
		user_code                varchar(8)      NOT NULL,      
		user_category            varchar(10)         NULL,      
		load_no                  int                 NULL,      
		cust_po                  varchar(20)         NULL,      
		total_pieces             int                 NULL,      
		lowest_bin_no            varchar(12)         NULL,      
		consolidate_shipment     int                 NULL,      
		allocation_date          datetime            NULL,      
		promo_id                 varchar(20)         NULL,      
		cf                       char(1)             NULL,
		mp_consolidation_no		 int                 NULL, -- v1.1     
		promo_level				 varchar(20)		 NULL) -- v1.2

	CREATE INDEX #so_alloc_management_idx1 ON #so_alloc_management 
		(order_no, order_ext, location, sel_flg)

	CREATE TABLE #so_pre_allocation_table               (                                                     
		order_no             int             NOT NULL,      
		order_ext            int             NOT NULL,      
		location             varchar(10)     NOT NULL,      
		part_no              varchar(30)     NOT NULL,      
		line_no              int             NOT NULL,      
		pre_allocated_qty    decimal(24,8)   NOT NULL     )                                                  
	
	CREATE INDEX #so_pre_allocation_table_idx1 ON #so_pre_allocation_table                                
		(order_no, order_ext, location, part_no, pre_allocated_qty) 

	CREATE TABLE #temp_sia_working_tbl          (                                               
		order_no        int         NOT NULL,       
		order_ext       int         NOT NULL,       
		location        varchar(10) NOT NULL,       
		part_no         varchar(30) NOT NULL,       
		lb_tracking     char(1)     NOT NULL,       
		qty_ordered     int         NOT NULL,       
		qty_assigned    int         NOT NULL,       
		qty_needed      int         NOT NULL,       
		qty_to_alloc    int         NOT NULL    )   
                                        
	CREATE INDEX #temp_sia_working_tbl_idx1 on #temp_sia_working_tbl 
		(order_no, order_ext, location, part_no)
	CREATE INDEX #temp_sia_working_tbl_idx2 on #temp_sia_working_tbl 
		(qty_to_alloc)
	CREATE INDEX #temp_sia_working_tbl_idx3 on #temp_sia_working_tbl 
		(location, part_no)
	CREATE INDEX #temp_sia_working_tbl_idx4 on #temp_sia_working_tbl 
		(qty_needed)

	CREATE TABLE #top_level_parts               (                                             
		line_no         int             NOT NULL,   
		part_no         varchar(30)     NOT NULL,   
		qty_alloc       decimal(20, 8)  NOT NULL,   
		qty_avail       decimal(20, 8)  NOT NULL  )  

	CREATE INDEX #top_level_parts_ix01 ON #top_level_parts  
		(line_no, part_no, qty_alloc, qty_avail)   
	CREATE INDEX #top_level_parts_ix02 ON #top_level_parts  
		(part_no ) 

	CREATE TABLE #so_alloc_management_Header                       (                                                         
		sel_flg                  int             NOT NULL,      
		sel_flg2                 int             NOT NULL,      
		prev_alloc_pct           decimal(24,8)   NOT NULL,      
		curr_alloc_pct           decimal(24,8)   NOT NULL,      
		curr_fill_pct            decimal(24,8)   NOT NULL,      
		order_no                 int             NOT NULL,      
		order_ext                int             NOT NULL,      
		location                 varchar(10)     NOT NULL,      
		order_status             char(1)         NOT NULL,      
		sch_ship_date            datetime        NOT NULL,      
		consolidation_no         int                 NULL,      
		cust_type                varchar(40)         NULL,      
		cust_type2               varchar(40)         NULL,      
		cust_type3               varchar(40)         NULL,      
		cust_name                varchar(40)         NULL,      
		cust_flg                 char(1)             NULL,      
		cust_code                varchar(10)     NOT NULL,      
		territory_code           varchar(10)         NULL,      
		carrier_code             varchar(20)         NULL,      
		dest_zone_code           varchar(8)          NULL,      
		ordered_dollars          varchar(20)         NULL,      
		shippable_dollars        varchar(20)         NULL,      
		shippable_margin_dollars varchar(20)         NULL,      
		ship_to                  varchar(40)         NULL,      
		postal_code              varchar(10)         NULL,      
		so_priority_code         int                 NULL,      
		alloc_type               varchar(20)         NULL,      
		user_code                varchar(8)      NOT NULL,      
		user_category            varchar(10)         NULL,      
		load_no                  int                 NULL,      
		cust_po                  varchar(20)         NULL,      
		total_pieces             int                 NULL,      
		lowest_bin_no            varchar(12)         NULL,      
		consolidate_shipment     int                 NULL,      
		allocation_date          datetime            NULL,      
		promo_id                 varchar(20)         NULL,      
		cf                       char(1)             NULL,
		mp_consolidation_no		 int                 NULL, -- v1.1      
		promo_level				 varchar(20)		 NULL) -- v1.2

	CREATE TABLE #so_allocation_detail_view_Detail     (                                             
		order_no        INT             NOT NULL,   
		order_ext       INT             NOT NULL,   
		location        VARCHAR(10)     NOT NULL,   
		line_no         INT             NOT NULL,   
		part_no         VARCHAR(30)     NOT NULL,   
		part_desc       VARCHAR(278)        NULL,   
		lb_tracking     CHAR(1)         NOT NULL,   
		qty_ordered     DECIMAL(24, 8)  NOT NULL,   
		qty_avail       DECIMAL(24, 8)  NOT NULL,   
		qty_picked      DECIMAL(24, 8)  NOT NULL,   
		qty_alloc       DECIMAL(24, 8)  NOT NULL,   
		avail_pct       DECIMAL(24,8)   NOT NULL,   
		alloc_pct       DECIMAL(24,8)   NOT NULL,   
		qty_to_alloc    INT                 NULL,   
		type_code       VARCHAR(10)         NULL,   
		from_line_no    INT                 NULL,   
		order_by_frame  INT                 NULL  )   

	CREATE TABLE #so_alloc_err          (                                      
		order_no        int,                
		order_ext       int,                
		line_no         int,                
		part_no         varchar(30),        
		err_msg         varchar(255)      )
 
	CREATE TABLE #so_soft_alloc_byline_tbl      (                                              
		order_no        int         NOT NULL,       
		order_ext       int         NOT NULL,       
		line_no         int         NOT NULL,       
		part_no         varchar(30) NOT NULL,       
		from_line_no    int             NULL,       
		type_code       VARCHAR(10) NOT NULL,       
		qty_override    DECIMAL(20,8) NOT NULL DEFAULT (0) )   

	-- Populate tables
	EXEC cvo_create_allocation_temp_table_data_sp @order_no, @ext

	-- Backup change records
	SELECT order_no, order_ext, line_no, part_no, 0 from_line_no, '0' type_code, change
	INTO #change_backup
	FROM dbo.cvo_soft_alloc_det 
	WHERE order_no = @order_no
	AND order_ext = @ext
	AND change > 0
	AND deleted = 0

	-- Unallocate
	UPDATE #so_alloc_management set sel_flg = 0, sel_flg2 = -1
	DELETE FROM #so_soft_alloc_byline_tbl

	INSERT #so_soft_alloc_byline_tbl (order_no, order_ext, line_no, part_no, from_line_no, type_code )
	SELECT order_no, order_ext, line_no, part_no, 0, '0'
	FROM dbo.cvo_soft_alloc_det 
	WHERE order_no = @order_no
	AND order_ext = @ext
	AND(deleted = 1 or change > 0)
	
	EXEC CVO_Include_alloc_unalloc_byline_sp
	EXEC tdc_plw_so_save_sp 0,'', 'AUTO_ALLOC', 'ORDER BY  order_no ASC, order_ext ASC',0

	-- Update soft alloc records to allow allocation of changes
	UPDATE
		a
	SET
		change = b.change
	FROM
		cvo_soft_alloc_det a
	INNER JOIN
		#change_backup b
	ON
		a.order_no = b.order_no
		AND a.order_ext = b.order_ext
		AND a.line_no = b.line_no
		AND a.part_no = b.part_no

	-- Re-populate tables
	EXEC cvo_create_allocation_temp_table_data_sp @order_no, @ext

	-- Re-Allocate
	UPDATE #so_alloc_management set sel_flg = -1, sel_flg2 = 0
	DELETE FROM #so_soft_alloc_byline_tbl

	INSERT #so_soft_alloc_byline_tbl (order_no, order_ext, line_no, part_no, from_line_no, type_code )
	SELECT order_no, order_ext, line_no, part_no, 0, '0'
	FROM dbo.cvo_soft_alloc_det 
	WHERE order_no = @order_no
	AND order_ext = @ext
	AND change > 0 	

	EXEC CVO_Include_alloc_unalloc_byline_sp

	--EXEC tdc_plw_so_allocate_selected_lines 'manager', '[Adhoc]', 0
	EXEC tdc_plw_so_allocate_selected_lines 'AUTO_ALLOC', 'AUTO_ALLOC', 0

END 
GO
GRANT EXECUTE ON  [dbo].[cvo_process_soft_alloc_changes_sp] TO [public]
GO
