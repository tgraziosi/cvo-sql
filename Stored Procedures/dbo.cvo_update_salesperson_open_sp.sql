SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[cvo_update_salesperson_open_sp]	@from_code		varchar(10),
												@to_code		varchar(10),
												@date_from		varchar(10),
												@date_to		varchar(10),
												@status_str		varchar(30),
												@order_type		varchar(10),
												@ext_from		int,
												@ext_to			int,
												@promo_id		varchar(20),
												@promo_level	varchar(30),
												@cust_from		varchar(10),
												@cust_to		varchar(10)
AS
BEGIN
	-- DIRECTIVES
	SET NOCOUNT ON
	SET QUOTED_IDENTIFIER OFF

	-- DECLARATIONS
	DECLARE	@SQL	varchar(5000)

	-- Working table
	CREATE TABLE #results (
		order_no		int,
		order_ext		int,
		order_no_text	varchar(30),
		order_type		varchar(10),
		entered_date	varchar(50),
		status			varchar(20),
		hold_reason		varchar(50),
		user_category	varchar(20),
		promo_id		varchar(20),
		promo_level		varchar(30),
		code_to			varchar(10),
		territory_code	varchar(10),
		process			char(1))

	-- Build SQL statement to populate working table
	SET @SQL = 'INSERT #results '
	SET @SQL = @SQL + ' SELECT a.order_no, a.ext, CAST(a.order_no AS varchar(20)) + ''-'' + CAST(a.ext AS varchar(10)), CASE WHEN a.type = ''I'' THEN ''INVOICE'' ELSE ''CREDIT'' END, '
	SET @SQL = @SQL + ' CONVERT(varchar(10),a.date_entered,101) + '' '' + a.who_entered, '
	SET @SQL = @SQL + ' CASE a.status WHEN ''A'' THEN ''User Hold'' WHEN ''B'' THEN ''Price Hold'' WHEN ''H'' THEN ''Price hold'' WHEN ''C'' THEN ''Credit Hold'' WHEN ''N'' THEN ''New'' '
	SET @SQL = @SQL + ' WHEN ''Q'' THEN ''Open/Printed'' WHEN ''P'' THEN ''Open/Picked'' ELSE ''Unknown'' END, a.hold_reason, a.user_category, b.promo_id, b.promo_level, ' 
	SET @SQL = @SQL + ' ''' + @to_code + ''', a.ship_to_region, ''Y'' '

	-- From
	SET @SQL = @SQL + ' FROM orders_all a (NOLOCK) JOIN cvo_orders_all b (NOLOCK) ON a.order_no = b.order_no AND a.ext = b.ext '

	-- Where
	SET @SQL = @SQL + ' WHERE a.salesperson = ''' + @from_code + ''' AND CONVERT(varchar(10),a.date_entered,112) >= ''' + 
						CONVERT(varchar(10),@date_from,112) + ''' AND CONVERT(varchar(10),a.date_entered,112) <= ''' + CONVERT(varchar(10),@date_to,112) + ''' AND '
	SET @SQL = @SQL + ' a.ext >= ' + CAST(@ext_from AS varchar(10)) + ' AND a.ext <= ' + CAST(@ext_to AS varchar(10)) + ' AND a.status IN ' + @status_str + ' '
	
	IF (@order_type > '')
	BEGIN
		SET @SQL = @SQL + ' AND a.user_category = ''' + @order_type + ''' '
	END

	IF (@promo_id > '')
	BEGIN
		SET @SQL = @SQL + ' AND b.promo_id = ''' + @promo_id + ''' AND b.promo_level = ''' + @promo_level + ''' '
	END
	
	-- v1.1 Start
	IF (@cust_from > '' AND @cust_to > '')
	BEGIN
		SET @SQL = @SQL + ' AND a.cust_code >= ''' + @cust_from + ''' AND a.cust_code <= ''' + @cust_to + ''' '
	END

	IF ((@cust_from > '' AND @cust_to = '') OR (@cust_from = '' AND @cust_to > ''))
	BEGIN
		IF (@cust_from > '')
			SET @SQL = @SQL + ' AND a.cust_code = ''' + @cust_from + ''' '
		IF (@cust_to > '')
			SET @SQL = @SQL + ' AND a.cust_code = ''' + @cust_to + ''' '
	END
	-- v1.1 End

	EXEC (@SQL)

	-- Update the territory_code to be the new one
	UPDATE	a
	SET		territory_code = b.territory_code
	FROM	#results a
	JOIN	arsalesp b (NOLOCK)
	ON		a.code_to = b.salesperson_code

	-- Remove any orders where they exist in a closed carton
	DELETE	a
	FROM	#results a
	JOIN	tdc_carton_tx b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	WHERE	b.order_type = 'S'
	AND		b.status <> 'O'

	SELECT * FROM #results ORDER BY order_no, order_ext

	DROP TABLE #results

END
GO
GRANT EXECUTE ON  [dbo].[cvo_update_salesperson_open_sp] TO [public]
GO
