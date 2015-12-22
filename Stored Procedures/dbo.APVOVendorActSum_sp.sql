SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




CREATE PROC [dbo].[APVOVendorActSum_sp]         @debug_level smallint = 0

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
	  @amt_extended float,
	  @amt_extended_oper float,
	  @home_precision smallint,
	  @oper_precision smallint



 DECLARE @temp1 TABLE(vendor_code varchar(12), 
		trx_ctrl_num varchar(16))
 Declare @temp2 TABLE (vendor_code varchar(12), 
		pay_to_code varchar(8), 
		trx_ctrl_num varchar(16))
 DECLARE @temp3 TABLE (class_code varchar(8),
		trx_ctrl_num varchar(16))
 DECLARE @temp4 TABLE (branch_code varchar(16),
		trx_ctrl_num varchar(16)) 



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvovas.cpp" + ", line " + STR( 80, 5 ) + " -- ENTRY: "


SELECT  @vend_flag = apactvnd_flag,
		@pto_flag = apactpto_flag,
		@cls_flag = apactcls_flag,
		@bch_flag = apactbch_flag,
		@vend2_flag = apsumvnd_flag,
		@pto2_flag = apsumpto_flag,
		@cls2_flag = apsumcls_flag,
		@bch2_flag = apsumbch_flag
FROM    apco






 
SELECT @home_precision = b.curr_precision,
	   @oper_precision =  c.curr_precision
FROM glco a, glcurr_vw b, glcurr_vw c
WHERE a.home_currency = b.currency_code
AND a.oper_currency = c.currency_code

IF ((@vend_flag = 1) OR (@vend2_flag = 1))
   BEGIN

   IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvovas.cpp" + ", line " + STR( 108, 5 ) + " -- MSG: " + "Process Vendor Activity/Summary"

	insert into @temp1
	SELECT vendor_code, trx_ctrl_num = MAX(trx_ctrl_num)
--	INTO #temp1	
	FROM #apvochg_work a
	GROUP BY vendor_code
	
	
	INSERT #apvovnd_work          (
			vendor_code,    date_last_vouch,        amt_last_vouch,      
			last_vouch_doc, last_vouch_cur,
			num_vouch,              amt_vouch,                      amt_vouch_oper,
			rate_home,              rate_oper,
			db_action )
	SELECT      
			a.vendor_code,  a.date_applied,         (SIGN(a.amt_net) * ROUND(ABS(a.amt_net) + 0.0000001, 6)),  
			a.trx_ctrl_num, a.nat_cur_code, 
			0,                              0.0,                            0.0,
			a.rate_home,    a.rate_oper,
			0
--	FROM  #apvochg_work a, #temp1 b
	FROM  #apvochg_work a, @temp1 b
	WHERE a.trx_ctrl_num = b.trx_ctrl_num 

  


	UPDATE #apvovnd_work
	SET num_vouch = ISNULL((SELECT COUNT(1)
						  FROM #apvochg_work
						  WHERE vendor_code = #apvovnd_work.vendor_code),0),
	    amt_vouch = (SELECT ISNULL(SUM((SIGN(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) * ROUND(ABS(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) + 0.0000001, @home_precision))),0)
						  FROM #apvochg_work
						  WHERE vendor_code = #apvovnd_work.vendor_code),
	    amt_vouch_oper = (SELECT ISNULL(SUM((SIGN(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) * ROUND(ABS(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) + 0.0000001, @oper_precision))),0)
						  FROM #apvochg_work
						  WHERE vendor_code = #apvovnd_work.vendor_code)
	FROM #apvovnd_work


--	DROP TABLE #temp1       

	END


IF ((@pto_flag = 1) OR (@pto2_flag = 1))
   BEGIN
   IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvovas.cpp" + ", line " + STR( 156, 5 ) + " -- MSG: " + "Process Pay to Activity/Summary"
   
	INSERT into @temp2
	SELECT vendor_code, pay_to_code, trx_ctrl_num = MAX(trx_ctrl_num)
--	INTO #temp2
	FROM #apvochg_work
	WHERE pay_to_code != ""
	GROUP BY vendor_code, pay_to_code

	INSERT #apvopto_work          (
			vendor_code,            pay_to_code,    date_last_vouch,
			amt_last_vouch,         last_vouch_doc, last_vouch_cur, 
			num_vouch,
			amt_vouch,                      amt_vouch_oper, 
			rate_home,                      rate_oper,
			db_action )
	SELECT      
			a.vendor_code,          a.pay_to_code,  a.date_applied,
			(SIGN(a.amt_net) * ROUND(ABS(a.amt_net) + 0.0000001, 6)),     a.doc_ctrl_num, a.nat_cur_code, 
			0,
			0.0,                            0.0,                    
			a.rate_home,            a.rate_oper,
			0
--	FROM  #apvochg_work a, #temp2 b
	FROM  #apvochg_work a, @temp2 b
	WHERE a.trx_ctrl_num = b.trx_ctrl_num 


  


	UPDATE #apvopto_work
	SET num_vouch = ISNULL((SELECT COUNT(1)
						  FROM #apvochg_work
						  WHERE vendor_code = #apvopto_work.vendor_code
						  AND pay_to_code = #apvopto_work.pay_to_code),0),
	    amt_vouch = (SELECT ISNULL(SUM((SIGN(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) * ROUND(ABS(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) + 0.0000001, @home_precision))),0)
						  FROM #apvochg_work
						  WHERE vendor_code = #apvopto_work.vendor_code
						  AND pay_to_code = #apvopto_work.pay_to_code),
	    amt_vouch_oper = (SELECT ISNULL(SUM((SIGN(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) * ROUND(ABS(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) + 0.0000001, @oper_precision))),0)
						  FROM #apvochg_work
						  WHERE vendor_code = #apvopto_work.vendor_code
						  AND pay_to_code = #apvopto_work.pay_to_code)
	FROM #apvopto_work

		
--	 DROP TABLE #temp2
			
	END



IF ((@cls_flag = 1) OR (@cls2_flag = 1))
   BEGIN
      IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvovas.cpp" + ", line " + STR( 211, 5 ) + " -- MSG: " + "Process Class Activity/Summary"

	INSERT INTO @temp3
	SELECT class_code, trx_ctrl_num = MAX(trx_ctrl_num)
--	INTO #temp3
	FROM #apvochg_work
	GROUP BY class_code

	INSERT #apvocls_work          (
			class_code,             date_last_vouch,        amt_last_vouch,      
			last_vouch_doc, last_vouch_cur,
			num_vouch,              amt_vouch,                      amt_vouch_oper,
			rate_home,              rate_oper,

			db_action )
	SELECT      
			a.class_code,   a.date_applied,         (SIGN(a.amt_net) * ROUND(ABS(a.amt_net) + 0.0000001, 6)),  
			a.trx_ctrl_num, a.nat_cur_code,
			0,                              0.0,                            0.0,
			a.rate_home,    a.rate_oper,
			0
--	FROM  #apvochg_work a, #temp3 b
	FROM  #apvochg_work a, @temp3 b
	WHERE a.trx_ctrl_num = b.trx_ctrl_num

  


	UPDATE #apvocls_work
	SET num_vouch = ISNULL((SELECT COUNT(1)
						  FROM #apvochg_work
						  WHERE class_code = #apvocls_work.class_code),0),
	    amt_vouch = (SELECT ISNULL(SUM((SIGN(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) * ROUND(ABS(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) + 0.0000001, @home_precision))),0)
						  FROM #apvochg_work
						  WHERE class_code = #apvocls_work.class_code),
	    amt_vouch_oper = (SELECT ISNULL(SUM((SIGN(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) * ROUND(ABS(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) + 0.0000001, @oper_precision))),0)
						  FROM #apvochg_work
						  WHERE class_code = #apvocls_work.class_code)
	FROM #apvocls_work

		
--	DROP TABLE #temp3

 END


IF ((@bch_flag = 1) OR (@bch2_flag = 1))

   BEGIN
      IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvovas.cpp" + ", line " + STR( 260, 5 ) + " -- MSG: " + "Process Branch Activity/Summary"

	insert INTO @temp4
	SELECT branch_code, trx_ctrl_num = MAX(trx_ctrl_num)
--	INTO #temp4
	FROM #apvochg_work
	GROUP BY branch_code
	
	INSERT #apvobch_work          (
			branch_code,    date_last_vouch,        amt_last_vouch,      
			last_vouch_doc, last_vouch_cur, 
			num_vouch,              amt_vouch,                      amt_vouch_oper,
			rate_home,              rate_oper,
			db_action )
	SELECT      
			a.branch_code,  a.date_applied,         (SIGN(a.amt_net) * ROUND(ABS(a.amt_net) + 0.0000001, 6)),  
			a.trx_ctrl_num, a.nat_cur_code, 
			0,                                      0.0,                    0.0,
			a.rate_home,    a.rate_oper,
			0
--	FROM  #apvochg_work a, #temp4 b
	FROM  #apvochg_work a, @temp4 b
	WHERE a.trx_ctrl_num = b.trx_ctrl_num

  


	UPDATE #apvobch_work
	SET num_vouch = ISNULL((SELECT COUNT(*)
						  FROM #apvochg_work
						  WHERE branch_code = #apvobch_work.branch_code),0),
	    amt_vouch = (SELECT ISNULL(SUM((SIGN(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) * ROUND(ABS(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) + 0.0000001, @home_precision))),0)
						  FROM #apvochg_work
						  WHERE branch_code = #apvobch_work.branch_code),
	    amt_vouch_oper = (SELECT ISNULL(SUM((SIGN(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) * ROUND(ABS(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) + 0.0000001, @oper_precision))),0)
						  FROM #apvochg_work
						  WHERE branch_code = #apvobch_work.branch_code)
	FROM #apvobch_work

--	DROP TABLE #temp4

  END


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apvovas.cpp" + ", line " + STR( 304, 5 ) + " -- EXIT: "
RETURN 0

GO
GRANT EXECUTE ON  [dbo].[APVOVendorActSum_sp] TO [public]
GO
