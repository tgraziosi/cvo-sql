SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_print_xfer_sn_pack_list_sp](
			@user_id    varchar(50),
			@station_id varchar(20),
			@xfer_no    integer)
AS

DECLARE
	@carton_no           	int,	        @Carton_Total 		int,
	@Airbill_No          	varchar (18),	@Carton_Class     	char    (10), 
	@Carton_Ship_Date    	varchar (30),	@Carton_Type      	char    (10),  
	@Cust_Addr1          	varchar (40), 	@Cust_Addr2 		varchar (40),  
	@Cust_Addr3          	varchar (40),  	@Cust_Addr4 		varchar (40),  
	@Cust_Addr5         	varchar (40),  	@Order_Plus_Ext 	varchar (20),
	@Addr1               	varchar (40),	@Addr2 			varchar (40),
	@Attention 	     	varchar (40),	@Cust_Code 		varchar (40),
	@Cust_Name          	varchar (40),	@Cust_Po 		varchar (40),
	@Date_Shipped        	varchar (30),	@Freight_Description 	varchar (20),
	@Freight_Allow_Type  	varchar (20),	@Item_Description   	varchar (275),
	@Line_No  	     	int,	        @Lot_Ser 		varchar (30),
	@from_loc 	     	varchar (20),	@Note 			varchar (275),
	@part_no 	   	varchar (35),	@salesperson	    	varchar (10),  
	@Req_Ship_Date 		varchar (30),	@Routing 		varchar (30),
	@Sch_Ship_Date 		varchar (30),	@Shipper 		varchar (10),
	@Ship_To_Add_1 		varchar (40),	@Ship_To_Add_2 		varchar (40),
	@Ship_To_Add_3 		varchar (40),	@Ship_To_Add_4 		varchar (40),
	@Ship_To_Add_5 		varchar (40),	@Ship_To_City 		varchar (40),
	@Ship_To_Country 	varchar (40),	@Ship_To_Name 		varchar (40),
	@Ship_To_No 		varchar (10),	@Ship_To_Region 	varchar (10),
	@Ship_To_State 		char    (40),	@Ship_To_Zip 		varchar (10),
	@Special_Instr 		varchar (275),	@Sum_Pack_Qty 		varchar (20),	
	-- START v1.1
	@Tracking_No 		varchar (30),   @UPC_Code 		varchar (40),	
	-- @Tracking_No 		varchar (25),   @UPC_Code 		varchar (40),	
	-- END v1.1
	@Weight_Carton 		varchar (20),   @Weight_UOM_Carton 	char    (3),	
	@Weight     		varchar (20),   @Weight_UOM  		varchar (2),
	@format_id              varchar (40),   @printer_id             varchar (30),
	@details_count 		int,            @max_details_on_page    int,            
	@printed_details_cnt    int,            @total_pages            int,  
	@page_no                int,            @number_of_copies       int,
	@trans			varchar (15),   @Sum_Ordered_Qty        varchar (20),
	@back_ord_flag	        char    (1),    @zone_desc		varchar (40),
	@dest_zone_code	    	varchar (8),    @salesperson_name       varchar (40),	 
	@return_value		int,		@terms_desc		varchar (300),
	@terms			varchar (10),   @printed_on_the_page    int,
	@date_entered  		varchar(50), 	@req_no       		varchar(50),
	@to_loc			varchar(50),	@serial_no		varchar(50), 
	@to_loc_addr1  		varchar(60),   	@to_loc_addr2        	varchar(60),  
	@to_loc_addr3        	varchar(60), 	@serial_no_raw		varchar(50),
	@to_loc_addr4  		varchar(60),   	@to_loc_addr5        	varchar(60),  
	@to_loc_name 	        varchar(70), 	@shipper_no		varchar(50),
	@shipper_name        	varchar(70), 	@name			varchar(50),
	@addr3	              	varchar(60),	@addr4	      	 	varchar(60),   
	@addr5	           	varchar(60)

DECLARE @sku_code VARCHAR(16), @height DECIMAL(20,8), @width DECIMAL(20,8), @cubic_feet DECIMAL(20,8),
	 @length DECIMAL(20,8), @cmdty_code VARCHAR(8), @weight_ea DECIMAL(20,8), @so_qty_increment DECIMAL(20,8), 
	 @category_1 VARCHAR(15), @category_2 VARCHAR(15), @category_3 VARCHAR(15), @category_4 VARCHAR(15), @category_5 VARCHAR(15) 

----------------- Header Data --------------------------------------
SELECT  DISTINCT 
	@date_entered 	= CAST(a.date_entered  AS varchar(50)),
	@from_loc 	= a.from_loc,
	@note 		= REPLACE(a.note, CHAR(13), '/'),   
	@req_no 	= a.req_no, 
	@routing 	= a.routing,
	@sch_ship_date 	= CAST(a.sch_ship_date AS varchar(50)), 
	@special_instr 	= REPLACE(a.special_instr, CHAR(13), '/'), 
	@to_loc 	= a.to_loc,      
	@to_loc_addr1 	= a.to_loc_addr1,
	@to_loc_addr2 	= a.to_loc_addr2,
	@to_loc_addr3 	= a.to_loc_addr3,
	@to_loc_addr4 	= a.to_loc_addr4,
	@to_loc_addr5 	= a.to_loc_addr5,
	@to_loc_name 	= a.to_loc_name, 
	@shipper_no 	= a.shipper_no,  
	@shipper_name 	= a.shipper_name,
	@name         	= b.[name],
	@addr1 		= b.addr1,
	@addr2		= b.addr2,
	@addr3 		= b.addr3,
	@addr4 		= b.addr4,
	@addr5 		= b.addr5
  FROM  xfers a, locations b
 WHERE  a.xfer_no  = @xfer_no
   AND  a.from_loc = b.location

EXEC tdc_parse_string_sp @Special_Instr, @Special_Instr output	
EXEC tdc_parse_string_sp @terms_desc,    @terms_desc    output	
EXEC tdc_parse_string_sp @Note,          @Note          output	

	 
-------------- Now let's insert the Header information into #PrintData  --------------------------------------------
-------------- We are going to use this table in the tdc_print_label_sp --------------------------------------------
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_XFER_NO',       CAST(@xfer_no AS varchar (20) ))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_DATE_ENTERED',  ISNULL(@date_entered,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_FROM_LOC',      ISNULL(@from_loc,		'')) 
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_NOTE',          ISNULL(@note,		''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_REQ_NO',        ISNULL(@req_no,		''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ROUTING',       ISNULL(@routing,		''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SCH_SHIP_DATE', ISNULL(@sch_ship_date,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SPECIAL_INSTR', ISNULL(@special_instr,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_TO_LOC',        ISNULL(@to_loc,		''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_TO_LOC_ADDR1',  ISNULL(@to_loc_addr1,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_TO_LOC_ADDR2',  ISNULL(@to_loc_addr2,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_TO_LOC_ADDR3',  ISNULL(@to_loc_addr3,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_TO_LOC_ADDR4',  ISNULL(@to_loc_addr4,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_TO_LOC_ADDR5',  ISNULL(@to_loc_addr5,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_TO_LOC_NAME',   ISNULL(@to_loc_name,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SHIPPER_NO',    ISNULL(@shipper_no,		''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SHIPPER_NAME',  ISNULL(@shipper_name,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_NAME',          ISNULL(@name,		''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ADDR1',	    ISNULL(@addr1,		''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ADDR2',	    ISNULL(@addr2,		''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ADDR3',	    ISNULL(@addr3,		''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ADDR4', 	    ISNULL(@addr4,		''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ADDR5', 	    ISNULL(@addr5,		''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_USER_ID',       ISNULL(@user_id,		''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_TO_LOC_CITY',   ISNULL(@user_id,		''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_TO_LOC_STATE',  ISNULL(@user_id,		''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_TO_LOC_ZIP',    ISNULL(@user_id,		''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_TO_LOC_COUNTRY',ISNULL(@user_id,		''))

IF (@@ERROR <> 0 )
BEGIN
	RAISERROR ('Insert into #PrintData Failed', 16, 1)					
	RETURN
END
------------------------------------------------------------------------------------------------

-- Now let's run the tdc_print_label_sp to get format_id, printer_id, and number of copies -----
EXEC @return_value = tdc_print_label_sp 'PPS', 'XFERSNLIST', 'VB', @station_id

-- IF label hasn't been set up for the station id, try finding a record for the user id
IF @return_value != 0
BEGIN
	EXEC @return_value = tdc_print_label_sp 'PPS', 'XFERSNLIST', 'VB', @user_id
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
	SELECT carton_no 
          FROM tdc_carton_tx (NOLOCK)
         WHERE order_no   = @xfer_no
	   AND order_ext  = 0 
	   AND status     = 'C'
	   AND order_type = 'S'
	UNION 
	SELECT tdc_carton_tx.carton_no 
 	  FROM tdc_stage_carton   (NOLOCK)
	 INNER JOIN tdc_carton_tx (NOLOCK) ON 
               tdc_stage_carton.carton_no = tdc_carton_tx.carton_no
	 WHERE tdc_carton_tx.order_no         = @xfer_no
	   AND tdc_carton_tx.order_ext        = 0
	   AND tdc_carton_tx.status           = 'S'
	   AND tdc_carton_tx.order_type	      = 'S'
           AND tdc_stage_carton.adm_ship_flag = 'N'
 	 ORDER BY carton_no

	OPEN Cartons_on_Order_Cursor	
	FETCH NEXT FROM Cartons_on_Order_Cursor INTO @carton_no

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
		   AND  order_type = 'S'

		-- Remove the '0' after the '.'
		EXEC tdc_trim_zeros_sp @Weight_Carton OUTPUT

		INSERT INTO #tdc_pack_ticket_sub_header(print_value) VALUES('LP_CARTON_NO_'         + RTRIM(CAST(@printed_details_cnt AS char(4))) + ',' + ISNULL(CAST(@carton_no AS varchar(10)), ''))
		INSERT INTO #tdc_pack_ticket_sub_header(print_value) VALUES('LP_AIRBILL_NO_'        + RTRIM(CAST(@printed_details_cnt AS char(4))) + ',' + ISNULL(@Airbill_No,        ''))
		INSERT INTO #tdc_pack_ticket_sub_header(print_value) VALUES('LP_CARTON_CLASS_'      + RTRIM(CAST(@printed_details_cnt AS char(4))) + ',' + ISNULL(@Carton_Class,      ''))
		INSERT INTO #tdc_pack_ticket_sub_header(print_value) VALUES('LP_CARTON_SHIP_DATE_'  + RTRIM(CAST(@printed_details_cnt AS char(4))) + ',' + ISNULL(@Carton_Ship_Date,  ''))
		INSERT INTO #tdc_pack_ticket_sub_header(print_value) VALUES('LP_CARTON_TYPE_'       + RTRIM(CAST(@printed_details_cnt AS char(4))) + ',' + ISNULL(@Carton_Type,       ''))
		INSERT INTO #tdc_pack_ticket_sub_header(print_value) VALUES('LP_SHIPPER_'           + RTRIM(CAST(@printed_details_cnt AS char(4))) + ',' + ISNULL(@Shipper,           ''))
		INSERT INTO #tdc_pack_ticket_sub_header(print_value) VALUES('LP_STATION_ID_'        + RTRIM(CAST(@printed_details_cnt AS char(4))) + ',' + ISNULL(@station_ID,        ''))
		INSERT INTO #tdc_pack_ticket_sub_header(print_value) VALUES('LP_TRACKING_NO_'       + RTRIM(CAST(@printed_details_cnt AS char(4))) + ',' + ISNULL(@Tracking_No,       ''))
		INSERT INTO #tdc_pack_ticket_sub_header(print_value) VALUES('LP_WEIGHT_CARTON_'     + RTRIM(CAST(@printed_details_cnt AS char(4))) + ',' + ISNULL(@Weight_Carton,     ''))
		INSERT INTO #tdc_pack_ticket_sub_header(print_value) VALUES('LP_WEIGHT_UOM_CARTON_' + RTRIM(CAST(@printed_details_cnt AS char(4))) + ',' + ISNULL(@Weight_UOM_Carton, ''))
		
		-- Next Detail Line
		SELECT  @printed_details_cnt = @printed_details_cnt + 1

		FETCH NEXT FROM Cartons_on_Order_Cursor INTO @carton_no
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

	-- Get  Count of the Details to be printed
	SELECT @details_count = COUNT(*) 
          FROM tdc_carton_detail_tx (NOLOCK)
	 WHERE order_no  = @xfer_no
	   AND order_ext = 0
	   AND serial_no IS NOT NULL
           AND serial_no != ''	
	   AND carton_no IN(SELECT carton_no FROM tdc_carton_tx (NOLOCK)
				 WHERE order_no  = @xfer_no
				   AND order_ext = 0
				   AND serial_no IS NOT NULL
			           AND serial_no != ''	
				   AND order_type = 'X')

	----------------------------------
	-- Get Max Detail Lines on a page.           
	----------------------------------
	SET @max_details_on_page = 0

	-- First check if user defined the number of details for the format ID
	SELECT @max_details_on_page = detail_lines    
          FROM tdc_tx_print_detail_config (NOLOCK)  
         WHERE module       = 'PPS'   
           AND trans        = 'XFERSNLIST'
           AND trans_source = 'VB'
           AND format_id    = @format_id

	-- If not defined, get the value from tdc_config
	IF ISNULL(@max_details_on_page, 0) = 0
	BEGIN
		-- If not defined, default to 4
		SELECT @max_details_on_page = ISNULL((SELECT value_str FROM tdc_config (NOLOCK) WHERE [function] = 'ORDPACKTKT_Detl_Cnt'), 4) 
	END
	
	-- Get Total Pages
	SELECT @total_pages = 
		CASE WHEN @details_count % @max_details_on_page = 0 
		     THEN @details_count / @max_details_on_page		
	     	     ELSE @details_count / @max_details_on_page + 1	
		END		

	-- First Page
	SELECT @page_no = 1, @printed_details_cnt = 1, @printed_on_the_page = 1

	----- For Order based pack tickets the details are: --------------------------
        ----- part_no, item_description, upc_code, sum_pack_qty, sum_ordered_qty --------------


	DECLARE detail_cursor CURSOR FOR 
		SELECT DISTINCT a.part_no,       
				a.lot_ser, 
				a.serial_no,
				a.serial_no_raw,
				b.upc_code,     
				b.[description]
	   	  FROM tdc_carton_detail_tx a (NOLOCK), inv_master b (NOLOCK)
		 WHERE order_no  = @xfer_no
	  	   AND order_ext = 0
	 	   AND a.part_no = b.part_no
		   AND serial_no IS NOT NULL
	           AND serial_no != ''	
		   AND carton_no IN(SELECT carton_no FROM tdc_carton_tx(NOLOCK)
					 WHERE order_no  = @xfer_no
				  	   AND order_ext = 0
				 	   AND a.part_no = b.part_no
					   AND serial_no IS NOT NULL
				           AND serial_no != ''	
					   AND order_type = 'X')

	OPEN detail_cursor
	
	FETCH NEXT FROM detail_cursor INTO @part_no, @lot_ser, @serial_no, @serial_no_raw, @upc_code, @item_description
		
	WHILE (@@FETCH_STATUS <> -1)
	BEGIN
		EXEC tdc_parse_string_sp @item_description, @item_description output	

		-------------- Now let's insert the Details into the output table -----------------			
		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_PART_NO_'          + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@part_no, ''))
		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_ITEM_DESCRIPTION_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@item_description, ''))
		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_UPC_CODE_'         + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@upc_code, ''))
		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_LOT_SER_'          + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@lot_ser, ''))
		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_SERIAL_NO_'        + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@serial_no, ''))
		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_SERIAL_NO_RAW_'    + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@serial_no_raw, ''))

		SELECT @sku_code = isnull(sku_code, ''), @height = height, @width = width, @length = length, @cmdty_code = isnull(cmdty_code, ''), 
			@weight_ea = weight_ea, @so_qty_increment = isnull(so_qty_increment, 0), @cubic_feet = cubic_feet 
			FROM inv_master (nolock) WHERE part_no = @part_no
			
		SELECT @category_1 = isnull(category_1, ''), @category_2 = isnull(category_2, ''), @category_3 = isnull(category_3, ''), 
			@category_4 = isnull(category_4, ''), @category_5 = isnull(category_5, '') 
			FROM inv_master_add (nolock) WHERE part_no = @part_no

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

			RAISERROR ('Insert into #PrintPackList_DTL Failed', 16, 4)				
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
		END -- End of 'If we reached max detail lines on the page'

		-- Next Detail Line
		SELECT @printed_details_cnt = @printed_details_cnt + 1
		SELECT @printed_on_the_page = @printed_on_the_page + 1

		FETCH NEXT FROM detail_cursor INTO @part_no, @lot_ser, @serial_no, @serial_no_raw, @upc_code, @item_description

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
		INSERT INTO #tdc_print_ticket (print_value) SELECT '*DUPLICATES,'    + RTRIM(CAST(@number_of_copies AS char(3)))
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
GRANT EXECUTE ON  [dbo].[tdc_print_xfer_sn_pack_list_sp] TO [public]
GO
