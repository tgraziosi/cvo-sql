SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO










CREATE PROC [dbo].[APVOUPSummary_sp]
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
	@sumvi_flag smallint,
	@date_applied int,
	@period_start_date int,
	@period_end_date int


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvoups.cpp" + ", line " + STR( 66, 5 ) + " -- ENTRY: "


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
	  UPDATE vnd
	  SET vnd.num_vouch = vnd.num_vouch + b.num_vouch,
		  vnd.amt_vouch = vnd.amt_vouch + b.amt_vouch,
		  vnd.amt_vouch_oper = vnd.amt_vouch_oper + b.amt_vouch_oper
	  FROM apsumvnd vnd
		INNER JOIN #apvovnd_work b ON vnd.vendor_code = b.vendor_code
	  WHERE @date_applied BETWEEN vnd.date_from AND vnd.date_thru
		


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
		wrk.num_vouch,      	0,				 		0,
		0,        			0,		   				0,
		0,       			wrk.amt_vouch,      		0,
		0.0,     			0.0,	   				0.0,       
		0.0,     			0.0,					0.0,
		0.0,     			0.0,      				0,
		0,				 	0,						wrk.amt_vouch_oper,
		0.0,				0.0,					0.0,
		0.0,				0.0,					0.0,
		0.0,				0.0,					0.0
	FROM #apvovnd_work wrk
		LEFT JOIN apsumvnd b on wrk.vendor_code = b.vendor_code
	WHERE @date_applied BETWEEN b.date_from AND b.date_thru
		AND b.vendor_code IS NULL





   END


IF @pto_flag = 1
   BEGIN
	  UPDATE pto
	  SET pto.num_vouch = pto.num_vouch + b.num_vouch,
		  pto.amt_vouch = pto.amt_vouch + b.amt_vouch,
		  pto.amt_vouch_oper = pto.amt_vouch_oper + b.amt_vouch
	  FROM apsumpto pto
		INNER JOIN #apvopto_work b ON pto.vendor_code = b.vendor_code AND pto.pay_to_code = b.pay_to_code
	  WHERE @date_applied BETWEEN pto.date_from AND pto.date_thru


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
SELECT  wrk.vendor_code,	wrk.pay_to_code, @period_start_date,@period_end_date,
		wrk.num_vouch, 			0,				 		0,
		0,        			0,		        		0,
		0,       			wrk.amt_vouch,      		0,
		0.0,     			0.0,	   				0.0,       
		0.0,     			0.0,					0.0,
		0.0,     			0.0,      				0,
		0,				 	0,						wrk.amt_vouch_oper,
		0.0,				0.0,					0.0,
		0.0,				0.0,					0.0,
		0.0,				0.0,					0.0
	FROM #apvopto_work wrk
		LEFT JOIN apsumpto b ON wrk.vendor_code = b.vendor_code AND wrk.pay_to_code = b.pay_to_code
	WHERE @date_applied BETWEEN b.date_from AND b.date_thru
		AND b.pay_to_code IS NULL

   END

IF @cls_flag = 1
   BEGIN
	  UPDATE cls
	  SET cls.num_vouch = cls.num_vouch + b.num_vouch,
		  cls.amt_vouch = cls.amt_vouch + b.amt_vouch,
		  cls.amt_vouch_oper = cls.amt_vouch_oper + b.amt_vouch_oper
	  FROM apsumcls cls
		INNER JOIN #apvocls_work b ON cls.class_code = b.class_code
	  WHERE @date_applied BETWEEN cls.date_from AND cls.date_thru


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
		wrk.num_vouch,			0,				 		0,
		0,        			0,		        		0,
		0,       			wrk.amt_vouch,      		0.0,
		0.0,     			0.0,					0.0,       
		0.0,     			0.0,					0.0,
		0.0,     			0.0,      				0,
		0,				 	0,						wrk.amt_vouch_oper,
		0.0,				0.0,					0.0,
		0.0,				0.0,					0.0,
		0.0,				0.0,					0.0
	FROM #apvocls_work wrk
		LEFT JOIN apsumcls b ON wrk.class_code = b.class_code
	WHERE @date_applied BETWEEN b.date_from AND b.date_thru
		AND b.class_code IS NULL

   END

IF @bch_flag = 1
   BEGIN
	  UPDATE bch
	  SET bch.num_vouch = bch.num_vouch + b.num_vouch,
		  bch.amt_vouch = bch.amt_vouch + b.amt_vouch,
		  bch.amt_vouch_oper = bch.amt_vouch_oper + b.amt_vouch_oper
	  FROM apsumbch bch
		INNER JOIN #apvobch_work b ON bch.branch_code = b.branch_code
	  WHERE @date_applied BETWEEN bch.date_from AND bch.date_thru


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
		wrk.num_vouch,      	0,				 		0,
		0,        			0,		        		0,
		0,       			wrk.amt_vouch, 				0.0,
		0.0,     			0.0,	   				0.0,       
		0.0,     			0.0,					0.0,
		0.0,     			0.0,      				0,
		0,				 	0,						wrk.amt_vouch_oper,
		0.0,				0.0,					0.0,
		0.0,				0.0,					0.0,
		0.0,				0.0,					0.0
	FROM #apvobch_work wrk
		LEFT JOIN apsumbch b ON wrk.branch_code = b.branch_code
	WHERE @date_applied BETWEEN b.date_from AND b.date_thru
		AND b.branch_code IS NULL

   END




IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvoups.cpp" + ", line " + STR( 264, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[APVOUPSummary_sp] TO [public]
GO
