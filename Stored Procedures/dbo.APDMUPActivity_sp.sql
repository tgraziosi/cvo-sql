SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO










CREATE PROC [dbo].[APDMUPActivity_sp]
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

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdmupa.cpp" + ", line " + STR( 55, 5 ) + " -- ENTRY: "


SELECT  @vend_flag = apactvnd_flag,
		@pto_flag = apactpto_flag,
		@cls_flag = apactcls_flag,
		@bch_flag = apactbch_flag
FROM    apco


IF @vend_flag = 1
   BEGIN

	  UPDATE apactvnd
	  SET date_last_dm = b.date_last_dm,
	      amt_last_dm = b.amt_last_dm,
		  last_dm_doc = b.last_dm_doc,
		  last_dm_cur = b.last_dm_cur,
		  amt_balance = apactvnd.amt_balance + b.amt_balance,
		  amt_balance_oper = apactvnd.amt_balance_oper + b.amt_balance_oper
	  FROM apactvnd
		INNER JOIN #apdmvnd_work b ON apactvnd.vendor_code = b.vendor_code




	  INSERT apactvnd (
		vendor_code,			date_last_vouch,        date_last_dm,
		date_last_adj,  		date_last_pyt,          date_last_void,
		amt_last_vouch, 		amt_last_dm,            amt_last_adj,
		amt_last_pyt,   		amt_last_void,          amt_age_bracket1,
		amt_age_bracket2,		amt_age_bracket3,      	amt_age_bracket4,
		amt_age_bracket5,		amt_age_bracket6,      	amt_on_order,
		amt_vouch_unposted,		last_vouch_doc,      	last_dm_doc,
		last_adj_doc,   		last_pyt_doc,           last_pyt_acct,
		last_void_doc,  		last_void_acct,         high_amt_ap,
		high_amt_vouch, 		high_date_ap,           high_date_vouch,
		num_vouch,      		num_vouch_paid,         num_overdue_pyt,
		avg_days_pay,   		avg_days_overdue,       last_trx_time,
		amt_balance,
		last_vouch_cur,			last_dm_cur,       		last_adj_cur,   	    
		last_pyt_cur,			last_void_cur,		
		amt_age_bracket1_oper,	amt_age_bracket2_oper,  amt_age_bracket3_oper,
		amt_age_bracket4_oper,	amt_age_bracket5_oper,  amt_age_bracket6_oper,
		amt_balance_oper,		amt_on_order_oper, 		amt_vouch_unposted_oper, 
		high_amt_ap_oper )
	  SELECT  
		wrk.vendor_code,			0,        				wrk.date_last_dm,
		0,  					0,			        	0,
		0.0, 					wrk.amt_last_dm,       		0.0,
		0.0,				   	0.0,          			0.0,
		0.0,					0.0,      				0.0,
		0.0,					0.0,      				0.0,
		0.0,					'',      				wrk.last_dm_doc,
		'',   					'',           			'',
		'',  					'',         			0.0,
		0.0, 					0,           			0,
		0,      				0,				        0,
		0,   					0,       				0,
		wrk.amt_balance,
		'',						wrk.last_dm_cur,       		'',   	    
		'',						'',		
		0.0,					0.0,   					0.0,
		0.0,					0.0,   					0.0,
		wrk.amt_balance_oper,		0.0,   					0.0,
		0.0

	FROM #apdmvnd_work wrk
		LEFT JOIN apactvnd b ON wrk.vendor_code = b.vendor_code
	WHERE b.vendor_code IS NULL

   END


IF @pto_flag = 1
   BEGIN


	  UPDATE apactpto
	  SET date_last_dm = b.date_last_dm,
	      amt_last_dm = b.amt_last_dm,
		  last_dm_doc = b.last_dm_doc,
		  last_dm_cur = b.last_dm_cur,
		  amt_balance = apactpto.amt_balance + b.amt_balance,
		  amt_balance_oper = apactpto.amt_balance_oper + b.amt_balance_oper
	  FROM apactpto
		INNER JOIN #apdmpto_work b ON apactpto.vendor_code = b.vendor_code AND apactpto.pay_to_code = b.pay_to_code




	  INSERT apactpto ( 
		vendor_code,    		pay_to_code,  			date_last_vouch,        date_last_dm,
		date_last_adj,  		date_last_pyt,          date_last_void,
		amt_last_vouch, 		amt_last_dm,            amt_last_adj,
		amt_last_pyt,   		amt_last_void,          amt_age_bracket1,
		amt_age_bracket2,		amt_age_bracket3,      	amt_age_bracket4,
		amt_age_bracket5,		amt_age_bracket6,      	amt_on_order,
		amt_vouch_unposted,		last_vouch_doc,      	last_dm_doc,
		last_adj_doc,  			last_pyt_doc,           last_pyt_acct,
		last_void_doc,  		last_void_acct,         high_amt_ap,
		high_amt_vouch,	 		high_date_ap,           high_date_vouch,
		num_vouch,      		num_vouch_paid,         num_overdue_pyt,
		avg_days_pay,   		avg_days_overdue,       last_trx_time,
		amt_balance,
		last_vouch_cur,			last_dm_cur,       		last_adj_cur,   	    
		last_pyt_cur,			last_void_cur,		
		amt_age_bracket1_oper,	amt_age_bracket2_oper,  amt_age_bracket3_oper,
		amt_age_bracket4_oper,	amt_age_bracket5_oper,  amt_age_bracket6_oper,
		amt_balance_oper,		amt_on_order_oper, 		amt_vouch_unposted_oper, 
		high_amt_ap_oper )
	  SELECT  
		wrk.vendor_code,			wrk.pay_to_code, 			0,        				wrk.date_last_dm,
		0,  					0,			        	0,
		0.0, 					wrk.amt_last_dm,            0.0,
		0.0,			   		0.0,          			0.0,
		0.0,			  		0.0,      				0.0,
		0.0,					0.0,      				0.0,
		0.0,					'',      				wrk.last_dm_doc,
		'',   					'',				        '',
		'',  					'',         			0.0,
		0.0, 					0,           			0,
		0,      				0, 				        0,
		0,					   	0,					    0,
		wrk.amt_balance,
		'',						wrk.last_dm_cur,       		'',   	    
		'',						'',		
		0.0,					0.0,   					0.0,
		0.0,					0.0,   					0.0,
		wrk.amt_balance_oper,		0.0,   					0.0,
		0.0
	FROM #apdmpto_work wrk
		LEFT JOIN apactpto b ON wrk.vendor_code = b.vendor_code AND wrk.pay_to_code = b.pay_to_code
	WHERE b.pay_to_code IS NULL


   END

IF @cls_flag = 1
   BEGIN


	  UPDATE apactcls
	  SET date_last_dm = b.date_last_dm,
	      amt_last_dm = b.amt_last_dm,
		  last_dm_doc = b.last_dm_doc,
		  last_dm_cur = b.last_dm_cur,
		  amt_balance = apactcls.amt_balance + b.amt_balance,
		  amt_balance_oper = apactcls.amt_balance_oper + b.amt_balance_oper
	  FROM apactcls
		INNER JOIN #apdmcls_work b ON apactcls.class_code = b.class_code




	  INSERT apactcls ( 
		class_code,    			date_last_vouch,        date_last_dm,
		date_last_adj,  		date_last_pyt,          date_last_void,
		amt_last_vouch, 		amt_last_dm,            amt_last_adj,
		amt_last_pyt,   		amt_last_void,          amt_age_bracket1,
		amt_age_bracket2,		amt_age_bracket3,      	amt_age_bracket4,
		amt_age_bracket5,		amt_age_bracket6,      	amt_on_order,
		amt_vouch_unposted,		last_vouch_doc,      	last_dm_doc,
		last_adj_doc,   		last_pyt_doc,           last_pyt_acct,
		last_void_doc,  		last_void_acct,         high_amt_ap,
		high_amt_vouch, 		high_date_ap,           high_date_vouch,
		num_vouch,      		num_vouch_paid,         num_overdue_pyt,
		avg_days_pay,  			avg_days_overdue,       last_trx_time,
		amt_balance,
		last_vouch_cur,			last_dm_cur,       		last_adj_cur,   	    
		last_pyt_cur,			last_void_cur,		
		amt_age_bracket1_oper,	amt_age_bracket2_oper,	amt_age_bracket3_oper,
		amt_age_bracket4_oper,	amt_age_bracket5_oper,  amt_age_bracket6_oper,
		amt_balance_oper,		amt_on_order_oper, 		amt_vouch_unposted_oper, 
		high_amt_ap_oper )
	  SELECT  
		wrk.class_code,				0, 						wrk.date_last_dm,
		0,  					0,			        	0,
		0.0, 					wrk.amt_last_dm,       		0.0,
		0.0,				   	0.0,          			0.0,
		0.0,					0.0,      				0.0,
		0.0,					0.0,      				0.0,
		0.0,					'',      				wrk.last_dm_doc,
		'',   					'',           			'',
		'', 	 				'',         			0.0,
		0.0, 					0,           			0,
		0,      				0,         				0,
		0,   					0,       				0,
		wrk.amt_balance,
		'',						wrk.last_dm_cur,       		'',   	    
		'',						'',		
		0.0,					0.0,   					0.0,
		0.0,					0.0,   					0.0,
		wrk.amt_balance_oper,		0.0,   					0.0,
		0.0
	FROM #apdmcls_work wrk
		LEFT JOIN apactcls b ON wrk.class_code = b.class_code
	WHERE b.class_code IS NULL


   END

IF @bch_flag = 1
   BEGIN


	  UPDATE apactbch
	  SET date_last_dm = b.date_last_dm,
	      amt_last_dm = b.amt_last_dm,
		  last_dm_doc = b.last_dm_doc,
		  last_dm_cur = b.last_dm_cur,
		  amt_balance = apactbch.amt_balance + b.amt_balance,
		  amt_balance_oper = apactbch.amt_balance_oper + b.amt_balance_oper
	  FROM apactbch
		INNER JOIN #apdmbch_work b ON apactbch.branch_code = b.branch_code





	  INSERT apactbch ( 
		branch_code,    		date_last_vouch,        date_last_dm,
		date_last_adj,  		date_last_pyt,          date_last_void,
		amt_last_vouch, 		amt_last_dm,            amt_last_adj,
		amt_last_pyt,   		amt_last_void,          amt_age_bracket1,
		amt_age_bracket2,		amt_age_bracket3,     	amt_age_bracket4,
		amt_age_bracket5,		amt_age_bracket6,      	amt_on_order,
		amt_vouch_unposted,		last_vouch_doc,      	last_dm_doc,
		last_adj_doc,   		last_pyt_doc,           last_pyt_acct,
		last_void_doc,  		last_void_acct,         high_amt_ap,
		high_amt_vouch, 		high_date_ap,           high_date_vouch,
		num_vouch,      		num_vouch_paid,         num_overdue_pyt,
		avg_days_pay,   		avg_days_overdue,       last_trx_time,
		amt_balance,
		last_vouch_cur,			last_dm_cur,       		last_adj_cur,   	    
		last_pyt_cur,			last_void_cur,		
		amt_age_bracket1_oper,	amt_age_bracket2_oper,  amt_age_bracket3_oper,
		amt_age_bracket4_oper,	amt_age_bracket5_oper,  amt_age_bracket6_oper,
		amt_balance_oper,		amt_on_order_oper, 		amt_vouch_unposted_oper, 
		high_amt_ap_oper )
	  SELECT  
		wrk.branch_code,			0,        				wrk.date_last_dm,
		0,  					0,			        	0,
		0.0, 					wrk.amt_last_dm,       		0.0,
		0.0,				   	0.0,          			0.0,
		0.0,					0.0,      				0.0,
		0.0,					0.0,      				0.0,
		0.0,					'',      				wrk.last_dm_doc,
		'',   					'',				        '',
		'',  					'',         			0.0,
		0.0, 					0,           			0,
		0,      				0,         				0,
		0,   					0,       				0,
		wrk.amt_balance,
		'',						wrk.last_dm_cur,       		'',   	    
		'',						'',		
		0.0,					0.0,   					0.0,
		0.0,					0.0,   					0.0,
		wrk.amt_balance_oper,		0.0,   					0.0,
		0.0
	FROM #apdmbch_work wrk
		LEFT JOIN apactbch b ON wrk.branch_code = b.branch_code
	WHERE b.branch_code IS NULL


   END



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdmupa.cpp" + ", line " + STR( 324, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[APDMUPActivity_sp] TO [public]
GO
