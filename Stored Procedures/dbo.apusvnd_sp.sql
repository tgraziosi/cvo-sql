SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*
              Confidential Information
   Limited Distribution of Authorized Persons Only
   Created 2001 and Protected as Unpublished Work
         Under the U.S. Copyright Act of 1976
Copyright (c) 2001 Epicor Software Corporation, 2001
                 All Rights Reserved 
 */
     CREATE PROC [dbo].[apusvnd_sp] AS    DECLARE  @apsumvnd_flag int,  @home_precision int, 
 @oper_precision int,  @dm_cnt int,  @vo_cnt int,  @py_cnt int,  @va_cnt int,  @pa_cnt int 
   SELECT @apsumvnd_flag = apsumvnd_flag FROM apco IF (@apsumvnd_flag = 1) BEGIN 
 SELECT @home_precision = b.curr_precision,  @oper_precision = c.curr_precision  FROM glco a, glcurr_vw b, glcurr_vw c 
 WHERE a.home_currency = b.currency_code  AND a.oper_currency = c.currency_code  SELECT DISTINCT 
 a.trx_ctrl_num, a.vendor_code,  prd.period_start_date, prd.period_end_date,  a.amt_net, 
 a.amt_discount, a.amt_freight, a.amt_tax,  a.rate_home, a.rate_oper  INTO #temp1 
 FROM apdmhdr a, apmaster c, glprd prd  WHERE a.vendor_code = c.vendor_code  AND c.address_type = 0 
 AND a.date_applied between prd.period_start_date and prd.period_end_date  SELECT DISTINCT trx_ctrl_num, vendor_code, period_start_date, period_end_date, amt_net, rate_home, rate_oper 
 INTO #temp2  FROM #temp1  SELECT @dm_cnt = ISNULL((SELECT COUNT(*) FROM #temp2),0) 
 DELETE apsumvnd  IF ( @dm_cnt > 0 )  BEGIN  CREATE TABLE #apdmvnd_work  (  vendor_code varchar(12), 
 date_from int,  date_thru int,  num_dm int,  amt_dm float,  amt_disc_given float, 
 amt_freight float,  amt_tax float,  last_trx_time int,  amt_dm_oper float,  amt_disc_given_oper float, 
 amt_freight_oper float,  amt_tax_oper float,  db_action smallint  )  INSERT #apdmvnd_work ( 
 vendor_code, date_from, date_thru,  num_dm, amt_dm, amt_disc_given,  amt_freight, amt_tax, 
 last_trx_time, amt_dm_oper, amt_disc_given_oper,  amt_freight_oper, amt_tax_oper, 
 db_action )  SELECT DISTINCT  vendor_code, period_start_date, period_end_date,  1, 0.0, 0.0, 
 0.0, 0.0,  0, 0.0, 0.0,  0.0, 0.0,  1  FROM #temp1  UPDATE #apdmvnd_work  SET num_dm = ISNULL((SELECT COUNT(*) 
 FROM #temp2 a  WHERE a.vendor_code = b.vendor_code  AND a.period_start_date = b.date_from 
 AND a.period_end_date = b.date_thru),0)  FROM #temp2 a, #apdmvnd_work b  WHERE b.db_action = 1 
 AND a.vendor_code = b.vendor_code  UPDATE #apdmvnd_work  SET amt_disc_given = (SELECT ISNULL( SUM( (SIGN(a.amt_discount * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) )) * ROUND(ABS(a.amt_discount * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) )) + 0.0000001, @home_precision))),0) 
 FROM #temp1 a  WHERE a.vendor_code = b.vendor_code  AND a.period_start_date = b.date_from 
 AND a.period_end_date = b.date_thru),  amt_disc_given_oper = (SELECT ISNULL( SUM( (SIGN(a.amt_discount * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) )) * ROUND(ABS(a.amt_discount * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) )) + 0.0000001, @oper_precision))),0) 
 FROM #temp1 a  WHERE a.vendor_code = b.vendor_code  AND a.period_start_date = b.date_from 
 AND a.period_end_date = b.date_thru),  amt_freight = (SELECT ISNULL( SUM( (SIGN(a.amt_freight * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) )) * ROUND(ABS(a.amt_freight * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) )) + 0.0000001, @home_precision))),0) 
 FROM #temp1 a  WHERE a.vendor_code = b.vendor_code  AND a.period_start_date = b.date_from 
 AND a.period_end_date = b.date_thru),  amt_freight_oper = (SELECT ISNULL( SUM( (SIGN(a.amt_freight * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) )) * ROUND(ABS(a.amt_freight * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) )) + 0.0000001, @oper_precision))),0) 
 FROM #temp1 a  WHERE a.vendor_code = b.vendor_code  AND a.period_start_date = b.date_from 
 AND a.period_end_date = b.date_thru),  amt_tax = (SELECT ISNULL( SUM( (SIGN(a.amt_tax * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) )) * ROUND(ABS(a.amt_tax * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) )) + 0.0000001, @home_precision))),0) 
 FROM #temp1 a  WHERE a.vendor_code = b.vendor_code  AND a.period_start_date = b.date_from 
 AND a.period_end_date = b.date_thru),  amt_tax_oper = (SELECT ISNULL( SUM( (SIGN(a.amt_tax * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) )) * ROUND(ABS(a.amt_tax * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) )) + 0.0000001, @oper_precision))),0) 
 FROM #temp1 a  WHERE a.vendor_code = b.vendor_code  AND a.period_start_date = b.date_from 
 AND a.period_end_date = b.date_thru)  FROM #temp1 a, #apdmvnd_work b  WHERE b.db_action > 0 
 AND a.vendor_code = b.vendor_code  UPDATE #apdmvnd_work  SET amt_dm = (SELECT ISNULL( SUM( (SIGN(a.amt_net * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) )) * ROUND(ABS(a.amt_net * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) )) + 0.0000001, @home_precision))),0) 
 FROM #temp2 a  WHERE a.vendor_code = b.vendor_code  AND a.period_start_date = b.date_from 
 AND a.period_end_date = b.date_thru),  amt_dm_oper = (SELECT ISNULL( SUM( (SIGN(a.amt_net * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) )) * ROUND(ABS(a.amt_net * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) )) + 0.0000001, @oper_precision))),0) 
 FROM #temp2 a  WHERE a.vendor_code = b.vendor_code  AND a.period_start_date = b.date_from 
 AND a.period_end_date = b.date_thru)  FROM #temp2 a, #apdmvnd_work b  WHERE b.db_action > 0 
 AND a.vendor_code = b.vendor_code  DROP TABLE #temp2  UPDATE #apdmvnd_work  SET db_action = 2 
 FROM #apdmvnd_work a, apsumvnd b  WHERE a.vendor_code = b.vendor_code  AND a.date_from = b.date_from 
 AND a.date_thru = b.date_thru  UPDATE apsumvnd  SET num_dm = apsumvnd.num_dm + b.num_dm, 
 amt_dm = apsumvnd.amt_dm + b.amt_dm,  amt_dm_oper = apsumvnd.amt_dm_oper + b.amt_dm_oper, 
 amt_disc_given = apsumvnd.amt_disc_given - b.amt_disc_given,  amt_disc_given_oper = apsumvnd.amt_disc_given_oper - b.amt_disc_given_oper, 
 amt_freight = apsumvnd.amt_freight - b.amt_freight,  amt_freight_oper = apsumvnd.amt_freight_oper - b.amt_freight_oper, 
 amt_tax = apsumvnd.amt_tax - b.amt_tax,  amt_tax_oper = apsumvnd.amt_tax_oper - b.amt_tax_oper 
 FROM apsumvnd, #apdmvnd_work b  WHERE apsumvnd.vendor_code = b.vendor_code  AND b.db_action = 2 
 AND apsumvnd.date_from = b.date_from  AND apsumvnd.date_thru = b.date_thru  INSERT apsumvnd( timestamp, 
 vendor_code, date_from, date_thru,  num_vouch, num_vouch_paid, num_dm,  num_adj, num_pyt, num_overdue_pyt, 
 num_void,  amt_vouch, amt_dm, amt_adj,  amt_pyt, amt_void, amt_disc_given,  amt_disc_taken, amt_disc_lost, amt_freight, 
 amt_tax,  avg_days_pay, avg_days_overdue, last_trx_time,  amt_vouch_oper, amt_dm_oper, amt_adj_oper, 
 amt_pyt_oper, amt_void_oper, amt_disc_given_oper,  amt_disc_taken_oper, amt_disc_lost_oper, amt_freight_oper, 
 amt_tax_oper)  SELECT NULL,  vendor_code, date_from, date_thru,  0, 0, num_dm,  0, 0, 0, 
 0,  0.0, amt_dm, 0.0,  0.0, 0.0, -amt_disc_given,  0.0, 0.0, -amt_freight,  -amt_tax, 
 0, 0, 0,  0.0, amt_dm_oper, 0.0,  0.0, 0.0, -amt_disc_given_oper,  0.0, 0.0, -amt_freight_oper, 
 -amt_tax_oper  FROM #apdmvnd_work  WHERE db_action != 2  DROP TABLE #apdmvnd_work 
 END  ELSE  DROP TABLE #temp2    SELECT DISTINCT  a.trx_ctrl_num, a.vendor_code, 
 prd.period_start_date, prd.period_end_date,  a.date_applied, a.date_due, a.date_paid, 
 a.paid_flag,  a.amt_net,  a.amt_discount, a.amt_freight, a.amt_tax,  a.rate_home, a.rate_oper 
 INTO #temp3  FROM apvohdr a, apmaster c, glprd prd  WHERE a.vendor_code = c.vendor_code 
 AND c.address_type = 0  AND a.date_applied between prd.period_start_date and prd.period_end_date 
 SELECT DISTINCT trx_ctrl_num, vendor_code, period_start_date, period_end_date,  date_applied, date_due, date_paid, paid_flag, amt_net, rate_home, rate_oper 
 INTO #temp4  FROM #temp3  SELECT @vo_cnt = ISNULL((SELECT COUNT(*) FROM #temp4),0) 
 IF ( @vo_cnt > 0 )  BEGIN  CREATE TABLE #apvovnd_work  (  vendor_code varchar(12), 
 date_from int,  date_thru int,  avg_days_pay int,   avg_days_overdue int,  num_vouch int, 
 num_vouch_paid int,  num_overdue_pyt int,   amt_vouch float,  amt_disc_given float, 
 amt_freight float,  amt_tax float,  last_trx_time int,  amt_vouch_oper float,  amt_disc_given_oper float, 
 amt_freight_oper float,  amt_tax_oper float,  db_action smallint  )  INSERT #apvovnd_work ( 
 vendor_code, date_from, date_thru,  avg_days_pay, avg_days_overdue,  num_vouch, num_vouch_paid, num_overdue_pyt, 
 amt_vouch, amt_disc_given, amt_freight, amt_tax,  last_trx_time,  amt_vouch_oper, amt_disc_given_oper, amt_freight_oper, amt_tax_oper, 
 db_action )  SELECT DISTINCT  vendor_code, period_start_date, period_end_date,  0, 0, 
 1, 0, 0,  0.0, 0.0, 0.0, 0.0,  0,  0.0, 0.0, 0.0, 0.0,  1  FROM #temp3  UPDATE #apvovnd_work 
 SET num_vouch = ISNULL((SELECT COUNT(*)  FROM #temp4 a  WHERE a.vendor_code = b.vendor_code 
 AND a.period_start_date = b.date_from  AND a.period_end_date = b.date_thru),0), 
 num_vouch_paid = (SELECT ISNULL(SUM(a.paid_flag),0)  FROM #temp4 a  WHERE a.vendor_code = b.vendor_code 
 AND a.period_start_date = b.date_from  AND a.period_end_date = b.date_thru  AND a.paid_flag = 1), 
 num_overdue_pyt = (SELECT ISNULL(SUM(a.paid_flag),0)  FROM #temp4 a  WHERE a.vendor_code = b.vendor_code 
 AND a.period_start_date = b.date_from  AND a.period_end_date = b.date_thru  AND a.paid_flag = 1 
 AND a.date_paid > a.date_due),  avg_days_pay = (SELECT ISNULL(SUM(a.date_paid - a.date_applied),0.0) 
 FROM #temp4 a  WHERE a.vendor_code = b.vendor_code  AND a.period_start_date = b.date_from 
 AND a.period_end_date = b.date_thru  AND a.paid_flag = 1  AND a.date_paid > a.date_applied), 
 avg_days_overdue = (SELECT ISNULL(SUM(a.date_paid - a.date_due),0.0)  FROM #temp4 a 
 WHERE a.vendor_code = b.vendor_code  AND a.period_start_date = b.date_from  AND a.period_end_date = b.date_thru 
 AND a.paid_flag = 1  AND a.date_paid > a.date_due)  FROM #temp4 a, #apvovnd_work b 
 WHERE b.db_action = 1  AND a.vendor_code = b.vendor_code  UPDATE #apvovnd_work 
 SET amt_disc_given = (SELECT ISNULL( SUM( (SIGN(a.amt_discount * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) )) * ROUND(ABS(a.amt_discount * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) )) + 0.0000001, @home_precision))),0) 
 FROM #temp3 a  WHERE a.vendor_code = b.vendor_code  AND a.period_start_date = b.date_from 
 AND a.period_end_date = b.date_thru),  amt_disc_given_oper = (SELECT ISNULL( SUM( (SIGN(a.amt_discount * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) )) * ROUND(ABS(a.amt_discount * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) )) + 0.0000001, @oper_precision))),0) 
 FROM #temp3 a  WHERE a.vendor_code = b.vendor_code  AND a.period_start_date = b.date_from 
 AND a.period_end_date = b.date_thru),  amt_freight = (SELECT ISNULL( SUM( (SIGN(a.amt_freight * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) )) * ROUND(ABS(a.amt_freight * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) )) + 0.0000001, @home_precision))),0) 
 FROM #temp3 a  WHERE a.vendor_code = b.vendor_code  AND a.period_start_date = b.date_from 
 AND a.period_end_date = b.date_thru),  amt_freight_oper = (SELECT ISNULL( SUM( (SIGN(a.amt_freight * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) )) * ROUND(ABS(a.amt_freight * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) )) + 0.0000001, @oper_precision))),0) 
 FROM #temp3 a  WHERE a.vendor_code = b.vendor_code  AND a.period_start_date = b.date_from 
 AND a.period_end_date = b.date_thru),  amt_tax = (SELECT ISNULL( SUM( (SIGN(a.amt_tax * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) )) * ROUND(ABS(a.amt_tax * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) )) + 0.0000001, @home_precision))),0) 
 FROM #temp3 a  WHERE a.vendor_code = b.vendor_code  AND a.period_start_date = b.date_from 
 AND a.period_end_date = b.date_thru),  amt_tax_oper = (SELECT ISNULL( SUM( (SIGN(a.amt_tax * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) )) * ROUND(ABS(a.amt_tax * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) )) + 0.0000001, @oper_precision))),0) 
 FROM #temp3 a  WHERE a.vendor_code = b.vendor_code  AND a.period_start_date = b.date_from 
 AND a.period_end_date = b.date_thru)  FROM #temp3 a, #apvovnd_work b  WHERE b.db_action > 0 
 AND a.vendor_code = b.vendor_code  UPDATE #apvovnd_work  SET amt_vouch = (SELECT ISNULL( SUM( (SIGN(a.amt_net * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) )) * ROUND(ABS(a.amt_net * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) )) + 0.0000001, @home_precision))),0) 
 FROM #temp4 a  WHERE a.vendor_code = b.vendor_code  AND a.period_start_date = b.date_from 
 AND a.period_end_date = b.date_thru),  amt_vouch_oper = (SELECT ISNULL( SUM( (SIGN(a.amt_net * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) )) * ROUND(ABS(a.amt_net * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) )) + 0.0000001, @oper_precision))),0) 
 FROM #temp4 a  WHERE a.vendor_code = b.vendor_code  AND a.period_start_date = b.date_from 
 AND a.period_end_date = b.date_thru)  FROM #temp4 a, #apvovnd_work b  WHERE b.db_action > 0 
 AND a.vendor_code = b.vendor_code  DROP TABLE #temp4  UPDATE #apvovnd_work  SET db_action = 2 
 FROM #apvovnd_work a, apsumvnd b  WHERE a.vendor_code = b.vendor_code  AND a.date_from = b.date_from 
 AND a.date_thru = b.date_thru  UPDATE apsumvnd  SET num_vouch = apsumvnd.num_vouch + b.num_vouch, 
 num_vouch_paid = apsumvnd.num_vouch_paid + b.num_vouch_paid,  num_overdue_pyt = apsumvnd.num_overdue_pyt + b.num_overdue_pyt, 
 avg_days_pay = apsumvnd.avg_days_pay + b.avg_days_pay,  avg_days_overdue = apsumvnd.avg_days_overdue + b.avg_days_overdue, 
 amt_vouch = apsumvnd.amt_vouch + b.amt_vouch,  amt_vouch_oper = apsumvnd.amt_vouch_oper + b.amt_vouch_oper, 
 amt_disc_given = apsumvnd.amt_disc_given + b.amt_disc_given,  amt_disc_given_oper = apsumvnd.amt_disc_given_oper + b.amt_disc_given_oper, 
 amt_freight = apsumvnd.amt_freight + b.amt_freight,  amt_freight_oper = apsumvnd.amt_freight_oper + b.amt_freight_oper, 
 amt_tax = apsumvnd.amt_tax + b.amt_tax,  amt_tax_oper = apsumvnd.amt_tax_oper + b.amt_tax_oper 
 FROM apsumvnd, #apvovnd_work b  WHERE apsumvnd.vendor_code = b.vendor_code  AND b.db_action = 2 
 AND apsumvnd.date_from = b.date_from  AND apsumvnd.date_thru = b.date_thru  INSERT apsumvnd( timestamp, 
 vendor_code, date_from, date_thru,  num_vouch, num_vouch_paid, num_dm,  num_adj, num_pyt, num_overdue_pyt, 
 num_void,  amt_vouch, amt_dm, amt_adj,  amt_pyt, amt_void, amt_disc_given,  amt_disc_taken, amt_disc_lost, amt_freight, 
 amt_tax,  avg_days_pay, avg_days_overdue, last_trx_time,  amt_vouch_oper, amt_dm_oper, amt_adj_oper, 
 amt_pyt_oper, amt_void_oper, amt_disc_given_oper,  amt_disc_taken_oper, amt_disc_lost_oper, amt_freight_oper, 
 amt_tax_oper)  SELECT NULL,  vendor_code, date_from, date_thru,  num_vouch, num_vouch_paid, 0, 
 0, 0, num_overdue_pyt,  0,  amt_vouch, 0.0, 0.0,  0.0, 0.0, amt_disc_given,  0.0, 0.0, amt_freight, 
 amt_tax,  avg_days_pay, avg_days_overdue, 0,  amt_vouch_oper, 0.0, 0.0,  0.0, 0.0, amt_disc_given_oper, 
 0.0, 0.0, amt_freight_oper,  amt_tax_oper  FROM #apvovnd_work  WHERE db_action != 2 
 DROP TABLE #apvovnd_work  END  ELSE  DROP TABLE #temp4    SELECT DISTINCT  a.trx_ctrl_num, a.vendor_code, 
 prd.period_start_date, prd.period_end_date,  a.amt_net, a.amt_discount,  a.rate_home, a.rate_oper 
 INTO #temp5  FROM appyhdr a, apmaster c, glprd prd  WHERE a.vendor_code = c.vendor_code 
 AND c.address_type = 0  AND a.date_applied between prd.period_start_date and prd.period_end_date 
 SELECT DISTINCT trx_ctrl_num, vendor_code, period_start_date, period_end_date, amt_net, rate_home, rate_oper 
 INTO #temp6  FROM #temp5  SELECT @py_cnt = ISNULL((SELECT COUNT(*) FROM #temp6),0) 
 IF ( @py_cnt > 0 )  BEGIN  CREATE TABLE #appyvnd_work  (  vendor_code varchar(12), 
 date_from int,  date_thru int,  num_pyt int,  amt_pyt float,  amt_disc_taken float, 
 last_trx_time int,  amt_pyt_oper float,  amt_disc_taken_oper float,  db_action smallint 
 )  INSERT #appyvnd_work (  vendor_code, date_from, date_thru,  num_pyt, amt_pyt, amt_disc_taken, 
 last_trx_time, amt_pyt_oper, amt_disc_taken_oper,  db_action )  SELECT DISTINCT 
 vendor_code, period_start_date, period_end_date,  1, 0.0, 0.0,  0, 0.0, 0.0,  1 
 FROM #temp5  UPDATE #appyvnd_work  SET num_pyt = ISNULL((SELECT COUNT(*)  FROM #temp6 a 
 WHERE a.vendor_code = b.vendor_code  AND a.period_start_date = b.date_from  AND a.period_end_date = b.date_thru),0) 
 FROM #temp6 a, #appyvnd_work b  WHERE b.db_action = 1  AND a.vendor_code = b.vendor_code 
 UPDATE #appyvnd_work  SET amt_disc_taken = (SELECT ISNULL( SUM( (SIGN(a.amt_discount * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) )) * ROUND(ABS(a.amt_discount * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) )) + 0.0000001, @home_precision))),0) 
 FROM #temp5 a  WHERE a.vendor_code = b.vendor_code  AND a.period_start_date = b.date_from 
 AND a.period_end_date = b.date_thru),  amt_disc_taken_oper = (SELECT ISNULL( SUM( (SIGN(a.amt_discount * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) )) * ROUND(ABS(a.amt_discount * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) )) + 0.0000001, @oper_precision))),0) 
 FROM #temp5 a  WHERE a.vendor_code = b.vendor_code  AND a.period_start_date = b.date_from 
 AND a.period_end_date = b.date_thru)  FROM #temp5 a, #appyvnd_work b  WHERE b.db_action > 0 
 AND a.vendor_code = b.vendor_code  UPDATE #appyvnd_work  SET amt_pyt = (SELECT ISNULL( SUM( (SIGN(a.amt_net * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) )) * ROUND(ABS(a.amt_net * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) )) + 0.0000001, @home_precision))),0) 
 FROM #temp6 a  WHERE a.vendor_code = b.vendor_code  AND a.period_start_date = b.date_from 
 AND a.period_end_date = b.date_thru),  amt_pyt_oper = (SELECT ISNULL( SUM( (SIGN(a.amt_net * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) )) * ROUND(ABS(a.amt_net * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) )) + 0.0000001, @oper_precision))),0) 
 FROM #temp6 a  WHERE a.vendor_code = b.vendor_code  AND a.period_start_date = b.date_from 
 AND a.period_end_date = b.date_thru)  FROM #temp6 a, #appyvnd_work b  WHERE b.db_action > 0 
 AND a.vendor_code = b.vendor_code  DROP TABLE #temp6  UPDATE #appyvnd_work  SET db_action = 2 
 FROM #appyvnd_work a, apsumvnd b  WHERE a.vendor_code = b.vendor_code  AND a.date_from = b.date_from 
 AND a.date_thru = b.date_thru  UPDATE apsumvnd  SET num_pyt = apsumvnd.num_pyt + b.num_pyt, 
 amt_pyt = apsumvnd.amt_pyt + b.amt_pyt,  amt_pyt_oper = apsumvnd.amt_pyt_oper + b.amt_pyt_oper, 
 amt_disc_taken = apsumvnd.amt_disc_taken + b.amt_disc_taken,  amt_disc_taken_oper = apsumvnd.amt_disc_taken_oper + b.amt_disc_taken_oper 
 FROM apsumvnd, #appyvnd_work b  WHERE apsumvnd.vendor_code = b.vendor_code  AND b.db_action = 2 
 AND apsumvnd.date_from = b.date_from  AND apsumvnd.date_thru = b.date_thru  INSERT apsumvnd( timestamp, 
 vendor_code, date_from, date_thru,  num_vouch, num_vouch_paid, num_dm,  num_adj, num_pyt, num_overdue_pyt, 
 num_void,  amt_vouch, amt_dm, amt_adj,  amt_pyt, amt_void, amt_disc_given,  amt_disc_taken, amt_disc_lost, amt_freight, 
 amt_tax,  avg_days_pay, avg_days_overdue, last_trx_time,  amt_vouch_oper, amt_dm_oper, amt_adj_oper, 
 amt_pyt_oper, amt_void_oper, amt_disc_given_oper,  amt_disc_taken_oper, amt_disc_lost_oper, amt_freight_oper, 
 amt_tax_oper)  SELECT NULL,  vendor_code, date_from, date_thru,  0, 0, 0,  0, num_pyt, 0, 
 0,  0.0, 0.0, 0.0,  amt_pyt, 0.0, 0.0,  amt_disc_taken, 0.0, 0.0,  0.0,  0, 0, 0, 
 0.0, 0.0, 0.0,  amt_pyt_oper, 0.0, 0.0,  amt_disc_taken_oper, 0.0, 0.0,  0.0  FROM #appyvnd_work 
 WHERE db_action != 2  DROP TABLE #appyvnd_work  END  ELSE  DROP TABLE #temp6   
 SELECT  a.apply_to_num, a.vendor_code,  prd.period_start_date, prd.period_end_date, 
 a.amt_net,  a.rate_home, a.rate_oper  INTO #temp7  FROM apvohdr a, apvahdr b, apmaster c, glprd prd 
 WHERE a.apply_to_num = b.apply_to_num  AND a.vendor_code = c.vendor_code  AND c.address_type = 0 
 AND a.date_applied between prd.period_start_date and prd.period_end_date  SELECT DISTINCT apply_to_num, vendor_code, period_start_date, period_end_date, amt_net, rate_home, rate_oper 
 INTO #temp8  FROM #temp7  SELECT @va_cnt = ISNULL((SELECT COUNT(*) FROM #temp8),0) 
 IF ( @va_cnt > 0 )  BEGIN  CREATE TABLE #apvavnd_work  (  vendor_code varchar(12), 
 date_from int,  date_thru int,  num_adj int,  amt_adj float,  last_trx_time int, 
 amt_adj_oper float,  db_action smallint  )  INSERT #apvavnd_work (  vendor_code, date_from, date_thru, 
 num_adj, amt_adj,  last_trx_time, amt_adj_oper,  db_action )  SELECT DISTINCT  vendor_code, period_start_date, period_end_date, 
 1, 0.0,  0, 0.0,  1  FROM #temp7  UPDATE #apvavnd_work  SET num_adj = ISNULL((SELECT COUNT(*) 
 FROM #temp8 a  WHERE a.vendor_code = b.vendor_code  AND a.period_start_date = b.date_from 
 AND a.period_end_date = b.date_thru),0)  FROM #temp8 a, #apvavnd_work b  WHERE b.db_action = 1 
 AND a.vendor_code = b.vendor_code  UPDATE #apvavnd_work  SET amt_adj = (SELECT ISNULL( SUM( (SIGN(a.amt_net * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) )) * ROUND(ABS(a.amt_net * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) )) + 0.0000001, @home_precision))),0) 
 FROM #temp8 a  WHERE a.vendor_code = b.vendor_code  AND a.period_start_date = b.date_from 
 AND a.period_end_date = b.date_thru),  amt_adj_oper = (SELECT ISNULL( SUM( (SIGN(a.amt_net * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) )) * ROUND(ABS(a.amt_net * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) )) + 0.0000001, @oper_precision))),0) 
 FROM #temp8 a  WHERE a.vendor_code = b.vendor_code  AND a.period_start_date = b.date_from 
 AND a.period_end_date = b.date_thru)  FROM #temp8 a, #apvavnd_work b  WHERE b.db_action > 0 
 AND a.vendor_code = b.vendor_code  DROP TABLE #temp8  UPDATE #apvavnd_work  SET db_action = 2 
 FROM #apvavnd_work a, apsumvnd b  WHERE a.vendor_code = b.vendor_code  AND a.date_from = b.date_from 
 AND a.date_thru = b.date_thru  UPDATE apsumvnd  SET num_adj = apsumvnd.num_adj + b.num_adj, 
 amt_adj = apsumvnd.amt_adj + b.amt_adj,  amt_adj_oper = apsumvnd.amt_adj_oper + b.amt_adj_oper 
 FROM apsumvnd, #apvavnd_work b  WHERE apsumvnd.vendor_code = b.vendor_code  AND b.db_action = 2 
 AND apsumvnd.date_from = b.date_from  AND apsumvnd.date_thru = b.date_thru  INSERT apsumvnd( timestamp, 
 vendor_code, date_from, date_thru,  num_vouch, num_vouch_paid, num_dm,  num_adj, num_pyt, num_overdue_pyt, 
 num_void,  amt_vouch, amt_dm, amt_adj,  amt_pyt, amt_void, amt_disc_given,  amt_disc_taken, amt_disc_lost, amt_freight, 
 amt_tax,  avg_days_pay, avg_days_overdue, last_trx_time,  amt_vouch_oper, amt_dm_oper, amt_adj_oper, 
 amt_pyt_oper, amt_void_oper, amt_disc_given_oper,  amt_disc_taken_oper, amt_disc_lost_oper, amt_freight_oper, 
 amt_tax_oper)  SELECT NULL,  vendor_code, date_from, date_thru,  0, 0, 0,  num_adj, 0, 0, 
 0,  0.0, 0.0, amt_adj,  0.0, 0.0, 0.0,  0.0, 0.0, 0.0,  0.0,  0, 0, 0,  0.0, 0.0, amt_adj_oper, 
 0.0, 0.0, 0.0,  0.0, 0.0, 0.0,  0.0  FROM #apvavnd_work  WHERE db_action != 2  DROP TABLE #apvavnd_work 
 END    SELECT  a.doc_ctrl_num, a.vendor_code, a.cash_acct_code,  prd.period_start_date, prd.period_end_date, 
 a.amt_net,  a.rate_home, a.rate_oper  INTO #temp9  FROM appyhdr a, appahdr b, apmaster c, glprd prd 
 WHERE a.doc_ctrl_num = b.doc_ctrl_num  AND a.cash_acct_code = b.cash_acct_code  AND a.vendor_code = c.vendor_code 
 AND a.payment_type != 4  AND c.address_type = 0  AND a.date_applied between prd.period_start_date and prd.period_end_date 
 SELECT DISTINCT doc_ctrl_num, vendor_code, cash_acct_code, period_start_date, period_end_date, amt_net, rate_home, rate_oper 
 INTO #temp10  FROM #temp9  SELECT @pa_cnt = ISNULL((SELECT COUNT(*) FROM #temp10),0) 
 IF ( @pa_cnt > 0 )  BEGIN  CREATE TABLE #appavnd_work  (  vendor_code varchar(12), 
 date_from int,  date_thru int,  num_void int,  amt_void float,  last_trx_time int, 
 amt_void_oper float,  db_action smallint  )  INSERT #appavnd_work (  vendor_code, date_from, date_thru, 
 num_void, amt_void,  last_trx_time, amt_void_oper,  db_action )  SELECT DISTINCT 
 vendor_code, period_start_date, period_end_date,  1, 0.0,  0, 0.0,  1  FROM #temp9 
 UPDATE #appavnd_work  SET num_void = ISNULL((SELECT COUNT(*)  FROM #temp10 a  WHERE a.vendor_code = b.vendor_code 
 AND a.period_start_date = b.date_from  AND a.period_end_date = b.date_thru),0)  FROM #temp10 a, #appavnd_work b 
 WHERE b.db_action = 1  AND a.vendor_code = b.vendor_code  UPDATE #appavnd_work 
 SET amt_void = (SELECT ISNULL( SUM( (SIGN(a.amt_net * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) )) * ROUND(ABS(a.amt_net * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) )) + 0.0000001, @home_precision))),0) 
 FROM #temp10 a  WHERE a.vendor_code = b.vendor_code  AND a.period_start_date = b.date_from 
 AND a.period_end_date = b.date_thru),  amt_void_oper = (SELECT ISNULL( SUM( (SIGN(a.amt_net * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) )) * ROUND(ABS(a.amt_net * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) )) + 0.0000001, @oper_precision))),0) 
 FROM #temp10 a  WHERE a.vendor_code = b.vendor_code  AND a.period_start_date = b.date_from 
 AND a.period_end_date = b.date_thru)  FROM #temp10 a, #appavnd_work b  WHERE b.db_action > 0 
 AND a.vendor_code = b.vendor_code  DROP TABLE #temp10  UPDATE #appavnd_work  SET db_action = 2 
 FROM #appavnd_work a, apsumvnd b  WHERE a.vendor_code = b.vendor_code  AND a.date_from = b.date_from 
 AND a.date_thru = b.date_thru  UPDATE apsumvnd  SET num_void = apsumvnd.num_void + b.num_void, 
 amt_void = apsumvnd.amt_void + b.amt_void,  amt_void_oper = apsumvnd.amt_void_oper + b.amt_void_oper 
 FROM apsumvnd, #appavnd_work b  WHERE apsumvnd.vendor_code = b.vendor_code  AND b.db_action = 2 
 AND apsumvnd.date_from = b.date_from  AND apsumvnd.date_thru = b.date_thru  INSERT apsumvnd( timestamp, 
 vendor_code, date_from, date_thru,  num_vouch, num_vouch_paid, num_dm,  num_adj, num_pyt, num_overdue_pyt, 
 num_void,  amt_vouch, amt_dm, amt_adj,  amt_pyt, amt_void, amt_disc_given,  amt_disc_taken, amt_disc_lost, amt_freight, 
 amt_tax,  avg_days_pay, avg_days_overdue, last_trx_time,  amt_vouch_oper, amt_dm_oper, amt_adj_oper, 
 amt_pyt_oper, amt_void_oper, amt_disc_given_oper,  amt_disc_taken_oper, amt_disc_lost_oper, amt_freight_oper, 
 amt_tax_oper)  SELECT NULL,  vendor_code, date_from, date_thru,  0, 0, 0,  0, 0, 0, 
 num_void,  0.0, 0.0, 0.0,  0.0, amt_void, 0.0,  0.0, 0.0, 0.0,  0.0,  0, 0, 0,  0.0, 0.0, 0.0, 
 0.0, amt_void_oper, 0.0,  0.0, 0.0, 0.0,  0.0  FROM #appavnd_work  WHERE db_action != 2 
 DROP TABLE #appavnd_work  END  ELSE  DROP TABLE #temp10  DROP TABLE #temp1  DROP TABLE #temp3 
 DROP TABLE #temp5  DROP TABLE #temp7  DROP TABLE #temp9 END 
GO
GRANT EXECUTE ON  [dbo].[apusvnd_sp] TO [public]
GO
