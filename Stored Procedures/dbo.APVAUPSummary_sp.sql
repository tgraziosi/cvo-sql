SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO










CREATE PROC [dbo].[APVAUPSummary_sp]
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


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvaups.sp" + ", line " + STR( 64, 5 ) + " -- ENTRY: "


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
	 UPDATE #apvavnd_work
	 SET db_action = 2
	 FROM #apvavnd_work, apsumvnd b
	 WHERE #apvavnd_work.vendor_code = b.vendor_code
	 AND @date_applied BETWEEN b.date_from AND b.date_thru


	 UPDATE apsumvnd
	 SET num_adj = apsumvnd.num_adj + b.num_adj,
		 amt_adj = apsumvnd.amt_adj + b.amt_adj,
		 amt_adj_oper = apsumvnd.amt_adj_oper + b.amt_adj_oper
	 FROM apsumvnd, #apvavnd_work b
	 WHERE apsumvnd.vendor_code = b.vendor_code
	 AND db_action = 2


INSERT apsumvnd( 
		vendor_code, 		date_from, 		date_thru,
		num_vouch, 		num_vouch_paid, 		num_dm,
		num_adj, 		num_pyt, 		num_overdue_pyt,
		num_void, 		amt_vouch, 		amt_dm,
		amt_adj, 		amt_pyt, 		amt_void, 
		amt_disc_given, 		amt_disc_taken, 		amt_disc_lost,
		amt_freight, 		amt_tax, 		avg_days_pay,
		avg_days_overdue, 		last_trx_time,
		amt_vouch_oper, 	amt_dm_oper,			amt_adj_oper, 	
		amt_pyt_oper, 	amt_void_oper, 	amt_disc_given_oper, 	
		amt_disc_taken_oper, 	amt_disc_lost_oper,		amt_freight_oper, 	
		amt_tax_oper)
SELECT vendor_code, 			@period_start_date, @period_end_date,
		0, 				0,				 		0,
		num_adj, 				0,		 				0,
		0, 				0.0, 				0.0,
		amt_adj,	 			0.0,	 				0.0, 
		0.0, 				0.0,					0.0,
		0.0, 				0.0, 				0,
		0,				 		0,
		0.0, 		 			0.0,					amt_adj_oper,
		0.0, 				0.0, 				0.0,
		0.0, 				0.0,					0.0,
		0.0
	FROM #apvavnd_work
	WHERE db_action != 2



 END


IF @pto_flag = 1
 BEGIN
	 UPDATE #apvapto_work
	 SET db_action = 2
	 FROM #apvapto_work, apsumpto b
	 WHERE #apvapto_work.vendor_code = b.vendor_code
	 AND #apvapto_work.pay_to_code = b.pay_to_code
	 AND @date_applied BETWEEN b.date_from AND b.date_thru


	 UPDATE apsumpto
	 SET num_adj	= apsumpto.num_adj + b.num_adj,
		 amt_adj = apsumpto.amt_adj + b.amt_adj,
		 amt_adj_oper = apsumpto.amt_adj_oper + b.amt_adj_oper
	 FROM apsumpto, #apvapto_work b
	 WHERE apsumpto.vendor_code = b.vendor_code
	 AND apsumpto.pay_to_code = b.pay_to_code
	 AND db_action = 2


INSERT apsumpto( 
		vendor_code,pay_to_code, date_from, 	date_thru,
		num_vouch, 		num_vouch_paid, 		num_dm,
		num_adj, 		num_pyt, 		num_overdue_pyt,
		num_void, 		amt_vouch, 		amt_dm,
		amt_adj, 		amt_pyt, 		amt_void, 
		amt_disc_given, 		amt_disc_taken, 		amt_disc_lost,
		amt_freight, 		amt_tax, 		avg_days_pay,
		avg_days_overdue, 		last_trx_time,
		amt_vouch_oper, 	amt_dm_oper,			amt_adj_oper, 	
		amt_pyt_oper, 	amt_void_oper, 	amt_disc_given_oper, 	
		amt_disc_taken_oper, 	amt_disc_lost_oper,		amt_freight_oper, 	
		amt_tax_oper)
SELECT vendor_code,			pay_to_code, 			@period_start_date,		@period_end_date,
		0, 				0,				 		0,
		num_adj, 				0,		 		0,
		0, 				0.0, 				0.0,
		amt_adj, 	 			0.0,	 				0.0, 
		0.0, 				0.0,					0.0,
		0.0, 				0.0, 				0,
		0,					 	0,
		0.0, 				0.0,					amt_adj_oper,
		0.0, 				0.0, 				0.0,
		0.0, 				0.0,					0.0,
		0.0
	FROM #apvapto_work
	WHERE db_action != 2

 END

IF @cls_flag = 1
 BEGIN
	 UPDATE #apvacls_work
	 SET db_action = 2
	 FROM #apvacls_work, apsumcls b
	 WHERE #apvacls_work.class_code = b.class_code
	 AND @date_applied BETWEEN b.date_from AND b.date_thru


	 UPDATE apsumcls
	 SET num_adj = apsumcls.num_adj + b.num_adj,
		 amt_adj = apsumcls.amt_adj + b.amt_adj,
		 amt_adj_oper = apsumcls.amt_adj_oper + b.amt_adj_oper
	 FROM apsumcls, #apvacls_work b
	 WHERE apsumcls.class_code = b.class_code
	 AND db_action = 2


INSERT apsumcls( 
		class_code, 			date_from, 		date_thru,
		num_vouch, 		num_vouch_paid, 		num_dm,
		num_adj, 		num_pyt, 		num_overdue_pyt,
		num_void, 		amt_vouch, 		amt_dm,
		amt_adj, 		amt_pyt, 		amt_void, 
		amt_disc_given, 		amt_disc_taken, 		amt_disc_lost,
		amt_freight, 		amt_tax, 		avg_days_pay,
		avg_days_overdue, 		last_trx_time,
		amt_vouch_oper, 	amt_dm_oper,			amt_adj_oper, 	
		amt_pyt_oper, 	amt_void_oper, 	amt_disc_given_oper, 	
		amt_disc_taken_oper, 	amt_disc_lost_oper,		amt_freight_oper, 	
		amt_tax_oper)
SELECT class_code,				@period_start_date, @period_end_date,
		0, 				0,				 		0,
		num_adj, 	 			0,		 		0,
		0, 				0.0, 				0.0,
		amt_adj, 	 			0.0,					0.0, 
		0.0, 				0.0,					0.0,
		0.0, 				0.0, 				0,
		0,				 		0,
		0.0, 		 			0.0,					amt_adj_oper,
		0.0, 				0.0, 				0.0,
		0.0, 				0.0,					0.0,
		0.0
	FROM #apvacls_work
	WHERE db_action != 2

 END

IF @bch_flag = 1
 BEGIN
	 UPDATE #apvabch_work
	 SET db_action = 2
	 FROM #apvabch_work, apsumbch b
	 WHERE #apvabch_work.branch_code = b.branch_code
	 AND @date_applied BETWEEN b.date_from AND b.date_thru


	 UPDATE apsumbch
	 SET num_adj	= apsumbch.num_adj + b.num_adj,
		 amt_adj = apsumbch.amt_adj + b.amt_adj,
		 amt_adj_oper = apsumbch.amt_adj_oper + b.amt_adj_oper
	 FROM apsumbch, #apvabch_work b
	 WHERE apsumbch.branch_code = b.branch_code
	 AND db_action = 2


INSERT apsumbch( 
		branch_code, 		date_from, 		date_thru,
		num_vouch, 		num_vouch_paid, 		num_dm,
		num_adj, 		num_pyt, 		num_overdue_pyt,
		num_void, 		amt_vouch, 		amt_dm,
		amt_adj, 		amt_pyt, 		amt_void, 
		amt_disc_given, 		amt_disc_taken, 		amt_disc_lost,
		amt_freight, 		amt_tax, 		avg_days_pay,
		avg_days_overdue, 		last_trx_time,
		amt_vouch_oper, 	amt_dm_oper,			amt_adj_oper, 	
		amt_pyt_oper, 	amt_void_oper, 	amt_disc_given_oper, 	
		amt_disc_taken_oper, 	amt_disc_lost_oper,		amt_freight_oper, 	
		amt_tax_oper)
SELECT branch_code,			@period_start_date, @period_end_date,
		0, 				0,				 		0,
		num_adj, 	 			0,		 		0,
		0, 				0.0, 				0.0,
		amt_adj, 				0.0,	 				0.0, 
		0.0, 				0.0,					0.0,
		0.0, 				0.0, 				0,
		0,					 	0,
		0.0, 	 			0.0,					amt_adj_oper,
		0.0, 		 			0.0, 				0.0,
		0.0, 		 			0.0,					0.0,
		0.0
	FROM #apvabch_work
	WHERE db_action != 2

 END


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvaups.sp" + ", line " + STR( 284, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[APVAUPSummary_sp] TO [public]
GO
