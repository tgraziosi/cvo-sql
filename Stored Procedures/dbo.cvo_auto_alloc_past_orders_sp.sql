SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v1.0 CT 24/03/2014 - Issue #1459 - Automate the allocation of past orders
-- v1.1 CB 14/08/2015 - Add missing mp_consolidation_no column
-- v1.2 CB 14/04/2016 - #1596 - Add promo level
-- EXEC dbo.cvo_auto_alloc_past_orders_sp 'ZZ'

CREATE PROC [dbo].[cvo_auto_alloc_past_orders_sp] @order_type	VARCHAR(2) = 'ZZ'
AS
BEGIN

	SET NOCOUNT ON

	DECLARE @where_clause		VARCHAR(2000),
			@alloc_order		SMALLINT,
			@template			VARCHAR(255),
			@today				VARCHAR(8),
			@yesterday			VARCHAR(8),
			@oldest				VARCHAR(8),
			@date_entered		DATETIME,
			@in_where_clause1	VARCHAR(255),
			@in_where_clause2	VARCHAR(255),
			@in_where_clause3	VARCHAR(255),
			@in_where_clause4	VARCHAR(255),
			@char				CHAR(1),
			@pos				SMALLINT,
			@rec_id				INT,
			@order_no			INT,
			@ext				INT,
			@msg				VARCHAR(1000)


	EXEC dbo.cvo_auto_alloc_past_orders_log_sp @order_type, NULL, NULL, NULL, 'Starting auto allocation routine'

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
		mp_consolidation_no		 int				 NULL,  -- v1.1   
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
		mp_consolidation_no		 int				 NULL, -- v1.1      
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
	
	CREATE TABLE #alloc_orders (
		rec_id					INT IDENTITY (1,1),		
		order_no				INT,
		ext						INT,
		template				VARCHAR(255))

	-- Get oldest order date
	SELECT 
		@date_entered = MIN(date_entered)
	FROM
		dbo.orders_all (NOLOCK)
	WHERE
		[status] = 'N'
		AND [type] = 'I'
		AND ext = 0

	-- Convert dates to format used by allocation routine
	SELECT @today = CONVERT(VARCHAR(8),GETDATE(),1)
	SELECT @yesterday = CONVERT(VARCHAR(8),DATEADD(day, -1,GETDATE()),1)
	SELECT @oldest = CONVERT(VARCHAR(8),@date_entered,1)

	SET @msg = 'Date range from : ' + @oldest + ' to: ' + @yesterday
	EXEC dbo.cvo_auto_alloc_past_orders_log_sp @order_type, NULL, NULL, NULL, @msg

	-- Work through templates for the order type
	SET @alloc_order = 0
	WHILE 1=1
	BEGIN
		SELECT TOP 1
			@alloc_order = alloc_order,
			@where_clause = where_clause,
			@template = template_desc
		FROM
			dbo.cvo_auto_alloc_past_orders_templates (NOLOCK)
		WHERE
			order_type = @order_type
			AND alloc_order > @alloc_order
			AND ISNULL(where_clause,'') <> ''
		ORDER BY
			alloc_order

		IF @@ROWCOUNT = 0
			BREAK

		-- Update WHERE clause with date place holders
		SET @where_clause = REPLACE(@where_clause,'*TODAY*',@today)
		SET @where_clause = REPLACE(@where_clause,'*YESTERDAY*',@yesterday)
		SET @where_clause = REPLACE(@where_clause,'*OLDEST*',@oldest)

		IF LEN(@where_clause) <= 1020
		BEGIN

			-- Split up where clause to pass into pick ticket routine
			SET @in_where_clause1 = ''
			SET @in_where_clause2 = ''
			SET @in_where_clause3 = ''
			SET @in_where_clause4 = ''

			-- 1. Where clause 1
			IF @where_clause <> ''
			BEGIN
				IF LEN(@where_clause) <= 255
				BEGIN
					SELECT @in_where_clause1 = @where_clause
					SET @where_clause = ''
				END
				ELSE
				BEGIN
					SET @pos = 255	
					SELECT @pos = dbo.f_string_split_position (@where_clause,@pos)
					SELECT @in_where_clause1 = SUBSTRING(@where_clause,1,@pos)
					SELECT @where_clause = SUBSTRING(@where_clause,@pos + 1,(LEN(@where_clause)- @pos))
				END
			END

			-- 2. Where clause 2
			IF @where_clause <> ''
			BEGIN
				IF LEN(@where_clause) <= 255
				BEGIN
					SELECT @in_where_clause2 = @where_clause
					SET @where_clause = ''
				END
				ELSE
				BEGIN
					SET @pos = 255	
					SELECT @pos = dbo.f_string_split_position (@where_clause,@pos)
					SELECT @in_where_clause2 = SUBSTRING(@where_clause,1,@pos)
					SELECT @where_clause = SUBSTRING(@where_clause,@pos + 1,(LEN(@where_clause)- @pos))
				END
			END
			
			-- 3. Where clause 3
			IF @where_clause <> ''
			BEGIN
				IF LEN(@where_clause) <= 255
				BEGIN
					SELECT @in_where_clause3 = @where_clause
					SET @where_clause = ''
				END
				ELSE
				BEGIN
					SET @pos = 255	
					SELECT @pos = dbo.f_string_split_position (@where_clause,@pos)
					SELECT @in_where_clause3 = SUBSTRING(@where_clause,1,@pos)
					SELECT @where_clause = SUBSTRING(@where_clause,@pos + 1,(LEN(@where_clause)- @pos))
				END
			END
			
			-- 4. Where clause 4
			IF @where_clause <> ''
			BEGIN
		
				IF LEN(@where_clause) <= 255
				BEGIN
					SELECT @in_where_clause4 = @where_clause
				END
				ELSE
				BEGIN
					EXEC dbo.cvo_auto_alloc_past_orders_log_sp @order_type, @template, NULL, NULL, 'Error creating where clause - clause4 too long'
					RETURN
				END
				
			END

			-- Clear working tables
			DELETE FROM #so_allocation_detail_view
			DELETE FROM #so_alloc_management
			DELETE FROM #so_pre_allocation_table
			DELETE FROM #temp_sia_working_tbl
			DELETE FROM #top_level_parts
			DELETE FROM #so_alloc_management_Header
			DELETE FROM #so_allocation_detail_view_Detail
			DELETE FROM #so_alloc_err
			DELETE FROM #alloc_orders

			EXEC dbo.cvo_auto_alloc_past_orders_log_sp @order_type, @template, NULL, NULL, 'Processing template'

			-- Get orders based on allocation template
			EXEC tdc_plw_so_alloc_management_sp '', 'Default', @in_where_clause1, @in_where_clause2, @in_where_clause3, @in_where_clause4, 'ORDER BY  order_no ASC, order_ext ASC', 0, 0,0,'ALL', 'AUTO_ALLOC', 0

			-- Remove orders we can't allocate
			DELETE FROM #so_alloc_management where curr_alloc_pct >= curr_fill_pct

			DELETE
				a
			FROM
				#so_allocation_detail_view a 
			LEFT JOIN
				#so_alloc_management b
			ON
				a.order_no = b.order_no
				AND a.order_ext = b.order_ext
			WHERE
				b.order_no IS NULL

			-- Set remaining orders to allocate
			UPDATE #so_alloc_management SET sel_flg = -1

			-- Load allocated orders into temp table
			INSERT INTO #alloc_orders(
				order_no,
				ext,
				template)
			SELECT 
				order_no,
				order_ext,
				@template 
			FROM 
				#so_alloc_management 
			WHERE
				sel_flg = -1
			ORDER BY 
				order_no, 
				order_ext

			SET @msg = CAST(@@ROWCOUNT AS VARCHAR(6)) + ' order(s) selected for allocation'
			EXEC dbo.cvo_auto_alloc_past_orders_log_sp @order_type, @template, NULL, NULL, @msg

			IF EXISTS (SELECT 1 FROM #alloc_orders)
			BEGIN

				-- Mark records as being processed
				DELETE FROM tdc_plw_orders_being_allocated WHERE username = 'AUTO_ALLOC'  
				INSERT INTO tdc_plw_orders_being_allocated (
					order_no, 
					order_ext, 
					order_type, 
					username)   
				SELECT 
					order_no, 
					order_ext, 
					'S', 
					'AUTO_ALLOC'   
				FROM 
					#so_alloc_management   
				WHERE 
					(sel_flg <> 0 OR sel_flg2 <> 0)     
					AND CAST(order_no AS VARCHAR) + '-' + CAST(order_ext AS varchar) NOT IN(       
						SELECT DISTINCT CAST(a.order_no AS VARCHAR) + '-' + CAST(a.order_ext AS varchar)         
						FROM tdc_plw_orders_being_allocated a (NOLOCK),              #so_alloc_management b         
						WHERE ( sel_flg <> 0 OR sel_flg2 <> 0 )          
						AND a.order_no = b.order_no          
						AND a.order_ext = b.order_ext          
						AND a.order_type = 'S'         
						AND a.username != 'AUTO_ALLOC' )

				EXEC dbo.cvo_auto_alloc_past_orders_log_sp @order_type, @template, NULL, NULL, 'Allocating orders....'
			
				-- Allocate orders
				EXEC tdc_plw_so_save_sp 0,'AUTO_ALLOC', 'AUTO_ALLOC', 'ORDER BY  order_no ASC, order_ext ASC',1

				-- Loop through orders 
				SET @rec_id = 0		

				WHILE 1=1
				BEGIN
					SELECT TOP 1
						@rec_id = rec_id,
						@order_no = order_no,
						@ext = ext,
						@template = template
					FROM
						#alloc_orders
					WHERE
						rec_id > @rec_id
					ORDER BY
						rec_id

					IF @@ROWCOUNT = 0	
						BREAK

					EXEC dbo.cvo_auto_alloc_past_orders_log_sp @order_type, @template, @order_no, @ext, 'Allocation process run'

					-- Recalc freight
					EXEC [dbo].[CVO_GetFreight_recalculate_wrap_sp] @order_no, @ext
			
				END

				-- Custom bin code
				EXEC CVO_allocate_by_bin_group_adjust_sp 0

				-- Unmark orders as being allocated
				DELETE FROM tdc_plw_orders_being_allocated WHERE username = 'AUTO_ALLOC'

			END
		END
		ELSE
		BEGIN
			EXEC dbo.cvo_auto_alloc_past_orders_log_sp @order_type, @template, NULL, NULL, 'Error creating where clause - clause too long'
		END

	END

	EXEC dbo.cvo_auto_alloc_past_orders_log_sp @order_type, NULL, NULL, NULL, 'Stopping auto allocation routine'

END

GO
GRANT EXECUTE ON  [dbo].[cvo_auto_alloc_past_orders_sp] TO [public]
GO
