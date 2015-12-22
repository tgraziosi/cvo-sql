SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE  PROCEDURE [dbo].[apvoact_sp]  @debug smallint = 0
				
AS

BEGIN

DECLARE

		@vend_flag        smallint,
		@pto_flag         smallint,
		@cls_flag         smallint,
		@bch_flag         smallint,
		@home_precision	smallint,
		@oper_precision	smallint





	SELECT  @vend_flag = apactvnd_flag,
	@pto_flag = apactpto_flag,
	@cls_flag = apactcls_flag,
	@bch_flag = apactbch_flag
		FROM    apco


SELECT @home_precision = b.curr_precision,
	   @oper_precision =  c.curr_precision
FROM glco a, glcurr_vw b, glcurr_vw c
WHERE a.home_currency = b.currency_code
AND a.oper_currency = c.currency_code


  
		
if ((@vend_flag = 1) OR 
	(@pto_flag = 1) OR
	(@bch_flag = 1) OR
	(@cls_flag = 1))


  
  IF (@vend_flag = 1)
  BEGIN

	 INSERT #apvtemp (code,code2,amt_net_home,amt_net_oper)
	 SELECT DISTINCT vendor_code,'', 
	 	amt_net_home = sum((SIGN(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) * ROUND(ABS(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) + 0.0000001, @home_precision))),
	 	amt_net_oper = sum((SIGN(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) * ROUND(ABS(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) + 0.0000001, @oper_precision)))
	 FROM #apinpchg
	 GROUP BY vendor_code
		 
	  
	  UPDATE apactvnd
	  SET amt_vouch_unposted = apactvnd.amt_vouch_unposted + b.amt_net_home,
		  amt_vouch_unposted_oper = apactvnd.amt_vouch_unposted_oper + b.amt_net_oper
	  FROM apactvnd,#apvtemp      b
	  WHERE apactvnd.vendor_code = b.code



	 
	  UPDATE #apinpchg
	  SET mark_flag = 1
	  FROM #apinpchg,apactvnd b
	  WHERE #apinpchg.vendor_code = b.vendor_code

	  
		INSERT apactvnd
		   (
			vendor_code,
			date_last_vouch,
			date_last_dm,
			date_last_adj,
			date_last_pyt,
			date_last_void,
			amt_last_vouch,
			amt_last_dm,
			amt_last_adj,
			amt_last_pyt,
			amt_last_void,
			amt_age_bracket1,
			amt_age_bracket2,
			amt_age_bracket3,
			amt_age_bracket4,
			amt_age_bracket5,
			amt_age_bracket6,
			amt_on_order,
			amt_vouch_unposted,
			last_vouch_doc,
			last_dm_doc,
			last_adj_doc,
			last_pyt_doc,
			last_pyt_acct,
			last_void_doc,
			last_void_acct,
			high_amt_ap,
			high_amt_vouch,
			high_date_ap,
			high_date_vouch,
			num_vouch,
			num_vouch_paid,
			num_overdue_pyt,
			avg_days_pay,
			avg_days_overdue,
			last_trx_time,
			amt_balance,
			last_vouch_cur,
			last_dm_cur,
			last_adj_cur,
			last_pyt_cur,
			last_void_cur,
			amt_age_bracket1_oper,
			amt_age_bracket2_oper,
			amt_age_bracket3_oper,
			amt_age_bracket4_oper,
			amt_age_bracket5_oper,
			amt_age_bracket6_oper,
			amt_balance_oper,
			amt_on_order_oper,
			amt_vouch_unposted_oper,
			high_amt_ap_oper
			)
			SELECT DISTINCT
				vendor_code,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				'',
				'',
				'',
				'',
				'',
				'',
				'',
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				'',
				'',
				'',
				'',
				'',
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0  
			FROM #apinpchg                    
			WHERE mark_flag = 0

	  
	  UPDATE #apinpchg
	  SET mark_flag = 0  
		  
	  DELETE #apvtemp
		 
  END


              
IF (@pto_flag = 1)
  BEGIN


	 INSERT #apvtemp(code,code2,amt_net_home,amt_net_oper)
	 SELECT DISTINCT vendor_code, pay_to_code,
	 	amt_net_home = sum((SIGN(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) * ROUND(ABS(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) + 0.0000001, @home_precision))),
	 	amt_net_oper = sum((SIGN(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) * ROUND(ABS(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) + 0.0000001, @oper_precision)))
	 FROM #apinpchg
	 WHERE mark_flag = 0
	 AND pay_to_code != ''
	 GROUP BY vendor_code, pay_to_code

		 
	 
	 UPDATE apactpto
	 SET amt_vouch_unposted = apactpto.amt_vouch_unposted + b.amt_net_home,
	     amt_vouch_unposted_oper = apactpto.amt_vouch_unposted_oper + b.amt_net_oper
	 FROM apactpto,#apvtemp      b
	 WHERE apactpto.vendor_code = b.code
	 AND   apactpto.pay_to_code = b.code2
	 
     
	 UPDATE #apinpchg
	 SET mark_flag = 2
	 FROM #apinpchg,apvend b
	 WHERE #apinpchg.vendor_code = b.vendor_code
	 AND #apinpchg.pay_to_code != ''
	 AND pay_to_hist_flag = 0
	 
	 
	 UPDATE #apinpchg
	 SET mark_flag = 1
	 FROM #apinpchg a,apactpto b
	 WHERE a.vendor_code = b.vendor_code
	 AND a.pay_to_code = b.pay_to_code
	 AND a.pay_to_code != ''

	 
	 INSERT apactpto
		   (
			vendor_code,
			pay_to_code,
			date_last_vouch,
			date_last_dm,
			date_last_adj,
			date_last_pyt,
			date_last_void,
			amt_last_vouch,
			amt_last_dm,
			amt_last_adj,
			amt_last_pyt,
			amt_last_void,
			amt_age_bracket1,
			amt_age_bracket2,
			amt_age_bracket3,
			amt_age_bracket4,
			amt_age_bracket5,
			amt_age_bracket6,
			amt_on_order,
			amt_vouch_unposted,
			last_vouch_doc,
			last_dm_doc,
			last_adj_doc,
			last_pyt_doc,
			last_pyt_acct,
			last_void_doc,
			last_void_acct,
			high_amt_ap,
			high_amt_vouch,
			high_date_ap,
			high_date_vouch,
			num_vouch,
			num_vouch_paid,
			num_overdue_pyt,
			avg_days_pay,
			avg_days_overdue,
			last_trx_time,
			amt_balance,
			last_vouch_cur,
			last_dm_cur,
			last_adj_cur,
			last_pyt_cur,
			last_void_cur,
			amt_age_bracket1_oper,
			amt_age_bracket2_oper,
			amt_age_bracket3_oper,
			amt_age_bracket4_oper,
			amt_age_bracket5_oper,
			amt_age_bracket6_oper,
			amt_balance_oper,
			amt_on_order_oper,
			amt_vouch_unposted_oper,
			high_amt_ap_oper
			)
			SELECT DISTINCT
				vendor_code,
				pay_to_code,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				'',
				'',
				'',
				'',
				'',
				'',
				'',
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,  
				'',
				'',
				'',
				'',
				'',
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0  
			FROM #apinpchg                    
			WHERE mark_flag = 0
			AND pay_to_code != ''
			

		  
		 
		  

		     
			UPDATE #apinpchg
			SET mark_flag = 0  

	  DELETE #apvtemp
  END



  
  IF (@bch_flag = 1)
  BEGIN

	 INSERT #apvtemp(code,code2,amt_net_home,amt_net_oper)
	 SELECT DISTINCT branch_code,'', 
	 	amt_net_home = sum((SIGN(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) * ROUND(ABS(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) + 0.0000001, @home_precision))),
	 	amt_net_oper = sum((SIGN(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) * ROUND(ABS(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) + 0.0000001, @oper_precision)))
	 FROM #apinpchg
	 GROUP BY branch_code
		 
	  
	  UPDATE apactbch
	  SET amt_vouch_unposted = apactbch.amt_vouch_unposted + b.amt_net_home,
		  amt_vouch_unposted_oper = apactbch.amt_vouch_unposted_oper + b.amt_net_oper
	  FROM apactbch,#apvtemp b
	  WHERE apactbch.branch_code = b.code

	 
	  UPDATE #apinpchg
	  SET mark_flag = 1
	  FROM #apinpchg,apactbch b
	  WHERE #apinpchg.branch_code = b.branch_code

	  
		INSERT apactbch
		   (
			branch_code,
			date_last_vouch,
			date_last_dm,
			date_last_adj,
			date_last_pyt,
			date_last_void,
			amt_last_vouch,
			amt_last_dm,
			amt_last_adj,
			amt_last_pyt,
			amt_last_void,
			amt_age_bracket1,
			amt_age_bracket2,
			amt_age_bracket3,
			amt_age_bracket4,
			amt_age_bracket5,
			amt_age_bracket6,
			amt_on_order,
			amt_vouch_unposted,
			last_vouch_doc,
			last_dm_doc,
			last_adj_doc,
			last_pyt_doc,
			last_pyt_acct,
			last_void_doc,
			last_void_acct,
			high_amt_ap,
			high_amt_vouch,
			high_date_ap,
			high_date_vouch,
			num_vouch,
			num_vouch_paid,
			num_overdue_pyt,
			avg_days_pay,
			avg_days_overdue,
			last_trx_time,
			amt_balance,
			last_vouch_cur,
			last_dm_cur,
			last_adj_cur,
			last_pyt_cur,
			last_void_cur,
			amt_age_bracket1_oper,
			amt_age_bracket2_oper,
			amt_age_bracket3_oper,
			amt_age_bracket4_oper,
			amt_age_bracket5_oper,
			amt_age_bracket6_oper,
			amt_balance_oper,
			amt_on_order_oper,
			amt_vouch_unposted_oper,
			high_amt_ap_oper
			)
			SELECT DISTINCT
				branch_code,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				'',
				'',
				'',
				'',
				'',
				'',
				'',
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,  
				'',
				'',
				'',
				'',
				'',
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0  
			FROM #apinpchg                    
			WHERE mark_flag = 0

			
			UPDATE #apinpchg
			SET mark_flag = 0  

		 
		  
  END

DELETE #apvtemp

  
  IF (@cls_flag = 1)
  BEGIN

	 INSERT #apvtemp(code,code2,amt_net_home,amt_net_oper)
	 SELECT DISTINCT class_code,'',
	 	amt_net_home = sum((SIGN(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) * ROUND(ABS(amt_net * ( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) )) + 0.0000001, @home_precision))),
	 	amt_net_oper = sum((SIGN(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) * ROUND(ABS(amt_net * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) )) + 0.0000001, @oper_precision)))
	 FROM #apinpchg
	 GROUP BY class_code
		 
	  
	  UPDATE apactcls
	  SET amt_vouch_unposted = apactcls.amt_vouch_unposted + b.amt_net_home,
		  amt_vouch_unposted_oper = apactcls.amt_vouch_unposted_oper + b.amt_net_oper
	  FROM apactcls,#apvtemp b
	  WHERE apactcls.class_code = b.code

	 
	  UPDATE #apinpchg
	  SET mark_flag = 1
	  FROM #apinpchg,apactcls b
	  WHERE #apinpchg.class_code = b.class_code

	  
		INSERT apactcls
		   (
			class_code,
			date_last_vouch,
			date_last_dm,
			date_last_adj,
			date_last_pyt,
			date_last_void,
			amt_last_vouch,
			amt_last_dm,
			amt_last_adj,
			amt_last_pyt,
			amt_last_void,
			amt_age_bracket1,
			amt_age_bracket2,
			amt_age_bracket3,
			amt_age_bracket4,
			amt_age_bracket5,
			amt_age_bracket6,
			amt_on_order,
			amt_vouch_unposted,
			last_vouch_doc,
			last_dm_doc,
			last_adj_doc,
			last_pyt_doc,
			last_pyt_acct,
			last_void_doc,
			last_void_acct,
			high_amt_ap,
			high_amt_vouch,
			high_date_ap,
			high_date_vouch,
			num_vouch,
			num_vouch_paid,
			num_overdue_pyt,
			avg_days_pay,
			avg_days_overdue,
			last_trx_time,
			amt_balance,
			last_vouch_cur,
			last_dm_cur,
			last_adj_cur,
			last_pyt_cur,
			last_void_cur,
			amt_age_bracket1_oper,
			amt_age_bracket2_oper,
			amt_age_bracket3_oper,
			amt_age_bracket4_oper,
			amt_age_bracket5_oper,
			amt_age_bracket6_oper,
			amt_balance_oper,
			amt_on_order_oper,
			amt_vouch_unposted_oper,
			high_amt_ap_oper
			)
			SELECT DISTINCT
				class_code,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				'',
				'',
				'',
				'',
				'',
				'',
				'',
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,  
				'',
				'',
				'',
				'',
				'',
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0  
			FROM #apinpchg                    
			WHERE mark_flag = 0

			
			UPDATE #apinpchg
			SET mark_flag = 0  


		 
		  
  END

DELETE #apvtemp
RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[apvoact_sp] TO [public]
GO
