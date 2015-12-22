SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO









CREATE PROC [dbo].[APPYUPActivity_sp]
											@batch_ctrl_num		varchar(16),
											@client_id 			varchar(20),
											@user_id			int,  
											@debug_level		smallint = 0
AS

   DECLARE
      @vend_flag smallint,
	  @pto_flag smallint,
	  @cls_flag smallint,     
	  @bch_flag smallint

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appyupa.cpp" + ", line " + STR( 60, 5 ) + " -- ENTRY: "


SELECT  @vend_flag = apactvnd_flag,
		@pto_flag = apactpto_flag,
		@cls_flag = apactcls_flag,
		@bch_flag = apactbch_flag
FROM    apco


IF @vend_flag = 1
   BEGIN

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appyupa.cpp" + ", line " + STR( 73, 5 ) + " -- MSG: " + "Update vendor activity"
	

	  UPDATE apactvnd
	  SET date_last_pyt = b.date_last_pyt,
 	      amt_last_pyt = b.amt_last_pyt,
		  last_pyt_doc = b.last_pyt_doc,
		  last_pyt_acct = b.last_pyt_acct,
		  last_pyt_cur = b.last_pyt_cur,
		  amt_balance = apactvnd.amt_balance - b.amt_pyt - b.amt_disc_taken,
		  amt_balance_oper = apactvnd.amt_balance_oper - b.amt_pyt_oper - b.amt_disc_taken_oper,
		  num_vouch_paid = apactvnd.num_vouch_paid + b.num_vouch_paid,
		  num_overdue_pyt = apactvnd.num_overdue_pyt + b.num_overdue_pyt
	  FROM apactvnd
		INNER JOIN #appyvnd_work b ON apactvnd.vendor_code = b.vendor_code

	  UPDATE apactvnd
	  	SET	  avg_days_pay = (apactvnd.avg_days_pay * apactvnd.num_vouch_paid + b.days_pay)/(apactvnd.num_vouch_paid + b.num_vouch_paid)
	  FROM apactvnd
		INNER JOIN #appyvnd_work b ON apactvnd.vendor_code = b.vendor_code
	  WHERE apactvnd.num_vouch_paid + b.num_vouch_paid != 0

	  UPDATE apactvnd
	  	SET	  avg_days_overdue = (apactvnd.avg_days_overdue * apactvnd.num_overdue_pyt + b.days_overdue)/(apactvnd.num_overdue_pyt + b.num_overdue_pyt)
	  FROM apactvnd
		INNER JOIN #appyvnd_work b ON apactvnd.vendor_code = b.vendor_code
	  WHERE apactvnd.num_overdue_pyt + b.num_overdue_pyt != 0




	  UPDATE wrk
	  SET wrk.days_pay = wrk.days_pay / wrk.num_vouch_paid
	  FROM #appyvnd_work wrk
		LEFT JOIN apactvnd b ON wrk.vendor_code = b.vendor_code 
	  WHERE wrk.num_vouch_paid != 0 AND b.vendor_code IS NULL
	  

	  UPDATE wrk
	  SET wrk.days_overdue = wrk.days_overdue / wrk.num_overdue_pyt
	  FROM #appyvnd_work wrk
		LEFT JOIN apactvnd b ON wrk.vendor_code = b.vendor_code 
	  WHERE wrk.num_overdue_pyt != 0 AND b.vendor_code IS NULL


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
		wrk.vendor_code,		0,        				0,
		0,  				wrk.date_last_pyt,        	0,
		0.0, 				0.0,            		0.0,
		wrk.amt_last_pyt,   	0.0,          			0.0,
		0.0,				0.0,      				0.0,
		0.0,				0.0,      				0.0,
		0.0,				'',      				'',
		'',   				wrk.last_pyt_doc,           wrk.last_pyt_acct,
		'',  				'',         			0.0,
		0.0, 				0,           			0,
		0,      			wrk.num_vouch_paid,         wrk.num_overdue_pyt,
		wrk.days_pay,			wrk.days_overdue,       0,
		-(wrk.amt_pyt + wrk.amt_disc_taken),
		'',					'',						'',
		wrk.last_pyt_cur,		'',
		0.0,				0.0,					0.0,
		0.0,				0.0,					0.0,
		0.0,				0.0,					0.0,
		-(wrk.amt_pyt_oper + wrk.amt_disc_taken_oper)
	FROM  #appyvnd_work wrk
		LEFT JOIN apactvnd b ON wrk.vendor_code = b.vendor_code
	WHERE b.vendor_code IS NULL



   END


IF @pto_flag = 1
   BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appyupa.cpp" + ", line " + STR( 170, 5 ) + " -- MSG: " + "Update pay to activity"
	

	  UPDATE apactpto
	  SET date_last_pyt = b.date_last_pyt,
	      amt_last_pyt = b.amt_last_pyt,
		  last_pyt_doc = b.last_pyt_doc,
		  last_pyt_acct = b.last_pyt_acct,
		  last_pyt_cur = b.last_pyt_cur,
		  amt_balance = apactpto.amt_balance - b.amt_pyt + b.amt_disc_taken,
		  amt_balance_oper = apactpto.amt_balance_oper - b.amt_pyt_oper - b.amt_disc_taken_oper,
		  num_vouch_paid = apactpto.num_vouch_paid + b.num_vouch_paid,
		  num_overdue_pyt = apactpto.num_overdue_pyt + b.num_overdue_pyt
	  FROM apactpto
		INNER JOIN #appypto_work b ON apactpto.vendor_code = b.vendor_code AND apactpto.pay_to_code = b.pay_to_code


	  UPDATE apactpto
	  	SET	  avg_days_pay = (apactpto.avg_days_pay * apactpto.num_vouch_paid + b.days_pay)/(apactpto.num_vouch_paid + b.num_vouch_paid)
	  FROM apactpto
		INNER JOIN #appypto_work b ON apactpto.vendor_code = b.vendor_code AND apactpto.pay_to_code = b.pay_to_code
	  WHERE apactpto.num_vouch_paid + b.num_vouch_paid != 0

	  UPDATE apactpto
	  	SET	  avg_days_overdue = (apactpto.avg_days_overdue * apactpto.num_overdue_pyt + b.days_overdue)/(apactpto.num_overdue_pyt + b.num_overdue_pyt)
	  FROM apactpto
		INNER JOIN #appypto_work b ON apactpto.vendor_code = b.vendor_code AND apactpto.pay_to_code = b.pay_to_code
	  WHERE apactpto.num_overdue_pyt + b.num_overdue_pyt != 0


	  UPDATE wrk
	  SET wrk.days_pay = wrk.days_pay / wrk.num_vouch_paid
	  FROM #appypto_work wrk
		LEFT JOIN apactpto b ON wrk.vendor_code = b.vendor_code AND wrk.pay_to_code = b.pay_to_code
	  WHERE wrk.num_vouch_paid != 0 AND b.pay_to_code IS NULL

	  UPDATE wrk
	  SET wrk.days_overdue = wrk.days_overdue / wrk.num_overdue_pyt
	  FROM #appypto_work wrk
		LEFT JOIN apactpto b ON wrk.vendor_code = b.vendor_code AND wrk.pay_to_code = b.pay_to_code
	  WHERE wrk.num_overdue_pyt != 0 AND b.pay_to_code IS NULL


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
		amt_balance,
		last_vouch_cur,		last_dm_cur,			last_adj_cur,
		last_pyt_cur,		last_void_cur,			
		amt_age_bracket1_oper,	amt_age_bracket2_oper,	amt_age_bracket3_oper,
		amt_age_bracket4_oper,	amt_age_bracket5_oper,	amt_age_bracket6_oper,
		amt_on_order_oper,		amt_vouch_unposted_oper,high_amt_ap_oper,
		amt_balance_oper
		 )
	  SELECT  
		wrk.vendor_code,	wrk.pay_to_code, 0,        				0,
		0,  				wrk.date_last_pyt,        	0,
		0.0, 				0.0,            		0.0,
		wrk.amt_last_pyt,   	0.0,          			0.0,
		0.0,				0.0,      				0.0,
		0.0,				0.0,      				0.0,
		0.0,				'',      				'',
		'',   				wrk.last_pyt_doc,           wrk.last_pyt_acct,
		'',  				'',         			0.0,
		0.0, 				0,           			0,
		0,      			wrk.num_vouch_paid,         wrk.num_overdue_pyt,
		wrk.days_pay,			wrk.days_overdue,       0,
		-(wrk.amt_pyt + wrk.amt_disc_taken),
		'',					'',						'',
		wrk.last_pyt_cur,		'',
		0.0,				0.0,					0.0,
		0.0,				0.0,					0.0,
		0.0,				0.0,					0.0,
		-(wrk.amt_pyt_oper + wrk.amt_disc_taken_oper)

	FROM  #appypto_work wrk
		LEFT JOIN apactpto b ON wrk.vendor_code = b.vendor_code AND wrk.pay_to_code = b.pay_to_code
	WHERE  b.pay_to_code IS NULL



   END

IF @cls_flag = 1
   BEGIN

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appyupa.cpp" + ", line " + STR( 266, 5 ) + " -- MSG: " + "Update class activity"
	

	  UPDATE apactcls
	  SET date_last_pyt = b.date_last_pyt,
	      amt_last_pyt = b.amt_last_pyt,
		  last_pyt_doc = b.last_pyt_doc,
		  last_pyt_acct = b.last_pyt_acct,
		  last_pyt_cur = b.last_pyt_cur,
		  amt_balance = apactcls.amt_balance - b.amt_pyt - b.amt_disc_taken,
		  amt_balance_oper = apactcls.amt_balance_oper - b.amt_pyt_oper - b.amt_disc_taken_oper,
		  num_vouch_paid = apactcls.num_vouch_paid + b.num_vouch_paid,
		  num_overdue_pyt = apactcls.num_overdue_pyt + b.num_overdue_pyt
	  FROM apactcls
		INNER JOIN #appycls_work b ON apactcls.class_code = b.class_code

	  UPDATE apactcls
	  	SET	  avg_days_pay = (apactcls.avg_days_pay * apactcls.num_vouch_paid + b.days_pay)/(apactcls.num_vouch_paid + b.num_vouch_paid)
	  FROM apactcls
		INNER JOIN #appycls_work b ON apactcls.class_code = b.class_code
	  WHERE apactcls.num_vouch_paid + b.num_vouch_paid != 0

	  UPDATE apactcls
	  	SET	  avg_days_overdue = (apactcls.avg_days_overdue * apactcls.num_overdue_pyt + b.days_overdue)/(apactcls.num_overdue_pyt + b.num_overdue_pyt)
	  FROM apactcls
		INNER JOIN #appycls_work b ON apactcls.class_code = b.class_code
	  WHERE apactcls.num_overdue_pyt + b.num_overdue_pyt != 0



	  UPDATE wrk
	  SET wrk.days_pay = wrk.days_pay / wrk.num_vouch_paid
	  FROM #appycls_work wrk
		LEFT JOIN apactcls b ON wrk.class_code = b.class_code
	  WHERE wrk.num_vouch_paid != 0 AND b.class_code IS NULL


	  UPDATE wrk
	  SET wrk.days_overdue = wrk.days_overdue / wrk.num_overdue_pyt
	  FROM #appycls_work wrk
		LEFT JOIN apactcls b ON wrk.class_code = b.class_code
	  WHERE wrk.num_overdue_pyt != 0 AND b.class_code IS NULL



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
		amt_balance,
		last_vouch_cur,		last_dm_cur,			last_adj_cur,
		last_pyt_cur,		last_void_cur,			
		amt_age_bracket1_oper,	amt_age_bracket2_oper,	amt_age_bracket3_oper,
		amt_age_bracket4_oper,	amt_age_bracket5_oper,	amt_age_bracket6_oper,
		amt_on_order_oper,		amt_vouch_unposted_oper,high_amt_ap_oper,
		amt_balance_oper
		 )
	  SELECT 
		wrk.class_code,			0,        				0,
		0,  				wrk.date_last_pyt,        	0,
		0.0, 				0.0,            		0.0,
		wrk.amt_last_pyt,   	0.0,          			0.0,
		0.0,				0.0,      				0.0,
		0.0,				0.0,      				0.0,
		0.0,				'',      				'',
		'',   				wrk.last_pyt_doc,           wrk.last_pyt_acct,
		'',  				'',         			0.0,
		0.0, 				0,           			0,
		0,      			wrk.num_vouch_paid,         wrk.num_overdue_pyt,
		wrk.days_pay,			wrk.days_overdue,       0,
		-(wrk.amt_pyt + wrk.amt_disc_taken),
		'',					'',						'',
		wrk.last_pyt_cur,		'',
		0.0,				0.0,					0.0,
		0.0,				0.0,					0.0,
		0.0,				0.0,					0.0,
		-(wrk.amt_pyt_oper + wrk.amt_disc_taken_oper)

    FROM #appycls_work wrk
		LEFT JOIN apactcls b ON wrk.class_code = b.class_code
	WHERE b.class_code IS NULL



   END

IF @bch_flag = 1
   BEGIN

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appyupa.cpp" + ", line " + STR( 364, 5 ) + " -- MSG: " + "Update branch activity"
	

	  UPDATE apactbch
	  SET date_last_pyt = b.date_last_pyt,
	      amt_last_pyt = b.amt_last_pyt,
		  last_pyt_doc = b.last_pyt_doc,
		  last_pyt_acct = b.last_pyt_acct,
		  last_pyt_cur = b.last_pyt_cur,
		  amt_balance = apactbch.amt_balance - b.amt_pyt - b.amt_disc_taken,
		  amt_balance_oper = apactbch.amt_balance_oper - b.amt_pyt_oper - b.amt_disc_taken_oper,
		  num_vouch_paid = apactbch.num_vouch_paid + b.num_vouch_paid,
		  num_overdue_pyt = apactbch.num_overdue_pyt + b.num_overdue_pyt
	  FROM apactbch
		INNER JOIN #appybch_work b ON apactbch.branch_code = b.branch_code

	  UPDATE apactbch
	  	SET	  avg_days_pay = (apactbch.avg_days_pay * apactbch.num_vouch_paid + b.days_pay)/(apactbch.num_vouch_paid + b.num_vouch_paid)
	  FROM apactbch
		INNER JOIN #appybch_work b ON apactbch.branch_code = b.branch_code
	  WHERE apactbch.num_vouch_paid + b.num_vouch_paid != 0

	  UPDATE apactbch
	  	SET	  avg_days_overdue = (apactbch.avg_days_overdue * apactbch.num_overdue_pyt + b.days_overdue)/(apactbch.num_overdue_pyt + b.num_overdue_pyt)
	  FROM apactbch
		INNER JOIN #appybch_work b ON apactbch.branch_code = b.branch_code
	  WHERE apactbch.num_overdue_pyt + b.num_overdue_pyt != 0


	  UPDATE wrk
	  SET wrk.days_pay = wrk.days_pay / wrk.num_vouch_paid
	  FROM #appybch_work wrk
		LEFT JOIN apactbch b ON wrk.branch_code = b.branch_code
	  WHERE wrk.num_vouch_paid != 0 AND b.branch_code IS NULL


	  UPDATE wrk
	  SET wrk.days_overdue = wrk.days_overdue / wrk.num_overdue_pyt
	  FROM #appybch_work wrk
		LEFT JOIN apactbch b ON wrk.branch_code = b.branch_code
	  WHERE wrk.num_overdue_pyt != 0 AND b.branch_code IS NULL



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
		amt_balance,
		last_vouch_cur,		last_dm_cur,			last_adj_cur,
		last_pyt_cur,		last_void_cur,			
		amt_age_bracket1_oper,	amt_age_bracket2_oper,	amt_age_bracket3_oper,
		amt_age_bracket4_oper,	amt_age_bracket5_oper,	amt_age_bracket6_oper,
		amt_on_order_oper,		amt_vouch_unposted_oper,high_amt_ap_oper,
		amt_balance_oper
		 )
	  SELECT  
		wrk.branch_code,	0,        				0,
		0,  				wrk.date_last_pyt,        	0,
		0.0, 				0.0,            		0.0,
		wrk.amt_last_pyt,   	0.0,          			0.0,
		0.0,				0.0,      				0.0,
		0.0,				0.0,      				0.0,
		0.0,				'',      				'',
		'',   				wrk.last_pyt_doc,           wrk.last_pyt_acct,
		'',  				'',         			0.0,
		0.0, 				0,           			0,
		0,      			wrk.num_vouch_paid,         wrk.num_overdue_pyt,
		wrk.days_pay,			wrk.days_overdue,       0,
		-(wrk.amt_pyt + wrk.amt_disc_taken),
		'',					'',						'',
		wrk.last_pyt_cur,		'',
		0.0,				0.0,					0.0,
		0.0,				0.0,					0.0,
		0.0,				0.0,					0.0,
		-(wrk.amt_pyt_oper + wrk.amt_disc_taken_oper)

	  FROM #appybch_work wrk
		LEFT JOIN apactbch b ON wrk.branch_code = b.branch_code
	  WHERE b.branch_code IS NULL



   END



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appyupa.cpp" + ", line " + STR( 460, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[APPYUPActivity_sp] TO [public]
GO
