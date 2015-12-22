SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[apuapto_sp] 
					 
AS
BEGIN

	
	DECLARE	@precision_home	smallint,
			@precision_oper	smallint

	SELECT	@precision_home = curr_precision
	FROM	glcurr_vw, glco
	WHERE	glco.home_currency = glcurr_vw.currency_code

	SELECT	@precision_oper = curr_precision
	FROM	glcurr_vw, glco
	WHERE	glco.oper_currency = glcurr_vw.currency_code

	
	CREATE TABLE #vendor_bal
	(	vendor_code 	varchar(12), 
		pay_to_code		varchar(8),
		amt_balance_home	float,
		amt_balance_oper	float,
		amt_vouch_unposted_home	float,
		amt_vouch_unposted_oper	float, 
		num_vouch		int,
		num_vouch_paid		int,
		num_overdue_pyt	int,
		days_overdue		int,
		days_pay		int,
		avg_days_overdue	int,
		avg_days_pay		int,
		exists_flag		int
	)	
	
	
	INSERT	#vendor_bal
	SELECT vendor_code,
		pay_to_code,
		(SIGN(SUM(SIGN(SIGN(ref_id-1)+1)*(SIGN(amount*( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) * ROUND(ABS(amount*( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) + 0.0000001, @precision_home)))) * ROUND(ABS(SUM(SIGN(SIGN(ref_id-1)+1)*(SIGN(amount*( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) * ROUND(ABS(amount*( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) + 0.0000001, @precision_home)))) + 0.0000001, @precision_home)),
		(SIGN(SUM(SIGN(SIGN(ref_id-1)+1)*(SIGN(amount*( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) * ROUND(ABS(amount*( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) + 0.0000001, @precision_oper)))) * ROUND(ABS(SUM(SIGN(SIGN(ref_id-1)+1)*(SIGN(amount*( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) * ROUND(ABS(amount*( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) + 0.0000001, @precision_oper)))) + 0.0000001, @precision_oper)),
		0.0, 0.0, 
		SUM(SIGN(SIGN(4091.5 - trx_type)+1)*SIGN(SIGN(1.5-ref_id)+1)),
		SUM(SIGN(SIGN(4091.5 - trx_type)+1)*SIGN(paid_flag)*SIGN(SIGN(1.5-ref_id)+1)),
		SUM(SIGN(SIGN(4091.5 - trx_type)+1)*SIGN(paid_flag)*SIGN(SIGN(1.5-ref_id)+1)
			* SIGN(SIGN(date_paid - date_due+0.5)+1)),
		SUM(SIGN(SIGN(4091.5 - trx_type)+1)*(date_paid-date_due)*SIGN(paid_flag)
			* SIGN(SIGN(date_paid-date_due+0.5)+1)),
		SUM(SIGN(SIGN(4091.5 - trx_type)+1)*(date_paid-date_doc)*SIGN(paid_flag)
			* SIGN(SIGN(date_paid-date_doc+0.5)+1)),	
		0, 0, 0
	FROM	aptrxage
	GROUP BY vendor_code, pay_to_code 
		
	CREATE CLUSTERED INDEX #cust_bal_ind ON #vendor_bal(vendor_code)
	
	
	UPDATE	#vendor_bal
	SET	avg_days_pay = (SIGN(days_pay/num_vouch_paid) * ROUND(ABS(days_pay/num_vouch_paid) + 0.0000001, 0)),
		avg_days_overdue = (SIGN(days_overdue/num_vouch_paid) * ROUND(ABS(days_overdue/num_vouch_paid) + 0.0000001, 0))
	WHERE	num_vouch_paid > 0
	
	IF EXISTS (	SELECT vendor_code
			FROM	apinpchg
			WHERE	trx_type <= 4091
			AND	hold_flag = 0 )
	BEGIN
		
		CREATE TABLE #unposted_trx
		(
			vendor_code		varchar(12),
			pay_to_code		varchar(8),
			amt_vouch_unposted_home	float,
			amt_vouch_unposted_oper	float,
			exists_flag		smallint
		)
		
		INSERT #unposted_trx
		SELECT vendor_code,
			pay_to_code,
			SUM(SIGN(SIGN(4091.5-trx_type)+1)*SIGN(1-hold_flag)*
				(SIGN(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) * ROUND(ABS(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) + 0.0000001, @precision_home))),
			SUM(SIGN(SIGN(4091.5-trx_type)+1)*SIGN(1-hold_flag)*
				(SIGN(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) * ROUND(ABS(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) + 0.0000001, @precision_oper))),
			0
		FROM	apinpchg
		GROUP BY vendor_code, pay_to_code
		
		
		UPDATE	#unposted_trx
		SET	exists_flag = 1
		FROM	#vendor_bal
		WHERE	#vendor_bal.vendor_code = #unposted_trx.vendor_code
		AND		#vendor_bal.pay_to_code = #unposted_trx.pay_to_code
		
		
		INSERT #vendor_bal
		SELECT	vendor_code, pay_to_code, 0.0, 0.0, 
			amt_vouch_unposted_home, amt_vouch_unposted_oper,
			0, 0, 0, 0, 0, 0, 0, 0
		FROM	#unposted_trx
		WHERE	#unposted_trx.exists_flag = 0
		
		
		UPDATE	#vendor_bal
		SET	amt_vouch_unposted_home = #unposted_trx.amt_vouch_unposted_home,
			amt_vouch_unposted_oper = #unposted_trx.amt_vouch_unposted_oper
		FROM	#unposted_trx
		WHERE	#vendor_bal.vendor_code = #unposted_trx.vendor_code
		AND		#vendor_bal.pay_to_code = #unposted_trx.pay_to_code
		AND	#unposted_trx.exists_flag = 1
		
		DROP TABLE #unposted_trx
		
	END
		
			
	UPDATE	#vendor_bal
	SET	exists_flag = 1
	FROM	apactpto
	WHERE	apactpto.vendor_code = #vendor_bal.vendor_code
	AND		apactpto.pay_to_code = #vendor_bal.pay_to_code
										 
	
	UPDATE	apactpto
	SET	last_trx_time = 0

	
	UPDATE	apactpto
	SET	amt_balance 		= bal.amt_balance_home,
		amt_vouch_unposted 	= bal.amt_vouch_unposted_home,
		amt_balance_oper 	= bal.amt_balance_oper,
		amt_vouch_unposted_oper 	= bal.amt_vouch_unposted_oper,
		num_vouch 		= bal.num_vouch,
		num_vouch_paid 		= bal.num_vouch_paid,
		num_overdue_pyt 	= bal.num_overdue_pyt,
		avg_days_overdue 	= bal.avg_days_overdue,
		avg_days_pay 		= bal.avg_days_pay,
		last_trx_time		 = 1
	FROM	#vendor_bal	bal
	WHERE	bal.vendor_code = apactpto.vendor_code
	AND	bal.pay_to_code = apactpto.pay_to_code
	AND	exists_flag = 1

	
	INSERT	apactpto (	
 		vendor_code,		pay_to_code,	date_last_vouch,		date_last_dm,
		date_last_adj,			date_last_pyt,			date_last_void,
		amt_last_vouch,			amt_last_dm,			amt_last_adj,
		amt_last_pyt,			amt_last_void,			amt_age_bracket1,
		amt_age_bracket2,		amt_age_bracket3,		amt_age_bracket4,
		amt_age_bracket5,		amt_age_bracket6,		amt_on_order,
		amt_vouch_unposted,		last_vouch_doc,			last_dm_doc,
		last_adj_doc,			last_pyt_doc,			last_pyt_acct,
		last_void_doc,			last_void_acct,			high_amt_ap,
		high_amt_vouch,			high_date_ap,			high_date_vouch,
		num_vouch,				num_vouch_paid,			num_overdue_pyt,
		avg_days_pay,			avg_days_overdue,		last_trx_time,
		amt_balance,			last_vouch_cur,			last_dm_cur,
		last_adj_cur,			last_pyt_cur,			last_void_cur,
		amt_age_bracket1_oper,	amt_age_bracket2_oper,	amt_age_bracket3_oper,
		amt_age_bracket4_oper,	amt_age_bracket5_oper,	amt_age_bracket6_oper,
		amt_balance_oper,		amt_on_order_oper,		amt_vouch_unposted_oper,
		high_amt_ap_oper
		) 
	SELECT	
		vendor_code, 	 pay_to_code,		0, 						0,
		0, 						0, 						0,
		0.0, 					0.0, 					0.0,
		0.0, 					0.0, 					0.0,
		0.0, 					0.0, 					0.0,
		0.0, 					0.0, 					0.0,
		amt_vouch_unposted_home,' ', 					' ',
		' ', 					' ', 					' ',
		' ', 					' ', 					0.0,
		0.0, 					0, 						0,
		num_vouch,				num_vouch_paid,			num_overdue_pyt,
		avg_days_pay,			avg_days_overdue,		1,
		amt_balance_home,		' ', 					' ',
		' ', 					' ', 					' ',
		0.0, 					0.0, 					0.0,
		0.0, 					0.0, 					0.0,
		amt_balance_oper, 	 	0.0, 					amt_vouch_unposted_oper,
		0.0
	FROM	#vendor_bal
	WHERE	exists_flag = 0

	
	DELETE	apactpto
	WHERE	last_trx_time = 0	

	DROP TABLE #vendor_bal

END


/**/                                              
GO
GRANT EXECUTE ON  [dbo].[apuapto_sp] TO [public]
GO
