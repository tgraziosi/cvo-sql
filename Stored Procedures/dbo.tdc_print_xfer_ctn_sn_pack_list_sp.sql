SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_print_xfer_ctn_sn_pack_list_sp](
			@user_id    varchar(50),
			@station_id varchar(20),
			@xfer_no   int,
			@carton_no  int)
AS


DECLARE	
	@airbill_no          	VARCHAR (18),   @carton_class     	CHAR    (10), 
	@address1 		VARCHAR (40),	@date_shipped        	VARCHAR (30),
	@address2 		VARCHAR (40),	@shipper 		VARCHAR (10),
	@address3 		VARCHAR (40),	@city 		        VARCHAR (40),
	@attention 	     	VARCHAR (40),	@cust_code 		VARCHAR (40),
	@to_loc			VARCHAR (20),   @to_loc_name		VARCHAR (40),
	@from_loc 	     	VARCHAR (20),	@carton_type      	CHAR    (10), 
	@cust_name          	VARCHAR (40),	@cust_po 		VARCHAR (40),
	@country 	        VARCHAR (40),	@ship_to_name 		VARCHAR (40),
	-- START v1.1
	@ship_to_no 		VARCHAR (10),	@tracking_no 		VARCHAR (30),
	-- @ship_to_no 		VARCHAR (10),	@tracking_no 		VARCHAR (25),
	-- END v1.1
	@state 		        CHAR    (40),	@zip 		        VARCHAR (10),
	@weight     		VARCHAR (20),   @weight_uom  		VARCHAR (2),
	@format_id              VARCHAR (40),   @printer_id             VARCHAR (30),
	@number_of_copies       INT,            @carrier_code           VARCHAR (10),
	@template_code          VARCHAR (10),   @return_value		INT,
	@Weight_Carton 		varchar (20),   @printed_on_the_page    int,
	@Sum_Ordered_Qty        varchar (20),   @Sum_Pack_Qty 		varchar (20),	
	@Carton_Ship_Date    	varchar (30),   @Weight_UOM_Carton 	char    (3),
	@details_count 		int,            @max_details_on_page    int,            
	@printed_details_cnt    int,            @total_pages            int,  
	@page_no                int, 		@part_no		VARCHAR(30),
	@UPC_Code 		varchar (40), 	@Item_Description   	varchar (255), 
	@Lot_Ser 		varchar (30),	@serial_no              varchar (50),   
	@serial_no_raw          varchar (50),	@previous_part          varchar (30),   
	@previous_lot           varchar (24)
	
DECLARE @sku_code VARCHAR(16), @height DECIMAL(20,8), @width DECIMAL(20,8), @cubic_feet DECIMAL(20,8),
	 @length DECIMAL(20,8), @cmdty_code VARCHAR(8), @weight_ea DECIMAL(20,8), @so_qty_increment DECIMAL(20,8), 
	 @category_1 VARCHAR(15), @category_2 VARCHAR(15), @category_3 VARCHAR(15), @category_4 VARCHAR(15), @category_5 VARCHAR(15) 

SELECT 	
	@address1           = address1,      			
	@address2           = address2,      			
	@address3           = address3,      			
	@attention          = attention,     			
	@airbill_no         = cs_airbill_no, 			
	@carrier_code       = carrier_code,  			
	@carton_class       = carton_class,  			
	@carton_type        = carton_type,   			
       	@city               = city,          			
        @country            = country,       			
	@cust_code          = cust_code,     			
	@cust_po            = cust_po,       			
 	@date_shipped       = date_shipped,  			
	@xfer_no            = CAST(order_no   AS VARCHAR(10)),
	@ship_to_name       = [name],          			
	@ship_to_no         = ship_to_no,    			
	@shipper            = shipper,       			
	@state              = state,         			 
	@template_code      = template_code, 			
	@tracking_no        = cs_tracking_no,			
	@weight             = CAST(weight AS VARCHAR(20)),       
	@weight_uom         = weight_uom,    			
	@zip                = zip
  FROM tdc_carton_tx (NOLOCK) 
 WHERE carton_no = @carton_no

-- Remove the '0' after the '.'
EXEC tdc_trim_zeros_sp @Weight OUTPUT

SELECT @from_loc = from_loc, @to_loc = to_loc, @to_loc_name = to_loc_name
  FROM xfers (NOLOCK) 
 WHERE xfer_no = @xfer_no

INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ADDRESS1',   	ISNULL(@address1,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ADDRESS2', 		ISNULL(@address3,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ADDRESS3', 		ISNULL(@address3,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_AIRBILL_NO', 	ISNULL(@airbill_no,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ATTENTION', 	ISNULL(@attention,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CARTON_CLASS', 	ISNULL(@carton_class,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CARTON_NO',     	ISNULL(CAST(@carton_no AS VARCHAR(20)), ''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CARTON_TYPE',   	ISNULL(@carton_type,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CITY', 		ISNULL(@city,		''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_COUNTRY', 		ISNULL(@country,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_DATE_SHIPPED', 	ISNULL(@date_shipped,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_FROM_LOCATION', 	ISNULL(@from_loc,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ROUTING',	        ISNULL(@carrier_code,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SHIP_TO_NAME', 	ISNULL(@ship_to_name,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SHIP_TO_NO', 	ISNULL(@ship_to_no,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SHIPPER', 		ISNULL(@shipper,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_STATE', 		ISNULL(@state,		''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_STATION_ID', 	ISNULL(@station_id,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_TEMPLATE_CODE', 	ISNULL(@template_code,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_TO_LOC', 		ISNULL(@to_loc,		''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_TO_LOC_NAME', 	ISNULL(@to_loc_name,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_TRACKING_NO', 	ISNULL(@tracking_no,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_USER_ID', 		ISNULL(@user_id,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_WEIGHT', 		ISNULL(@weight,		''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_WEIGHT_UOM', 	ISNULL(@weight_uom,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_XFER_NO', 		ISNULL(@xfer_no,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ZIP', 		ISNULL(@zip,		''))

IF (@@ERROR <> 0 )
BEGIN
	RAISERROR ('Insert into #PrintData Failed', 16, 1)					
	RETURN
END
------------------------------------------------------------------------------------------------

-- Now let's run the tdc_print_label_sp to get format_id, printer_id, and number of copies -----
EXEC @return_value = tdc_print_label_sp 'PPS', 'XFERCTNSNLIST', 'VB', @station_id

-- IF label hasn't been set up for the station id, try finding a record for the user id
IF @return_value != 0
BEGIN
	EXEC @return_value = tdc_print_label_sp 'PPS', 'XFERCTNSNLIST', 'VB', @user_id
END

-- IF label hasn't been set up for the user id, exit
IF @return_value != 0
BEGIN
	TRUNCATE TABLE #PrintData
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
	 WHERE carton_no = @carton_no
	   AND ISNULL(serial_no, '') <> ''

	----------------------------------
	-- Get Max Detail Lines on a page.           
	----------------------------------
	SET @max_details_on_page = 0

	-- First check if user defined the number of details for the format ID
	SELECT @max_details_on_page = detail_lines    
          FROM tdc_tx_print_detail_config (NOLOCK)  
         WHERE module       = 'PPS'   
           AND trans        = 'XFERCTNSNLIST'
           AND trans_source = 'VB'
           AND format_id    = @format_id

	-- If not defined, get the value from tdc_config
	IF ISNULL(@max_details_on_page, 0) = 0
	BEGIN
		-- If not defined, default to 4
		SELECT @max_details_on_page = ISNULL((SELECT value_str FROM tdc_config (NOLOCK) WHERE [function] = 'CTNSNLIST_Detl_Cnt'), 4) 
	END

	-- First Page
	SELECT @page_no = 1, @printed_details_cnt = 1, @printed_on_the_page = 1

	----------------------- Now let's get the Detail Data ----------------------------------------

	----- The details For Order based Serial Number pack tickets  are:           --------------
        ----- part_no, item_description, lot_ser, upc_code, serial_no, serial_no_raw --------------
	DECLARE detail_cursor CURSOR FOR 
		SELECT DISTINCT a.part_no,       
				a.lot_ser,       
				a.serial_no,     
				a.serial_no_raw, 
				b.upc_code,       
				b.[description]
	   	  FROM tdc_carton_detail_tx a (NOLOCK), inv_master b (NOLOCK)
		 WHERE carton_no = @carton_no
	 	   AND a.part_no = b.part_no
	   	   AND ISNULL(serial_no, '') <> ''

	OPEN detail_cursor
		
	FETCH NEXT FROM detail_cursor INTO 
		@part_no, @lot_ser, @serial_no, @serial_no_raw, @upc_code, @item_description
		
	WHILE (@@FETCH_STATUS <> -1)
	BEGIN	
		-- If part_no or lot_ser changed, we insert a blank row.
		IF( ((len(@previous_part) > 0) AND (@part_no <> @previous_part))
		 OR ((len(@previous_lot)  > 0) AND (@lot_ser <> @previous_lot)))
		BEGIN
			-------------- Now let's insert the blank row into the output table -----------------			
			INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_PART_NO_'          + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + '')
			INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_ITEM_DESCRIPTION_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + '')
			INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_UPC_CODE_'         + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + '')
			INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_LOT_SER_'          + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + '')
			INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_SERIAL_NO_'        + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + '')
			INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_SERIAL_NO_RAW_'    + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + '')
			INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_SKU_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ''
			INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_HEIGHT_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ''
			INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_WIDTH_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ''
			INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_CUBIC_FEET_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ''
			INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_LENGTH_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ''
			INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_CMDTY_CODE_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ''
			INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_WEIGHT_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ''
			INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_SO_QTY_INCR_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ''
			INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_CATEGORY_1_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ''
			INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_CATEGORY_2_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ''
			INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_CATEGORY_3_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ''
			INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_CATEGORY_4_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ''
			INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_CATEGORY_5_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ''


			IF (@@ERROR <> 0 )
			BEGIN
				CLOSE      detail_cursor
				DEALLOCATE detail_cursor
				CLOSE      print_cursor
				DEALLOCATE print_cursor
				RAISERROR ('Insert into #tdc_print_ticket Failed', 16, 4)				
				RETURN
			END
	
			-- Increment @details_count because the blank row is a detail
			SELECT @details_count = @details_count + 1
			-----------------------------------------------------------------------------------------------

			-- If we reached max detail lines on the page, print the Footer
			IF @printed_on_the_page = @max_details_on_page
			BEGIN
				-------------- Now let's insert the Footer into the output table -----------------
				-- We insert total_pages = '' for now because we don't know how  -----------------
				-- many blank rows we need to insert. We'll update total_pages later -------------
				INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_PAGE_NO,'     + RTRIM(CAST(@page_no AS char(4)))
				INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_TOTAL_PAGES,' + ''
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
		END -- End of inserting blank row
				
		SELECT @previous_part = @part_no
		SELECT @previous_lot  = ISNULL(@lot_ser, '')
		EXEC tdc_parse_string_sp @Item_Description, @Item_Description output	

		-------------- Now let's insert the Details into the output table -----------------			
		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_PART_NO_'          + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@part_no, 		''))
		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_ITEM_DESCRIPTION_' + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@item_description, 	''))
		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_UPC_CODE_'         + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@upc_code, 		''))
		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_LOT_SER_'          + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@lot_ser, 		''))
		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_SERIAL_NO_'        + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@serial_no, 		''))
		INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_SERIAL_NO_RAW_'    + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + ISNULL(@serial_no_raw, 	''))
		
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
			RAISERROR ('Insert into #tdc_print_ticket Failed', 16, 4)				
			RETURN
		END
		-----------------------------------------------------------------------------------------------

		-- If we reached max detail lines on the page, print the Footer
		IF @printed_on_the_page = @max_details_on_page
		BEGIN
			-------------- Now let's insert the Footer into the output table -----------------
			-- We insert total_pages = '' for now because we don't know how  -----------------
			-- many blank rows we need to insert. We'll update total_pages later -------------
			INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_PAGE_NO,'     + RTRIM(CAST(@page_no AS char(4)))
			INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_TOTAL_PAGES,' + ''
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

		FETCH NEXT FROM detail_cursor INTO 
			@part_no, @lot_ser, @serial_no, @serial_no_raw, @upc_code, @item_description
	END -- End of the detail_cursor

	CLOSE      detail_cursor
	DEALLOCATE detail_cursor

	------------------ All the details have been inserted ------------------------------------
	
	-- Now we know the total detail count so we can calculate @total_pages and 
	-- update #tdc_print_ticket

	-- Get Total Pages
	SELECT @total_pages = 
		CASE WHEN @details_count % @max_details_on_page = 0 
		     THEN @details_count / @max_details_on_page		
	     	     ELSE @details_count / @max_details_on_page + 1	
		END		

	UPDATE #tdc_print_ticket 
	   SET print_value = (SELECT 'LP_TOTAL_PAGES,' + RTRIM(CAST(@total_pages AS char(4))))
	 WHERE print_value LIKE ('LP_TOTAL_PAGES,%')

	IF @page_no - 1 <> @total_pages
	BEGIN
		-------------- Now let's insert the Footer into the output table -----------------
		INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_PAGE_NO,'     + RTRIM(CAST(@page_no     AS char(4))) 
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
	END
	-----------------------------------------------------------------------------------------------
	FETCH NEXT FROM print_cursor INTO @format_id, @printer_id, @number_of_copies
END

CLOSE      print_cursor
DEALLOCATE print_cursor


RETURN
GO
GRANT EXECUTE ON  [dbo].[tdc_print_xfer_ctn_sn_pack_list_sp] TO [public]
GO
