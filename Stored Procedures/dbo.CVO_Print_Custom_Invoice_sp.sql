SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- v1.1 CB 20/07/2011	68668-012 - Print from sales order
-- v2.0 TM 10/28/2011	Fix issue in Sold To field
-- v2.1 CT 14/08/2012	Add polarized items to the invoice
-- v2.2 CT 16/08/2012	Keep polarized, but also show cases not linked to frames
-- v2.3 CT 17/08/2012	For cases not linked to parts and with no price on sales order, set price of 0.01
-- v2.4 CT 17/08/2012	Include cases not linked to frames in total qty
-- v2.5 CT 22/08/2012	Only print grand total on last page
-- v2.6 CB 30/08/2012	Only print the sub total on the last page
-- v10.0 CB 10/07/2012	CVO-CF-1 - Custom Frame Processing 
-- v10.1 CB 21/01/2013  Issue #1113 - Not dealing with frame/case relationship correctly
-- v10.2 CB 19/06/2015	Fix issue with LP_TOTAL_QTY on multiple pages

CREATE PROCEDURE  [dbo].[CVO_Print_Custom_Invoice_sp]   
			@order_no		INT,
			@order_ext		INT,
			@module			VARCHAR(3),
			@trans			VARCHAR(20),
			@trans_source	VARCHAR(2),
			@station_id     VARCHAR(20),
			@is_lastpage	SMALLINT, -- v2.5
			@LP_TOTAL_QTY	decimal(20,0) = 0 -- v10.2		
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
			@LP_SHIP_TO_PHONE	VARCHAR(20),
			@LP_SHIP_TO_ADD_3	VARCHAR(40),					--v2.0		
			@LP_SHIP_TO_ADD_4	VARCHAR(40),					--v2.0		
			@LP_ORD_TYPE		VARCHAR(4),						--v2.0		
			@LP_ORD_DATE		VARCHAR(12),					--v2.0		
			@LP_OPERATOR		VARCHAR(20),					--v2.0		
			@LP_SALES_REP		VARCHAR(20),					--v2.0		
			@LP_CUST_PO			VARCHAR(30),					--v2.0		
			@LP_INV_NO			VARCHAR(20),					--v2.0		
			@LP_SHIP_TO_COUNTRY	VARCHAR(30),					--v2.0		
			@LP_BILL_TO_NAME	VARCHAR(40),     				--v2.0		
			@LP_BILL_TO_ADD_1	VARCHAR(40),					--v2.0		
			@LP_BILL_TO_ADD_2	VARCHAR(40),					--v2.0		
			@LP_BILL_TO_ADD_3	VARCHAR(40),					--v2.0		
			@LP_BILL_TO_ADD_4	VARCHAR(40),					--v2.0		
			@LP_BILL_TO_COUNTRY	VARCHAR(30),					--v2.0		
			@LP_TERMS			VARCHAR(10),					--v2.0	
			@LP_CARRIER			VARCHAR(20),					--v2.0	
			@LP_SHP_DATE		VARCHAR(20),					--v2.0	
			@LP_CUST_NO			VARCHAR(8),						--v2.0	
			@LP_WEIGHT			VARCHAR(40),					--v2.0	
			@LP_POP_MSG			VARCHAR(65)						--v2.0	


	--Detail vars
	DECLARE @row_id				INT,
			@LP_PART_NO			VARCHAR(32),
			@PREV_PART_NO		VARCHAR(32),
			@LP_PART_NO_DESC	VARCHAR(50),
			@TYPE_CODE			VARCHAR(10),
			@ADD_CASE			CHAR(1),
			@LP_CASES_INCLUDED	VARCHAR(15),
			@LINE_NO			INT,
			@FROM_LINE_NO		INT,
			@LP_MATERIAL		VARCHAR(15),
			@LP_ORIGIN			VARCHAR(40),
			@LP_QTY				DECIMAL(20,0),
			@LP_UNIT_VALUE		DECIMAL(20,2),
			@LP_TOTAL_VALUE		DECIMAL(20,2),
			@is_POP				INT,
			@i					INT		

	--Footer vars
	DECLARE @LP_FT_TOTAL_AMOUNT	DECIMAL(20,2),				--v2.0
			@LP_FT_PIECES		VARCHAR(40),
			@LP_FT_WEIGHT		VARCHAR(40),
			@LP_FT_TERMS1		VARCHAR(200),
			@LP_FT_TERMS2		VARCHAR(200),
			@LP_FT_TERMS3		VARCHAR(200),
			@LP_FT_DISPLAY_LINE	VARCHAR(40),
			@LP_FT_SIGN			VARCHAR(40),
			@LP_FT_COORD		VARCHAR(40),		
			@LP_FT_CVO			VARCHAR(40),
-- v10.2	@LP_TOTAL_QTY		DECIMAL(20,0),				--v2.0
			@LP_TOTAL_AMOUNT	DECIMAL(20,2),				--v2.0
			@LP_TOTAL_FREIGHT	DECIMAL(20,2)				--v2.0

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
		SELECT @LP_SHIP_TO_NAME  = ISNULL(address_name		,''),  
			   @LP_SHIP_TO_ADD_1 = ISNULL(addr1				,''), 
			   @LP_SHIP_TO_ADD_2 = ISNULL(addr2				,''), 
			   @LP_SHIP_TO_ADD_3 = ISNULL(addr3,''),					--v2.0 
			   @LP_SHIP_TO_ADD_4 = ISNULL(addr4,''),					--v2.0 
			   @LP_SHIP_TO_PHONE = ISNULL(attention_phone	,''),
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
			   @LP_SHIP_TO_PHONE = ISNULL(phone,''),
			   @LP_SHIP_TO_COUNTRY	= ISNULL(g.description,'')				--v2.0
		FROM   orders a (NOLOCK), gl_country g (NOLOCK)						--v2.0
		WHERE  order_no  = @order_no AND
			   ext       = @order_ext AND
			   a.ship_to_country_cd = g.country_code						--v2.0
	--END  SED008 -- Global Ship To

	SELECT 	@LP_ORD_TYPE	= IsNull(o.user_category,''),			--v2.0		
			@LP_ORD_DATE	= o.date_entered,						--v2.0		
			@LP_OPERATOR	= IsNull(o.who_entered,''),				--v2.0		
			@LP_SALES_REP	= IsNull(o.salesperson,''),				--v2.0		
			@LP_CUST_PO		= IsNull(o.cust_po,''),					--v2.0		
			-- tag 11/8/2013 @LP_INV_NO		= CONVERT(char(20),o.order_no),			--v2.0
			@LP_INV_NO		= CONVERT(char(20),isnull(oi.doc_ctrl_num,o.order_no)),			--v2.0
			@LP_BILL_TO_NAME = ISNULL(a.customer_name,''),			--v2.0
			@LP_BILL_TO_ADD_1 = ISNULL(a.addr2,''),					--v2.0
			@LP_BILL_TO_ADD_2 = ISNULL(a.addr3,''),					--v2.0
			@LP_BILL_TO_ADD_3 = ISNULL(a.addr4,''),					--v2.0
			@LP_BILL_TO_ADD_4 = ISNULL(a.addr5,''),					--v2.0
			@LP_BILL_TO_COUNTRY	= ISNULL(g.description,'')			--v2.0
	FROM   orders o (NOLOCK)
		LEFT JOIN arcust a (NOLOCK) ON o.cust_code = a.customer_code
		LEFT JOIN gl_country g (NOLOCK) ON a.country_code = g.country_code	--v2.0
		-- tag 11/8/2013
		left join cvo_order_invoice oi (nolock) on o.order_no = oi.order_no and o.ext = oi.order_ext
	WHERE  o.order_no  = @order_no AND o.ext = @order_ext


	SELECT @LP_CUST_NO			= o.cust_code,
		   @LP_TERMS			= ISNULL(t.terms_desc,''),
		   @LP_CARRIER			= ISNULL(a.addr1,''),
		   @LP_SHP_DATE			= CONVERT(VARCHAR,sch_ship_date,101)
	FROM   orders o (NOLOCK)
		LEFT OUTER JOIN arshipv a (NOLOCK) ON o.routing = a.ship_via_code
		LEFT OUTER JOIN arterms t (NOLOCK) ON o.terms = t.terms_code
	WHERE  order_no = @order_no AND ext = @order_ext

	--Insert Header
	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_CUST_ADDR'    ,@LP_CUST_ADDR	)
	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_CUST_ADDR1'   ,@LP_CUST_ADDR1	)
	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_CUST_ADDR2'   ,@LP_CUST_ADDR2	)
	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_CUST_PHONE'   ,@LP_CUST_PHONE	)
	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_CUST_FAX'     ,@LP_CUST_FAX		)
	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_SHIP_TO_NAME' ,@LP_SHIP_TO_NAME )
	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_SHIP_TO_ADD_1',@LP_SHIP_TO_ADD_1)
	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_SHIP_TO_ADD_2',@LP_SHIP_TO_ADD_2)
	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_SHIP_TO_ADD_3',@LP_SHIP_TO_ADD_3)
	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_SHIP_TO_ADD_4',@LP_SHIP_TO_ADD_4)
	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_SHIP_TO_PHONE',@LP_SHIP_TO_PHONE)
	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_SHIP_TO_COUNTRY',@LP_SHIP_TO_COUNTRY)
	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_ORD_TYPE',@LP_ORD_TYPE)				--v2.0
	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_ORD_DATE',@LP_ORD_DATE)				--v2.0
	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_OPERATOR',@LP_OPERATOR)				--v2.0
	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_SALES_REP',@LP_SALES_REP)			--v2.0
	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_CUST_PO',@LP_CUST_PO)				--v2.0
	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_INV_NO',@LP_INV_NO)					--v2.0
	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_BILL_TO_NAME',@LP_BILL_TO_NAME)		--v2.0
	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_BILL_TO_ADD_1',@LP_BILL_TO_ADD_1)	--v2.0
	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_BILL_TO_ADD_2',@LP_BILL_TO_ADD_2)	--v2.0
	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_BILL_TO_ADD_3',@LP_BILL_TO_ADD_3)	--v2.0
	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_BILL_TO_ADD_4',@LP_BILL_TO_ADD_4)	--v2.0
	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_BILL_TO_COUNTRY',@LP_BILL_TO_COUNTRY)	--v2.0
	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_CUST_NO',@LP_CUST_NO)				--v2.0
	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_TERMS',@LP_TERMS)					--v2.0
	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_CARRIER',@LP_CARRIER)				--v2.0
	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_SHP_DATE',@LP_SHP_DATE)				--v2.0


	-- v10.1 Start
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
	-- v10.1 End


--v2.0
	-- START v2.4
	-- v10.2 Start
--    SELECT @LP_TOTAL_QTY = SUM(CAST(qty AS decimal(20,0)))
--	  FROM #PrintData_detail WHERE (type_code <> @case) OR (type_code = @case AND from_line_no = 0)
	-- v10.2 End
	
	/*
    SELECT @LP_TOTAL_QTY = SUM(CAST(qty AS decimal(20,0)))
	  FROM #PrintData_detail WHERE type_code <> @case
	*/
	-- END v2.4


	SELECT @LP_FT_TOTAL_AMOUNT = 0
	SELECT @LP_TOTAL_AMOUNT = 0
	SELECT @LP_TOTAL_FREIGHT = 0
	SELECT @is_POP = 0

--v2.0
	--First Insert Frames
    --@avail_lines_detail	
    declare @cur VARCHAR(400)
	-- v2.1 v2.2 Start
--	SET @cur = '
--    DECLARE lines_cur CURSOR FOR	
--    SELECT  TOP ' + CAST(@max_lines_per_page AS VARCHAR(2))  + ' row_id, part_no, part_no_desc, type_code, add_case, line_no, from_line_no, material, origin, qty, unit_value, total_value
--	FROM    #PrintData_detail
--	WHERE from_line_no = 0  ORDER BY carton_no, type_code
--	OPEN lines_cur'

	
	SET @cur = '
    DECLARE lines_cur CURSOR FOR	
    SELECT  TOP ' + CAST(@max_lines_per_page AS VARCHAR(2))  + ' row_id, part_no, part_no_desc, type_code, add_case, line_no, from_line_no, material, origin, qty, unit_value, total_value
	FROM    #PrintData_detail
	WHERE ((from_line_no = 0) OR (from_line_no <> 0 AND type_code <> '''+ @case +'''))   ORDER BY carton_no, type_code 
	OPEN lines_cur'
	-- END v2.1 v2.2

	exec (@cur)

	SET @i = 0
	FETCH NEXT FROM lines_cur 
	INTO @row_id, @LP_PART_NO, @LP_PART_NO_DESC, @TYPE_CODE, @ADD_CASE, @LINE_NO, @FROM_LINE_NO, @LP_MATERIAL, @LP_ORIGIN, @LP_QTY, @LP_UNIT_VALUE, @LP_TOTAL_VALUE

	WHILE @@FETCH_STATUS = 0
	BEGIN	
	   SET @i = @i + 1 	 
	   SET @LP_CASES_INCLUDED = ''
	   
	  IF @LP_PART_NO = @PREV_PART_NO
		SET @LP_PART_NO = ''
	  ELSE
		SET @PREV_PART_NO = @LP_PART_NO	

		--if it is a frame AND include case AND cases are included in this shipment
--v2.0  The flag on the table is reset to N after case is added so we just need to look
	   --IF @TYPE_CODE = @frame AND @add_case = 'Y' AND EXISTS(SELECT * FROM #PrintData_detail WHERE order_no = @order_no AND order_ext = @order_ext AND type_code = @case AND from_line_no =  @LINE_NO)
-- v10.0	   IF @TYPE_CODE <> @case AND EXISTS(SELECT * FROM #PrintData_detail WHERE order_no = @order_no AND order_ext = @order_ext AND type_code = @case AND from_line_no =  @LINE_NO)
-- v10.1 Start
		IF ( @TYPE_CODE <> @case AND EXISTS(SELECT a.* FROM #PrintData_detail a JOIN #cvo_ord_list b ON a.order_no = b.order_no AND a.order_ext = b.order_ext AND a.line_no = b.line_no
												AND a.type_code = @case AND b.from_line_no = @LINE_NO))
		SET @LP_CASES_INCLUDED = 'CASES INCLUDED'		
-- v10.1 End

--	   IF @TYPE_CODE <> @case AND EXISTS(SELECT 1 FROM cvo_ord_list (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext AND line_no =  @LINE_NO AND add_case = 'Y') -- v10.0
--		SET @LP_CASES_INCLUDED = 'CASES INCLUDED'		

	   IF @LP_UNIT_VALUE = 0 AND @FROM_LINE_NO = 0 AND @TYPE_CODE <> 'CASE'
		  BEGIN
			IF @TYPE_CODE IN ('FRAME','SUN')
				BEGIN	
				    SET @is_POP = 1
				    SET @LP_PART_NO_DESC = '(*) '+@LP_PART_NO_DESC
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


		UPDATE #Print_Doc_Total SET doc_total = doc_total + @LP_TOTAL_VALUE

		SELECT @LP_TOTAL_AMOUNT = @LP_TOTAL_AMOUNT + @LP_TOTAL_VALUE

	   INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_PART_NO_'	    + CAST(@i AS CHAR(2)),@LP_PART_NO		)
	   INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_PART_NO_DESC_'   + CAST(@i AS CHAR(2)),@LP_PART_NO_DESC	)
	   INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_CASES_INCLUDED_' + CAST(@i AS CHAR(2)),@LP_CASES_INCLUDED)
	   INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_MATERIAL_'		+ CAST(@i AS CHAR(2)),@LP_MATERIAL		)
	   INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_ORIGIN_'			+ CAST(@i AS CHAR(2)),@LP_ORIGIN		)
	   INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_QTY_'			+ CAST(@i AS CHAR(2)),@LP_QTY			)
	   INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_UNIT_VALUE_'		+ CAST(@i AS CHAR(2)),@LP_UNIT_VALUE	)
	   INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_TOTAL_VALUE_'	+ CAST(@i AS CHAR(2)),@LP_TOTAL_VALUE	)

	   DELETE #PrintData_detail WHERE row_id = @row_id

	   FETCH NEXT FROM lines_cur 
	   INTO @row_id, @LP_PART_NO, @LP_PART_NO_DESC, @TYPE_CODE, @ADD_CASE, @LINE_NO, @FROM_LINE_NO, @LP_MATERIAL, @LP_ORIGIN, @LP_QTY, @LP_UNIT_VALUE, @LP_TOTAL_VALUE
	END

	CLOSE lines_cur
	DEALLOCATE lines_cur

	SET @PREV_PART_NO = ''

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
	INTO @LP_PART_NO, @LP_ORIGIN, @LP_QTY

	WHILE @@FETCH_STATUS = 0 AND @i < @max_lines_per_page
	BEGIN	

--if @i < @max_lines_per_page
--begin
	   SET @i = @i + 1 	 	   
	   SET @LP_PART_NO_DESC   = 'CASES: COST ARE INCLUDED W/FRAMES'
       SET @LP_CASES_INCLUDED = ''
	   SET @LP_MATERIAL       = ''
       --SET @LP_UNIT_VALUE     = ''
       --SET @LP_TOTAL_VALUE    = ''

	  IF @LP_PART_NO = @PREV_PART_NO
		SET @LP_PART_NO = ''
	  ELSE
		SET @PREV_PART_NO = @LP_PART_NO

	   DELETE #PrintData_detail WHERE type_code = @case
--end
	   FETCH NEXT FROM cases_lines_cur 
	   INTO @LP_PART_NO, @LP_ORIGIN, @LP_QTY
	END

	CLOSE cases_lines_cur
	DEALLOCATE cases_lines_cur	

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
	SET	@LP_FT_TOTAL_AMOUNT	= 0			
	SET	@LP_FT_PIECES		= ''
	SET	@LP_FT_WEIGHT		= ''
	SET @LP_FT_TERMS1		= ''
	SET @LP_FT_TERMS2		= ''	
	SET @LP_FT_TERMS3		= ''
	SET @LP_FT_DISPLAY_LINE = ''
	SET @LP_FT_SIGN			= ''
	SET @LP_FT_COORD		= ''		
	SET @LP_FT_CVO			= ''
	SET @LP_POP_MSG			= ''		--v2.0

   IF @is_pop = 1
	 BEGIN
		SET @LP_POP_MSG = '* PROMOTIONAL MATERIAL. NO COMMERCIAL VALUE. FOR CUSTOMS ONLY.'
		INSERT INTO #PrintData ( data_field,  data_value) VALUES ('LP_POP_MSG', @LP_POP_MSG)		--v2.1
	 END

	IF NOT EXISTS(SELECT * FROM #PrintData_detail WHERE type_code IN (@frame,@case))
	BEGIN
		SELECT	@LP_WEIGHT	=  SUM(CAST((weight_ea * ordered) AS DECIMAL(20,2))) 
		  FROM	ord_list (NOLOCK)
		 WHERE	order_no	= @order_no AND order_ext	= @order_ext

		SELECT @LP_WEIGHT = @LP_WEIGHT + ' LB'					--v2.0

		SELECT @LP_TOTAL_FREIGHT = tot_ord_freight
		  FROM orders (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext

	END

	SELECT @LP_FT_TOTAL_AMOUNT = doc_total + @LP_TOTAL_FREIGHT FROM #Print_Doc_Total

	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_WEIGHT',@LP_WEIGHT)					--v2.0
	-- tg - print on last page only INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_TOTAL_QTY', @LP_TOTAL_QTY)				--v2.0
	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_TOTAL_FREIGHT', @LP_TOTAL_FREIGHT)		--v2.0
 
	-- START v2.5
	IF ISNULL(@is_lastpage,0) = 1
	BEGIN
		SET @LP_TOTAL_AMOUNT = (@LP_FT_TOTAL_AMOUNT - @LP_TOTAL_FREIGHT) -- v2.6
		-- tg - print on last page only
		INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_TOTAL_QTY', @LP_TOTAL_QTY)				--v2.0
		INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_FT_TOTAL_AMOUNT', @LP_FT_TOTAL_AMOUNT)
		INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_TOTAL_AMOUNT', @LP_TOTAL_AMOUNT)		--v2.6
	END
	ELSE
	BEGIN
		INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_TOTAL_QTY', '')				--v2.0
		INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_FT_TOTAL_AMOUNT', '')
		INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_TOTAL_AMOUNT', '')		--v2.6
	END
	-- END v2.5


END





GO
