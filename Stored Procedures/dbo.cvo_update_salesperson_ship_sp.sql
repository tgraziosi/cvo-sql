SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[cvo_update_salesperson_ship_sp]
AS
BEGIN
	-- DIRECTIVES
	SET NOCOUNT ON

	-- DECLARATIONS
	DECLARE @timefence	int

	-- Get the config setting
	IF EXISTS (SELECT 1 FROM dbo.config (NOLOCK) WHERE flag = 'SALESP UPD TIMEFRAME' AND ISNUMERIC(value_str) = 1)
		SELECT @timefence = CAST(value_str AS int) FROM dbo.config (NOLOCK) WHERE flag = 'SALESP UPD TIMEFRAME' 
	ELSE
		SET @timefence = 2

	-- CREATE WORKING TABLE
	CREATE TABLE #cvo_update_salesperson_ship (
		order_no				int,
		order_ext				int,
		order_no_text			varchar(30),
		order_type				varchar(20),
		date_shipped			varchar(50),
		territory_code			varchar(10),
		new_territory_code		varchar(10),
		salesperson_code		varchar(10),
		new_salesperson_code	varchar(10),
		process					char(1),
		ignore					char(1))

	-- Get data
	INSERT	#cvo_update_salesperson_ship
	SELECT	a.order_no,
			a.ext,
			CAST(a.order_no as varchar(20)) + '-' + CAST(a.ext as varchar(10)),
			CASE a.type WHEN 'I' THEN 'ORDER' ELSE 'CREDIT' END,
			CONVERT(varchar(10),a.date_shipped,101) + ' ' + a.who_entered,
			a.ship_to_region,
			b.territory_code,
			a.salesperson,
			b.salesperson_code,
			'N',
			'Y'
	FROM	orders_all a (NOLOCK)
	JOIN	armaster_all b (NOLOCK)
	ON		a.cust_code = b.customer_code
	AND		a.ship_to = b.ship_to_code
	WHERE	a.status IN ('R','S','T')
	AND		CONVERT(varchar(10),a.date_shipped,112) < CONVERT(varchar(10),DATEADD(day, 1, GETDATE()),112)
	AND		CONVERT(varchar(10),a.date_shipped,112) >= CONVERT(varchar(10),DATEADD(month, (@timefence * -1) , GETDATE()),112)
	AND		(a.salesperson <> b.salesperson_code)

	-- Insert the new records into the cvo_update_salesperson_ship table
	INSERT	dbo.cvo_update_salesperson_ship 
		(order_no, order_ext, order_no_text, order_type, date_shipped, territory_code, new_territory_code, salesperson_code, 
			new_salesperson_code, process, ignore)
	SELECT	a.order_no, 
			a.order_ext, 
			a.order_no_text, 
			a.order_type, 
			a.date_shipped, 
			a.territory_code, 
			a.new_territory_code, 
			a.salesperson_code, 
			a.new_salesperson_code, 
			a.process, 
			a.ignore
	FROM	#cvo_update_salesperson_ship a
	LEFT JOIN
			dbo.cvo_update_salesperson_ship b 
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.order_ext
	WHERE	b.order_no IS NULL		

	DROP TABLE #cvo_update_salesperson_ship

	-- Remove records that are outside of the timeframe
	DELETE	a
	FROM	cvo_update_salesperson_ship a
	JOIN	orders_all b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.order_ext = b.ext
	WHERE	CONVERT(varchar(10),b.date_shipped,112) < CONVERT(varchar(10),DATEADD(month, (@timefence * -1) , GETDATE()),112)

END

GO
GRANT EXECUTE ON  [dbo].[cvo_update_salesperson_ship_sp] TO [public]
GO
