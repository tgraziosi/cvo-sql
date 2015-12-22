SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AR\PROCS\arupdsts.SPv - e7.2.2 : 1.14
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                





























CREATE PROC [dbo].[ARUPDateShipToSummary_SP] 
					 
AS

DECLARE	@precision_oper	smallint,
		@precision_home	smallint

	

	SELECT	@precision_home = curr_precision
	FROM	glcurr_vw, glco
	WHERE	glco.home_currency = glcurr_vw.currency_code

	SELECT	@precision_oper = curr_precision
	FROM	glcurr_vw, glco
	WHERE	glco.oper_currency = glcurr_vw.currency_code


	
	CREATE TABLE #shipto_tot
	(	customer_code 	varchar(8), 
		ship_to_code		varchar(8),
		date_from		int,
		date_thru		int,
		amt_inv		float,
		amt_cm			float,
		amt_adj		float,
		amt_wr_off		float,
		amt_pyt		float,
		amt_nsf		float,
		amt_fin_chg		float,
		amt_late_chg		float,
		amt_disc_taken	float,
		amt_inv_oper		float,	
		amt_cm_oper		float,
		amt_adj_oper		float,
		amt_wr_off_oper	float,
		amt_pyt_oper		float,
		amt_nsf_oper		float,
		amt_fin_chg_oper	float,
		amt_late_chg_oper	float,
		amt_disc_t_oper	float,
		num_inv		int,
		num_inv_paid		int,
		num_cm			int,
		num_adj		int,
		num_wr_off		int,
		num_pyt		int,
		num_overdue_pyt	int,
		num_nsf		int,
		num_fin_chg		int,
		num_late_chg		int,
		days_pay		int,
		days_overdue		int,
		avg_days_pay		int,
		avg_days_overdue	int,
		exists_flag		int,
		amt_tax		float,
		amt_tax_oper		float,
		amt_freight		float,
		amt_freight_oper	float,
		amt_disc_given	float,
		amt_disc_g_oper	float
	)	

	
	INSERT	#shipto_tot		
	SELECT	inv.customer_code,
		inv.ship_to_code,
		prd.period_start_date,
		prd.period_end_date,
		0.0, 0.0, 0.0,
		ROUND( SUM((( 1-ABS(SIGN(age.trx_type - 2141)))+
			(1-ABS(SIGN(age.trx_type-2151))) +
			(1-ABS(SIGN(age.trx_type-2142)))) * 
			ROUND( -age.amount * ( SIGN(1 + SIGN(age.rate_home))*(age.rate_home) + (SIGN(ABS(SIGN(ROUND(age.rate_home,6))))/(age.rate_home + SIGN(1 - ABS(SIGN(ROUND(age.rate_home,6)))))) * SIGN(SIGN(age.rate_home) - 1) ), @precision_home )), @precision_home), 
		0.0,
		ROUND( SUM((( 1-ABS(SIGN(age.trx_type - 2121)))) * 
			ROUND( -age.amount * ( SIGN(1 + SIGN(age.rate_home))*(age.rate_home) + (SIGN(ABS(SIGN(ROUND(age.rate_home,6))))/(age.rate_home + SIGN(1 - ABS(SIGN(ROUND(age.rate_home,6)))))) * SIGN(SIGN(age.rate_home) - 1) ), @precision_home )), @precision_home), 
		0.0, 0.0,
		ROUND( SUM((( 1-ABS(SIGN(age.trx_type - 2131))) +
			(1-ABS(SIGN(age.trx_type-2132)))) * 
			ROUND( -age.amount * ( SIGN(1 + SIGN(age.rate_home))*(age.rate_home) + (SIGN(ABS(SIGN(ROUND(age.rate_home,6))))/(age.rate_home + SIGN(1 - ABS(SIGN(ROUND(age.rate_home,6)))))) * SIGN(SIGN(age.rate_home) - 1) ), @precision_home )), @precision_home), 
		0.0, 0.0, 0.0,
		ROUND( SUM((( 1-ABS(SIGN(age.trx_type - 2141)))+
			(1-ABS(SIGN(age.trx_type-2151))) +
			(1-ABS(SIGN(age.trx_type-2142)))) * 
			ROUND( -age.amount * ( SIGN(1 + SIGN(age.rate_oper))*(age.rate_oper) + (SIGN(ABS(SIGN(ROUND(age.rate_oper,6))))/(age.rate_oper + SIGN(1 - ABS(SIGN(ROUND(age.rate_oper,6)))))) * SIGN(SIGN(age.rate_oper) - 1) ), @precision_oper )), @precision_oper), 
		0.0,
		ROUND( SUM((( 1-ABS(SIGN(age.trx_type - 2121)))) * 
			ROUND( -age.amount * ( SIGN(1 + SIGN(age.rate_oper))*(age.rate_oper) + (SIGN(ABS(SIGN(ROUND(age.rate_oper,6))))/(age.rate_oper + SIGN(1 - ABS(SIGN(ROUND(age.rate_oper,6)))))) * SIGN(SIGN(age.rate_oper) - 1) ), @precision_oper )), @precision_oper), 
		0.0, 0.0,
		ROUND( SUM((( 1-ABS(SIGN(age.trx_type - 2131))) +
			(1-ABS(SIGN(age.trx_type-2132)))) * 
			ROUND( -age.amount * ( SIGN(1 + SIGN(age.rate_oper))*(age.rate_oper) + (SIGN(ABS(SIGN(ROUND(age.rate_oper,6))))/(age.rate_oper + SIGN(1 - ABS(SIGN(ROUND(age.rate_oper,6)))))) * SIGN(SIGN(age.rate_oper) - 1) ), @precision_oper )), @precision_oper), 
		0, 0, 0, 0, 
		0, 
		0, 
		SUM(SIGN(SIGN(2031.5 - age.trx_type)+1)*SIGN(age.paid_flag)*SIGN(SIGN(1.5-age.ref_id)+1)
			* SIGN(SIGN(age.date_paid - age.date_due+0.5)+1)), 
		SUM((1-ABS(SIGN(age.trx_type-2121)))), 
		0, 0, 
		0, 0, 0, 0, 0, 
		0.0, 0.0, 0.0, 0.0, 0.0, 0.0
	FROM	artrxage age, artrx inv, glprd prd
	WHERE	age.date_applied between prd.period_start_date and prd.period_end_date
	AND	age.sub_apply_num = inv.doc_ctrl_num
	AND	age.sub_apply_type = inv.trx_type
	AND	inv.trx_type <= 2031
	AND	( LTRIM(inv.customer_code) IS NOT NULL AND LTRIM(inv.customer_code) != " " )
	AND	( LTRIM(inv.ship_to_code) IS NOT NULL AND LTRIM(inv.ship_to_code) != " " )
	GROUP BY inv.customer_code, inv.ship_to_code, prd.period_start_date, prd.period_end_date

	
	
	CREATE TABLE #artrx_tot
	(	customer_code 	varchar(8), 
		ship_to_code 		varchar(8), 
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
		num_fin_chg		int,
		num_late_chg		int,
		amt_tax		float,
		amt_tax_oper		float,
		amt_freight		float,
		amt_freight_oper	float,
		amt_disc_given	float,
		amt_disc_g_oper	float,
		days_pay		int,
		days_overdue		int
	)	
	

	INSERT	#artrx_tot		
	SELECT	a.customer_code,
		a.ship_to_code,
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
			* SIGN( 1 + SIGN(a.date_paid - a.date_due)) * (a.date_paid - a.date_due)) 
	FROM	artrx a, glprd prd
	WHERE	a.date_applied between prd.period_start_date and prd.period_end_date
	AND	( LTRIM(a.customer_code) IS NOT NULL AND LTRIM(a.customer_code) != " " )
	AND	( LTRIM(a.ship_to_code) IS NOT NULL AND LTRIM(a.ship_to_code) != " " )
	GROUP BY a.customer_code, a.ship_to_code, prd.period_start_date, prd.period_end_date


	UPDATE	#shipto_tot
	SET	#shipto_tot.amt_inv = a.amt_inv,
		#shipto_tot.amt_cm = a.amt_cm,
		#shipto_tot.amt_adj = a.amt_adj,
		#shipto_tot.amt_fin_chg = a.amt_fin_chg,
		#shipto_tot.amt_late_chg = a.amt_late_chg,
		#shipto_tot.amt_inv_oper = a.amt_inv_oper,
		#shipto_tot.amt_cm_oper = a.amt_cm_oper,
		#shipto_tot.amt_adj_oper = a.amt_adj_oper,
		#shipto_tot.amt_fin_chg_oper = a.amt_fin_chg_oper,
		#shipto_tot.amt_late_chg_oper = a.amt_late_chg_oper,
		#shipto_tot.num_inv = a.num_inv,
		#shipto_tot.num_inv_paid = a.num_inv_paid,
		#shipto_tot.num_cm = a.num_cm,
		#shipto_tot.num_adj = a.num_adj,
		#shipto_tot.num_fin_chg = a.num_fin_chg,
		#shipto_tot.num_late_chg = a.num_late_chg,
		#shipto_tot.amt_tax = a.amt_tax,
		#shipto_tot.amt_tax_oper = a.amt_tax_oper,
		#shipto_tot.amt_freight = a.amt_freight,
		#shipto_tot.amt_freight_oper = a.amt_freight_oper,
		#shipto_tot.amt_disc_given = a.amt_disc_given,
		#shipto_tot.amt_disc_g_oper = a.amt_disc_g_oper,
		#shipto_tot.days_pay = a.days_pay,
		#shipto_tot.days_overdue = a.days_overdue
	FROM	#artrx_tot a
	WHERE	#shipto_tot.customer_code = a.customer_code
	AND	#shipto_tot.ship_to_code = a.ship_to_code
	AND	a.date_from = #shipto_tot.date_from
	AND	a.date_thru = #shipto_tot.date_thru


	DROP TABLE #artrx_tot


	
	CREATE TABLE #amt_pyt_tot
	(	customer_code 	varchar(8), 
		ship_to_code 		varchar(8), 
		date_from		int,
		date_thru		int,
		amt_pyt		float,
		amt_pyt_oper		float
	)	
	
			
	INSERT	#amt_pyt_tot
	SELECT	age.customer_code, 
		trx.ship_to_code,
		s.date_from,
		s.date_thru,
		sum( ROUND( pdt.inv_amt_applied * ( SIGN(1 + SIGN(age.rate_home))*(age.rate_home) + (SIGN(ABS(SIGN(ROUND(age.rate_home,6))))/(age.rate_home + SIGN(1 - ABS(SIGN(ROUND(age.rate_home,6)))))) * SIGN(SIGN(age.rate_home) - 1) ), @precision_home ) + pdt.gain_home ), 
		sum( ROUND( pdt.inv_amt_applied * ( SIGN(1 + SIGN(age.rate_oper))*(age.rate_oper) + (SIGN(ABS(SIGN(ROUND(age.rate_oper,6))))/(age.rate_oper + SIGN(1 - ABS(SIGN(ROUND(age.rate_oper,6)))))) * SIGN(SIGN(age.rate_oper) - 1) ), @precision_oper ) + pdt.gain_oper ) 
	FROM	artrxage age, artrxpdt pdt, artrx trx, #shipto_tot s
	WHERE	age.sub_apply_num = trx.doc_ctrl_num
	AND	age.sub_apply_type = trx.trx_type
	AND	trx.ship_to_code = s.ship_to_code
	AND	trx.customer_code = s.customer_code
	AND	pdt.doc_ctrl_num = age.doc_ctrl_num
	AND	pdt.payer_cust_code = age.payer_cust_code
	AND	pdt.sequence_id = age.ref_id
	AND	pdt.date_applied between s.date_from and s.date_thru 
	AND	( LTRIM(age.customer_code) IS NOT NULL AND LTRIM(age.customer_code) != " " )
	AND	( LTRIM(trx.ship_to_code) IS NOT NULL AND LTRIM(trx.ship_to_code) != " " )
	AND	pdt.trx_type = 2111
	AND	age.trx_type IN (2111, 2032)	
	AND	pdt.void_flag = 0	
	GROUP BY age.customer_code, trx.ship_to_code, s.date_from, s.date_thru

	
	UPDATE	#shipto_tot
	SET	#shipto_tot.amt_pyt = a.amt_pyt,
		#shipto_tot.amt_pyt_oper = a.amt_pyt_oper
	FROM	#amt_pyt_tot a
	WHERE	#shipto_tot.customer_code = a.customer_code
	AND	#shipto_tot.ship_to_code = a.ship_to_code
	AND	a.date_from = #shipto_tot.date_from
	AND	a.date_thru = #shipto_tot.date_thru

	DROP TABLE #amt_pyt_tot


	
	
	CREATE TABLE #tran_nums
	(	customer_code 	varchar(8), 
		ship_to_code 		varchar(8), 
		date_from		int,
		date_thru		int,
		num_wr_off		int,
		num_pyt		int
	)	
	
	INSERT	#tran_nums
	SELECT	inv.customer_code, 
		inv.ship_to_code,
		s.date_from,
		s.date_thru,
		SUM(((1-ABS(SIGN(pdt.trx_type-2111))) + (1-ABS(SIGN(pdt.trx_type-2151)))) * 
			SIGN(ABS(pdt.amt_wr_off))), 
		SUM(1-ABS(SIGN(pdt.trx_type-2111))) 
	FROM	artrxpdt pdt, artrx inv, #shipto_tot s
	WHERE	inv.ship_to_code = s.ship_to_code
	AND	inv.customer_code = s.customer_code
	AND	pdt.sub_apply_num = inv.doc_ctrl_num
	AND	pdt.sub_apply_type = inv.trx_type
	AND	pdt.date_applied between s.date_from and s.date_thru 
	AND	inv.trx_type <= 2031
	AND	pdt.void_flag = 0
	GROUP BY inv.customer_code, inv.ship_to_code, s.date_from, s.date_thru

	
	UPDATE	#shipto_tot
	SET	#shipto_tot.num_wr_off = a.num_wr_off,
		#shipto_tot.num_pyt = a.num_pyt
	FROM	#tran_nums a
	WHERE	#shipto_tot.customer_code = a.customer_code
	AND	#shipto_tot.ship_to_code = a.ship_to_code
	AND	a.date_from = #shipto_tot.date_from
	AND	a.date_thru = #shipto_tot.date_thru

	DROP TABLE #tran_nums


	
	UPDATE	#shipto_tot
	SET	avg_days_pay = ROUND(days_pay/num_inv_paid, 0),
		avg_days_overdue = ROUND(days_overdue/num_inv_paid, 0)
	WHERE	num_inv_paid > 0
	


	
	UPDATE	#shipto_tot
	SET	exists_flag = 1
	FROM	arsumshp
	WHERE	arsumshp.customer_code = #shipto_tot.customer_code
	AND	arsumshp.ship_to_code = #shipto_tot.ship_to_code
	AND	arsumshp.date_thru = #shipto_tot.date_thru

	
	UPDATE	arsumshp
	SET	last_trx_time = 0

	
	UPDATE	arsumshp
	SET	date_from = tot.date_from,
		amt_inv = tot.amt_inv,
		amt_cm = tot.amt_cm,
		amt_adj = tot.amt_adj,
		amt_wr_off = tot.amt_wr_off,
		amt_pyt = tot.amt_pyt,
		amt_nsf = tot.amt_nsf,
		amt_fin_chg = tot.amt_fin_chg,
		amt_late_chg = tot.amt_late_chg,
		amt_disc_taken = tot.amt_disc_taken,
		amt_inv_oper = tot.amt_inv_oper,	
		amt_cm_oper = tot.amt_cm_oper,
		amt_adj_oper = tot.amt_adj_oper,
		amt_wr_off_oper = tot.amt_wr_off_oper,
		amt_pyt_oper = tot.amt_pyt_oper,
		amt_nsf_oper = tot.amt_nsf_oper,
		amt_fin_chg_oper = tot.amt_fin_chg_oper,
		amt_late_chg_oper = tot.amt_late_chg_oper,
		amt_disc_t_oper = tot.amt_disc_t_oper,
		num_inv = tot.num_inv,
		num_inv_paid = tot.num_inv_paid,
		num_cm = tot.num_cm,
		num_adj = tot.num_adj,
		num_wr_off = tot.num_wr_off,
		num_pyt = tot.num_pyt,
		num_overdue_pyt = tot.num_overdue_pyt,
		num_nsf = tot.num_nsf,
		num_fin_chg = tot.num_fin_chg,
		num_late_chg = tot.num_late_chg,
		avg_days_pay = tot.avg_days_pay,
		avg_days_overdue = tot.avg_days_overdue,
		amt_tax = tot.amt_tax,
		amt_tax_oper = tot.amt_tax_oper,
		amt_freight = tot.amt_freight,
		amt_freight_oper = tot.amt_freight_oper,
		amt_disc_given = tot.amt_disc_given,
		amt_disc_g_oper = tot.amt_disc_g_oper,
		last_trx_time = 1
	FROM	#shipto_tot tot
	WHERE	arsumshp.customer_code = tot.customer_code
	AND	arsumshp.ship_to_code = tot.ship_to_code
	AND	arsumshp.date_thru = tot.date_thru
	AND	tot.exists_flag = 1

	
	INSERT	arsumshp (	customer_code, 	ship_to_code, 	date_from, 		date_thru,
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
				amt_freight_oper,	amt_tax_oper 			)
	SELECT	customer_code, 	ship_to_code, 	date_from, 		date_thru,
		num_inv, 		num_inv_paid, 	num_cm,
		num_adj,		num_wr_off,		num_pyt,
		num_overdue_pyt,	num_nsf,		num_fin_chg,
		num_late_chg,		amt_inv, 		amt_cm, 
		amt_adj,		amt_wr_off,		amt_pyt,
		amt_nsf,		amt_fin_chg,		amt_late_chg,
		0.0,			0.0,			0.0,
		amt_disc_given,	amt_disc_taken,	0.0,
		amt_freight,		amt_tax,		avg_days_pay,
		avg_days_overdue,	1,			amt_inv_oper,
		amt_cm_oper,		amt_adj_oper,		amt_wr_off_oper,
		amt_pyt_oper,		amt_nsf_oper,		amt_fin_chg_oper,
		amt_late_chg_oper,	amt_disc_g_oper,	amt_disc_t_oper,
		amt_freight_oper,	amt_tax_oper 					
	FROM	#shipto_tot
	WHERE	exists_flag = 0	

	
	DELETE	arsumshp
	WHERE	last_trx_time = 0
	
	DROP TABLE #shipto_tot

GO
GRANT EXECUTE ON  [dbo].[ARUPDateShipToSummary_SP] TO [public]
GO
