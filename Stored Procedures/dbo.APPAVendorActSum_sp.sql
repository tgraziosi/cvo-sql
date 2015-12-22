SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO





CREATE PROC [dbo].[APPAVendorActSum_sp] 	@debug_level smallint = 0

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

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/appavas.sp" + ", line " + STR( 87, 5 ) + " -- ENTRY: "


SELECT @vend_flag = apactvnd_flag,
		@pto_flag = apactpto_flag,
		@cls_flag = apactcls_flag,
		@bch_flag = apactbch_flag,
		@vend2_flag = apsumvnd_flag,
		@pto2_flag = apsumpto_flag,
		@cls2_flag = apsumcls_flag,
		@bch2_flag = apsumbch_flag
FROM apco


 
SELECT @home_precision = b.curr_precision,
	 @oper_precision = c.curr_precision
FROM glco a, glcurr_vw b, glcurr_vw c
WHERE a.home_currency = b.currency_code
AND a.oper_currency = c.currency_code


IF ((@vend_flag = 1) OR (@vend2_flag = 1))
 BEGIN

 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/appavas.sp" + ", line " + STR( 116, 5 ) + " -- MSG: " + "Process Vendor Activity/Summary"

	SELECT vendor_code, trx_ctrl_num = MAX(trx_ctrl_num)
	INTO #temp1
	FROM #appapyt_work 
	WHERE payment_type = 1
	GROUP BY vendor_code


 	INSERT #appavnd_work (
			vendor_code,			date_last_void,		amt_last_void,
			last_void_doc,			last_void_acct, 	last_void_cur,	
			num_vouch_paid,	
			num_void,				amt_void,			amt_disc_voided,
			amt_void_oper,			amt_disc_voided_oper,	
			rate_home,				rate_oper, 			db_action )
 	SELECT 
			a.vendor_code,			a.date_applied,		a.amt_payment, 
			a.doc_ctrl_num,			a.cash_acct_code,	a.nat_cur_code, 
			0,
			0,						0.0,				0.0,
			0.0,					0.0,
			a.rate_home,			a.rate_oper,		0
	FROM #appapyt_work a, #temp1 b
	WHERE a.trx_ctrl_num = b.trx_ctrl_num

 

	UPDATE #appavnd_work
	SET num_void = (SELECT COUNT(*)
						 FROM #appatrx_work
						 WHERE vendor_code = #appavnd_work.vendor_code),
	 amt_void = (SELECT ISNULL(SUM((SIGN(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) * ROUND(ABS(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) + 0.0000001, @home_precision))),0.0)
						 FROM #appatrx_work
						 WHERE void_flag IN (1,2,3,5)
						 AND vendor_code = #appavnd_work.vendor_code),
	 amt_void_oper = (SELECT ISNULL(SUM((SIGN(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) * ROUND(ABS(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) + 0.0000001, @oper_precision))),0.0)
						 FROM #appatrx_work
						 WHERE void_flag IN (1,2,3,5)
						 AND vendor_code = #appavnd_work.vendor_code),
	 amt_disc_voided = (SELECT ISNULL(SUM((SIGN(amt_discount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) * ROUND(ABS(amt_discount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) + 0.0000001, @home_precision))),0.0)
						 FROM #appatrx_work
						 WHERE vendor_code = #appavnd_work.vendor_code),
	 amt_disc_voided_oper = (SELECT ISNULL(SUM((SIGN(amt_discount * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) * ROUND(ABS(amt_discount * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) + 0.0000001, @oper_precision))),0.0)
						 FROM #appatrx_work
						 WHERE vendor_code = #appavnd_work.vendor_code)
 		

	UPDATE #appavnd_work
	 SET num_vouch_paid = (SELECT -ISNULL(SUM(old_paid_flag),0)
							FROM #appatrxv_work
							WHERE paid_flag != old_paid_flag
							AND vendor_code = #appavnd_work.vendor_code)

	DROP TABLE #temp1

	END



IF ((@pto_flag = 1) OR (@pto2_flag = 1))
 BEGIN

 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/appavas.sp" + ", line " + STR( 179, 5 ) + " -- MSG: " + "Process Pay-to Activity/Summary"

	SELECT vendor_code, pay_to_code, trx_ctrl_num = MAX(trx_ctrl_num)
	INTO #temp2
	FROM #appapyt_work 
	WHERE payment_type = 1
	AND pay_to_code != ""
	GROUP BY vendor_code, pay_to_code


 	INSERT #appapto_work (
			vendor_code,		pay_to_code,	date_last_void,
			amt_last_void,		last_void_doc,	last_void_acct,
			last_void_cur,
			num_vouch_paid,		num_void,		amt_void,		
			amt_disc_voided,	amt_void_oper,	amt_disc_voided_oper,
			rate_home,			rate_oper,		db_action )
 	SELECT 
			a.vendor_code,		a.pay_to_code,	a.date_applied,
			a.amt_payment,		a.doc_ctrl_num,	a.cash_acct_code,
			a.nat_cur_code,
			0, 	0,				0.0, 
			0.0,				0.0,			0.0,
			a.rate_home,		a.rate_oper,	0					
	FROM #appapyt_work a, #temp2 b
	WHERE a.trx_ctrl_num = b.trx_ctrl_num 

 


	UPDATE #appapto_work
	SET num_void = (SELECT COUNT(*)
						 FROM #appatrx_work
						 WHERE vendor_code = #appapto_work.vendor_code
						 AND pay_to_code = #appapto_work.pay_to_code),
	 amt_void = (SELECT ISNULL(SUM((SIGN(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) * ROUND(ABS(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) + 0.0000001, @home_precision))),0.0)
						 FROM #appatrx_work
						 WHERE void_flag IN (1,2,3,5)
						 AND vendor_code = #appapto_work.vendor_code
						 AND pay_to_code = #appapto_work.pay_to_code),
	 amt_void_oper = (SELECT ISNULL(SUM((SIGN(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) * ROUND(ABS(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) + 0.0000001, @oper_precision))),0.0)
						 FROM #appatrx_work
						 WHERE void_flag IN (1,2,3,5)
						 AND vendor_code = #appapto_work.vendor_code
						 AND pay_to_code = #appapto_work.pay_to_code),
	 amt_disc_voided = (SELECT ISNULL(SUM((SIGN(amt_discount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) * ROUND(ABS(amt_discount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) + 0.0000001, @home_precision))),0.0)
						 FROM #appatrx_work
						 WHERE vendor_code = #appapto_work.vendor_code
						 AND pay_to_code = #appapto_work.pay_to_code),
	 amt_disc_voided_oper = (SELECT ISNULL(SUM((SIGN(amt_discount * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) * ROUND(ABS(amt_discount * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) + 0.0000001, @oper_precision))),0.0)
						 FROM #appatrx_work
						 WHERE vendor_code = #appapto_work.vendor_code
						 AND pay_to_code = #appapto_work.pay_to_code)
 		

	UPDATE #appapto_work
	 SET num_vouch_paid = (SELECT -ISNULL(SUM(old_paid_flag),0)
							FROM #appatrxv_work
							WHERE paid_flag != old_paid_flag
							AND vendor_code = #appapto_work.vendor_code
							AND pay_to_code = #appapto_work.pay_to_code)
	DROP TABLE #temp2

	END


IF ((@cls_flag = 1) OR (@cls2_flag = 1))
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/appavas.sp" + ", line " + STR( 247, 5 ) + " -- MSG: " + "Process Class Activity/Summary"

	SELECT class_code, trx_ctrl_num = MAX(trx_ctrl_num)
	INTO #temp3
	FROM #appatrx_work
	GROUP BY class_code



 	INSERT #appacls_work (
			class_code,			date_last_void,		amt_last_void,
			last_void_doc,		last_void_acct,		last_void_cur,	
			num_vouch_paid,	
			num_void,			amt_void,			amt_disc_voided,
			amt_void_oper,		amt_disc_voided_oper,
			rate_home,			rate_oper,			db_action )
 	SELECT 
			b.class_code,		a.date_applied,		a.amt_payment, 
			a.doc_ctrl_num,		a.cash_acct_code,	a.nat_cur_code, 
			0,
			0,					0.0,				0.0,
			0.0,				0.0,
			a.rate_home,		a.rate_oper,		0
	FROM #appapyt_work a, #temp3 b
	WHERE a.trx_ctrl_num = b.trx_ctrl_num

	UPDATE #appacls_work
	SET num_void = (SELECT COUNT(*)
						 FROM #appatrx_work
						 WHERE class_code = #appacls_work.class_code),
	 amt_void = (SELECT ISNULL(SUM((SIGN(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) * ROUND(ABS(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) + 0.0000001, @home_precision))),0.0)
						 FROM #appatrx_work
						 WHERE void_flag IN (1,2,3,5)
						 AND class_code = #appacls_work.class_code),
	 amt_void_oper = (SELECT ISNULL(SUM((SIGN(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) * ROUND(ABS(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) + 0.0000001, @oper_precision))),0.0)
						 FROM #appatrx_work
						 WHERE void_flag IN (1,2,3,5)
						 AND class_code = #appacls_work.class_code),
	 amt_disc_voided = (SELECT ISNULL(SUM((SIGN(amt_discount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) * ROUND(ABS(amt_discount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) + 0.0000001, @home_precision))),0.0)
						 FROM #appatrx_work
						 WHERE class_code = #appacls_work.class_code),
	 amt_disc_voided_oper = (SELECT ISNULL(SUM((SIGN(amt_discount * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) * ROUND(ABS(amt_discount * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) + 0.0000001, @oper_precision))),0.0)
						 FROM #appatrx_work
						 WHERE class_code = #appacls_work.class_code)


	UPDATE #appacls_work
	 SET num_vouch_paid = (SELECT -ISNULL(SUM(old_paid_flag),0)
							FROM #appatrxv_work
							WHERE paid_flag != old_paid_flag
							AND class_code = #appacls_work.class_code)

	 DROP TABLE #temp3

 END


IF ((@bch_flag = 1) OR (@bch2_flag = 1))
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/appavas.sp" + ", line " + STR( 306, 5 ) + " -- MSG: " + "Process Branch Activity/Summary"


	SELECT branch_code, trx_ctrl_num = MAX(trx_ctrl_num)
	INTO #temp4
	FROM #appatrx_work
	GROUP BY branch_code

 	INSERT #appabch_work (
			branch_code,		date_last_void,		amt_last_void,
			last_void_doc,		last_void_acct,		last_void_cur,	
			num_vouch_paid,	
			num_void,			amt_void,			amt_disc_voided,		
			amt_void_oper,		amt_disc_voided_oper,
			rate_home,			rate_oper,			db_action )
 	SELECT 
			b.branch_code, a.date_applied,		a.amt_payment, 
			a.doc_ctrl_num, a.cash_acct_code,	a.nat_cur_code,
			0, 
			0, 0.0,				0.0,
			0.0,				0.0,				
			a.rate_home,		a.rate_oper,		0
	FROM #appapyt_work a, #temp4 b
	WHERE a.trx_ctrl_num = b.trx_ctrl_num

	UPDATE #appabch_work
	SET 
 		num_void = (SELECT COUNT(*)
						 FROM #appatrx_work
						 WHERE branch_code = #appabch_work.branch_code),
	 amt_void = (SELECT ISNULL(SUM((SIGN(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) * ROUND(ABS(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) + 0.0000001, @home_precision))),0.0)
						 FROM #appatrx_work
						 WHERE void_flag IN (1,2,3,5)
						 AND branch_code = #appabch_work.branch_code),
	 amt_void_oper = (SELECT ISNULL(SUM((SIGN(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) * ROUND(ABS(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) + 0.0000001, @oper_precision))),0.0)
						 FROM #appatrx_work
						 WHERE void_flag IN (1,2,3,5)
						 AND branch_code = #appabch_work.branch_code),
	 amt_disc_voided = (SELECT ISNULL(SUM((SIGN(amt_discount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) * ROUND(ABS(amt_discount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) + 0.0000001, @home_precision))),0.0)
						 FROM #appatrx_work
						 WHERE branch_code = #appabch_work.branch_code),
	 amt_disc_voided_oper = (SELECT ISNULL(SUM((SIGN(amt_discount * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) * ROUND(ABS(amt_discount * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) + 0.0000001, @oper_precision))),0.0)
						 FROM #appatrx_work
						 WHERE branch_code = #appabch_work.branch_code)


	UPDATE #appabch_work
	 SET num_vouch_paid = (SELECT -ISNULL(SUM(old_paid_flag),0)
							FROM #appatrxv_work
							WHERE paid_flag != old_paid_flag
							AND branch_code = #appabch_work.branch_code)

	DROP TABLE #temp4

 END

	 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/appavas.sp" + ", line " + STR( 364, 5 ) + " -- EXIT: "
RETURN 0

GO
GRANT EXECUTE ON  [dbo].[APPAVendorActSum_sp] TO [public]
GO
