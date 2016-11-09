SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- EXEC [tdc_print_plw_so_pick_ticket_sp] '1', '999', 1305, 0, 'CVO'
-- v1.0 CB 04/04/2011 - 6.Consolidation
-- v1.1 CB 11/05/2011 - Case Part Consolidation
-- v2.0 TM 07/13/2011 - Pass Order Type to Pick Ticket
-- v2.1 TM 11/29/2011 - Reset order and sched ship date
-- v3.0 RCM 1/16/2011 - REDO TOTAL PAGE CALCULATION for Consolidation
-- v4.0 DM 01/31/2011 - Add SO Display Line
-- v5.0 TM 03/16/2012 - Add Customer Type
-- v5.1 CT 26/07/2012 - For autopack stock orders, start a new page for each carton
-- v5.2 CT 30/07/2012 - Fix for consolidated cases
-- v5.3 CT 03/08/2012 - Move #pick_ticket table create to top of SP
-- v5.4 CT 08/08/2012 - Consolidated cases fix for autopack stock orders 
-- v5.5	CT 20/08/2012 - Ensure header is printed on last page, fix required to no_of_details calc	
-- v5.6 CT 20/08/2012 - Add carton no to header
-- v5.7 CB 29/08/2012 - Fix issue where parts are not appearing on the correct carton page
-- v5.8 CT 08/10/2012 - Corrected autopack logic issue where carton change coincides with std page break
-- v5.9 CB 10/10/2012 - Issue #901 - Autopick cases - do not display the tran id if autopick cases is on and the case is related
-- v6.0 CT 06/11/2012 - Add order summary
-- v6.1 CB 17/01/2013 - Issue #1108 Add flag for custom
-- v6.2 CB 11/09/2013 - Issue #1370 - Object already created
-- v6.3 CT 10/04/2014 - Issue #572 - Label is now shared with consolidated pick list, some field labels now passed as parameters
-- v6.4 CB 10/06/2015 - Fix issue when lines are deleted on the order but have not been unallocated. Page numbering goes out.
-- v6.5 CB 13/01/2016 - #1586 - When orders are allocated or a picking list printed then update backorder processing
-- v6.6 CB 02/03/2016 - Add link to polarized lines
-- v6.7 CB 09/06/2016 - Deal with manual case quantities
-- v6.8 CB 15/06/2016 - Fix issue with multiple case lines
-- v6.9 CB 11/07/2016 - Need to recalc line count if order has manual case quantities
-- v7.0 CB 23/08/2016 - CVO-CF-49 - Dynamic Custom Frames

CREATE PROCEDURE [dbo].[tdc_print_plw_so_pick_ticket_sp]  
 @user_id     varchar(50),  
 @station_id  varchar(20),  
 @order_no    int,  
 @order_ext   int,  
 @location    varchar(10)  
AS  
  
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
 @prt_line_no             int,					--v2.,0
 @display_line            int,					--v4.,0
 @order_time		varchar(10),		--v2.1.5
 @polarized_line varchar(40), -- v6.6
 @man_case int, -- v6.7
 @man_count int, -- v6.9
 @kit_count int -- v7.0
   
DECLARE @sku_code VARCHAR(16), @height DECIMAL(20,8), @width DECIMAL(20,8), @cubic_feet DECIMAL(20,8),  
  @length DECIMAL(20,8), @cmdty_code VARCHAR(8), @weight_ea DECIMAL(20,8), @so_qty_increment DECIMAL(20,8),   
  @category_1 VARCHAR(15), @category_2 VARCHAR(15), @category_3 VARCHAR(15), @category_4 VARCHAR(15), @category_5 VARCHAR(15)   

DECLARE @promo_name varchar(30), @order_type varchar(60), @routing varchar(20)		-- T McGrady	22.MAR.2011			-- v2.0

DECLARE @summary1 VARCHAR(60),@summary2 VARCHAR(60),@summary3 VARCHAR(60) -- v6.0

DECLARE @display_carton INT	-- v5.6
-- START v5.1
DECLARE @is_autopack			SMALLINT,
		@carton_id				INT,
		@carton_lines			INT,
		@max_carton_id			INT,
		@carton_sql				VARCHAR(100),
		@prev_carton_id			INT,
		@carton_on_the_page		INT,
		@reqd_lines				INT

IF EXISTS(SELECT 1 FROM dbo.CVO_autopack_carton (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext)
BEGIN
	SET @is_autopack = 1
	SELECT @max_carton_id = MAX(carton_id) FROM dbo.CVO_autopack_carton (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext
END
ELSE
BEGIN
	SET @is_autopack = 0
END
-- END v5.1 

-- v5.9 Start
DECLARE @autopick_cases	smallint

IF EXISTS (SELECT 1 FROM dbo.tdc_config WHERE [function] = 'AUTOPICK_CASES' and active = 'Y')
	SET @autopick_cases = 1
ELSE
	SET @autopick_cases = 0
-- v5.9 End


-- START v5.3
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
-- END v5.3
----------------- Header Data --------------------------------------  
  
-- Now retrieve the Orders information  
SELECT DISTINCT  
		@ord_plus_ext		= CAST(order_no  AS varchar(10)) + '-' + CAST(order_ext AS varchar(4)),  
		@order_date			= convert(varchar(12),order_date,101),
		@special_instr		= REPLACE(a.special_instr, CHAR(13), '/'),      
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
 WHERE customer_code = @cust_code								--v4.0
--   AND orders.ext       = @order_ext   
--   AND orders.cust_code = armaster.customer_code  
--   AND orders.ship_to   = armaster.ship_to_code     
--   AND armaster.address_type = (SELECT MAX(address_type)   
--                    FROM armaster (NOLOCK)   
--                WHERE customer_code = orders.cust_code   
--                   AND ship_to_code  = orders.ship_to)   
  
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

-- Ensure Carrier is from order header						-- v3.0 TM
SELECT @carrier_DESC = IsNull(v.addr1,' ')
  FROM orders o, arshipv v 
 WHERE o.routing = v.ship_via_code AND o.order_no = @order_no AND ext = @order_ext 
--
  
IF @header_add_note IS NULL SET @header_add_note = ''  
  
EXEC tdc_parse_string_sp @header_add_note, @header_add_note OUTPUT  

--v2.1.5
SELECT @order_time = convert(varchar(5),date_entered,108)
--		@order_date = date_entered,   
--		@sch_ship_date = sch_ship_date
  FROM orders (NOLOCK)  
 WHERE order_no  = @order_no AND ext = @order_ext  
--v2.1.5
  
-------------- Now let's insert the Header information into #PrintData  --------------------------------------------  
-------------- We are going to use this table in the tdc_print_label_sp --------------------------------------------  
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ORDER_NO',             CAST(@order_no  AS varchar(10)))  
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ORDER_EXT',            CAST(@order_ext AS varchar(4)))  
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ORDER_PLUS_EXT',       ISNULL(@ord_plus_ext,   ''))  
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_LOCATION',             ISNULL(@location,    ''))  
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SPECIAL_INSTR',        ISNULL(@special_instr,   ''))   
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ORDER_NOTE',           ISNULL(@order_note,   ''))  
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CUST_PO',             ISNULL(@cust_po,    ''))  
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
-- START v6.3
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_IS_CONSOLIDATED',     '')
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_INSTRUCT_TEXT',     'Special Instructions:')
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_BARCODE_HDR',     'Sales Order No.:')
-- END v6.3


-- ADD PROMO NAME																					-- T McGrady	22.MAR.2011
SELECT @promo_name = IsNull(p.promo_name,'')														-- T McGrady	22.MAR.2011
FROM  CVO_orders_all o (nolock)																		-- T McGrady	22.MAR.2011
LEFT OUTER JOIN CVO_promotions p ON o.promo_id = p.promo_id AND o.promo_level = p.promo_level		-- T McGrady	22.MAR.2011
WHERE o.order_no = @order_no																		-- T McGrady	22.MAR.2011
  AND o.ext = @order_ext																			-- T McGrady	22.MAR.2011
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_PROMO_NAME',ISNULL(@promo_name,' '))	-- T McGrady	22.MAR.2011
--																									-- T McGrady	22.MAR.2011

SELECT @order_type = p.category_code+'/'+p.category_desc, @routing = o.routing						-- v2.0
FROM  orders o (nolock)																				-- v2.0
LEFT OUTER JOIN so_usrcateg p ON o.user_category = p.category_code									-- v2.0
WHERE o.order_no = @order_no																		-- v2.0
  AND o.ext = @order_ext																			-- v2.0
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ORDER_TYPE',ISNULL(@order_type,' '))	-- v2.0
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ROUTING',ISNULL(@routing,' '))			-- v2.0
--																									-- v2.0


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

-- v1.0 Start
IF EXISTS(SELECT 1 FROM dbo.cvo_consolidate_shipments WHERE order_no = @order_no AND order_ext = @order_ext)
	SET @LP_CONSOLIDATED_SHIPMENT = 'CONSOLIDATED SHIPMENT'
-- v1.0 End

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

TRUNCATE TABLE #PrintData_Output -- v7.0
  
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

-- v6.4 Start
SELECT @details_count =              --3.0 Rob Martin Start
	(select COUNT(a.line_no)
		FROM tdc_pick_queue a (NOLOCK)
		JOIN ord_list b (NOLOCK)
		ON a.trans_type_no = b.order_no
		AND a.trans_type_ext = b.order_ext
		AND a.line_no = b.line_no
		WHERE a.trans_type_no  = @order_no  
		and a.trans_type_ext =@order_ext
		and a.location = @location
		and ISNULL(a.assign_user_id,'') <> 'HIDDEN' 
		and a.trans = 'STDPICK')
-- v6.4 End

                                                    -- 3.0 Rob Martin end

-- v7.0 Start
	IF OBJECT_ID('tempdb..#CF_kits') IS NOT NULL
		DROP TABLE #CF_kits

	CREATE TABLE #CF_kits (
		order_no	int,
		order_ext	int,
		line_no		int,
		ord_qty		decimal(20,8),
		line_desc	varchar(60),
		kit_id		varchar(30))

	INSERT	#CF_kits
	SELECT	a.order_no, a.order_ext, a.line_no, MIN(a.ord_qty), MIN(a.kit_caption), MIN(a.kit_id)
	FROM	#so_pick_ticket a
	WHERE	a.order_no = @order_no
	AND		a.order_ext = @order_ext
	AND		a.part_type = 'C'
	GROUP BY a.order_no, a.order_ext, a.line_no

	DELETE	a
	FROM	#so_pick_ticket a
	JOIN	#CF_kits b
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	AND		a.kit_id = b.kit_id
	AND		a.part_no <> b.kit_id
	WHERE	a.order_no = @order_no
	AND		a.order_ext = @order_ext
	AND		a.part_type = 'C'

	SET @kit_count = @@ROWCOUNT

	IF (@kit_count IS NULL)
		SET @kit_count = 0

	DROP TABLE #CF_kits
-- v7.0 End

	
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
	-- Call routine to populate #cvo_ord_list with the frame/case relationship
	EXEC CVO_create_fc_relationship_sp @order_no, @order_ext
END
-- v5.9 End
     
-- Declare cursor as a sring so we can dynamicaly change it  , date_expires   SED009 -- Pick List Printing -- date_expires should not be included into cursor
-- START v5.1 
 IF @is_autopack = 1
 BEGIN
	-- START v5.3
	/*
	-- Create temporary table for details
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
	*/
	DELETE FROM #pick_ticket
	-- END v5.3
	
	-- Load details into table
	INSERT #pick_ticket
	SELECT	order_no, order_ext, location, line_no, part_type,  uom, [description], ord_qty, dest_bin,  
			pick_qty, part_no, lot_ser, bin_no, item_note, tran_id,0 AS carton_id 
	FROM #so_pick_ticket   
	WHERE order_no  = @order_no
	AND order_ext = @order_ext 
	AND location  = @location

	IF EXISTS (SELECT 1 FROM #pick_ticket)
	BEGIN
		-- Transform data to split by carton
		EXEC dbo.CVO_transform_pickticket_for_autopack_carton_sp @order_no,@order_ext, @max_carton_id
	END

	-- START v5.4
	-- Now we know what pick records are assigned to each carton we can calculate number of pages
	-- calculate total pages
	SET @total_pages = 0  
		
	SET @details_count = 0	  	-- v5.5
	
	-- Check how many items are on each carton  
	SET @carton_id = 0  
	WHILE 1=1  
	BEGIN  
		SELECT TOP 1  
			@carton_id = carton_id  
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
	  
		-- Get lines to display for carton
		SELECT 
			@carton_lines = COUNT(1)
		FROM
			#pick_ticket a (NOLOCK)
		INNER JOIN
			tdc_pick_queue b (NOLOCK)
		ON
			CAST(a.tran_id AS INT) = b.tran_id
		WHERE
			ISNULL(b.assign_user_id,'') <> 'HIDDEN'
			AND a.carton_id = @carton_id

		SELECT @total_pages = @total_pages + CASE WHEN @carton_lines % @max_details_on_page = 0 THEN @carton_lines / @max_details_on_page ELSE @carton_lines / @max_details_on_page + 1 END      
		SET @details_count = @details_count + @carton_lines -- v5.5
	    
	END  
	   
	-- Now get how many are not on cartons  
	SELECT   
		@carton_lines = COUNT(1)  
	FROM   
		dbo.tdc_pick_queue a (NOLOCK)  
	LEFT JOIN  
		dbo.CVO_autopack_carton b (NOLOCK)  
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
	SET @details_count = @details_count + @carton_lines -- v5.5
	-- END v5.4


	


	-- Populate cursor from temp table
	SELECT @cursor_statement =	'DECLARE detail_cursor CURSOR FOR  
								SELECT line_no, part_type,  uom, [description], ord_qty, dest_bin,  
								pick_qty, part_no, lot_ser, bin_no, item_note, CAST(tran_id AS varchar(10)), carton_id, 0 
								FROM #pick_ticket   
								WHERE order_no  =   ' + cast(@order_no as varchar(30)) +  
								' AND order_ext =   ' + cast(@order_ext as varchar(4)) +  
								' AND location  = ''' +      @location                 + ''''  
	    
	 -- We should be able to print non-qty bearing and misc part  , date_expires = ''	SED009 -- Pick List Printing -- date_expires should not be included into cursor
	 SELECT @non_qty_statement =	'UNION      
									SELECT line_no, part_type,  uom, [description], ordered, NULL AS dest_bin, 
									pick_qty = ordered, part_no, NULL AS lot_ser, NULL AS bin_no, note, NULL AS tran_id, ' + CAST(@max_carton_id + 1 AS VARCHAR(10)) + ' AS carton_id, 0     
									FROM ord_list (NOLOCK)  
									WHERE order_no  =   ' + cast(@order_no as varchar(30)) +  
									' AND order_ext =   ' + cast(@order_ext as varchar(4)) +  
									' AND location  = ''' +      @location                 + '''  
									AND part_type IN (''V'', ''M'') '

 END
 ELSE
 BEGIN

	-- v6.7 Start
	IF OBJECT_ID('tempdb..#man_cases') IS NOT NULL
		DROP TABLE #man_cases

	CREATE TABLE #man_cases (
		order_no	int,
		order_ext	int,
		line_no		int,
		ord_qty		decimal(20,8),
		alloc_qty	decimal(20,8),
		man_qty		decimal(20,8),
		man_line	int)

	INSERT	#man_cases
-- v6.8 SELECT	a.order_no, a.order_ext, a.line_no, a.ord_qty, a.pick_qty, a.pick_qty - c.pick_qty , 0
	SELECT	a.order_no, a.order_ext, a.line_no, a.ord_qty, a.pick_qty, a.pick_qty - SUM(c.pick_qty) , 0 -- v6.8
	FROM	#so_pick_ticket a
	JOIN	#cvo_ord_list b
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	JOIN	#so_pick_ticket c
	ON		a.order_no = c.order_no
	AND		a.order_ext = c.order_ext
	AND		b.from_line_no = c.line_no
	WHERE	a.order_no = @order_no
	AND		a.order_ext = @order_ext
	AND		b.is_case = 1
	GROUP BY a.order_no, a.order_ext, a.line_no, a.ord_qty, a.pick_qty -- v6.8


	INSERT #so_pick_ticket (cons_no, order_no, order_ext, location, line_no, part_no, lot_ser, bin_no, ord_qty, pick_qty, part_type, user_id, order_date, cust_po, sch_ship_date, carrier_desc, 
							ship_to_add_1, ship_to_add_2, ship_to_add_3, ship_to_city, ship_to_country, ship_to_name, ship_to_state, ship_to_zip, special_instr, order_note, item_note, 
							uom, description, customer_name, addr1, addr2, addr3, addr4, addr5, cust_code, kit_caption, cancel_date, kit_id, group_code_id, seq_no, 
							tran_id, dest_bin, trans_type, date_expires)
	SELECT	a.cons_no, a.order_no, a.order_ext, a.location, a.line_no, a.part_no, a.lot_ser, a.bin_no, b.man_qty, b.man_qty, a.part_type, a.user_id, a.order_date, a.cust_po, a.sch_ship_date, a.carrier_desc, 
			a.ship_to_add_1, a.ship_to_add_2, a.ship_to_add_3, a.ship_to_city, a.ship_to_country, a.ship_to_name, a.ship_to_state, a.ship_to_zip, a.special_instr, a.order_note, a.item_note, 
			a.uom, a.description, a.customer_name, a.addr1, a.addr2, a.addr3, a.addr4, a.addr5, a.cust_code, 'NEW', a.cancel_date, a.kit_id, a.group_code_id, a.seq_no, 
			a.tran_id, a.dest_bin, a.trans_type, a.date_expires
	FROM	#so_pick_ticket a
	JOIN	#man_cases b
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	WHERE	a.order_no = @order_no
	AND		a.order_ext = @order_ext
	AND		b.man_qty > 0

	UPDATE	a
	SET		pick_qty = a.pick_qty - b.man_qty
	FROM	#so_pick_ticket a
	JOIN	#man_cases b
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	WHERE	a.order_no = @order_no
	AND		a.order_ext = @order_ext
	AND		b.man_qty > 0
	AND ISNULL(a.kit_caption,'') <> 'NEW'
	-- v6.7 End

	-- v6.9 Start
	SELECT @man_count = (SELECT COUNT(1) FROM #so_pick_ticket WHERE kit_caption = 'NEW')
	SELECT @details_count = @details_count + ISNULL(@man_count,0) - @kit_count -- v7.0          
	
	SELECT @total_pages =   
	  CASE WHEN @details_count % @max_details_on_page = 0   
		   THEN @details_count / @max_details_on_page    
				ELSE @details_count / @max_details_on_page + 1   
	  END    
	-- v6.9 End

	SELECT @cursor_statement =	'DECLARE detail_cursor CURSOR FOR  
								SELECT line_no, part_type,  uom, [description], ord_qty, dest_bin,  
								pick_qty, part_no, lot_ser, bin_no, item_note, CAST(tran_id AS varchar(10)),1 AS carton_id, CASE WHEN ISNULL(kit_caption,'''') = ''NEW'' THEN 1 ELSE 0 END 
								FROM #so_pick_ticket   
								WHERE order_no  =   ' + cast(@order_no as varchar(30)) +  
								' AND order_ext =   ' + cast(@order_ext as varchar(4)) +  
								' AND location  = ''' +      @location                 + ''''  
	    
    -- We should be able to print non-qty bearing and misc part  , date_expires = ''	SED009 -- Pick List Printing -- date_expires should not be included into cursor
	SELECT @non_qty_statement =	'UNION      
								SELECT line_no, part_type,  uom, [description], ordered, NULL AS dest_bin,  
								pick_qty = ordered, part_no, NULL AS lot_ser, NULL AS bin_no, note, NULL AS tran_id,1 AS carton_id, 0   
								FROM ord_list (NOLOCK)  
								WHERE order_no  =   ' + cast(@order_no as varchar(30)) +  
								' AND order_ext =   ' + cast(@order_ext as varchar(4)) +  
								' AND location  = ''' +      @location                 + '''  
								AND part_type IN (''V'', ''M'')'  
 END 
-- END v5.1

 EXEC (@cursor_statement + @non_qty_statement + @order_by_clause)  

  
 OPEN detail_cursor  
  
 FETCH NEXT FROM detail_cursor INTO   
  @line_no, @part_type, @uom,     @description, @ord_qty, @dest_bin,  
  @topick,  @part_no,   @lot_ser, @bin_no,      @item_note, @tran_id, @carton_id,	-- v5.1  
 @man_case -- v6.7
  
 SET @prev_carton_id = @carton_id	-- v5.1
 SET @display_carton = 1 -- v5.4

 WHILE (@@FETCH_STATUS <> -1)  
 BEGIN  


	-- START v6.0 - order summary
	IF @page_no = 1
	BEGIN
		EXEC cvo_pick_ticket_summary_sp @order_no,@order_ext,@location,@summary1 OUTPUT,@summary2 OUTPUT,@summary3 OUTPUT
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
	   @topick,  @part_no,   @lot_ser, @bin_no,      @item_note, @tran_id, @carton_id,	-- v5.1  
		@man_case -- v6.7

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
 
  IF EXISTS(SELECT * FROM ord_list(NOLOCK)   
      WHERE order_no   = @order_no  
                      AND order_ext  = @order_ext  
        AND line_no    = @line_no  
        AND part_type != 'C')  
  BEGIN  
   SELECT TOP 1 @description = [description]  
     FROM ord_list(NOLOCK)   
    WHERE order_no   = @order_no  
                    AND order_ext  = @order_ext  
      AND location   = @location  
      AND line_no    = @line_no  
  END  
  ELSE  
  BEGIN  
   SELECT TOP 1 @description = [description]  
     FROM ord_list_kit(NOLOCK)   
    WHERE order_no   = @order_no  
                    AND order_ext  = @order_ext  
      AND line_no    = @line_no  
      AND part_no   = @part_no  
  END  
  
  -- Order detail additional note  
  SELECT @detail_add_note = CAST(note AS varchar(255))  
    FROM notes (NOLOCK)  
   WHERE code_type = 'O'  
     AND code      = @order_no             
     AND line_no   = @line_no  
    
  IF @detail_add_note IS NULL SET @detail_add_note = ''  
    
  SELECT @prt_line_no = display_line FROM ord_list(NOLOCK) 
   WHERE order_no = @order_no AND order_ext = @order_ext AND line_no = @line_no  

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

	  IF EXISTS(SELECT buying_group FROM CVO_orders_all WHERE order_no = @order_no AND ext = @order_ext AND buying_group IS NOT NULL AND buying_group != '' )
		BEGIN
	  	  --qty is already added in this file
		    SELECT @list_price = CAST(price_a AS DECIMAL (20,2))
		    FROM   inventory 
		    WHERE  part_no = @part_no AND location = @Location	
		    INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_BUYING_GROUP,Buying Group: Yes')   	  			
		END
	  ELSE
		BEGIN
			-- Print List price always
		    SELECT @list_price = CAST(price_a AS DECIMAL (20,2))								-- T McGrady	22.MAR.2011
		    FROM   inventory																	-- T McGrady	22.MAR.2011
		    WHERE  part_no = @part_no AND location = @Location									-- T McGrady	22.MAR.2011
			--shipped, curr_price, discount as 'discount %', total_tax,
			-- v1.1 Case Part Consolidation Start
			IF @ConSet = 1
			BEGIN
				SELECT @gross_price     = CAST((@ConQty * ol.curr_price) AS DECIMAL (20,2)),													--as Line_1_Gross,
					   @net_price       = CAST(((@ConQty * ol.curr_price * ((100 - ol.discount)/100)) + ol.total_tax)AS DECIMAL (20,2)),		--as Line_1_Net, 
					   @discount_amount = CAST((@ConQty * ol.curr_price * (ol.discount/100)) AS DECIMAL (20,2)),								--as Line_1_DiscAmt
					   @discount_pct    = CAST((ol.discount) AS DECIMAL (20,2))																--as Line_1_DiscPct
				FROM   ord_list ol (nolock) , tdc_soft_alloc_tbl sa (nolock)
				WHERE  ol.order_no = sa.order_no	AND
					   ol.order_ext = sa.order_ext	AND
					   ol.line_no   = sa.line_no	AND
					   ol.order_no  = @order_no		AND 
					   ol.order_ext = @order_ext	AND 
					   ol.part_no   = @part_no		AND 
					   ol.location  = @Location 
			END
			ELSE
			BEGIN
				SELECT @gross_price     = CAST((sa.qty * ol.curr_price) AS DECIMAL (20,2)),													--as Line_1_Gross,
					   @net_price       = CAST(((sa.qty * ol.curr_price * ((100 - ol.discount)/100)) + ol.total_tax)AS DECIMAL (20,2)),		--as Line_1_Net, 
					   @discount_amount = CAST((sa.qty * ol.curr_price * (ol.discount/100)) AS DECIMAL (20,2)),								--as Line_1_DiscAmt
					   @discount_pct    = CAST((ol.discount) AS DECIMAL (20,2))																--as Line_1_DiscPct
				FROM   ord_list ol (nolock) , tdc_soft_alloc_tbl sa (nolock)
				WHERE  ol.order_no = sa.order_no	AND
					   ol.order_ext = sa.order_ext	AND
					   ol.line_no   = sa.line_no	AND
					   ol.order_no  = @order_no		AND 
					   ol.order_ext = @order_ext	AND 
					   ol.part_no   = @part_no		AND 
					   ol.location  = @Location 
			END					   
			-- v1.1 Case Part Consolidation Start

			INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_BUYING_GROUP,Buying Group: No')   	  			
		END

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
	INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_LINE_NO_'      + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + isnull(CAST(@prt_line_no AS varchar(4)),  '')  

--  INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_LINE_NO_'      + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + isnull(CAST(@line_no AS varchar(4)),  '')  

-- v4.0
  INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_DISPLAY_LINE_NO_'      + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + isnull(CAST(@prt_line_no AS varchar(4)),  '') 
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

  -- v6.6 Start
	IF EXISTS (SELECT 1 FROM #cvo_ord_list WHERE from_line_no = @line_no AND is_polarized = 1)
	BEGIN
		SELECT @polarized_line = ISNULL(@part_no,'') + ' (Plrzd Ln ' + CAST(line_no as varchar(10)) + ')' FROM #cvo_ord_list WHERE from_line_no = @line_no AND is_polarized = 1
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_PART_NO_'      + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + isnull(@polarized_line,'')
	END
	ELSE
	BEGIN
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_PART_NO_'      + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + isnull(@part_no,           '')  
	END
  -- v6.6 End

  INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_LOT_SER_'      + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + isnull(@lot_ser,                      '')  
  INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_BIN_NO_'       + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + isnull(@bin_no,                       '')  
  INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_ITEM_NOTE_'  + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + isnull(@item_note,                    '')  

  -- v5.9 Start
	IF @autopick_cases = 1
	BEGIN
		-- Check if this is a related case which will be autopicked
		IF EXISTS (SELECT 1 FROM #cvo_ord_list WHERE order_no = @order_no AND order_ext = @order_ext AND line_no = @line_no AND  from_line_no <> 0 AND is_case = 1)
		BEGIN
			-- v6.7 Start
			IF (@man_case = 0)
				SET @tran_id = ''
			-- v6.7
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
   @topick,  @part_no,   @lot_ser, @bin_no,      @item_note, @tran_id, @carton_id,	-- v5.1 
	@man_case -- v6.7

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

-- v6.5 Start
EXEC dbo.cvo_update_bo_processing_sp 'P', @order_no, @order_ext
-- v6.5 End

  
RETURN 





GO


GRANT EXECUTE ON  [dbo].[tdc_print_plw_so_pick_ticket_sp] TO [public]
GO
