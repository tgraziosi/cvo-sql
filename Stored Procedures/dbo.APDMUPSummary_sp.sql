SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO










CREATE PROC [dbo].[APDMUPSummary_sp]
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
	@period_end_date int,
	@vendor_code varchar(12)

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdmups.cpp" + ", line " + STR( 64, 5 ) + " -- ENTRY: "


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
	SET num_dm = apsumvnd.num_dm + b.num_dm,
		amt_dm = apsumvnd.amt_dm + b.amt_dm,
		amt_dm_oper = apsumvnd.amt_dm_oper + b.amt_dm_oper
	FROM apsumvnd
		INNER JOIN #apdmvnd_work b ON apsumvnd.vendor_code = b.vendor_code
	WHERE @date_applied BETWEEN apsumvnd.date_from AND apsumvnd.date_thru

	INSERT  apsumvnd( 
		vendor_code,    		date_from,      		date_thru,
		num_vouch,      		num_vouch_paid, 		num_dm,
		num_adj,        		num_pyt,        		num_overdue_pyt,
		num_void,       		amt_vouch,      		amt_dm,
		amt_adj,        		amt_pyt,        		amt_void,       
		amt_disc_given, 		amt_disc_taken, 		amt_disc_lost,
		amt_freight,    		amt_tax,        		avg_days_pay,
		avg_days_overdue, 		last_trx_time,
		amt_vouch_oper,      	amt_dm_oper,			amt_adj_oper,        	
		amt_pyt_oper,        	amt_void_oper,       	amt_disc_given_oper, 	
		amt_disc_taken_oper, 	amt_disc_lost_oper,		amt_freight_oper,    	
		amt_tax_oper)
	SELECT  
		wrk.vendor_code,			@period_start_date,     @period_end_date,
		0,      				0,				 		wrk.num_dm,
		0,        				0,		   				0,
		0,       				0.0,      				wrk.amt_dm,
		0.0,     				0.0,	   				0.0,       
		0.0,     				0.0,					0.0,
		0.0,     				0.0,      				0,
		0,				 		0,
		0.0,     				wrk.amt_dm_oper,			0.0,
		0.0,     				0.0,      				0.0,
		0.0,     				0.0,					0.0,
		0.0
	FROM #apdmvnd_work wrk
		LEFT JOIN apsumvnd b ON wrk.vendor_code = b.vendor_code
	WHERE @date_applied BETWEEN b.date_from AND b.date_thru
		AND b.vendor_code IS NULL

END



IF @pto_flag = 1
BEGIN


	UPDATE apsumpto
	SET num_dm	= apsumpto.num_dm + b.num_dm,
		amt_dm = apsumpto.amt_dm + b.amt_dm,
	  	amt_dm_oper = apsumpto.amt_dm_oper + b.amt_dm_oper
	FROM apsumpto
		INNER JOIN #apdmpto_work b ON apsumpto.vendor_code = b.vendor_code AND apsumpto.pay_to_code = b.pay_to_code
	WHERE @date_applied BETWEEN apsumpto.date_from AND apsumpto.date_thru


	INSERT  apsumpto( 
		vendor_code,			pay_to_code, 			date_from,      		date_thru,
		num_vouch,      		num_vouch_paid, 		num_dm,
		num_adj,        		num_pyt,        		num_overdue_pyt,
		num_void,       		amt_vouch,      		amt_dm,
		amt_adj,        		amt_pyt,        		amt_void,       
		amt_disc_given, 		amt_disc_taken, 		amt_disc_lost,
		amt_freight,    		amt_tax,        		avg_days_pay,
		avg_days_overdue, 		last_trx_time,
		amt_vouch_oper,      	amt_dm_oper,			amt_adj_oper,        	
		amt_pyt_oper,        	amt_void_oper,       	amt_disc_given_oper, 	
		amt_disc_taken_oper, 	amt_disc_lost_oper,		amt_freight_oper,    	
		amt_tax_oper)
	SELECT  
		wrk.vendor_code,			wrk.pay_to_code, 			@period_start_date,		@period_end_date,
		0,      				0,				 		wrk.num_dm,
		0,        				0,		        		0,
		0,       				0.0,      				wrk.amt_dm,
		0.0,     				0.0,	   				0.0,       
		0.0,     				0.0,					0.0,
		0.0,     				0.0,      				0,
		0,				 		0,
		0.0,     				wrk.amt_dm_oper,			0.0,
		0.0,     				0.0,      				0.0,
		0.0,     				0.0,					0.0,
		0.0
	FROM #apdmpto_work wrk
		LEFT JOIN apsumpto b ON wrk.vendor_code = b.vendor_code AND wrk.pay_to_code = b.pay_to_code
	WHERE @date_applied BETWEEN b.date_from AND b.date_thru
		AND b.pay_to_code IS NULL

   END



IF @cls_flag = 1
BEGIN


 	UPDATE apsumcls
	SET num_dm = apsumcls.num_dm + b.num_dm,
	 	amt_dm = apsumcls.amt_dm + b.amt_dm,
		amt_dm_oper = apsumcls.amt_dm_oper + b.amt_dm_oper
   	FROM apsumcls
		INNER JOIN #apdmcls_work b ON apsumcls.class_code = b.class_code
	WHERE @date_applied BETWEEN apsumcls.date_from AND apsumcls.date_thru


	INSERT  apsumcls( 
		class_code,    			date_from,      		date_thru,
		num_vouch,      		num_vouch_paid, 		num_dm,
		num_adj,        		num_pyt,        		num_overdue_pyt,
		num_void,       		amt_vouch,      		amt_dm,
		amt_adj,        		amt_pyt,        		amt_void,       
		amt_disc_given, 		amt_disc_taken, 		amt_disc_lost,
		amt_freight,    		amt_tax,        		avg_days_pay,
		avg_days_overdue, 		last_trx_time,
		amt_vouch_oper,      	amt_dm_oper,			amt_adj_oper,        	
		amt_pyt_oper,        	amt_void_oper,       	amt_disc_given_oper, 	
		amt_disc_taken_oper, 	amt_disc_lost_oper,		amt_freight_oper,    	
		amt_tax_oper)
	SELECT  
		wrk.class_code,				@period_start_date,     @period_end_date,
		0,      				0,				 		wrk.num_dm,
		0,        				0,		        		0,
		0,       				0.0,      				wrk.amt_dm,
		0.0,     				0.0,					0.0,       
		0.0,     				0.0,					0.0,
		0.0,     				0.0,      				0,
		0,				 		0,
		0.0,     				wrk.amt_dm_oper,			0.0,
		0.0,     				0.0,      				0.0,
		0.0,     				0.0,					0.0,
		0.0
	FROM #apdmcls_work wrk
		LEFT JOIN apsumcls b ON wrk.class_code = b.class_code
	WHERE @date_applied BETWEEN b.date_from AND b.date_thru
		AND b.class_code IS NULL
END



IF @bch_flag = 1
BEGIN



	UPDATE apsumbch
	SET num_dm	= apsumbch.num_dm + b.num_dm,
	 	amt_dm = apsumbch.amt_dm + b.amt_dm,
		amt_dm_oper = apsumbch.amt_dm_oper + b.amt_dm_oper
  	FROM apsumbch
		INNER JOIN #apdmbch_work b ON apsumbch.branch_code = b.branch_code
	WHERE @date_applied BETWEEN apsumbch.date_from AND apsumbch.date_thru


	INSERT  apsumbch( 
		branch_code,    		date_from,      		date_thru,
		num_vouch,      		num_vouch_paid, 		num_dm,
		num_adj,        		num_pyt,        		num_overdue_pyt,
		num_void,       		amt_vouch,      		amt_dm,
		amt_adj,        		amt_pyt,        		amt_void,       
		amt_disc_given, 		amt_disc_taken, 		amt_disc_lost,
		amt_freight,    		amt_tax,        		avg_days_pay,
		avg_days_overdue, 		last_trx_time,
		amt_vouch_oper,      	amt_dm_oper,			amt_adj_oper,        	
		amt_pyt_oper,        	amt_void_oper,       	amt_disc_given_oper, 	
		amt_disc_taken_oper, 	amt_disc_lost_oper,		amt_freight_oper,    	
		amt_tax_oper)
	SELECT  
		wrk.branch_code,			@period_start_date,     @period_end_date,
		0,      				0,				 		wrk.num_dm,
		0,        				0,		        		0,
		0,       				0.0,      				wrk.amt_dm,
		0.0,     				0.0,	   				0.0,       
		0.0,     				0.0,					0.0,
		0.0,     				0.0,      				0,
		0,				 		0,
		0.0,     				wrk.amt_dm_oper,			0.0,
		0.0,     				0.0,      				0.0,
		0.0,     				0.0,					0.0,
		0.0
	FROM #apdmbch_work wrk
		LEFT JOIN apsumbch b ON wrk.branch_code = b.branch_code
	WHERE @date_applied BETWEEN b.date_from AND b.date_thru
		AND b.branch_code IS NULL
END




IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdmups.cpp" + ", line " + STR( 275, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[APDMUPSummary_sp] TO [public]
GO
