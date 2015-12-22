SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




CREATE PROC [dbo].[APPYVendorActSum_sp]  	@debug_level smallint = 0

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

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appyvas.cpp" + ", line " + STR( 92, 5 ) + " -- ENTRY: "


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

   IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appyvas.cpp" + ", line " + STR( 120, 5 ) + " -- MSG: " + "Insert #appyvnd_work"

	INSERT @temp1
	SELECT vendor_code, trx_ctrl_num = MAX(trx_ctrl_num)
	FROM #appypyt_work
	WHERE payment_type = 1
	GROUP BY vendor_code


   	INSERT #appyvnd_work          (
			vendor_code,       date_last_pyt,          	amt_last_pyt,      
			last_pyt_doc,      last_pyt_acct,		   	last_pyt_cur,
			num_vouch_paid,         
			num_overdue_pyt,   days_pay,				days_overdue,      
			num_pyt,		   amt_pyt,					amt_disc_taken,
			amt_pyt_oper,	   amt_disc_taken_oper,
			rate_home,		   rate_oper,		   
			db_action )
    	SELECT      
			a.vendor_code,        	a.date_applied,     a.amt_payment,  
			a.doc_ctrl_num,       	a.cash_acct_code,	a.nat_cur_code,	
			0,                    
			0,                    	0,				   	0,                    
			0,						0.0,				0.0,
			0.0,					0.0,
			a.rate_home,			a.rate_oper,
			0
	FROM  #appypyt_work a, @temp1 b
	WHERE a.trx_ctrl_num = b.trx_ctrl_num



  	UPDATE #appyvnd_work
	SET num_vouch_paid = (SELECT ISNULL(SUM(paid_flag),0)
						  FROM #appytrxv_work
						  WHERE paid_flag = 1
						  AND vendor_code = #appyvnd_work.vendor_code)

    UPDATE #appyvnd_work   
    SET   num_overdue_pyt = (SELECT ISNULL(SUM(paid_flag),0) 
						  FROM #appytrxv_work
						  WHERE paid_flag = 1
						  AND date_paid > date_due
						  AND vendor_code = #appyvnd_work.vendor_code)
	
	
   UPDATE #appyvnd_work	
	 SET  num_pyt = ISNULL((SELECT COUNT(1)
						  FROM #appytrx_work
						  WHERE vendor_code = #appyvnd_work.vendor_code),0),
	   amt_pyt = (SELECT ISNULL(SUM((SIGN(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) * ROUND(ABS(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) + 0.0000001, @home_precision))),0.0)
						  FROM #appytrx_work
						  WHERE vendor_code = #appyvnd_work.vendor_code),		
	   amt_pyt_oper = (SELECT ISNULL(SUM((SIGN(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) * ROUND(ABS(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) + 0.0000001, @oper_precision))),0.0)
						  FROM #appytrx_work
						  WHERE vendor_code = #appyvnd_work.vendor_code),		
	   amt_disc_taken = (SELECT ISNULL(SUM((SIGN(amt_discount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) * ROUND(ABS(amt_discount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) + 0.0000001, @home_precision))),0.0)
						  FROM #appytrx_work
						  WHERE vendor_code = #appyvnd_work.vendor_code),
	   amt_disc_taken_oper = (SELECT ISNULL(SUM((SIGN(amt_discount * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) * ROUND(ABS(amt_discount * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) + 0.0000001, @oper_precision))),0.0)
						  FROM #appytrx_work
						  WHERE vendor_code = #appyvnd_work.vendor_code)
	FROM #appyvnd_work



	UPDATE #appyvnd_work
		SET days_pay = (SELECT ISNULL(SUM(date_paid - date_applied),0.0)
						   FROM #appytrxv_work
  						   WHERE paid_flag = 1
						   AND date_paid > date_applied
						   AND vendor_code = #appyvnd_work.vendor_code)
		

	UPDATE #appyvnd_work
		 SET days_overdue = (SELECT ISNULL(SUM(date_paid - date_due),0.0)
						   FROM #appytrxv_work
  						   WHERE paid_flag = 1
						   AND date_paid > date_due
						   AND vendor_code = #appyvnd_work.vendor_code)

  
  		



	END


IF ((@pto_flag = 1) OR (@pto2_flag = 1))
   BEGIN
   IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appyvas.cpp" + ", line " + STR( 211, 5 ) + " -- MSG: " + "Process Pay to Activity/Summary"
   
	INSERT @temp2
	SELECT vendor_code, pay_to_code, trx_ctrl_num = MAX(trx_ctrl_num)
	FROM #appypyt_work
	WHERE pay_to_code != ""
	AND payment_type = 1
	GROUP BY vendor_code, pay_to_code

       INSERT #appypto_work (
				vendor_code,            pay_to_code,    	date_last_pyt,
				amt_last_pyt,   		last_pyt_doc,		last_pyt_acct,
				last_pyt_cur,
				num_vouch_paid,			num_overdue_pyt,	days_pay,   
				days_overdue,			num_pyt,			amt_pyt,
				amt_disc_taken,			
				amt_pyt_oper,			amt_disc_taken_oper,
				rate_home,				rate_oper,		   
				db_action ) 
	SELECT  		
				a.vendor_code,          a.pay_to_code,    	a.date_applied,
				a.amt_payment, 			a.doc_ctrl_num,		a.cash_acct_code,
				a.nat_cur_code,
				0,                      0,              	0,
				0,                      0,					0.0,
				0.0,					
				0.0,					0.0,
				a.rate_home,			a.rate_oper,
				0
	FROM  #appypyt_work a, @temp2 b
	WHERE a.trx_ctrl_num = b.trx_ctrl_num

	UPDATE #appypto_work
	SET num_vouch_paid = (SELECT ISNULL(SUM(paid_flag),0) 
						  FROM #appytrxv_work
						  WHERE paid_flag = 1
						  AND vendor_code = #appypto_work.vendor_code
						  AND pay_to_code = #appypto_work.pay_to_code)
	 
	UPDATE #appypto_work
	SET	num_overdue_pyt = (SELECT ISNULL(SUM(paid_flag),0)
						  FROM #appytrxv_work
						  WHERE paid_flag = 1
						  AND date_paid > date_due
						  AND vendor_code = #appypto_work.vendor_code
						  AND pay_to_code = #appypto_work.pay_to_code)
	   
	UPDATE #appypto_work   
	  SET  num_pyt = (SELECT ISNULL(COUNT(1),0)
						  FROM #appytrx_work
						  WHERE vendor_code = #appypto_work.vendor_code
						  AND pay_to_code = #appypto_work.pay_to_code),
	   amt_pyt = (SELECT ISNULL(SUM((SIGN(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) * ROUND(ABS(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) + 0.0000001, @home_precision))),0)
						  FROM #appytrx_work
						  WHERE vendor_code = #appypto_work.vendor_code
						  AND pay_to_code = #appypto_work.pay_to_code),
	   amt_pyt_oper = (SELECT ISNULL(SUM((SIGN(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) * ROUND(ABS(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) + 0.0000001, @oper_precision))),0)
						  FROM #appytrx_work
						  WHERE vendor_code = #appypto_work.vendor_code
						  AND pay_to_code = #appypto_work.pay_to_code),
	   amt_disc_taken = (SELECT ISNULL(SUM((SIGN(amt_discount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) * ROUND(ABS(amt_discount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) + 0.0000001, @home_precision))),0)
						  FROM #appytrx_work
						  WHERE vendor_code = #appypto_work.vendor_code
						  AND pay_to_code = #appypto_work.pay_to_code),
	   amt_disc_taken_oper = (SELECT ISNULL(SUM((SIGN(amt_discount * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) * ROUND(ABS(amt_discount * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) + 0.0000001, @oper_precision))),0)
						  FROM #appytrx_work
						  WHERE vendor_code = #appypto_work.vendor_code
						  AND pay_to_code = #appypto_work.pay_to_code)
	FROM #appypto_work


	UPDATE #appypto_work
		SET days_pay = (SELECT ISNULL(SUM(date_paid - date_applied),0.0)
						   FROM #appytrxv_work
  						   WHERE paid_flag = 1
						   AND date_paid > date_applied
						   AND vendor_code = #appypto_work.vendor_code
						   AND pay_to_code = #appypto_work.pay_to_code)
	UPDATE #appypto_work
		SET days_overdue = (SELECT ISNULL(SUM(date_paid - date_due),0.0)
						   FROM #appytrxv_work
  						   WHERE paid_flag = 1
						   AND date_paid > date_due
						   AND vendor_code = #appypto_work.vendor_code
						   AND pay_to_code = #appypto_work.pay_to_code)



	END



IF ((@cls_flag = 1) OR (@cls2_flag = 1))
   BEGIN
      IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appyvas.cpp" + ", line " + STR( 305, 5 ) + " -- MSG: " + "Process Class Activity/Summary"

	INSERT @temp3
	SELECT class_code, trx_ctrl_num = MAX(trx_ctrl_num)
	FROM #appytrx_work
	GROUP BY class_code


   INSERT #appycls_work (
		class_code,     	date_last_pyt,          amt_last_pyt,   
		last_pyt_doc,   	last_pyt_acct,			last_pyt_cur,			
		num_vouch_paid,         
		num_overdue_pyt,	days_pay,				days_overdue,
		num_pyt,			amt_pyt,				amt_disc_taken,		
 		amt_pyt_oper,		amt_disc_taken_oper,
 		rate_home,			rate_oper,		   
		db_action )
	SELECT  DISTINCT
		b.class_code,		a.date_applied,         a.amt_payment,  
		a.doc_ctrl_num, 	a.cash_acct_code,		a.nat_cur_code,		
		0,
		0,              	0,                      0,
		0,					0.0,					0.0,
		0.0,  				0.0,
		a.rate_home,		a.rate_oper,
		0
	FROM  #appypyt_work a, @temp3 b
	WHERE  a.trx_ctrl_num = b.trx_ctrl_num

	UPDATE #appycls_work
	SET 
  		num_vouch_paid = (SELECT ISNULL(SUM(paid_flag),0) 
						  FROM #appytrxv_work
						  WHERE paid_flag = 1
						  AND class_code = #appycls_work.class_code)

	UPDATE #appycls_work
	SET	num_overdue_pyt = (SELECT ISNULL(SUM(paid_flag),0)
						  FROM #appytrxv_work
						  WHERE paid_flag = 1
						  AND date_paid > date_due
						  AND class_code = #appycls_work.class_code)
	UPDATE #appycls_work
	   SET num_pyt = (SELECT ISNULL(COUNT(1),0)
						  FROM #appytrx_work
						  WHERE class_code = #appycls_work.class_code),
	   amt_pyt = (SELECT ISNULL(SUM((SIGN(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) * ROUND(ABS(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) + 0.0000001, @home_precision))),0)
						  FROM #appytrx_work
						  WHERE class_code = #appycls_work.class_code),
	   amt_pyt_oper = (SELECT ISNULL(SUM((SIGN(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) * ROUND(ABS(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) + 0.0000001, @oper_precision))),0)
						  FROM #appytrx_work
						  WHERE class_code = #appycls_work.class_code),
	   amt_disc_taken = (SELECT ISNULL(SUM((SIGN(amt_discount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) * ROUND(ABS(amt_discount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) + 0.0000001, @home_precision))),0)
						  FROM #appytrx_work
						  WHERE	class_code = #appycls_work.class_code),
	   amt_disc_taken_oper = (SELECT ISNULL(SUM((SIGN(amt_discount * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) * ROUND(ABS(amt_discount * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) + 0.0000001, @oper_precision))),0)
						  FROM #appytrx_work
						  WHERE	class_code = #appycls_work.class_code)
	FROM #appycls_work

	UPDATE #appycls_work
		SET days_pay = (SELECT ISNULL(SUM(date_paid - date_applied),0.0)
						   FROM #appytrxv_work
  						   WHERE paid_flag = 1
						   AND date_paid > date_applied
						   AND class_code = #appycls_work.class_code)

	UPDATE #appycls_work
		SET days_overdue = (SELECT ISNULL(SUM(date_paid - date_due),0.0)
						   FROM #appytrxv_work 
  						   WHERE paid_flag = 1
						   AND date_paid > date_due
						   AND class_code = #appycls_work.class_code)
	


 END


IF ((@bch_flag = 1) OR (@bch2_flag = 1))

   BEGIN
      IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appyvas.cpp" + ", line " + STR( 387, 5 ) + " -- MSG: " + "Process Branch Activity/Summary"

	INSERT @temp4
	SELECT branch_code, trx_ctrl_num = MAX(trx_ctrl_num)
	FROM #appytrx_work 
	GROUP BY branch_code


	INSERT #appybch_work (
		branch_code,    	date_last_pyt,          amt_last_pyt,   
		last_pyt_doc,   	last_pyt_acct,			last_pyt_cur,
		num_vouch_paid,         
		num_overdue_pyt,	days_pay,				days_overdue,     
		num_pyt,			amt_pyt,				amt_disc_taken,
  		amt_pyt_oper,		amt_disc_taken_oper,
 		rate_home,			rate_oper,		   
		db_action )
	SELECT  DISTINCT 
		b.branch_code,  	a.date_applied,         a.amt_payment,  
		a.doc_ctrl_num, 	a.cash_acct_code,		a.nat_cur_code,		
		0,
		0,              	0,                      0,
		0,					0.0,					0.0,
		0.0,				0.0,
		a.rate_home,  		a.rate_oper,
		0
		FROM  #appypyt_work a, @temp4 b
	WHERE a.trx_ctrl_num = b.trx_ctrl_num

	UPDATE #appybch_work
	SET 
	   	num_vouch_paid = (SELECT ISNULL(SUM(paid_flag),0)
						  FROM #appytrxv_work
						  WHERE paid_flag = 1
						  AND branch_code = #appybch_work.branch_code)
	UPDATE #appybch_work
	SET	num_overdue_pyt = (SELECT  ISNULL(SUM(paid_flag),0)
						  FROM #appytrxv_work
						  WHERE paid_flag = 1
						  AND date_paid > date_due
						  AND branch_code = #appybch_work.branch_code)
	UPDATE #appybch_work   
	   SET num_pyt = (SELECT ISNULL(COUNT(1),0)
						  FROM #appytrx_work
						  WHERE branch_code = #appybch_work.branch_code),
	   amt_pyt = (SELECT ISNULL(SUM((SIGN(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) * ROUND(ABS(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) + 0.0000001, @home_precision))),0)
						  FROM #appytrx_work
						  WHERE branch_code = #appybch_work.branch_code),
	   amt_pyt_oper = (SELECT ISNULL(SUM((SIGN(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) * ROUND(ABS(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) + 0.0000001, @oper_precision))),0)
						  FROM #appytrx_work
						  WHERE branch_code = #appybch_work.branch_code),
	   amt_disc_taken = (SELECT ISNULL(SUM((SIGN(amt_discount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) * ROUND(ABS(amt_discount * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) + 0.0000001, @home_precision))),0)
						  FROM #appytrx_work
						  WHERE branch_code = #appybch_work.branch_code),
	   amt_disc_taken_oper = (SELECT ISNULL(SUM((SIGN(amt_discount * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) * ROUND(ABS(amt_discount * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) + 0.0000001, @oper_precision))),0)
						  FROM #appytrx_work
						  WHERE branch_code = #appybch_work.branch_code)
	FROM #appybch_work

	UPDATE #appybch_work
		SET days_pay = (SELECT ISNULL(SUM(date_paid - date_applied),0.0)
						   FROM #appytrxv_work
  						   WHERE paid_flag = 1
						   AND date_paid > date_applied
						   AND branch_code = #appybch_work.branch_code)

	UPDATE #appybch_work
		SET days_overdue = (SELECT ISNULL(SUM(date_paid - date_due),0.0)
						   FROM #appytrxv_work
  						   WHERE paid_flag = 1
						   AND date_paid > date_due
						   AND branch_code = #appybch_work.branch_code)
  



  END




IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "appyvas.cpp" + ", line " + STR( 468, 5 ) + " -- EXIT: "
RETURN 0

GO
GRANT EXECUTE ON  [dbo].[APPYVendorActSum_sp] TO [public]
GO
