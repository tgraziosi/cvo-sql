SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARGetAmtApplied_SP] @precission int,
				@cust_code varchar(8),
				@org_id varchar(30)
AS
BEGIN
	SELECT	ISNULL(SUM(ROUND(b.amt_applied * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) ), @precission)),0.0) 
	FROM	arinppyt a, arinppdt b, #arvpay 
	WHERE	a.customer_code = #arvpay.customer_code 
	AND	a.trx_ctrl_num = b.trx_ctrl_num 
	AND	a.trx_type = b.trx_type 
	AND	a.payment_type > 1 
	AND	a.trx_type = 2111
	AND	a.org_id = @org_id
END 
GO
GRANT EXECUTE ON  [dbo].[ARGetAmtApplied_SP] TO [public]
GO
