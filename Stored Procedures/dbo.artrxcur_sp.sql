SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[artrxcur_sp] @doc_ctrl_num varchar( 16 ), @trx_type smallint
AS

DECLARE	
		@sum_gain_home		float,	 
		@sum_gain_oper		float,	
		@precision_home		smallint,
		@precision_oper		smallint,
		@amt_paid_to_date		float

SELECT	@precision_home = curr_precision
FROM	glcurr_vw, glco
WHERE	glco.home_currency = glcurr_vw.currency_code

SELECT	@precision_oper = curr_precision
FROM	glcurr_vw, glco
WHERE	glco.oper_currency = glcurr_vw.currency_code

BEGIN
	DELETE #artrxcur

	SELECT	
		@sum_gain_home = 0.0,
		@sum_gain_oper = 0.0

	INSERT #artrxcur 
	(
		nat_cur_code,		amt_gross,		amt_discount,
		amt_freight,		amt_tax,		amt_net,
		amt_tot_chg,		amt_paid_to_date,	balance,
		rate_home_1,		rate_home_2,		rate_home_3,
		rate_home_4,		rate_home_5,		rate_home_6,
		rate_home_7,		rate_oper_1,		rate_oper_2,
		rate_oper_3,		rate_oper_4, 		rate_oper_5,
		rate_oper_6,		rate_oper_7,		rate_home,
		rate_oper,			
		amt_gross_home,					
		amt_discount_home,
		amt_freight_home,		
		amt_tax_home,						
		amt_net_home,
		amt_tot_chg_home,		
		amt_paid_to_date_home,				
		balance_home,
		amt_gross_oper,		
		amt_discount_oper,					
		amt_freight_oper,
		amt_tax_oper,			
		amt_net_oper,						
		amt_tot_chg_oper,
		amt_paid_to_date_oper,	
		balance_oper,						
		gain_home,
		gain_oper	
	)
	SELECT nat_cur_code,		amt_gross, 		amt_discount,				
		amt_freight,		amt_tax,		amt_net,	
		amt_tot_chg,		amt_paid_to_date, 	(amt_tot_chg-amt_paid_to_date),	
		rate_home,		rate_home,		rate_home,
		rate_home,		rate_home,		rate_home,				
		rate_home,	 	rate_oper,		rate_oper,	
		rate_oper,		rate_oper, 		rate_oper,				
		rate_oper,		rate_oper,		rate_home,
		rate_oper,										
		ROUND(amt_gross * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ), @precision_home),
		ROUND(amt_discount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ), @precision_home),	 			
		ROUND(amt_freight * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ), @precision_home),
		ROUND(amt_tax * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ), @precision_home),				
		ROUND(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ), @precision_home),	
		ROUND(amt_tot_chg * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ), @precision_home),				
		ROUND(amt_paid_to_date * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ), @precision_home),
		ROUND((amt_tot_chg-amt_paid_to_date) * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ), @precision_home), 	
		ROUND(amt_gross * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ),	@precision_oper),
		ROUND(amt_discount * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ), @precision_oper),				
		ROUND(amt_freight * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ), @precision_oper),
		ROUND(amt_tax * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ), @precision_oper),				
		ROUND(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ), @precision_oper),	
		ROUND(amt_tot_chg * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ), @precision_oper), 				
		ROUND(amt_paid_to_date * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ), @precision_oper),
		ROUND((amt_tot_chg-amt_paid_to_date) * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ), @precision_oper),	
		@sum_gain_home,
		@sum_gain_oper 
	FROM	artrx 
	WHERE	doc_ctrl_num = @doc_ctrl_num 
	AND	trx_type = @trx_type


	SELECT	@sum_gain_home = ISNULL(sum(ISNULL(gain_home,0.0)),0.0),
		@sum_gain_oper = ISNULL(sum(ISNULL(gain_oper,0.0)) ,0.0)
	FROM	artrxpdt 
	WHERE	apply_to_num = @doc_ctrl_num 
	AND	apply_trx_type = @trx_type 

	UPDATE #artrxcur 
	SET	gain_home = @sum_gain_home, 
		gain_oper = @sum_gain_oper	

	SELECT @amt_paid_to_date = amt_paid_to_date from #artrxcur

	IF (ABS((@amt_paid_to_date)-(0.0)) > 0.0000001)
		UPDATE #artrxcur
		SET 	rate_home = (amt_paid_to_date_home + @sum_gain_home)/amt_paid_to_date, 
			rate_oper = (amt_paid_to_date_oper + @sum_gain_oper)/amt_paid_to_date 
		
		
	
	IF(SELECT SIGN(rate_home_1) FROM #artrxcur ) < 0.0
	BEGIN
		UPDATE	#artrxcur
		SET	rate_home = - 1/rate_home			
	END

	IF(SELECT SIGN(rate_oper_1) FROM #artrxcur ) < 0.0
	BEGIN
		UPDATE	#artrxcur
		SET	rate_oper = - 1/rate_oper			
	END
END
GO
GRANT EXECUTE ON  [dbo].[artrxcur_sp] TO [public]
GO
