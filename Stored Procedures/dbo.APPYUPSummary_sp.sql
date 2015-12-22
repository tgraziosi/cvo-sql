SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO









CREATE PROC [dbo].[APPYUPSummary_sp]
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
	@date_applied int,
	@period_start_date int,
	@period_end_date int


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appyups.cpp" + ", line " + STR( 64, 5 ) + " -- ENTRY: "


SELECT  @vend_flag = apsumvnd_flag,
		@pto_flag = apsumpto_flag,
		@cls_flag = apsumcls_flag,
		@bch_flag = apsumbch_flag
FROM    apco


SELECT @date_applied = date_applied
FROM batchctl
WHERE batch_ctrl_num = @batch_ctrl_num



SELECT @period_start_date = period_start_date,
	   @period_end_date = period_end_date
FROM glprd
WHERE @date_applied BETWEEN period_start_date AND period_end_date


IF @vend_flag = 1
   BEGIN

	  UPDATE apsumvnd
	  SET num_vouch_paid = apsumvnd.num_vouch_paid + b.num_vouch_paid,
	      num_pyt = apsumvnd.num_pyt + b.num_pyt,
		  num_overdue_pyt = apsumvnd.num_overdue_pyt + b.num_overdue_pyt,
		  amt_pyt = apsumvnd.amt_pyt + b.amt_pyt,
		  amt_pyt_oper = apsumvnd.amt_pyt_oper + b.amt_pyt_oper,
		  amt_disc_taken = apsumvnd.amt_disc_taken + b.amt_disc_taken,
		  amt_disc_taken_oper = apsumvnd.amt_disc_taken_oper + b.amt_disc_taken_oper 


	  FROM apsumvnd
		INNER JOIN #appyvnd_work b ON apsumvnd.vendor_code = b.vendor_code
	  WHERE @date_applied BETWEEN apsumvnd.date_from AND apsumvnd.date_thru


INSERT  apsumvnd( 
		vendor_code,    	date_from,      		date_thru,
		num_vouch,      	num_vouch_paid, 		num_dm,
		num_adj,        	num_pyt,        		num_overdue_pyt,
		num_void,       	amt_vouch,      		amt_dm,
		amt_adj,        	amt_pyt,        		amt_void,       
		amt_disc_given, 	amt_disc_taken, 		amt_disc_lost,
		amt_freight,    	amt_tax,        		avg_days_pay,
		avg_days_overdue, 	last_trx_time,			amt_vouch_oper,
		amt_dm_oper,		amt_adj_oper,			amt_pyt_oper,
		amt_void_oper,		amt_disc_given_oper,	amt_disc_taken_oper,
		amt_disc_lost_oper,	amt_freight_oper,		amt_tax_oper
		)
SELECT  wrk.vendor_code,		@period_start_date,     @period_end_date,
		0,      			wrk.num_vouch_paid, 		0,
		0,        			wrk.num_pyt,   				wrk.num_overdue_pyt,
		0,       			0.0,      				0.0,
		0.0,     			wrk.amt_pyt,   				0.0,       
		0.0,     			wrk.amt_disc_taken,			0.0,
		0.0,     			0.0,      				wrk.days_pay,
		wrk.days_overdue,		0,						0.0,
		0.0,				0.0,					wrk.amt_pyt_oper,
		0.0,				0.0,					wrk.amt_disc_taken_oper,
		0.0,				0.0,					0.0
	FROM #appyvnd_work wrk
		LEFT JOIN apsumvnd b ON wrk.vendor_code = b.vendor_code
	WHERE @date_applied BETWEEN b.date_from AND b.date_thru AND b.vendor_code IS NULL


   END


IF @pto_flag = 1
   BEGIN

	  UPDATE apsumpto
	  SET num_vouch_paid = apsumpto.num_vouch_paid + b.num_vouch_paid,
	      num_pyt	= apsumpto.num_pyt + b.num_pyt,
		  num_overdue_pyt = apsumpto.num_overdue_pyt + b.num_overdue_pyt,
		  amt_pyt = apsumpto.amt_pyt + b.amt_pyt,
		  amt_pyt_oper = apsumpto.amt_pyt_oper + b.amt_pyt_oper,
		  amt_disc_taken = apsumpto.amt_disc_taken + b.amt_disc_taken,
		  amt_disc_taken_oper = apsumpto.amt_disc_taken_oper + b.amt_disc_taken_oper 


	  FROM apsumpto
		INNER JOIN #appypto_work b ON apsumpto.vendor_code = b.vendor_code AND apsumpto.pay_to_code = b.pay_to_code
	  WHERE @date_applied BETWEEN apsumpto.date_from AND apsumpto.date_thru


INSERT  apsumpto( 
		vendor_code,pay_to_code, date_from,      	date_thru,
		num_vouch,      	num_vouch_paid, 		num_dm,
		num_adj,        	num_pyt,        		num_overdue_pyt,
		num_void,       	amt_vouch,      		amt_dm,
		amt_adj,        	amt_pyt,        		amt_void,       
		amt_disc_given, 	amt_disc_taken, 		amt_disc_lost,
		amt_freight,    	amt_tax,        		avg_days_pay,
		avg_days_overdue, 	last_trx_time,			amt_vouch_oper,
		amt_dm_oper,		amt_adj_oper,			amt_pyt_oper,
		amt_void_oper,		amt_disc_given_oper,	amt_disc_taken_oper,
		amt_disc_lost_oper,	amt_freight_oper,		amt_tax_oper
		)
SELECT  wrk.vendor_code,wrk.pay_to_code, @period_start_date,@period_end_date,
		0,      			wrk.num_vouch_paid, 		0,
		0,        			wrk.num_pyt,        		wrk.num_overdue_pyt,
		0,       			0.0,      				0.0,
		0.0,     			wrk.amt_pyt,   				0.0,       
		0.0,     			wrk.amt_disc_taken,			0.0,
		0.0,     			0.0,      				wrk.days_pay,
		wrk.days_overdue,		0,						0.0,
		0.0,				0.0,					wrk.amt_pyt_oper,
		0.0,				0.0,					wrk.amt_disc_taken_oper,
		0.0,				0.0,					0.0
	FROM #appypto_work wrk
		LEFT JOIN apsumpto b ON wrk.vendor_code = b.vendor_code AND wrk.pay_to_code = b.pay_to_code
	WHERE @date_applied BETWEEN b.date_from AND b.date_thru AND b.pay_to_code IS NULL

   END

IF @cls_flag = 1
   BEGIN


	  UPDATE apsumcls
	  SET num_vouch_paid = apsumcls.num_vouch_paid + b.num_vouch_paid,
	      num_pyt = apsumcls.num_pyt + b.num_pyt,
		  num_overdue_pyt = apsumcls.num_overdue_pyt + b.num_overdue_pyt,
		  amt_pyt = apsumcls.amt_pyt + b.amt_pyt,
		  amt_pyt_oper = apsumcls.amt_pyt_oper + b.amt_pyt_oper,
		  amt_disc_taken = apsumcls.amt_disc_taken + b.amt_disc_taken,
		  amt_disc_taken_oper = apsumcls.amt_disc_taken_oper + b.amt_disc_taken_oper 


	  FROM apsumcls
		INNER JOIN #appycls_work b ON apsumcls.class_code = b.class_code
	  WHERE @date_applied BETWEEN apsumcls.date_from AND apsumcls.date_thru


INSERT  apsumcls( 
		class_code,    		date_from,      		date_thru,
		num_vouch,      	num_vouch_paid, 		num_dm,
		num_adj,        	num_pyt,        		num_overdue_pyt,
		num_void,       	amt_vouch,      		amt_dm,
		amt_adj,        	amt_pyt,        		amt_void,       
		amt_disc_given, 	amt_disc_taken, 		amt_disc_lost,
		amt_freight,    	amt_tax,        		avg_days_pay,
		avg_days_overdue, 	last_trx_time,			amt_vouch_oper,
		amt_dm_oper,		amt_adj_oper,			amt_pyt_oper,
		amt_void_oper,		amt_disc_given_oper,	amt_disc_taken_oper,
		amt_disc_lost_oper,	amt_freight_oper,		amt_tax_oper
		)
SELECT  wrk.class_code,			@period_start_date,     @period_end_date,
		0,      			wrk.num_vouch_paid, 		0,
		0,        			wrk.num_pyt,        		wrk.num_overdue_pyt,
		0,       			0.0,      				0.0,
		0.0,     			wrk.amt_pyt,   				0.0,       
		0.0,     			wrk.amt_disc_taken,			0.0,
		0.0,     			0.0,      				wrk.days_pay,
		wrk.days_overdue,		0,						0.0,
		0.0,				0.0,					wrk.amt_pyt_oper,
		0.0,				0.0,					wrk.amt_disc_taken_oper,
		0.0,				0.0,					0.0
	FROM #appycls_work wrk
		LEFT JOIN apsumcls b ON wrk.class_code = b.class_code
	WHERE @date_applied BETWEEN b.date_from AND b.date_thru AND b.class_code IS NULL


   END

IF @bch_flag = 1
   BEGIN


	  UPDATE apsumbch
	  SET num_vouch_paid = apsumbch.num_vouch_paid + b.num_vouch_paid,
	      num_pyt	= apsumbch.num_pyt + b.num_pyt,
		  num_overdue_pyt = apsumbch.num_overdue_pyt + b.num_overdue_pyt,
		  amt_pyt = apsumbch.amt_pyt + b.amt_pyt,
		  amt_pyt_oper = apsumbch.amt_pyt_oper + b.amt_pyt_oper,
		  amt_disc_taken = apsumbch.amt_disc_taken + b.amt_disc_taken,
		  amt_disc_taken_oper = apsumbch.amt_disc_taken_oper + b.amt_disc_taken_oper 


	  FROM apsumbch
		INNER JOIN #appybch_work b ON apsumbch.branch_code = b.branch_code
	  WHERE @date_applied BETWEEN apsumbch.date_from AND apsumbch.date_thru


INSERT  apsumbch( 
		branch_code,    	date_from,      		date_thru,
		num_vouch,      	num_vouch_paid, 		num_dm,
		num_adj,        	num_pyt,        		num_overdue_pyt,
		num_void,       	amt_vouch,      		amt_dm,
		amt_adj,        	amt_pyt,        		amt_void,       
		amt_disc_given, 	amt_disc_taken, 		amt_disc_lost,
		amt_freight,    	amt_tax,        		avg_days_pay,
		avg_days_overdue, 	last_trx_time,			amt_vouch_oper,
		amt_dm_oper,		amt_adj_oper,			amt_pyt_oper,
		amt_void_oper,		amt_disc_given_oper,	amt_disc_taken_oper,
		amt_disc_lost_oper,	amt_freight_oper,		amt_tax_oper
		)
SELECT  wrk.branch_code,		@period_start_date,     @period_end_date,
		0,      			wrk.num_vouch_paid, 		0,
		0,        			wrk.num_pyt,        		wrk.num_overdue_pyt,
		0,       			0.0,      				0.0,
		0.0,     			wrk.amt_pyt,   				0.0,       
		0.0,     			wrk.amt_disc_taken,			0.0,
		0.0,     			0.0,      				wrk.days_pay,
		wrk.days_overdue, 		0,						0.0,
		0.0,				0.0,					wrk.amt_pyt_oper,
		0.0,				0.0,					wrk.amt_disc_taken_oper,
		0.0,				0.0,					0.0
	FROM #appybch_work wrk
		LEFT JOIN apsumbch b ON wrk.branch_code = b.branch_code
	WHERE @date_applied BETWEEN b.date_from AND b.date_thru AND b.branch_code IS NULL


   END




IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appyups.cpp" + ", line " + STR( 287, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[APPYUPSummary_sp] TO [public]
GO
