SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v20.0 CT 24/04/2014 - Based on tdc_print_ord_pack_list_sp, comments below for that SP
-- v20.1 CT 11/07/2014 - Fix for weight logic
-- v20.2 CT 11/07/2014 - Fix for total due amount
-- v20.3 tag 10/8/2014 - add invoice notes in sub-header
-- v20.4 CT 20/10/2014 - Issue #1367 - If net price > list price, set list = net and discount = 0
/*
-- v1.0 CB 04/04/2011 - 6.Consolidation
-- v6.0 TM 3/22/2012  - Add Invoice Number
-- v6.1 TM 3/26/2012  - Additional Changes for Invoice change
-- v6.2 CB 27/06/2012 -  Add in writing to the cvo_invoice_audit table
-- v6.3 CB 09/07/2012 - Fix rounding issues amt_disc from cvo_ord_list always needs to be rounded
-- v6.4 CB 13/07/2012 - Write the invoice date to cvo_order_invoice
-- v6.5 CB 17/07/2012 - Use the shipping total for freight & tax
-- v10.1 CB 19/07/2012 - CVO-CF-1 -  Custom Frame Processing - Mark Custom Frame lines as CUSTOMIZED
-- v6.6 CT 13/08/2012 - Don't group order lines by part_no
-- v10.2 CB 10/07/2012 - Issue #755 - Print frames first then cases
-- v10.3 CB 08/11/2012 - Remove number from custom frame notation
-- v10.4 CT 04/12/2012 - Add invoice note
-- v10.5 CB 06/12/2012 - If more than one format specified then temp table needs recreating
-- v10.6 CB 17/01/2013 - Issue #1106 - LP_SHIP_TOT and LP_TOT_BO should only include frames and suns
-- v10.7 CB 20/06/2013 - Issue #965 - Use total_tax instead of tot_ord_tax
-- v10.8 CB 10/07/2013 - Issue #927 - Buying Group Switching
-- v10.9 CT 21/10/2013 - Issue #1373 - extend tracking no to 30 characters
-- v11.0 CT 05/11/2013 - Issue #864 - Printing promo credit details
-- v11.1 CB 05/03/2015 - Fix issue with LP_CONS_TEXT appearing after PRINTLABEL
-- v11.2 CB 05/05/2015 - Issue #1538 - Not displaying free frames correctly for BGs
-- v11.3 CB 13/05/2015 - Issue #1446 - Add invoice notes from customer
-- v11.4 CB 01/07/2015 - Fix issue when free frames are given on a bg with bg inv option set
-- v11.5 CB 08/09/2015 - As per Tine - They want to see the gross price (list price) as whatever it is (non-zero), and the net price to show as $0.
-- v11.6 CB 03/12/2015 - Fix for BG customer set to regular invoice
-- v11.7 CB 24/05/2016 - Fix code for pulling back promo name
-- v11.8 CB 24/08/2016 - CVO-CF-49 - Dynamic Custom Frames
-- v11.9 CB 12/01/2017 - Recalc tax and totals

*/

CREATE PROCEDURE [dbo].[cvo_masterpack_print_consolidated_invoice_sp]( @user_id				VARCHAR(50),  
																   @station_id			VARCHAR(20),  
																   @consolidation_no	INT)  

-- exec [cvo_masterpack_print_consolidated_invoice_sp] 'cvoptical\tgraziosi','222','422'

AS
BEGIN
	SET NOCOUNT ON
	DECLARE @carton_no            int,         @Carton_Total   int,  
			@Airbill_No           varchar (18), @Carton_Class      char    (10),   
			@Carton_Ship_Date     varchar (30), @Carton_Type       char    (10),    
			@Cust_Addr1           varchar (40),  @Cust_Addr2   varchar (40),    
			@Cust_Addr3           varchar (40),   @Cust_Addr4   varchar (40),    
			@Cust_Addr5          varchar (40),   @Order_Plus_Ext  varchar (20),  
			@Addr1                varchar (40), @Addr2    varchar (40),  
			@Attention        varchar (40), @Cust_Code   varchar (40),  
			@Cust_Name           varchar (40), @Cust_Po   varchar (40),  
			@Date_Shipped         varchar (30), @Freight_Description  varchar (20),  
			@Freight_Allow_Type   varchar (20), @Item_Description    varchar (275),  
			@Line_No         int,         @Lot_Ser   varchar (30),  
			@Location        varchar (20), @Note    varchar (275),  
			@part_no      varchar (35), @who_entered  varchar (50),  
			@Req_Ship_Date   varchar (30), @Routing   varchar (30),  
			@Sch_Ship_Date   varchar (30), @Shipper   varchar (10),  
			@Ship_To_Add_1   varchar (40), @Ship_To_Add_2   varchar (40),  
			@Ship_To_Add_3   varchar (40), @Ship_To_Add_4   varchar (40),  
			@Ship_To_Add_5   varchar (40), @Ship_To_City   varchar (40),  
			@Ship_To_Country  varchar (40), @Ship_To_Name   varchar (40),  
			@Ship_To_No   varchar (10), @Ship_To_Region  varchar (10),  
			@Ship_To_State   char    (40), @Ship_To_Zip   varchar (10),  
			@Special_Instr   varchar (275), @Sum_Pack_Qty   varchar (20), 
			-- START v10.9  
			@Tracking_No   varchar (30),   @UPC_Code   varchar (40),   
			-- @Tracking_No   varchar (25),   @UPC_Code   varchar (40),   
			-- END v10.9
			@Weight_Carton   varchar (20),   @Weight_UOM_Carton  char    (3),   
			@Weight       varchar (20),   @Weight_UOM    varchar (2),  
			@format_id              varchar (40),   @printer_id             varchar (30),  
			@details_count   int,            @max_details_on_page    int,              
			@printed_details_cnt    int,            @total_pages            int,    
			@page_no                int,            @number_of_copies       int,  
			@trans   varchar (15),   @Sum_Ordered_Qty        varchar (20),  
			@back_ord_flag         char    (1),    @zone_desc  varchar (40),  
			@dest_zone_code      varchar (8),    @salesperson_name       varchar (40),  
			@salesperson      varchar (10),   @insert_value           varchar (300),  
			@return_value  int,  @terms_desc  varchar (300),  
			@terms   varchar (10),   @printed_on_the_page    int,  
			@cust_part_no  varchar (30), @drawing_no  varchar (30) ,  
			@Sum_Qty_Short          varchar (20),   @header_add_note varchar (255),
			@order_date	varchar(30),  @order_type varchar(30), @li_note varchar(10),						--v2.0  
			@Tot_qty_ship	varchar(30),  @tot_qty_bo varchar(10), @bg_message varchar(100),					--v2.0  
			@invoice_num	varchar(16),	@invoice_date	varchar(12),										--v6.0
			@caller	varchar(60),																			--v6.0
			@invoice_note VARCHAR(255),																			-- v10.4
			@parent varchar(10), @current_parent varchar(10), -- v10.8
			@rec_id				INT,
			@order_no			INT,
			@order_ext			INT,
			@cons_text			VARCHAR(1000),
			@free_shipping		VARCHAR(30),
			@orders_count		SMALLINT,
			@promo_count		SMALLINT,
			@f_order_total		DECIMAL(20,8),
			@cons_order_tax		DECIMAL(20,2),
			@cons_order_frt		DECIMAL(20,2),
			@cons_order_gross	DECIMAL(20,2),
			@cons_order_disc	DECIMAL(20,2),
			@cons_order_net		DECIMAL(20,2),
			@cons_order_total	DECIMAL(20,2),
			@new_order_totals	SMALLINT,
			@added_freight		SMALLINT
			-- 100814 tag - add notes
			,@notes_count_1		smallint
			,@notes_count_2		smallint
			,@invoice_note_1	varchar(130)
			,@invoice_note_2	varchar(130)

	-- DECLARE	@custom_count int -- v10.1 v10.3
	DECLARE @sku_code VARCHAR(16), @height DECIMAL(20,8), @width DECIMAL(20,8), @cubic_feet DECIMAL(20,8),  
			@length DECIMAL(20,8), @cmdty_code VARCHAR(8), @weight_ea DECIMAL(20,8), @so_qty_increment DECIMAL(20,8),   
			@category_1 VARCHAR(15), @category_2 VARCHAR(15), @category_3 VARCHAR(15), @category_4 VARCHAR(15), @category_5 VARCHAR(15)   
	  
	DECLARE @promo_name varchar(30), @BG_Name varchar(40), @Cust_Type varchar(40)	--v2.0				-- T McGrady	22.MAR.2011
	DECLARE @Sum_Line_Ship Decimal(20,8)		--v4.0

	-- START v6.6
	DECLARE @c_list_price		DECIMAL(20,2),
			@c_gross_price		DECIMAL(20,2), 
			@c_net_price		DECIMAL(20,2), 
			@c_ext_net_price	DECIMAL(20,2),
			@c_discount_amount	DECIMAL(20,2), 
			@c_discount_pct		DECIMAL(20,2)
	-- END v6.6

	DECLARE @is_credit SMALLINT -- v11.0

	DECLARE @is_free SMALLINT, -- v11.2
			@inv_option varchar(8), -- v11.4
			@row_id		int, -- v11.9
			@last_row_id int -- v11.9

	-- v10.2 Start
	CREATE TABLE #part_type (
		part_type	varchar(20),
		printorder	int)

	INSERT	#part_type
	SELECT	'FRAME', 0
	INSERT	#part_type
	SELECT	'SUN', 0

	INSERT	#part_type
	SELECT	kys, 1
	FROM	part_type (NOLOCK)
	WHERE	kys NOT IN ('FRAME','SUN')
	-- v10.2 End

	-- v11.9 Start
	CREATE TABLE #orders_to_process_recalc (
		row_id		int IDENTITY(1,1),
		order_no	int,
		order_ext	int)

	INSERT	#orders_to_process_recalc (order_no, order_ext)
	SELECT	order_no, order_ext
	FROM	dbo.cvo_masterpack_consolidation_det (NOLOCK)
	WHERE	consolidation_no = @consolidation_no

	SET @last_row_id = 0

	SELECT	TOP 1 @row_id = row_id,
			@order_no = order_no,
			@order_ext = order_ext
	FROM	#orders_to_process_recalc
	WHERE	row_id > @last_row_id
	ORDER BY row_id ASC

	WHILE (@@ROWCOUNT <> 0)
	BEGIN
		EXEC dbo.fs_calculate_oetax_wrap @order_no, @order_ext, 0, 1 
		EXEC dbo.fs_updordtots @order_no, @order_ext	

		SET @last_row_id = @row_id

		SELECT	TOP 1 @row_id = row_id,
				@order_no = order_no,
				@order_ext = order_ext
		FROM	#orders_to_process_recalc
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC
	END
	
	DROP TABLE #orders_to_process_recalc
	-- v11.9 End


	-- Get an order from the consolidation set, so we can pull back order header details
	SELECT TOP 1
		@order_no = order_no,
		@order_ext = order_ext
	FROM
		dbo.cvo_masterpack_consolidation_det (NOLOCK)
	WHERE
		consolidation_no = @consolidation_no

	----------------- Header Data --------------------------------------  
	  
	-- Now retrieve the Orders information  
	SELECT  @Order_Plus_Ext  = (CAST(@order_no  AS varchar(10)) + '-' + CAST  (@order_ext  AS varchar(10))),  
	 @Attention          = orders.attention,   
	 @Cust_Addr1         = arcust.addr1,   
	 @Cust_Addr2         = arcust.addr2,  
	 @Cust_Addr3         = arcust.addr3,   
	 @Cust_Addr4         = arcust.addr4,   
	 @Cust_Addr5         = arcust.addr5,   
	 @Cust_Code          = orders.cust_code,   
	 @Cust_Name          = arcust.customer_name,    
	 @Cust_PO            = orders.cust_po,   
	 @Date_Shipped       = orders.date_shipped,   
	 @Freight_Allow_Type = orders.freight_allow_type,  
	 @Location           = orders.location,  
	 @Note				 = REPLACE(orders.note, CHAR(13), '/'),
	 @order_date		 = orders.date_entered,					--v2.0   
	 @Req_Ship_Date      = orders.req_ship_date,             
	 @Routing            = arshipv.addr1,						--v2.0		--orders.routing,    
	 @Sch_Ship_Date      = orders.sch_ship_date,  
	 @Ship_To_Add_1      = orders.ship_to_add_1,  
	 @Ship_To_Add_2      = orders.ship_to_add_2,   
	 @Ship_To_Add_3      = orders.ship_to_add_3,  
	 @Ship_To_Add_4      = orders.ship_to_add_4,   
	 @Ship_To_Add_5      = orders.ship_to_add_5,  
	 @Ship_To_City       = orders.ship_to_city,     
	 @Ship_To_Country    = orders.ship_to_country,  
	 @Ship_To_Name       = orders.ship_to_name,   
	 @Ship_To_Region     = orders.ship_to_region,    
	 @Ship_To_State      = orders.ship_to_state,     
	 @Ship_To_Zip        = orders.ship_to_zip,       
	 --@Special_Instr      = REPLACE(orders.special_instr, CHAR(13), '/'),    
	 @salesperson        = orders.salesperson,       
	 @dest_zone_code     = orders.dest_zone_code,  
	 @back_ord_flag      = orders.back_ord_flag,  
	 @ship_to_no         = orders.ship_to,  
	 @terms              = orders.terms,  
	 @who_entered		 = orders.who_entered,
	 @order_type		 = cat.category_desc,			--v2.0
	 @caller			 = ISNULL(orders.user_def_fld2,'')			--v6.0
	  FROM  tdc_order   (NOLOCK)  
	 INNER  JOIN orders (NOLOCK) ON tdc_order.order_no = orders.order_no AND tdc_order.order_ext = orders.ext
	  LEFT  OUTER JOIN arcust (NOLOCK) ON orders.cust_code = arcust.customer_code
	  LEFT  OUTER JOIN arshipv (NOLOCK) ON orders.routing = arshipv.ship_via_code				--v2.0
	  LEFT  OUTER JOIN so_usrcateg cat (NOLOCK) ON orders.user_category = cat.category_code		--v2.0
	 WHERE  tdc_order.order_no   = @order_no  
	   AND  tdc_order.order_ext  = @order_ext      
	
 
	--BEGIN SED008 -- Global Ship To
	--JVM 07/28/2010
	IF EXISTS(SELECT sold_to FROM orders (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext AND sold_to IS NOT NULL AND LTRIM (sold_to) <> '' AND RTRIM (sold_to) <> '')
	BEGIN
		SELECT	@ship_to_no         = a.ship_to_code,		       
				@Ship_To_Name       = a.address_name, 
				@Ship_To_Add_1      = a.addr2,  
				@Ship_To_Add_2      = a.addr3,   
				@Ship_To_Add_3      = a.addr4,  
				@Ship_To_Add_4      = a.addr5,   
				@Ship_To_Add_5      = a.addr6,  
				@Ship_To_City       = a.city,     
				@Ship_To_Country	= a.country_code,   
				@Ship_To_Region     = a.territory_code,    
				@Ship_To_State      = a.state,     
				@Ship_To_Zip        = a.postal_code  
		FROM    armaster_all a  (NOLOCK)
		WHERE   a.customer_code = (SELECT sold_to FROM orders (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext ) AND
				address_type = 9
	END	  
	--END   SED008 -- Global Ship To    
	  
	--Now retrieve Location information  
	SELECT @Addr1 = addr1, @Addr2 = addr2  FROM locations (NOLOCK) WHERE location = @Location  
	  
	--Now retrieve Freight Type information  
	SELECT @Freight_Description = [description] FROM freight_type (NOLOCK) WHERE kys = ISNULL(@Freight_Allow_Type, '')  
	  
	--Now retrieve salesperson information  
	SELECT @salesperson_name = salesperson_name FROM arsalesp (NOLOCK) WHERE salesperson_code = ISNULL(@salesperson, '')  
	  
	--Now retrieve zone information   
	SELECT @zone_desc = zone_desc FROM arzone (NOLOCK) WHERE zone_code = ISNULL(@dest_zone_code, '')  
	  
	--Now retrieve terms information   
	SELECT @terms_desc = terms_desc FROM arterms (NOLOCK) WHERE terms_code = ISNULL(@terms, '')  
	  
	-- Retrieve the total number of cartons,calculate the weight associated with   
	-- the cartons for this order_no, order_ext, & retrieve the weight_uom.  
	SELECT @Carton_Total =   
	 (SELECT COUNT (DISTINCT a.carton_no) FROM tdc_carton_tx a(NOLOCK)  
			INNER JOIN dbo.cvo_masterpack_consolidation_det b (NOLOCK)	
			ON a.order_no = b.order_no AND a.order_ext = b.order_ext
			WHERE b.consolidation_no = @consolidation_no  
		 AND a.[status]    = 'C'       AND a.order_type = 'S' )  
	  +   
	 (SELECT COUNT (DISTINCT tdc_carton_tx.carton_no) FROM tdc_stage_carton (NOLOCK)  
			INNER JOIN tdc_carton_tx (NOLOCK) 
			ON tdc_stage_carton.carton_no = tdc_carton_tx.carton_no 	
			INNER JOIN dbo.cvo_masterpack_consolidation_det mpc (NOLOCK)
			ON tdc_carton_tx.order_no = mpc.order_no AND tdc_carton_tx.order_ext = mpc.order_ext
			WHERE mpc.consolidation_no = @consolidation_no
			AND tdc_carton_tx.status   = 'S'       AND tdc_stage_carton.adm_ship_flag = 'N'  
			AND tdc_carton_tx.order_type = 'S')  
	
	-- START v20.1  
	SELECT 
	--	@Weight       = CAST(SUM(a.weight) AS varchar (20)),   
		@Weight_UOM   = MAX(a.weight_uom)  
	FROM 
		dbo.tdc_carton_tx a (NOLOCK)
	INNER JOIN 
		dbo.cvo_masterpack_consolidation_det b (NOLOCK)	
	ON 
		a.order_no = b.order_no 
		AND a.order_ext = b.order_ext
	WHERE 
		b.consolidation_no = @consolidation_no   
	 	AND a.order_type = 'S'  

	SELECT DISTINCT
		a.carton_no,
		a.weight
	INTO 
		#weight_calc
	FROM 
		dbo.tdc_carton_tx a (NOLOCK)
	INNER JOIN 
		dbo.cvo_masterpack_consolidation_det b (NOLOCK)	
	ON 
		a.order_no = b.order_no 
		AND a.order_ext = b.order_ext
	WHERE 
		b.consolidation_no = @consolidation_no   
	 	AND a.order_type = 'S' 

	SELECT
		@Weight       = CAST(SUM(weight) AS varchar (20))
	FROM
		#weight_calc

	DROP TABLE #weight_calc
	-- END v20.1
	  
	-- Remove the '0' after the '.'  
	EXEC tdc_trim_zeros_sp @Weight OUTPUT  
	EXEC tdc_parse_string_sp @Special_Instr, @Special_Instr output   
	EXEC tdc_parse_string_sp @terms_desc,    @terms_desc    output   
	EXEC tdc_parse_string_sp @Note,          @Note          output   
	
	/*  
	-- Order header additional note  
	SELECT @header_add_note = CAST(note AS varchar(255))  
	  FROM notes (NOLOCK)  
	 WHERE code_type = 'O'  
	   AND code      = @order_no             
	   AND line_no   = 0  
	*/  
	IF @header_add_note IS NULL SET @header_add_note = ''  
	  
	EXEC tdc_parse_string_sp @header_add_note, @header_add_note OUTPUT  

	-- v10.8 Start
	SELECT	@current_parent = buying_group
	FROM	cvo_orders_all (NOLOCK)
	WHERE	order_no = @order_no
	AND		ext = @order_ext

	SELECT @parent = dbo.f_cvo_get_buying_group(@cust_code,GETDATE())

	IF (ISNULL(@current_parent,'') <> @parent)
	BEGIN
		UPDATE	cvo_orders_all
		SET		buying_group = @parent
		WHERE	order_no = @order_no
		AND		ext = @order_ext
	END

	SET @invoice_date = CONVERT(varchar(12),GETDATE(),101)

	-- v10.8 End
	 
	-------------- Now let's insert the Header information into #PrintData  --------------------------------------------  
	-------------- We are going to use this table in the tdc_print_label_sp --------------------------------------------  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ORDER_NO',        CAST  (@order_no  AS varchar(10) ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ORDER_EXT',       CAST  (@order_ext AS varchar(10) ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ORDER_PLUS_EXT',  'See Below')  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ORDER_TYPE',      'See Below')  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_INVOICE_NUM', 'See Below')				--v6.0
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ADDR1',           ISNULL(@addr1,         ''  ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ADDR2',           ISNULL(@addr2,         ''  ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ATTENTION',       ISNULL(@attention,         ''  ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CUST_CODE',       ISNULL(@cust_code,         ''  ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CUST_NAME',       ISNULL(@cust_name,         ''  ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CUST_ADDR1',      ISNULL(@cust_addr1,         ''  ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CUST_ADDR2',      ISNULL(@cust_addr2,         ''  ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CUST_ADDR3',      ISNULL(@cust_addr3,         ''  ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CUST_ADDR4',      ISNULL(@cust_addr4,         ''  ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CUST_ADDR5',      ISNULL(@cust_addr5,         ''  ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CUST_PO',         'See Below')  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_DATE_SHIPPED',    ISNULL(@date_shipped,        ''  ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ORDER_DATE',      'Multiple')  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_FREIGHT_DESCRIPTION', ISNULL(@freight_description, ''  ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_FREIGHT_ALLOW_TYPE',  ISNULL(@freight_allow_type,  ''  ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_LOCATION',        ISNULL(@location,            ''  ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_NOTE',            ISNULL(@note,                ''  ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_HEADER_ADD_NOTE', ISNULL(@header_add_note,     ''  ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_REQ_SHIP_DATE',   ISNULL(@req_ship_date,       ''  ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ROUTING',         ISNULL(@routing,             ''  ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SCH_SHIP_DATE',   ISNULL(@sch_ship_date,       ''  ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SHIP_TO_ADD_1',   ISNULL(@ship_to_add_1,       ''  ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SHIP_TO_ADD_2',   ISNULL(@ship_to_add_2,       ''  ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SHIP_TO_ADD_3',   ISNULL(@ship_to_add_3,       ''  ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SHIP_TO_ADD_4',   ISNULL(@ship_to_add_4,       ''  ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SHIP_TO_ADD_5',   ISNULL(@ship_to_add_5,       ''  ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SHIP_TO_CITY',    ISNULL(@ship_to_city,        ''  ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SHIP_TO_COUNTRY', ISNULL(@ship_to_country,     ''  ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SHIP_TO_NAME',    ISNULL(@ship_to_name,        ''  ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SHIP_TO_REGION',  ISNULL(@ship_to_region,      ''  ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SHIP_TO_STATE',   ISNULL(@ship_to_state,       ''  ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SHIP_TO_ZIP',     ISNULL(@ship_to_zip,         ''  ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SPECIAL_INSTR',   ISNULL(@special_instr,       ''  ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_USERID',          ISNULL(@user_id,             ''  ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CARTON_TOTAL',    CAST(@carton_total AS varchar(10)))    
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_WEIGHT_UOM',      ISNULL(@weight_uom,          ''  ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SALESPERSON',     ISNULL(@salesperson,         ''  ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SALESPERSON_NAME',	ISNULL(@salesperson_name,    ''  ))  
	--INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_DEST_ZONE_CODE',  ISNULL(@dest_zone_code,      ''  ))  
	--INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_DEST_ZONE_DESC',  ISNULL(@zone_desc,           ''  ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_BACK_ORD_FLAG',   ISNULL(@back_ord_flag,       ''  ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SHIP_TO_NO',      ISNULL(@ship_to_no,          ''  ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_TERMS',           ISNULL(@terms,               ''  ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_TERMS_DESC',      'See Below')  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_WHO_ENTERED',     ISNULL(@who_entered,         ''  )) 
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CALLER', ISNULL(@caller,''))		--v6.0
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CONSOLIDATED_ORDERS', 'Y')		
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_PROMO_NAME','See Below')
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_INVOICE_DATE', ISNULL(@invoice_date,''))			--v6.0	
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_WEIGHT',          ISNULL(@weight,              ''  ))
	--																									

	/*
	-- START v10.4 - get invoice note
	SELECT
		@invoice_note = ISNULL(REPLACE(invoice_note, CHAR(13) + CHAR(10), ' ') ,'')	
	FROM
		dbo.cvo_orders_all (NOLOCK)
	WHERE
		order_no = @order_no																		
		AND ext = @order_ext
	*/

	-- v11.3 Start
	SELECT	@invoice_note = b.comment_line + CASE WHEN ISNULL(@invoice_note,'') > '' THEN ' \ ' ELSE '' END + ISNULL(@invoice_note,'')
	FROM	arcust a (NOLOCK)
	JOIN	arcommnt b (NOLOCK)
	ON		a.inv_comment_code = b.comment_code
	WHERE	a.customer_code = @cust_code
	-- v11.3 End

	-- 4/11/2017 -- Invoice Note for SM reorders		
	IF (DATEPART(WEEKDAY,GETDATE())) = 2 -- only on Mondays
			AND GETDATE() BETWEEN '4/10/2017' AND '7/3/2017'
			AND CHARINDEX('FREE Shipping!',ISNULL(@invoice_note,'')) = 0 
	BEGIN
				SELECT @invoice_note = CASE WHEN ISNULL(@invoice_note,'') = ''
				THEN 'Place a Steve Madden reorder today and get FREE shipping!'
				ELSE ISNULL(@invoice_note,'') + CHAR(13) + CHAR(10) + 'Place a Steve Madden reorder today and get FREE shipping!' 
				END
	END

	-- v11.4 Start
	SELECT	@inv_option = ISNULL(alt_location_code,'')
	FROM	arcust (NOLOCK)
	WHERE	customer_code = @cust_code
	-- v11.4 End
	
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_INVOICE_NOTE',ISNULL(@invoice_note,' '))
	-- END v10.4

	--v2.0 Add Buying Group Name
	SELECT @BG_Name = customer_name, @Cust_Type = addr_sort1 
	FROM CVO_orders_all 
	 INNER JOIN arcust ON  buying_group = customer_code
	 WHERE order_no = @order_no AND ext = @order_ext AND buying_group is not null AND buying_group != ''

	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_BUYGRP_NAME', ISNULL(@BG_Name,'')) 
	--

	-- CVO - Need Order values for printing
	DECLARE @order_tax		Decimal(20,2),
			@order_frt		Decimal(20,2),
			@order_disc		Decimal(20,2),
			@order_gross	Decimal(20,2),
			@order_total	Decimal(20,2),
			@order_ext_list	Decimal(20,2),			--v6.1
			@order_tot_list	Decimal(20,2),			--v6.1
			@order_net		Decimal(20,2),
			@BG_Order		int

	SET @order_gross	= 0.00
	SET @order_tax		= 0.00
	SET @order_disc		= 0.00
	SET @order_frt		= 0.00
	SET @order_net		= 0.00
	SET @order_total	= 0.00
	SET @order_tot_list	= 0.00					--v6.1
	SET @order_ext_list	= 0.00					--v6.1

	SET @BG_Order	= 0

	IF EXISTS(SELECT buying_group FROM CVO_orders_all WHERE order_no = @order_no AND ext = @order_ext AND buying_group IS NOT NULL AND buying_group != '' )
	BEGIN
		IF @Cust_Type = 'Buying Group'
		BEGIN
			SELECT  @order_tax      = CAST(SUM(o.total_tax) AS DECIMAL (20,2)),
					@order_frt      = CAST(SUM(o.freight) AS DECIMAL (20,2)), -- v6.5
					@bg_message		= 'Please contact your buying group directly for all invoice, credit memo and payment inquiries.',
					@BG_Order		= 1
			FROM  dbo.orders o (nolock)
			INNER JOIN dbo.cvo_masterpack_consolidation_det b (NOLOCK)
			ON o.order_no = b.order_no AND o.ext = b.order_ext
			WHERE b.consolidation_no = @consolidation_no
		END
		ELSE
		BEGIN
			SELECT  @order_tax      = CAST(SUM(o.total_tax) AS DECIMAL (20,2)),
					@order_frt      = CAST(SUM(o.freight) AS DECIMAL (20,2)), 
					@bg_message		= ' ',
					@BG_Order		= 0
			FROM  orders o (nolock)
			INNER JOIN dbo.cvo_masterpack_consolidation_det b (NOLOCK)
			ON o.order_no = b.order_no AND o.ext = b.order_ext
			WHERE b.consolidation_no = @consolidation_no
		END
	END
	ELSE
	BEGIN
		SELECT  @order_tax      = CAST(SUM(o.total_tax) AS DECIMAL (20,2)),
				@order_frt      = CAST(SUM(o.freight) AS DECIMAL (20,2)), -- v6.5
				@bg_message		= ' ',
				@BG_Order		= 0
		FROM  orders o (nolock)
		INNER JOIN dbo.cvo_masterpack_consolidation_det b (NOLOCK)
		ON o.order_no = b.order_no AND o.ext = b.order_ext
		WHERE b.consolidation_no = @consolidation_no
	END


	SET @cons_order_tax = ISNULL(@order_tax,0)
	SET @cons_order_frt = ISNULL(@order_frt,0)
	SET @added_freight = 0

	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_BG_MESSAGE', ISNULL(@bg_message,' '))

	SELECT 
		@tot_qty_ship = ISNULL((SELECT CAST(SUM(a.pack_qty) AS varchar(20))),'') 
	FROM 
		dbo.tdc_carton_detail_tx a (NOLOCK)  
	INNER JOIN 
		dbo.inv_master b (NOLOCK) 
	ON 
		a.part_no = b.part_no
	INNER JOIN 
		dbo.cvo_masterpack_consolidation_det c (NOLOCK)
	ON 
		a.order_no = c.order_no 
		AND a.order_ext = c.order_ext
	WHERE 
		c.consolidation_no = @consolidation_no
		AND b.type_code IN ('FRAME','SUN')
	  
 

	SELECT 
		@tot_qty_bo =  ISNULL((SELECT CAST(SUM(ordered - shipped) AS varchar(20))),'') 
	FROM 
		dbo.ord_list a (NOLOCK) 
	INNER JOIN 
		dbo.inv_master b (NOLOCK) 
	ON 
		a.part_no = b.part_no
	INNER JOIN 
		dbo.cvo_masterpack_consolidation_det c (NOLOCK)
	ON 
		a.order_no = c.order_no 
		AND a.order_ext = c.order_ext
	WHERE 
		c.consolidation_no = @consolidation_no
		AND b.type_code IN ('FRAME','SUN')

	-- Remove the '0' after the '.'  
	EXEC tdc_trim_zeros_sp @tot_qty_ship OUTPUT  
	EXEC tdc_trim_zeros_sp @tot_qty_bo OUTPUT  

	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_TOT_SHIP', CAST(@tot_qty_ship AS VARCHAR(30)))
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_TOT_BO', CAST(@tot_qty_bo AS VARCHAR(30)))
	-- v10.6 End
	--V2.0

	DECLARE @LP_CONSOLIDATED_SHIPMENT VARCHAR(40)
	SET @LP_CONSOLIDATED_SHIPMENT = ' '

	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CONSOLIDATED_SHIPMENT', @LP_CONSOLIDATED_SHIPMENT)  	
	   
	IF (@@ERROR <> 0 )  
	BEGIN  
	 RAISERROR ('Insert into #PrintData Failed', 16, 1)       
	 RETURN  
	END  
	------------------------------------------------------------------------------------------------  
	-- Now let's run the tdc_print_label_sp to get format_id, printer_id, and number of copies -----  
	EXEC @return_value = tdc_print_label_sp 'PPS', 'ORDPACKTKT', 'VB', @station_id  
	  
	-- IF label hasn't been set up for the station id, try finding a record for the user id  
	IF @return_value != 0  
	BEGIN  
	 EXEC @return_value = tdc_print_label_sp 'PPS', 'ORDPACKTKT', 'VB', @user_id  
	END  
	  
	-- IF label hasn't been set up for the user id, exit  
	IF @return_value != 0  
	BEGIN  
	 TRUNCATE TABLE #PrintData  
	 RETURN  
	END  
	  
	------------------------------------------------------------------------------------------------  
	  
	-- Now let's get the 'Sub-Header' info which is: the list of all the cartons &  
	-- airbill_no, carton_class, carton_ship_date, carton_type, shipper, station_id,  
	-- tracking_no, weight_carton, weight_uom_carton  
	SELECT @printed_details_cnt = 1  
  
	-- Retrieve the closed cartons as well as the staged cartons   
	-- that have not been shipped according to ADM  
	DECLARE Cartons_on_Order_Cursor CURSOR FOR  
	SELECT DISTINCT
		a.carton_no,
		a.order_no,
		a.order_ext   
	FROM 
		dbo.tdc_carton_tx a(NOLOCK) 
	INNER JOIN 
		dbo.cvo_masterpack_consolidation_det b (NOLOCK)
	ON 
		a.order_no = b.order_no 
		AND a.order_ext = b.order_ext
	WHERE 
		b.consolidation_no = @consolidation_no 
		AND a.[status]     = 'C'  
		AND a.order_type = 'S'    
	UNION   
	SELECT DISTINCT
		tdc_carton_tx.carton_no,
		tdc_carton_tx.order_no,
		tdc_carton_tx.order_ext    
	FROM 
		tdc_stage_carton   (NOLOCK)  
	INNER JOIN 
		tdc_carton_tx (NOLOCK) 
	ON   
		tdc_stage_carton.carton_no = tdc_carton_tx.carton_no  
	INNER JOIN 
		dbo.cvo_masterpack_consolidation_det mpc (NOLOCK)
	ON 
		tdc_carton_tx.order_no = mpc.order_no 
		AND tdc_carton_tx.order_ext = mpc.order_ext
	WHERE 
		mpc.consolidation_no = @consolidation_no
		AND tdc_carton_tx.status           = 'S'  
		AND tdc_carton_tx.order_type       = 'S'  
		AND tdc_stage_carton.adm_ship_flag = 'N'  
	ORDER BY 
		carton_no,  
		order_no,
		order_ext
  


	OPEN Cartons_on_Order_Cursor   
	FETCH NEXT FROM Cartons_on_Order_Cursor INTO @carton_no, @order_no, @order_ext  
  
	WHILE (@@FETCH_STATUS = 0)  
	BEGIN   
		SELECT  @Airbill_No        = cs_airbill_no,   
		@Carton_Class      = carton_class,   
		@Carton_Ship_Date  = date_shipped,  
		@Carton_Type       = carton_type,  
		@Shipper           = shipper,   
		@station_ID        = station_id,  
		@Tracking_No       = cs_tracking_no,  
		@Weight_Carton     = CAST(weight AS varchar(20)),   
		@Weight_UOM_Carton = weight_uom  
		  FROM  tdc_carton_tx (NOLOCK)  
		WHERE  carton_no  = @carton_no  
		 AND  order_no   = @order_no  
		 AND  order_ext  = @order_ext  
		 AND  order_type = 'S'  
  
		-- Remove the '0' after the '.'  
		EXEC tdc_trim_zeros_sp @Weight_Carton OUTPUT  
  
		INSERT INTO #tdc_pack_ticket_sub_header(print_value) VALUES('LP_CARTON_NO_'         + RTRIM(CAST(@printed_details_cnt AS char(4))) + ',' + ISNULL(CAST(@carton_no AS varchar(10)), ''))  
		--INSERT INTO #tdc_pack_ticket_sub_header(print_value) VALUES('LP_AIRBILL_NO_'        + RTRIM(CAST(@printed_details_cnt AS char(4))) + ',' + ISNULL(@Airbill_No,        ''))  
		--INSERT INTO #tdc_pack_ticket_sub_header(print_value) VALUES('LP_CARTON_CLASS_'      + RTRIM(CAST(@printed_details_cnt AS char(4))) + ',' + ISNULL(@Carton_Class,      ''))  
		--INSERT INTO #tdc_pack_ticket_sub_header(print_value) VALUES('LP_CARTON_SHIP_DATE_'  + RTRIM(CAST(@printed_details_cnt AS char(4))) + ',' + ISNULL(@Carton_Ship_Date,  ''))  
		--INSERT INTO #tdc_pack_ticket_sub_header(print_value) VALUES('LP_CARTON_TYPE_'       + RTRIM(CAST(@printed_details_cnt AS char(4))) + ',' + ISNULL(@Carton_Type,       ''))  
		INSERT INTO #tdc_pack_ticket_sub_header(print_value) VALUES('LP_SHIPPER_'           + RTRIM(CAST(@printed_details_cnt AS char(4))) + ',' + ISNULL(@Shipper,           ''))  
		--INSERT INTO #tdc_pack_ticket_sub_header(print_value) VALUES('LP_STATION_ID_'        + RTRIM(CAST(@printed_details_cnt AS char(4))) + ',' + ISNULL(@station_ID,        ''))  
		--INSERT INTO #tdc_pack_ticket_sub_header(print_value) VALUES('LP_TRACKING_NO_'       + RTRIM(CAST(@printed_details_cnt AS char(4))) + ',' + ISNULL(@Tracking_No,       ''))  
		INSERT INTO #tdc_pack_ticket_sub_header(print_value) VALUES('LP_WEIGHT_CARTON_'     + RTRIM(CAST(@printed_details_cnt AS char(4))) + ',' + ISNULL(@Weight_Carton,     ''))  
		INSERT INTO #tdc_pack_ticket_sub_header(print_value) VALUES('LP_WEIGHT_UOM_CARTON_' + RTRIM(CAST(@printed_details_cnt AS char(4))) + ',' + ISNULL(@Weight_UOM_Carton, ''))  

		-- Next Detail Line  
		SELECT  @printed_details_cnt = @printed_details_cnt + 1  

		FETCH NEXT FROM Cartons_on_Order_Cursor INTO @carton_no, @order_no, @order_ext
	END  
  
	IF (@@ERROR <> 0 )  
	BEGIN  
		CLOSE      Cartons_on_Order_Cursor  
		DEALLOCATE Cartons_on_Order_Cursor  

		RAISERROR ('Insert into #tdc_pack_ticket_sub_header Failed', 16, 2)     
		RETURN  
	END  
  
	CLOSE      Cartons_on_Order_Cursor  
	DEALLOCATE Cartons_on_Order_Cursor	
	-----------------------------------------------------------------------------------------------  
	-- Loop through the format_ids  
	DECLARE print_cursor CURSOR FOR   
	 SELECT format_id, printer_id, number_of_copies FROM #PrintData_Output  
	  
	OPEN print_cursor  
	  
	FETCH NEXT FROM print_cursor INTO @format_id, @printer_id, @number_of_copies  
	   
	WHILE (@@FETCH_STATUS = 0)  
	BEGIN  
	 -------------- Now let's insert the Header $ Sub Header into the output table -----------------  
	 INSERT INTO #tdc_print_ticket (print_value) SELECT '*FORMAT,' + @format_id   
	 INSERT INTO #tdc_print_ticket (print_value) SELECT data_field + ',' + data_value FROM #PrintData  
	 INSERT INTO #tdc_print_ticket (print_value) SELECT print_value                   FROM #tdc_pack_ticket_sub_header  
	     
	 IF (@@ERROR <> 0 )  
	 BEGIN  
	  CLOSE      print_cursor  
	  DEALLOCATE print_cursor  
	  RAISERROR ('Insert into #tdc_print_ticket Failed', 16, 3)       
	  RETURN  
	 END  
	 -----------------------------------------------------------------------------------------------  
	-- START v6.6
	-- v10.5
	IF OBJECT_ID('tempdb..#detail') IS NOT NULL
		DROP TABLE #detail

	CREATE TABLE #detail(
		part_no			VARCHAR(30) NULL,
		pack_qty		DECIMAL(20,8) NULL,
		ordered			DECIMAL(20,8) NULL,
		qty_short		DECIMAL(20,8) NULL,
		list_price		DECIMAL(20,2) NULL,
		gross_price		DECIMAL(20,2) NULL, 
		net_price		DECIMAL(20,2) NULL, 
		ext_net_price	DECIMAL(20,2) NULL,
		discount_amount DECIMAL(20,2) NULL, 
		discount_pct	DECIMAL(20,2) NULL,
		note			VARCHAR(10) NULL,
		is_credit		SMALLINT NULL, --) 
		is_free			smallint NULL) -- v11.2

	CREATE TABLE #cons_orders_hdr(
		rec_id			INT IDENTITY(1,1) NOT NULL,
		order_no		INT NOT NULL,
		order_ext		INT NOT NULL,
		invoice_num		VARCHAR(16) NULL,		
		invoice_date	DATETIME NULL,
		promo_name		VARCHAR(30) NULL,
		order_type		VARCHAR(30) NULL,
		terms_desc		VARCHAR(300) NULL,
		free_shipping	VARCHAR(30) NULL,
		cust_po			VARCHAR(40) NULL
		-- 100814 - tag - add invoice notes
		,invoice_note_1   varchar(130)
		,invoice_note_2	  varchar(130)
		)

	CREATE TABLE #cons_orders_det(	
		order_no		INT NOT NULL,
		order_ext		INT NOT NULL,
		part_no			VARCHAR(30) NULL,
		pack_qty		DECIMAL(20,8) NULL,
		ordered			DECIMAL(20,8) NULL,
		qty_short		DECIMAL(20,8) NULL,
		list_price		DECIMAL(20,2) NULL,
		gross_price		DECIMAL(20,2) NULL, 
		net_price		DECIMAL(20,2) NULL, 
		ext_net_price	DECIMAL(20,2) NULL,
		discount_amount DECIMAL(20,2) NULL, 
		discount_pct	DECIMAL(20,2) NULL,
		note			VARCHAR(10) NULL,
		is_credit		SMALLINT NULL,
		is_free			smallint NULL) -- v11.2

	-- Load orders
	INSERT INTO #cons_orders_hdr(
		order_no,
		order_ext)
	SELECT DISTINCT 
		a.order_no,
		a.order_ext
	FROM 
		dbo.tdc_carton_tx a(NOLOCK) 
	INNER JOIN 
		dbo.cvo_masterpack_consolidation_det b (NOLOCK)
	ON 
		a.order_no = b.order_no 
		AND a.order_ext = b.order_ext
	WHERE 
		b.consolidation_no = @consolidation_no 
		AND a.[status]     = 'C'  
		AND a.order_type = 'S'  
	UNION   
	SELECT DISTINCT 
		tdc_carton_tx.order_no,   
		tdc_carton_tx.order_ext
	FROM 
		tdc_stage_carton   (NOLOCK)  
	INNER JOIN 
		tdc_carton_tx (NOLOCK) 
	ON   
		tdc_stage_carton.carton_no = tdc_carton_tx.carton_no  
	INNER JOIN 
		dbo.cvo_masterpack_consolidation_det mpc (NOLOCK)
	ON 
		tdc_carton_tx.order_no = mpc.order_no 
		AND tdc_carton_tx.order_ext = mpc.order_ext
	WHERE 
		mpc.consolidation_no = @consolidation_no
		AND tdc_carton_tx.status           = 'S'  
		AND tdc_carton_tx.order_type       = 'S'  
		AND tdc_stage_carton.adm_ship_flag = 'N'  
	ORDER BY 
		order_no,
		order_ext

	-- Update orders with additional details
	UPDATE 
		a
	SET
		invoice_num = ISNULL(b.doc_ctrl_num,''), 
		invoice_date = CONVERT(varchar(12),GETDATE(),101), 
		promo_name = ISNULL(d.promo_name,''), 
		order_type	= ISNULL(e.category_desc,''), 
		terms_desc = ISNULL(f.terms_desc,''),
		free_shipping = ISNULL(c.free_shipping,'N'),
		cust_po = ISNULL(o.cust_po,'')
		-- tag 100814 - add invoice notes
		,invoice_note_1 = isnull(substring(REPLACE(c.invoice_note, CHAR(13) + CHAR(10), ' '),1,124),'')
		,invoice_note_2 = isnull(substring(REPLACE(c.invoice_note, CHAR(13) + CHAR(10), ' '),125,130),'')
	FROM
		#cons_orders_hdr a
	INNER JOIN
		dbo.orders_all o (NOLOCK)
	ON
		a.order_no  = o.order_no 
		AND a.order_ext = o.ext 
	INNER JOIN
		dbo.cvo_order_invoice b (NOLOCK)
	ON
		a.order_no  = b.order_no 
		AND a.order_ext = b.order_ext 
	INNER JOIN 
		dbo.CVO_orders_all c (NOLOCK)
	ON
		a.order_no  = c.order_no 
		AND a.order_ext = c.ext 
	LEFT JOIN 
		dbo.CVO_promotions d (NOLOCK)
	ON 
		c.promo_id = d.promo_id 
		AND c.promo_level = d.promo_level -- v11.7
-- v11.7AND c.promo_level = c.promo_level
	LEFT JOIN 
		dbo.so_usrcateg e (NOLOCK) 
	ON 
		o.user_category = e.category_code
	LEFT JOIN
		dbo.arterms f (NOLOCK)
	ON
		o.terms = f.terms_code

	-- Loop through and get all the details, so we can calculate number of lines
	SET @rec_id = 0

	WHILE 1=1
	BEGIN
	
		SELECT TOP 1
			@rec_id = rec_id,
			@order_no = order_no,
			@order_ext = order_ext
		FROM
			#cons_orders_hdr
		WHERE
			rec_id > @rec_id
		ORDER BY
			rec_id

		IF @@ROWCOUNT = 0
			BREAK

		-- Get order details
		EXEC dbo.cvo_get_pack_list_details_sp @order_no, @order_ext, @Location, @inv_option -- v11.6

		-- Store details
		INSERT INTO #cons_orders_det(
			order_no,
			order_ext,
			part_no,
			pack_qty,
			ordered,
			qty_short,
			list_price,
			gross_price, 
			net_price, 
			ext_net_price,
			discount_amount, 
			discount_pct,
			note,
			is_credit,
			is_free) -- v11.2
		SELECT
			@order_no,
			@order_ext,
			part_no,
			pack_qty,
			ordered,
			qty_short,
			list_price,
			gross_price, 
			net_price, 
			ext_net_price,
			discount_amount, 
			discount_pct,
			note,
			is_credit,
			is_free -- v11.2
		FROM
			#detail	

		DELETE FROM #detail
	END

	----------------------------------
	-- Details count
	----------------------------------
	-- Detail lines
	SELECT @details_count = COUNT(1) FROM #cons_orders_det

	-- Orders (5 lines per order - 2 header, 2 footer, 1 blank)
	SELECT @orders_count = COUNT(1) FROM #cons_orders_hdr
	SET @orders_count = ISNULL(@orders_count,0) * 4
	
	-- Last order won't have a blank line at the end so subtract 1
	SET @orders_count = @orders_count - 1
	
	-- Promo (1 line per promo order)
	SELECT @promo_count = COUNT(1) FROM #cons_orders_hdr WHERE ISNULL(promo_name,'') <> ''
	SET @promo_count = ISNULL(@promo_count,0)

	-- Notes - 100814 - tag
	SELECT @notes_count_1 = COUNT(1) FROM #cons_orders_hdr WHERE ISNULL(invoice_note_1,'') <> ''
	SET @notes_count_1 = ISNULL(@notes_count_1,0)

	SELECT @notes_count_2 = COUNT(1) FROM #cons_orders_hdr WHERE ISNULL(invoice_note_2,'') <> ''
	SET @notes_count_2 = ISNULL(@notes_count_2,0)

	SET @details_count = @details_count + @orders_count + @promo_count + @notes_count_1 + @notes_count_2


	----------------------------------  
	-- Get Max Detail Lines on a page.             
	----------------------------------  
	SET @max_details_on_page = 0  
	  
	-- First check if user defined the number of details for the format ID  
	SELECT @max_details_on_page = detail_lines      
			  FROM tdc_tx_print_detail_config (NOLOCK)    
			 WHERE module       = 'PPS'     
			   AND trans        = 'ORDPACKTKT'  
			   AND trans_source = 'VB'  
			   AND format_id    = @format_id  
	  
	-- If not defined, get the value from tdc_config  
	IF ISNULL(@max_details_on_page, 0) = 0  
	BEGIN  
		-- If not defined, default to 4  
		SELECT @max_details_on_page = ISNULL((SELECT value_str FROM tdc_config (NOLOCK) WHERE [function] = 'ORDPACKTKT_Detl_Cnt'), 4)   
	END  
	   
	-- Get Total Pages  
	SELECT @total_pages = CASE 
							WHEN @details_count % @max_details_on_page = 0  THEN @details_count / @max_details_on_page    
							ELSE @details_count / @max_details_on_page + 1   
							END    
	  
	-- First Page  
	SELECT @page_no = 1, @printed_details_cnt = 1, @printed_on_the_page = 1  

	
	--SET @cons_order_tax = 0
	--SET @cons_order_frt = 0
	SET @cons_order_gross = 0
	SET @cons_order_disc = 0
	SET @cons_order_net = 0
	SET @cons_order_total = 0

	-- Loop through each order and process it
	SET @rec_id = 0

	WHILE 1=1
	BEGIN

		-- START v20.2
		IF @rec_id <> 0
		BEGIN
			SET @added_freight = 1
		END 
		-- END v20.2
	
		SELECT TOP 1
			@rec_id = rec_id,
			@order_no = order_no,
			@order_ext = order_ext,
			@invoice_num = invoice_num,
			@invoice_date = invoice_date,
			@promo_name = promo_name,
			@order_type	= order_type,
			@terms_desc = terms_desc,
			@free_shipping = free_shipping,
			@cust_po = cust_po
			-- 100814 - add invoice notes
			,@invoice_note_1 = invoice_note_1
			,@invoice_note_2 = invoice_note_2
		FROM
			#cons_orders_hdr
		WHERE
			rec_id > @rec_id
		ORDER BY
			rec_id

		IF @@ROWCOUNT = 0
			BREAK

		SET @order_gross	= 0.00
		SET @order_disc		= 0.00
		SET @order_net		= 0.00
		SET @order_total	= 0.00
		SET @order_tot_list	= 0.00					
		SET @order_ext_list	= 0.00					
		

		-- Clear previous details
		DELETE FROM #detail

		-- Load details into temp table
		INSERT INTO #detail(
			part_no,
			pack_qty,
			ordered,
			qty_short,
			list_price,
			gross_price, 
			net_price, 
			ext_net_price,
			discount_amount, 
			discount_pct,
			note,
			is_credit,
			is_free) -- v11.2
		SELECT
			part_no,
			pack_qty,
			ordered,
			qty_short,
			list_price,
			gross_price, 
			net_price, 
			ext_net_price,
			discount_amount, 
			discount_pct,
			note,
			is_credit,
			is_free -- v11.2
		FROM
			#cons_orders_det	
		WHERE
			order_no = @order_no
			AND order_ext = @order_ext
		


		-- Update invoice details
		UPDATE	cvo_order_invoice
		SET		inv_date = @invoice_date
		WHERE	order_no  = @order_no 
		AND		order_ext = @order_ext 
		
		-- Line 1 of order header
		SET @cons_text = 'Invoice #: ' + ISNULL(@invoice_num,'') + '     Order #: ' + CAST(@order_no AS VARCHAR(10)) + '-' + CAST(@order_ext AS VARCHAR(3))
		INSERT INTO #tdc_print_ticket(print_value) VALUES('LP_CONS_TEXT_'         + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@cons_text, ''))  

		/*-----------START: CHECK FOR BOTTOM OF PAGE -----------*/
		-- If we reached max detail lines on the page, print the Footer  
		IF @printed_on_the_page = @max_details_on_page  
		BEGIN  
			IF @page_no = @total_pages			--@total_pages = 1
			BEGIN
				INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_TAX,' + CAST(@cons_order_tax AS VARCHAR(30)))
				INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_FREIGHT,' + CAST(@cons_order_frt AS VARCHAR(30)))
				INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_GROSS,' + CAST(@cons_order_gross AS VARCHAR(30)))
				INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_DISCOUNT,' + CAST(@cons_order_disc AS VARCHAR(30)))
				INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_NET,' + CAST(@cons_order_net AS VARCHAR(30)))
				INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_TOTAL,' + CAST(@cons_order_total AS VARCHAR(30)))
			END
			ELSE
			BEGIN
				INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_TAX,' + CAST(' ' AS VARCHAR(30)))
				INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_FREIGHT,' + CAST(' ' AS VARCHAR(30)))
				INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_GROSS,' + CAST(' ' AS VARCHAR(30)))
				INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_DISCOUNT,' + CAST(' ' AS VARCHAR(30)))
				INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_NET,' + CAST(' ' AS VARCHAR(30)))
				INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_TOTAL,' + CAST(' ' AS VARCHAR(30)))
			END

			-------------- Now let's insert the Footer into the output table -----------------  
			INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_PAGE_NO,'+RTRIM(CAST(@page_no AS char(4)))+' of '+RTRIM(CAST(@total_pages AS char(4)))
			INSERT INTO #tdc_print_ticket (print_value) SELECT '*PRINTERNUMBER,' + @printer_id  
			INSERT INTO #tdc_print_ticket (print_value) SELECT '*QUANTITY,'      + RTRIM(CAST(@number_of_copies AS char(4)))  
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
			-----------------------------------------------------------------------------------  
		   
			-- Next Page  
			SELECT @page_no = @page_no + 1  
			SELECT @printed_on_the_page = 0  
		     
			IF (@printed_details_cnt < @details_count)  
			BEGIN  
				-------------- Now let's insert the Header $ Sub Header into the output table -----------------  
				INSERT INTO #tdc_print_ticket (print_value) SELECT '*FORMAT,' + @format_id   
				INSERT INTO #tdc_print_ticket (print_value) SELECT data_field + ',' + data_value FROM #PrintData  
				INSERT INTO #tdc_print_ticket (print_value) SELECT print_value                   FROM #tdc_pack_ticket_sub_header  

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
		END -- End of 'If we reached max detail lines on the page'  
		/*-----------END: CHECK FOR BOTTOM OF PAGE -----------*/

		-- Next Detail Line  
		SELECT @printed_details_cnt = @printed_details_cnt + 1  
		SELECT @printed_on_the_page = @printed_on_the_page + 1 

		-- Line 2 of order header
		SET @cons_text = 'Order Type: ' + ISNULL(@order_type,'') + '     Customer PO: ' + ISNULL(@cust_po,'') + '     Terms: ' + ISNULL(@terms_desc,'')
		INSERT INTO #tdc_print_ticket(print_value) VALUES('LP_CONS_TEXT_'         + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@cons_text, ''))  

		/*-----------START: CHECK FOR BOTTOM OF PAGE -----------*/
		-- If we reached max detail lines on the page, print the Footer  
		IF @printed_on_the_page = @max_details_on_page  
		BEGIN  
			IF @page_no = @total_pages			--@total_pages = 1
			BEGIN
				INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_TAX,' + CAST(@cons_order_tax AS VARCHAR(30)))
				INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_FREIGHT,' + CAST(@cons_order_frt AS VARCHAR(30)))
				INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_GROSS,' + CAST(@cons_order_gross AS VARCHAR(30)))
				INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_DISCOUNT,' + CAST(@cons_order_disc AS VARCHAR(30)))
				INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_NET,' + CAST(@cons_order_net AS VARCHAR(30)))
				INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_TOTAL,' + CAST(@cons_order_total AS VARCHAR(30)))
			END
			ELSE
			BEGIN
				INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_TAX,' + CAST(' ' AS VARCHAR(30)))
				INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_FREIGHT,' + CAST(' ' AS VARCHAR(30)))
				INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_GROSS,' + CAST(' ' AS VARCHAR(30)))
				INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_DISCOUNT,' + CAST(' ' AS VARCHAR(30)))
				INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_NET,' + CAST(' ' AS VARCHAR(30)))
				INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_TOTAL,' + CAST(' ' AS VARCHAR(30)))
			END

			-------------- Now let's insert the Footer into the output table -----------------  
			INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_PAGE_NO,'+RTRIM(CAST(@page_no AS char(4)))+' of '+RTRIM(CAST(@total_pages AS char(4)))
			INSERT INTO #tdc_print_ticket (print_value) SELECT '*PRINTERNUMBER,' + @printer_id  
			INSERT INTO #tdc_print_ticket (print_value) SELECT '*QUANTITY,'      + RTRIM(CAST(@number_of_copies AS char(4)))  
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
			-----------------------------------------------------------------------------------  
		   
			-- Next Page  
			SELECT @page_no = @page_no + 1  
			SELECT @printed_on_the_page = 0  
		     
			IF (@printed_details_cnt < @details_count)  
			BEGIN  
				-------------- Now let's insert the Header $ Sub Header into the output table -----------------  
				INSERT INTO #tdc_print_ticket (print_value) SELECT '*FORMAT,' + @format_id   
				INSERT INTO #tdc_print_ticket (print_value) SELECT data_field + ',' + data_value FROM #PrintData  
				INSERT INTO #tdc_print_ticket (print_value) SELECT print_value                   FROM #tdc_pack_ticket_sub_header  

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
		END -- End of 'If we reached max detail lines on the page'  
		/*-----------END: CHECK FOR BOTTOM OF PAGE -----------*/
		
		-- Next Detail Line  
		SELECT @printed_details_cnt = @printed_details_cnt + 1  
		SELECT @printed_on_the_page = @printed_on_the_page + 1 

		-- Line 3 of order header - only if there is a promo
		IF ISNULL(@promo_name,'') <> ''
		BEGIN
			SET @cons_text = 'Promotion: ' + ISNULL(@promo_name,'') 
			INSERT INTO #tdc_print_ticket(print_value) VALUES('LP_CONS_TEXT_'         + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@cons_text, ''))  

			/*-----------START: CHECK FOR BOTTOM OF PAGE -----------*/
			-- If we reached max detail lines on the page, print the Footer  
			IF @printed_on_the_page = @max_details_on_page  
			BEGIN  
				IF @page_no = @total_pages			--@total_pages = 1
				BEGIN
					INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_TAX,' + CAST(@cons_order_tax AS VARCHAR(30)))
					INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_FREIGHT,' + CAST(@cons_order_frt AS VARCHAR(30)))
					INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_GROSS,' + CAST(@cons_order_gross AS VARCHAR(30)))
					INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_DISCOUNT,' + CAST(@cons_order_disc AS VARCHAR(30)))
					INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_NET,' + CAST(@cons_order_net AS VARCHAR(30)))
					INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_TOTAL,' + CAST(@cons_order_total AS VARCHAR(30)))
				END
				ELSE
				BEGIN
					INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_TAX,' + CAST(' ' AS VARCHAR(30)))
					INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_FREIGHT,' + CAST(' ' AS VARCHAR(30)))
					INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_GROSS,' + CAST(' ' AS VARCHAR(30)))
					INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_DISCOUNT,' + CAST(' ' AS VARCHAR(30)))
					INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_NET,' + CAST(' ' AS VARCHAR(30)))
					INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_TOTAL,' + CAST(' ' AS VARCHAR(30)))
				END

				-------------- Now let's insert the Footer into the output table -----------------  
				INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_PAGE_NO,'+RTRIM(CAST(@page_no AS char(4)))+' of '+RTRIM(CAST(@total_pages AS char(4)))
				INSERT INTO #tdc_print_ticket (print_value) SELECT '*PRINTERNUMBER,' + @printer_id  
				INSERT INTO #tdc_print_ticket (print_value) SELECT '*QUANTITY,'      + RTRIM(CAST(@number_of_copies AS char(4)))  
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
				-----------------------------------------------------------------------------------  
			   
				-- Next Page  
				SELECT @page_no = @page_no + 1  
				SELECT @printed_on_the_page = 0  
			     
				IF (@printed_details_cnt < @details_count)  
				BEGIN  
					-------------- Now let's insert the Header $ Sub Header into the output table -----------------  
					INSERT INTO #tdc_print_ticket (print_value) SELECT '*FORMAT,' + @format_id   
					INSERT INTO #tdc_print_ticket (print_value) SELECT data_field + ',' + data_value FROM #PrintData  
					INSERT INTO #tdc_print_ticket (print_value) SELECT print_value                   FROM #tdc_pack_ticket_sub_header  

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
			END -- End of 'If we reached max detail lines on the page'  
			/*-----------END: CHECK FOR BOTTOM OF PAGE -----------*/
			
			-- Next Detail Line  
			SELECT @printed_details_cnt = @printed_details_cnt + 1  
			SELECT @printed_on_the_page = @printed_on_the_page + 1 
		END

		IF ISNULL(@invoice_note_1,'') <> ''
		BEGIN
			SET @cons_text = 'Note: ' + ISNULL(@invoice_note_1,'') 
			INSERT INTO #tdc_print_ticket(print_value) VALUES('LP_CONS_TEXT_'         + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@cons_text, ''))  

			/*-----------START: CHECK FOR BOTTOM OF PAGE -----------*/
			-- If we reached max detail lines on the page, print the Footer  
			IF @printed_on_the_page = @max_details_on_page  
			BEGIN  
				IF @page_no = @total_pages			--@total_pages = 1
				BEGIN
					INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_TAX,' + CAST(@cons_order_tax AS VARCHAR(30)))
					INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_FREIGHT,' + CAST(@cons_order_frt AS VARCHAR(30)))
					INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_GROSS,' + CAST(@cons_order_gross AS VARCHAR(30)))
					INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_DISCOUNT,' + CAST(@cons_order_disc AS VARCHAR(30)))
					INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_NET,' + CAST(@cons_order_net AS VARCHAR(30)))
					INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_TOTAL,' + CAST(@cons_order_total AS VARCHAR(30)))
				END
				ELSE
				BEGIN
					INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_TAX,' + CAST(' ' AS VARCHAR(30)))
					INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_FREIGHT,' + CAST(' ' AS VARCHAR(30)))
					INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_GROSS,' + CAST(' ' AS VARCHAR(30)))
					INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_DISCOUNT,' + CAST(' ' AS VARCHAR(30)))
					INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_NET,' + CAST(' ' AS VARCHAR(30)))
					INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_TOTAL,' + CAST(' ' AS VARCHAR(30)))
				END

				-------------- Now let's insert the Footer into the output table -----------------  
				INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_PAGE_NO,'+RTRIM(CAST(@page_no AS char(4)))+' of '+RTRIM(CAST(@total_pages AS char(4)))
				INSERT INTO #tdc_print_ticket (print_value) SELECT '*PRINTERNUMBER,' + @printer_id  
				INSERT INTO #tdc_print_ticket (print_value) SELECT '*QUANTITY,'      + RTRIM(CAST(@number_of_copies AS char(4)))  
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
				-----------------------------------------------------------------------------------  
			   
				-- Next Page  
				SELECT @page_no = @page_no + 1  
				SELECT @printed_on_the_page = 0  
			     
				IF (@printed_details_cnt < @details_count)  
				BEGIN  
					-------------- Now let's insert the Header $ Sub Header into the output table -----------------  
					INSERT INTO #tdc_print_ticket (print_value) SELECT '*FORMAT,' + @format_id   
					INSERT INTO #tdc_print_ticket (print_value) SELECT data_field + ',' + data_value FROM #PrintData  
					INSERT INTO #tdc_print_ticket (print_value) SELECT print_value                   FROM #tdc_pack_ticket_sub_header  

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
			END -- End of 'If we reached max detail lines on the page'  
			/*-----------END: CHECK FOR BOTTOM OF PAGE -----------*/
			
			-- Next Detail Line  
			SELECT @printed_details_cnt = @printed_details_cnt + 1  
			SELECT @printed_on_the_page = @printed_on_the_page + 1 
		END -- invoice notes line 1

		IF ISNULL(@invoice_note_2,'') <> ''
		BEGIN
			SET @cons_text = ISNULL(@invoice_note_2,'') 
			INSERT INTO #tdc_print_ticket(print_value) VALUES('LP_CONS_TEXT_'         + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@cons_text, ''))  

			/*-----------START: CHECK FOR BOTTOM OF PAGE -----------*/
			-- If we reached max detail lines on the page, print the Footer  
			IF @printed_on_the_page = @max_details_on_page  
			BEGIN  
				IF @page_no = @total_pages			--@total_pages = 1
				BEGIN
					INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_TAX,' + CAST(@cons_order_tax AS VARCHAR(30)))
					INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_FREIGHT,' + CAST(@cons_order_frt AS VARCHAR(30)))
					INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_GROSS,' + CAST(@cons_order_gross AS VARCHAR(30)))
					INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_DISCOUNT,' + CAST(@cons_order_disc AS VARCHAR(30)))
					INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_NET,' + CAST(@cons_order_net AS VARCHAR(30)))
					INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_TOTAL,' + CAST(@cons_order_total AS VARCHAR(30)))
				END
				ELSE
				BEGIN
					INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_TAX,' + CAST(' ' AS VARCHAR(30)))
					INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_FREIGHT,' + CAST(' ' AS VARCHAR(30)))
					INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_GROSS,' + CAST(' ' AS VARCHAR(30)))
					INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_DISCOUNT,' + CAST(' ' AS VARCHAR(30)))
					INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_NET,' + CAST(' ' AS VARCHAR(30)))
					INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_TOTAL,' + CAST(' ' AS VARCHAR(30)))
				END

				-------------- Now let's insert the Footer into the output table -----------------  
				INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_PAGE_NO,'+RTRIM(CAST(@page_no AS char(4)))+' of '+RTRIM(CAST(@total_pages AS char(4)))
				INSERT INTO #tdc_print_ticket (print_value) SELECT '*PRINTERNUMBER,' + @printer_id  
				INSERT INTO #tdc_print_ticket (print_value) SELECT '*QUANTITY,'      + RTRIM(CAST(@number_of_copies AS char(4)))  
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
				-----------------------------------------------------------------------------------  
			   
				-- Next Page  
				SELECT @page_no = @page_no + 1  
				SELECT @printed_on_the_page = 0  
			     
				IF (@printed_details_cnt < @details_count)  
				BEGIN  
					-------------- Now let's insert the Header $ Sub Header into the output table -----------------  
					INSERT INTO #tdc_print_ticket (print_value) SELECT '*FORMAT,' + @format_id   
					INSERT INTO #tdc_print_ticket (print_value) SELECT data_field + ',' + data_value FROM #PrintData  
					INSERT INTO #tdc_print_ticket (print_value) SELECT print_value                   FROM #tdc_pack_ticket_sub_header  

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
			END -- End of 'If we reached max detail lines on the page'  
			/*-----------END: CHECK FOR BOTTOM OF PAGE -----------*/
			
			-- Next Detail Line  
			SELECT @printed_details_cnt = @printed_details_cnt + 1  
			SELECT @printed_on_the_page = @printed_on_the_page + 1 
		END -- notes line 2
	 
		-- Now do the normal details
		----- For Order based pack tickets the details are: --------------------------  
		----- part_no, item_description, upc_code, sum_pack_qty, sum_ordered_qty --------------  
		-- v10.2 Start
		DECLARE detail_cursor CURSOR FOR   
		SELECT 
			a.part_no,
			ISNULL(CAST(a.pack_qty AS varchar(20)),''),
			ISNULL(CAST(a.ordered AS varchar(20)),''),
			ISNULL(a.pack_qty,0),
			ISNULL(CAST(a.qty_short AS varchar(20)),''),
			a.list_price,
			a.gross_price, 
			a.net_price, 
			a.ext_net_price,
			a.discount_amount, 
			a.discount_pct,
			a.note,
			a.is_credit, -- v11.0 
			a.is_free -- v11.2
		FROM 
			#detail a
		LEFT JOIN
			inv_master b (NOLOCK)
		ON 
			a.part_no = b.part_no
		LEFT JOIN
			#part_type c
		ON
			b.type_code = c.part_type
		ORDER BY 
			ISNULL(c.printorder,3), a.part_no
		-- v10.2 end 
	 
		OPEN detail_cursor  
	   
		FETCH NEXT FROM detail_cursor INTO 
			@part_no, 
			@Sum_Pack_Qty, 
			@Sum_Ordered_Qty, 
			@Sum_Line_Ship, 
			@Sum_Qty_Short,
			@c_list_price,
			@c_gross_price, 
			@c_net_price, 
			@c_ext_net_price,
			@c_discount_amount, 
			@c_discount_pct,
			@li_note,
			@is_credit, -- v11.0 
			@is_free -- v11.2

	
	    
		WHILE (@@FETCH_STATUS <> -1)  
		BEGIN  

			SET @new_order_totals = 0

			-- Get cust_part_no  
			SELECT @cust_part_no = cust_part FROM cust_xref (NOLOCK) WHERE part_no = @part_no AND customer_key = @cust_code  
			           
			-- Get drawing_no & upc_code of the Item   
			SELECT @UPC_Code   = upc_code, @drawing_no = sku_no FROM inv_master (NOLOCK) WHERE part_no = @part_no  

			-- v11.8 Start
--			IF EXISTS(SELECT * FROM ord_list(NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext  AND part_no = @part_no  AND part_type != 'C')  
--			BEGIN  
				SELECT TOP 1 
					@item_description = [description]  
				FROM 
					dbo.ord_list(NOLOCK)   
				WHERE 
					order_no   = @order_no  
					AND order_ext  = @order_ext  
					AND part_no    = @part_no  
--			END  
--			ELSE  
--			BEGIN  
--				SELECT TOP 1 
--					@item_description = [description]  
--				FROM 
--					dbo.ord_list_kit(NOLOCK)   
--				WHERE 
--					order_no   = @order_no  
--					AND order_ext  = @order_ext  
--					AND part_no   = @part_no  
--			END  
			-- v11.8 End
	  
			-- v10.1 Start
			IF EXISTS (SELECT 1 FROM ord_list a (NOLOCK) JOIN cvo_ord_list b (NOLOCK) ON a.order_no = b.order_no AND a.order_ext = b.order_ext AND a.line_no = b.line_no
						WHERE a.order_no = @order_no AND a.order_ext = @order_ext  AND a.part_no = @part_no AND b.is_customized = 'S')
			BEGIN
				SET @item_description = '(*) ' + @item_description -- v10.3
			END

			-- v10.1 End

			-- Remove the '0' after the '.'  
			EXEC tdc_trim_zeros_sp @Sum_Ordered_Qty OUTPUT  
			EXEC tdc_trim_zeros_sp @Sum_Pack_Qty    OUTPUT  
			EXEC tdc_trim_zeros_sp @Sum_Qty_Short   OUTPUT  
			EXEC tdc_parse_string_sp @item_description, @item_description output   
	  
			IF @Sum_Pack_Qty = '' SET @Sum_Pack_Qty = '0'			--v4.0 Make sure we show 0 for no shipments
	   
			-------------- Now let's insert the Details into the output table -----------------     
			--BEGIN SED009 -- Pick List/Invoice & Pack List/Inovoice
			--JVM 09/14/2010 
			DECLARE @list_price  VARCHAR (40)
			DECLARE @gross_price VARCHAR (40), @net_price VARCHAR (40), @ext_net_price VARCHAR(40),
				  @discount_amount VARCHAR (40), @discount_pct varchar(40)

			SET @list_price      = ''
			SET @gross_price     = ''
			SET @ext_net_price   = ''
			SET @net_price	   = ''
			SET @discount_amount = ''
			SET @discount_pct	   = ''

			-- START v20.4
			IF @c_net_price > @c_list_price
			BEGIN
				SET @c_list_price = @c_net_price
				SET @c_discount_amount = 0
				SET @c_discount_pct = 0
			END
			-- END v20.4

			-- START v6.6
			--IF EXISTS(SELECT buying_group FROM CVO_orders_all WHERE order_no = @order_no AND ext = @order_ext AND buying_group is not null AND buying_group != '' )
			IF @BG_Order = 1
			BEGIN
				
				-- v11.2 Start
				IF (@is_free = 0 AND @inv_option = '1') -- v11.4 -- v11.5
				BEGIN
					SELECT	@list_price	= CAST(@c_list_price AS DECIMAL (20,2)),				
							@order_ext_list = @c_list_price * @Sum_Line_Ship
				END
				ELSE
				BEGIN -- v11.5 Start
					IF (@is_free = 1 AND @inv_option = '1')
					BEGIN
						SELECT	@list_price	= CAST(@c_list_price AS DECIMAL (20,2)),		
								@discount_amount = CAST(@c_list_price AS DECIMAL (20,2))
					END
					ELSE
					BEGIN
						-- v11.6 Start
						IF (@is_free = 0 AND @inv_option = '0')
						BEGIN
							SELECT	@list_price	= CAST(@c_list_price AS DECIMAL (20,2)),				
									@order_ext_list = @c_list_price * @Sum_Line_Ship,
									@discount_amount	=CAST(@c_discount_amount AS DECIMAL(20,2)),
									@gross_price	= CAST(@c_gross_price AS DECIMAL(20,2)),
									@net_price		= CAST(@c_net_price AS DECIMAL(20,2))

						END
						ELSE
						BEGIN
							SELECT	@list_price	= 0,				
									@order_ext_list = 0
						END -- v11.5 End
					END
					-- v11.6 End
				END
				-- v11.2 End
			
				INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_BUYING_GROUP,Buying Group: Yes') 
			END
			ELSE
			BEGIN
				SELECT 	@gross_price	= CAST(@c_gross_price AS DECIMAL(20,2)), 
						@net_price		= CAST(@c_net_price AS DECIMAL(20,2)),							
						@ext_net_price	= CAST(@c_ext_net_price AS DECIMAL(20,2)),						
						@discount_amount	=CAST(@c_discount_amount AS DECIMAL(20,2)),
						@discount_pct	= CAST(@c_discount_pct AS DECIMAL(20,2)), 
						@list_price		= CAST(@c_list_price AS DECIMAL(20,2))
			
				INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_BUYING_GROUP,Buying Group: No') 
			END
			-- END v6.6

			IF @BG_Order = 0
			BEGIN
				SELECT @order_disc	= @order_disc + @discount_amount
				SELECT @order_net	= @order_net + @gross_price
				SELECT @order_gross	= 0
				SELECT @order_disc	= 0
				IF @added_freight = 0
				BEGIN
					SELECT @order_total	= @order_net + @order_tax + @order_frt
					-- START v20.2
					--SET @added_freight = 1
					-- END v20.2
				END
				ELSE
				BEGIN
					SELECT @order_total	= @order_net 
				END
			END
			ELSE																	--v6.1
			BEGIN																	--v6.1
				-- START v11.0 - don't include promo credits in totals for BG
				IF @is_credit = 0
				BEGIN
					SELECT @order_tot_list	= @order_tot_list + @order_ext_list			--v6.1
					SELECT @order_net = @order_tot_list									--v6.1
				
					IF @added_freight = 0
					BEGIN
						SELECT @order_total	= @order_net + @order_tax + @order_frt			--v6.1
						-- START v20.2
						--SET @added_freight = 1
						-- END v20.2
					END
					ELSE
					BEGIN
						SELECT @order_total	= @order_net 
					END
				END
				-- END v11.0
			END																	--v6.1

			SET @new_order_totals = 1

			EXEC tdc_trim_zeros_sp @discount_pct OUTPUT								--v6.1

			INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_LIST_PRICE_'      + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + @list_price      )   
			INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_GROSS_PRICE_'     + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + @gross_price     )   
			INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_NET_PRICE_'       + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + @net_price       )   
			INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_DISCOUNT_AMOUNT_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + @discount_amount )   
			INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_DISCOUNT_PCT_'	 + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + @discount_pct )   		  
			--END   SED009 -- Pick List/Invoice & Pack List/Inovoice  

			-- START v11.0
			IF @is_credit = 1
			BEGIN
				INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_PART_NO_'          + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',PROMO CREDIT')  
				INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_ITEM_DESCRIPTION_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',CREDIT FOR ' + ISNULL(@part_no, ''))
				INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_SUM_PACK_QTY_'     + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',')  
				INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_SUM_ORDERED_QTY_'  + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',')  
				INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_SUM_QTY_SHORT_'  + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',')
				INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_TRAY_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',')   
			END
			ELSE
			BEGIN
				INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_PART_NO_'          + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + @part_no)  
				INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_ITEM_DESCRIPTION_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@item_description, ''))  
				INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_SUM_PACK_QTY_'     + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + @sum_pack_qty)  
				INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_SUM_ORDERED_QTY_'  + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + @sum_ordered_qty )  
				INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_SUM_QTY_SHORT_'  + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + @Sum_Qty_Short ) 
				INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_TRAY_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@li_note, ''))  
			END
			-- END v11.0

			INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_UPC_CODE_'         + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@upc_code,     ''))  
		 
			INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_CUST_PART_NO_'     + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@cust_part_no,     ''))  
			INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_DRAWING_NO_'    + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@drawing_no,     ''))  
		  
			SELECT	@sku_code = isnull(sku_code, ''), @height = height, @width = width, @length = length, @cmdty_code = isnull(cmdty_code, ''),   
					@weight_ea = weight_ea, @so_qty_increment = isnull(so_qty_increment, 0), @cubic_feet = cubic_feet   
			FROM inv_master (nolock) WHERE part_no = @part_no  
	 
			SELECT	@category_1 = isnull(category_1, ''), @category_2 = isnull(category_2, ''), @category_3 = isnull(category_3, ''),   
					@category_4 = isnull(category_4, ''), @category_5 = isnull(category_5, '')   
			FROM inv_master_add (nolock) WHERE part_no = @part_no  

			INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_SKU_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@sku_code, '')   
			INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_CMDTY_CODE_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@cmdty_code, '')  
			INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_WEIGHT_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + CAST(@weight AS varchar(20))  
			INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_SO_QTY_INCR_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + CAST(@so_qty_increment AS varchar(20))  
 
			IF (@@ERROR <> 0 )  
			BEGIN  
				CLOSE      detail_cursor  
				DEALLOCATE detail_cursor  
				CLOSE      print_cursor  
				DEALLOCATE print_cursor  

				RAISERROR ('Insert into #PrintPackList_DTL Failed', 16, 4)      
				RETURN  
			END  
			-----------------------------------------------------------------------------------------------  
	  
			-- If we reached max detail lines on the page, print the Footer  
			IF @printed_on_the_page = @max_details_on_page  
			BEGIN  
				IF @page_no = @total_pages			--@total_pages = 1
				BEGIN
					INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_TAX,' + CAST(@cons_order_tax AS VARCHAR(30)))
					INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_FREIGHT,' + CAST(@cons_order_frt AS VARCHAR(30)))
					INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_GROSS,' + CAST(@cons_order_gross AS VARCHAR(30)))
					INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_DISCOUNT,' + CAST(@cons_order_disc AS VARCHAR(30)))
					INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_NET,' + CAST(@cons_order_net AS VARCHAR(30)))
					INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_TOTAL,' + CAST(@cons_order_total AS VARCHAR(30)))
				END
				ELSE
				BEGIN
					INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_TAX,' + CAST(' ' AS VARCHAR(30)))
					INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_FREIGHT,' + CAST(' ' AS VARCHAR(30)))
					INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_GROSS,' + CAST(' ' AS VARCHAR(30)))
					INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_DISCOUNT,' + CAST(' ' AS VARCHAR(30)))
					INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_NET,' + CAST(' ' AS VARCHAR(30)))
					INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_TOTAL,' + CAST(' ' AS VARCHAR(30)))
				END

				-------------- Now let's insert the Footer into the output table -----------------  
				INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_PAGE_NO,'+RTRIM(CAST(@page_no AS char(4)))+' of '+RTRIM(CAST(@total_pages AS char(4)))
				INSERT INTO #tdc_print_ticket (print_value) SELECT '*PRINTERNUMBER,' + @printer_id  
				INSERT INTO #tdc_print_ticket (print_value) SELECT '*QUANTITY,'      + RTRIM(CAST(@number_of_copies AS char(4)))  
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
				-----------------------------------------------------------------------------------  
			   
				-- Next Page  
				SELECT @page_no = @page_no + 1  
				SELECT @printed_on_the_page = 0  
			     
				IF (@printed_details_cnt < @details_count)  
				BEGIN  
					-------------- Now let's insert the Header $ Sub Header into the output table -----------------  
					INSERT INTO #tdc_print_ticket (print_value) SELECT '*FORMAT,' + @format_id   
					INSERT INTO #tdc_print_ticket (print_value) SELECT data_field + ',' + data_value FROM #PrintData  
					INSERT INTO #tdc_print_ticket (print_value) SELECT print_value                   FROM #tdc_pack_ticket_sub_header  

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
			END -- End of 'If we reached max detail lines on the page'  
		  
			-- Next Detail Line  
			SELECT @printed_details_cnt = @printed_details_cnt + 1  
			SELECT @printed_on_the_page = @printed_on_the_page + 1  
	  
		   -- START v6.6
			--FETCH NEXT FROM detail_cursor INTO @part_no  
			FETCH NEXT FROM detail_cursor INTO 
				@part_no, 
				@Sum_Pack_Qty, 
				@Sum_Ordered_Qty, 
				@Sum_Line_Ship, 
				@Sum_Qty_Short,
				@c_list_price,
				@c_gross_price, 
				@c_net_price, 
				@c_ext_net_price,
				@c_discount_amount, 
				@c_discount_pct,
				@li_note,
				@is_credit, -- v11.0  
				@is_free -- v11.2
			-- END v6.6
		END -- End of the detail_cursor  
	  
		CLOSE      detail_cursor  
		DEALLOCATE detail_cursor  

		-- Order footer - line 1: total and free shipping
		/*
		SELECT
			@f_order_total = SUM(ISNULL(gross_price,0))
		FROM
			#details

		*/
		SET @f_order_total = @order_net
		SET @f_order_total = ISNULL(@f_order_total,0)

		SET @cons_text = 'Order Total : ' + ISNULL(CAST(CAST(@f_order_total AS DECIMAL(20,2)) AS VARCHAR(15)),'')

		IF ISNULL(@free_shipping,'N') = 'Y'
		BEGIN
			SET @cons_text = @cons_text + '    *Note: Free freight on this portion of the order* ' 
		END
		
		INSERT INTO #tdc_print_ticket(print_value) VALUES('LP_CONS_TEXT_'         + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@cons_text, ''))  

		/*-----------START: CHECK FOR BOTTOM OF PAGE -----------*/
		-- If we reached max detail lines on the page, print the Footer  
		IF @printed_on_the_page = @max_details_on_page  
		BEGIN  
			IF @page_no = @total_pages			--@total_pages = 1
			BEGIN
				INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_TAX,' + CAST(@cons_order_tax AS VARCHAR(30)))
				INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_FREIGHT,' + CAST(@cons_order_frt AS VARCHAR(30)))
				INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_GROSS,' + CAST(@cons_order_gross AS VARCHAR(30)))
				INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_DISCOUNT,' + CAST(@cons_order_disc AS VARCHAR(30)))
				INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_NET,' + CAST(@cons_order_net AS VARCHAR(30)))
				INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_TOTAL,' + CAST(@cons_order_total AS VARCHAR(30)))
			END
			ELSE
			BEGIN
				INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_TAX,' + CAST(' ' AS VARCHAR(30)))
				INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_FREIGHT,' + CAST(' ' AS VARCHAR(30)))
				INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_GROSS,' + CAST(' ' AS VARCHAR(30)))
				INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_DISCOUNT,' + CAST(' ' AS VARCHAR(30)))
				INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_NET,' + CAST(' ' AS VARCHAR(30)))
				INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_TOTAL,' + CAST(' ' AS VARCHAR(30)))
			END

			-------------- Now let's insert the Footer into the output table -----------------  
			INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_PAGE_NO,'+RTRIM(CAST(@page_no AS char(4)))+' of '+RTRIM(CAST(@total_pages AS char(4)))
			INSERT INTO #tdc_print_ticket (print_value) SELECT '*PRINTERNUMBER,' + @printer_id  
			INSERT INTO #tdc_print_ticket (print_value) SELECT '*QUANTITY,'      + RTRIM(CAST(@number_of_copies AS char(4)))  
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
			-----------------------------------------------------------------------------------  
		   
			-- Next Page  
			SELECT @page_no = @page_no + 1  
			SELECT @printed_on_the_page = 0  
		     
			IF (@printed_details_cnt < @details_count)  
			BEGIN  
				-------------- Now let's insert the Header $ Sub Header into the output table -----------------  
				INSERT INTO #tdc_print_ticket (print_value) SELECT '*FORMAT,' + @format_id   
				INSERT INTO #tdc_print_ticket (print_value) SELECT data_field + ',' + data_value FROM #PrintData  
				INSERT INTO #tdc_print_ticket (print_value) SELECT print_value                   FROM #tdc_pack_ticket_sub_header  

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
		END -- End of 'If we reached max detail lines on the page'  
		/*-----------END: CHECK FOR BOTTOM OF PAGE -----------*/

		-- Next Detail Line  
		SELECT @printed_details_cnt = @printed_details_cnt + 1  
		SELECT @printed_on_the_page = @printed_on_the_page + 1 

		-- v11.1 Start
		IF EXISTS (SELECT 1 FROM #cons_orders_hdr WHERE rec_id > @rec_id)
		BEGIN
			SET @cons_text = ''
			INSERT INTO #tdc_print_ticket(print_value) VALUES('LP_CONS_TEXT_'         + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@cons_text, ''))  
		END
		-- v11.1 End

		/*-----------START: CHECK FOR BOTTOM OF PAGE -----------*/
		-- If we reached max detail lines on the page, print the Footer  
		IF @printed_on_the_page = @max_details_on_page  
		BEGIN  
			IF @page_no = @total_pages			--@total_pages = 1
			BEGIN
				INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_TAX,' + CAST(@cons_order_tax AS VARCHAR(30)))
				INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_FREIGHT,' + CAST(@cons_order_frt AS VARCHAR(30)))
				INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_GROSS,' + CAST(@cons_order_gross AS VARCHAR(30)))
				INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_DISCOUNT,' + CAST(@cons_order_disc AS VARCHAR(30)))
				INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_NET,' + CAST(@cons_order_net AS VARCHAR(30)))
				INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_TOTAL,' + CAST(@cons_order_total AS VARCHAR(30)))
			END
			ELSE
			BEGIN
				INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_TAX,' + CAST(' ' AS VARCHAR(30)))
				INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_FREIGHT,' + CAST(' ' AS VARCHAR(30)))
				INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_GROSS,' + CAST(' ' AS VARCHAR(30)))
				INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_DISCOUNT,' + CAST(' ' AS VARCHAR(30)))
				INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_NET,' + CAST(' ' AS VARCHAR(30)))
				INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_TOTAL,' + CAST(' ' AS VARCHAR(30)))
			END

			-------------- Now let's insert the Footer into the output table -----------------  
			INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_PAGE_NO,'+RTRIM(CAST(@page_no AS char(4)))+' of '+RTRIM(CAST(@total_pages AS char(4)))
			INSERT INTO #tdc_print_ticket (print_value) SELECT '*PRINTERNUMBER,' + @printer_id  
			INSERT INTO #tdc_print_ticket (print_value) SELECT '*QUANTITY,'      + RTRIM(CAST(@number_of_copies AS char(4)))  
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
			-----------------------------------------------------------------------------------  
		   
			-- Next Page  
			SELECT @page_no = @page_no + 1  
			SELECT @printed_on_the_page = 0  
		     
			IF (@printed_details_cnt < @details_count)  
			BEGIN  
				-------------- Now let's insert the Header $ Sub Header into the output table -----------------  
				INSERT INTO #tdc_print_ticket (print_value) SELECT '*FORMAT,' + @format_id   
				INSERT INTO #tdc_print_ticket (print_value) SELECT data_field + ',' + data_value FROM #PrintData  
				INSERT INTO #tdc_print_ticket (print_value) SELECT print_value                   FROM #tdc_pack_ticket_sub_header  

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
		END -- End of 'If we reached max detail lines on the page'  
		/*-----------END: CHECK FOR BOTTOM OF PAGE -----------*/

		-- Next Detail Line  
		SELECT @printed_details_cnt = @printed_details_cnt + 1  
		SELECT @printed_on_the_page = @printed_on_the_page + 1 


		-- v6.2 Write audit record
		INSERT dbo.cvo_invoice_audit (order_no, order_ext, customer_code, ship_to, invoice_no, order_value, tax_value, freight_value, 
									discount_value, order_total, printed_date)
		VALUES (@order_no, @order_ext, @Cust_Code, @ship_to_no, @invoice_num, @order_net, @order_tax, @order_frt, @order_disc, @order_total, GETDATE())

					
		-- 4/11/2017 -- Invoice Note for SM reorders		
		IF (DATEPART(WEEKDAY,GETDATE())) = 2 -- only on Mondays
				AND GETDATE() BETWEEN '4/10/2017' AND '7/3/2017'
		BEGIN
				UPDATE co 
				SET co.invoice_note = CASE WHEN ISNULL(co.invoice_note,'') = ''
					THEN 'Place a Steve Madden reorder today and get FREE shipping!'
					ELSE ISNULL(co.invoice_note,'') + CHAR(13) + CHAR(10) + 'Place a Steve Madden reorder today and get FREE shipping!' 
					END
				FROM cvo_orders_all co
				JOIN orders o ON o.order_no = co.order_no AND o.ext = co.ext
				WHERE co.order_no = @order_no AND co.ext = @order_ext AND o.type = 'I'
				AND CHARINDEX('FREE Shipping!',ISNULL(co.invoice_note,'')) = 0 
		END


		-- Keep running totals
		IF @new_order_totals = 1
		BEGIN
			SET @cons_order_gross = @cons_order_gross + ISNULL(@order_gross,0)
			SET @cons_order_disc = @cons_order_disc + ISNULL(@order_disc,0)
			SET @cons_order_net = @cons_order_net + ISNULL(@order_net,0)
			SET @cons_order_total = @cons_order_total + ISNULL(@order_total,0)
			SET @new_order_totals = 0
		END
	END
	 
	-- These are calculated at the top of the routine for the entire consolidation set
	SET @cons_order_tax = ISNULL(@order_tax,0)
	SET @cons_order_frt = ISNULL(@order_frt,0)
  
	 ------------------ All the details have been inserted ------------------------------------  
	  
	 IF @page_no - 1 <> @total_pages  
	 BEGIN  
		INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_TAX,' + CAST(@cons_order_tax AS VARCHAR(30)))
		INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_FREIGHT,' + CAST(@cons_order_frt AS VARCHAR(30)))
		INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_GROSS,' + CAST(@cons_order_gross AS VARCHAR(30)))
		INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_DISCOUNT,' + CAST(@cons_order_disc AS VARCHAR(30)))
		INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_NET,' + CAST(@cons_order_net AS VARCHAR(30)))
		INSERT INTO #tdc_print_ticket (print_value) SELECT ('LP_ORDER_TOTAL,' + CAST(@cons_order_total AS VARCHAR(30)))

	  -------------- Now let's insert the Footer into the output table -----------------  
	  INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_PAGE_NO,'+RTRIM(CAST(@page_no AS char(4)))+' of '+RTRIM(CAST(@total_pages AS char(4)))
	  --INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_TOTAL_PAGES,' + RTRIM(CAST(@total_pages AS char(4)))  
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
	 END  
	 -----------------------------------------------------------------------------------------------  
	 FETCH NEXT FROM print_cursor INTO @format_id, @printer_id, @number_of_copies  
	END  
	  
	CLOSE      print_cursor  
	DEALLOCATE print_cursor  
	  
	RETURN
END

GO
