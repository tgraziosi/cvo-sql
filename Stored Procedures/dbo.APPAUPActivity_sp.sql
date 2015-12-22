SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO









CREATE PROC [dbo].[APPAUPActivity_sp]
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

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/appaupa.sp" + ", line " + STR( 60, 5 ) + " -- ENTRY: "


SELECT @vend_flag = apactvnd_flag,
		@pto_flag = apactpto_flag,
		@cls_flag = apactcls_flag,
		@bch_flag = apactbch_flag
FROM apco


IF @vend_flag = 1
 BEGIN


	 UPDATE apactvnd
	 SET date_last_void = b.date_last_void,
	 amt_last_void = b.amt_last_void,
		 last_void_doc = b.last_void_doc,
		 last_void_acct = b.last_void_acct,
		 last_void_cur = b.last_void_cur,
		 amt_balance = apactvnd.amt_balance + b.amt_void + b.amt_disc_voided,
		 amt_balance_oper = apactvnd.amt_balance_oper + b.amt_void_oper + b.amt_disc_voided_oper,
		 num_vouch_paid = apactvnd.num_vouch_paid + b.num_vouch_paid
	 FROM apactvnd, #appavnd_work b
	 WHERE apactvnd.vendor_code = b.vendor_code


	 UPDATE apactvnd
	 SET high_amt_ap = amt_balance,
		 high_amt_ap_oper = amt_balance_oper,
	 high_date_ap = date_last_void
	 WHERE ((amt_balance) > (high_amt_ap) + 0.0000001)

	 UPDATE #appavnd_work
	 SET db_action = 1
	 FROM #appavnd_work, apactvnd b
	 WHERE #appavnd_work.vendor_code = b.vendor_code


	 INSERT apactvnd (
		vendor_code,		date_last_vouch, date_last_dm,
		date_last_adj, 	date_last_pyt, date_last_void,
		amt_last_vouch, 	amt_last_dm, amt_last_adj,
		amt_last_pyt, 	amt_last_void, amt_age_bracket1,
		amt_age_bracket2,	amt_age_bracket3, 	amt_age_bracket4,
		amt_age_bracket5,	amt_age_bracket6, 	amt_on_order,
		amt_vouch_unposted,	last_vouch_doc, 	last_dm_doc,
		last_adj_doc, 	last_pyt_doc, last_pyt_acct,
		last_void_doc, 	last_void_acct, high_amt_ap,
		high_amt_vouch, 	high_date_ap, high_date_vouch,
		num_vouch, 	num_vouch_paid, num_overdue_pyt,
		avg_days_pay, 	avg_days_overdue, last_trx_time,
		amt_balance,
		last_vouch_cur,		last_dm_cur,			last_adj_cur,
		last_pyt_cur,		last_void_cur,			
		amt_age_bracket1_oper,	amt_age_bracket2_oper,	amt_age_bracket3_oper,
		amt_age_bracket4_oper,	amt_age_bracket5_oper,	amt_age_bracket6_oper,
		amt_on_order_oper,		amt_vouch_unposted_oper,high_amt_ap_oper,
		amt_balance_oper
		 )
	 SELECT 
		vendor_code,		0, 				0,
		0, 				0,			 	date_last_void,
		0.0, 				0.0, 		0.0,
		0.0,			 	amt_last_void, 			0.0,
		0.0,				0.0, 				0.0,
		0.0,				0.0, 				0.0,
		0.0,				'', 				'',
		'', 				'', 			'',
		last_void_doc, 	last_void_acct,			amt_void + amt_disc_voided,
		0.0, 				date_last_void,			0,
		0, 			0,						0,
		0, 				0, 				0,
		amt_void + amt_disc_voided,
		'',					'',						'',
		'',					last_void_cur,
		0.0,				0.0,					0.0,
		0.0,				0.0,					0.0,
		0.0,				0.0,					amt_void_oper + amt_disc_voided_oper,
		amt_void_oper + amt_disc_voided_oper

	FROM #appavnd_work
	WHERE db_action = 0



 END


IF @pto_flag = 1
 BEGIN


	 UPDATE apactpto
	 SET date_last_void = b.date_last_void,
	 amt_last_void = b.amt_last_void,
		 last_void_doc = b.last_void_doc,
		 last_void_acct = b.last_void_acct,
		 last_void_cur = b.last_void_cur,
		 amt_balance = apactpto.amt_balance + b.amt_void + b.amt_disc_voided,
		 amt_balance_oper = apactpto.amt_balance_oper + b.amt_void_oper + b.amt_disc_voided_oper,
		 num_vouch_paid = apactpto.num_vouch_paid + b.num_vouch_paid
	 FROM apactpto, #appapto_work b
	 WHERE apactpto.vendor_code = b.vendor_code
	 AND apactpto.pay_to_code = b.pay_to_code

	 UPDATE apactpto
	 SET high_amt_ap = amt_balance,
		 high_amt_ap_oper = amt_balance_oper,
	 high_date_ap = date_last_void
	 WHERE ((amt_balance) > (high_amt_ap) + 0.0000001)

	 UPDATE #appapto_work
	 SET db_action = 1
	 FROM #appapto_work, apactpto b
	 WHERE #appapto_work.vendor_code = b.vendor_code
	 AND #appapto_work.pay_to_code = b.pay_to_code


	 INSERT apactpto (
		vendor_code, pay_to_code, date_last_vouch, date_last_dm,
		date_last_adj, date_last_pyt, date_last_void,
		amt_last_vouch, amt_last_dm, amt_last_adj,
		amt_last_pyt, amt_last_void, amt_age_bracket1,
		amt_age_bracket2,amt_age_bracket3, amt_age_bracket4,
		amt_age_bracket5,amt_age_bracket6, amt_on_order,
		amt_vouch_unposted,last_vouch_doc, last_dm_doc,
		last_adj_doc, last_pyt_doc, last_pyt_acct,
		last_void_doc, last_void_acct, high_amt_ap,
		high_amt_vouch, high_date_ap, high_date_vouch,
		num_vouch, num_vouch_paid, num_overdue_pyt,
		avg_days_pay, avg_days_overdue, last_trx_time,
		amt_balance,
		last_vouch_cur,		last_dm_cur,			last_adj_cur,
		last_pyt_cur,		last_void_cur,			
		amt_age_bracket1_oper,	amt_age_bracket2_oper,	amt_age_bracket3_oper,
		amt_age_bracket4_oper,	amt_age_bracket5_oper,	amt_age_bracket6_oper,
		amt_on_order_oper,		amt_vouch_unposted_oper,high_amt_ap_oper,
		amt_balance_oper
		 )
	 SELECT 
		vendor_code,	pay_to_code, 0, 				0,
		0, 				0,			 	date_last_void,
		0.0, 				0.0, 		0.0,
		0.0,			 	amt_last_void, 			0.0,
		0.0,				0.0, 				0.0,
		0.0,				0.0, 				0.0,
		0.0,				'', 				'',
		'', 				'', 			'',
		last_void_doc, 	last_void_acct,			amt_void + amt_disc_voided,
		0.0, 				date_last_void,			0,
		0, 			0,						0,
		0, 				0, 				0,
		amt_void + amt_disc_voided,
		'',					'',						'',
		'',					last_void_cur,
		0.0,				0.0,					0.0,
		0.0,				0.0,					0.0,
		0.0,				0.0,					amt_void_oper + amt_disc_voided_oper,
		amt_void_oper + amt_disc_voided_oper
	FROM #appapto_work
	WHERE db_action = 0



 END

IF @cls_flag = 1
 BEGIN


	 UPDATE apactcls
	 SET date_last_void = b.date_last_void,
	 amt_last_void = b.amt_last_void,
		 last_void_doc = b.last_void_doc,
		 last_void_acct = b.last_void_acct,
		 last_void_cur = b.last_void_cur,
		 amt_balance = apactcls.amt_balance + b.amt_void + b.amt_disc_voided,
		 amt_balance_oper = apactcls.amt_balance_oper + b.amt_void_oper + b.amt_disc_voided_oper,
		 num_vouch_paid = apactcls.num_vouch_paid + b.num_vouch_paid
	 FROM apactcls, #appacls_work b
	 WHERE apactcls.class_code = b.class_code

	 UPDATE apactcls
	 SET high_amt_ap = amt_balance,
		 high_amt_ap_oper = amt_balance_oper,
	 high_date_ap = date_last_void
	 WHERE ((amt_balance) > (high_amt_ap) + 0.0000001)

	 UPDATE #appacls_work
	 SET db_action = 1
	 FROM #appacls_work, apactcls b
	 WHERE #appacls_work.class_code = b.class_code

	 INSERT apactcls (
		class_code, date_last_vouch, date_last_dm,
		date_last_adj, date_last_pyt, date_last_void,
		amt_last_vouch, amt_last_dm, amt_last_adj,
		amt_last_pyt, amt_last_void, amt_age_bracket1,
		amt_age_bracket2,amt_age_bracket3, amt_age_bracket4,
		amt_age_bracket5,amt_age_bracket6, amt_on_order,
		amt_vouch_unposted,last_vouch_doc, last_dm_doc,
		last_adj_doc, last_pyt_doc, last_pyt_acct,
		last_void_doc, last_void_acct, high_amt_ap,
		high_amt_vouch, high_date_ap, high_date_vouch,
		num_vouch, num_vouch_paid, num_overdue_pyt,
		avg_days_pay, avg_days_overdue, last_trx_time,
		amt_balance,
		last_vouch_cur,		last_dm_cur,			last_adj_cur,
		last_pyt_cur,		last_void_cur,			
		amt_age_bracket1_oper,	amt_age_bracket2_oper,	amt_age_bracket3_oper,
		amt_age_bracket4_oper,	amt_age_bracket5_oper,	amt_age_bracket6_oper,
		amt_on_order_oper,		amt_vouch_unposted_oper,high_amt_ap_oper,
		amt_balance_oper
		 )
	 SELECT 
		class_code,0, 				0,
		0, 				0,			 	date_last_void,
		0.0, 				0.0, 		0.0,
		0.0,			 	amt_last_void, 			0.0,
		0.0,				0.0, 				0.0,
		0.0,				0.0, 				0.0,
		0.0,				'', 				'',
		'', 				'', 			'',
		last_void_doc, 	last_void_acct,			amt_void + amt_disc_voided,
		0.0, 				date_last_void,			0,
		0, 			0,						0,
		0, 				0, 				0,
		amt_void + amt_disc_voided,
		'',					'',						'',
		'',					last_void_cur,
		0.0,				0.0,					0.0,
		0.0,				0.0,					0.0,
		0.0,				0.0,					amt_void_oper + amt_disc_voided_oper,
		amt_void_oper + amt_disc_voided_oper
	FROM #appacls_work
	WHERE db_action = 0



 END

IF @bch_flag = 1
 BEGIN


	 UPDATE apactbch
	 SET date_last_void = b.date_last_void,
	 amt_last_void = b.amt_last_void,
		 last_void_doc = b.last_void_doc,
		 last_void_acct = b.last_void_acct,
		 last_void_cur = b.last_void_cur,
		 amt_balance = apactbch.amt_balance + b.amt_void + b.amt_disc_voided,
		 amt_balance_oper = apactbch.amt_balance_oper + b.amt_void_oper + b.amt_disc_voided_oper,
		 num_vouch_paid = apactbch.num_vouch_paid + b.num_vouch_paid
	 FROM apactbch, #appabch_work b
	 WHERE apactbch.branch_code = b.branch_code
	 AND db_action = 1

	 UPDATE apactbch
	 SET high_amt_ap = amt_balance,
		 high_amt_ap_oper = amt_balance_oper,
	 high_date_ap = date_last_void
	 WHERE ((amt_balance) > (high_amt_ap) + 0.0000001)

	 UPDATE #appabch_work
	 SET db_action = 1
	 FROM #appabch_work, apactbch b
	 WHERE #appabch_work.branch_code = b.branch_code


	 INSERT apactbch (
		branch_code, date_last_vouch, date_last_dm,
		date_last_adj, date_last_pyt, date_last_void,
		amt_last_vouch, amt_last_dm, amt_last_adj,
		amt_last_pyt, amt_last_void, amt_age_bracket1,
		amt_age_bracket2,amt_age_bracket3, amt_age_bracket4,
		amt_age_bracket5,amt_age_bracket6, amt_on_order,
		amt_vouch_unposted,last_vouch_doc, last_dm_doc,
		last_adj_doc, last_pyt_doc, last_pyt_acct,
		last_void_doc, last_void_acct, high_amt_ap,
		high_amt_vouch, high_date_ap, high_date_vouch,
		num_vouch, num_vouch_paid, num_overdue_pyt,
		avg_days_pay, avg_days_overdue, last_trx_time,
		amt_balance,
		last_vouch_cur,		last_dm_cur,			last_adj_cur,
		last_pyt_cur,		last_void_cur,			
		amt_age_bracket1_oper,	amt_age_bracket2_oper,	amt_age_bracket3_oper,
		amt_age_bracket4_oper,	amt_age_bracket5_oper,	amt_age_bracket6_oper,
		amt_on_order_oper,		amt_vouch_unposted_oper,high_amt_ap_oper,
		amt_balance_oper
		 )
	 SELECT 
		branch_code,		0, 				0,
		0, 				0,			 	date_last_void,
		0.0, 				0.0, 		0.0,
		0.0,			 	amt_last_void, 			0.0,
		0.0,				0.0, 				0.0,
		0.0,				0.0, 				0.0,
		0.0,				'', 				'',
		'', 				'', 			'',
		last_void_doc, 	last_void_acct,			amt_void + amt_disc_voided,
		0.0, 				date_last_void,			0,
		0, 			0,				 0,
		0, 				0, 				0,
		amt_void + amt_disc_voided,
		'',					'',						'',
		'',					last_void_cur,
		0.0,				0.0,					0.0,
		0.0,				0.0,					0.0,
		0.0,				0.0,					amt_void_oper + amt_disc_voided_oper,
		amt_void_oper + amt_disc_voided_oper
	FROM #appabch_work
	WHERE db_action = 0



 END



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/appaupa.sp" + ", line " + STR( 381, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[APPAUPActivity_sp] TO [public]
GO
