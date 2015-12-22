SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARUPDateCustSummary_SP] 
					 
AS


DECLARE	@precision_oper	smallint,
		@precision_home	smallint

	
	SELECT	@precision_home = curr_precision
	FROM	glcurr_vw, glco
	WHERE	glco.home_currency = glcurr_vw.currency_code

	SELECT	@precision_oper = curr_precision
	FROM	glcurr_vw, glco
	WHERE	glco.oper_currency = glcurr_vw.currency_code

	
	DELETE arsumcus

	
	

	INSERT	arsumcus (	customer_code, 	date_from, 		date_thru,
				num_inv, 		num_inv_paid, 	num_cm,
				num_adj, 		num_wr_off, 		num_pyt,
				num_overdue_pyt, 	num_nsf, 		num_fin_chg,
				num_late_chg, 	amt_inv, 		amt_cm,
				amt_adj, 		amt_wr_off, 		amt_pyt,
				amt_nsf, 		amt_fin_chg, 		amt_late_chg,
				amt_profit, 		prc_profit, 		amt_comm,
				amt_disc_given,	amt_disc_taken,	amt_disc_lost,
				amt_freight,		amt_tax,		avg_days_pay,
				avg_days_overdue,	last_trx_time,	amt_inv_oper,
				amt_cm_oper,		amt_adj_oper,		amt_wr_off_oper,
				amt_pyt_oper,		amt_nsf_oper,		amt_fin_chg_oper,
				amt_late_chg_oper,	amt_disc_g_oper,	amt_disc_t_oper,	
				amt_freight_oper,	amt_tax_oper		
			)
	SELECT		age.customer_code,		prd.period_start_date,		prd.period_end_date,
			0,				0,					0,
			0,				
							SUM((( 1-ABS(SIGN(age.trx_type - 2141))) + ( 1-ABS(SIGN(age.trx_type - 2151))) 
							- ( 1-ABS(SIGN(age.trx_type - 2142)))) 
							* SIGN(1 + SIGN(age.ref_id)) * ABS(SIGN(age.ref_id) )), 
												SUM((( 1-ABS(SIGN(age.trx_type - 2032))) + ( 1-ABS(SIGN(age.trx_type - 2111))) 
												- ( 1-ABS(SIGN(age.trx_type - 2112))) - ( 1-ABS(SIGN(age.trx_type - 2113))) - ( 1-ABS(SIGN(age.trx_type - 2121)))) 
												* SIGN(1 + SIGN(age.ref_id)) * ABS(SIGN(age.ref_id) )), 
			SUM(SIGN(SIGN(2031.5 - age.trx_type)+1)*SIGN(age.paid_flag)*SIGN(SIGN(1.5-age.ref_id)+1)
			* SIGN(SIGN(age.date_paid - age.date_due+0.5)+1)), 
							0,					0,
			0,				0.0,					0.0,	
			0.0,				ROUND( SUM((( 1-ABS(SIGN(age.trx_type - 2141)))+
							(1-ABS(SIGN(age.trx_type-2151))) +
							(1-ABS(SIGN(age.trx_type-2142)))) * 
							ROUND( -age.amount * ( SIGN(1 + SIGN(age.rate_home))*(age.rate_home) + (SIGN(ABS(SIGN(ROUND(age.rate_home,6))))/(age.rate_home + SIGN(1 - ABS(SIGN(ROUND(age.rate_home,6)))))) * SIGN(SIGN(age.rate_home) - 1) ), @precision_home )), @precision_home), 
												-SUM((( 1-ABS(SIGN(age.trx_type - 2032))) + ( 1-ABS(SIGN(age.trx_type - 2111))) 
												+ ( 1-ABS(SIGN(age.trx_type - 2112))) + ( 1-ABS(SIGN(age.trx_type - 2113))) + ( 1-ABS(SIGN(age.trx_type - 2121)))) 
												* SIGN(1 + SIGN(age.ref_id)) * ABS(SIGN(age.ref_id)) 
												* ROUND( age.amount * ( SIGN(1 + SIGN(age.rate_home))*(age.rate_home) + (SIGN(ABS(SIGN(ROUND(age.rate_home,6))))/(age.rate_home + SIGN(1 - ABS(SIGN(ROUND(age.rate_home,6)))))) * SIGN(SIGN(age.rate_home) - 1) ), @precision_home )), 
			ROUND( SUM((( 1-ABS(SIGN(age.trx_type - 2121)))) * 
			ROUND( -age.amount * ( SIGN(1 + SIGN(age.rate_home))*(age.rate_home) + (SIGN(ABS(SIGN(ROUND(age.rate_home,6))))/(age.rate_home + SIGN(1 - ABS(SIGN(ROUND(age.rate_home,6)))))) * SIGN(SIGN(age.rate_home) - 1) ), @precision_home ) * SIGN(age.ref_id )), @precision_home), 
							0.0,					0.0,
			0.0,				0.0,					0.0,
			0.0,				ROUND( SUM((( 1-ABS(SIGN(age.trx_type - 2131))) -
							(1-ABS(SIGN(age.trx_type-2132)))) * 
							ROUND( age.amount * ( SIGN(1 + SIGN(age.rate_home))*(age.rate_home) + (SIGN(ABS(SIGN(ROUND(age.rate_home,6))))/(age.rate_home + SIGN(1 - ABS(SIGN(ROUND(age.rate_home,6)))))) * SIGN(SIGN(age.rate_home) - 1) ), @precision_home )), @precision_home), 
												0.0,
			0.0,				0.0,					0,
			0,				0,					0.0,
			0.0,				0.0,					ROUND( SUM((( 1-ABS(SIGN(age.trx_type - 2141)))+
												(1-ABS(SIGN(age.trx_type-2151))) +
												(1-ABS(SIGN(age.trx_type-2142)))) * 
												ROUND( -age.amount * ( SIGN(1 + SIGN(age.rate_oper))*(age.rate_oper) + (SIGN(ABS(SIGN(ROUND(age.rate_oper,6))))/(age.rate_oper + SIGN(1 - ABS(SIGN(ROUND(age.rate_oper,6)))))) * SIGN(SIGN(age.rate_oper) - 1) ), @precision_oper )), @precision_oper), 
			-SUM((( 1-ABS(SIGN(age.trx_type - 2032))) + ( 1-ABS(SIGN(age.trx_type - 2111))) 
			+ ( 1-ABS(SIGN(age.trx_type - 2112))) + ( 1-ABS(SIGN(age.trx_type - 2113))) + ( 1-ABS(SIGN(age.trx_type - 2121)))) 
			* SIGN(1 + SIGN(age.ref_id)) * ABS(SIGN(age.ref_id)) 
			* ROUND( age.amount * ( SIGN(1 + SIGN(age.rate_oper))*(age.rate_oper) + (SIGN(ABS(SIGN(ROUND(age.rate_oper,6))))/(age.rate_oper + SIGN(1 - ABS(SIGN(ROUND(age.rate_oper,6)))))) * SIGN(SIGN(age.rate_oper) - 1) ), @precision_oper )), 
							ROUND( SUM((( 1-ABS(SIGN(age.trx_type - 2121)))) * 
							ROUND( -age.amount * ( SIGN(1 + SIGN(age.rate_oper))*(age.rate_oper) + (SIGN(ABS(SIGN(ROUND(age.rate_oper,6))))/(age.rate_oper + SIGN(1 - ABS(SIGN(ROUND(age.rate_oper,6)))))) * SIGN(SIGN(age.rate_oper) - 1) ), @precision_oper ) * SIGN(age.ref_id )), @precision_oper), 
												0.0,				
			0.0,				0.0,					ROUND( SUM((( 1-ABS(SIGN(age.trx_type - 2131))) +
												(1-ABS(SIGN(age.trx_type-2132)))) * 
												
												ROUND( -age.amount * ( SIGN(1 + SIGN(age.rate_oper))*(age.rate_oper) + (SIGN(ABS(SIGN(ROUND(age.rate_oper,6))))/(age.rate_oper + SIGN(1 - ABS(SIGN(ROUND(age.rate_oper,6)))))) * SIGN(SIGN(age.rate_oper) - 1) ), @precision_oper )), @precision_oper), 
			0.0,				0.0
	FROM	artrxage age, glprd prd
	WHERE	age.date_applied between prd.period_start_date and prd.period_end_date
	GROUP BY age.customer_code, prd.period_start_date, prd.period_end_date

	
	CREATE TABLE #artrx_tot
	(	customer_code 	varchar(8), 
		date_from		int,
		date_thru		int,
		amt_inv		float,
		amt_cm			float,
		amt_adj		float,
		amt_fin_chg		float,
		amt_late_chg		float,
		amt_inv_oper		float,	
		amt_cm_oper		float,
		amt_adj_oper		float,
		amt_fin_chg_oper	float,
		amt_late_chg_oper	float,
		num_inv		int,
		num_inv_paid		int,
		num_cm			int,
		num_adj		int,
		num_nsf		int,
		num_fin_chg		int,
		num_late_chg		int,
		amt_tax		float,
		amt_tax_oper		float,
		amt_freight		float,
		amt_freight_oper	float,
		amt_disc_given	float,
		amt_disc_g_oper	float,
		days_pay		int,
		days_overdue		int,
		avg_days_pay		int,	
		avg_days_overdue	int,	
		exists_flag		smallint
	)	

	
	INSERT	#artrx_tot		
	SELECT	a.customer_code,
		prd.period_start_date,
		prd.period_end_date,
		ROUND( SUM((( 1-ABS(SIGN(a.trx_type-2021))) + ( 1-ABS(SIGN(a.trx_type-2031 )))) * 
			ROUND( a.amt_net * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) ) * (1-void_flag), @precision_home )), @precision_home), 
		ROUND( SUM((( 1-ABS(SIGN(a.trx_type - 2032)))) * 
			ROUND(( a.amt_net * ( 1 - SIGN( ABS( a.recurring_flag - 1 )))
			+ a.amt_tax * ( 1 - SIGN( ABS( a.recurring_flag - 2 )))	
			+ a.amt_freight * ( 1 - SIGN( ABS( a.recurring_flag - 3 )))
		 	+ ( a.amt_tax + a.amt_freight ) * ( 1 - SIGN( ABS( a.recurring_flag - 4 )))) * 
		 		( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) ), @precision_home )), @precision_home), 
		ROUND( SUM((( 1-ABS(SIGN(a.trx_type - 2051)))) * 
			ROUND( a.amt_net * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) ), @precision_home )), @precision_home), 
		ROUND( SUM((( 1-ABS(SIGN(a.trx_type - 2061)))) * 
			ROUND( a.amt_net * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) ), @precision_home )), @precision_home), 
		ROUND( SUM((( 1-ABS(SIGN(a.trx_type - 2071)))) * 
			ROUND( a.amt_net * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) ), @precision_home )), @precision_home), 
		ROUND( SUM((( 1-ABS(SIGN(a.trx_type-2021))) + ( 1-ABS(SIGN(a.trx_type-2031 )))) * 
			ROUND( a.amt_net * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) ) * (1-void_flag), @precision_oper )), @precision_oper), 
		ROUND( SUM((( 1-ABS(SIGN(a.trx_type - 2032)))) * 
			ROUND(( a.amt_net * ( 1 - SIGN( ABS( a.recurring_flag - 1 )))
			+ a.amt_tax * ( 1 - SIGN( ABS( a.recurring_flag - 2 )))	
			+ a.amt_freight * ( 1 - SIGN( ABS( a.recurring_flag - 3 )))
		 	+ ( a.amt_tax + a.amt_freight ) * ( 1 - SIGN( ABS( a.recurring_flag - 4 )))) * 
		 		( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) ), @precision_oper )), @precision_oper), 
		ROUND( SUM((( 1-ABS(SIGN(a.trx_type - 2051)))) * 
			ROUND( a.amt_net * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) ), @precision_oper )), @precision_oper), 
		ROUND( SUM((( 1-ABS(SIGN(a.trx_type - 2061 )))) * 
			ROUND( a.amt_net * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) ), @precision_oper )), @precision_oper), 
		ROUND( SUM((( 1-ABS(SIGN(a.trx_type - 2071)))) * 
			ROUND( a.amt_net * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) ), @precision_oper )), @precision_oper), 
		SUM(((1-ABS(SIGN(a.trx_type-2021))) + (1-ABS(SIGN(a.trx_type-2031)))) * (1-void_flag)), 
		SUM(((1-ABS(SIGN(a.trx_type-2021))) + (1-ABS(SIGN(a.trx_type-2031)))) * a.paid_flag ), 
		SUM((1-ABS(SIGN(a.trx_type-2032)))), 
		SUM((1-ABS(SIGN(a.trx_type-2051)))), 
		SUM(1-ABS(SIGN(a.trx_type-2121))), 
		SUM((1-ABS(SIGN(a.trx_type-2061)))), 
		SUM((1-ABS(SIGN(a.trx_type-2071)))), 
		ROUND( SUM((( 1-ABS(SIGN(a.trx_type - 2021))) + ( 1-ABS(SIGN(a.trx_type-2031 )))) * 
			ROUND( a.amt_tax * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) ), @precision_home )), @precision_home), 
		ROUND( SUM((( 1-ABS(SIGN(a.trx_type - 2021))) + ( 1-ABS(SIGN(a.trx_type-2031 )))) * 
			ROUND( a.amt_tax * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) ), @precision_oper )), @precision_oper), 
		ROUND( SUM((( 1-ABS(SIGN(a.trx_type - 2021))) + ( 1-ABS(SIGN(a.trx_type-2031 )))) * 
			ROUND( a.amt_freight * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) ), @precision_home )), @precision_home), 
		ROUND( SUM((( 1-ABS(SIGN(a.trx_type - 2021))) + ( 1-ABS(SIGN(a.trx_type-2031 )))) * 
			ROUND( a.amt_freight * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) ), @precision_oper )), @precision_oper), 
		ROUND( SUM((( 1-ABS(SIGN(a.trx_type - 2021))) + ( 1-ABS(SIGN(a.trx_type-2031 )))) * 
			ROUND( a.amt_discount * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) ), @precision_home )), @precision_home), 
		ROUND( SUM((( 1-ABS(SIGN(a.trx_type - 2021))) + ( 1-ABS(SIGN(a.trx_type-2031 )))) * 
			ROUND( a.amt_discount * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) ), @precision_oper )), @precision_oper), 
		SUM(((1-ABS(SIGN(trx_type-2021))) + ( 1-ABS(SIGN(trx_type-2031 )))) * 
			SIGN( 1 + SIGN(a.date_paid - a.date_doc)) * (a.date_paid - a.date_doc)), 
		SUM(((1-ABS(SIGN(trx_type-2021))) + ( 1-ABS(SIGN(trx_type-2031 )))) 
			* SIGN( 1 + SIGN(a.date_paid - a.date_due)) * (a.date_paid - a.date_due)), 
		0,0,0
	FROM	artrx a, glprd prd
	WHERE	a.date_applied between prd.period_start_date and prd.period_end_date
	GROUP BY a.customer_code, prd.period_start_date, prd.period_end_date

	
	UPDATE	#artrx_tot
	SET	avg_days_pay = ROUND(days_pay/num_inv_paid, 0),
		avg_days_overdue = ROUND(days_overdue/num_inv_paid, 0)
	WHERE	num_inv_paid > 0

				
	
	UPDATE	#artrx_tot
	SET	exists_flag = 1
	FROM	arsumcus
	WHERE	arsumcus.customer_code = #artrx_tot.customer_code
	AND	arsumcus.date_thru = #artrx_tot.date_thru


	UPDATE	arsumcus
	SET	
		num_inv = a.num_inv,
		num_inv_paid = a.num_inv_paid,
		num_cm = a.num_cm,
		num_adj = a.num_adj,
		num_fin_chg = a.num_fin_chg,
		num_late_chg = a.num_late_chg,
		amt_inv = a.amt_inv,
		amt_cm = a.amt_cm,
		amt_adj = a.amt_adj,
		amt_fin_chg = a.amt_fin_chg,
		amt_late_chg = a.amt_late_chg,
		amt_disc_given = a.amt_disc_given,
		amt_freight = a.amt_freight,
		amt_tax = a.amt_tax,
		amt_inv_oper = a.amt_inv_oper,
		amt_cm_oper = a.amt_cm_oper,
		amt_adj_oper = a.amt_adj_oper,
		amt_fin_chg_oper = a.amt_fin_chg_oper,
		amt_late_chg_oper = a.amt_late_chg_oper,
		amt_disc_g_oper = a.amt_disc_g_oper,
		amt_freight_oper = a.amt_freight_oper,
		amt_tax_oper = a.amt_tax_oper,
		avg_days_pay = a.avg_days_pay,
		avg_days_overdue = a.avg_days_overdue
	FROM	#artrx_tot a
	WHERE	arsumcus.customer_code = a.customer_code
	AND	arsumcus.date_from = a.date_from
	AND	arsumcus.date_thru = a.date_thru


	INSERT	arsumcus (	customer_code, 	date_from, 		date_thru,
				num_inv, 		num_inv_paid, 	num_cm,
				num_adj, 		num_wr_off, 		num_pyt,
				num_overdue_pyt, 	num_nsf, 		num_fin_chg,
				num_late_chg, 	amt_inv, 		amt_cm,
				amt_adj, 		amt_wr_off, 		amt_pyt,
				amt_nsf, 		amt_fin_chg, 		amt_late_chg,
				amt_profit, 		prc_profit, 		amt_comm,
				amt_disc_given,	amt_disc_taken,	amt_disc_lost,
				amt_freight,		amt_tax,		avg_days_pay,
				avg_days_overdue,	last_trx_time,	amt_inv_oper,
				amt_cm_oper,		amt_adj_oper,		amt_wr_off_oper,
				amt_pyt_oper,		amt_nsf_oper,		amt_fin_chg_oper,
				amt_late_chg_oper,	amt_disc_g_oper,	amt_disc_t_oper,	
				amt_freight_oper,	amt_tax_oper
			)
	SELECT			
				customer_code, 	date_from, 		date_thru,
				num_inv, 		num_inv_paid, 	num_cm,
				num_adj, 		0, 			0,
				0, 			0, 			num_fin_chg,
				num_late_chg, 	amt_inv, 		amt_cm,
				amt_adj, 		0.0, 			0.0,
				0.0, 			amt_fin_chg, 		amt_late_chg,
				0.0, 			0.0, 			0.0,
				amt_disc_given,	0.0,			0.0,
				amt_freight,		amt_tax,		avg_days_pay,
				avg_days_overdue,	0,			amt_inv_oper,
				amt_cm_oper,		amt_adj_oper,		0.0,
				0.0,			0.0,			amt_fin_chg_oper,
				amt_late_chg_oper,	amt_disc_g_oper,	0.0,	
				amt_freight_oper,	amt_tax_oper
	FROM	#artrx_tot
	WHERE	exists_flag = 0
	
	DROP TABLE #artrx_tot




GO
GRANT EXECUTE ON  [dbo].[ARUPDateCustSummary_SP] TO [public]
GO
