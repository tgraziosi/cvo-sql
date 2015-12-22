SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.1 CT 21/10/13 - Issue #1373 - extend tracking no to 30 characters
CREATE PROCEDURE [dbo].[tdc_print_ctn_pre_pack_list_sp](  
   @user_id      varchar(50),  
   @station_id   varchar(20),  
   @order_no     int,  
   @order_ext    int,  
   @carton_no    int,  
   @date_entered varchar(30))  
  
AS  
  
DECLARE  
 @Carton_Total   int,            @return_value           int,  
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
 @terms   varchar (10),   @Lot_Ser   varchar (30),  
 @Location        varchar (20), @Note    varchar (275),  
 @part_no      varchar (35), @salesperson      varchar (10),  
 @Req_Ship_Date   varchar (30), @Routing   varchar (30),  
 @Sch_Ship_Date   varchar (30), @Shipper   varchar (10),  
 @Ship_To_Add_1   varchar (40), @Ship_To_Add_2   varchar (40),  
 @Ship_To_Add_3   varchar (40), @Ship_To_Add_4   varchar (40),  
 @Ship_To_Add_5   varchar (40), @Ship_To_City   varchar (40),  
 @Ship_To_Country  varchar (40), @Ship_To_Name   varchar (40),  
 @Ship_To_No   varchar (10), @Ship_To_Region  varchar (10),  
 @Ship_To_State   char    (40), @Ship_To_Zip   varchar (10),  
 @Special_Instr   varchar (275), @insert_value           varchar (300),  
 -- START v1.1
 @Tracking_No   varchar (30),   @UPC_Code   varchar (40),   
 -- @Tracking_No   varchar (25),   @UPC_Code   varchar (40),   
 -- END v1.1
 @Weight_UOM_Carton  char    (3), @trans   varchar (15),  
 @Weight       varchar (20),   @Weight_UOM    varchar (2),  
 @format_id              varchar (40),   @printer_id             varchar (30),  
 @details_count   int,            @max_details_on_page    int,              
 @printed_details_cnt    int,            @total_pages            int,    
 @page_no                int,            @number_of_copies       int,  
 @back_ord_flag         char    (1),    @Line_No         int,   
 @dest_zone_code      varchar (8),    @salesperson_name       varchar (40),  
 @terms_desc  varchar (300), @zone_desc  varchar (40),  
 @Weight_Carton   varchar (20),   @printed_on_the_page    int,  
 @Sum_Ordered_Qty        varchar (20),   @Sum_Pack_Qty   varchar (20),  
 @header_add_note varchar (255)  
   
DECLARE @sku_code VARCHAR(16), @height DECIMAL(20,8), @width DECIMAL(20,8), @cubic_feet DECIMAL(20,8),  
  @length DECIMAL(20,8), @cmdty_code VARCHAR(8), @weight_ea DECIMAL(20,8), @so_qty_increment DECIMAL(20,8),   
  @category_1 VARCHAR(15), @category_2 VARCHAR(15), @category_3 VARCHAR(15), @category_4 VARCHAR(15), @category_5 VARCHAR(15)   
  
------------------------------------- Header Data -----------------------------------------------------------------  
  
-- Now retrieve the Orders information  
SELECT   @Order_Plus_Ext     = (CAST(@order_no  AS varchar(10)) + '-' + CAST  (@order_ext  AS varchar(10))),  
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
		 @Req_Ship_Date      = orders.req_ship_date,             
		 @Routing            = orders.routing,    
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
		 @Special_Instr      = REPLACE(orders.special_instr, CHAR(13), '/'),   
		 @salesperson        = orders.salesperson,       
		 @dest_zone_code     = orders.dest_zone_code,  
		 @back_ord_flag      = orders.back_ord_flag,  
		 @ship_to_no         = orders.ship_to,  
		 @terms              = orders.terms  
  FROM  tdc_order   (NOLOCK)  
 INNER  JOIN orders (NOLOCK) ON  
        tdc_order.order_no  = orders.order_no  
   AND  tdc_order.order_ext = orders.ext   
  LEFT  OUTER JOIN arcust (NOLOCK) ON   
 orders.cust_code = arcust.customer_code  
 WHERE  tdc_order.order_no   = @order_no  
   AND  tdc_order.order_ext  = @order_ext  
   
--BEGIN SED008 -- Global Ship To
--JVM 07/28/2010
IF EXISTS(SELECT sold_to FROM orders (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext AND sold_to IS NOT NULL AND LTRIM (sold_to) <> '' AND RTRIM (sold_to) <> '')
BEGIN
	SELECT	@ship_to_no         = a.ship_to_code,		       
			@Ship_To_Name       = a.address_name, 
			@Ship_To_Add_1      = a.addr1,  
			@Ship_To_Add_2      = a.addr2,   
			@Ship_To_Add_3      = a.addr3,  
			@Ship_To_Add_4      = a.addr4,   
			@Ship_To_Add_5      = a.addr5,  
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
   
--If user entered a date, use the entered date  
IF ISNULL(@date_entered,'') != ''  
 SELECT @date_shipped = CAST(@date_entered AS DATETIME)  
  
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
  
-- Retrieve the total number of cartons & Calculate the weight associated with   
-- the carton, & retrieve the weight_uom.  
SELECT @Carton_Total = 1,  
       @Weight       = ISNULL(CAST(weight AS varchar(20)), ''),  
       @Weight_UOM   = weight_uom  
  FROM tdc_carton_tx  
 WHERE carton_no = @carton_no  
  
-- Remove the '0' after the '.'  
EXEC tdc_trim_zeros_sp @Weight OUTPUT  
  
-- Order header additional note  
SELECT @header_add_note = CAST(note AS varchar(255))  
  FROM notes (NOLOCK)  
 WHERE code_type = 'O'  
   AND code      = @order_no             
   AND line_no   = 0  
  
IF @header_add_note IS NULL SET @header_add_note = ''  
  
EXEC tdc_parse_string_sp @header_add_note, @header_add_note OUTPUT  
   
-------------- Now let's insert the Header information into #PrintData  --------------------------------------------  
-------------- We are going to use this table in the tdc_print_label_sp --------------------------------------------  
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ORDER_NO',            CAST  (@order_no  AS varchar(10) ))  
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ORDER_EXT',           CAST  (@order_ext AS varchar(10) ))  
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ORDER_PLUS_EXT',      ISNULL(@order_plus_ext,      ''  ))  
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ADDR1',           ISNULL(@addr1,         ''  ))  
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ADDR2',           ISNULL(@addr2,         ''  ))  
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ATTENTION',           ISNULL(@attention,         ''  ))  
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CUST_CODE',           ISNULL(@cust_code,         ''  ))  
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CUST_NAME',           ISNULL(@cust_name,         ''  ))  
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CUST_ADDR1',          ISNULL(@cust_addr1,         ''  ))  
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CUST_ADDR2',         ISNULL(@cust_addr2,         ''  ))  
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CUST_ADDR3',        ISNULL(@cust_addr3,         ''  ))  
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CUST_ADDR4',        ISNULL(@cust_addr4,         ''  ))  
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CUST_ADDR5',        ISNULL(@cust_addr5,         ''  ))  
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CUST_PO',          ISNULL(@cust_po,         ''  ))  
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_DATE_SHIPPED',        ISNULL(@date_shipped,        ''  ))  
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_FREIGHT_DESCRIPTION', ISNULL(@freight_description, ''  ))  
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_FREIGHT_ALLOW_TYPE',  ISNULL(@freight_allow_type,  ''  ))  
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_LOCATION',            ISNULL(@location,            ''  ))  
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_NOTE',            ISNULL(@note,                ''  ))  
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_HEADER_ADD_NOTE',    ISNULL(@header_add_note,     ''  ))  
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_REQ_SHIP_DATE',       ISNULL(@req_ship_date,       ''  ))  
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ROUTING',            ISNULL(@routing,             ''  ))  
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SCH_SHIP_DATE',       ISNULL(@sch_ship_date,       ''  ))  
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SHIP_TO_ADD_1',       ISNULL(@ship_to_add_1,       ''  ))  
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SHIP_TO_ADD_2',       ISNULL(@ship_to_add_2,       ''  ))  
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SHIP_TO_ADD_3',       ISNULL(@ship_to_add_3,       ''  ))  
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SHIP_TO_ADD_4',       ISNULL(@ship_to_add_4,       ''  ))  
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SHIP_TO_ADD_5',       ISNULL(@ship_to_add_5,       ''  ))  
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SHIP_TO_CITY',   ISNULL(@ship_to_city,        ''  ))  
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SHIP_TO_COUNTRY',     ISNULL(@ship_to_country,     ''  ))  
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SHIP_TO_NAME',   ISNULL(@ship_to_name,        ''  ))  
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SHIP_TO_REGION',      ISNULL(@ship_to_region,      ''  ))  
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SHIP_TO_STATE',       ISNULL(@ship_to_state,       ''  ))  
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SHIP_TO_ZIP',    ISNULL(@ship_to_zip,         ''  ))  
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SPECIAL_INSTR',       ISNULL(@special_instr,       ''  ))  
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_USERID',              ISNULL(@user_id,             ''  ))  
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CARTON_TOTAL',        CAST  (@carton_total AS varchar(10)))  
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_WEIGHT',              ISNULL(@weight,              ''  ))  
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_WEIGHT_UOM',    ISNULL(@weight_uom,          ''  ))  
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SALESPERSON',    ISNULL(@salesperson,         ''  ))  
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SALESPERSON_NAME',    ISNULL(@salesperson_name,    ''  ))  
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_DEST_ZONE_CODE',    ISNULL(@dest_zone_code,      ''  ))  
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_DEST_ZONE_DESC',    ISNULL(@zone_desc,           ''  ))  
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_BACK_ORD_FLAG',   ISNULL(@back_ord_flag,       ''  ))  
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SHIP_TO_NO',    ISNULL(@ship_to_no,          ''  ))  
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_TERMS',            ISNULL(@terms,               ''  ))  
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_TERMS_DESC',    ISNULL(@terms_desc,          ''  ))  
   
IF (@@ERROR <> 0 )  
BEGIN  
 RAISERROR ('Insert into #PrintData Failed', 16, 1)       
 RETURN  
END  
  
------------------------------------------------------------------------------------------------  
  
-- Now let's run the tdc_print_label_sp to get format_id, printer_id, and number of copies -----  
EXEC @return_value = tdc_print_label_sp 'PLW', 'CTNPREPACKTKT', 'VB', @station_id  
  
-- IF label hasn't been set up for the station id, try finding a record for the user id  
IF @return_value != 0  
BEGIN  
 EXEC @return_value = tdc_print_label_sp 'PLW', 'CTNPREPACKTKT', 'VB', @user_id  
END  
  
-- IF label hasn't been set up for the user id, exit  
IF @return_value != 0  
BEGIN  
 TRUNCATE TABLE #PrintData  
 RETURN  
END  
  
-- Now let's get the 'Sub-Header' info which is: the list of all the cartons &  
-- airbill_no, carton_class, carton_ship_date, carton_type, shipper, station_id,  
-- tracking_no, weight_carton, weight_uom_carton  
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
 WHERE  order_no  = @order_no  
   AND  order_ext = @order_ext   
   AND  carton_no = @carton_no  
  
-- Remove the '0' after the '.'  
EXEC tdc_trim_zeros_sp @Weight_Carton OUTPUT  
  
INSERT INTO #tdc_pack_ticket_sub_header(print_value) VALUES('LP_CARTON_NO,'          + CAST(@carton_no AS varchar(10)))  
INSERT INTO #tdc_pack_ticket_sub_header(print_value) VALUES('LP_AIRBILL_NO,'        + ISNULL(@Airbill_No,  ''))  
INSERT INTO #tdc_pack_ticket_sub_header(print_value) VALUES('LP_CARTON_CLASS,'      + ISNULL(@Carton_Class,  ''))  
INSERT INTO #tdc_pack_ticket_sub_header(print_value) VALUES('LP_CARTON_SHIP_DATE,'  + ISNULL(@Carton_Ship_Date, ''))  
INSERT INTO #tdc_pack_ticket_sub_header(print_value) VALUES('LP_CARTON_TYPE,'       + ISNULL(@Carton_Type,  ''))  
INSERT INTO #tdc_pack_ticket_sub_header(print_value) VALUES('LP_SHIPPER,'           + ISNULL(@Shipper,  ''))  
INSERT INTO #tdc_pack_ticket_sub_header(print_value) VALUES('LP_STATION_ID,'        + ISNULL(@station_id ,  ''))  
INSERT INTO #tdc_pack_ticket_sub_header(print_value) VALUES('LP_TRACKING_NO,'       + ISNULL(@Tracking_No,  ''))  
INSERT INTO #tdc_pack_ticket_sub_header(print_value) VALUES('LP_WEIGHT_CARTON,'     + ISNULL(@Weight_Carton,  ''))  
INSERT INTO #tdc_pack_ticket_sub_header(print_value) VALUES('LP_WEIGHT_UOM_CARTON,' + ISNULL(@Weight_UOM_Carton , ''))  
    
IF (@@ERROR <> 0 )  
BEGIN  
 RAISERROR ('Insert into #tdc_pack_ticket_sub_header Failed', 16, 2)     
 RETURN  
END  
-----------------------------------------------------------------------------------------------  
  
-- Loop through the format_ids  
DECLARE print_cursor CURSOR FOR   
 SELECT format_id, printer_id, number_of_copies FROM #PrintData_Output  
  
OPEN print_cursor  
  
FETCH NEXT FROM print_cursor INTO @format_id, @printer_id, @number_of_copies  
   
WHILE (@@FETCH_STATUS <> -1)  
BEGIN  
 -------------- Now let's insert the Header $ Sub Header into the output table -----------------  
 INSERT INTO #tdc_print_ticket (print_value) SELECT '*FORMAT,' + @format_id   
 INSERT INTO #tdc_print_ticket (print_value) SELECT data_field + ',' + data_value FROM #PrintData  
 INSERT INTO #tdc_print_ticket (print_value) SELECT print_value FROM #tdc_pack_ticket_sub_header  
     
 IF (@@ERROR <> 0 )  
 BEGIN  
  CLOSE      print_cursor  
  DEALLOCATE print_cursor  
  RAISERROR ('Insert into #tdc_print_ticket Failed', 16, 3)       
  RETURN  
 END  
 -----------------------------------------------------------------------------------------------  
   
 -- Get  Count of the Details to be printed  
 SELECT @details_count = COUNT(DISTINCT part_no)   
   FROM tdc_carton_detail_tx (NOLOCK)  
  WHERE order_no  = @order_no  
    AND order_ext = @order_ext  
    AND carton_no = @carton_no  
  
 ----------------------------------  
 -- Get Max Detail Lines on a page.             
 ----------------------------------  
 SET @max_details_on_page = 0  
  
 -- First check if user defined the number of details for the format ID  
 SELECT @max_details_on_page = detail_lines      
          FROM tdc_tx_print_detail_config (NOLOCK)    
         WHERE module       = 'PPS'     
           AND trans        = 'CTNPREPACKTKT'  
           AND trans_source = 'VB'  
           AND format_id    = @format_id  
  
 -- If not defined, get the value from tdc_config  
 IF ISNULL(@max_details_on_page, 0) = 0  
 BEGIN  
  -- If not defined, default to 4  
  SELECT @max_details_on_page = ISNULL((SELECT value_str FROM tdc_config (NOLOCK) WHERE [function] = 'CTNPACKTKT_Detl_Cnt'), 4)   
 END   
    
 -- Get Total Pages  
 SELECT @total_pages =   
  CASE WHEN @details_count % @max_details_on_page = 0   
       THEN @details_count / @max_details_on_page    
            ELSE @details_count / @max_details_on_page + 1   
  END    
  
 -- First Page  
 SELECT @page_no = 1, @printed_details_cnt = 1, @printed_on_the_page = 1  
  
 ------------- Now let's get the Detail Data ----------------------------------------  
  
 ----- The details for Carton based pack tickets  are: --------------------------  
        ----- part_no, item_description, upc_code, sum_pack_qty, sum_ordered_qty --------------  
 DECLARE detail_cursor CURSOR FOR   
  SELECT DISTINCT part_no  
    FROM tdc_carton_detail_tx (NOLOCK)  
   WHERE order_no  = @order_no  
     AND order_ext = @order_ext  
        AND carton_no = @carton_no  
   ORDER BY part_no  
  
 OPEN detail_cursor  
 FETCH NEXT FROM detail_cursor INTO @part_no  
    
 WHILE (@@FETCH_STATUS <> -1)  
 BEGIN  
  -- Get item_description & upc_code of the Item   
  SELECT @UPC_Code = upc_code  
    FROM inv_master   
   WHERE part_no = @part_no  
  
  IF EXISTS(SELECT * FROM ord_list(NOLOCK)   
      WHERE order_no   = @order_no  
                      AND order_ext  = @order_ext  
        AND part_no    = @part_no  
        AND part_type != 'C')  
  BEGIN  
   SELECT TOP 1 @item_description = [description]  
     FROM ord_list(NOLOCK)   
    WHERE order_no   = @order_no  
                    AND order_ext  = @order_ext  
      AND part_no    = @part_no  
  END  
  ELSE  
  BEGIN  
   SELECT TOP 1 item_@description = [description]  
     FROM ord_list_kit(NOLOCK)   
    WHERE order_no   = @order_no  
                    AND order_ext  = @order_ext  
      AND part_no   = @part_no  
  END  
  
  -- Get Total Ordered Qty for the Item on the Order  
          SELECT @Sum_Ordered_Qty = ISNULL(  
           (SELECT CAST(SUM(ordered) AS varchar (20))  
              FROM ord_list   
                 WHERE order_no  = @order_no  
            AND order_ext = @order_ext   
        AND part_no   = @part_no), '0')  
  
  -- Get Total Packed Qty for the Item on the Order / Carton  
   SELECT @Sum_Pack_Qty = ISNULL(  
           (SELECT CAST(SUM(qty_to_pack) AS varchar (20))  
         FROM tdc_carton_detail_tx   
           WHERE order_no  = @order_no  
           AND order_ext = @order_ext   
           AND part_no   = @part_no  
           AND carton_no = @carton_no), '0')  
  
  -- Remove the '0' after the '.'  
  EXEC tdc_trim_zeros_sp @Sum_Ordered_Qty OUTPUT  
  EXEC tdc_trim_zeros_sp @Sum_Pack_Qty    OUTPUT  
    
  SELECT @sku_code = isnull(sku_code, ''), @height = height, @width = width, @length = length, @cmdty_code = isnull(cmdty_code, ''),   
   @weight_ea = weight_ea, @so_qty_increment = isnull(so_qty_increment, 0), @cubic_feet = cubic_feet   
   FROM inv_master (nolock) WHERE part_no = @part_no  
     
  SELECT @category_1 = isnull(category_1, ''), @category_2 = isnull(category_2, ''), @category_3 = isnull(category_3, ''),   
   @category_4 = isnull(category_4, ''), @category_5 = isnull(category_5, '')   
   FROM inv_master_add (nolock) WHERE part_no = @part_no  
     
  -------------- Now let's insert the Details into the output table -----------------     
  INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_PART_NO_'          + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + @part_no)  
  INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_ITEM_DESCRIPTION_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@item_description, ''))  
  INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_UPC_CODE_'         + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@upc_code,  ''))  
  INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_SUM_PACK_QTY_'     + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + @sum_pack_qty)  
  INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_SUM_ORDERED_QTY_'  + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + @sum_ordered_qty)  
  
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
  -----------------------------------------------------------------------------------------------  
  
  -- If we reached max detail lines on the page, print the Footer  
  IF @printed_on_the_page = @max_details_on_page  
  BEGIN  
   -------------- Now let's insert the Footer into the output table -----------------  
   INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_PAGE_NO,'     + RTRIM(CAST(@page_no     AS char(4)))  
   INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_TOTAL_PAGES,' + RTRIM(CAST(@total_pages AS char(4)))  
   INSERT INTO #tdc_print_ticket (print_value) SELECT '*PRINTERNUMBER,' + @printer_id  
   INSERT INTO #tdc_print_ticket (print_value) VALUES ('*QUANTITY,1')  
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
  END -- End io 'If we reached max detail lines on the page'  
  
  -- Next Detail Line  
  SELECT @printed_details_cnt = @printed_details_cnt + 1  
  SELECT @printed_on_the_page = @printed_on_the_page + 1  
  
  FETCH NEXT FROM detail_cursor INTO @part_no  
  
 END -- End of the detail_cursor  
  
 CLOSE      detail_cursor  
 DEALLOCATE detail_cursor  
  
 ------------------ All the details have been inserted ------------------------------------  
  
 IF @page_no - 1 <> @total_pages  
 BEGIN  
  -------------- Now let's insert the Footer into the output table -----------------  
  INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_PAGE_NO,'     + RTRIM(CAST(@page_no     AS char(4)))  
  INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_TOTAL_PAGES,' + RTRIM(CAST(@total_pages AS char(4)))  
  INSERT INTO #tdc_print_ticket (print_value) SELECT '*PRINTERNUMBER,' + @printer_id  
  INSERT INTO #tdc_print_ticket (print_value) VALUES ('*QUANTITY,1')  
  INSERT INTO #tdc_print_ticket (print_value) SELECT '*DUPLICATES,'    + RTRIM(CAST(@number_of_copies AS char(4)))  
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
GO
GRANT EXECUTE ON  [dbo].[tdc_print_ctn_pre_pack_list_sp] TO [public]
GO
