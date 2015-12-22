SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO









CREATE PROC [dbo].[APPAUPSummary_sp]
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


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/appaups.sp" + ", line " + STR( 76, 5 ) + " -- ENTRY: "


SELECT @vend_flag = apsumvnd_flag,
		@pto_flag = apsumpto_flag,
		@cls_flag = apsumcls_flag,
		@bch_flag = apsumbch_flag
FROM apco


SELECT @date_applied = date_applied
FROM batchctl
WHERE batch_ctrl_num = @batch_ctrl_num



SELECT @period_start_date = period_start_date,
	 @period_end_date = period_end_date
FROM glprd
WHERE @date_applied BETWEEN period_start_date AND period_end_date


IF @vend_flag = 1
 BEGIN
	 UPDATE #appavnd_work
	 SET db_action = 2
	 FROM #appavnd_work, apsumvnd b
	 WHERE #appavnd_work.vendor_code = b.vendor_code
	 AND @date_applied BETWEEN b.date_from AND b.date_thru


	 UPDATE apsumvnd
	 SET num_vouch_paid = apsumvnd.num_vouch_paid + b.num_vouch_paid,
	 num_void = apsumvnd.num_void + b.num_void,
		 amt_void = apsumvnd.amt_void + b.amt_void,
		 amt_void_oper = apsumvnd.amt_void_oper + b.amt_void_oper
	 FROM apsumvnd, #appavnd_work b
	 WHERE apsumvnd.vendor_code = b.vendor_code
	 AND db_action = 2
	 AND @date_applied BETWEEN apsumvnd.date_from AND apsumvnd.date_thru


INSERT apsumvnd( 
		vendor_code, 	date_from, 		date_thru,
		num_vouch, 	num_vouch_paid, 		num_dm,
		num_adj, 	num_pyt, 		num_overdue_pyt,
		num_void, 	amt_vouch, 		amt_dm,
		amt_adj, 	amt_pyt, 		amt_void, 
		amt_disc_given, 	amt_disc_taken, 		amt_disc_lost,
		amt_freight, 	amt_tax, 		avg_days_pay,
		avg_days_overdue, 	last_trx_time,			amt_vouch_oper,
		amt_dm_oper,		amt_adj_oper,			amt_pyt_oper,
		amt_void_oper,		amt_disc_given_oper,	amt_disc_taken_oper,
		amt_disc_lost_oper,	amt_freight_oper,		amt_tax_oper
		)
SELECT vendor_code,		@period_start_date, @period_end_date,
		0, 			num_vouch_paid, 		0,
		0, 			0, 					0,
		num_void, 			0.0, 				0.0,
		0.0, 			0.0, 					amt_void, 
		0.0, 			0.0,					0.0,
		0.0, 			0.0, 				0,
		0, 					0,						0.0,
		0.0,				0.0,					0.0,
		amt_void_oper,		0.0,					0.0,
		0.0,				0.0,					0.0
	FROM #appavnd_work
	WHERE db_action != 2



 END


IF @pto_flag = 1
 BEGIN
	 UPDATE #appapto_work
	 SET db_action = 2
	 FROM #appapto_work, apsumpto b
	 WHERE #appapto_work.vendor_code = b.vendor_code
	 AND #appapto_work.pay_to_code = b.pay_to_code
	 AND @date_applied BETWEEN b.date_from AND b.date_thru


	 UPDATE apsumpto
	 SET num_vouch_paid = apsumpto.num_vouch_paid + b.num_vouch_paid,
	 num_void = apsumpto.num_void + b.num_void,
		 amt_void = apsumpto.amt_void + b.amt_void,
		 amt_void_oper = apsumpto.amt_void_oper + b.amt_void_oper
	 FROM apsumpto, #appapto_work b
	 WHERE apsumpto.vendor_code = b.vendor_code
	 AND apsumpto.pay_to_code = b.pay_to_code
	 AND db_action = 2
	 AND @date_applied BETWEEN apsumpto.date_from AND apsumpto.date_thru


INSERT apsumpto( 
		vendor_code,pay_to_code, date_from, 	date_thru,
		num_vouch, 	num_vouch_paid, 		num_dm,
		num_adj, 	num_pyt, 		num_overdue_pyt,
		num_void, 	amt_vouch, 		amt_dm,
		amt_adj, 	amt_pyt, 		amt_void, 
		amt_disc_given, 	amt_disc_taken, 		amt_disc_lost,
		amt_freight, 	amt_tax, 		avg_days_pay,
		avg_days_overdue, 	last_trx_time,			amt_vouch_oper,
		amt_dm_oper,		amt_adj_oper,			amt_pyt_oper,
		amt_void_oper,		amt_disc_given_oper,	amt_disc_taken_oper,
		amt_disc_lost_oper,	amt_freight_oper,		amt_tax_oper
		)
SELECT vendor_code,pay_to_code, @period_start_date,@period_end_date,
		0, 			num_vouch_paid, 		0,
		0, 			0, 					0,
		num_void, 			0.0, 				0.0,
		0.0, 			0.0, 					amt_void, 
		0.0, 			0.0,					0.0,
		0.0, 			0.0, 				0,
		0, 					0,						0.0,
		0.0,				0.0,					0.0,
		amt_void_oper,		0.0,					0.0,
		0.0,				0.0,					0.0
	FROM #appapto_work
	WHERE db_action != 2

 END

IF @cls_flag = 1
 BEGIN
	 UPDATE #appacls_work
	 SET db_action = 2
	 FROM #appacls_work, apsumcls b
	 WHERE #appacls_work.class_code = b.class_code
	 AND @date_applied BETWEEN b.date_from AND b.date_thru


	 UPDATE apsumcls
	 SET num_vouch_paid = apsumcls.num_vouch_paid + b.num_vouch_paid,
	 num_void = apsumcls.num_void + b.num_void,
		 amt_void = apsumcls.amt_void + b.amt_void,
		 amt_void_oper = apsumcls.amt_void_oper + b.amt_void_oper
	 FROM apsumcls, #appacls_work b
	 WHERE apsumcls.class_code = b.class_code
	 AND db_action = 2
	 AND @date_applied BETWEEN apsumcls.date_from AND apsumcls.date_thru


INSERT apsumcls( 
		class_code, 		date_from, 		date_thru,
		num_vouch, 	num_vouch_paid, 		num_dm,
		num_adj, 	num_pyt, 		num_overdue_pyt,
		num_void, 	amt_vouch, 		amt_dm,
		amt_adj, 	amt_pyt, 		amt_void, 
		amt_disc_given, 	amt_disc_taken, 		amt_disc_lost,
		amt_freight, 	amt_tax, 		avg_days_pay,
		avg_days_overdue, 	last_trx_time,			amt_vouch_oper,
		amt_dm_oper,		amt_adj_oper,			amt_pyt_oper,
		amt_void_oper,		amt_disc_given_oper,	amt_disc_taken_oper,
		amt_disc_lost_oper,	amt_freight_oper,		amt_tax_oper
		)
SELECT class_code,			@period_start_date, @period_end_date,
		0, 			num_vouch_paid, 		0,
		0, 			0, 					0,
		num_void, 			0.0, 				0.0,
		0.0, 			0.0, 					amt_void, 
		0.0, 			0.0,					0.0,
		0.0, 			0.0, 				0,
		0, 					0,						0.0,
		0.0,				0.0,					0.0,
		amt_void_oper,		0.0,					0.0,
		0.0,				0.0,					0.0
	FROM #appacls_work
	WHERE db_action != 2

 END

IF @bch_flag = 1
 BEGIN
	 UPDATE #appabch_work
	 SET db_action = 2
	 FROM #appabch_work, apsumbch b
	 WHERE #appabch_work.branch_code = b.branch_code
	 AND @date_applied BETWEEN b.date_from AND b.date_thru


	 UPDATE apsumbch
	 SET num_vouch_paid = apsumbch.num_vouch_paid + b.num_vouch_paid,
	 num_void = apsumbch.num_void + b.num_void,
		 amt_void = apsumbch.amt_void + b.amt_void,
		 amt_void_oper = apsumbch.amt_void_oper + b.amt_void_oper
	 FROM apsumbch, #appabch_work b
	 WHERE apsumbch.branch_code = b.branch_code
	 AND db_action = 2
	 AND @date_applied BETWEEN apsumbch.date_from AND apsumbch.date_thru


INSERT apsumbch( 
		branch_code, 	date_from, 		date_thru,
		num_vouch, 	num_vouch_paid, 		num_dm,
		num_adj, 	num_pyt, 		num_overdue_pyt,
		num_void, 	amt_vouch, 		amt_dm,
		amt_adj, 	amt_pyt, 		amt_void, 
		amt_disc_given, 	amt_disc_taken, 		amt_disc_lost,
		amt_freight, 	amt_tax, 		avg_days_pay,
		avg_days_overdue, 	last_trx_time,			amt_vouch_oper,
		amt_dm_oper,		amt_adj_oper,			amt_pyt_oper,
		amt_void_oper,		amt_disc_given_oper,	amt_disc_taken_oper,
		amt_disc_lost_oper,	amt_freight_oper,		amt_tax_oper
		)
SELECT branch_code,		@period_start_date, @period_end_date,
		0, 			num_vouch_paid, 		0,
		0, 			0, 					0,
		num_void, 			0.0, 				0.0,
		0.0, 			0.0, 					amt_void, 
		0.0, 			0.0,					0.0,
		0.0, 			0.0, 				0,
		0, 					0,						0.0,
		0.0,				0.0,					0.0,
		amt_void_oper,		0.0,					0.0,
		0.0,				0.0,					0.0
	FROM #appabch_work
	WHERE db_action != 2



 END




IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/appaups.sp" + ", line " + STR( 304, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[APPAUPSummary_sp] TO [public]
GO
