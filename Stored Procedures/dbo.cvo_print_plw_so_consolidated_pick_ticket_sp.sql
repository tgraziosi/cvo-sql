SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- v10.1 - TAG - 10/07/2014 - CVO Change - print special instructions
-- v10.2 CB 03/01/2015 - Fix records returned
-- v10.3 CB 09/02/2015 - Fix issue with freight calc for consolidated orders
-- v10.4 CB 13/01/2016 - #1586 - When orders are allocated or a picking list printed then update backorder processing
-- v10.5 CB 08/06/2016 - Split out manual case qty
-- v10.6 CB 15/11/2017 - Fix issue with UNION statement
-- v10.7 CB 07/12/2018 - #1687 Box Type Update
-- v10.8 CB 23/01/2019 - Fix box count


CREATE PROCEDURE [dbo].[cvo_print_plw_so_consolidated_pick_ticket_sp]  
 @user_id			varchar(50),  
 @station_id		varchar(20),  
 @order_no			int,  
 @order_ext			int,  
 @location			varchar(10),
 @consolidation_no	INT  
AS  
BEGIN  
	DECLARE @printed_on_the_page int,  
			@details_count       int,           @max_details_on_page int,            @printed_details_cnt int,          
			@page_no             int,           @number_of_copies    int,            @line_no             int,  
			@total_pages         int,           @ord_qty             varchar(20),    @topick              varchar(20),   
			@item_note           varchar(275),  @description         varchar(275),   @part_no             varchar(30),  
			@uom                 varchar(25),   @format_id           varchar(40),    @printer_id          varchar(30),  
			@kit_id              varchar(30),   @kit_caption         varchar(300),   @part_type           char   (2),  
			@order_note          varchar(275),  @ord_plus_ext        varchar(20),    @dest_zone_code      varchar (8),  
			@special_instr       varchar(275),  @cust_po             varchar(50),    @dest_bin       varchar(12),  
			@cust_code           varchar(50),   @order_date          varchar(30),    @sch_ship_date       varchar(30),  
			@carrier_DESC        varchar(50),   @ship_to_name        varchar(50),    @print_cnt        varchar(10),  
			@ship_to_add_1       varchar(60),   @ship_to_add_2       varchar(60),    @ship_to_add_3       varchar(60),  
			@ship_to_city        varchar(60),   @ship_to_country     varchar(60),    @ship_to_state       varchar(40),  
			@ship_to_zip         varchar(30),   @customer_name       varchar(60),    @addr1               varchar(60),  
			@addr2               varchar(60),   @addr3               varchar(60),    @addr4               varchar(60),  
			@addr5               varchar(60),   @back_ord_flag  char   (1),     @zone_DESC       varchar(40),    
			@salesperson         varchar(10),   @ship_to_no   varchar(10),    @tran_id       varchar(10),  
			@lot_ser             varchar(24),   @bin_no              varchar(12),    @return_value        int,  
			@salesperson_name    varchar(40),   @order_by_val        varchar(30),    @order_by_clause     varchar(50),  
			@cursor_statement    varchar(999),  @non_qty_statement  varchar(5000),  @header_add_note     varchar(255),  
			@cust_sort1      varchar(40),   @cust_sort2   varchar(40),  @cust_sort3       varchar(40),  
			@detail_add_note     varchar(255),
			@prt_line_no             int,					
			@display_line            int,				
			@order_time		varchar(10)		
   
	DECLARE @sku_code VARCHAR(16), @height DECIMAL(20,8), @width DECIMAL(20,8), @cubic_feet DECIMAL(20,8),  
			@length DECIMAL(20,8), @cmdty_code VARCHAR(8), @weight_ea DECIMAL(20,8), @so_qty_increment DECIMAL(20,8),   
			@category_1 VARCHAR(15), @category_2 VARCHAR(15), @category_3 VARCHAR(15), @category_4 VARCHAR(15), @category_5 VARCHAR(15)   

	DECLARE @promo_name varchar(30), @order_type varchar(60), @routing varchar(20)		

	DECLARE @summary1 VARCHAR(60),@summary2 VARCHAR(60),@summary3 VARCHAR(60) 

	DECLARE @display_carton INT	
	
	DECLARE @is_autopack			SMALLINT,
			@carton_id				INT,
			@carton_lines			INT,
			@max_carton_id			INT,
			@carton_sql				VARCHAR(100),
			@prev_carton_id			INT,
			@carton_on_the_page		INT,
			@reqd_lines				INT
	
	DECLARE @c_order_no				INT,
			@c_ext					INT,
			@c_special_instr		varchar(275), -- v10.1
			@row_id					INT,
			@rec_id					INT


	SET @is_autopack = 0


	DECLARE @autopick_cases	smallint

	IF EXISTS (SELECT 1 FROM dbo.tdc_config WHERE [function] = 'AUTOPICK_CASES' and active = 'Y')
		SET @autopick_cases = 1
	ELSE
		SET @autopick_cases = 0

	-- Create temporary table for autopack stock order details
		CREATE TABLE #pick_ticket(
		[order_no] [int] NULL,
		[order_ext] [int] NULL,
		[location] [varchar] (10) NULL,
		[line_no] [int] NULL,
		[part_type] [char](1) NULL,
		[uom] [char](2) NULL,
		[description] [varchar](255) NULL,
		[ord_qty] [decimal](20, 8) NOT NULL,
		[dest_bin] [varchar](12) NULL,
		[pick_qty] [decimal](20, 8) NOT NULL,
		[part_no] [varchar](30) NOT NULL,
		[lot_ser] [varchar](25) NULL,
		[bin_no] [varchar](12) NULL,
		[item_note] [varchar](255) NULL,
		[tran_id] [INT] NULL,
		[carton_id] [int] NULL)  

	----------------- Header Data --------------------------------------  
	
	-- The special instructions field now displays the orders on the consolidation set
	CREATE TABLE #cons_orders (
		rec_id INT IDENTITY	(1,1),
		order_no INT,
		order_ext INT,
		-- START v10.1
		special_instr varchar(275))
		-- END v10.1

	INSERT INTO #cons_orders (
		order_no,
		order_ext,
		-- START v10.1
		special_instr)
		-- END v10.1
	SELECT DISTINCT
		b.order_no,
		b.order_ext,
		-- START v10.1
		c.special_instr
		-- END v10.1
	FROM
		dbo.cvo_masterpack_consolidation_det a (NOLOCK)
	INNER JOIN
		dbo.tdc_soft_alloc_tbl b (NOLOCK)
	ON
		a.order_no = b.order_no
		AND a.order_ext = b.order_ext
	-- START v10.1
	join #so_pick_ticket c (nolock)
	on
		c.order_no = a.order_no
		and c.order_ext = a.order_ext
	-- END v10.1
	WHERE
		a.consolidation_no = @consolidation_no
		AND b.order_type = 'S'

	SET @rec_id = 0
	SET @special_instr = ''
	
	WHILE 1=1
	BEGIN
		SELECT TOP 1
			@rec_id = rec_id,
			@c_order_no = order_no,
			@c_ext = order_ext,
			-- START v10.1
			@c_special_instr = isnull(special_instr,'') 
			-- END v10.1
		FROM
			#cons_orders
		WHERE
			rec_id > @rec_id
		ORDER BY 
			rec_id

		IF @@ROWCOUNT = 0
			BREAK

		-- START v10.1
		IF @special_instr = ''
		BEGIN
			SET @special_instr = CAST(@c_order_no AS VARCHAR(10)) + '-' + CAST(@c_ext AS VARCHAR(3)) 
			+ ' ' + isnull(@c_special_instr,'')
		END
		ELSE
		BEGIN
			SET @special_instr = left(rtrim(@special_instr) + ', ' + CAST(@c_order_no AS VARCHAR(10)) + '-' + CAST(@c_ext AS VARCHAR(3))
			+ ' ' + isnull(@c_special_instr,''), 275 )
		END
		-- END v10.1
	END


	-- Now retrieve the Orders information  
	SELECT DISTINCT  
			@ord_plus_ext		= CAST(order_no  AS varchar(10)) + '-' + CAST(order_ext AS varchar(4)),  
			@order_date			= convert(varchar(12),order_date,101),
			--@special_instr		= REPLACE(a.special_instr, CHAR(13), '/'),      
			@order_note			= REPLACE(a.order_note, CHAR(13), '/'),     
			@sch_ship_date		= convert(varchar(12),sch_ship_date,101),  
			@addr1				= addr1,      
			@addr2				= addr2,      
			@addr3				= addr3,      
			@addr4				= addr4,      
			@addr5				= addr5,      
			@ship_to_add_1		= ship_to_add_1,  
			@ship_to_add_2		= ship_to_add_2,  
			@ship_to_add_3		= ship_to_add_3,  
			@ship_to_name		= ship_to_name,   
			@ship_to_city		= ship_to_city,   
			@ship_to_state		= ship_to_state,  
			@ship_to_country	= ship_to_country,  
			@ship_to_zip		= ship_to_zip,      
			@customer_name		= customer_name,    
			@cust_po			= cust_po,        
			@cust_code			= cust_code,        
			@carrier_DESC		= carrier_DESC,     
			@print_cnt			= CASE WHEN  
								(SELECT COUNT(*) FROM tdc_print_history_tbl b  
								 WHERE b.order_no       = a.order_no   
							 AND b.order_ext      = a.order_ext   
							 AND b.location       = a.location   
							 AND pick_ticket_type = 'S' ) > 0   
						 THEN 'RE-PRINT'   
						 ELSE 'NEW'   
							   END  
	  FROM #so_pick_ticket a (NOLOCK)  
	 WHERE order_no  = @order_no  
	   AND order_ext = @order_ext  
	   AND location  = @location  
	   AND [user_id] = @user_id  
	-- SCR #36087  Jim 1/25/06  
	 --ORDER BY order_no, order_ext, location  

	--v2.0 GET COUNTRY FROM CUSTOMER MASTER
		SELECT @ship_to_country	= ISNULL(g.description,'')				--v2.0
		  FROM arcust a (NOLOCK), gl_country g (NOLOCK)					--v2.0  
		 WHERE a.customer_code = @cust_code								--v2.0
		   AND a.country_code = g.country_code							--v2.0
	--

	--BEGIN SED008 -- Global Ship To
	--JVM 07/28/2010
	IF EXISTS(SELECT sold_to FROM orders (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext AND sold_to IS NOT NULL AND LTRIM (sold_to) <> '' AND RTRIM (sold_to) <> '')
	BEGIN
		SELECT	--@ship_to_no         = a.ship_to_code,		       
				@ship_to_name       = a.address_name, 
				@ship_to_add_1      = a.addr1,  
				@ship_to_add_2      = a.addr2,   
				@ship_to_add_3      = a.addr3,  			
				@ship_to_city       = a.city,     
				@ship_to_country	= a.country_code,   
				@ship_to_state      = a.state,     
				@ship_to_zip        = a.postal_code  
		FROM    armaster_all a  (NOLOCK)
		WHERE   a.customer_code = (SELECT sold_to FROM orders (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext ) AND
				address_type = 9		    
	END	
	--END   SED008 -- Global Ship To
	  
	SELECT @cust_sort1 = addr_sort1,   
		   @cust_sort2 = addr_sort2,   
		   @cust_sort3 = addr_sort3  
	  FROM arcust (NOLOCK)
	 WHERE customer_code = @cust_code								
	  
	--Now retrieve salesperson, zone information, and user preferences  
	SELECT @salesperson =   
	 ISNULL((SELECT salesperson      FROM orders   (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext AND location = @location), '')  
	SELECT @salesperson_name =   
	 ISNULL((SELECT salesperson_name FROM arsalesp (NOLOCK) WHERE salesperson_code = @salesperson),        '')  
	SELECT @dest_zone_code =   
	 ISNULL((SELECT dest_zone_code   FROM orders   (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext AND location = @location), '')  
	SELECT @zone_DESC =   
	 ISNULL((SELECT zone_DESC        FROM arzone   (NOLOCK) WHERE zone_code = @dest_zone_code),        '')  
	SELECT @back_ord_flag =   
	 ISNULL((SELECT back_ord_flag    FROM orders   (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext AND location = @location), '')  
	  
	EXEC tdc_parse_string_sp @Special_Instr, @Special_Instr output   
	  
	-- Order header additional note  
	SELECT @header_add_note = CAST(note AS varchar(255))  
	  FROM notes (NOLOCK)  
	 WHERE code_type = 'O'  
	   AND code      = @order_no             
	   AND line_no   = 0  

	-- Ensure Carrier is from order header						
	SELECT @carrier_DESC = IsNull(v.addr1,' ')
	  FROM orders o, arshipv v 
	 WHERE o.routing = v.ship_via_code AND o.order_no = @order_no AND ext = @order_ext 
	--
	  
	IF @header_add_note IS NULL SET @header_add_note = ''  
	  
	EXEC tdc_parse_string_sp @header_add_note, @header_add_note OUTPUT  


	SELECT @order_time = convert(varchar(5),date_entered,108)
	  FROM orders (NOLOCK)  
	 WHERE order_no  = @order_no AND ext = @order_ext  

	  
	-------------- Now let's insert the Header information into #PrintData  --------------------------------------------  
	-------------- We are going to use this table in the tdc_print_label_sp --------------------------------------------  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ORDER_NO',             CAST(@order_no  AS varchar(10)))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ORDER_EXT',            CAST(@order_ext AS varchar(4)))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ORDER_PLUS_EXT',       CAST(@consolidation_no AS VARCHAR(10)))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_LOCATION',             ISNULL(@location,    ''))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SPECIAL_INSTR',        ISNULL(@special_instr,   ''))   
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ORDER_NOTE',           ISNULL(@order_note,   ''))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CUST_PO','')
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CUST_CODE',            ISNULL(@cust_code,    ''))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ORDER_DATE',           ISNULL(@order_date,   ''))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ORDER_TIME',           ISNULL(@order_time,   ''))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SCH_SHIP_DATE',        ISNULL(@sch_ship_date,   ''))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CARRIER_DESC',         ISNULL(@carrier_DESC,   ''))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SHIP_TO_NAME',         ISNULL(@ship_to_name,   ''))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SHIP_TO_ADD_1',        ISNULL(@ship_to_add_1,   ''))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SHIP_TO_ADD_2',        ISNULL(@ship_to_add_2,   ''))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SHIP_TO_ADD_3',        ISNULL(@ship_to_add_3,   ''))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SHIP_TO_CITY',         ISNULL(@ship_to_city,   ''))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SHIP_TO_COUNTRY',      ISNULL(@ship_to_country, ''))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SHIP_TO_STATE',        ISNULL(@ship_to_state,   ''))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SHIP_TO_ZIP',          ISNULL(@ship_to_zip,   ''))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CUSTOMER_NAME',        ISNULL(@customer_name,   ''))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ADDR1',            ISNULL(@addr1,    ''))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ADDR2',            ISNULL(@addr2,    ''))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ADDR3',            ISNULL(@addr3,    ''))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ADDR4',             ISNULL(@addr4,    ''))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ADDR5',             ISNULL(@addr5,    ''))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_PRINT_CNT',          ISNULL(@print_cnt,    ''))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_USER_ID',             ISNULL(@user_id,    ''))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SALESPERSON',          ISNULL(@salesperson,   ''))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SALESPERSON_NAME',     ISNULL(@salesperson_name,   ''))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_DEST_ZONE_CODE',       ISNULL(@dest_zone_code,   ''))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ZONE_DESC',           ISNULL(@zone_DESC,    ''))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CUSTOMER_PREFERENCE',  ISNULL(@back_ord_flag,   ''))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CUST_SORT1',      ISNULL(@cust_sort1,   ''))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CUST_SORT2',      ISNULL(@cust_sort2,   ''))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CUST_SORT3',      ISNULL(@cust_sort3,   ''))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_HEADER_ADD_NOTE',     ISNULL(@header_add_note,     ''))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_IS_CONSOLIDATED',     'Consolidated')
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_INSTRUCT_TEXT',     'Consolidated Orders:')
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_BARCODE_HDR',     'Consolidated No:')

	-- Not needed - multiple orders
	/*
	-- ADD PROMO NAME																					-- T McGrady	22.MAR.2011
	SELECT @promo_name = IsNull(p.promo_name,'')														-- T McGrady	22.MAR.2011
	FROM  CVO_orders_all o (nolock)																		-- T McGrady	22.MAR.2011
	LEFT OUTER JOIN CVO_promotions p ON o.promo_id = p.promo_id AND o.promo_level = p.promo_level		-- T McGrady	22.MAR.2011
	WHERE o.order_no = @order_no																		-- T McGrady	22.MAR.2011
	  AND o.ext = @order_ext																			-- T McGrady	22.MAR.2011
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_PROMO_NAME',ISNULL(@promo_name,' '))	-- T McGrady	22.MAR.2011
	--																									-- T McGrady	22.MAR.2011
	*/

	SELECT @order_type = p.category_code+'/'+p.category_desc, @routing = o.routing						-- v2.0
	FROM  orders o (nolock)																				-- v2.0
	LEFT OUTER JOIN so_usrcateg p ON o.user_category = p.category_code									-- v2.0
	WHERE o.order_no = @order_no																		-- v2.0
	  AND o.ext = @order_ext																			-- v2.0
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ORDER_TYPE',ISNULL(@order_type,' '))	-- v2.0
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ROUTING',ISNULL(@routing,' '))			-- v2.0
	--	

	-- v10.7 Start																									-- v2.0
	DECLARE	@packing_summary	varchar(100),
			@box_type			varchar(20),
			@box_type_count		int

	CREATE TABLE #packing_summary (
		box_type	varchar(20),
		box_count	int)

	INSERT	#packing_summary
	SELECT  box_type, COUNT(distinct box_id) -- v10.8
	FROM	cvo_pre_packaging  (NOLOCK) 
	WHERE	cons_no = @consolidation_no
	AND		order_type = 'S'
	GROUP BY box_type

	SET @packing_summary = ''
	SET @box_type = ''

	WHILE (1 = 1)
	BEGIN
		SELECT	TOP 1 @box_type = box_type,
				@box_type_count = box_count
		FROM	#packing_summary
		WHERE	box_type > @box_type
		ORDER BY box_type ASC

		IF (@@ROWCOUNT = 0)
			BREAK

		SET @packing_summary = @packing_summary + @box_type + ' x ' + CAST(@box_type_count as varchar(5)) + '; '

	END

	DROP TABLE #packing_summary

	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_PACKING_SUMMARY',ISNULL(@packing_summary,' '))
	-- v10.9 End																								-- v2.0


	-- CVO - Need Order values for printing
	DECLARE @order_tax		Decimal(20,2),
			@order_frt		Decimal(20,2),
			@order_disc		Decimal(20,2),
			@order_gross	Decimal(20,2),
			@order_net		Decimal(20,2)

	SET @order_gross	= 0.00
	SET @order_tax		= 0.00
	SET @order_disc		= 0.00
	SET @order_frt		= 0.00
	SET @order_net		= 0.00

	IF EXISTS(SELECT buying_group FROM CVO_orders_all WHERE order_no = @order_no AND ext = @order_ext AND buying_group IS NOT NULL AND buying_group != '' )
		BEGIN
			SELECT  @order_tax      = CAST((o.tot_ord_tax) AS DECIMAL (20,2)),
					@order_frt      = CAST((o.tot_ord_freight) AS DECIMAL (20,2))
			FROM  orders o (nolock)
			WHERE o.order_no = @order_no AND o.ext = @order_ext
		END
		ELSE
		BEGIN
			SELECT  @order_gross    = CAST((o.total_amt_order) AS DECIMAL (20,2)),
					@order_tax      = CAST((o.tot_ord_tax) AS DECIMAL (20,2)),
					@order_disc     = CAST((o.tot_ord_disc) AS DECIMAL (20,2)),
					@order_frt      = CAST((o.tot_ord_freight) AS DECIMAL (20,2)),
					@order_net      = CAST(((o.total_amt_order - o.tot_ord_disc) + o.tot_ord_tax + o.tot_ord_freight) AS DECIMAL (20,2))
			FROM  orders o (nolock)
			WHERE o.order_no = @order_no AND o.ext = @order_ext
		END

	-- v10.3 Start
	-- Calc freight for consolidation
	IF(@consolidation_no <> 0)
	BEGIN

		DECLARE @alloc_weight	decimal(20,8),
				@carrier_code	varchar(10),
				@zip_code		varchar(40),
				@wght			decimal(20,8),
				@Weight_code	varchar(20),
				@frght_amt		decimal(20,8)

		SELECT	@carrier_code = a.routing,   
				@zip_code = a.ship_to_zip     
		FROM	dbo.orders_all a (NOLOCK)    
		JOIN	#cons_orders z
		ON		a.order_no = z.order_no
		AND		a.ext = z.order_ext
		JOIN	dbo.cvo_orders_all cv (NOLOCK)  
		ON		a.order_no = cv.order_no  
		AND		a.ext = cv.ext  
		WHERE	ISNULL(a.freight_allow_type,'')  <> 'FRTOVRID' 
		AND		ISNULL(cv.free_shipping,'N') <> 'Y'    

		SELECT	@alloc_weight = ISNULL(SUM(l.weight_ea * a.qty),0)
		FROM	ord_list l (NOLOCK)
		JOIN	tdc_soft_alloc_tbl a (NOLOCK)
		ON		a.order_no = l.order_no
		AND		a.order_ext = l.order_ext
		AND		a.line_no = l.line_no
		JOIN	#cons_orders z
		ON		l.order_no = z.order_no
		AND		l.order_ext = z.order_ext
		JOIN	dbo.orders_all o (NOLOCK)  
		ON		z.order_no = o.order_no  
		AND		z.order_ext = o.ext  
		JOIN	dbo.cvo_orders_all cv (NOLOCK)  
		ON		z.order_no = cv.order_no  
		AND		z.order_ext = cv.ext  
		WHERE	ISNULL(o.freight_allow_type,'')  <> 'FRTOVRID' 
		AND		ISNULL(cv.free_shipping,'N') <> 'Y'    		
		
		SELECT	@wght = MIN(Max_weight)    
		FROM 	dbo.CVO_carriers (NOLOCK)
		WHERE	Carrier = @carrier_code 
		AND		Lower_zip <= LEFT(@zip_code,5) 
		AND		Upper_zip >= LEFT(@zip_code,5) 
		AND		Max_weight >= @alloc_weight  

		SELECT	@Weight_code = MIN(Weight_code)    
		FROM 	dbo.CVO_carriers (NOLOCK)
		WHERE	Carrier = @carrier_code 
		AND		Lower_zip <= LEFT(@zip_code,5) 
		AND		Upper_zip >= LEFT(@zip_code,5) 
		AND		Max_weight = @wght   

		SELECT	@frght_amt = ISNULL(MIN(charge), 0)    
		FROM	dbo.CVO_weights (NOLOCK)    
		WHERE 	Weight_code = @Weight_code 
		AND		wgt >= @alloc_weight

		SET @order_frt = @frght_amt

	END

	-- v10.3 End

	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ORDER_GROSS', CAST(@order_gross AS VARCHAR(30)))
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ORDER_TAX', CAST(@order_tax AS VARCHAR(30)))
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ORDER_DISCOUNT', CAST(@order_disc AS VARCHAR(30)))
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ORDER_FREIGHT', CAST(@order_frt AS VARCHAR(30)))
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ORDER_NET', CAST(@order_net AS VARCHAR(30)))
	--

	--BEGIN SED009 -- Consolidated Shipments
	--JVM 09/21/2010
	DECLARE @LP_CONSOLIDATED_SHIPMENT VARCHAR(40)
	IF EXISTS(SELECT sold_to FROM orders (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext AND sold_to IS NOT NULL AND LTRIM (sold_to) <> '' AND RTRIM (sold_to) <> '')
		SET @LP_CONSOLIDATED_SHIPMENT = 'LAB ORDER'
	ELSE
	IF EXISTS(SELECT customer_code FROM CVO_armaster_all WHERE customer_code = @cust_code AND consol_ship_flag = 1)
		SET @LP_CONSOLIDATED_SHIPMENT = 'CONSOLIDATED SHIPMENT'
	ELSE
		SET @LP_CONSOLIDATED_SHIPMENT = ' '

	IF EXISTS(SELECT 1 FROM dbo.cvo_consolidate_shipments WHERE order_no = @order_no AND order_ext = @order_ext)
		SET @LP_CONSOLIDATED_SHIPMENT = 'CONSOLIDATED SHIPMENT'

	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CONSOLIDATED_SHIPMENT', @LP_CONSOLIDATED_SHIPMENT)  	
	--END   SED009 -- Consolidated Shipments		

	-- v6.1 Start
	IF EXISTS (SELECT 1 FROM cvo_ord_list (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND is_customized = 'S')
		INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CUSTOM', 'Y')
	ELSE  	
		INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CUSTOM', 'N')
	-- v6.1 End		
			  
	IF (@@ERROR <> 0 )  
	BEGIN  
	 RAISERROR ('Insert into #PrintData Failed', 16, 1)     
	 RETURN  
	END  
	  
	--------------------------------------------------------------------------------------------------  
	-- Now let's run the tdc_print_label_sp to get format_id, printer_id, and number of copies -----  
	EXEC @return_value = tdc_print_label_sp 'PLW', 'SOPICKTKT', 'VB', @station_id  
	  
	-- IF label hasn't been set up for the station id, try finding a record for the user id  
	IF @return_value != 0  
	BEGIN  
	 EXEC @return_value = tdc_print_label_sp 'PLW', 'SOPICKTKT', 'VB', @user_id  
	END  
	  
	-- IF label hasn't been set up for the user id, exit  
	IF @return_value <> 0  
	BEGIN  
	 TRUNCATE TABLE #PrintData  
	 RETURN  
	END  
	  
	-- Loop through the format_ids  
	DECLARE print_cursor CURSOR FOR   
	 SELECT format_id, printer_id, number_of_copies FROM #PrintData_Output  
	  
	OPEN print_cursor  
	FETCH NEXT FROM print_cursor INTO @format_id, @printer_id, @number_of_copies  
	  
	WHILE (@@FETCH_STATUS <> -1)  
	BEGIN  
	 -------------- Now let's insert the Header into the output table -----------------  
	 INSERT INTO #tdc_print_ticket (print_value) SELECT '*FORMAT,' + @format_id   
	 INSERT INTO #tdc_print_ticket (print_value) SELECT data_field + ',' + data_value FROM #PrintData  
	   
	 IF (@@ERROR <> 0 )  
	 BEGIN  
	  CLOSE      print_cursor  
	  DEALLOCATE print_cursor  
	  RAISERROR ('Insert into #tdc_print_ticket Failed', 16, 2)       
	  RETURN  
	 END  
	 -----------------------------------------------------------------------------------------------  
	  
	 ------------------------ Detail Data ----------------------------------------------------------  
	 -- Get  Count of the Details to be printed  
	 /*SELECT @details_count =                  -----original code ROB Martin 1/16/12
	  (SELECT COUNT(*)   
		FROM #so_pick_ticket   
	   WHERE order_no  = @order_no  
				AND order_ext = @order_ext  
				AND location  = @location  
				AND [user_id] = @user_id)  
	  +  
	  (SELECT COUNT(*)    
			   FROM ord_list (NOLOCK)  
	   WHERE order_no  = @order_no  
		 AND order_ext = @order_ext  
		 AND location  = @location  
				   AND part_type IN ('V', 'M'))  ---end original code Rob Martin 1/16/12
	  */

	SELECT @details_count =              --3.0 Rob Martin Start
		(select count(*)
			from tdc_pick_queue nolock
	WHERE 
		mp_consolidation_no = @consolidation_no
		and location = @location
		and ISNULL(assign_user_id,'') <> 'HIDDEN' 
		and trans = 'STDPICK')

														



		
	 ----------------------------------  
	 -- Get Max Detail Lines on a page.             
	 ----------------------------------  
	SET @max_details_on_page = 0  
	 SET @order_by_val        = NULL  
	  
	 -- First check if user defined the number of details for the format ID  
	 SELECT @max_details_on_page = detail_lines,   
				   @order_by_val        = print_detail_sort        
			  FROM tdc_tx_print_detail_config (NOLOCK)    
			 WHERE module       = 'PLW'     
			   AND trans        = 'SOPICKTKT'  
			   AND trans_source = 'VB'  
			   AND format_id    = @format_id  
	  
	 -- If not defined, get the value from tdc_config  
	 IF ISNULL(@max_details_on_page, 0) = 0  
	 BEGIN  
	  -- If not defined, default to 4  
	  SELECT @max_details_on_page = ISNULL((SELECT value_str FROM tdc_config (NOLOCK) WHERE [function] = 'SO_Pick_Detl_Count'), 4)   
	 END  
	 
	-- START v5.4
	-- Move page calculation for autopack orders lower in the routine
	/*
	-- START v5.1 
	 -- Get Total Pages  
	 IF @is_autopack = 1
	 BEGIN
		SET @total_pages = 0
		
		-- Check how many items are on each carton
		SET @carton_id = 0
		WHILE 1=1
		BEGIN
			SELECT TOP 1
				@carton_id = carton_id,
				@carton_lines = COUNT(1)
			FROM
				dbo.CVO_autopack_carton (NOLOCK)
			WHERE
				order_no = @order_no
				AND order_ext = @order_ext
				AND carton_id > @carton_id
			GROUP BY 
				carton_id
			ORDER BY
				carton_id

			IF @@ROWCOUNT = 0
				BREAK

			SELECT @total_pages = @total_pages + CASE WHEN @carton_lines % @max_details_on_page = 0 THEN @carton_lines / @max_details_on_page ELSE @carton_lines / @max_details_on_page + 1 END    
			
		END
		
		-- Now get how many are not on cartons
		SELECT 
			@carton_lines = COUNT(1)
		FROM 
			dbo.tdc_pick_queue a (NOLOCK)
		LEFT JOIN
			CVO_autopack_carton b (NOLOCK)
		ON
			a.trans_type_no = b.order_no
			AND a.trans_type_ext = b.order_ext
			AND a.line_no = b.line_no 
		WHERE 
			a.trans_type_no  = @order_no  
			AND a.trans_type_ext = @order_ext
			AND a.location = @location
			AND ISNULL(a.assign_user_id,'') <> 'HIDDEN' 
			AND a.trans = 'STDPICK'
			AND b.order_no IS NULL

		SELECT @total_pages = @total_pages + CASE WHEN @carton_lines % @max_details_on_page = 0 THEN @carton_lines / @max_details_on_page ELSE @carton_lines / @max_details_on_page + 1 END

	 END
	 ELSE
	*/
	  IF @is_autopack <> 1
	-- END v5.4
	 BEGIN	
		 SELECT @total_pages =   
		  CASE WHEN @details_count % @max_details_on_page = 0   
			   THEN @details_count / @max_details_on_page    
					ELSE @details_count / @max_details_on_page + 1   
		  END    
	 END
	 -- END v5.1
	         
	 IF @order_by_val IS NULL  
	 BEGIN  
			 SELECT @order_by_val = ISNULL((SELECT value_str FROM tdc_config WHERE [function] = 'so_picktkt_sort' AND [active] = 'Y'),'0')  
	 END  
	  
			-- START v5.1 
			IF @is_autopack = 1
			BEGIN
				-- Order by carton string
				SET @carton_sql = ' carton_id '

				SELECT @order_by_clause =  
					CASE WHEN @order_by_val = 'LIFO'          THEN ' ORDER BY ' + @carton_sql + ' , date_expires DESC'  
						 WHEN @order_by_val = 'FIFO'          THEN ' ORDER BY ' + @carton_sql + ' , date_expires ASC'  
						 WHEN @order_by_val = 'LOT/BIN ASC'   THEN ' ORDER BY ' + @carton_sql + ' , bin_no ASC'  
						 WHEN @order_by_val = 'LOT/BIN DESC'  THEN ' ORDER BY ' + @carton_sql + ' , bin_no DESC'  
						 WHEN @order_by_val = 'QTY. ASC'      THEN ' ORDER BY ' + @carton_sql + ' , pick_qty ASC'  
						 WHEN @order_by_val = 'QTY. DESC'     THEN ' ORDER BY ' + @carton_sql + ' , pick_qty DESC'  
						 WHEN @order_by_val = 'LINE NO. ASC'  THEN ' ORDER BY ' + @carton_sql + '  ,line_no ASC'  
						 WHEN @order_by_val = 'LINE NO. DESC' THEN ' ORDER BY ' + @carton_sql + ' , line_no DESC'  
															  ELSE ' ORDER BY ' + @carton_sql + ' , line_no ASC'  
					END
			END
			ELSE
			BEGIN
				SELECT @order_by_clause =  
					CASE WHEN @order_by_val = 'LIFO'          THEN ' ORDER BY date_expires DESC'  
						 WHEN @order_by_val = 'FIFO'          THEN ' ORDER BY date_expires ASC'  
						 WHEN @order_by_val = 'LOT/BIN ASC'   THEN ' ORDER BY bin_no ASC'  
						 WHEN @order_by_val = 'LOT/BIN DESC'  THEN ' ORDER BY bin_no DESC'  
						 WHEN @order_by_val = 'QTY. ASC'      THEN ' ORDER BY pick_qty ASC'  
						 WHEN @order_by_val = 'QTY. DESC'     THEN ' ORDER BY pick_qty DESC'  
						 WHEN @order_by_val = 'LINE NO. ASC'  THEN ' ORDER BY line_no ASC'  
						 WHEN @order_by_val = 'LINE NO. DESC' THEN ' ORDER BY line_no DESC'  
															  ELSE ' ORDER BY line_no ASC'  
					END
			END
			-- END v1.5  
	  
	 -- First Page  
	 SELECT @page_no = 1, @printed_details_cnt = 1, @printed_on_the_page = 1  

	-- v5.9 Start
	-- Check the config, is autopick switched on
	IF @autopick_cases = 1
	BEGIN

		-- v6.2 Start
		IF OBJECT_ID('tempdb..#cvo_ord_list') IS NOT NULL
			DROP TABLE #cvo_ord_list
		-- v6.2 End

		-- Create working table for autopick cases
		CREATE TABLE #cvo_ord_list (
			order_no		int,
			order_ext		int,
			line_no			int,
			add_case		varchar(1),
			add_pattern		varchar(1),
			from_line_no	int,
			is_case			int,
			is_pattern		int,
			add_polarized	varchar(1),
			is_polarized	int,
			is_pop_gif		int,
			is_amt_disc		varchar(1),
			amt_disc		decimal(20,8),
			is_customized	varchar(1),
			promo_item		varchar(1),
			list_price		decimal(20,8),
			orig_list_price	decimal(20,8))		

		-- Call routine to populate #cvo_ord_list with the frame/case relationship for each order in consolidation set
		SET @row_id = 0
		WHILE 1=1 
		BEGIN
		
			SELECT TOP 1
				@row_id = row_id,
				@c_order_no = order_no,
				@c_ext = order_ext
			FROM
				dbo.cvo_masterpack_consolidation_det
			WHERE
				row_id > @row_id
			AND
				consolidation_no = @consolidation_no -- v10.2
			ORDER BY
				row_id

			IF @@ROWCOUNT = 0
				BREAK

			EXEC CVO_create_fc_relationship_sp @c_order_no, @c_ext
		END
	END

	SELECT @cursor_statement =	'DECLARE detail_cursor CURSOR FOR 
								SELECT 
									a.line_no,
									b.part_type,  
									b.uom, 
									b.[description],
									b.ord_qty,
									a.next_op as dest_bin,
									a.qty_to_process as pick_qty,
									a.part_no,
									a.lot as lot_ser, 
									a.bin_no, 
									b.item_note, 
									CAST(a.tran_id AS varchar(10)) as tran_id,
									1 AS carton_id
								FROM 
									dbo.tdc_pick_queue a (NOLOCK)
								INNER JOIN
									dbo.cvo_masterpack_consolidated_order_lines_vw b (NOLOCK)
								ON
									a.mp_consolidation_no = b.consolidation_no
									AND a.part_no = b.part_no
									AND a.location = b.location
								WHERE 
									a.mp_consolidation_no = ' + cast(@consolidation_no as varchar(30)) + 
								' AND a.location  = ''' +      @location                 + ''''  

	-- We should be able to print non-qty bearing and misc part  , date_expires = ''	SED009 -- Pick List Printing -- date_expires should not be included into cursor
	-- 10.6 add space
	SELECT @non_qty_statement =	' UNION 
								SELECT 
								1,
								part_type,  
								uom, 
								[description],
								ord_qty,
								NULL as dest_bin,
								ord_qty as pick_qty,
								part_no,
								NULL as lot_ser, 
								NULL as bin_no, 
								item_note, 
								NULL as tran_id,
								1 AS carton_id
							FROM 
								dbo.cvo_masterpack_consolidated_order_lines_vw (NOLOCK)
							WHERE 
								consolidation_no = ' + cast(@consolidation_no as varchar(30)) + 
								' AND part_type IN (''V'', ''M'')'


	 EXEC (@cursor_statement + @non_qty_statement + @order_by_clause)  

	  
	 OPEN detail_cursor  
	  
	 FETCH NEXT FROM detail_cursor INTO   
	  @line_no, @part_type, @uom,     @description, @ord_qty, @dest_bin,  
	  @topick,  @part_no,   @lot_ser, @bin_no,      @item_note, @tran_id, @carton_id	-- v5.1  
	  
	 SET @prev_carton_id = @carton_id	-- v5.1
	 SET @display_carton = 1 -- v5.4

	 WHILE (@@FETCH_STATUS <> -1)  
	 BEGIN  


		-- START v6.0 - order summary
		IF @page_no = 1
		BEGIN
			EXEC cvo_masterpack_consolidated_pick_ticket_summary_sp @consolidation_no,@location,@summary1 OUTPUT,@summary2 OUTPUT,@summary3 OUTPUT
		END
		ELSE
		BEGIN
			SET @summary1 = ''
			SET @summary2 = ''
			SET @summary3 = ''
		END
		
		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_ORDER_SUMMARY_1,' + @summary1) 
		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_ORDER_SUMMARY_2,' + @summary2) 
		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_ORDER_SUMMARY_3,' + @summary3) 
		-- END v6.0

	 -- v1.1 Case Part Consolidation - Start
		DECLARE	@ConQty		decimal(20,8),	
				@ConSet		int,
				@str_line	varchar(8)

		SET @ConSet = 0
		SET @str_line = 'Multiple'
		SET @ConQty = 0.00

		-- Is this line a consolidated one
		IF EXISTS (SELECT 1 FROM tdc_pick_queue (NOLOCK) WHERE tran_id = CAST(@tran_id AS INT)
					AND pcsn IS NOT NULL)
		BEGIN
			SET @ConSet = 1
			-- START v5.2
			IF @is_autopack = 1
			BEGIN
				-- START v5.4
				SELECT 
					@ConQty = SUM(a.pick_qty )
				FROM 
					#pick_ticket a (NOLOCK) 
				INNER JOIN 
					dbo.tdc_pick_queue b (NOLOCK)
				ON 
					a.tran_id	= b.tran_id
				WHERE 
					b.tran_id_link = CAST(@tran_id AS INT)  
					AND a.carton_id = @carton_id 
				/*	
				SELECT	@ConQty = SUM(pick_qty ) 
				FROM	#pick_ticket (NOLOCK)
				WHERE	tran_id = CAST(@tran_id AS INT)
						AND carton_id = @carton_id 
				*/
				-- END v5.4

			END
			ELSE
			BEGIN
				SELECT	@ConQty = CAST(pcsn AS DECIMAL(20,8)) 
				FROM	tdc_pick_queue (NOLOCK)
				WHERE	tran_id = CAST(@tran_id AS INT)
			END
			-- END v5.2
		END
		
		-- If this line is a HIDDEN one then move to the next record
		IF EXISTS (SELECT 1 FROM tdc_pick_queue (NOLOCK) WHERE tran_id = CAST(@tran_id AS INT)
					AND ISNULL(assign_user_id,'') = 'HIDDEN')
		BEGIN
		  FETCH NEXT FROM detail_cursor INTO   
		   @line_no, @part_type, @uom,     @description, @ord_qty, @dest_bin,  
		   @topick,  @part_no,   @lot_ser, @bin_no,      @item_note, @tran_id, @carton_id	-- v5.1  

		-- v5.7 START -  Code copied from end of cursor as it needs to be called if the print ticket is skipping a consolidated case pick

			  -- START v5.1
			  -- If we have changed to a new carton
			  IF ISNULL(@carton_id,@prev_carton_id) <> @prev_carton_id
			  BEGIN
				-- If we've printed something for the previous carton on this page
				IF @printed_on_the_page > 1
				BEGIN
					-- Pad out the page with blanks lines 
					SET @reqd_lines = @max_details_on_page - (@printed_on_the_page - 1)
					EXEC dbo.CVO_pad_print_ticket_sp @reqd_lines, @printed_on_the_page

					-- Print footer
					-------------- Now let's insert the Footer into the output table -------------------------------------------------  
					INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_PAGE_NO,' + RTRIM(CAST(@page_no AS char(4)))+' of '+ RTRIM(CAST(@total_pages AS char(4)))  
					INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_TOTAL_PAGES,' + RTRIM(CAST(@total_pages AS char(4)))  
					INSERT INTO #tdc_print_ticket (print_value) SELECT '*PRINTERNUMBER,' + @printer_id  
					INSERT INTO #tdc_print_ticket (print_value) SELECT '*QUANTITY,1'  
					INSERT INTO #tdc_print_ticket (print_value) SELECT '*DUPLICATES,'    + RTRIM(CAST(@number_of_copies AS char(4)))  
					INSERT INTO #tdc_print_ticket (print_value) SELECT '*PRINTLABEL'  

					IF (@@ERROR <> 0 )  
					BEGIN  
						CLOSE      detail_cursor  
						DEALLOCATE detail_cursor  
						CLOSE      print_cursor  
						DEALLOCATE print_cursor  
						RAISERROR ('Insert into #tdc_print_ticket Failed', 16, 5)       
						RETURN  
					END  
					-------------------------------------------------------------------------------------------------------------------  
			     
					-- Next Page  
					SELECT @page_no = @page_no + 1  
					SELECT @printed_on_the_page = 0  
			  
					-- START v5.5
					IF ((@printed_details_cnt -1) < @details_count)  
					--IF (@printed_details_cnt < @details_count)  
					-- END v5.5
					BEGIN  
						-------------- Now let's insert the Header into the output table -----------------  
						INSERT INTO #tdc_print_ticket (print_value) SELECT '*FORMAT,' + @format_id   
						INSERT INTO #tdc_print_ticket (print_value) SELECT data_field + ',' + data_value FROM #PrintData  
					 
						IF (@@ERROR <> 0 )  
						BEGIN  
							CLOSE      detail_cursor  
							DEALLOCATE detail_cursor  
							CLOSE      print_cursor  
							DEALLOCATE print_cursor  
							RAISERROR ('Insert into #tdc_print_ticket Failed', 16, 6)       
							RETURN  
						END  
						-----------------------------------------------------------------------------------------------  
					END    
			    
					SELECT @printed_on_the_page = @printed_on_the_page + 1  
					SET @prev_carton_id = @carton_id
					SET @display_carton = @display_carton + 1 -- v5.4
				END
				-- START v5.8
				ELSE
				BEGIN
					SET @prev_carton_id = @carton_id
					SET @display_carton = @display_carton + 1
				END
				-- END v5.8

			  END

				-- v5.7 END		

			CONTINUE
		END	

		-- v1.1 Case Part Consolidation - End 
	  
	  -- Order detail additional note  	    
	  IF @detail_add_note IS NULL SET @detail_add_note = ''  
	    
	  SELECT @prt_line_no = ''

	  SELECT @sku_code = isnull(sku_code, ''), @height = height, @width = width, @length = length, @cmdty_code = isnull(cmdty_code, ''),   
	   @weight_ea = weight_ea, @so_qty_increment = isnull(so_qty_increment, 0), @cubic_feet = cubic_feet   
	   FROM inv_master (nolock) WHERE part_no = @part_no  
	     
	  SELECT @category_1 = isnull(category_1, ''), @category_2 = isnull(category_2, ''), @category_3 = isnull(category_3, ''),   
	   @category_4 = isnull(category_4, ''), @category_5 = isnull(category_5, '')   
	   FROM inv_master_add (nolock) WHERE part_no = @part_no  
	  
	  -- Remove the '0' after the '.'  
	  EXEC tdc_trim_zeros_sp @ord_qty OUTPUT  
	  EXEC tdc_trim_zeros_sp @topick  OUTPUT 
	  EXEC tdc_trim_zeros_sp @ConQty  OUTPUT 
	  EXEC tdc_parse_string_sp @item_note,       @item_note       OUTPUT   
	  EXEC tdc_parse_string_sp @description,     @description     OUTPUT   
	  EXEC tdc_parse_string_sp @detail_add_note, @detail_add_note OUTPUT  
	  
	  -------------- Now let's insert the Details into the output table -----------------     
		--BEGIN SED009 -- Pick List/Invoice & Pack List/Inovoice
		--JVM 09/14/2010 
			DECLARE @list_price  VARCHAR (40)
			DECLARE @gross_price VARCHAR (40), @net_price VARCHAR (40), @discount_amount VARCHAR (40), @discount_pct VARCHAR (40)

			SET @list_price      = ''
			SET @gross_price     = ''
			SET @net_price	   = ''
			SET @discount_amount = ''
			SET @discount_pct	   = ''

		  
			-- START v5.6
			IF @is_autopack = 1
			BEGIN
				INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_CARTON_NO,Carton: ' + CAST(@display_carton AS VARCHAR)) 
			END
			ELSE
			BEGIN
				INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_CARTON_NO,')
			END
			-- END v5.6

			INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_LIST_PRICE_'      + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + @list_price      )   
			INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_GROSS_PRICE_'     + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + @gross_price     )   
			INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_NET_PRICE_'       + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + @net_price       )   
			INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_DISCOUNT_AMOUNT_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + @discount_amount )   		  
			INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_DISCOUNT_PCT_'	 + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + @discount_pct )   		  
		--END   SED009 -- Pick List/Invoice & Pack List/Inovoice

	   -- v1.1 Case Part Consolidation
	  IF @ConSet = 1
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_LINE_NO_'      + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + isnull(@str_line,  '')  
	  ELSE
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_LINE_NO_'      + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',Multiple'

	--  INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_LINE_NO_'      + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + isnull(CAST(@line_no AS varchar(4)),  '')  

	-- v4.0
	  INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_DISPLAY_LINE_NO_'      + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',Multiple'
	-- v4.0

	  INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_PART_TYPE_'    + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + isnull(@part_type,                '')     
	  INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_UOM_'           + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + isnull(@uom,             '')  
	  INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_DESCRIPTION_'   + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + isnull(@description,     '')  
	  INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_DETAIL_ADD_NOTE_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + isnull(@detail_add_note,   '')  

	   -- v1.1 Case Part Consolidation
	  IF @ConSet = 1 --AND @is_autopack = 0	-- v5.1 -- v5.2 removed
	  BEGIN
		  INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_ORD_QTY_'      + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + isnull(CAST(@ConQty AS varchar(20)),           '')  
		  INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_TOPICK_'       + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + isnull(CAST(@ConQty AS varchar(20)),           '')  
	  END
	  ELSE
	  BEGIN
		  INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_ORD_QTY_'      + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + isnull(@ord_qty,           '')  
		  INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_TOPICK_'       + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + isnull(@topick,           '')  
	  END

	  INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_PART_NO_'      + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + isnull(@part_no,           '')  
	  INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_LOT_SER_'      + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + isnull(@lot_ser,                      '')  
	  INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_BIN_NO_'       + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + isnull(@bin_no,                       '')  
	  INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_ITEM_NOTE_'  + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + isnull(@item_note,                    '')  

	  -- v5.9 Start
		IF @autopick_cases = 1
		BEGIN
			-- Check if this is a related case which will be autopicked
			IF EXISTS(	SELECT 1 FROM dbo.cvo_masterpack_consolidation_picks a (NOLOCK)
						INNER JOIN dbo.tdc_pick_queue b (NOLOCK)
						ON a.child_tran_id = b.tran_id 
						INNER JOIN dbo.cvo_ord_list c (NOLOCK)
						ON b.trans_type_no = c.order_no AND b.trans_type_ext = c.order_ext AND b.line_no = c.line_no
						JOIN dbo.tdc_pick_queue d (NOLOCK) -- v10.5
						ON a.parent_tran_id = d.tran_id -- v10.5
						WHERE a.parent_tran_id = @tran_id AND c.is_case = 1 AND d.company_no IS NULL) -- v10.5
			BEGIN
				SET @tran_id = ''
			END
		END 
	-- v5.9 End

	  INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_TRAN_ID_'      + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + isnull(@tran_id,                    '')  
	  INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_DEST_BIN_'     + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + isnull(@dest_bin,                     '')  
	  
	  INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_SKU_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@sku_code, '')  
	  INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_HEIGHT_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + CAST(@height AS varchar(20))  
	  INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_WIDTH_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + CAST(@width AS varchar(20))  
	  INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_CUBIC_FEET_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + CAST(@cubic_feet AS varchar(20))  
	  INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_LENGTH_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + CAST(@length AS varchar(20))  
	  INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_CMDTY_CODE_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@cmdty_code, '')  
	  INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_WEIGHT_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + CAST(@weight_ea AS varchar(20))  
	  INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_SO_QTY_INCR_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + CAST(@so_qty_increment AS varchar(20))  
	  INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_CATEGORY_1_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@category_1, '')  
	  INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_CATEGORY_2_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@category_2, '')  
	  INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_CATEGORY_3_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@category_3, '')  
	  INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_CATEGORY_4_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@category_4, '')  
	  INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_CATEGORY_5_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@category_5, '')  
	  
	  IF (@@ERROR <> 0 )  
	  BEGIN  
	   CLOSE      detail_cursor  
	   DEALLOCATE detail_cursor  
	   CLOSE      print_cursor  
	   DEALLOCATE print_cursor  
	   RAISERROR ('Insert into #tdc_print_ticket Failed', 16, 4)       
	   RETURN  
	  END  
	  -------------------------------------------------------------------------------------------------------------------  
	  
	  -- If we reached max detail lines on the page, print the Footer  
	  IF @printed_on_the_page = @max_details_on_page  
	  BEGIN  
	   -------------- Now let's insert the Footer into the output table -------------------------------------------------  
	   INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_PAGE_NO,' + RTRIM(CAST(@page_no AS char(4)))+' of '+ RTRIM(CAST(@total_pages AS char(4)))  
	   INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_TOTAL_PAGES,' + RTRIM(CAST(@total_pages AS char(4)))  
	   INSERT INTO #tdc_print_ticket (print_value) SELECT '*PRINTERNUMBER,' + @printer_id  
	   INSERT INTO #tdc_print_ticket (print_value) SELECT '*QUANTITY,1'  
	   INSERT INTO #tdc_print_ticket (print_value) SELECT '*DUPLICATES,'    + RTRIM(CAST(@number_of_copies AS char(4)))  
	   INSERT INTO #tdc_print_ticket (print_value) SELECT '*PRINTLABEL'  
	  
	   IF (@@ERROR <> 0 )  
	   BEGIN  
		CLOSE      detail_cursor  
		DEALLOCATE detail_cursor  
		CLOSE      print_cursor  
		DEALLOCATE print_cursor  
		RAISERROR ('Insert into #tdc_print_ticket Failed', 16, 5)       
		RETURN  
	   END  
	   -------------------------------------------------------------------------------------------------------------------  
	     
	   -- Next Page  
	   SELECT @page_no = @page_no + 1  
	   SELECT @printed_on_the_page = 0  
	  
	   IF (@printed_details_cnt < @details_count)  
	   BEGIN  
		-------------- Now let's insert the Header into the output table -----------------  
		INSERT INTO #tdc_print_ticket (print_value) SELECT '*FORMAT,' + @format_id   
		INSERT INTO #tdc_print_ticket (print_value) SELECT data_field + ',' + data_value FROM #PrintData  
	     
		IF (@@ERROR <> 0 )  
		BEGIN  
		 CLOSE      detail_cursor  
		 DEALLOCATE detail_cursor  
		 CLOSE      print_cursor  
		 DEALLOCATE print_cursor  
		 RAISERROR ('Insert into #tdc_print_ticket Failed', 16, 6)       
		 RETURN  
		END  
		-----------------------------------------------------------------------------------------------  
	   END  
	  END  
	    
	  --Next Detail Line  
	  SELECT @printed_details_cnt = @printed_details_cnt + 1  
	  SELECT @printed_on_the_page = @printed_on_the_page + 1  
	  
	  FETCH NEXT FROM detail_cursor INTO   
	   @line_no, @part_type, @uom,     @description, @ord_qty, @dest_bin,  
	   @topick,  @part_no,   @lot_ser, @bin_no,      @item_note, @tran_id, @carton_id	-- v5.1 

	  -- START v5.1
	  -- If we have changed to a new carton
	  IF ISNULL(@carton_id,@prev_carton_id) <> @prev_carton_id
	  BEGIN
		-- If we've printed something for the previous carton on this page
		IF @printed_on_the_page > 1
		BEGIN
			-- Pad out the page with blanks lines 
			SET @reqd_lines = @max_details_on_page - (@printed_on_the_page - 1)
			EXEC dbo.CVO_pad_print_ticket_sp @reqd_lines, @printed_on_the_page

			-- Print footer
			-------------- Now let's insert the Footer into the output table -------------------------------------------------  
			INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_PAGE_NO,' + RTRIM(CAST(@page_no AS char(4)))+' of '+ RTRIM(CAST(@total_pages AS char(4)))  
			INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_TOTAL_PAGES,' + RTRIM(CAST(@total_pages AS char(4)))  
			INSERT INTO #tdc_print_ticket (print_value) SELECT '*PRINTERNUMBER,' + @printer_id  
			INSERT INTO #tdc_print_ticket (print_value) SELECT '*QUANTITY,1'  
			INSERT INTO #tdc_print_ticket (print_value) SELECT '*DUPLICATES,'    + RTRIM(CAST(@number_of_copies AS char(4)))  
			INSERT INTO #tdc_print_ticket (print_value) SELECT '*PRINTLABEL'  

			IF (@@ERROR <> 0 )  
			BEGIN  
				CLOSE      detail_cursor  
				DEALLOCATE detail_cursor  
				CLOSE      print_cursor  
				DEALLOCATE print_cursor  
				RAISERROR ('Insert into #tdc_print_ticket Failed', 16, 5)       
				RETURN  
			END  
			-------------------------------------------------------------------------------------------------------------------  
	     
			-- Next Page  
			SELECT @page_no = @page_no + 1  
			SELECT @printed_on_the_page = 0  
	  
			-- START v5.5
			IF ((@printed_details_cnt -1) < @details_count)  
			--IF (@printed_details_cnt < @details_count)  
			-- END v5.5
			BEGIN  
				-------------- Now let's insert the Header into the output table -----------------  
				INSERT INTO #tdc_print_ticket (print_value) SELECT '*FORMAT,' + @format_id   
				INSERT INTO #tdc_print_ticket (print_value) SELECT data_field + ',' + data_value FROM #PrintData  
			 
				IF (@@ERROR <> 0 )  
				BEGIN  
					CLOSE      detail_cursor  
					DEALLOCATE detail_cursor  
					CLOSE      print_cursor  
					DEALLOCATE print_cursor  
					RAISERROR ('Insert into #tdc_print_ticket Failed', 16, 6)       
					RETURN  
				END  
				-----------------------------------------------------------------------------------------------  
			END    
	    
			SELECT @printed_on_the_page = @printed_on_the_page + 1  
			SET @prev_carton_id = @carton_id
			SET @display_carton = @display_carton + 1 -- v5.4
		END
		-- START v5.8
		ELSE
		BEGIN
			SET @prev_carton_id = @carton_id
			SET @display_carton = @display_carton + 1
		END
		-- END v5.8
	  END	-- IF ISNULL(@carton_id,@prev_carton_id) <> @prev_carton_id
	 END  
	  
	 CLOSE      detail_cursor  
	 DEALLOCATE detail_cursor  
	  
	 IF @page_no - 1 <> @total_pages  
	 BEGIN  
	  -------------- Now let's insert the Footer into the output table -------------------------------------------------  
	  INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_PAGE_NO,'     + RTRIM(CAST(@page_no AS char(4)))+' of '+ RTRIM(CAST(@total_pages AS char(4)))   
	  INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_TOTAL_PAGES,' + RTRIM(CAST(@total_pages AS char(4)))  
	  INSERT INTO #tdc_print_ticket (print_value) SELECT '*PRINTERNUMBER,' + @printer_id  
	  INSERT INTO #tdc_print_ticket (print_value) SELECT '*QUANTITY,'      + RTRIM(CAST(@number_of_copies AS char(3)))  
	  INSERT INTO #tdc_print_ticket (print_value) SELECT '*PRINTLABEL'  
	  
	  IF (@@ERROR <> 0 )  
	  BEGIN  
	   CLOSE      print_cursor  
	   DEALLOCATE print_cursor  
	   RAISERROR ('Insert into #tdc_print_ticket Failed', 16, 7)    
	   RETURN  
	  END  
	  -----------------------------------------------------------------------------------------------  
	 END  
	  
	 FETCH NEXT FROM print_cursor INTO @format_id, @printer_id, @number_of_copies  
	END  
	  
	CLOSE      print_cursor  
	DEALLOCATE print_cursor  
	DROP TABLE #pick_ticket	-- v5.2

	-- v5.9 Start
	IF @autopick_cases = 1
	BEGIN
		DROP TABLE #cvo_ord_list
	END
	-- v5.9 End

	-- v10.4 Start
	CREATE TABLE #cvo_chk_bo_print (
		row_id		int IDENTITY(1,1),
		order_no	int,
		order_ext	int)

	INSERT	#cvo_chk_bo_print (order_no, order_ext)
	SELECT	order_no, order_ext
	FROM	#cons_orders

	SET @row_id = 0
	WHILE 1=1 
	BEGIN	
		SELECT	TOP 1 @row_id = row_id,
				@c_order_no = order_no,
				@c_ext = order_ext
		FROM	#cvo_chk_bo_print
		WHERE	row_id > @row_id
		ORDER BY row_id ASC

		IF @@ROWCOUNT = 0
			BREAK

		EXEC dbo.cvo_update_bo_processing_sp 'P', @c_order_no, @c_ext
	END
	
	DROP TABLE #cvo_chk_bo_print
	-- v10.4 End
	  
	RETURN 
END
GO

GRANT EXECUTE ON  [dbo].[cvo_print_plw_so_consolidated_pick_ticket_sp] TO [public]
GO
