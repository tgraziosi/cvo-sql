SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v2.1 TM 11/29/2011 - Reset order and sched ship date
-- v3.0 RCM 1/16/2011 - REDO TOTAL PAGE CALCULATION for Consolidation
-- v3.1 CT 20/08/2012 - Add blank carton number 

CREATE PROCEDURE [dbo].[tdc_print_plw_so_pick_ticket_auto]  
   @order_no   int,  
   @order_ext  int,  
   @user_id    varchar(50)   
AS  
  
IF OBJECT_ID('tempdb..#tdc_print_ticket')   IS NOT NULL DROP TABLE #tdc_print_ticket  
IF OBJECT_ID('tempdb..#PrintData_Output')   IS NOT NULL DROP TABLE #PrintData_Output  
IF OBJECT_ID('tempdb..#PrintData')          IS NOT NULL DROP TABLE #PrintData  
IF OBJECT_ID('tempdb..#so_print_sel')      IS NOT NULL DROP TABLE #so_print_sel  
IF OBJECT_ID('tempdb..#so_pick_ticket')     IS NOT NULL DROP TABLE #so_pick_ticket  
IF OBJECT_ID('tempdb..#so_pick_ticket_details')  IS NOT NULL DROP TABLE #so_pick_ticket_details  
IF OBJECT_ID('tempdb..#so_pick_ticket_working_tbl')  IS NOT NULL DROP TABLE #so_pick_ticket_working_tbl  
IF OBJECT_ID('tempdb..#Select_Result')      IS NOT NULL DROP TABLE #Select_Result  
  
CREATE TABLE #Select_Result  
(  
 data_field varchar(300) NOT NULL,  
 data_value varchar(300)     NULL  
)  
  
CREATE TABLE #PrintData_Output  
(  
 format_id        varchar(40)  NOT NULL,  
 printer_id       varchar(30)  NOT NULL,  
 number_of_copies int          NOT NULL  
)  
  
CREATE TABLE #PrintData   
(  
 data_field varchar(300) NOT NULL,  
  data_value varchar(300)     NULL  
)  
  
CREATE TABLE #tdc_print_ticket   
(  
  row_id      int identity (1,1)  NOT NULL,   
  print_value varchar(300)        NOT NULL  
)  
  
CREATE TABLE #so_print_sel  
(                             
 order_no            int             NOT NULL,     
 order_ext           int             NOT NULL,     
 location            varchar(10)     NOT NULL,     
 sch_ship_date       datetime            NULL,     
 cust_name           varchar(40)         NULL,     
 curr_alloc_pct      decimal(20,2)       NULL,     
 sel_flg             int             NOT NULL DEFAULT 0  
)   
  
CREATE TABLE #so_pick_ticket_working_tbl  
(  
 order_no   int  not null,  
 order_ext int     not null,  
 line_no    int     not null,  
 [description] varchar(255)     null,  
 part_no  varchar(50) not null,  
 part_type char(1)  not null  
)  
  
CREATE TABLE #so_pick_ticket_details               
(                                                 
 order_no  int   NOT NULL,   
 order_ext int  NOT NULL,  
 location  varchar(10) NOT NULL,  
 sch_ship_date datetime      NULL,  
 cust_name varchar(255)     NULL,  
 curr_alloc_pct  decimal(20,2)      NULL,   
 sel_flg  int   NOT NULL DEFAULT 0,  
 alloc_type varchar(2) NULL   
)  
  
CREATE TABLE #so_pick_ticket   
(  
 cons_no  int       NULL,  
 order_no  int   NOT NULL,  
 order_ext  int   NOT NULL,  
 location  varchar (10)  NOT NULL,  
 line_no  int   NOT NULL,  
 part_no  varchar(30)  NOT NULL,  
 lot_ser  varchar(25)      NULL,  
 bin_no   varchar(12)      NULL,  
 ord_qty  decimal(20,8) NOT NULL,  
 pick_qty  decimal(20,8)  NOT NULL,  
 part_type  char(1)      NULL,  
 [user_id]  varchar(25)  NOT NULL,  
 order_date  datetime      NULL,  
 cust_po  varchar(20)      NULL,  
 sch_ship_date  datetime      NULL,  
 carrier_DESC  varchar(40)      NULL,  
 ship_to_add_1  varchar(40)      NULL,  
 ship_to_add_2  varchar(40)      NULL,  
 ship_to_add_3  varchar(40)      NULL,  
 ship_to_city  varchar(40)        NULL,  
 ship_to_country varchar(40)      NULL,  
 ship_to_name  varchar(40)      NULL,  
 ship_to_state  char(40)      NULL,  
 ship_to_zip  varchar(10)      NULL,  
 special_instr  varchar(255)      NULL,  
 order_note  varchar(255)      NULL,  
 item_note  varchar(255)      NULL,  
 uom   char(2)      NULL,  
 [description]  varchar(255)      NULL,  
 customer_name  varchar(40)      NULL,  
 addr1   varchar(40)      NULL,  
 addr2   varchar(40)      NULL,  
 addr3   varchar(40)      NULL,  
 addr4   varchar(40)      NULL,  
 addr5   varchar(40)      NULL,  
 cust_code  varchar(10)      NULL,  
 kit_caption  varchar(255)     NULL,  
 cancel_date  datetime      NULL,  
 kit_id   varchar(30)      NULL,  
 group_code_id varchar (20)      NULL,  
 seq_no   int       NULL,  
 tran_id  int           NULL,   
 dest_bin  varchar(12)      NULL,  
 trans_type      varchar(10)     NOT NULL,  
        date_expires    datetime            NULL  
)  
  
DECLARE @wd_drop_path   varchar(1000),  
 @bcpCommand     varchar(1200),  
 @global_temp_table_name varchar(25),  
 @temp   varchar(300),  
 @location     varchar(10),  
 @time_spid   varchar(50),  
 @database  varchar(128)  
  
DECLARE @sku_code VARCHAR(16), @height DECIMAL(20,8), @width DECIMAL(20,8), @cubic_feet DECIMAL(20,8),  
  @length DECIMAL(20,8), @cmdty_code VARCHAR(8), @weight_ea DECIMAL(20,8), @so_qty_increment DECIMAL(20,8),   
  @category_1 VARCHAR(15), @category_2 VARCHAR(15), @category_3 VARCHAR(15), @category_4 VARCHAR(15), @category_5 VARCHAR(15)   
  
  
DECLARE @promo_name varchar(30), @order_type varchar(60), @routing varchar(20)		-- v2.0		-- T McGrady	22.MAR.2011


----------------------------------------------------------------  
-- Get a uniq global temp table name based on the connection ID  
----------------------------------------------------------------  
-- SET @global_temp_table_name = '##tdc_bcp_out_' + CAST(@@SPID AS varchar(10))  
  
-- SELECT @location = ISNULL(location,'') FROM orders (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext  
  
----------------------------------------------------------------------  
-- Insert and "select" the order into the selected orders temp table  
-- This table is used in the print assign SP  
----------------------------------------------------------------------  
INSERT INTO #so_print_sel (order_no, order_ext, location, sel_flg)   
SELECT DISTINCT @order_no, @order_ext, location, -1  
  FROM ord_list (NOLOCK)  
 WHERE order_no = @order_no   
   AND order_ext = @order_ext  
-- VALUES (@order_no, @order_ext, @location, -1)  
  
---------------------------------------------------------------------------  
-- Execute the print assign SP and get all the data for the final print SP  
---------------------------------------------------------------------------  
INSERT INTO #so_pick_ticket_details (order_no, order_ext, location, sel_flg)  
SELECT DISTINCT @order_no, @order_ext, location, -1  
  FROM ord_list (NOLOCK)  
 WHERE order_no = @order_no   
   AND order_ext = @order_ext  
-- VALUES (@order_no, @order_ext, @location, -1)  
  
EXEC tdc_plw_so_print_assign_sp @user_id   
  
---------------------------------------------------------------------------  
-- Execute the SP that will generate the temptable with the output data  
---------------------------------------------------------------------------  
  
-- A local temporary table created in a stored procedure is dropped automatically when the stored procedure completes.   
-- The table can be referenced by any nested stored procedures executed by the stored procedure that created the table.   
-- The table cannot be referenced by the process which called the stored procedure that created the table.  
  
-- EXEC tdc_print_plw_so_pick_ticket_sp  @user_id, @user_id, @order_no, @order_ext, @location  
  
--*******************************************************************************************  
  
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
        @cursor_statement    varchar(999),  @non_qty_statement  varchar(5000),  
 @cust_sort1      varchar(40),   @cust_sort2   varchar(40),  @cust_sort3       varchar(40),
 @prt_line_no             int,
 @order_time		varchar(10)		--v2.1.5
  
  
----------------- Header Data --------------------------------------  
  
-- Now retrieve the Orders information  
SELECT DISTINCT  
		@ord_plus_ext     = CAST(order_no  AS varchar(10)) + '-' + CAST(order_ext AS varchar(4)), 
		@order_date			= convert(varchar(12),order_date,101),
		@special_instr   = REPLACE(a.special_instr, CHAR(13), '/'),      
		@order_note      = REPLACE(a.order_note, CHAR(13), '/'),     
		@sch_ship_date		= convert(varchar(12),sch_ship_date,101),  
		@addr1    = addr1,      
		@addr2    = addr2,      
		@addr3    = addr3,      
		@addr4    = addr4,      
		@addr5    = addr5,      
		@ship_to_add_1   = ship_to_add_1,  
		@ship_to_add_2   = ship_to_add_2,  
		@ship_to_add_3   = ship_to_add_3,  
		@ship_to_name    = ship_to_name,   
		@ship_to_city    = ship_to_city,   
		@ship_to_state   = ship_to_state,  
		@ship_to_country = ship_to_country,  
		@ship_to_zip     = ship_to_zip,      
		@customer_name   = customer_name,    
		@cust_po   = cust_po,        
		@cust_code   = cust_code,        
		@carrier_DESC    = carrier_DESC,     
		@print_cnt       = CASE WHEN  
						(SELECT COUNT(*)   
					FROM tdc_print_history_tbl b (nolock)  
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
-- AND location  = @location  
   AND [user_id] = @user_id  
 ORDER BY CAST(order_no  AS varchar(10)) + '-' + CAST(order_ext AS varchar(4)) --Jim 12/04/2007  


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
			@Ship_To_Name       = a.address_name,
			@Ship_To_Add_1      = a.addr1,  
			@Ship_To_Add_2      = a.addr2,   
			@Ship_To_Add_3      = a.addr3,  
			@Ship_To_City       = a.city,     
			@Ship_To_Country	= a.country_code,   
			@Ship_To_State      = a.state,     
			@Ship_To_Zip        = a.postal_code  
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
--SELECT @salesperson =   
-- ISNULL((SELECT salesperson      FROM orders   (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext AND location = @location), '')  
SELECT @salesperson_name =   
 ISNULL((SELECT salesperson_name FROM arsalesp (NOLOCK) WHERE salesperson_code = @salesperson),        '')  
--SELECT @dest_zone_code =   
-- ISNULL((SELECT dest_zone_code   FROM orders   (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext AND location = @location), '')  
SELECT @zone_DESC =   
 ISNULL((SELECT zone_DESC        FROM arzone   (NOLOCK) WHERE zone_code = @dest_zone_code),        '')  
--SELECT @back_ord_flag =   
-- ISNULL((SELECT back_ord_flag    FROM orders   (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext AND location = @location), '')  
  
SELECT @salesperson = ISNULL(salesperson, ''), @dest_zone_code = ISNULL(dest_zone_code, ''), @back_ord_flag = ISNULL(back_ord_flag, '')  
  FROM orders (NOLOCK)   
 WHERE order_no = @order_no  
   AND ext = @order_ext  
  
EXEC tdc_parse_string_sp @Special_Instr, @Special_Instr output   
  


--v2.1.5
SELECT @order_time = convert(varchar(5),date_entered,108)
	   --@order_date = date_entered
  FROM orders (NOLOCK)  
 WHERE order_no  = @order_no AND ext = @order_ext  
--v2.1.5


-- Ensure Carrier is from order header						-- v3.0 TM
SELECT @carrier_DESC = IsNull(v.addr1,' ')
  FROM orders o, arshipv v 
 WHERE o.routing = v.ship_via_code AND o.order_no = @order_no AND ext = @order_ext 
--
  
-------------- Now let's insert the Header information into #PrintData  --------------------------------------------  
-------------- We are going to use this table in the tdc_print_label_sp --------------------------------------------  
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ORDER_NO',             CAST(@order_no  AS varchar(10)))  
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ORDER_EXT',            CAST(@order_ext AS varchar(4)))  
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ORDER_PLUS_EXT',       ISNULL(@ord_plus_ext,   ''))  
--INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_LOCATION',             ISNULL(@location,   ''))  
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
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CARTON_NO',      '') -- v3.1
  

-- ADD PROMO NAME																					-- T McGrady	22.MAR.2011
SELECT @promo_name = IsNull(promo_name,'')															-- T McGrady	22.MAR.2011
FROM  CVO_orders_all o (nolock)																		-- T McGrady	22.MAR.2011
LEFT OUTER JOIN CVO_promotions p ON o.promo_id = p.promo_id AND o.promo_level = p.promo_level		-- T McGrady	22.MAR.2011
WHERE o.order_no = @order_no																		-- T McGrady	22.MAR.2011
  AND o.ext = @order_ext																			-- T McGrady	22.MAR.2011
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_PROMO_NAME', ISNULL(@promo_name, ''))	-- T McGrady	22.MAR.2011
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
IF EXISTS(SELECT sold_to FROM orders (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext AND sold_to IS NOT NULL AND LTRIM (sold_to) <> ' AND RTRIM (sold_to) <> ')
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


--------------------------------------------------------------------------------------------------  
-- Now let's run the tdc_print_label_sp to get format_id, printer_id, and number of copies -----  
EXEC @return_value = tdc_print_label_sp 'PLW', 'SOPICKTKT', 'VB', @user_id  
  
-- IF label hasn't been set up, exit  
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
  
WHILE (@@FETCH_STATUS = 0)  
BEGIN  
 -----------------------Multiple Locations-------------------------------------  
 SELECT @location = MIN(location)  
   FROM #so_pick_ticket_details  
   
 WHILE (@location IS NOT NULL)  
 BEGIN  
  INSERT INTO tdc_print_history_tbl (order_no, order_ext, location, print_date, printed_by, pick_ticket_type)  
  VALUES (@order_no, @order_ext, @location, GETDATE(), @user_id, 'S')  
  
  -------------- Now let's insert the Header into the output table -----------------  
  INSERT INTO #tdc_print_ticket (print_value) SELECT '*FORMAT,' + @format_id   
  INSERT INTO #tdc_print_ticket (print_value) SELECT data_field + ',' + data_value FROM #PrintData  
  INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_LOCATION,' + @location  
  -----------------------------------------------------------------------------------------------  
   
  ------------------------ Detail Data ----------------------------------------------------------  
  -- Get  Count of the Details to be printed  
  /*SELECT @details_count =   ------original code ROB Martin 1/16/2012
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
                AND part_type IN ('V', 'M'))  
        --    AND [user_id] = @user_id  
   */                                   ------original code ROB Martin 1/16/2012


SELECT @details_count =              --3.0 Rob Martin Start
	(select count(*)
		from tdc_pick_queue nolock
WHERE trans_type_no  = @order_no  
  and trans_type_ext =@order_ext
   and location = @location
    and ISNULL(assign_user_id,'') <> 'HIDDEN' 
     and trans = 'STDPICK')

                                                    -- 3.0 Rob Martin end

  -- Get Max Detail Lines on a page. If not defined, default to 4  
  SELECT @max_details_on_page =   
   ISNULL((SELECT value_str FROM tdc_config (NOLOCK) WHERE [function] = 'SO_Pick_Detl_Count'), 4)   
    
  -- Get Total Pages  
  SELECT @total_pages =   
   CASE WHEN @details_count % @max_details_on_page = 0   
        THEN @details_count / @max_details_on_page    
             ELSE @details_count / @max_details_on_page + 1   
   END    
           
         SELECT @order_by_val = ISNULL((SELECT value_str FROM tdc_config WHERE [function] = 'so_picktkt_sort' AND [active] = 'Y'),'0')  
   
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
   
  -- First Page  
  SELECT @page_no = 1, @printed_details_cnt = 1, @printed_on_the_page = 1  
           
         -- Declare cursor as a sring so we can dynamicaly change it  
         SELECT @cursor_statement =   
         'DECLARE detail_cursor CURSOR FOR  
    SELECT line_no, part_type,  uom, [description], ord_qty, dest_bin,  
           pick_qty AS TOPICK, part_no, lot_ser, bin_no, item_note, CAST(tran_id AS varchar(10))    
      FROM #so_pick_ticket   
     WHERE order_no  =   ' + cast(@order_no as varchar(30)) +  
     ' AND order_ext =   ' + cast(@order_ext as varchar(4)) +  
     ' AND location  = ''' +      @location                 + ''''  
     
    
  SELECT @non_qty_statement = -- We should be able to print non-qty bearing and misc part  
                 'UNION      
    SELECT line_no, part_type,  uom, [description], ordered, NULL AS dest_bin,  
           ordered AS TOPICK, part_no, NULL AS lot_ser, NULL AS bin_no, note, NULL AS tran_id     
             FROM ord_list (NOLOCK)  
     WHERE order_no  =   ' + cast(@order_no as varchar(30)) +  
     ' AND order_ext =   ' + cast(@order_ext as varchar(4)) +  
     ' AND location  = ''' +      @location                 + '''  
                        AND part_type IN (''V'', ''M'')'  
   
  EXEC (@cursor_statement + @non_qty_statement + @order_by_clause)  
   
  OPEN detail_cursor  
   
  FETCH NEXT FROM detail_cursor INTO   
   @line_no, @part_type, @uom,     @description, @ord_qty, @dest_bin,  
   @topick,  @part_no,   @lot_ser, @bin_no,      @item_note, @tran_id  
   
  WHILE (@@FETCH_STATUS = 0)  
  BEGIN  

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
		SELECT	@ConQty = CAST(pcsn AS DECIMAL(20,8)) 
		FROM	tdc_pick_queue (NOLOCK)
		WHERE	tran_id = CAST(@tran_id AS INT)
	END
	
	-- If this line is a HIDDEN one then move to the next record
	IF EXISTS (SELECT 1 FROM tdc_pick_queue (NOLOCK) WHERE tran_id = CAST(@tran_id AS INT)
				AND ISNULL(assign_user_id,'') = 'HIDDEN')
	BEGIN
	  FETCH NEXT FROM detail_cursor INTO   
	   @line_no, @part_type, @uom,     @description, @ord_qty, @dest_bin,  
	   @topick,  @part_no,   @lot_ser, @bin_no,      @item_note, @tran_id  
		
		CONTINUE
	END	
	-- v1.1 Case Part Consolidation - End 

   IF EXISTS (SELECT *   
         FROM ord_list(NOLOCK)   
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
   EXEC tdc_parse_string_sp @item_note,     @item_note    OUTPUT   
   EXEC tdc_parse_string_sp @description,   @description  OUTPUT   
   
INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_CARTON_NO,')

   -------------- Now let's insert the Details into the output table -----------------  
   -- v1.1 Case Part Consolidation
  IF @ConSet = 1
	INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_LINE_NO_'      + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + isnull(@str_line,  '')  
  ELSE
	INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_LINE_NO_'      + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + isnull(CAST(@prt_line_no AS varchar(4)),  '')  
   
--   INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_LINE_NO_'     + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + isnull(CAST(@line_no AS varchar(4)), '')     
   INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_PART_TYPE_'   + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + isnull(@part_type,               '')     
   INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_UOM_'         + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + isnull(@uom,            '')  
   INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_DESCRIPTION_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + isnull(@description,    '')  

   -- v1.1 Case Part Consolidation
  IF @ConSet = 1
  BEGIN
	  INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_ORD_QTY_'      + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + isnull(CAST(@ConQty AS varchar(20)),           '')  
	  INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_TOPICK_'       + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + isnull(CAST(@ConQty AS varchar(20)),           '')  
  END
  ELSE
  BEGIN
	  INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_ORD_QTY_'      + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + isnull(@ord_qty,           '')  
	  INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_TOPICK_'       + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + isnull(@topick,           '')  
  END

--   INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_ORD_QTY_'     + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + isnull(@ord_qty,            '')  
--   INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_TOPICK_'      + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + isnull(@topick,            '')  

   INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_PART_NO_'     + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + isnull(@part_no,            '')  
   INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_LOT_SER_'     + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + isnull(@lot_ser,                     '')  
   INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_BIN_NO_'      + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + isnull(@bin_no,                      '')  
   INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_ITEM_NOTE_'   + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + isnull(@item_note,                   '')  
   INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_TRAN_ID_'     + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + isnull(@tran_id,                     '')  
   INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_DEST_BIN_'    + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + isnull(@dest_bin,                    '')  
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
   -------------------------------------------------------------------------------------------------------------------  
   
   -- If we reached max detail lines on the page, print the Footer  
   IF @printed_on_the_page = @max_details_on_page  
   BEGIN  
    -------------- Now let's insert the Footer into the output table -------------------------------------------------  
    INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_PAGE_NO,'     + RTRIM(CAST(@page_no AS char(4)))+' of '+ RTRIM(CAST(@total_pages AS char(4)))  
    INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_TOTAL_PAGES,' + RTRIM(CAST(@total_pages AS char(4)))  
    INSERT INTO #tdc_print_ticket (print_value) SELECT '*PRINTERNUMBER,' + @printer_id  
    INSERT INTO #tdc_print_ticket (print_value) SELECT '*QUANTITY,1'  
    INSERT INTO #tdc_print_ticket (print_value) SELECT '*DUPLICATES,'    + RTRIM(CAST(@number_of_copies AS char(4)))  
    INSERT INTO #tdc_print_ticket (print_value) SELECT '*PRINTLABEL'  
    -------------------------------------------------------------------------------------------------------------------  
      
    -- Next Page  
    SELECT @page_no = @page_no + 1  
    SELECT @printed_on_the_page = 0  
   
    IF (@printed_details_cnt < @details_count)  
    BEGIN  
     -------------- Now let's insert the Header into the output table -----------------  
     INSERT INTO #tdc_print_ticket (print_value) SELECT '*FORMAT,' + @format_id   
     INSERT INTO #tdc_print_ticket (print_value) SELECT data_field + ',' + data_value FROM #PrintData  
     -----------------------------------------------------------------------------------------------  
    END  
   END  
     
   --Next Detail Line  
   SELECT @printed_details_cnt = @printed_details_cnt + 1  
   SELECT @printed_on_the_page = @printed_on_the_page + 1  
   
   FETCH NEXT FROM detail_cursor INTO   
    @line_no, @part_type, @uom,     @description, @ord_qty, @dest_bin,  
    @topick,  @part_no,   @lot_ser, @bin_no,      @item_note, @tran_id  
  END  
   
  CLOSE      detail_cursor  
  DEALLOCATE detail_cursor  
   
  IF @page_no - 1 <> @total_pages  
  BEGIN  
   -------------- Now let's insert the Footer into the output table -------------------------------------------------  
   INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_PAGE_NO,' + RTRIM(CAST(@page_no AS char(4)))+' of '+ RTRIM(CAST(@total_pages AS char(4)))   
   INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_TOTAL_PAGES,' + RTRIM(CAST(@total_pages AS char(4)))  
   INSERT INTO #tdc_print_ticket (print_value) SELECT '*PRINTERNUMBER,' + @printer_id  
   INSERT INTO #tdc_print_ticket (print_value) SELECT '*QUANTITY,'      + RTRIM(CAST(@number_of_copies AS char(3)))  
   INSERT INTO #tdc_print_ticket (print_value) SELECT '*PRINTLABEL'  
   -----------------------------------------------------------------------------------------------  
  END  
  
  SELECT @location = MIN(location)  
    FROM #so_pick_ticket_details  
   WHERE location > @location  
 END -- while loop for location  
  
 FETCH NEXT FROM print_cursor INTO @format_id, @printer_id, @number_of_copies  
END  
  
CLOSE      print_cursor  
DEALLOCATE print_cursor  
  
--*******************************************************************************************  
  
IF NOT EXISTS (SELECT * FROM #tdc_print_ticket) RETURN 0  
  
--------------------------------------------------------------------------  
-- If printer_id or qty_to_print not set up, exit  
--------------------------------------------------------------------------  
IF EXISTS (SELECT *   
      FROM #tdc_print_ticket   
     WHERE print_value = '*PRINTERNUMBER,'       
        OR print_value = '*PRINTERNUMBER,0'      
        OR print_value = '*DUPLICATES,0')  
BEGIN  
 TRUNCATE TABLE #tdc_print_ticket  
 RETURN 0  
END  
  
--------------------------------------------------------------------------  
-- Get the WDDrop path  
--------------------------------------------------------------------------  
SELECT @wd_drop_path = value_str FROM tdc_config(NOLOCK) WHERE [function] = 'wddrop_directory'  
  
IF ISNULL(@wd_drop_path, '') = ''  
BEGIN  
 RAISERROR ('Loftware WatchDog directory not set up', 16, 1)  
 RETURN -1  
END  
  
IF RIGHT(@wd_drop_path, 1) != '\' SET @wd_drop_path = @wd_drop_path + '\'  
  
--------------------------------------------------------------------------  
-- Generate the output file name  
--------------------------------------------------------------------------  
SET @wd_drop_path = @wd_drop_path + 'TDC' +   
 RIGHT(CONVERT(varchar(8),  GETDATE(), 112), 4) + REPLACE(CONVERT(varchar(12), GETDATE(), 114), ':', '') +  
 '.pas'  
    
---------------------------------------------------------------------------  
-- Create a global temp table and fill it with the data to be printed.   
-- The global temp table is used for bcp output  
---------------------------------------------------------------------------  
  
SELECT @time_spid = convert(varchar(40), getdate(), 109) + CAST(@@SPID AS varchar(10))  
  
--SET @temp = 'CREATE TABLE ' + @global_temp_table_name + '(row_id int, print_value varchar(300))'  
--EXEC (@temp)  
  
--SET @temp = 'INSERT INTO  ' + @global_temp_table_name + ' SELECT * FROM #tdc_print_ticket'  
--EXEC (@temp)  
  
INSERT INTO tdc_bcp_print_values (row_id, print_value, time_spid)  
SELECT row_id, print_value, @time_spid  
  FROM #tdc_print_ticket  
ORDER BY row_id  
  
SELECT @database = db_name(dbid) FROM master.dbo.sysprocesses (nolock) WHERE SPID = @@SPID  
  
--------------------------------------------------------------------------  
-- Import data into the .pas file  
--------------------------------------------------------------------------  
--SET @bcpCommand = 'bcp "SELECT print_value FROM tempdb..' + @global_temp_table_name + ' ORDER BY row_id" queryout "' + @wd_drop_path + '" -t -c'  
   
SET @bcpCommand = 'bcp "SELECT print_value FROM ' + @database + '..tdc_bcp_print_values (nolock) WHERE time_spid = ''' + @time_spid + ''' ORDER BY row_id" queryout "' + @wd_drop_path + '" -t -c'  
EXEC master..xp_cmdshell @bcpCommand, no_output  
  
---------------------------------------------------------------------------  
-- Drop the global temp table   
---------------------------------------------------------------------------  
--SET @temp = 'DROP TABLE ' + @global_temp_table_name   
--EXEC (@temp)  
  
DELETE FROM tdc_bcp_print_values WHERE time_spid = @time_spid  
  
---------------------------------------------------------------------------  
-- Mark order as printed  
---------------------------------------------------------------------------  
UPDATE orders                
   SET status       = 'Q',   
       printed      = 'Q',    
       date_printed = GETDATE()               
 WHERE order_no     = @order_no      
   AND ext          = @order_ext  
          
RETURN 0 



GO
GRANT EXECUTE ON  [dbo].[tdc_print_plw_so_pick_ticket_auto] TO [public]
GO
