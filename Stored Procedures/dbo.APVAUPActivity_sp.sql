SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO










CREATE PROC [dbo].[APVAUPActivity_sp]
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

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvaupa.sp" + ", line " + STR( 55, 5 ) + " -- ENTRY: "


SELECT @vend_flag = apactvnd_flag,
		@pto_flag = apactpto_flag,
		@cls_flag = apactcls_flag,
		@bch_flag = apactbch_flag
FROM apco


IF @vend_flag = 1
 BEGIN


	 UPDATE apactvnd
	 SET date_last_adj = b.date_last_adj,
	 amt_last_adj = b.amt_last_adj,
		 last_adj_doc = b.last_adj_doc,
		 last_adj_cur = b.last_adj_cur
	 FROM apactvnd a, #apvavnd_work b
	 WHERE a.vendor_code = b.vendor_code

	 UPDATE #apvavnd_work
	 SET db_action = 1
	 FROM #apvavnd_work a, apactvnd b
	 WHERE a.vendor_code = b.vendor_code


	 INSERT apactvnd (		
		vendor_code,			date_last_vouch, date_last_dm,
		date_last_adj, 		date_last_pyt, date_last_void,
		amt_last_vouch, 		amt_last_dm, amt_last_adj,
		amt_last_pyt, 		amt_last_void, amt_age_bracket1,
		amt_age_bracket2,		amt_age_bracket3, 	amt_age_bracket4,
		amt_age_bracket5,		amt_age_bracket6, 	amt_on_order,
		amt_vouch_unposted,		last_vouch_doc, 	last_dm_doc,
		last_adj_doc, 		last_pyt_doc, last_pyt_acct,
		last_void_doc, 		last_void_acct, high_amt_ap,
		high_amt_vouch, 		high_date_ap, high_date_vouch,
		num_vouch, 		num_vouch_paid, 	num_overdue_pyt,
		avg_days_pay, 		avg_days_overdue, last_trx_time,
		amt_balance,
		last_vouch_cur,			last_dm_cur, 		last_adj_cur, 	 
		last_pyt_cur,			last_void_cur,		
		amt_age_bracket1_oper,	amt_age_bracket2_oper, amt_age_bracket3_oper,
		amt_age_bracket4_oper,	amt_age_bracket5_oper, amt_age_bracket6_oper,
		amt_balance_oper,		amt_on_order_oper, 		amt_vouch_unposted_oper, 
		high_amt_ap_oper )
	 SELECT 
		vendor_code,			0, 				0,
		date_last_adj,			0,			 	0,
		0.0, 					0.0,		 		amt_last_adj,
		0.0,				 	0.0, 			0.0,
		0.0,					0.0, 				0.0,
		0.0,					0.0, 				0.0,
		0.0,					'', 				'',
		last_adj_doc,			'', 			'',
		'', 					'', 			0.0,
		0.0, 					0, 			0,
		0, 				0,				 0,
		0, 					0, 				0,
		0.0,
		'',						'', 				last_adj_cur, 	 
		'',						'',		
		0.0,					0.0, 					0.0,
		0.0,					0.0, 					0.0,
		0.0,					0.0, 					0.0,
		0.0
	FROM #apvavnd_work
	WHERE db_action = 0



 END


IF @pto_flag = 1
 BEGIN


	 UPDATE apactpto
	 SET date_last_adj = b.date_last_adj,
	 amt_last_adj = b.amt_last_adj,
		 last_adj_doc = b.last_adj_doc,
		 last_adj_cur = b.last_adj_cur
	 FROM apactpto a, #apvapto_work b
	 WHERE a.vendor_code = b.vendor_code
	 AND a.pay_to_code = b.pay_to_code

	 UPDATE #apvapto_work
	 SET db_action = 1
	 FROM #apvapto_work a, apactpto b
	 WHERE a.vendor_code = b.vendor_code
	 AND a.pay_to_code = b.pay_to_code


	 INSERT apactpto (		
		vendor_code, 		pay_to_code, 			date_last_vouch, date_last_dm,
		date_last_adj, 			date_last_pyt, date_last_void,
		amt_last_vouch, 		amt_last_dm, amt_last_adj,
		amt_last_pyt, 		amt_last_void, amt_age_bracket1,
		amt_age_bracket2,		amt_age_bracket3, 	amt_age_bracket4,
		amt_age_bracket5,		amt_age_bracket6, 	amt_on_order,
		amt_vouch_unposted,		last_vouch_doc, 	last_dm_doc,
		last_adj_doc, 		last_pyt_doc, last_pyt_acct,
		last_void_doc, 			last_void_acct, high_amt_ap,
		high_amt_vouch, 		high_date_ap, high_date_vouch,
		num_vouch, 		num_vouch_paid, num_overdue_pyt,
		avg_days_pay, 		avg_days_overdue, last_trx_time,
		amt_balance,
		last_vouch_cur,			last_dm_cur, 		last_adj_cur, 	 
		last_pyt_cur,			last_void_cur,		
		amt_age_bracket1_oper,	amt_age_bracket2_oper, amt_age_bracket3_oper,
		amt_age_bracket4_oper,	amt_age_bracket5_oper, amt_age_bracket6_oper,
		amt_balance_oper,		amt_on_order_oper, 		amt_vouch_unposted_oper, 
		high_amt_ap_oper )
	 
	 SELECT 
		vendor_code,			pay_to_code, 			0, 				0,
		date_last_adj,			0,			 	0,
		0.0, 					0.0, 		amt_last_adj,
		0.0,				 	0.0, 			0.0,
		0.0,					0.0, 				0.0,
		0.0,					0.0, 				0.0,
		0.0,					'', 				'',
		last_adj_doc,			'',				 '',
		'', 					'', 			0.0,
		0.0, 					0, 			0,
		0, 				0, 				 0,
		0,					 	0,					 0,
		0.0,
		'',						'', 				last_adj_cur, 	 
		'',						'',		
		0.0,					0.0, 					0.0,
		0.0,					0.0, 					0.0,
		0.0,					0.0, 					0.0,
		0.0
	FROM #apvapto_work
	WHERE db_action = 0



 END

IF @cls_flag = 1
 BEGIN


	 UPDATE apactcls
	 SET date_last_adj = b.date_last_adj,
	 amt_last_adj = b.amt_last_adj,
		 last_adj_doc = b.last_adj_doc,
		 last_adj_cur = b.last_adj_cur
	 FROM apactcls a, #apvacls_work b
	 WHERE a.class_code = b.class_code

	 UPDATE #apvacls_work
	 SET db_action = 1
	 FROM #apvacls_work a, apactcls b
	 WHERE a.class_code = b.class_code

	 INSERT apactcls (			
		class_code, 			date_last_vouch, date_last_dm,
		date_last_adj, 		date_last_pyt, date_last_void,
		amt_last_vouch, 		amt_last_dm, amt_last_adj,
		amt_last_pyt, 		amt_last_void, amt_age_bracket1,
		amt_age_bracket2,		amt_age_bracket3, 	amt_age_bracket4,
		amt_age_bracket5,		amt_age_bracket6, 	amt_on_order,
		amt_vouch_unposted,		last_vouch_doc, 	last_dm_doc,
		last_adj_doc, 		 	last_pyt_doc, last_pyt_acct,
		last_void_doc, 		 	last_void_acct, high_amt_ap,
		high_amt_vouch,		 	high_date_ap, high_date_vouch,
		num_vouch, 		num_vouch_paid, num_overdue_pyt,
		avg_days_pay, 		avg_days_overdue, last_trx_time,
		amt_balance,
		last_vouch_cur,			last_dm_cur, 		last_adj_cur, 	 
		last_pyt_cur,			last_void_cur,		
		amt_age_bracket1_oper,	amt_age_bracket2_oper, amt_age_bracket3_oper,
		amt_age_bracket4_oper,	amt_age_bracket5_oper, amt_age_bracket6_oper,
		amt_balance_oper,		amt_on_order_oper, 		amt_vouch_unposted_oper, 
		high_amt_ap_oper )
	 SELECT 
		class_code,				0, 						0,
		date_last_adj, 		0,			 	0,
		0.0, 					0.0,		 		amt_last_adj,
		0.0,				 	0.0, 			0.0,
		0.0,					0.0, 				0.0,
		0.0,					0.0, 				0.0,
		0.0,					'', 				'',
		last_adj_doc,			'', 			'',
		'', 					'', 			0.0,
		0.0, 					0, 			0,
		0, 				0, 				0,
		0, 					0, 				0,
		0.0,
		'',						'', 				last_adj_cur, 	 
		'',						'',		
		0.0,					0.0, 					0.0,
		0.0,					0.0, 					0.0,
		0.0,					0.0, 					0.0,
		0.0
	FROM #apvacls_work
	WHERE db_action = 0



 END

IF @bch_flag = 1
 BEGIN


	 UPDATE apactbch
	 SET date_last_adj = b.date_last_adj,
	 amt_last_adj = b.amt_last_adj,
		 last_adj_doc = b.last_adj_doc,
		 last_adj_cur = b.last_adj_cur
	 FROM apactbch a, #apvabch_work b
	 WHERE a.branch_code = b.branch_code

	 UPDATE #apvabch_work
	 SET db_action = 1
	 FROM #apvabch_work a, apactbch b
	 WHERE a.branch_code = b.branch_code

	 INSERT apactbch (			
		branch_code, 		date_last_vouch, date_last_dm,
		date_last_adj, 		date_last_pyt, date_last_void,
		amt_last_vouch, 		amt_last_dm, amt_last_adj,
		amt_last_pyt, 		amt_last_void, amt_age_bracket1,
		amt_age_bracket2,		amt_age_bracket3, 	amt_age_bracket4,
		amt_age_bracket5,		amt_age_bracket6, 	amt_on_order,
		amt_vouch_unposted,		last_vouch_doc, 	last_dm_doc,
		last_adj_doc, 		last_pyt_doc, last_pyt_acct,
		last_void_doc, 		last_void_acct, high_amt_ap,
		high_amt_vouch, 		high_date_ap, high_date_vouch,
		num_vouch, 		num_vouch_paid, num_overdue_pyt,
		avg_days_pay, 		avg_days_overdue, last_trx_time,
		amt_balance,
		last_vouch_cur,			last_dm_cur, 		last_adj_cur, 	 
		last_pyt_cur,			last_void_cur,		
		amt_age_bracket1_oper,	amt_age_bracket2_oper, amt_age_bracket3_oper,
		amt_age_bracket4_oper,	amt_age_bracket5_oper, amt_age_bracket6_oper,
		amt_balance_oper,		amt_on_order_oper, 		amt_vouch_unposted_oper, 
		high_amt_ap_oper )
	 SELECT 
		branch_code,			0, 				0,
		date_last_adj,			0,			 	0,
		0.0, 					0.0,		 		amt_last_adj,
		0.0,				 	0.0, 			0.0,
		0.0,					0.0, 				0.0,
		0.0,					0.0, 				0.0,
		0.0,					'', 				'',
		last_adj_doc, 			'',				 '',
		'', 					'', 			0.0,
		0.0, 					0, 			0,
		0, 				0, 				0,
		0, 					0, 				0,
		0.0,
		'',						'', 				last_adj_cur, 	 
		'',						'',		
		0.0,					0.0, 					0.0,
		0.0,					0.0, 					0.0,
		0.0,					0.0, 					0.0,
		0.0
	FROM #apvabch_work
	WHERE db_action = 0



 END



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvaupa.sp" + ", line " + STR( 329, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[APVAUPActivity_sp] TO [public]
GO
