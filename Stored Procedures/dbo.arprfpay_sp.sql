SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[arprfpay_sp] @cust_code varchar(8), @trx_type smallint, @trx_num varchar(16)
AS
BEGIN
	DELETE #arinppyt

	DECLARE 	@home_prec smallint, 
			@oper_prec smallint
	
	SELECT	@home_prec = curr_precision
	FROM	glcurr_vw, glco
	WHERE	glco.home_currency = glcurr_vw.currency_code

	SELECT	@oper_prec = curr_precision
	FROM	glcurr_vw, glco
	WHERE	glco.oper_currency = glcurr_vw.currency_code
	
	insert into #arinppyt (
		trx_ctrl_num,		doc_ctrl_num,		doc_desc,
		trx_type,		cash_acct_code,	payment_code,
		date_doc,		customer_code,	date_applied,
		date_entered,		amt_payment,		amt_on_acct,
		nat_cur_code,		rate_type_home,	rate_type_oper,
		rate_home,		rate_oper,		amt_home,
		amt_oper
	)
	SELECT	trx_ctrl_num,		doc_ctrl_num,		doc_desc,
		trx_type,		cash_acct_code,	payment_code,
		date_doc,		customer_code,	date_applied,
		date_entered,		amt_net,		amt_on_acct,
		nat_cur_code,		rate_type_home,	rate_type_oper,
		rate_home,		rate_oper,		ROUND( amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ), @home_prec ),
		ROUND( amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ), @oper_prec )
	FROM artrx
	WHERE customer_code = @cust_code
	AND trx_type = @trx_type
	AND trx_ctrl_num = @trx_num
END

GO
GRANT EXECUTE ON  [dbo].[arprfpay_sp] TO [public]
GO
