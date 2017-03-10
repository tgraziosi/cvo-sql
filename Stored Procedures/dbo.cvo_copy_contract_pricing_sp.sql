SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_copy_contract_pricing_sp] @cust_code varchar(10),
											 @to_cust_code varchar(10)
AS
BEGIN
	-- DIRECTIVES
	SET NOCOUNT ON

	-- WORKING TABLES
	CREATE TABLE #copy_quote (
		customer_key	varchar(10),
		ship_to_no		varchar(10),
		ilevel			int,
		item			varchar(30),
		min_qty			decimal(20,8),
		type			char(1),
		rate			decimal(20,8),
		note			varchar(255),
		date_entered	datetime,
		date_expires	datetime,
		sales_comm		decimal(20,8),
		cust_part_no	varchar(50),
		curr_key		varchar(10),
		start_date		datetime,
		style			varchar(40),
		res_type		varchar(10))

	INSERT	#copy_quote
	SELECT	customer_key, ship_to_no, ilevel, item, min_qty, type, rate, note, date_entered, date_expires, 
			sales_comm, cust_part_no, curr_key, start_date, style, res_type
	FROM	c_quote (NOLOCK)
	WHERE	customer_key = @cust_code
	AND		ship_to_no = 'ALL'

	UPDATE	#copy_quote
	SET		customer_key = @to_cust_code,
			date_entered = GETDATE()

	DELETE	a
	FROM	#copy_quote a
	JOIN	c_quote b (NOLOCK)
	ON		a.customer_key = b.customer_key
	AND		a.ship_to_no = b.ship_to_no
	AND		a.ilevel = b.ilevel
	AND		a.item = b.item
-- v1.2	AND		a.type = b.type
	AND		a.curr_key = b.curr_key
-- v1.1	AND		a.style = b.style
-- v1.1	AND		a.res_type = b.res_type

	INSERT	c_quote (customer_key, ship_to_no, ilevel, item, min_qty, type, rate, note, date_entered, date_expires, 
			sales_comm, cust_part_no, curr_key, start_date, style, res_type)
	SELECT	customer_key, ship_to_no, ilevel, item, min_qty, type, rate, note, date_entered, date_expires, 
			sales_comm, cust_part_no, curr_key, start_date, style, res_type
	FROM	#copy_quote

	DROP TABLE #copy_quote

	RETURN

END
GO
GRANT EXECUTE ON  [dbo].[cvo_copy_contract_pricing_sp] TO [public]
GO
