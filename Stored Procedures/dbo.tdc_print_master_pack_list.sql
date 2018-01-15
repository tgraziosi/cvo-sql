SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v2.0 TM 12/27/2011 Reformat for CVO for Master Pack Manifest  
-- v2.1 CB 29/12/2017 Change detail_cursor to loop - Performance
  
CREATE PROCEDURE [dbo].[tdc_print_master_pack_list]	@user_id    varchar(50),  
													@station_id varchar(20),  
													@pack_no    int  
AS  
BEGIN  
	DECLARE @carton_total				int,            
			@return_value				int,  
			@format_id					varchar(40),   
			@printer_id					varchar(30),  
			@details_count				int,            
			@max_details_on_page		int,              
			@printed_details_cnt		int,            
			@total_pages				int,    
			@page_no					int,            
			@number_of_copies			int,  
			@status						char(1), 
			@carton_class				char(10),   
			@carrier_code				varchar(40), 
			@carton_type				char(10), -- v2.0  
			@address1					varchar(40),  
			@name						varchar(40),    
			@address2					varchar(40),   
			@city						varchar(40),    
			@address3					varchar(40),   
			@state						varchar(40),  
			@Attention					varchar(40), 
			@zip						varchar(10),  
			@cust_code					varchar(40), 
			@country					varchar(40),  
			@cs_tracking_no				varchar(255), 
			@cs_tx_no					varchar(12),  
			@cs_zone					varchar(10), 
			@cs_oversize				varchar(255),  
			@cs_call_tag_no				varchar(10), 
			@cs_airbill_no				varchar(18),  
			@cs_other					varchar(8), 
			@cs_pickup_no				varchar(10),  
			@cs_dim_weight				varchar(13),   
			@cs_published_freight		varchar(13),   
			@cs_disc_freight			varchar(13), 
			@date_shipped				varchar(20),  
			@Weight						varchar(20),   
			@freight_to					varchar(30),  
			@cust_freight				varchar(13),   
			@adjust_rate				varchar(10),   
			@charge_code				varchar(10),   
			@template_code				varchar(10),  
			@cs_estimated_freight		varchar(13), 
			@carton_no					varchar(20),  
			@cs_airbillno				varchar(18),   
			@printed_on_the_page		int,  
			@order_no					varchar (20), 
			@order_ext					varchar(20),  
			@header_add_note			varchar(255),  
			@ord_cust_code				varchar(8), 
			@cust_name					varchar(40), -- v2.0  
			@ord_pack_qty				varchar(20), 
			@tot_pack_qty				varchar(20), -- v2.0  
			@row_id						int -- v2.1

	-- v2.1 Start
	CREATE TABLE #mpl_detail_cursor (
		row_id			int IDENTITY(1,1),
		order_no		int, 
		order_ext		int, 
		carton_no		int, 
		carton_type		varchar(10), 
		carton_class	varchar(10), 
		ord_cust_code	varchar(10), 
		cust_name		varchar(40))
	-- v2.1 End  
  
	------------------------------------- Header Data -----------------------------------------------------------------  
	-- Now retrieve the Orders information  
	SELECT	@cust_code = cust_code,  
			@status = status,  
			@carrier_code = v.ship_via_name,     --v2.0  --carrier_code,   
			@weight = CAST(weight AS varchar(13)),                   
			@name = [name],                                       
			@address1 = address1,                                   
			@address2 = address2,                                   
			@address3 = address3,                                   
			@city = city,                                       
			@state = state,   
			@zip = zip,          
			@country = country,                                    
			@attention = attention,                                  
			@cs_tx_no = cs_tx_no,      
			@cs_tracking_no = cs_tracking_no,                                                                                                                                                                                                                     
			@cs_zone = cs_zone,      
			@cs_oversize = cs_oversize,                                                                                                                                                                                                                           			                    
			@cs_call_tag_no = cs_call_tag_no,   
			@cs_airbill_no = cs_airbill_no,        
			@cs_other = CAST(cs_other AS varchar(8)),                
			@cs_pickup_no = cs_pickup_no,  
			@cs_dim_weight = cs_dim_weight,            
			@cs_published_freight = cs_published_freight,      
			@cs_disc_freight = cs_disc_freight,          
			@cs_estimated_freight = cs_estimated_freight,                                                                                                                                   
			@date_shipped = CAST(IsNull(date_shipped,getdate()) AS varchar(20)),                                             
			@freight_to = freight_to,                       
			@cust_freight = CAST(cust_freight AS varchar(13)),             
			@adjust_rate = CAST(adjust_rate AS varchar(4)),   
			@charge_code = charge_code,   
			@template_code = template_code   
	FROM	tdc_master_pack_tbl mp (NOLOCK)  
	LEFT OUTER JOIN arshipv v (NOLOCK) 
	ON		mp.carrier_code = v.ship_via_code  
	WHERE	pack_no = @pack_no  
  
	SELECT	@carton_total = COUNT(carton_no) 
	FROM	tdc_master_pack_ctn_tbl (NOLOCK) 
	WHERE	pack_no = @pack_no  
  
	-- Remove the '0' after the '.'  
	EXEC tdc_trim_zeros_sp @Weight OUTPUT  
	EXEC tdc_parse_string_sp @cs_oversize, @cs_oversize output   
  
	SELECT	@tot_pack_qty = CAST(SUM(pack_qty) AS varchar(20))   
	FROM	tdc_carton_detail_tx (NOLOCK)   
	WHERE	carton_no IN (SELECT carton_no FROM tdc_master_pack_ctn_tbl (NOLOCK) WHERE pack_no = @pack_no)  
	EXEC tdc_trim_zeros_sp @tot_pack_qty OUTPUT  
  
	-------------- Now let's insert the Header information into #PrintData  --------------------------------------------  
	-------------- We are going to use this table in the tdc_print_label_sp --------------------------------------------  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_PACK_NO',           CAST  (@pack_no      AS varchar(10)))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CARTON_TOTAL',      CAST  (@carton_total AS varchar(10)))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CUST_CODE',       ISNULL(@cust_code,       '' ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ROUTING',  ISNULL(@carrier_code,          '' ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_WEIGHT',         ISNULL(@weight,          '' ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_NAME',         ISNULL(@name,           '' ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ADDRESS1',         ISNULL(@address1,          '' ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ADDRESS2',         ISNULL(@address2,          '' ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ADDRESS3',          ISNULL(@address3,          '' ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CITY',           ISNULL(@city,           '' ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_STATE',      ISNULL(@state,           '' ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ZIP',         ISNULL(@zip,           '' ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_COUNTRY',      ISNULL(@country,          '' ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ATTENTION',  ISNULL(@attention,          '' ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_TX_NO',         ISNULL(@cs_tx_no,         '' ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_TRACKING_NO',  ISNULL(@cs_tracking_no,  '' ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ZONE',    ISNULL(@cs_zone,    '' ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_OVERSIZE',          ISNULL(@cs_oversize,            '' ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CALL_TAG_NO',  ISNULL(@cs_call_tag_no,         '' ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_AIRBILL_NO',        ISNULL(@cs_airbillno,        '' ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_OTHER',          ISNULL(@cs_other,              '' ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_PICKUP_NO',        ISNULL(@cs_pickup_no,        '' ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_DIM_WEIGHT',        ISNULL(@cs_dim_weight,        '' ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_PUBLISHED_FREIGHT', ISNULL(@cs_published_freight, '' ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_DATE_SHIPPED',      ISNULL(@date_shipped,        '' ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_FREIGHT_TO',        ISNULL(@freight_to,        '' ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CUST_FREIGHT',      ISNULL(@cust_freight,        '' ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ADJUST_RATE', ISNULL(@adjust_rate,         '' ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CHARGE_CODE',      ISNULL(@charge_code,      '' ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_TEMPLATE_CODE', ISNULL(@template_code,         '' ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_USERID',            ISNULL(@user_id,               '' ))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_STATION_ID',  ISNULL(@station_id,  ''))  
	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_TOT_QTY',  ISNULL(@tot_pack_qty,  ''))  
  
	IF (@@ERROR <> 0 )  
	BEGIN  
		RAISERROR ('Insert into #PrintData Failed', 16, 1)       
		RETURN  
	END  
  
	-- Now let's run the tdc_print_label_sp to get format_id, printer_id, and number of copies -----  
	EXEC @return_value = tdc_print_label_sp 'PPS', 'MASTERPACK', 'VB', @station_id  
  
	-- IF label hasn't been set up for the station id, try finding a record for the user id  
	IF @return_value != 0  
	BEGIN  
		EXEC @return_value = tdc_print_label_sp 'PPS', 'MASTERPACK', 'VB', @user_id  
	END  
  
	-- IF label hasn't been set up for the user id, exit  
	IF @return_value != 0  
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
		SELECT	@details_count = COUNT(order_no)   
		FROM	tdc_carton_tx (NOLOCK)  
		WHERE	carton_no IN (SELECT carton_no FROM tdc_master_pack_ctn_tbl (NOLOCK) WHERE pack_no = @pack_no)  
  
		----------------------------------  
		-- Get Max Detail Lines on a page.             
		----------------------------------  
		SET @max_details_on_page = 0  
  
		-- First check if user defined the number of details for the format ID  
		SELECT	@max_details_on_page = detail_lines      
        FROM	tdc_tx_print_detail_config (NOLOCK)    
        WHERE	module = 'PPS'     
        AND		trans = 'MASTERPACK'  
        AND		trans_source = 'VB'  
        AND		format_id = @format_id  
  
		-- If not defined, get the value from tdc_config  
		IF ISNULL(@max_details_on_page, 0) = 0  
		BEGIN  
			-- If not defined, default to 4  
			SELECT @max_details_on_page = ISNULL((SELECT value_str FROM tdc_config (NOLOCK) WHERE [function] = 'CTNPACKTKT_Detl_Cnt'), 4)   
		END  
    
		-- Get Total Pages  
		SELECT	@total_pages = CASE WHEN @details_count % @max_details_on_page = 0   
				THEN @details_count / @max_details_on_page    
				ELSE @details_count / @max_details_on_page + 1 END    
  
		-- First Page  
		SELECT @page_no = 1, @printed_details_cnt = 1, @printed_on_the_page = 1  
  
		------------- Now let's get the Detail Data ----------------------------------------  
		-- v2.1 Start  
--		DECLARE detail_cursor CURSOR FOR   
--		SELECT	CAST(tx.order_no AS varchar(10)), CAST(tx.order_ext AS varchar(10)),  
--				CAST(carton_no AS varchar(10)), carton_type, carton_class,  
--				o.cust_code, o.ship_to_name  
--		FROM	tdc_carton_tx tx (NOLOCK)  
--		LEFT OUTER JOIN orders_all o (NOLOCK) ON tx.order_no = o.order_no AND tx.order_ext = o.ext  
--		WHERE	carton_no IN (SELECT carton_no FROM tdc_master_pack_ctn_tbl (NOLOCK) WHERE pack_no = @pack_no)  
--		ORDER BY carton_no, tx.order_no  
--  
--		OPEN detail_cursor  
--		FETCH NEXT FROM detail_cursor INTO @order_no, @order_ext, @carton_no, @carton_type, @carton_class, @ord_cust_code, @cust_name  
--    
--		WHILE (@@FETCH_STATUS <> -1)  
--		BEGIN    

		TRUNCATE TABLE #mpl_detail_cursor

		INSERT	#mpl_detail_cursor (order_no, order_ext, carton_no,	carton_type, carton_class, ord_cust_code, cust_name)
		SELECT	CAST(tx.order_no AS varchar(10)), CAST(tx.order_ext AS varchar(10)),  
				CAST(carton_no AS varchar(10)), carton_type, carton_class,  
				o.cust_code, o.ship_to_name  
		FROM	tdc_carton_tx tx (NOLOCK)  
		LEFT OUTER JOIN orders_all o (NOLOCK) ON tx.order_no = o.order_no AND tx.order_ext = o.ext  
		WHERE	carton_no IN (SELECT carton_no FROM tdc_master_pack_ctn_tbl (NOLOCK) WHERE pack_no = @pack_no)  
		ORDER BY carton_no, tx.order_no

		SET @row_id = 0

		WHILE (1 = 1)
		BEGIN

			SELECT	TOP 1 @row_id = row_id,
					@order_no = order_no, 
					@order_ext = order_ext, 
					@carton_no = carton_no, 
					@carton_type = carton_type, 
					@carton_class = carton_class, 
					@ord_cust_code = ord_cust_code, 
					@cust_name = cust_name
			FROM	#mpl_detail_cursor
			WHERE	row_id > @row_id
			ORDER BY row_id ASC

			IF (@@ROWCOUNT = 0)
				BREAK
			-- v2.1 End

 			SELECT	@ord_pack_qty = CAST(SUM(pack_qty) AS varchar(20))   
			FROM	tdc_carton_detail_tx WHERE carton_no = @carton_no  
			EXEC tdc_trim_zeros_sp @ord_pack_qty OUTPUT  
  
			-------------- Now let's insert the Details into the output table -----------------  
			INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_ORDER_NO_'      + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + @order_no)  
			INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_ORDER_EXT_'     + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + @order_ext)  
			INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_CARTON_NO_'     + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + @carton_no)  
			INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_CARTON_TYPE_'   + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + @carton_type)  
			INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_CARTON_CLASS_'  + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + @carton_class)  
			INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_CUST_CODE_'  + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + @ord_cust_code)  
			INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_CUST_NAME_'  + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + @cust_name)  
			INSERT INTO #tdc_print_ticket (print_value) VALUES('LP_CARTON_QTY_'  + RTRIM(CAST(@printed_on_the_page AS char(4))) + ',' + @ord_pack_qty)  
  
			IF (@@ERROR <> 0 )  
			BEGIN  
				-- v2.1 CLOSE      detail_cursor  
				-- v2.1 DEALLOCATE detail_cursor  
				DROP TABLE #mpl_detail_cursor -- v2.1
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
				INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_PAGE_NO,' + RTRIM(CAST(@page_no AS char(4)))+ ' OF ' + RTRIM(CAST(@total_pages AS char(4)))  
				--INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_TOTAL_PAGES,' + RTRIM(CAST(@total_pages AS char(4)))  
				INSERT INTO #tdc_print_ticket (print_value) SELECT '*PRINTERNUMBER,' + @printer_id  
				INSERT INTO #tdc_print_ticket (print_value) VALUES ('*QUANTITY,1')  
				INSERT INTO #tdc_print_ticket (print_value) SELECT '*DUPLICATES,'    + RTRIM(CAST(@number_of_copies AS char(4)))  
				INSERT INTO #tdc_print_ticket (print_value) SELECT '*PRINTLABEL'  
   
				IF (@@ERROR <> 0 )  
				BEGIN  
					-- v2.1 CLOSE      detail_cursor  
					-- v2.1 DEALLOCATE detail_cursor  
					DROP TABLE #mpl_detail_cursor --  v2.1
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
						-- v2.1 CLOSE      detail_cursor  
						-- v2.1 DEALLOCATE detail_cursor  
						DROP TABLE #mpl_detail_cursor -- v2.1
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
  
			-- v2.1 FETCH NEXT FROM detail_cursor INTO @order_no, @order_ext, @carton_no, @carton_type, @carton_class, @ord_cust_code, @cust_name  
		END -- End of the detail_cursor  
  
		-- v2.1 CLOSE      detail_cursor  
		-- v2.1 DEALLOCATE detail_cursor  
  
		------------------ All the details have been inserted ------------------------------------  
		IF @page_no - 1 <> @total_pages  
		BEGIN  
			-------------- Now let's insert the Footer into the output table -----------------  
			INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_PAGE_NO,' + RTRIM(CAST(@page_no AS char(4)))+ ' OF ' + RTRIM(CAST(@total_pages AS char(4)))  
			--INSERT INTO #tdc_print_ticket (print_value) SELECT 'LP_TOTAL_PAGES,' + RTRIM(CAST(@total_pages AS char(4)))  
			INSERT INTO #tdc_print_ticket (print_value) SELECT '*PRINTERNUMBER,' + @printer_id  
			INSERT INTO #tdc_print_ticket (print_value) VALUES ('*QUANTITY,1')  
			INSERT INTO #tdc_print_ticket (print_value) SELECT '*DUPLICATES,'    + RTRIM(CAST(@number_of_copies AS char(3)))  
			INSERT INTO #tdc_print_ticket (print_value) SELECT '*PRINTLABEL'  
  
			IF (@@ERROR <> 0 )  
			BEGIN  
				CLOSE      print_cursor  
				DEALLOCATE print_cursor  
				DROP TABLE #mpl_detail_cursor -- v2.1
				RAISERROR ('Insert into #tdc_print_ticket Failed', 16, 7)    
				RETURN  
			END  
		END  
		-----------------------------------------------------------------------------------------------  
		FETCH NEXT FROM print_cursor INTO @format_id, @printer_id, @number_of_copies  
	END  
  
	CLOSE      print_cursor  
	DEALLOCATE print_cursor  
	DROP TABLE #mpl_detail_cursor -- v2.1
  
	RETURN  
 END
GO
GRANT EXECUTE ON  [dbo].[tdc_print_master_pack_list] TO [public]
GO
