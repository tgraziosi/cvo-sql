SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v1.1 CB 20/07/2011	68668-012 - Print from sales order
-- v2.0 TM 10/28/2011	Fix issue in Sold To field
-- v2.1 CB 13/07/2012	Use total value instead of unit value
-- v2.2 CB 10/01/2013	Issue #1078 - dates should be ship date
-- v2.3 CB 30/06/2015	Add weight field per line and add D/F column

CREATE PROCEDURE  [dbo].[CVO_Print_Export_Declaration_sp]   
			@order_no		INT,
			@order_ext		INT,
			@module			VARCHAR(3),
			@trans			VARCHAR(20),
			@trans_source	VARCHAR(2),
			@station_id     VARCHAR(20)
AS

BEGIN

	--Header vars
	DECLARE @format_id          VARCHAR(40),    
			@printer_id         VARCHAR(30),
			@number_of_copies	INT,
			@max_lines_per_page INT,
			@avail_lines_detail INT,
			@LP_CUST_NAME		VARCHAR(40),
			@LP_CUST_ADDR1		VARCHAR(40),
			@LP_CUST_ADDR2		VARCHAR(40),
			@LP_SHP_DATE		VARCHAR(20),
			@LP_SHIP_TO_NAME	VARCHAR(40),     
			@LP_SHIP_TO_ADD_1	VARCHAR(40),
			@LP_SHIP_TO_ADD_2	VARCHAR(40),
			@LP_SHIP_TO_ADD_3	VARCHAR(40),			--v2.0
			@LP_SHIP_TO_COUNTRY VARCHAR(40),									
			@LP_CARRIER			VARCHAR(20),
			@LP_CUR_DATE		VARCHAR(10),
			@LP_DF				CHAR(1) -- v2.3

	--Detail vars
	DECLARE @row_id				INT			 ,						
			@LP_PART_NO_DESC	VARCHAR(50)	 ,
			@LP_SCHEDULE_B_NO	VARCHAR(50)	 ,																		
			@LINE_NO			INT			 ,			
			@LP_QTY				DECIMAL(20,0),
			@LP_UNIT_VALUE		DECIMAL(20,2),
			@i					INT		

	--Footer vars
	DECLARE @LP_WEIGHT			VARCHAR(40)
	
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
	FROM	tdc_tx_print_routing (NOLOCK)
	WHERE	module				= @module		AND
			trans				= @trans		AND
			trans_source		= @trans_source AND   
			format_id			= @format_id    AND
			user_station_id		= @station_id 

	--max number of pages to print per page
	SELECT  @max_lines_per_page = CAST(detail_lines AS INT) 
	FROM    tdc_tx_print_detail_config (NOLOCK)
	WHERE	trans_source = 'VB'		AND 
			module       = 'SHP'	AND 
			trans        = @trans 

	--max number of detail lines existing in .lwl file
	SET @avail_lines_detail = 30

	--if user wants to print more lines than existing then
	IF @max_lines_per_page > @avail_lines_detail
		SET @max_lines_per_page = @avail_lines_detail

	TRUNCATE TABLE #PrintData  
	TRUNCATE TABLE #PrintData_Output
	
	-- Firstly, insert *FORMAT and all the data that we pass.
	INSERT INTO #PrintData_Output ( format_id,  printer_id,  number_of_copies)   
	VALUES (@format_id, @printer_id, @number_of_copies)    

	--Get Header Info
	SELECT @LP_CUST_NAME  = ISNULL(CompanyName,''),
		   @LP_CUST_ADDR1 = ISNULL(address1,'') + ', ' + ISNULL(address2,''), 
		   @LP_CUST_ADDR2 = ISNULL(city,'')     + ', ' + ISNULL(state,'')    + ' ' + ISNULL(zipCode,'')
	FROM   tdc_contact_reg (NOLOCK)
	WHERE  ServerName = @@SERVERNAME        
		   
		   
	--BEGIN SED008 -- Global Ship To
	--JVM 07/28/2010
	IF EXISTS(SELECT sold_to FROM orders (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext 
		AND sold_to IS NOT NULL AND LTRIM (sold_to) <> '' AND RTRIM (sold_to) <> ''
		AND sold_to <> cust_code)		--v2.0
		SELECT @LP_SHIP_TO_NAME    = ISNULL(address_name ,''),  
			   @LP_SHIP_TO_ADD_1   = ISNULL(addr1		 ,''), 
			   @LP_SHIP_TO_ADD_2   = ISNULL(addr2		 ,''), 
			   @LP_SHIP_TO_ADD_3   = ISNULL(addr3		 ,''),				--v2.0
			   @LP_SHIP_TO_COUNTRY = ISNULL(g.description ,'')				--v2.0
		FROM   armaster_all a (NOLOCK), gl_country g (NOLOCK)				--v2.0
		WHERE  address_type = 9 AND a.country_code = g.country_code AND		--v2.0
			   customer_code = (SELECT sold_to FROM orders (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext)
	ELSE	      		   
		SELECT @LP_SHIP_TO_NAME		= ISNULL(ship_to_name		,''),  
			   @LP_SHIP_TO_ADD_1	= ISNULL(ship_to_add_1		,''), 
			   @LP_SHIP_TO_ADD_2	= ISNULL(ship_to_add_2		,''),		   		   		   
			   @LP_SHIP_TO_ADD_3	= ISNULL(ship_to_add_3		,''),		--v2.0   		   		   
			   @LP_SHIP_TO_COUNTRY	= ISNULL(g.description,'')				--v2.0
		FROM   orders a (NOLOCK), gl_country g (NOLOCK)						--v2.0
		WHERE  order_no  = @order_no AND
			   ext       = @order_ext AND
			   a.ship_to_country_cd = g.country_code						--v2.0

	--END   SED008 -- Global Ship To

	SELECT @LP_CARRIER			= ISNULL(a.addr1,''),							--v2.0
		   @LP_SHP_DATE			= CONVERT(VARCHAR,sch_ship_date, 101)			--v2.0
	FROM   orders o (NOLOCK) 
		LEFT OUTER JOIN arshipv a (NOLOCK) ON o.routing = a.ship_via_code
	WHERE  order_no  = @order_no AND
		   ext       = @order_ext		   		   		   

	-- v2.3 Start
--	SELECT	@LP_WEIGHT	= SUM(CAST((weight / 2.20462262) AS DECIMAL(20,2)))
--	FROM	tdc_carton_tx (NOLOCK)
--	WHERE	order_no	= @order_no AND 
--			order_ext	= @order_ext

	-- v1.1 If weight is still null then get the weight from the order line
--	IF @LP_WEIGHT IS NULL
--	BEGIN
--		SELECT	@LP_WEIGHT	=  SUM(CAST(((weight_ea * ordered) / 2.20462262) AS DECIMAL(20,2)))			--v2.0
--		FROM	ord_list (NOLOCK)
--		WHERE	order_no	= @order_no AND 
--				order_ext	= @order_ext
--	END
	-- v2.3 End

	-- SELECT @LP_CUR_DATE = CONVERT(VARCHAR,GETDATE(), 101) v2.2
	SELECT @LP_CUR_DATE = CONVERT(VARCHAR,GETDATE(), 101)
	SELECT @LP_CUR_DATE	= @LP_SHP_DATE -- v2.2

	--Insert Header
	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_CUST_NAME'		,@LP_CUST_NAME		)
	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_CUST_ADDR1'		,@LP_CUST_ADDR1		)
	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_CUST_ADDR2'		,@LP_CUST_ADDR2		)
	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_SHP_DATE'		,@LP_SHP_DATE		)
	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_SHIP_TO_NAME'	,@LP_SHIP_TO_NAME	)
	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_SHIP_TO_ADD_1'	,@LP_SHIP_TO_ADD_1	)
	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_SHIP_TO_ADD_2'	,@LP_SHIP_TO_ADD_2	)	
	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_SHIP_TO_ADD_3'	,@LP_SHIP_TO_ADD_3	)	
	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_CARRIER_'		,@LP_CARRIER		)
	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_SHIP_TO_COUNTRY',@LP_SHIP_TO_COUNTRY)	
	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_CARRIER'		,@LP_CARRIER		)
-- v2.3	INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_WEIGHT'			,@LP_WEIGHT			)	
    INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_CUR_DATE'		,@LP_CUR_DATE		)	

	--First Insert Frames
    --@avail_lines_detail
    declare @cur VARCHAR(400)

--v2.0 Need to Group by Schedule B code
--	SET @cur = '
--    DECLARE lines_cur CURSOR FOR	
--    SELECT  TOP ' + CAST(@max_lines_per_page AS VARCHAR(2))  + ' row_id,  part_no_desc, line_no,  qty, unit_value, schedule_B_no
--	FROM    #PrintData_detail
--	ORDER BY carton_no, type_code
--	OPEN lines_cur'

	-- v2.3 Start
	SET @cur = '
    DECLARE lines_cur CURSOR FOR	
    SELECT  TOP ' + CAST(@max_lines_per_page AS VARCHAR(2))  + ' schedule_B_no, sum(convert(decimal(20,0),qty)), sum(total_value), 
			CASE WHEN LEFT(origin,13) = ''UNITED STATES'' THEN ''D'' ELSE ''F'' END 
	FROM    #PrintData_detail
	GROUP BY schedule_B_no, CASE WHEN LEFT(origin,13) = ''UNITED STATES'' THEN ''D'' ELSE ''F'' END 	
	ORDER BY schedule_B_no
	OPEN lines_cur'
	-- v2.3 End
	exec (@cur)

	SET @i = 0
	FETCH NEXT FROM lines_cur 
	INTO  @LP_SCHEDULE_B_NO, @LP_QTY, @LP_UNIT_VALUE, @LP_DF -- v2.3 

	WHILE @@FETCH_STATUS = 0
	BEGIN	
	   SET @i = @i + 1 	 

		-- v2.3 Start		
		SELECT	@LP_WEIGHT	=  CASE WHEN a.status IN ('P','R','S','T') THEN SUM(CAST(((a.weight_ea * a.shipped) / 2.20462262) AS DECIMAL(20,2)))
														ELSE SUM(CAST(((a.weight_ea * a.ordered) / 2.20462262) AS DECIMAL(20,2))) END
		FROM	ord_list a (NOLOCK)
		JOIN	#PrintData_detail b
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		AND		a.part_no = b.part_no
		WHERE	a.order_no	= @order_no 
		AND		a.order_ext	= @order_ext
		AND		b.schedule_B_no = @LP_SCHEDULE_B_NO
		AND		CASE WHEN LEFT(origin,13) = 'UNITED STATES' THEN 'D' ELSE 'F' END = @LP_DF
		GROUP BY a.status
		-- v2.3 End

	   INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_SCHEDULE_B_NO_'	+ CAST(@i AS CHAR(2)),@LP_SCHEDULE_B_NO	)
	   INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_QTY_'			+ CAST(@i AS CHAR(2)),@LP_QTY			)
	   INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_UNIT_VALUE_'		+ CAST(@i AS CHAR(2)),@LP_UNIT_VALUE	)	   

		-- v2.3 Start
	   INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_WEIGHT_'		+ CAST(@i AS CHAR(2)),@LP_WEIGHT)	   
	   INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_DF_'		+ CAST(@i AS CHAR(2)),@LP_DF)	   
		-- v2.3 End

	   DELETE #PrintData_detail WHERE row_id = @row_id
	
		FETCH NEXT FROM lines_cur 
		INTO  @LP_SCHEDULE_B_NO, @LP_QTY, @LP_UNIT_VALUE, @LP_DF -- v2.3  
	END

	CLOSE lines_cur
	DEALLOCATE lines_cur
	
	WHILE @i < @avail_lines_detail
	BEGIN	
	   SET @i = @i + 1   	   
	   INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_SCHEDULE_B_NO_'	+ CAST(@i AS CHAR(2)), '')
	   INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_QTY_'			+ CAST(@i AS CHAR(2)), '')
	   INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_UNIT_VALUE_'		+ CAST(@i AS CHAR(2)), '')	   
		-- v2.3 Start
	   INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_WEIGHT_'		+ CAST(@i AS CHAR(2)), '')	   
	   INSERT INTO #PrintData ( data_field,  data_value)   VALUES ('LP_DF_'		+ CAST(@i AS CHAR(2)), '')	   
		-- v2.3 End
	END
	 
END






GO
GRANT EXECUTE ON  [dbo].[CVO_Print_Export_Declaration_sp] TO [public]
GO
