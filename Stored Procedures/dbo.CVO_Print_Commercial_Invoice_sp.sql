SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure [dbo].[CVO_Print_Commercial_Invoice_sp]    Script Date: 05/26/2010  *****
SED004 -- Control Packing -- Print International Documents
Object:      Stored Procedure CVO_Print_Commercial_Invoice_sp  
Source file: CVO_Print_Commercial_Invoice_sp.sql
Author:		 Jesus Velazquez
Created:	 05/26/2010
Function:    After shipping prints Commercial Invoice
Modified:    
Calls:    
Called by:   WMS -- Shipping Screen
Copyright:   Epicor Software 2010.  All rights reserved.  
*/

-- v1.1 CB 20/07/2011	68668-012 - Print from sales order
-- v2.0 TM 10/28/2011	Fix issue in Sold To field
-- v10.0 CB 10/7/2012	CVO-CF-1 - Custom Frame Processing
-- v2.1 CT 14/08/2012	Add polarized items to the invoice
-- v2.2 CT 16/08/2012	Keep polarized, but also show cases not linked to frames
-- v2.3 CT 17/08/2012	For cases not linked to parts and with no price on sales order, set price of 0.01
-- v2.4 CT 17/08/2012	Only print total on last page of the invoice
-- v2.5 CB 20/12/2012	Issue #1039 - Total missing when page full
-- v2.6 CB 14/01/2013	Issue  - Totals only on last page fix
-- v2.7 CB 16/01/2013	Issue #1100 - Not dealing with frame/case relationship correctly


CREATE PROCEDURE  [dbo].[CVO_Print_Commercial_Invoice_sp]   
			@order_no		INT,
			@order_ext		INT,
			@module			VARCHAR(3),
			@trans			VARCHAR(20),
			@trans_source	VARCHAR(2),
			@station_id     VARCHAR(20),
			@order_total	DECIMAL(20,2) OUTPUT -- v2.4
AS

BEGIN
	--Header vars
	DECLARE @format_id          VARCHAR(40),    
			@printer_id         VARCHAR(30),
			@number_of_copies	INT,
			@max_lines_per_page INT,
			@avail_lines_detail INT,
			@LP_CUST_ADDR		VARCHAR(100),
			@LP_CUST_ADDR1		VARCHAR(100),
			@LP_CUST_ADDR2		VARCHAR(100),
			@LP_CUST_PHONE		VARCHAR(20),
			@LP_CUST_FAX		VARCHAR(20),
			@LP_SHIP_TO_NAME	VARCHAR(40),     
			@LP_SHIP_TO_ADD_1	VARCHAR(40),
			@LP_SHIP_TO_ADD_2	VARCHAR(40),
			@LP_SHIP_TO_ADD_3	VARCHAR(40),
			@LP_SHIP_TO_ADD_4	VARCHAR(40),
			@LP_SHIP_TO_ADD_5	VARCHAR(40),
			@LP_SHIP_TO_PHONE	VARCHAR(20),
			@LP_SHIP_TO_COUNTRY	VARCHAR(40),					--v2.0		
			@LP_FT_TOT_AMT_TXT	VARCHAR(40) -- v2.4

	--Detail vars
	DECLARE @row_id				INT,
			@LP_CARTON_NO		INT,
			@PREV_CARTON_NO		INT,
			@LP_PART_NO_DESC	VARCHAR(50),
			@TYPE_CODE			VARCHAR(10),
			@ADD_CASE			CHAR(1),
			@LP_CASES_INCLUDED	VARCHAR(15),
			@LINE_NO			INT,
			@FROM_LINE_NO		INT,					--v2.0
			@LP_MATERIAL		VARCHAR(15),
			@LP_TAG				VARCHAR(2),				-- v2.0
			@is_POP				int,
			@LP_ORIGIN			VARCHAR(40),
			@LP_QTY				DECIMAL(20,0),
			@LP_UNIT_VALUE		DECIMAL(20,2),
			@LP_TOTAL_VALUE		DECIMAL(20,2),
			@i					INT		

	--Footer vars
	DECLARE @LP_FT_TOTAL_AMOUNT	VARCHAR(40),
			@LP_FT_PIECES		VARCHAR(40),
			@LP_FT_WEIGHT		VARCHAR(40),
			@LP_FT_TERMS1		VARCHAR(200),
			@LP_FT_TERMS2		VARCHAR(200),
			@LP_FT_TERMS3		VARCHAR(200),
			@LP_FT_DISPLAY_LINE	VARCHAR(40),
			@LP_FT_SIGN			VARCHAR(40),
			@LP_FT_COORD		VARCHAR(40),		
			@LP_FT_CVO			VARCHAR(40)

	--add vars
	DECLARE @frame VARCHAR(10),
	        @case  VARCHAR(10)
	        
	SET @frame = [dbo].[CVO_get_ResType_PartType_fn] ('DEF_RES_TYPE_FRAME')
	SET @case  = [dbo].[CVO_get_ResType_PartType_fn] ('DEF_RES_TYPE_CASE')
	
	SET @format_id  = ''  
	SET @printer_id = 0 
	SET @number_of_copies = 0 
			
	SELECT @format_id		= ISNULL(format_id,'')
	FROM   tdc_label_format_control (NOLOCK)
	WHERE  module			= @module		AND 
		   trans			= @trans		AND 
		   trans_source		= @trans_source

	SELECT  @printer_id			= ISNULL(printer,0), 
			@number_of_copies	= ISNULL(quantity,0)  
	FROM	tdc_tx_print_routing  (NOLOCK)
	WHERE	module				= @module		AND
			trans				= @trans		AND
			trans_source		= @trans_source AND   
			format_id			= @format_id    AND
			user_station_id		= @station_id 

	--max number of pages to print per page
	SELECT  @max_lines_per_page = CAST(detail_lines AS INT) 
	FROM    tdc_tx_print_detail_config (NOLOCK)
	WHERE	trans_source = 'VB'				AND 
			module       = 'SHP'			AND 
			trans        = @trans

	--max number of detail lines existing in .lwl file
	SET @avail_lines_detail = 34

	--if user wants to print more lines than existing then
	IF @max_lines_per_page > @avail_lines_detail
		SET @max_lines_per_page = @avail_lines_detail

	TRUNCATE TABLE #PrintData  
	TRUNCATE TABLE #PrintData_Output
	
	-- Firstly, insert *FORMAT and all the data that we pass.
	INSERT INTO #PrintData_Output ( format_id,  printer_id,  number_of_copies)   
	VALUES (@format_id, @printer_id, @number_of_copies)    

	--Get Header Info
--v2.0 Get Address Info from ARCO
--	SELECT @LP_CUST_ADDR1 = ISNULL(address1,'') + ', ' + ISNULL(address2,''), 
--		   @LP_CUST_ADDR2 = ISNULL(city,'')     + ', ' + ISNULL(state,'')    + ' ' + ISNULL(zipCode,''),
--		   @LP_CUST_PHONE = ISNULL(phone,''),
--		   @LP_CUST_FAX   = ISNULL(fax,'')
--	FROM   tdc_contact_reg (NOLOCK)
--	WHERE  ServerName = @@SERVERNAME   

	SELECT @LP_CUST_ADDR1 = ISNULL(addr2,''), 
		   @LP_CUST_ADDR2 = ISNULL(addr3,''),
		   @LP_CUST_PHONE = ISNULL(addr5,''),
		   @LP_CUST_FAX   = ISNULL(addr6,'')
	FROM   arco (NOLOCK)
--

	SET @LP_CUST_ADDR = @LP_CUST_ADDR1 + ', ' + @LP_CUST_ADDR2 + '  ' + @LP_CUST_PHONE + '  ' + @LP_CUST_FAX

	--BEGIN SED008 -- Global Ship To
	--JVM 07/28/2010
	IF EXISTS(SELECT sold_to FROM orders (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext 
		AND sold_to IS NOT NULL AND LTRIM (sold_to) <> '' AND RTRIM (sold_to) <> ''
		AND sold_to <> cust_code)		--v2.0
		SELECT @LP_SHIP_TO_NAME  = ISNULL(address_name,''),  
			   @LP_SHIP_TO_ADD_1 = ISNULL(addr1,''), 
			   @LP_SHIP_TO_ADD_2 = ISNULL(addr2,''), 
			   @LP_SHIP_TO_ADD_3 = ISNULL(addr3,''),					--v2.0
			   @LP_SHIP_TO_ADD_4 = ISNULL(addr4,''),					--v2.0
			   @LP_SHIP_TO_ADD_5 = ISNULL(addr5,''),					--v2.0
			   @LP_SHIP_TO_PHONE = ISNULL(attention_phone,''),
			   @LP_SHIP_TO_COUNTRY = ISNULL(g.description ,'')				--v2.0
		FROM   armaster_all a (NOLOCK), gl_country g (NOLOCK)				--v2.0
		WHERE  address_type = 9 AND a.country_code = g.country_code AND		--v2.0
			   customer_code = (SELECT sold_to FROM orders (NOLOCK)WHERE order_no = @order_no AND ext = @order_ext)
	ELSE	      
		SELECT @LP_SHIP_TO_NAME  = ISNULL(ship_to_name,''),  
			   @LP_SHIP_TO_ADD_1 = ISNULL(ship_to_add_1,''), 
			   @LP_SHIP_TO_ADD_2 = ISNULL(ship_to_add_2,''), 
			   @LP_SHIP_TO_ADD_3 = ISNULL(ship_to_add_3,''),			--v2.0
			   @LP_SHIP_TO_ADD_4 = ISNULL(ship_to_add_4,''),			--v2.0
			   @LP_SHIP_TO_ADD_5 = ISNULL(ship_to_add_5,''),			--v2.0
			   @LP_SHIP_TO_PHONE = ISNULL(phone,''),
			   @LP_SHIP_TO_COUNTRY	= ISNULL(g.description,'')				--v2.0
		FROM   orders a (NOLOCK), gl_country g (NOLOCK)						--v2.0
		WHERE  order_no  = @order_no AND
			   ext       = @order_ext AND
			   a.ship_to_country_cd = g.country_code						--v2.0
	--END  SED008 -- Global Ship To

	--Insert Header
	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_CUST_ADDR'    ,@LP_CUST_ADDR	)
	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_CUST_ADDR1'   ,@LP_CUST_ADDR1	)
	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_CUST_ADDR2'   ,@LP_CUST_ADDR2	)
	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_CUST_PHONE'   ,@LP_CUST_PHONE	)
	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_CUST_FAX'     ,@LP_CUST_FAX		)
	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_SHIP_TO_NAME' ,@LP_SHIP_TO_NAME )
	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_SHIP_TO_ADD_1',@LP_SHIP_TO_ADD_1)
	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_SHIP_TO_ADD_2',@LP_SHIP_TO_ADD_2)
	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_SHIP_TO_ADD_3',@LP_SHIP_TO_ADD_3)		--v2.0
	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_SHIP_TO_ADD_4',@LP_SHIP_TO_ADD_4)		--v2.0
	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_SHIP_TO_ADD_5',@LP_SHIP_TO_ADD_5)		--v2.0
	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_SHIP_TO_PHONE',@LP_SHIP_TO_PHONE)	   	   
	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_SHIP_TO_COUNTRY',@LP_SHIP_TO_COUNTRY)	   	   

	--v2.0 Print Order Amount based on Allocated amounts
    --SELECT @LP_FT_TOTAL_AMOUNT = SUM(CAST(total_value AS decimal(20,2)))
	--  FROM #PrintData_detail WHERE type_code <> @case

	SELECT @LP_FT_TOTAL_AMOUNT = 0
	SELECT @is_pop = 0

	-- v2.7 Start
	IF OBJECT_ID('tempdb..#cvo_ord_list') IS NOT NULL  
		DROP TABLE #cvo_ord_list

	SELECT	* INTO #cvo_ord_list
	FROM	cvo_ord_list
	WHERE	1 = 2

	EXEC CVO_create_fc_relationship_sp @order_no, @order_ext

	UPDATE	a
	SET		from_line_no = b.from_line_no
	FROM	#PrintData_detail a
	JOIN	#cvo_ord_list b
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	AND		a.line_no = b.line_no
	WHERE	b.from_line_no <> 0
	-- v2.7 End

	--First Insert Frames
    --@avail_lines_detail
    declare @cur VARCHAR(400)

-- v2.1 v2.2
--	SET @cur = '
--    DECLARE lines_cur CURSOR FOR	
--    SELECT  TOP ' + CAST(@max_lines_per_page AS VARCHAR(2))  + ' row_id, carton_no, part_no_desc, type_code, add_case, line_no, from_line_no, material, origin, qty, unit_value, total_value
--	FROM    #PrintData_detail WHERE from_line_no = 0  ORDER BY carton_no, type_code
--	OPEN lines_cur'

	-- v2.2
	SET @cur = '
    DECLARE lines_cur CURSOR FOR	
    SELECT  TOP ' + CAST(@max_lines_per_page AS VARCHAR(2))  + ' row_id, carton_no, part_no_desc, type_code, add_case, line_no, from_line_no, material, origin, qty, unit_value, total_value
	FROM    #PrintData_detail WHERE ((from_line_no = 0) OR (from_line_no <> 0 AND type_code <> '''+ @case +'''))   ORDER BY carton_no, type_code 
	OPEN lines_cur'


	exec (@cur)

	SET @i = 0
	FETCH NEXT FROM lines_cur 
	INTO @row_id, @LP_CARTON_NO, @LP_PART_NO_DESC, @TYPE_CODE, @ADD_CASE, @LINE_NO, @FROM_LINE_NO, @LP_MATERIAL, @LP_ORIGIN, @LP_QTY, @LP_UNIT_VALUE, @LP_TOTAL_VALUE

	WHILE @@FETCH_STATUS = 0
	BEGIN	
	   SET @i = @i + 1 	 
	   SET @LP_CASES_INCLUDED = ''
	   SET @LP_TAG = ''
	   
	  IF @LP_CARTON_NO = @PREV_CARTON_NO
		SET @LP_CARTON_NO = ''
	  ELSE
		SET @PREV_CARTON_NO = @LP_CARTON_NO	


--v2.0  If the item is related to another item do not include
--
-- v10.0 IF @TYPE_CODE <> @case AND EXISTS(SELECT * FROM #PrintData_detail WHERE order_no = @order_no AND order_ext = @order_ext AND type_code = @case AND from_line_no =  @LINE_NO)
--	   IF @TYPE_CODE <> @case AND EXISTS(SELECT 1 FROM cvo_ord_list (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND line_no =  @LINE_NO AND add_case = 'Y') -- v10.0
-- v2.7 Start
		IF ( @TYPE_CODE <> @case AND EXISTS(SELECT a.* FROM #PrintData_detail a JOIN #cvo_ord_list b ON a.order_no = b.order_no AND a.order_ext = b.order_ext AND a.line_no = b.line_no
												AND a.type_code = @case AND b.from_line_no = @LINE_NO))
		SET @LP_CASES_INCLUDED = 'CASES INCLUDED'		
-- v2.7 End
	   IF @LP_UNIT_VALUE = 0 AND @FROM_LINE_NO = 0 AND @TYPE_CODE <> 'CASE'
		  BEGIN
			IF @TYPE_CODE IN ('FRAME','SUN')
				BEGIN	
					SET @LP_UNIT_VALUE = 1.00
					SET @LP_TOTAL_VALUE = @LP_QTY * @LP_UNIT_VALUE
				END
			ELSE
				BEGIN	
					SET @LP_UNIT_VALUE = 0.05
					SET @LP_TOTAL_VALUE = @LP_QTY * @LP_UNIT_VALUE
				END
		  END

		IF @TYPE_CODE = 'POP' 
			BEGIN
			  SET @is_POP = 1
			  SET @LP_PART_NO_DESC = '(*) '+@LP_PART_NO_DESC
			END

		-- START v2.3
		IF (@TYPE_CODE = @case) AND (@LP_UNIT_VALUE = 0)
		BEGIN
			-- Set unit value = 0.01
			SET @LP_UNIT_VALUE = 0.01

			-- Recalculate total value 
			SET @LP_TOTAL_VALUE = @LP_UNIT_VALUE * @LP_QTY
		END
		-- END v2.3


		SELECT @LP_FT_TOTAL_AMOUNT = @LP_FT_TOTAL_AMOUNT + @LP_TOTAL_VALUE

		-- v2.4
		SET @order_total = @order_total + @LP_TOTAL_VALUE

	   INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_CARTON_NO_'	    + CAST(@i AS CHAR(2)),@LP_CARTON_NO		)
	   INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_PART_NO_DESC_'   + CAST(@i AS CHAR(2)),@LP_PART_NO_DESC	)
	   INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_CASES_INCLUDED_' + CAST(@i AS CHAR(2)),@LP_CASES_INCLUDED)
	   INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_MATERIAL_'		+ CAST(@i AS CHAR(2)),@LP_MATERIAL		)
	   INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_ORIGIN_'			+ CAST(@i AS CHAR(2)),@LP_ORIGIN		)
	   INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_TAG_'			+ CAST(@i AS CHAR(2)),@LP_TAG		)
	   INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_QTY_'			+ CAST(@i AS CHAR(2)),@LP_QTY			)
	   INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_UNIT_VALUE_'		+ CAST(@i AS CHAR(2)),@LP_UNIT_VALUE	)
	   INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_TOTAL_VALUE_'	+ CAST(@i AS CHAR(2)),@LP_TOTAL_VALUE	)

	   DELETE #PrintData_detail WHERE row_id = @row_id

	   FETCH NEXT FROM lines_cur 
	   INTO @row_id, @LP_CARTON_NO, @LP_PART_NO_DESC, @TYPE_CODE, @ADD_CASE, @LINE_NO, @FROM_LINE_NO, @LP_MATERIAL, @LP_ORIGIN, @LP_QTY, @LP_UNIT_VALUE, @LP_TOTAL_VALUE
	END

	CLOSE lines_cur
	DEALLOCATE lines_cur

	SET @PREV_CARTON_NO = ''

	--Then Insert Cases
	SET @cur = '
    DECLARE  cases_lines_cur CURSOR FOR	
    SELECT   carton_no, MAX(origin), SUM(CAST(qty AS decimal(20,0)))
	FROM     #PrintData_detail
	WHERE   type_code = '''+ @case +'''
	GROUP BY carton_no
	ORDER by carton_no
	OPEN cases_lines_cur'
	exec (@cur)

	--SET @i = 0
	FETCH NEXT FROM cases_lines_cur 
	INTO @LP_CARTON_NO, @LP_ORIGIN, @LP_QTY
	WHILE @@FETCH_STATUS = 0 AND @i < @max_lines_per_page
	BEGIN	

--if @i < @max_lines_per_page
--begin
	   SET @i = @i + 1 	 	   
	   SET @LP_PART_NO_DESC   = 'CASES: COST ARE INCLUDED W/FRAMES'
       SET @LP_CASES_INCLUDED = ''
	   SET @LP_MATERIAL       = ''
	   SET @LP_ORIGIN       = ''					--v2.0
       SET @LP_UNIT_VALUE     = 0
       SET @LP_TOTAL_VALUE    = 0

	  IF @LP_CARTON_NO = @PREV_CARTON_NO
		SET @LP_CARTON_NO = ''
	  ELSE
		SET @PREV_CARTON_NO = @LP_CARTON_NO

	   INSERT INTO #PrintData ( data_field,  data_value) VALUES ('LP_CARTON_NO_'	  + CAST(@i AS CHAR(2)),@LP_CARTON_NO)
	   INSERT INTO #PrintData ( data_field,  data_value) VALUES ('LP_PART_NO_DESC_'   + CAST(@i AS CHAR(2)),@LP_PART_NO_DESC)
	   INSERT INTO #PrintData ( data_field,  data_value) VALUES ('LP_CASES_INCLUDED_' + CAST(@i AS CHAR(2)),@LP_CASES_INCLUDED)
	   INSERT INTO #PrintData ( data_field,  data_value) VALUES ('LP_MATERIAL_'		  + CAST(@i AS CHAR(2)),@LP_MATERIAL)
	   INSERT INTO #PrintData ( data_field,  data_value) VALUES ('LP_ORIGIN_'		  + CAST(@i AS CHAR(2)),@LP_ORIGIN)
	   INSERT INTO #PrintData ( data_field,  data_value) VALUES ('LP_QTY_'			  + CAST(@i AS CHAR(2)),'')				--v2.0
	   INSERT INTO #PrintData ( data_field,  data_value) VALUES ('LP_UNIT_VALUE_'	  + CAST(@i AS CHAR(2)),'')
	   INSERT INTO #PrintData ( data_field,  data_value) VALUES ('LP_TOTAL_VALUE_'	  + CAST(@i AS CHAR(2)),'')

	   DELETE #PrintData_detail WHERE type_code = @case
--end
	   FETCH NEXT FROM cases_lines_cur 
	   INTO @LP_CARTON_NO, @LP_ORIGIN, @LP_QTY
	END

	CLOSE cases_lines_cur
	DEALLOCATE cases_lines_cur	

   IF @is_pop = 1
	 BEGIN
		SET @i = @i + 1 	 	   
		SET @LP_PART_NO_DESC   = '* PROMOTIONAL MATERIAL. NO COMMERCIAL VALUE.'
		INSERT INTO #PrintData ( data_field,  data_value) VALUES ('LP_CARTON_NO_'	   + CAST(@i AS CHAR(2)),@LP_CARTON_NO)
		INSERT INTO #PrintData ( data_field,  data_value) VALUES ('LP_PART_NO_DESC_'   + CAST(@i AS CHAR(2)),@LP_PART_NO_DESC)
		INSERT INTO #PrintData ( data_field,  data_value) VALUES ('LP_CASES_INCLUDED_' + CAST(@i AS CHAR(2)),@LP_CASES_INCLUDED)
		INSERT INTO #PrintData ( data_field,  data_value) VALUES ('LP_MATERIAL_'	   + CAST(@i AS CHAR(2)),@LP_MATERIAL)
	    INSERT INTO #PrintData ( data_field,  data_value) VALUES ('LP_ORIGIN_'		   + CAST(@i AS CHAR(2)),@LP_ORIGIN)
		INSERT INTO #PrintData ( data_field,  data_value) VALUES ('LP_QTY_'			   + CAST(@i AS CHAR(2)),'')				--v2.0
		INSERT INTO #PrintData ( data_field,  data_value) VALUES ('LP_UNIT_VALUE_'	   + CAST(@i AS CHAR(2)),'')
		INSERT INTO #PrintData ( data_field,  data_value) VALUES ('LP_TOTAL_VALUE_'	   + CAST(@i AS CHAR(2)),'')
	 END

	WHILE @i < @avail_lines_detail
	BEGIN	
	   SET @i = @i + 1   
	   INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_CARTON_NO_'	    + CAST(@i AS CHAR(2)), '')
	   INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_PART_NO_DESC_'   + CAST(@i AS CHAR(2)), '')
	   INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_CASES_INCLUDED_' + CAST(@i AS CHAR(2)), '')
	   INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_MATERIAL_'		+ CAST(@i AS CHAR(2)), '')
	   INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_ORIGIN_'			+ CAST(@i AS CHAR(2)), '')
	   INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_QTY_'			+ CAST(@i AS CHAR(2)), '')
	   INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_UNIT_VALUE_'		+ CAST(@i AS CHAR(2)), '')
	   INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_TOTAL_VALUE_'	+ CAST(@i AS CHAR(2)), '')
	END
	
	--Insert Footer
	--SET	@LP_FT_TOTAL_AMOUNT	= ''			--v2.0
	SET	@LP_FT_PIECES		= ''
	SET	@LP_FT_WEIGHT		= ''
	SET @LP_FT_TERMS1		= ''
	SET @LP_FT_TERMS2		= ''	
	SET @LP_FT_TERMS3		= ''
	SET @LP_FT_DISPLAY_LINE = ''
	SET @LP_FT_SIGN			= ''
	SET @LP_FT_COORD		= ''		
	SET @LP_FT_CVO			= ''
	SET @LP_FT_TOT_AMT_TXT	= ''	-- v2.4


--	IF NOT EXISTS(SELECT * FROM #PrintData_detail WHERE type_code IN (@frame,@case)) v2.5
	IF NOT EXISTS(SELECT * FROM #PrintData_detail) -- v2.6 WHERE type_code IN (@frame)) -- v2.5
	BEGIN
--		SELECT	@LP_FT_TOTAL_AMOUNT	= ': $ ' + CAST(CAST(total_invoice AS DECIMAL(20,2)) AS VARCHAR(40))
--		FROM	orders (NOLOCK)
--		WHERE	order_no	= @order_no AND 
--				ext			= @order_ext		
--
--		-- v1.1 If total is still null then get the total from the order
--		IF (SELECT total_invoice FROM orders (NOLOCK)
--				WHERE	order_no	= @order_no AND 
--						ext			= @order_ext) = 0
--		BEGIN
--			SELECT	@LP_FT_TOTAL_AMOUNT	= ': $ ' + CAST(CAST(total_amt_order AS DECIMAL(20,2)) AS VARCHAR(40))
--			FROM	orders (NOLOCK)
--			WHERE	order_no	= @order_no AND 
--					ext			= @order_ext		
--		END
			
		SELECT	@LP_FT_PIECES = ': ' + CAST(COUNT(DISTINCT CARTON_NO) AS VARCHAR(10))+ ' Box'
		FROM	#cartonsToShip --cartonsToShip_--
		WHERE	order_no	= @order_no AND 
				order_ext	= @order_ext

		SELECT	@LP_FT_WEIGHT	=  SUM(CAST(weight AS DECIMAL(20,2))) 
		FROM	tdc_carton_tx (NOLOCK)
		WHERE	order_no	= @order_no AND 
				order_ext	= @order_ext

		-- v1.1 If weight is still null then get the weight from the order line
		IF @LP_FT_WEIGHT IS NULL
		BEGIN
			SELECT	@LP_FT_WEIGHT	=  SUM(CAST((weight_ea * ordered) AS DECIMAL(20,2))) 
			FROM	ord_list (NOLOCK)
			WHERE	order_no	= @order_no AND 
					order_ext	= @order_ext
		END

		SET @LP_FT_TERMS1		= 'These commodities licensed by the U.S. for ultimate destination: ' + @LP_SHIP_TO_COUNTRY + ' Diversion contrary to U.S. law prohibited.'			--v2.0
		SET @LP_FT_TERMS2		= 'We hereby certify that the information on this invoice is true and correct and that the contents of this shipment are as stated above.'
		SET @LP_FT_TERMS3		= 'We do hereby authorize: Ship Via to execute any additional documents necessary for the export of merchandise described herein on our behalf.'
		SET @LP_FT_DISPLAY_LINE = '______________________________________'
		SET @LP_FT_SIGN			= ''
		SET @LP_FT_COORD		= 'International Sales Coordinator'		
		SET @LP_FT_CVO			= 'ClearVision Optical Co.'

		SET @LP_FT_TOT_AMT_TXT = CAST(@order_total AS VARCHAR(20))	-- v2.4

		INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_FT_TOTAL_AMOUNT', @LP_FT_TOT_AMT_TXT	)


	END	

	SELECT @LP_FT_WEIGHT = @LP_FT_WEIGHT + ' LB'					--v2.0
	
	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_FT_TOTAL_AMOUNT', ''	)
	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_FT_PIECES'		, @LP_FT_PIECES			)
	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_FT_WEIGHT'		, @LP_FT_WEIGHT			)
	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_FT_TERMS1'		, @LP_FT_TERMS1			)
	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_FT_TERMS2'		, @LP_FT_TERMS2			)
	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_FT_TERMS3'		, @LP_FT_TERMS3			)
	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_FT_DISPLAY_LINE', @LP_FT_DISPLAY_LINE	)
	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_FT_SIGN'		, @LP_FT_SIGN			)
	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_FT_COORD'		, @LP_FT_COORD			)
	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_FT_CVO'			, @LP_FT_CVO			)


END






GO
GRANT EXECUTE ON  [dbo].[CVO_Print_Commercial_Invoice_sp] TO [public]
GO
