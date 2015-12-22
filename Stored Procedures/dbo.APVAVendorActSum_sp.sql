SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO





CREATE PROC [dbo].[APVAVendorActSum_sp] 	@debug_level smallint = 0

AS
 DECLARE
 @vend_flag smallint,
	 @pto_flag smallint,
	 @cls_flag smallint, 
	 @bch_flag smallint,
 @vend2_flag smallint,
	 @pto2_flag smallint,
	 @cls2_flag smallint, 
	 @bch2_flag smallint,
	 @home_precision smallint,
	 @oper_precision smallint

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvavas.sp" + ", line " + STR( 64, 5 ) + " -- ENTRY: "


SELECT @vend_flag = apactvnd_flag,
		@pto_flag = apactpto_flag,
		@cls_flag = apactcls_flag,
		@bch_flag = apactbch_flag,
		@vend2_flag = apsumvnd_flag,
		@pto2_flag = apsumpto_flag,
		@cls2_flag = apsumcls_flag,
		@bch2_flag = apsumbch_flag
FROM apco

 
SELECT 	@home_precision = b.curr_precision,
	 	@oper_precision = c.curr_precision
FROM 	glco a, glcurr_vw b, glcurr_vw c
WHERE 	a.home_currency = b.currency_code
AND 	a.oper_currency = c.currency_code

IF ((@vend_flag = 1) OR (@vend2_flag = 1))
 BEGIN

 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvavas.sp" + ", line " + STR( 89, 5 ) + " -- MSG: " + "Process Vendor Activity/Summary"

	SELECT vendor_code, trx_ctrl_num = MAX(trx_ctrl_num)
	INTO #temp1
	FROM #apvachg_work a
	GROUP BY vendor_code


 	INSERT #apvavnd_work (
			vendor_code, date_last_adj,		amt_last_adj, 
			last_adj_doc, amt_balance,			num_adj,
			amt_adj,		 last_adj_cur,	 	amt_adj_oper,	
			db_action )
 	SELECT 
			a.vendor_code,	 a.date_applied, 	(SIGN(a.amt_net) * ROUND(ABS(a.amt_net) + 0.0000001, 6)), 
			a.trx_ctrl_num, 0.0,					0,
			0.0,			 a.nat_cur_code, 	0.0,						
			0
	FROM #apvachg_work a, #temp1 b
	WHERE a.trx_ctrl_num = b.trx_ctrl_num

 


	UPDATE #apvavnd_work
	SET num_adj 	= ISNULL((SELECT COUNT(*)
						 FROM #apvachg_work
						 WHERE vendor_code = #apvavnd_work.vendor_code),0),
	 amt_adj 		= (SELECT ISNULL( SUM( (SIGN(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) * ROUND(ABS(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) + 0.0000001, @home_precision))),0)
						 FROM #apvachg_work
						 WHERE vendor_code = #apvavnd_work.vendor_code),
	 amt_adj_oper	= (SELECT ISNULL( SUM( (SIGN(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) * ROUND(ABS(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) + 0.0000001, @oper_precision))),0)
						 FROM #apvachg_work
						 WHERE vendor_code = #apvavnd_work.vendor_code)
	FROM #apvavnd_work

 	DROP TABLE #temp1	

	END


IF ((@pto_flag = 1) OR (@pto2_flag = 1))
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvavas.sp" + ", line " + STR( 132, 5 ) + " -- MSG: " + "Process Pay to Activity/Summary"
 
	SELECT vendor_code, pay_to_code, trx_ctrl_num = MAX(trx_ctrl_num)
	INTO #temp2
	FROM #apvachg_work a
	WHERE pay_to_code != ""
	GROUP BY vendor_code, pay_to_code


 	INSERT #apvapto_work (
			vendor_code, pay_to_code, 	date_last_adj,		amt_last_adj, 
			last_adj_doc, amt_balance,		num_adj,
			amt_adj,		 last_adj_cur,	amt_adj_oper,	
			db_action )
 	SELECT 
			a.vendor_code, a.pay_to_code, a.date_applied, (SIGN(a.amt_net) * ROUND(ABS(a.amt_net) + 0.0000001, 6)), 
			a.trx_ctrl_num, 0.0,				0,
			0.0,			 a.nat_cur_code, 0.0,						
			0
	FROM #apvachg_work a, #temp2 b
	WHERE a.trx_ctrl_num = b.trx_ctrl_num


	UPDATE #apvapto_work
	SET num_adj = ISNULL((SELECT COUNT(*)
						 FROM #apvachg_work
						 WHERE vendor_code = #apvapto_work.vendor_code
						 AND pay_to_code = #apvapto_work.pay_to_code),0),
	 amt_adj = (SELECT ISNULL( SUM( (SIGN(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) * ROUND(ABS(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) + 0.0000001, @home_precision))),0)
						 FROM #apvachg_work
						 WHERE vendor_code = #apvapto_work.vendor_code
						 AND pay_to_code = #apvapto_work.pay_to_code),
	 amt_adj_oper	= (SELECT ISNULL( SUM( (SIGN(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) * ROUND(ABS(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) + 0.0000001, @oper_precision))),0)
						 FROM #apvachg_work
						 WHERE vendor_code = #apvapto_work.vendor_code
						 AND pay_to_code = #apvapto_work.pay_to_code)
	FROM #apvapto_work

 	DROP TABLE #temp2	

			
	END



IF ((@cls_flag = 1) OR (@cls2_flag = 1))
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvavas.sp" + ", line " + STR( 179, 5 ) + " -- MSG: " + "Process Class Activity/Summary"

	SELECT class_code, trx_ctrl_num = MAX(trx_ctrl_num)
	INTO #temp3
	FROM #apvachg_work a
	GROUP BY class_code


 	INSERT #apvacls_work (
			class_code, date_last_adj,	amt_last_adj, 
			last_adj_doc, amt_balance,		num_adj,
			amt_adj,		 last_adj_cur,		amt_adj_oper,	
			db_action )
 	SELECT 
			a.class_code, a.date_applied, (SIGN(a.amt_net) * ROUND(ABS(a.amt_net) + 0.0000001, 6)), 
			a.trx_ctrl_num, 0.0,				0,
			0.0,			 a.nat_cur_code, 	0.0,						
			0
	FROM #apvachg_work a, #temp3 b
	WHERE a.trx_ctrl_num = b.trx_ctrl_num

 


	UPDATE #apvacls_work
	SET num_adj = ISNULL((SELECT COUNT(*)
						 FROM #apvachg_work
						 WHERE class_code = #apvacls_work.class_code),0),
	 amt_adj = (SELECT ISNULL( SUM( (SIGN(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) * ROUND(ABS(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) + 0.0000001, @home_precision))),0)
						 FROM #apvachg_work
						 WHERE class_code = #apvacls_work.class_code),
	 amt_adj_oper	= (SELECT ISNULL( SUM( (SIGN(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) * ROUND(ABS(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) + 0.0000001, @oper_precision))),0)
						 FROM #apvachg_work
						 WHERE class_code = #apvacls_work.class_code)
	FROM #apvacls_work

 	DROP TABLE #temp3	

 END


IF ((@bch_flag = 1) OR (@bch2_flag = 1))

 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvavas.sp" + ", line " + STR( 223, 5 ) + " -- MSG: " + "Process Branch Activity/Summary"

	SELECT branch_code, trx_ctrl_num = MAX(trx_ctrl_num)
	INTO #temp4
	FROM #apvachg_work a
	GROUP BY branch_code


 	INSERT #apvabch_work (
			branch_code, date_last_adj,	amt_last_adj, 
			last_adj_doc, amt_balance,		num_adj,
			amt_adj,		 last_adj_cur,	amt_adj_oper,	
			db_action )

 	SELECT 
			a.branch_code, a.date_applied, (SIGN(a.amt_net) * ROUND(ABS(a.amt_net) + 0.0000001, 6)), 
			a.trx_ctrl_num, 0.0,				0,
			0.0,			 a.nat_cur_code, 0.0,						
			0
	FROM #apvachg_work a, #temp4 b
	WHERE a.trx_ctrl_num = b.trx_ctrl_num

 


	UPDATE #apvabch_work
	SET num_adj = ISNULL((SELECT COUNT(*)
						 FROM #apvachg_work
						 WHERE branch_code = #apvabch_work.branch_code),0),
	 amt_adj = (SELECT ISNULL( SUM( (SIGN(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) * ROUND(ABS(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) + 0.0000001, @home_precision))),0)
						 FROM #apvachg_work
						 WHERE branch_code = #apvabch_work.branch_code),
	 amt_adj_oper	= (SELECT ISNULL( SUM( (SIGN(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) * ROUND(ABS(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) + 0.0000001, @oper_precision))),0)
						 FROM #apvachg_work
						 WHERE branch_code = #apvabch_work.branch_code)
	FROM #apvabch_work

	DROP TABLE #temp4
 END




IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apvavas.sp" + ", line " + STR( 266, 5 ) + " -- EXIT: "
RETURN 0

GO
GRANT EXECUTE ON  [dbo].[APVAVendorActSum_sp] TO [public]
GO
