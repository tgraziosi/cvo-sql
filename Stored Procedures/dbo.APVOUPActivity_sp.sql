SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO












CREATE PROC [dbo].[APVOUPActivity_sp]
											@batch_ctrl_num		varchar(16),
											@client_id 			varchar(20),
											@user_id			int,  
											@debug_level		smallint = 0
AS

   DECLARE
      @vend_flag smallint,
	  @pto_flag smallint,
	  @cls_flag smallint,     
	  @bch_flag smallint,
	  @current_date int,

	  @age_brk1 smallint, 	
	  @age_brk2 smallint,  	
	  @age_brk3 smallint,  
	  @age_brk4 smallint, 	
	  @age_brk5 smallint,		
	  @pay_to_flag smallint,
	  @precision_home smallint, 
	  @precision_oper smallint

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvoupa.cpp" + ", line " + STR( 68, 5 ) + " -- ENTRY: "


SELECT  @vend_flag = apactvnd_flag,
		@pto_flag = apactpto_flag,
		@cls_flag = apactcls_flag,
		@bch_flag = apactbch_flag
FROM    apco



SELECT	@precision_home = curr_precision
FROM	glcurr_vw, glco
WHERE	glco.home_currency = glcurr_vw.currency_code

SELECT	@precision_oper = curr_precision
FROM	glcurr_vw, glco
WHERE	glco.oper_currency = glcurr_vw.currency_code


DECLARE @apvobracket_work TABLE 
(
	wild_code			varchar(12),
	age_bracket1	float,
	age_bracket2	float,
	age_bracket3	float,
	age_bracket4	float,
	age_bracket5	float,
	age_bracket6	float,
	age_bracket1_oper	float,
	age_bracket2_oper	float,
	age_bracket3_oper	float,
	age_bracket4_oper	float,
	age_bracket5_oper	float,
	age_bracket6_oper	float
)


SELECT	@age_brk1 = age_bracket1 ,
	@age_brk2 = age_bracket2 ,
	@age_brk3 = age_bracket3 ,
	@age_brk4 = age_bracket4 ,
	@age_brk5 = age_bracket5 ,
	@pay_to_flag = apactpto_flag
FROM	apco



EXEC appdate_sp @current_date OUTPUT		


IF @vend_flag = 1
   BEGIN



	  UPDATE apactvnd
	  SET date_last_vouch = b.date_last_vouch,
	      amt_last_vouch = b.amt_last_vouch,
		  last_vouch_doc = b.last_vouch_doc,
		  last_vouch_cur = b.last_vouch_cur,
		  amt_balance = apactvnd.amt_balance + b.amt_vouch,	   				
		  amt_vouch_unposted = apactvnd.amt_vouch_unposted - b.amt_vouch,	
		  num_vouch = apactvnd.num_vouch + b.num_vouch,
		  amt_balance_oper = apactvnd.amt_balance_oper + b.amt_vouch_oper,
		  amt_vouch_unposted_oper = apactvnd.amt_vouch_unposted_oper - b.amt_vouch_oper,
		  high_amt_ap = (sign((sign((apactvnd.high_amt_ap) - (apactvnd.amt_balance + b.amt_vouch) + 0.00000001) + 1)) * (apactvnd.high_amt_ap) + sign((sign((apactvnd.amt_balance + b.amt_vouch) - (apactvnd.high_amt_ap) - 0.00000001) + 1)) * (apactvnd.amt_balance + b.amt_vouch)),
		  high_amt_ap_oper = (sign((sign((apactvnd.high_amt_ap_oper) - (apactvnd.amt_balance_oper + b.amt_vouch_oper) + 0.00000001) + 1)) * (apactvnd.high_amt_ap_oper) + sign((sign((apactvnd.amt_balance_oper + b.amt_vouch_oper) - (apactvnd.high_amt_ap_oper) - 0.00000001) + 1)) * (apactvnd.amt_balance_oper + b.amt_vouch_oper)),
		  high_date_ap = (sign((sign((apactvnd.high_amt_ap) - (apactvnd.amt_balance + b.amt_vouch) + 0.00000001) + 1)) * (apactvnd.high_date_ap) + sign((sign((apactvnd.amt_balance + b.amt_vouch) - (apactvnd.high_amt_ap) - 0.00000001) + 1)) * (@current_date))
	  FROM apactvnd
		INNER JOIN #apvovnd_work b ON apactvnd.vendor_code = b.vendor_code



	  

	  INSERT apactvnd (
		vendor_code,		date_last_vouch,        date_last_dm,
		date_last_adj,  	date_last_pyt,          date_last_void,
		amt_last_vouch, 	amt_last_dm,            amt_last_adj,
		amt_last_pyt,   	amt_last_void,          amt_age_bracket1,
		amt_age_bracket2,	amt_age_bracket3,      	amt_age_bracket4,
		amt_age_bracket5,	amt_age_bracket6,      	amt_on_order,
		amt_vouch_unposted,	last_vouch_doc,      	last_dm_doc,
		last_adj_doc,   	last_pyt_doc,           last_pyt_acct,
		last_void_doc,  	last_void_acct,         high_amt_ap,
		high_amt_vouch, 	high_date_ap,           high_date_vouch,
		num_vouch,      	num_vouch_paid,         num_overdue_pyt,
		avg_days_pay,   	avg_days_overdue,       last_trx_time,
		amt_balance,
		last_vouch_cur,		last_dm_cur,			last_adj_cur,
		last_pyt_cur,		last_void_cur,			
		amt_age_bracket1_oper,	amt_age_bracket2_oper,	amt_age_bracket3_oper,
		amt_age_bracket4_oper,	amt_age_bracket5_oper,	amt_age_bracket6_oper,
		amt_on_order_oper,		amt_vouch_unposted_oper,high_amt_ap_oper,
		amt_balance_oper
		 )
	  SELECT 
		a.vendor_code,		a.date_last_vouch,        0,
		0,  				0,			        	0,
		a.amt_last_vouch, 	0,       		0.0,
		0.0,			   	0.0,          			0.0,
		0.0,				0.0,      				0.0,
		0.0,				0.0,      				0.0,
		0.0,				a.last_vouch_doc,      	'',
		'',   				'',           			'',
		'',  				'',         			a.amt_vouch,
		a.amt_vouch,			@current_date,			@current_date,
		a.num_vouch, 			0,				        0,
		0,   				0,       				0,
		a.amt_vouch,
		a.last_vouch_cur,		'',						'',
		'',					'',
		0.0,					0.0,					0.0,
		0.0,					0.0,					0.0,
		0.0,					0.0,					a.amt_vouch_oper,
		a.amt_vouch_oper
	FROM  #apvovnd_work a
		LEFT JOIN apactvnd b ON a.vendor_code = b.vendor_code
	WHERE b.vendor_code IS NULL


	INSERT INTO @apvobracket_work
	SELECT a.vendor_code, 	  
		SUM(SIGN(1- SIGN( @current_date - a.date_aging - @age_brk1 )) 
			* ROUND(a.amt_net * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) ), @precision_home)),

 
		SUM(SIGN(1 + SIGN( @current_date - a.date_aging - @age_brk1 - 0.5)) 
			* SIGN(1- SIGN(@current_date - a.date_aging - @age_brk2 ))
			* ROUND(a.amt_net * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) ), @precision_home)),

		SUM(SIGN(1 + SIGN( @current_date - a.date_aging - @age_brk2 - 0.5)) 
			* SIGN(1- SIGN(@current_date - a.date_aging - @age_brk3 ))
			* ROUND(a.amt_net * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) ), @precision_home)),

		SUM(SIGN(1 + SIGN( @current_date - a.date_aging - @age_brk3 - 0.5)) 
			* SIGN(1- SIGN(@current_date - a.date_aging - @age_brk4 ))
			* ROUND(a.amt_net * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) ), @precision_home)),

		SUM(SIGN(1 + SIGN(@current_date - a.date_aging - @age_brk4 - 0.5)) 
			* SIGN(1- SIGN(@current_date - a.date_aging - @age_brk5 ))
			* ROUND(a.amt_net * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) ), @precision_home)),

		SUM(SIGN(1 + SIGN(@current_date - a.date_aging - @age_brk5 - 0.5)) 
			* ROUND( a.amt_net * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) ), @precision_home)),

		SUM(SIGN(1- SIGN( @current_date - a.date_aging - @age_brk1 )) 
			* ROUND( a.amt_net * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) ), @precision_oper)),

		SUM(SIGN(1 + SIGN(@current_date - a.date_aging - @age_brk1 - 0.5)) 
			* SIGN(1- SIGN(@current_date - a.date_aging - @age_brk2 ))
			* ROUND( a.amt_net * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) ), @precision_oper)),

		SUM(SIGN(1 + SIGN(@current_date - a.date_aging - @age_brk2 - 0.5)) 
			* SIGN(1- SIGN(@current_date - a.date_aging - @age_brk3 ))
			* ROUND( a.amt_net * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) ), @precision_oper)),

		SUM(SIGN(1 + SIGN(@current_date - a.date_aging - @age_brk3 - 0.5)) 
			* SIGN(1- SIGN(@current_date - a.date_aging - @age_brk4 ))
			* ROUND( a.amt_net * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) ), @precision_oper)),

		SUM(SIGN(1 + SIGN(@current_date - a.date_aging - @age_brk4 - 0.5)) 
			* SIGN(1- SIGN(@current_date - a.date_aging - @age_brk5 ))
			* ROUND( a.amt_net * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) ), @precision_oper)),

		SUM(SIGN(1 + SIGN(@current_date - a.date_aging - @age_brk5 - 0.5)) 
			* ROUND( a.amt_net * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) ), @precision_oper))

	FROM 	#apvochg_work a
		INNER JOIN #apvovnd_work b ON a.vendor_code = b.vendor_code
	GROUP BY a.vendor_code

	UPDATE apactvnd
	SET 
		amt_age_bracket1 = b.amt_age_bracket1 + a.age_bracket1 ,
		amt_age_bracket2 = b.amt_age_bracket2 + a.age_bracket2 ,
		amt_age_bracket3 = b.amt_age_bracket3 + a.age_bracket3 ,
	      	amt_age_bracket4 = b.amt_age_bracket4 + a.age_bracket4 ,
		amt_age_bracket5 = b.amt_age_bracket5 + a.age_bracket5 ,
		amt_age_bracket6 = b.amt_age_bracket6 + a.age_bracket6,
		amt_age_bracket1_oper = b.amt_age_bracket1_oper  + a.age_bracket1_oper ,
		amt_age_bracket2_oper = b.amt_age_bracket2_oper + a.age_bracket2_oper ,
		amt_age_bracket3_oper = b.amt_age_bracket3_oper + a.age_bracket3_oper ,
	      	amt_age_bracket4_oper = b.amt_age_bracket4_oper + a.age_bracket4_oper ,
		amt_age_bracket5_oper = b.amt_age_bracket5_oper + a.age_bracket5_oper ,
		amt_age_bracket6_oper = b.amt_age_bracket6_oper + a.age_bracket6_oper

	FROM @apvobracket_work a 
		INNER JOIN apactvnd b ON a.wild_code = b.vendor_code



   END


IF @pto_flag = 1
   BEGIN

	  UPDATE apactpto
	  SET date_last_vouch = b.date_last_vouch,
	      amt_last_vouch = b.amt_last_vouch,
		  last_vouch_doc = b.last_vouch_doc,
		  last_vouch_cur = b.last_vouch_cur,
		  amt_balance = apactpto.amt_balance + b.amt_vouch,
		  amt_balance_oper = apactpto.amt_balance_oper + b.amt_vouch_oper,
		  amt_vouch_unposted = apactpto.amt_vouch_unposted - b.amt_vouch,
		  amt_vouch_unposted_oper = apactpto.amt_vouch_unposted_oper - b.amt_vouch_oper,
		  num_vouch = apactpto.num_vouch + b.num_vouch,
		  high_amt_ap = (sign((sign((apactpto.high_amt_ap) - (apactpto.amt_balance + b.amt_vouch) + 0.00000001) + 1)) * (apactpto.high_amt_ap) + sign((sign((apactpto.amt_balance + b.amt_vouch) - (apactpto.high_amt_ap) - 0.00000001) + 1)) * (apactpto.amt_balance + b.amt_vouch)),
		  high_amt_ap_oper = (sign((sign((apactpto.high_amt_ap_oper) - (apactpto.amt_balance_oper + b.amt_vouch_oper) + 0.00000001) + 1)) * (apactpto.high_amt_ap_oper) + sign((sign((apactpto.amt_balance_oper + b.amt_vouch_oper) - (apactpto.high_amt_ap_oper) - 0.00000001) + 1)) * (apactpto.amt_balance_oper + b.amt_vouch_oper)),
		  high_date_ap = (sign((sign((apactpto.high_amt_ap) - (apactpto.amt_balance + b.amt_vouch) + 0.00000001) + 1)) * (apactpto.high_date_ap) + sign((sign((apactpto.amt_balance + b.amt_vouch) - (apactpto.high_amt_ap) - 0.00000001) + 1)) * (@current_date))
	  FROM apactpto
		INNER JOIN #apvopto_work b ON apactpto.vendor_code = b.vendor_code AND apactpto.pay_to_code = b.pay_to_code





	  INSERT apactpto (
		vendor_code,    pay_to_code,  date_last_vouch,        date_last_dm,
		date_last_adj,  date_last_pyt,          date_last_void,
		amt_last_vouch, amt_last_dm,            amt_last_adj,
		amt_last_pyt,   amt_last_void,          amt_age_bracket1,
		amt_age_bracket2,amt_age_bracket3,      amt_age_bracket4,
		amt_age_bracket5,amt_age_bracket6,      amt_on_order,
		amt_vouch_unposted,last_vouch_doc,      last_dm_doc,
		last_adj_doc,   last_pyt_doc,           last_pyt_acct,
		last_void_doc,  last_void_acct,         high_amt_ap,
		high_amt_vouch, high_date_ap,           high_date_vouch,
		num_vouch,      num_vouch_paid,         num_overdue_pyt,
		avg_days_pay,   avg_days_overdue,       last_trx_time,
		amt_balance,	last_vouch_cur,			amt_vouch_unposted_oper,
		high_amt_ap_oper,	amt_balance_oper
		 )
	  SELECT  
		a.vendor_code,		a.pay_to_code, a.date_last_vouch,        0,
		0,  				0,			        	0,
		a.amt_last_vouch, 	0,       		0.0,
		0.0,			   	0.0,          			0.0,
		0.0,				0.0,      				0.0,
		0.0,				0.0,      				0.0,
		0.0,				a.last_vouch_doc,      	'',
		'',   				'',           			'',
		'',  				'',         			a.amt_vouch,
		a.amt_vouch,			@current_date,			@current_date,
		a.num_vouch, 			0,				        0,
		0,   				0,       				0,
		a.amt_vouch,			a.last_vouch_cur,			0.0,
		a.amt_vouch_oper,		a.amt_vouch_oper
	FROM  #apvopto_work a
		LEFT JOIN apactpto b ON a.vendor_code = b.vendor_code AND a.pay_to_code = b.pay_to_code
	WHERE b.pay_to_code IS NULL


	



	INSERT INTO @apvobracket_work
	SELECT a.vendor_code, 	  
		SUM(SIGN(1- SIGN( @current_date - a.date_aging - @age_brk1 )) 
			* ROUND(a.amt_net * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) ), @precision_home)),

 
		SUM(SIGN(1 + SIGN( @current_date - a.date_aging - @age_brk1 - 0.5)) 
			* SIGN(1- SIGN(@current_date - a.date_aging - @age_brk2 ))
			* ROUND(a.amt_net * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) ), @precision_home)),

		SUM(SIGN(1 + SIGN( @current_date - a.date_aging - @age_brk2 - 0.5)) 
			* SIGN(1- SIGN(@current_date - a.date_aging - @age_brk3 ))
			* ROUND(a.amt_net * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) ), @precision_home)),

		SUM(SIGN(1 + SIGN( @current_date - a.date_aging - @age_brk3 - 0.5)) 
			* SIGN(1- SIGN(@current_date - a.date_aging - @age_brk4 ))
			* ROUND(a.amt_net * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) ), @precision_home)),

		SUM(SIGN(1 + SIGN(@current_date - a.date_aging - @age_brk4 - 0.5)) 
			* SIGN(1- SIGN(@current_date - a.date_aging - @age_brk5 ))
			* ROUND(a.amt_net * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) ), @precision_home)),

		SUM(SIGN(1 + SIGN(@current_date - a.date_aging - @age_brk5 - 0.5)) 
			* ROUND( a.amt_net * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) ), @precision_home)),

		SUM(SIGN(1- SIGN( @current_date - a.date_aging - @age_brk1 )) 
			* ROUND( a.amt_net * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) ), @precision_oper)),

		SUM(SIGN(1 + SIGN(@current_date - a.date_aging - @age_brk1 - 0.5)) 
			* SIGN(1- SIGN(@current_date - a.date_aging - @age_brk2 ))
			* ROUND( a.amt_net * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) ), @precision_oper)),

		SUM(SIGN(1 + SIGN(@current_date - a.date_aging - @age_brk2 - 0.5)) 
			* SIGN(1- SIGN(@current_date - a.date_aging - @age_brk3 ))
			* ROUND( a.amt_net * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) ), @precision_oper)),

		SUM(SIGN(1 + SIGN(@current_date - a.date_aging - @age_brk3 - 0.5)) 
			* SIGN(1- SIGN(@current_date - a.date_aging - @age_brk4 ))
			* ROUND( a.amt_net * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) ), @precision_oper)),

		SUM(SIGN(1 + SIGN(@current_date - a.date_aging - @age_brk4 - 0.5)) 
			* SIGN(1- SIGN(@current_date - a.date_aging - @age_brk5 ))
			* ROUND( a.amt_net * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) ), @precision_oper)),

		SUM(SIGN(1 + SIGN(@current_date - a.date_aging - @age_brk5 - 0.5)) 
			* ROUND( a.amt_net * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) ), @precision_oper))

	FROM 	#apvochg_work a
		INNER JOIN #apvopto_work b ON a.vendor_code = b.vendor_code
	GROUP BY a.vendor_code

	UPDATE apactpto
	SET 
		amt_age_bracket1 = b.amt_age_bracket1 + a.age_bracket1 ,
		amt_age_bracket2 = b.amt_age_bracket2 + a.age_bracket2 ,
		amt_age_bracket3 = b.amt_age_bracket3 + a.age_bracket3 ,
	      	amt_age_bracket4 = b.amt_age_bracket4 + a.age_bracket4 ,
		amt_age_bracket5 = b.amt_age_bracket5 + a.age_bracket5 ,
		amt_age_bracket6 = b.amt_age_bracket6 + a.age_bracket6,
		amt_age_bracket1_oper = b.amt_age_bracket1_oper  + a.age_bracket1_oper ,
		amt_age_bracket2_oper = b.amt_age_bracket2_oper + a.age_bracket2_oper ,
		amt_age_bracket3_oper = b.amt_age_bracket3_oper + a.age_bracket3_oper ,
	      	amt_age_bracket4_oper = b.amt_age_bracket4_oper + a.age_bracket4_oper ,
		amt_age_bracket5_oper = b.amt_age_bracket5_oper + a.age_bracket5_oper ,
		amt_age_bracket6_oper = b.amt_age_bracket6_oper + a.age_bracket6_oper

	FROM @apvobracket_work a 
		INNER JOIN apactpto b ON a.wild_code = b.vendor_code



	DELETE @apvobracket_work



   END

IF @cls_flag = 1
   BEGIN


	  UPDATE apactcls
	  SET date_last_vouch = b.date_last_vouch,
	      amt_last_vouch = b.amt_last_vouch,
		  last_vouch_doc = b.last_vouch_doc,
		  last_vouch_cur = b.last_vouch_cur,
		  amt_balance = apactcls.amt_balance + b.amt_vouch,
		  amt_balance_oper = apactcls.amt_balance_oper + b.amt_vouch_oper,
		  amt_vouch_unposted = apactcls.amt_vouch_unposted - b.amt_vouch,
		  amt_vouch_unposted_oper = apactcls.amt_vouch_unposted_oper - b.amt_vouch_oper,
		  num_vouch = apactcls.num_vouch + b.num_vouch,
		  high_amt_ap = (sign((sign((apactcls.high_amt_ap) - (apactcls.amt_balance + b.amt_vouch) + 0.00000001) + 1)) * (apactcls.high_amt_ap) + sign((sign((apactcls.amt_balance + b.amt_vouch) - (apactcls.high_amt_ap) - 0.00000001) + 1)) * (apactcls.amt_balance + b.amt_vouch)),
		  high_amt_ap_oper = (sign((sign((apactcls.high_amt_ap_oper) - (apactcls.amt_balance_oper + b.amt_vouch_oper) + 0.00000001) + 1)) * (apactcls.high_amt_ap_oper) + sign((sign((apactcls.amt_balance_oper + b.amt_vouch_oper) - (apactcls.high_amt_ap_oper) - 0.00000001) + 1)) * (apactcls.amt_balance_oper + b.amt_vouch_oper)),
		  high_date_ap = (sign((sign((apactcls.high_amt_ap) - (apactcls.amt_balance + b.amt_vouch) + 0.00000001) + 1)) * (apactcls.high_date_ap) + sign((sign((apactcls.amt_balance + b.amt_vouch) - (apactcls.high_amt_ap) - 0.00000001) + 1)) * (@current_date))
	  FROM apactcls
		INNER JOIN #apvocls_work b ON apactcls.class_code = b.class_code




	  INSERT apactcls (
		class_code,    date_last_vouch,        date_last_dm,
		date_last_adj,  date_last_pyt,          date_last_void,
		amt_last_vouch, amt_last_dm,            amt_last_adj,
		amt_last_pyt,   amt_last_void,          amt_age_bracket1,
		amt_age_bracket2,amt_age_bracket3,      amt_age_bracket4,
		amt_age_bracket5,amt_age_bracket6,      amt_on_order,
		amt_vouch_unposted,last_vouch_doc,      last_dm_doc,
		last_adj_doc,   last_pyt_doc,           last_pyt_acct,
		last_void_doc,  last_void_acct,         high_amt_ap,
		high_amt_vouch, high_date_ap,           high_date_vouch,
		num_vouch,      num_vouch_paid,         num_overdue_pyt,
		avg_days_pay,   avg_days_overdue,       last_trx_time,
		amt_balance,	last_vouch_cur,			amt_vouch_unposted_oper,
		high_amt_ap_oper,	amt_balance_oper
		 )
	  SELECT  
		a.class_code,		a.date_last_vouch,        0,
		0,  				0,			        	0,
		a.amt_last_vouch, 	0,       		0.0,
		0.0,			   	0.0,          			0.0,
		0.0,				0.0,      				0.0,
		0.0,				0.0,      				0.0,
		0.0,				a.last_vouch_doc,      	'',
		'',   				'',           			'',
		'',  				'',         			a.amt_vouch,
		a.amt_vouch, 			@current_date,			@current_date,
		a.num_vouch, 			0,				        0,
		0,   				0,       				0,
		a.amt_vouch,			a.last_vouch_cur,			0.0,
		a.amt_vouch_oper,		a.amt_vouch_oper
	FROM  #apvocls_work a
		LEFT JOIN apactcls b ON a.class_code = b.class_code
	WHERE b.class_code IS NULL

		
	


	INSERT INTO @apvobracket_work
	SELECT a.class_code, 	  
		SUM(SIGN(1- SIGN( @current_date - a.date_aging - @age_brk1 )) 
			* ROUND(a.amt_net * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) ), @precision_home)),

 
		SUM(SIGN(1 + SIGN( @current_date - a.date_aging - @age_brk1 - 0.5)) 
			* SIGN(1- SIGN(@current_date - a.date_aging - @age_brk2 ))
			* ROUND(a.amt_net * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) ), @precision_home)),

		SUM(SIGN(1 + SIGN( @current_date - a.date_aging - @age_brk2 - 0.5)) 
			* SIGN(1- SIGN(@current_date - a.date_aging - @age_brk3 ))
			* ROUND(a.amt_net * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) ), @precision_home)),

		SUM(SIGN(1 + SIGN( @current_date - a.date_aging - @age_brk3 - 0.5)) 
			* SIGN(1- SIGN(@current_date - a.date_aging - @age_brk4 ))
			* ROUND(a.amt_net * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) ), @precision_home)),

		SUM(SIGN(1 + SIGN(@current_date - a.date_aging - @age_brk4 - 0.5)) 
			* SIGN(1- SIGN(@current_date - a.date_aging - @age_brk5 ))
			* ROUND(a.amt_net * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) ), @precision_home)),

		SUM(SIGN(1 + SIGN(@current_date - a.date_aging - @age_brk5 - 0.5)) 
			* ROUND( a.amt_net * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) ), @precision_home)),

		SUM(SIGN(1- SIGN( @current_date - a.date_aging - @age_brk1 )) 
			* ROUND( a.amt_net * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) ), @precision_oper)),

		SUM(SIGN(1 + SIGN(@current_date - a.date_aging - @age_brk1 - 0.5)) 
			* SIGN(1- SIGN(@current_date - a.date_aging - @age_brk2 ))
			* ROUND( a.amt_net * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) ), @precision_oper)),

		SUM(SIGN(1 + SIGN(@current_date - a.date_aging - @age_brk2 - 0.5)) 
			* SIGN(1- SIGN(@current_date - a.date_aging - @age_brk3 ))
			* ROUND( a.amt_net * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) ), @precision_oper)),

		SUM(SIGN(1 + SIGN(@current_date - a.date_aging - @age_brk3 - 0.5)) 
			* SIGN(1- SIGN(@current_date - a.date_aging - @age_brk4 ))
			* ROUND( a.amt_net * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) ), @precision_oper)),

		SUM(SIGN(1 + SIGN(@current_date - a.date_aging - @age_brk4 - 0.5)) 
			* SIGN(1- SIGN(@current_date - a.date_aging - @age_brk5 ))
			* ROUND( a.amt_net * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) ), @precision_oper)),

		SUM(SIGN(1 + SIGN(@current_date - a.date_aging - @age_brk5 - 0.5)) 
			* ROUND( a.amt_net * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) ), @precision_oper))

	FROM 	#apvochg_work a
		INNER JOIN #apvocls_work b ON a.class_code = b.class_code
	GROUP BY a.class_code

	UPDATE apactcls
	SET 
		amt_age_bracket1 = b.amt_age_bracket1 + a.age_bracket1 ,
		amt_age_bracket2 = b.amt_age_bracket2 + a.age_bracket2 ,
		amt_age_bracket3 = b.amt_age_bracket3 + a.age_bracket3 ,
	      	amt_age_bracket4 = b.amt_age_bracket4 + a.age_bracket4 ,
		amt_age_bracket5 = b.amt_age_bracket5 + a.age_bracket5 ,
		amt_age_bracket6 = b.amt_age_bracket6 + a.age_bracket6,
		amt_age_bracket1_oper = b.amt_age_bracket1_oper  + a.age_bracket1_oper ,
		amt_age_bracket2_oper = b.amt_age_bracket2_oper + a.age_bracket2_oper ,
		amt_age_bracket3_oper = b.amt_age_bracket3_oper + a.age_bracket3_oper ,
	      	amt_age_bracket4_oper = b.amt_age_bracket4_oper + a.age_bracket4_oper ,
		amt_age_bracket5_oper = b.amt_age_bracket5_oper + a.age_bracket5_oper ,
		amt_age_bracket6_oper = b.amt_age_bracket6_oper + a.age_bracket6_oper

	FROM @apvobracket_work a
		INNER JOIN apactcls b ON a.wild_code = b.class_code



	DELETE @apvobracket_work



   END

IF @bch_flag = 1
   BEGIN


	  UPDATE apactbch
	  SET date_last_vouch = b.date_last_vouch,
	      amt_last_vouch = b.amt_last_vouch,
		  last_vouch_doc = b.last_vouch_doc,
		  last_vouch_cur = b.last_vouch_cur,
		  amt_balance = apactbch.amt_balance + b.amt_vouch,
		  amt_balance_oper = apactbch.amt_balance_oper + b.amt_vouch_oper,
		  amt_vouch_unposted = apactbch.amt_vouch_unposted - b.amt_vouch,
		  amt_vouch_unposted_oper = apactbch.amt_vouch_unposted_oper - b.amt_vouch_oper,
		  num_vouch = apactbch.num_vouch + b.num_vouch,
		  high_amt_ap = (sign((sign((apactbch.high_amt_ap) - (apactbch.amt_balance + b.amt_vouch) + 0.00000001) + 1)) * (apactbch.high_amt_ap) + sign((sign((apactbch.amt_balance + b.amt_vouch) - (apactbch.high_amt_ap) - 0.00000001) + 1)) * (apactbch.amt_balance + b.amt_vouch)),
		  high_amt_ap_oper = (sign((sign((apactbch.high_amt_ap_oper) - (apactbch.amt_balance_oper + b.amt_vouch_oper) + 0.00000001) + 1)) * (apactbch.high_amt_ap_oper) + sign((sign((apactbch.amt_balance_oper + b.amt_vouch_oper) - (apactbch.high_amt_ap_oper) - 0.00000001) + 1)) * (apactbch.amt_balance_oper + b.amt_vouch_oper)),
		  high_date_ap = (sign((sign((apactbch.high_amt_ap) - (apactbch.amt_balance + b.amt_vouch) + 0.00000001) + 1)) * (apactbch.high_date_ap) + sign((sign((apactbch.amt_balance + b.amt_vouch) - (apactbch.high_amt_ap) - 0.00000001) + 1)) * (@current_date))
	  FROM apactbch
		INNER JOIN #apvobch_work b ON apactbch.branch_code = b.branch_code



	  INSERT apactbch (
		branch_code,    date_last_vouch,        date_last_dm,
		date_last_adj,  date_last_pyt,          date_last_void,
		amt_last_vouch, amt_last_dm,            amt_last_adj,
		amt_last_pyt,   amt_last_void,          amt_age_bracket1,
		amt_age_bracket2,amt_age_bracket3,      amt_age_bracket4,
		amt_age_bracket5,amt_age_bracket6,      amt_on_order,
		amt_vouch_unposted,last_vouch_doc,      last_dm_doc,
		last_adj_doc,   last_pyt_doc,           last_pyt_acct,
		last_void_doc,  last_void_acct,         high_amt_ap,
		high_amt_vouch, high_date_ap,           high_date_vouch,
		num_vouch,      num_vouch_paid,         num_overdue_pyt,
		avg_days_pay,   avg_days_overdue,       last_trx_time,
		amt_balance,	last_vouch_cur,			amt_vouch_unposted_oper,
		high_amt_ap_oper,	amt_balance_oper
		 )
	  SELECT 
		a.branch_code,		a.date_last_vouch,        0,
		0,  				0,			        	0,
		a.amt_last_vouch, 	0,       		0.0,
		0.0,			   	0.0,          			0.0,
		0.0,				0.0,      				0.0,
		0.0,				0.0,      				0.0,
		0.0,				a.last_vouch_doc,      	'',
		'',   				'',           			'',
		'',  				'',         			a.amt_vouch,
		a.amt_vouch,			@current_date,			@current_date,
		a.num_vouch, 			0,				        0,
		0,   				0,       				0,
		a.amt_vouch,			a.last_vouch_cur,			0.0,
		a.amt_vouch_oper,		a.amt_vouch_oper
	FROM  #apvobch_work a
		LEFT JOIN apactbch b ON a.branch_code = b.branch_code
	WHERE b.branch_code IS NULL

	



	INSERT INTO @apvobracket_work
	SELECT a.branch_code, 	  
		SUM(SIGN(1- SIGN( @current_date - a.date_aging - @age_brk1 )) 
			* ROUND(a.amt_net * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) ), @precision_home)),

 
		SUM(SIGN(1 + SIGN( @current_date - a.date_aging - @age_brk1 - 0.5)) 
			* SIGN(1- SIGN(@current_date - a.date_aging - @age_brk2 ))
			* ROUND(a.amt_net * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) ), @precision_home)),

		SUM(SIGN(1 + SIGN( @current_date - a.date_aging - @age_brk2 - 0.5)) 
			* SIGN(1- SIGN(@current_date - a.date_aging - @age_brk3 ))
			* ROUND(a.amt_net * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) ), @precision_home)),

		SUM(SIGN(1 + SIGN( @current_date - a.date_aging - @age_brk3 - 0.5)) 
			* SIGN(1- SIGN(@current_date - a.date_aging - @age_brk4 ))
			* ROUND(a.amt_net * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) ), @precision_home)),

		SUM(SIGN(1 + SIGN(@current_date - a.date_aging - @age_brk4 - 0.5)) 
			* SIGN(1- SIGN(@current_date - a.date_aging - @age_brk5 ))
			* ROUND(a.amt_net * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) ), @precision_home)),

		SUM(SIGN(1 + SIGN(@current_date - a.date_aging - @age_brk5 - 0.5)) 
			* ROUND( a.amt_net * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) ), @precision_home)),

		SUM(SIGN(1- SIGN( @current_date - a.date_aging - @age_brk1 )) 
			* ROUND( a.amt_net * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) ), @precision_oper)),

		SUM(SIGN(1 + SIGN(@current_date - a.date_aging - @age_brk1 - 0.5)) 
			* SIGN(1- SIGN(@current_date - a.date_aging - @age_brk2 ))
			* ROUND( a.amt_net * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) ), @precision_oper)),

		SUM(SIGN(1 + SIGN(@current_date - a.date_aging - @age_brk2 - 0.5)) 
			* SIGN(1- SIGN(@current_date - a.date_aging - @age_brk3 ))
			* ROUND( a.amt_net * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) ), @precision_oper)),

		SUM(SIGN(1 + SIGN(@current_date - a.date_aging - @age_brk3 - 0.5)) 
			* SIGN(1- SIGN(@current_date - a.date_aging - @age_brk4 ))
			* ROUND( a.amt_net * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) ), @precision_oper)),

		SUM(SIGN(1 + SIGN(@current_date - a.date_aging - @age_brk4 - 0.5)) 
			* SIGN(1- SIGN(@current_date - a.date_aging - @age_brk5 ))
			* ROUND( a.amt_net * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) ), @precision_oper)),

		SUM(SIGN(1 + SIGN(@current_date - a.date_aging - @age_brk5 - 0.5)) 
			* ROUND( a.amt_net * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) ), @precision_oper))

	FROM 	#apvochg_work a
		INNER JOIN #apvobch_work b ON a.branch_code = b.branch_code
	GROUP BY a.branch_code

	UPDATE apactbch
	SET 
		amt_age_bracket1 = b.amt_age_bracket1 + a.age_bracket1 ,
		amt_age_bracket2 = b.amt_age_bracket2 + a.age_bracket2 ,
		amt_age_bracket3 = b.amt_age_bracket3 + a.age_bracket3 ,
	      	amt_age_bracket4 = b.amt_age_bracket4 + a.age_bracket4 ,
		amt_age_bracket5 = b.amt_age_bracket5 + a.age_bracket5 ,
		amt_age_bracket6 = b.amt_age_bracket6 + a.age_bracket6,
		amt_age_bracket1_oper = b.amt_age_bracket1_oper  + a.age_bracket1_oper ,
		amt_age_bracket2_oper = b.amt_age_bracket2_oper + a.age_bracket2_oper ,
		amt_age_bracket3_oper = b.amt_age_bracket3_oper + a.age_bracket3_oper ,
	      	amt_age_bracket4_oper = b.amt_age_bracket4_oper + a.age_bracket4_oper ,
		amt_age_bracket5_oper = b.amt_age_bracket5_oper + a.age_bracket5_oper ,
		amt_age_bracket6_oper = b.amt_age_bracket6_oper + a.age_bracket6_oper

	FROM @apvobracket_work a
		INNER JOIN apactbch b ON a.wild_code = b.branch_code



	DELETE @apvobracket_work



   END


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvoupa.cpp" + ", line " + STR( 682, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[APVOUPActivity_sp] TO [public]
GO
