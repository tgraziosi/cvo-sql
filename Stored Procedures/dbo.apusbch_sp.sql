SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/                                                


































CREATE PROC [dbo].[apusbch_sp]        
					    
AS

DECLARE	

		@apsumbch_flag int,
		@home_precision int,
		@oper_precision int,
		@dm_cnt	int,
		@vo_cnt	int,
		@py_cnt	int,
		@va_cnt	int,
		@pa_cnt	int


SELECT  @apsumbch_flag = apsumbch_flag
FROM    apco

IF (@apsumbch_flag = 1)
BEGIN

	SELECT 	@home_precision = b.curr_precision,
			@oper_precision = c.curr_precision
	FROM 	glco a, glcurr_vw b, glcurr_vw c
	WHERE 	a.home_currency = b.currency_code
	AND 	a.oper_currency = c.currency_code

	SELECT 		
			b.trx_ctrl_num, 		a.vendor_code, 			a.branch_code,          
			prd.period_start_date,	prd.period_end_date,	
			a.amt_net,						
			b.amt_discount,     	b.amt_freight,  		b.amt_tax,       
			a.rate_home,			a.rate_oper
	INTO #temp1
	FROM  apdmhdr a, apdmdet b, apmaster c, glprd prd
	WHERE a.trx_ctrl_num = b.trx_ctrl_num
	AND   a.vendor_code = c.vendor_code
	AND   c.address_type = 0
	AND	  a.date_applied between prd.period_start_date and prd.period_end_date

	SELECT DISTINCT trx_ctrl_num, branch_code, period_start_date, period_end_date, amt_net, rate_home, rate_oper
	INTO #temp2
	FROM #temp1

	SELECT @dm_cnt = ISNULL((SELECT COUNT(*) FROM #temp2),0)

	DELETE apsumbch

	IF ( @dm_cnt > 0 )
	BEGIN

		CREATE TABLE #apdmbch_work
		(
			branch_code			varchar(8),
			date_from		int,
			date_thru		int,
			num_dm				int,
			amt_dm				float,
			amt_disc_given		float,	
			amt_freight		float,	
			amt_tax			float,	
			last_trx_time		int,	
			amt_dm_oper			float,
			amt_disc_given_oper	float,	
			amt_freight_oper	float,	
			amt_tax_oper		float,	
			db_action 			smallint
		)

	   	INSERT #apdmbch_work (
			branch_code,        	date_from, 			date_thru,              
			num_dm,           		amt_dm,				amt_disc_given,         
			amt_freight,        	amt_tax,        	
			last_trx_time,      	amt_dm_oper,		amt_disc_given_oper,    
			amt_freight_oper,   	amt_tax_oper,   	
			db_action )
		SELECT DISTINCT 
			branch_code,        	period_start_date, 	period_end_date,      	
			1,              		0.0,				0.0,                    
			0.0,                	0.0,    			
			0,                  	0.0,				0.0,                    
			0.0,                	0.0,    			
			1 
		FROM  #temp1 

		UPDATE #apdmbch_work
		SET num_dm = ISNULL((SELECT COUNT(*)
							  FROM #temp2 a
							  WHERE a.branch_code = b.branch_code
							  AND   a.period_start_date = b.date_from 
							  AND   a.period_end_date = b.date_thru),0)
		FROM #temp2 a, #apdmbch_work b
		WHERE b.db_action = 1
		AND   a.branch_code = b.branch_code

		UPDATE #apdmbch_work
		SET amt_disc_given = (SELECT ISNULL( SUM( (SIGN(a.amt_discount * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) )) * ROUND(ABS(a.amt_discount * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) )) + 0.0000001, @home_precision))),0)
								FROM #temp1 a
								WHERE a.branch_code = b.branch_code
								AND   a.period_start_date = b.date_from 
								AND   a.period_end_date = b.date_thru),
			amt_disc_given_oper = (SELECT ISNULL( SUM( (SIGN(a.amt_discount * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) )) * ROUND(ABS(a.amt_discount * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) )) + 0.0000001, @oper_precision))),0)
								FROM #temp1 a
								WHERE a.branch_code = b.branch_code
								AND   a.period_start_date = b.date_from 
								AND   a.period_end_date = b.date_thru),
			amt_freight = (SELECT ISNULL( SUM( (SIGN(a.amt_freight * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) )) * ROUND(ABS(a.amt_freight * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) )) + 0.0000001, @home_precision))),0)
								FROM #temp1 a
								WHERE a.branch_code = b.branch_code
								AND   a.period_start_date = b.date_from 
								AND   a.period_end_date = b.date_thru),
			amt_freight_oper = (SELECT ISNULL( SUM( (SIGN(a.amt_freight * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) )) * ROUND(ABS(a.amt_freight * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) )) + 0.0000001, @oper_precision))),0)
								FROM #temp1 a
								WHERE a.branch_code = b.branch_code
								AND   a.period_start_date = b.date_from 
								AND   a.period_end_date = b.date_thru),
			amt_tax = (SELECT ISNULL( SUM( (SIGN(a.amt_tax * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) )) * ROUND(ABS(a.amt_tax * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) )) + 0.0000001, @home_precision))),0)
								FROM #temp1 a
								WHERE a.branch_code = b.branch_code
								AND   a.period_start_date = b.date_from 
								AND   a.period_end_date = b.date_thru),
			amt_tax_oper = (SELECT ISNULL( SUM( (SIGN(a.amt_tax * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) )) * ROUND(ABS(a.amt_tax * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) )) + 0.0000001, @oper_precision))),0)
								FROM #temp1 a
								WHERE a.branch_code = b.branch_code
								AND   a.period_start_date = b.date_from 
								AND   a.period_end_date = b.date_thru)
		FROM #temp1 a, #apdmbch_work b
		WHERE b.db_action > 0
		AND   a.branch_code = b.branch_code


		UPDATE #apdmbch_work
		SET amt_dm = (SELECT ISNULL( SUM( (SIGN(a.amt_net * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) )) * ROUND(ABS(a.amt_net * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) )) + 0.0000001, @home_precision))),0)
								FROM #temp2 a
								WHERE a.branch_code = b.branch_code
								AND   a.period_start_date = b.date_from 
								AND   a.period_end_date = b.date_thru),
			amt_dm_oper = (SELECT ISNULL( SUM( (SIGN(a.amt_net * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) )) * ROUND(ABS(a.amt_net * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) )) + 0.0000001, @oper_precision))),0)
								FROM #temp2 a
								WHERE a.branch_code = b.branch_code
								AND   a.period_start_date = b.date_from 
								AND   a.period_end_date = b.date_thru)
		FROM #temp2 a, #apdmbch_work b
		WHERE b.db_action > 0
		AND   a.branch_code = b.branch_code

		DROP TABLE #temp2

		UPDATE #apdmbch_work
		SET db_action = 2
		FROM #apdmbch_work a, apsumbch b
		WHERE a.branch_code = b.branch_code
		AND   a.date_from = b.date_from 
		AND   a.date_thru = b.date_thru

		UPDATE apsumbch
		SET num_dm = apsumbch.num_dm + b.num_dm,
			amt_dm = apsumbch.amt_dm + b.amt_dm,
			amt_dm_oper = apsumbch.amt_dm_oper + b.amt_dm_oper,
			amt_disc_given = apsumbch.amt_disc_given - b.amt_disc_given,
			amt_disc_given_oper = apsumbch.amt_disc_given_oper - b.amt_disc_given_oper,
			amt_freight = apsumbch.amt_freight - b.amt_freight,
			amt_freight_oper = apsumbch.amt_freight_oper - b.amt_freight_oper,
			amt_tax = apsumbch.amt_tax - b.amt_tax,
			amt_tax_oper = apsumbch.amt_tax_oper - b.amt_tax_oper
		FROM  apsumbch, #apdmbch_work b
		WHERE apsumbch.branch_code = b.branch_code
		AND   b.db_action = 2
		AND   apsumbch.date_from = b.date_from 
		AND   apsumbch.date_thru = b.date_thru

		INSERT  apsumbch( 			timestamp,
			branch_code,			date_from,      		date_thru,			   	
			num_vouch,      		num_vouch_paid, 		num_dm,
			num_adj,        		num_pyt,        		num_overdue_pyt,
			num_void,       		
			amt_vouch,      		amt_dm,					amt_adj,        		
			amt_pyt,        		amt_void,       		amt_disc_given, 		
			amt_disc_taken, 		amt_disc_lost,			amt_freight,    		
			amt_tax,        		
			avg_days_pay,			avg_days_overdue, 		last_trx_time,
			amt_vouch_oper,      	amt_dm_oper,			amt_adj_oper,        	
			amt_pyt_oper,        	amt_void_oper,       	amt_disc_given_oper, 	
			amt_disc_taken_oper, 	amt_disc_lost_oper,		amt_freight_oper,    	
			amt_tax_oper)
		SELECT  NULL,	
			branch_code,			date_from,     			date_thru,				
			0,      				0,				 		num_dm,
			0,        				0,        				0,
			0,       				
			0.0,      				amt_dm,					0.0,     				
			0.0,	   				0.0,       				-amt_disc_given, 		
			0.0, 					0.0,					-amt_freight,    		
			-amt_tax,      			
			0,						0,				 		0,
			0.0,     				amt_dm_oper,			0.0,
			0.0,     				0.0,      				-amt_disc_given_oper, 	
			0.0, 					0.0,					-amt_freight_oper,    	
			-amt_tax_oper
		FROM  #apdmbch_work
		WHERE db_action != 2

		DROP TABLE #apdmbch_work
	END
	ELSE 
		DROP TABLE #temp2


	
	SELECT 		
			b.trx_ctrl_num, 		a.vendor_code, 			a.branch_code,          
			prd.period_start_date,	prd.period_end_date,	
			a.date_applied,			a.date_due,				a.date_paid, 
			a.paid_flag,
			a.amt_net,			  
			b.amt_discount,     	b.amt_freight,  		b.amt_tax,       
			a.rate_home,			a.rate_oper
	INTO #temp3
	FROM  apvohdr a, apvodet b, apmaster c, glprd prd
	WHERE a.trx_ctrl_num = b.trx_ctrl_num
	AND   a.vendor_code = c.vendor_code
	AND   c.address_type = 0
	AND	  a.date_applied between prd.period_start_date and prd.period_end_date

	SELECT DISTINCT trx_ctrl_num, branch_code, period_start_date, period_end_date,	
					date_applied, date_due,	date_paid, paid_flag, amt_net, rate_home, rate_oper
	INTO #temp4
	FROM #temp3

	SELECT @vo_cnt = ISNULL((SELECT COUNT(*) FROM #temp4),0)

	IF ( @vo_cnt > 0 )
	BEGIN

		CREATE TABLE #apvobch_work
		(
			branch_code		varchar(8),
			date_from		int,
			date_thru		int,
			avg_days_pay		int,	
			avg_days_overdue	int,
			num_vouch		int,	
			num_vouch_paid		int,
			num_overdue_pyt		int,	
			amt_vouch		float,	
			amt_disc_given		float,	
			amt_freight		float,	
			amt_tax			float,	
			last_trx_time		int,	
			amt_vouch_oper		float,	
			amt_disc_given_oper	float,	
			amt_freight_oper	float,	
			amt_tax_oper		float,	
			db_action		smallint
		)

		INSERT #apvobch_work (
			branch_code,         	date_from,      		date_thru,
			avg_days_pay, 			avg_days_overdue,              
			num_vouch,              num_vouch_paid, 		num_overdue_pyt, 
			amt_vouch,				amt_disc_given,         amt_freight,            amt_tax,        
			last_trx_time,          
			amt_vouch_oper,			amt_disc_given_oper,    amt_freight_oper,       amt_tax_oper,   
			db_action )
		SELECT DISTINCT 
			branch_code,            period_start_date,		period_end_date,        
			0,						0,
			1,              		0,						0,
			0.0,					0.0,                    0.0,                    0.0,
			0,                      
			0.0,					0.0,                    0.0,                    0.0,
			1 
		FROM  #temp3

		UPDATE #apvobch_work
		SET num_vouch = ISNULL((SELECT COUNT(*)
								FROM #temp4 a
								WHERE a.branch_code = b.branch_code
								AND   a.period_start_date = b.date_from 
								AND   a.period_end_date = b.date_thru),0),
			num_vouch_paid = (SELECT ISNULL(SUM(a.paid_flag),0)
						  		FROM #temp4 a
								WHERE a.branch_code = b.branch_code
								AND   a.period_start_date = b.date_from 
								AND   a.period_end_date = b.date_thru
								AND   a.paid_flag = 1),
			num_overdue_pyt = (SELECT ISNULL(SUM(a.paid_flag),0) 
						  		FROM #temp4 a
								WHERE a.branch_code = b.branch_code
								AND   a.period_start_date = b.date_from 
								AND   a.period_end_date = b.date_thru
								AND   a.paid_flag = 1
							  	AND   a.date_paid > a.date_due),
			avg_days_pay = (SELECT ISNULL(SUM(a.date_paid - a.date_applied),0.0) 
						  		FROM #temp4 a
								WHERE a.branch_code = b.branch_code
								AND   a.period_start_date = b.date_from 
								AND   a.period_end_date = b.date_thru
								AND   a.paid_flag = 1
								AND   a.date_paid > a.date_applied),
			avg_days_overdue = (SELECT ISNULL(SUM(a.date_paid - a.date_due),0.0) 
						  		FROM #temp4 a
								WHERE a.branch_code = b.branch_code
								AND   a.period_start_date = b.date_from 
								AND   a.period_end_date = b.date_thru
								AND   a.paid_flag = 1
								AND   a.date_paid > a.date_due)
		FROM #temp4 a, #apvobch_work b
		WHERE b.db_action = 1
		AND   a.branch_code = b.branch_code

		UPDATE #apvobch_work
		SET amt_disc_given = (SELECT ISNULL( SUM( (SIGN(a.amt_discount * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) )) * ROUND(ABS(a.amt_discount * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) )) + 0.0000001, @home_precision))),0)
								FROM #temp3 a
								WHERE a.branch_code = b.branch_code
								AND   a.period_start_date = b.date_from 
								AND   a.period_end_date = b.date_thru),
			amt_disc_given_oper = (SELECT ISNULL( SUM( (SIGN(a.amt_discount * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) )) * ROUND(ABS(a.amt_discount * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) )) + 0.0000001, @oper_precision))),0)
								FROM #temp3 a
								WHERE a.branch_code = b.branch_code
								AND   a.period_start_date = b.date_from 
								AND   a.period_end_date = b.date_thru),
			amt_freight = (SELECT ISNULL( SUM( (SIGN(a.amt_freight * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) )) * ROUND(ABS(a.amt_freight * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) )) + 0.0000001, @home_precision))),0)
								FROM #temp3 a
								WHERE a.branch_code = b.branch_code
								AND   a.period_start_date = b.date_from 
								AND   a.period_end_date = b.date_thru),
			amt_freight_oper = (SELECT ISNULL( SUM( (SIGN(a.amt_freight * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) )) * ROUND(ABS(a.amt_freight * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) )) + 0.0000001, @oper_precision))),0)
								FROM #temp3 a
								WHERE a.branch_code = b.branch_code
								AND   a.period_start_date = b.date_from 
								AND   a.period_end_date = b.date_thru),
			amt_tax = (SELECT ISNULL( SUM( (SIGN(a.amt_tax * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) )) * ROUND(ABS(a.amt_tax * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) )) + 0.0000001, @home_precision))),0)
								FROM #temp3 a
								WHERE a.branch_code = b.branch_code
								AND   a.period_start_date = b.date_from 
								AND   a.period_end_date = b.date_thru),
			amt_tax_oper = (SELECT ISNULL( SUM( (SIGN(a.amt_tax * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) )) * ROUND(ABS(a.amt_tax * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) )) + 0.0000001, @oper_precision))),0)
								FROM #temp3 a
								WHERE a.branch_code = b.branch_code
								AND   a.period_start_date = b.date_from 
								AND   a.period_end_date = b.date_thru)
		FROM #temp3 a, #apvobch_work b
		WHERE b.db_action > 0
		AND   a.branch_code = b.branch_code

		UPDATE #apvobch_work
		SET amt_vouch = (SELECT ISNULL( SUM( (SIGN(a.amt_net * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) )) * ROUND(ABS(a.amt_net * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) )) + 0.0000001, @home_precision))),0)
								FROM #temp4 a
								WHERE a.branch_code = b.branch_code
								AND   a.period_start_date = b.date_from 
								AND   a.period_end_date = b.date_thru),
			amt_vouch_oper = (SELECT ISNULL( SUM( (SIGN(a.amt_net * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) )) * ROUND(ABS(a.amt_net * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) )) + 0.0000001, @oper_precision))),0)
								FROM #temp4 a
								WHERE a.branch_code = b.branch_code
								AND   a.period_start_date = b.date_from 
								AND   a.period_end_date = b.date_thru)
		FROM #temp4 a, #apvobch_work b
		WHERE b.db_action > 0
		AND   a.branch_code = b.branch_code

		DROP TABLE #temp4

		UPDATE #apvobch_work
		SET db_action = 2
		FROM #apvobch_work a, apsumbch b
		WHERE a.branch_code = b.branch_code
		AND   a.date_from = b.date_from 
		AND   a.date_thru = b.date_thru

		UPDATE apsumbch
		SET num_vouch = apsumbch.num_vouch + b.num_vouch,
			num_vouch_paid = apsumbch.num_vouch_paid + b.num_vouch_paid,
			num_overdue_pyt = apsumbch.num_overdue_pyt + b.num_overdue_pyt,
			avg_days_pay = apsumbch.avg_days_pay + b.avg_days_pay,
			avg_days_overdue = apsumbch.avg_days_overdue + b.avg_days_overdue,
			amt_vouch = apsumbch.amt_vouch + b.amt_vouch,
			amt_vouch_oper = apsumbch.amt_vouch_oper + b.amt_vouch_oper,
			amt_disc_given = apsumbch.amt_disc_given + b.amt_disc_given,
			amt_disc_given_oper = apsumbch.amt_disc_given_oper + b.amt_disc_given_oper,
			amt_freight = apsumbch.amt_freight + b.amt_freight,
			amt_freight_oper = apsumbch.amt_freight_oper + b.amt_freight_oper,
			amt_tax = apsumbch.amt_tax + b.amt_tax,
			amt_tax_oper = apsumbch.amt_tax_oper + b.amt_tax_oper
		FROM apsumbch, #apvobch_work b
		WHERE apsumbch.branch_code = b.branch_code
		AND   b.db_action = 2
		AND   apsumbch.date_from = b.date_from 
		AND   apsumbch.date_thru = b.date_thru

		INSERT  apsumbch( 			timestamp,
			branch_code,			date_from,      		date_thru,			   	
			num_vouch,      		num_vouch_paid, 		num_dm,
			num_adj,        		num_pyt,        		num_overdue_pyt,
			num_void,       		
			amt_vouch,      		amt_dm,					amt_adj,        		
			amt_pyt,        		amt_void,       		amt_disc_given, 		
			amt_disc_taken, 		amt_disc_lost,			amt_freight,    		
			amt_tax,        		
			avg_days_pay,			avg_days_overdue, 		last_trx_time,
			amt_vouch_oper,      	amt_dm_oper,			amt_adj_oper,        	
			amt_pyt_oper,        	amt_void_oper,       	amt_disc_given_oper, 	
			amt_disc_taken_oper, 	amt_disc_lost_oper,		amt_freight_oper,    	
			amt_tax_oper)
		SELECT  NULL,	
			branch_code,			date_from,     			date_thru,				
			num_vouch,      		num_vouch_paid,			0,
			0,        				0,        				num_overdue_pyt,
			0,       				
			amt_vouch,      		0.0,					0.0,     				
			0.0,	   				0.0,       				amt_disc_given, 		
			0.0, 					0.0,					amt_freight,    		
			amt_tax,      			
			avg_days_pay,			avg_days_overdue,		0,
			amt_vouch_oper,        	0.0,					0.0,
			0.0,     				0.0,      				amt_disc_given_oper, 	
			0.0, 					0.0,					amt_freight_oper,    	
			amt_tax_oper
		FROM  #apvobch_work
		WHERE db_action != 2

		DROP TABLE #apvobch_work
	END
	ELSE 
		DROP TABLE #temp4



	
	SELECT 		
			a.trx_ctrl_num, 		a.vendor_code, 			c.branch_code,          
			prd.period_start_date,	prd.period_end_date,	
			a.amt_net,				a.amt_discount, 	
			a.rate_home,			a.rate_oper
	INTO #temp5
	FROM  appyhdr a, appydet b, apmaster c, glprd prd
	WHERE a.trx_ctrl_num = b.trx_ctrl_num
	AND   a.vendor_code = c.vendor_code
	AND   c.address_type = 0
	AND	  a.date_applied between prd.period_start_date and prd.period_end_date

	SELECT DISTINCT trx_ctrl_num, branch_code, period_start_date, period_end_date, amt_net, rate_home, rate_oper
	INTO #temp6
	FROM #temp5

	SELECT @py_cnt = ISNULL((SELECT COUNT(*) FROM #temp6),0)

	IF ( @py_cnt > 0 )
	BEGIN

		CREATE TABLE #appybch_work
		(
			branch_code		varchar(8),
			date_from		int,
			date_thru		int,
			num_pyt		int,	
			amt_pyt		float,	
			amt_disc_taken		float,	
			last_trx_time		int,	
			amt_pyt_oper		float,	
			amt_disc_taken_oper	float,	
			db_action		smallint
		)

		INSERT #appybch_work (
			branch_code,         	date_from,      		date_thru,              
			num_pyt,              	amt_pyt,				amt_disc_taken,         
			last_trx_time,          amt_pyt_oper,			amt_disc_taken_oper,
			db_action )
		SELECT DISTINCT 
			branch_code,            period_start_date,		period_end_date,        
			1,              		0.0,					0.0,
			0,                      0.0,					0.0,                    
			1 
		FROM  #temp5

		UPDATE #appybch_work
		SET num_pyt = ISNULL((SELECT COUNT(*)
								 FROM #temp6 a
								 WHERE a.branch_code = b.branch_code
								 AND   a.period_start_date = b.date_from 
								 AND   a.period_end_date = b.date_thru),0)
		FROM #temp6 a, #appybch_work b
		WHERE b.db_action = 1
		AND   a.branch_code = b.branch_code

		UPDATE #appybch_work
		SET amt_disc_taken = (SELECT ISNULL( SUM( (SIGN(a.amt_discount * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) )) * ROUND(ABS(a.amt_discount * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) )) + 0.0000001, @home_precision))),0)
								FROM #temp5 a
								WHERE a.branch_code = b.branch_code
								AND   a.period_start_date = b.date_from 
								AND   a.period_end_date = b.date_thru),
			amt_disc_taken_oper = (SELECT ISNULL( SUM( (SIGN(a.amt_discount * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) )) * ROUND(ABS(a.amt_discount * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) )) + 0.0000001, @oper_precision))),0)
								FROM #temp5 a
								WHERE a.branch_code = b.branch_code
								AND   a.period_start_date = b.date_from 
								AND   a.period_end_date = b.date_thru)
		FROM #temp5 a, #appybch_work b
		WHERE b.db_action > 0
		AND   a.branch_code = b.branch_code

		UPDATE #appybch_work
		SET amt_pyt = (SELECT ISNULL( SUM( (SIGN(a.amt_net * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) )) * ROUND(ABS(a.amt_net * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) )) + 0.0000001, @home_precision))),0)
								FROM #temp6 a
								WHERE a.branch_code = b.branch_code
								AND   a.period_start_date = b.date_from 
								AND   a.period_end_date = b.date_thru),
			amt_pyt_oper = (SELECT ISNULL( SUM( (SIGN(a.amt_net * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) )) * ROUND(ABS(a.amt_net * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) )) + 0.0000001, @oper_precision))),0)
								FROM #temp6 a
								WHERE a.branch_code = b.branch_code
								AND   a.period_start_date = b.date_from 
								AND   a.period_end_date = b.date_thru)
		FROM #temp6 a, #appybch_work b
		WHERE b.db_action > 0
		AND   a.branch_code = b.branch_code

		DROP TABLE #temp6

		UPDATE #appybch_work
		SET db_action = 2
		FROM #appybch_work a, apsumbch b
		WHERE a.branch_code = b.branch_code
		AND   a.date_from = b.date_from 
		AND   a.date_thru = b.date_thru

		UPDATE apsumbch
		SET num_pyt = apsumbch.num_pyt + b.num_pyt,
			amt_pyt = apsumbch.amt_pyt + b.amt_pyt,
			amt_pyt_oper = apsumbch.amt_pyt_oper + b.amt_pyt_oper,
			amt_disc_taken = apsumbch.amt_disc_taken + b.amt_disc_taken,
			amt_disc_taken_oper = apsumbch.amt_disc_taken_oper + b.amt_disc_taken_oper
		FROM apsumbch, #appybch_work b
		WHERE apsumbch.branch_code = b.branch_code
		AND   b.db_action = 2
		AND   apsumbch.date_from = b.date_from 
		AND   apsumbch.date_thru = b.date_thru

		INSERT  apsumbch( 			timestamp,
			branch_code,			date_from,      		date_thru,			   	
			num_vouch,      		num_vouch_paid, 		num_dm,
			num_adj,        		num_pyt,        		num_overdue_pyt,
			num_void,       		
			amt_vouch,      		amt_dm,					amt_adj,        		
			amt_pyt,        		amt_void,       		amt_disc_given, 		
			amt_disc_taken, 		amt_disc_lost,			amt_freight,    		
			amt_tax,        		
			avg_days_pay,			avg_days_overdue, 		last_trx_time,
			amt_vouch_oper,      	amt_dm_oper,			amt_adj_oper,        	
			amt_pyt_oper,        	amt_void_oper,       	amt_disc_given_oper, 	
			amt_disc_taken_oper, 	amt_disc_lost_oper,		amt_freight_oper,    	
			amt_tax_oper)
		SELECT  NULL,	
			branch_code,			date_from,     			date_thru,				
			0,      				0,				 		0,
			0,        				num_pyt,        		0,
			0,       				
			0.0,      				0.0,					0.0,     				
			amt_pyt,	   			0.0,       				0.0, 		
			amt_disc_taken, 		0.0,					0.0,    		
			0.0,      			
			0,						0,				 		0,
			0.0,     				0.0,					0.0,
			amt_pyt_oper,     		0.0,      				0.0, 	
			amt_disc_taken_oper, 	0.0,					0.0,    		
			0.0
		FROM  #appybch_work
		WHERE db_action != 2

		DROP TABLE #appybch_work
	END
	ELSE 
		DROP TABLE #temp6



													   
	SELECT 		
			a.apply_to_num, 		a.vendor_code, 			a.branch_code,          
			prd.period_start_date,	prd.period_end_date,	
			a.amt_net,				
			a.rate_home,			a.rate_oper
	INTO #temp7
	FROM  apvohdr a, apvahdr b, apmaster c, glprd prd
	WHERE a.apply_to_num = b.apply_to_num
	AND   a.vendor_code = c.vendor_code
	AND   c.address_type = 0
	AND	  a.date_applied between prd.period_start_date and prd.period_end_date

	SELECT @va_cnt = ISNULL((SELECT COUNT(*) FROM #temp7),0)

	IF ( @va_cnt > 0 )
	BEGIN

		CREATE TABLE #apvabch_work
		(
			branch_code		varchar(8),
			date_from		int,
			date_thru		int,
			num_adj		int,	
			amt_adj		float,	
			last_trx_time		int,	
			amt_adj_oper		float,	
			db_action		smallint
		)

		INSERT #apvabch_work (
			branch_code,         	date_from,      		date_thru,              
			num_adj,              	amt_adj, 
			last_trx_time,          amt_adj_oper,
			db_action )
		SELECT DISTINCT 
			branch_code,            period_start_date,		period_end_date,        
			1,              		0.0,		 
			0,                      0.0,		 
			1 
		FROM  #temp7

		UPDATE #apvabch_work
		SET num_adj = ISNULL((SELECT COUNT(*)
								 FROM #temp7 a
								 WHERE a.branch_code = b.branch_code
								 AND   a.period_start_date = b.date_from 
								 AND   a.period_end_date = b.date_thru),0)
		FROM #temp7 a, #apvabch_work b
		WHERE b.db_action = 1
		AND   a.branch_code = b.branch_code

		UPDATE #apvabch_work
		SET amt_adj = (SELECT ISNULL( SUM( (SIGN(a.amt_net * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) )) * ROUND(ABS(a.amt_net * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) )) + 0.0000001, @home_precision))),0)
								FROM #temp7 a
								WHERE a.branch_code = b.branch_code
								AND   a.period_start_date = b.date_from 
								AND   a.period_end_date = b.date_thru),
			amt_adj_oper = (SELECT ISNULL( SUM( (SIGN(a.amt_net * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) )) * ROUND(ABS(a.amt_net * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) )) + 0.0000001, @oper_precision))),0)
								FROM #temp7 a
								WHERE a.branch_code = b.branch_code
								AND   a.period_start_date = b.date_from 
								AND   a.period_end_date = b.date_thru)
		FROM #temp7 a, #apvabch_work b
		WHERE b.db_action > 0
		AND   a.branch_code = b.branch_code

		UPDATE #apvabch_work
		SET db_action = 2
		FROM #apvabch_work a, apsumbch b
		WHERE a.branch_code = b.branch_code
		AND   a.date_from = b.date_from 
		AND   a.date_thru = b.date_thru

		UPDATE apsumbch
		SET num_adj = apsumbch.num_adj + b.num_adj,
			amt_adj = apsumbch.amt_adj + b.amt_adj,
			amt_adj_oper = apsumbch.amt_adj_oper + b.amt_adj_oper
		FROM apsumbch, #apvabch_work b
		WHERE apsumbch.branch_code = b.branch_code
		AND   b.db_action = 2
		AND   apsumbch.date_from = b.date_from 
		AND   apsumbch.date_thru = b.date_thru

		INSERT  apsumbch( 			timestamp,
			branch_code,			date_from,      		date_thru,			   	
			num_vouch,      		num_vouch_paid, 		num_dm,
			num_adj,        		num_pyt,        		num_overdue_pyt,
			num_void,       		
			amt_vouch,      		amt_dm,					amt_adj,        		
			amt_pyt,        		amt_void,       		amt_disc_given, 		
			amt_disc_taken, 		amt_disc_lost,			amt_freight,    		
			amt_tax,        		
			avg_days_pay,			avg_days_overdue, 		last_trx_time,
			amt_vouch_oper,      	amt_dm_oper,			amt_adj_oper,        	
			amt_pyt_oper,        	amt_void_oper,       	amt_disc_given_oper, 	
			amt_disc_taken_oper, 	amt_disc_lost_oper,		amt_freight_oper,    	
			amt_tax_oper)
		SELECT  NULL,	
			branch_code,			date_from,     			date_thru,				
			0,      				0,				 		0,
			num_adj,        	   	0,		        		0,
			0,       				
			0.0,      				0.0,				   	amt_adj,     				
			0.0,	   				0.0,       				0.0, 		
			0.0,	   				0.0,       				0.0, 		
			0.0,      			
			0,						0,				 		0,
			0.0,     				0.0,					amt_adj_oper,
			0.0,     				0.0,      				0.0, 	
			0.0,	   				0.0,       				0.0, 		
			0.0
		FROM  #apvabch_work
		WHERE db_action != 2

		DROP TABLE #apvabch_work
	END



	
	SELECT 		
			a.doc_ctrl_num, 		a.vendor_code, 			c.branch_code,  	a.cash_acct_code,        
			prd.period_start_date,	prd.period_end_date,	
			a.amt_net,				
			a.rate_home,			a.rate_oper
	INTO #temp9
	FROM  appyhdr a, appahdr b, apmaster c, glprd prd
	WHERE a.doc_ctrl_num = b.doc_ctrl_num
	AND   a.cash_acct_code = b.cash_acct_code
	AND   a.vendor_code = c.vendor_code
	AND   a.payment_type != 4
	AND   c.address_type = 0
	AND	  a.date_applied between prd.period_start_date and prd.period_end_date

	SELECT DISTINCT doc_ctrl_num, branch_code, cash_acct_code, period_start_date, period_end_date, amt_net, rate_home, rate_oper
	INTO #temp10
	FROM #temp9

	SELECT @pa_cnt = ISNULL((SELECT COUNT(*) FROM #temp10),0)

	IF ( @pa_cnt > 0 )
	BEGIN

		CREATE TABLE #appabch_work
		(
			branch_code		varchar(8),
			date_from		int,
			date_thru		int,
			num_void		int,	
			amt_void		float,	
			last_trx_time		int,	
			amt_void_oper		float,	
			db_action		smallint
		)

		INSERT #appabch_work (
			branch_code,         	date_from,      		date_thru,              
			num_void,              	amt_void, 
			last_trx_time,          amt_void_oper,
			db_action )
		SELECT DISTINCT 
			branch_code,            period_start_date,		period_end_date,        
			1,              		0.0,		 
			0,                      0.0,		 
			1 
		FROM  #temp9

		UPDATE #appabch_work
		SET num_void = ISNULL((SELECT COUNT(*)
								 FROM #temp10 a
								 WHERE a.branch_code = b.branch_code
								 AND   a.period_start_date = b.date_from 
								 AND   a.period_end_date = b.date_thru),0)
		FROM #temp10 a, #appabch_work b
		WHERE b.db_action = 1
		AND   a.branch_code = b.branch_code

		UPDATE #appabch_work
		SET amt_void = (SELECT ISNULL( SUM( (SIGN(a.amt_net * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) )) * ROUND(ABS(a.amt_net * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) )) + 0.0000001, @home_precision))),0)
								FROM #temp10 a
								WHERE a.branch_code = b.branch_code
								AND   a.period_start_date = b.date_from 
								AND   a.period_end_date = b.date_thru),
			amt_void_oper = (SELECT ISNULL( SUM( (SIGN(a.amt_net * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) )) * ROUND(ABS(a.amt_net * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) )) + 0.0000001, @oper_precision))),0)
								FROM #temp10 a
								WHERE a.branch_code = b.branch_code
								AND   a.period_start_date = b.date_from 
								AND   a.period_end_date = b.date_thru)
		FROM #temp10 a, #appabch_work b
		WHERE b.db_action > 0
		AND   a.branch_code = b.branch_code

		DROP TABLE #temp10

		UPDATE #appabch_work
		SET db_action = 2
		FROM #appabch_work a, apsumbch b
		WHERE a.branch_code = b.branch_code
		AND   a.date_from = b.date_from 
		AND   a.date_thru = b.date_thru

		UPDATE apsumbch
		SET num_void = apsumbch.num_void + b.num_void,
			amt_void = apsumbch.amt_void + b.amt_void,
			amt_void_oper = apsumbch.amt_void_oper + b.amt_void_oper
		FROM apsumbch, #appabch_work b
		WHERE apsumbch.branch_code = b.branch_code
		AND   b.db_action = 2
		AND   apsumbch.date_from = b.date_from 
		AND   apsumbch.date_thru = b.date_thru


		INSERT  apsumbch( 			timestamp,
			branch_code,			date_from,      		date_thru,			   	
			num_vouch,      		num_vouch_paid, 		num_dm,
			num_adj,        		num_pyt,        		num_overdue_pyt,
			num_void,       		
			amt_vouch,      		amt_dm,					amt_adj,        		
			amt_pyt,        		amt_void,       		amt_disc_given, 		
			amt_disc_taken, 		amt_disc_lost,			amt_freight,    		
			amt_tax,        		
			avg_days_pay,			avg_days_overdue, 		last_trx_time,
			amt_vouch_oper,      	amt_dm_oper,			amt_adj_oper,        	
			amt_pyt_oper,        	amt_void_oper,       	amt_disc_given_oper, 	
			amt_disc_taken_oper, 	amt_disc_lost_oper,		amt_freight_oper,    	
			amt_tax_oper)
		SELECT  NULL,	
			branch_code,			date_from,     			date_thru,				
			0,      				0,				 		0,
			0,        	   			0,		        		0,
		   	num_void,       				
			0.0,      				0.0,				   	0.0,     				
			0.0,	   				amt_void,       		0.0, 		
			0.0,	   				0.0,       				0.0, 		
			0.0,      			
			0,						0,				 		0,
			0.0,     				0.0,					0.0,
			0.0,     				amt_void_oper,      	0.0, 	
			0.0,	   				0.0,       				0.0, 		
			0.0
		FROM  #appabch_work
		WHERE db_action != 2

		DROP TABLE #appabch_work
	END
	ELSE 
		DROP TABLE #temp10


	DROP TABLE #temp1
	DROP TABLE #temp3
	DROP TABLE #temp5
	DROP TABLE #temp7
	DROP TABLE #temp9
END
GO
GRANT EXECUTE ON  [dbo].[apusbch_sp] TO [public]
GO
