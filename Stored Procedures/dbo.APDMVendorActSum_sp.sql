SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




CREATE PROC [dbo].[APDMVendorActSum_sp]  	@debug_level smallint = 0

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

 DECLARE @temp1 TABLE(vendor_code varchar(12), 
		trx_ctrl_num varchar(16))
 DECLARE @temp2 TABLE (vendor_code varchar(12), 
		pay_to_code varchar(8), 
		trx_ctrl_num varchar(16))
 DECLARE @temp3 TABLE (class_code varchar(8),
		trx_ctrl_num varchar(16))
 DECLARE @temp4 TABLE (branch_code varchar(16),
		trx_ctrl_num varchar(16)) 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdmvas.cpp" + ", line " + STR( 74, 5 ) + " -- ENTRY: "


SELECT  @vend_flag = apactvnd_flag,
		@pto_flag = apactpto_flag,
		@cls_flag = apactcls_flag,
		@bch_flag = apactbch_flag,
		@vend2_flag = apsumvnd_flag,
		@pto2_flag = apsumpto_flag,
		@cls2_flag = apsumcls_flag,
		@bch2_flag = apsumbch_flag
FROM    apco




 
SELECT 	@home_precision = b.curr_precision,
	   	@oper_precision = c.curr_precision
FROM 	glco a, glcurr_vw b, glcurr_vw c
WHERE 	a.home_currency = b.currency_code
AND 	a.oper_currency = c.currency_code

IF ((@vend_flag = 1) OR (@vend2_flag = 1))
   BEGIN

   IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdmvas.cpp" + ", line " + STR( 100, 5 ) + " -- MSG: " + "Process Vendor Activity/Summary"

	INSERT @temp1
	SELECT vendor_code, trx_ctrl_num = MAX(trx_ctrl_num)
	FROM #apdmchg_work a
	GROUP BY vendor_code


   	INSERT #apdmvnd_work (
			vendor_code,       	date_last_dm,		amt_last_dm,      
			last_dm_doc,       	amt_balance,	   	num_dm,
			amt_dm,		   	   	last_dm_cur,	   	amt_dm_oper,	
			amt_balance_oper,	db_action )
    	SELECT      
			a.vendor_code,      a.date_applied,     (SIGN(a.amt_net) * ROUND(ABS(a.amt_net) + 0.0000001, 6)),  
			a.trx_ctrl_num,     0.0,                0,
			0.0,			   	a.nat_cur_code,  	0.0,						
			0.0,				0
	FROM  #apdmchg_work a, @temp1 b
	WHERE a.trx_ctrl_num = b.trx_ctrl_num

  


	UPDATE #apdmvnd_work
	SET amt_balance = (SELECT ISNULL( SUM( (SIGN(-amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) * ROUND(ABS(-amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) + 0.0000001, @home_precision))),0)
						FROM #apdmchg_work										
						WHERE vendor_code = #apdmvnd_work.vendor_code),
		amt_balance_oper = (SELECT ISNULL( SUM( (SIGN(-amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) * ROUND(ABS(-amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) + 0.0000001, @oper_precision))),0)
					   	FROM #apdmchg_work
						WHERE vendor_code = #apdmvnd_work.vendor_code),
	   	num_dm = ISNULL((SELECT COUNT(1)
						FROM #apdmchg_work
						WHERE vendor_code = #apdmvnd_work.vendor_code),0),
	   	amt_dm = (SELECT ISNULL( SUM( (SIGN(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) * ROUND(ABS(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) + 0.0000001, @home_precision))),0)
						FROM #apdmchg_work
						WHERE vendor_code = #apdmvnd_work.vendor_code),
	   	amt_dm_oper = (SELECT ISNULL( SUM( (SIGN(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) * ROUND(ABS(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) + 0.0000001, @oper_precision))),0)
						FROM #apdmchg_work
						WHERE vendor_code = #apdmvnd_work.vendor_code)
	FROM #apdmvnd_work




	END



IF ((@pto_flag = 1) OR (@pto2_flag = 1))
   BEGIN
   IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdmvas.cpp" + ", line " + STR( 151, 5 ) + " -- MSG: " + "Process Pay to Activity/Summary"
   
	INSERT @temp2
	SELECT vendor_code, pay_to_code, trx_ctrl_num = MAX(trx_ctrl_num)
	FROM #apdmchg_work a
	WHERE pay_to_code != ""
	GROUP BY vendor_code, pay_to_code


   	INSERT #apdmpto_work (
			vendor_code,       	pay_to_code, 		date_last_dm,		amt_last_dm,      
			last_dm_doc,       	amt_balance,	   	num_dm,
			amt_dm,		   	   	last_dm_cur,	   	amt_dm_oper,	
			amt_balance_oper,	db_action )
    	SELECT      
			a.vendor_code,      a.pay_to_code,   	a.date_applied,     (SIGN(a.amt_net) * ROUND(ABS(a.amt_net) + 0.0000001, 6)),  
			a.trx_ctrl_num,     0.0,                0,
			0.0,			   	a.nat_cur_code,  	0.0,						
			0.0,				0
	FROM  #apdmchg_work a, @temp2 b
	WHERE a.trx_ctrl_num = b.trx_ctrl_num


	UPDATE #apdmpto_work
	SET amt_balance = (SELECT ISNULL( SUM( (SIGN(-amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) * ROUND(ABS(-amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) + 0.0000001, @home_precision))),0)
						  FROM #apdmchg_work
						  WHERE vendor_code = #apdmpto_work.vendor_code
						  AND pay_to_code = #apdmpto_work.pay_to_code),
		amt_balance_oper = (SELECT ISNULL( SUM( (SIGN(-amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) * ROUND(ABS(-amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) + 0.0000001, @oper_precision))),0)
						  FROM #apdmchg_work
						  WHERE vendor_code = #apdmpto_work.vendor_code
						  AND pay_to_code = #apdmpto_work.pay_to_code),
	   num_dm = ISNULL((SELECT COUNT(1)
						  FROM #apdmchg_work
						  WHERE vendor_code = #apdmpto_work.vendor_code
						  AND pay_to_code = #apdmpto_work.pay_to_code),0),
	   amt_dm = (SELECT ISNULL( SUM( (SIGN(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) * ROUND(ABS(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) + 0.0000001, @home_precision))),0)
						  FROM #apdmchg_work
						  WHERE vendor_code = #apdmpto_work.vendor_code
						  AND pay_to_code = #apdmpto_work.pay_to_code),
	   amt_dm_oper = (SELECT ISNULL( SUM( (SIGN(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) * ROUND(ABS(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) + 0.0000001, @oper_precision))),0)
						  FROM #apdmchg_work
						  WHERE vendor_code = #apdmpto_work.vendor_code
						  AND pay_to_code = #apdmpto_work.pay_to_code)
	FROM #apdmpto_work

  		

			
	END



IF ((@cls_flag = 1) OR (@cls2_flag = 1))
   BEGIN
      IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdmvas.cpp" + ", line " + STR( 206, 5 ) + " -- MSG: " + "Process Class Activity/Summary"

	INSERT @temp3
	SELECT class_code, trx_ctrl_num = MAX(trx_ctrl_num)
	FROM #apdmchg_work a
	GROUP BY class_code


   	INSERT #apdmcls_work (
			class_code,       	date_last_dm,		amt_last_dm,      
			last_dm_doc,      	amt_balance,	   	num_dm,
			amt_dm,		   	   	last_dm_cur,	   	amt_dm_oper,	
			amt_balance_oper,	db_action )
    	SELECT      
			a.class_code,       a.date_applied,     (SIGN(a.amt_net) * ROUND(ABS(a.amt_net) + 0.0000001, 6)),  
			a.trx_ctrl_num,     0.0,                0,
			0.0,			   	a.nat_cur_code,  	0.0,						
			0.0,				0
	FROM  #apdmchg_work a, @temp3 b
	WHERE a.trx_ctrl_num = b.trx_ctrl_num

  
	UPDATE #apdmcls_work
	SET amt_balance = (SELECT ISNULL( SUM( (SIGN(-amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) * ROUND(ABS(-amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) + 0.0000001, @home_precision))),0)
					   	FROM #apdmchg_work
						WHERE class_code = #apdmcls_work.class_code),
		amt_balance_oper =  (SELECT ISNULL( SUM( (SIGN(-amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) * ROUND(ABS(-amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) + 0.0000001, @oper_precision))),0)
						FROM #apdmchg_work
						WHERE class_code = #apdmcls_work.class_code),
	   num_dm = ISNULL((SELECT COUNT(1)
						FROM #apdmchg_work
						WHERE class_code = #apdmcls_work.class_code),0),
	   amt_dm = (SELECT ISNULL( SUM( (SIGN(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) * ROUND(ABS(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) + 0.0000001, @home_precision))),0)
						FROM #apdmchg_work
						WHERE class_code = #apdmcls_work.class_code),
	   amt_dm_oper = (SELECT ISNULL( SUM( (SIGN(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) * ROUND(ABS(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) + 0.0000001, @oper_precision))),0)
						FROM #apdmchg_work
						WHERE class_code = #apdmcls_work.class_code)
	FROM #apdmcls_work

	

 END



IF ((@bch_flag = 1) OR (@bch2_flag = 1))

   BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdmvas.cpp" + ", line " + STR( 255, 5 ) + " -- MSG: " + "Process Branch Activity/Summary"

	INSERT @temp4
	SELECT branch_code, trx_ctrl_num = MAX(trx_ctrl_num)
	FROM #apdmchg_work a
	GROUP BY branch_code

   	INSERT #apdmbch_work (
			branch_code,        date_last_dm,	   	amt_last_dm,      
			last_dm_doc,        amt_balance,	   	num_dm,
			amt_dm,		   	   	last_dm_cur,	   	amt_dm_oper,	
			amt_balance_oper,	db_action )
    	SELECT      
			a.branch_code,      a.date_applied,     (SIGN(a.amt_net) * ROUND(ABS(a.amt_net) + 0.0000001, 6)),  
			a.trx_ctrl_num,     0.0,                0,
			0.0,			   	a.nat_cur_code,  	0.0,						
			0.0,				0
	FROM  #apdmchg_work a, @temp4 b
	WHERE a.trx_ctrl_num = b.trx_ctrl_num


	UPDATE #apdmbch_work
	SET amt_balance = (SELECT ISNULL( SUM( (SIGN(-amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) * ROUND(ABS(-amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) + 0.0000001, @home_precision))),0)
						FROM #apdmchg_work
						WHERE branch_code = #apdmbch_work.branch_code),
		amt_balance_oper = 	(SELECT ISNULL( SUM( (SIGN(-amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) * ROUND(ABS(-amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) + 0.0000001, @oper_precision))),0)
						FROM #apdmchg_work
						WHERE branch_code = #apdmbch_work.branch_code),
	   num_dm = ISNULL((SELECT COUNT(1)
						FROM #apdmchg_work
						WHERE branch_code = #apdmbch_work.branch_code),0),
	   amt_dm = (SELECT ISNULL( SUM( (SIGN(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) * ROUND(ABS(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) + 0.0000001, @home_precision))),0)
						FROM #apdmchg_work
						WHERE branch_code = #apdmbch_work.branch_code),
	   amt_dm_oper = (SELECT ISNULL( SUM( (SIGN(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) * ROUND(ABS(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) + 0.0000001, @oper_precision))),0)
						FROM #apdmchg_work
						WHERE branch_code = #apdmbch_work.branch_code)
	FROM #apdmbch_work



  END





IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apdmvas.cpp" + ", line " + STR( 302, 5 ) + " -- EXIT: "
RETURN 0

GO
GRANT EXECUTE ON  [dbo].[APDMVendorActSum_sp] TO [public]
GO
