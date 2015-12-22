SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_pre_post_CR_validation_sp]	@all_dates	int,
												@from_date	int,
												@end_date	int,
												@all_trx	int,
												@from_trx	varchar(16),
												@end_trx	varchar(16),
												@all_cust	int,
												@from_cust	varchar(10),
												@end_cust	varchar(10),
												@all_pay	int,
												@from_pay	varchar(10),
												@end_pay	varchar(10)
AS
BEGIN

	-- Directives
	SET NOCOUNT ON
	SET QUOTED_IDENTIFIER OFF

	-- Declarations
	DECLARE	@SQL		varchar(5000)

	-- Working table
	CREATE TABLE #trans_to_post (
		customer_code	varchar(10),
		trx_ctrl_num	varchar(16), 
		trx_type		int)

	-- Build main query
	SET @SQL = "INSERT #trans_to_post (customer_code, trx_ctrl_num, trx_type) SELECT customer_code, trx_ctrl_num, trx_type FROM arinppyt (NOLOCK) "
    SET @SQL = @SQL + " WHERE hold_flag = 0 AND posted_flag = 0 AND non_ar_flag = 0 AND settlement_ctrl_num IN (SELECT settlement_ctrl_num FROM arinpstlhdr WHERE settle_flag = 0 ) "
	SET @SQL = @SQL + " AND trx_type BETWEEN 2111 AND 2111 "

	-- Add parameters
	IF (@all_dates = 0)
		SET @SQL = @SQL + " AND date_doc BETWEEN " + CAST(@from_date AS varchar(8)) + " AND " + CAST(@end_date AS varchar(8)) + " "

	IF (@all_trx = 0)
		SET @SQL = @SQL + " AND trx_ctrl_num BETWEEN '" + @from_trx + "' AND '" + @end_trx + "' "
 
	IF (@all_cust = 0)
		SET @SQL = @SQL + " AND customer_code BETWEEN '" + @from_cust + "' AND '" + @end_cust + "' "

	IF (@all_pay = 0)
		SET @SQL = @SQL + " AND payment_code BETWEEN '" + @from_pay + "' AND '" + @end_pay + "' "

	-- EXEC the SQL
	EXEC(@SQL)

	-- Check that there is data to post
	IF NOT EXISTS (SELECT 1 FROM #trans_to_post)
	BEGIN
		SELECT 'No transactions to post. Transactions may be on hold or waiting to be approved.'
		DROP TABLE #trans_to_post
		RETURN
	END

	DROP TABLE #trans_to_post
	
	-- Clear out parameter table for user
	DELETE	cvo_CR_parameters WHERE username = suser_sname()

	-- Add the paymethod to the parameter table for use later in the posting routine if specified
	IF (@all_pay = 0)
	BEGIN
		INSERT	cvo_CR_parameters (username, from_paymeth, end_paymeth)
		SELECT	suser_sname(), @from_pay, @end_pay
	END	

	SELECT ''

END
GO
GRANT EXECUTE ON  [dbo].[cvo_pre_post_CR_validation_sp] TO [public]
GO
