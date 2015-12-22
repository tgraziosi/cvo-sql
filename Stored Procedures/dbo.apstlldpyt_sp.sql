SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[apstlldpyt_sp]  @trx_ctrl_num varchar(16),  @vendor_code varchar(12), 
 @pay_to_code varchar(8),  @force_disc smallint,  @pay_in_full smallint,  @amt_payment float, 
 @doc_date int,  @nat_cur_code varchar(8),  @rate_home float,  @rate_oper float, 
 @date_applied int,  @restrict smallint,  @rate_type_home varchar(8),  @payment_type smallint, 
 @payment_meth smallint,  @amt_applied_orig float,  @amt_disc_taken_orig float,  @debug_level smallint = 0, 
 @settlement_ctrl_num varchar(16) AS DECLARE  @sequence_id int,  @home_currency varchar(8), 
 @oper_currency varchar(8),  @home_precision smallint,  @oper_precision smallint, 
 @paycur_precision smallint,  @one_check_flag smallint,  @voucher_no varchar(16), 
 @amt_applied float,  @amt_disc_taken float,  @vo_amt_applied float,  @vo_amt_disc_taken float, 
 @vo_precision smallint,  @cross_rate float,  @gain_home float,  @gain_oper float, 
 @prc float,  @dis_trx_ctrl_num varchar(16),  @dis_date int,  @dis_terms_code varchar(8) 
SELECT  @sequence_id =0,  @home_currency ="",  @oper_currency ="",  @home_precision =2, 
 @oper_precision =2,  @paycur_precision =2,  @one_check_flag =0,  @voucher_no ="", 
 @amt_applied =0.0,  @amt_disc_taken =0.0,  @vo_amt_applied =0.0,  @vo_amt_disc_taken =0.0, 
 @vo_precision =2,  @cross_rate =1.0,  @gain_home =0.0,  @gain_oper =0.0     CREATE TABLE #paying_vouchers 
(
 voucher_no varchar(16),  payment_no varchar(16),  amt_applied float,  vo_amt_applied float, 
 vo_amt_disc_taken float 
)
INSERT INTO #paying_vouchers SELECT v.apply_to_num,  v.trx_ctrl_num,  v.amt_applied, 
 v.vo_amt_applied,  v.amt_disc_taken FROM #apinppdt3450 v     DELETE #paying_vouchers 
 DELETE #apinppdt3450 WHERE trx_ctrl_num = @settlement_ctrl_num     CREATE TABLE #vouchers ( 
 trx_ctrl_num varchar(16),  trx_type smallint,  nat_cur_code varchar(8),  rate_type_home varchar(8), 
 rate_home float,  rate_oper float,  terms_code varchar(8),  date_discount int,  date_applied int, 
 vo_precision smallint,  amt_paid_to_date float,  amt_net float,  vo_amt_applied float, 
 vo_amt_disc_taken float,  cross_rate float,  amt_applied float,  amt_disc_taken float, 
 gain_home float,  gain_oper float,  one_check_flag smallint,  used smallint) CREATE CLUSTERED INDEX vouchers_ind_0 ON #vouchers (trx_ctrl_num) 
INSERT #vouchers (  trx_ctrl_num,  trx_type,  nat_cur_code,  rate_type_home,  rate_home, 
 rate_oper,  terms_code,  date_discount,  date_applied,  vo_precision,  amt_paid_to_date, 
 amt_net,  vo_amt_applied,  vo_amt_disc_taken,  cross_rate,  amt_applied,  amt_disc_taken, 
 gain_home,  gain_oper,  one_check_flag,  used ) SELECT trx_ctrl_num,  4091,  currency_code, 
 rate_type_home,  rate_home,  rate_oper,  terms_code,  date_discount,  date_applied, 
 0,  amt_paid_to_date,  amt_net,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  one_check_flag, 
 0 FROM aptrxapl_vw WHERE vendor_code = @vendor_code  AND (currency_code = @nat_cur_code 
 OR @restrict = 0) ORDER BY  date_due, trx_ctrl_num    IF ((SELECT COUNT(*) FROM #vouchers) = 0) 
BEGIN  SELECT @amt_applied_orig, @amt_disc_taken_orig  RETURN 0 END    SELECT @home_currency = a.home_currency, 
 @oper_currency = a.oper_currency,  @home_precision = b.curr_precision,  @oper_precision = c.curr_precision 
 FROM glco a, glcurr_vw b, glcurr_vw c  WHERE a.home_currency = b.currency_code  AND a.oper_currency = c.currency_code 
   SELECT @paycur_precision = curr_precision FROM glcurr_vw WHERE currency_code = @nat_cur_code 
   UPDATE #vouchers SET vo_precision = b.curr_precision FROM #vouchers, glcurr_vw b 
WHERE #vouchers.nat_cur_code = b.currency_code     SELECT  a.apply_to_num,  vo_amt_applied = SUM(a.vo_amt_applied), 
 vo_amt_disc_taken = SUM(a.vo_amt_disc_taken) INTO #amt_unposted FROM apinppdt a, #vouchers b, apinppyt c 
WHERE a.apply_to_num = @voucher_no   GROUP BY a.apply_to_num    SELECT a.apply_to_num, 
 vo_amt_disc_taken = SUM(a.vo_amt_disc_taken)  INTO #amt_posted  FROM appydet a, #vouchers b 
 WHERE a.apply_to_num = b.trx_ctrl_num  AND a.void_flag = 0  GROUP BY a.apply_to_num 
   UPDATE #vouchers SET amt_paid_to_date = #vouchers.amt_paid_to_date + b.vo_amt_applied + b.vo_amt_disc_taken 
FROM #vouchers, #amt_unposted b WHERE #vouchers.trx_ctrl_num = b.apply_to_num  
DECLARE apdiscount_calc CURSOR FOR  SELECT trx_ctrl_num, terms_code, date_discount FROM #vouchers 
OPEN apdiscount_calc FETCH NEXT FROM apdiscount_calc into @dis_trx_ctrl_num, @dis_terms_code, @dis_date 
WHILE @@FETCH_STATUS = 0 BEGIN  EXEC calc_discount_sp @doc_date, @dis_trx_ctrl_num, @dis_terms_code, @prc OUTPUT 
 IF @force_disc = 1  UPDATE #vouchers  SET vo_amt_disc_taken = (SIGN(#vouchers.amt_net * @prc) * ROUND(ABS(#vouchers.amt_net * @prc) + 0.0000001, #vouchers.vo_precision)) 
 WHERE #vouchers.trx_ctrl_num = @dis_trx_ctrl_num  ELSE  UPDATE #vouchers  SET vo_amt_disc_taken = (SIGN(#vouchers.amt_net * @prc) * ROUND(ABS(#vouchers.amt_net * @prc) + 0.0000001, #vouchers.vo_precision)) 
 WHERE #vouchers.trx_ctrl_num = @dis_trx_ctrl_num  AND @doc_date <= @dis_date  SELECT @dis_trx_ctrl_num = "", @dis_terms_code = "",@dis_date = 0, @prc =0 
 FETCH NEXT FROM apdiscount_calc into @dis_trx_ctrl_num, @dis_terms_code, @dis_date 
END CLOSE apdiscount_calc DEALLOCATE apdiscount_calc                     UPDATE #vouchers 
SET vo_amt_disc_taken = #vouchers.vo_amt_disc_taken - b.vo_amt_disc_taken FROM #vouchers, #amt_unposted b 
WHERE #vouchers.trx_ctrl_num = b.apply_to_num UPDATE #vouchers SET vo_amt_disc_taken = #vouchers.vo_amt_disc_taken - b.vo_amt_disc_taken 
FROM #vouchers, #amt_posted b WHERE #vouchers.trx_ctrl_num = b.apply_to_num UPDATE #vouchers 
SET vo_amt_disc_taken = 0.0 WHERE ((vo_amt_disc_taken) <= (0.0) + 0.0000001)    UPDATE #vouchers 
SET vo_amt_applied = amt_net - amt_paid_to_date - vo_amt_disc_taken DELETE #vouchers 
WHERE ((vo_amt_applied) <= (0.0) + 0.0000001)        UPDATE #vouchers SET cross_rate = 1.0 
WHERE nat_cur_code = @nat_cur_code UPDATE #vouchers SET date_applied = @date_applied 
WHERE @date_applied > date_applied CREATE TABLE #rates (from_currency varchar(8), 
 to_currency varchar(8),  rate_type varchar(8),  date_applied int,  rate float) INSERT #rates (from_currency, 
 to_currency,  rate_type,  date_applied,  rate) SELECT DISTINCT nat_cur_code,  @home_currency, 
 rate_type_home,  date_applied,  0.0 FROM #vouchers WHERE nat_cur_code != @nat_cur_code 
INSERT #rates (from_currency,  to_currency,  rate_type,  date_applied,  rate) SELECT DISTINCT @nat_cur_code, 
 @home_currency,  @rate_type_home,  date_applied,  0.0 FROM #vouchers WHERE nat_cur_code != @nat_cur_code 
EXEC CVO_Control..mcrates_sp UPDATE #vouchers SET cross_rate = ( SIGN(1 + SIGN(b.rate))*(b.rate) + (SIGN(ABS(SIGN(ROUND(b.rate,6))))/(b.rate + SIGN(1 - ABS(SIGN(ROUND(b.rate,6)))))) * SIGN(SIGN(b.rate) - 1) )/( SIGN(1 + SIGN(c.rate))*(c.rate) + (SIGN(ABS(SIGN(ROUND(c.rate,6))))/(c.rate + SIGN(1 - ABS(SIGN(ROUND(c.rate,6)))))) * SIGN(SIGN(c.rate) - 1) ) 
FROM #vouchers, #rates b, #rates c WHERE #vouchers.nat_cur_code = b.from_currency 
AND #vouchers.rate_type_home = b.rate_type AND #vouchers.date_applied = b.date_applied 
AND #vouchers.date_applied = c.date_applied AND c.rate_type = @rate_type_home AND c.from_currency = @nat_cur_code 
AND (ABS((c.rate)-(0.0)) > 0.0000001) DROP TABLE #rates UPDATE #vouchers SET amt_applied = (SIGN(vo_amt_applied * cross_rate) * ROUND(ABS(vo_amt_applied * cross_rate) + 0.0000001, @paycur_precision)), 
 amt_disc_taken = (SIGN(vo_amt_disc_taken * cross_rate) * ROUND(ABS(vo_amt_disc_taken * cross_rate) + 0.0000001, @paycur_precision)) 
UPDATE #vouchers SET gain_home = (SIGN(vo_amt_applied * ( SIGN(1 + SIGN(@rate_home))*(@rate_home) + (SIGN(ABS(SIGN(ROUND(@rate_home,6))))/(@rate_home + SIGN(1 - ABS(SIGN(ROUND(@rate_home,6)))))) * SIGN(SIGN(@rate_home) - 1) )) * ROUND(ABS(vo_amt_applied * ( SIGN(1 + SIGN(@rate_home))*(@rate_home) + (SIGN(ABS(SIGN(ROUND(@rate_home,6))))/(@rate_home + SIGN(1 - ABS(SIGN(ROUND(@rate_home,6)))))) * SIGN(SIGN(@rate_home) - 1) )) + 0.0000001, @home_precision)) 
 - (SIGN(amt_applied * ( SIGN(1 + SIGN(@rate_home))*(@rate_home) + (SIGN(ABS(SIGN(ROUND(@rate_home,6))))/(@rate_home + SIGN(1 - ABS(SIGN(ROUND(@rate_home,6)))))) * SIGN(SIGN(@rate_home) - 1) )) * ROUND(ABS(amt_applied * ( SIGN(1 + SIGN(@rate_home))*(@rate_home) + (SIGN(ABS(SIGN(ROUND(@rate_home,6))))/(@rate_home + SIGN(1 - ABS(SIGN(ROUND(@rate_home,6)))))) * SIGN(SIGN(@rate_home) - 1) )) + 0.0000001, @home_precision)) 
UPDATE #vouchers SET gain_oper = (SIGN(vo_amt_applied * ( SIGN(1 + SIGN(@rate_oper))*(@rate_oper) + (SIGN(ABS(SIGN(ROUND(@rate_oper,6))))/(@rate_oper + SIGN(1 - ABS(SIGN(ROUND(@rate_oper,6)))))) * SIGN(SIGN(@rate_oper) - 1) )) * ROUND(ABS(vo_amt_applied * ( SIGN(1 + SIGN(@rate_oper))*(@rate_oper) + (SIGN(ABS(SIGN(ROUND(@rate_oper,6))))/(@rate_oper + SIGN(1 - ABS(SIGN(ROUND(@rate_oper,6)))))) * SIGN(SIGN(@rate_oper) - 1) )) + 0.0000001, @oper_precision)) 
 - (SIGN(amt_applied * ( SIGN(1 + SIGN(@rate_oper))*(@rate_oper) + (SIGN(ABS(SIGN(ROUND(@rate_oper,6))))/(@rate_oper + SIGN(1 - ABS(SIGN(ROUND(@rate_oper,6)))))) * SIGN(SIGN(@rate_oper) - 1) )) * ROUND(ABS(amt_applied * ( SIGN(1 + SIGN(@rate_oper))*(@rate_oper) + (SIGN(ABS(SIGN(ROUND(@rate_oper,6))))/(@rate_oper + SIGN(1 - ABS(SIGN(ROUND(@rate_oper,6)))))) * SIGN(SIGN(@rate_oper) - 1) )) + 0.0000001, @oper_precision)) 
DROP TABLE #amt_unposted DROP TABLE #amt_posted    IF @pay_in_full = 0 BEGIN  UPDATE #vouchers 
 SET vo_amt_applied = 0.0,  vo_amt_disc_taken = 0.0,  amt_applied = 0.0,  amt_disc_taken = 0.0, 
 amt_paid_to_date = 0.0,  amt_net = 0.0  INSERT #apinppdt3450  (  trx_ctrl_num, 
 trx_type,  sequence_id,  apply_to_num,  apply_trx_type,  amt_applied,  amt_disc_taken, 
 line_desc,  void_flag,  payment_hold_flag,  vendor_code,  vo_amt_applied,  vo_amt_disc_taken, 
 gain_home,  gain_oper,  nat_cur_code,  cross_rate  )  SELECT @settlement_ctrl_num, 
 4111,  0,  trx_ctrl_num,  trx_type,  amt_applied,  amt_disc_taken,  "",  0,  0, 
 @vendor_code,  vo_amt_applied,  vo_amt_disc_taken,  gain_home,  gain_oper,  nat_cur_code, 
 cross_rate  FROM #vouchers  ORDER BY trx_ctrl_num END    ELSE BEGIN    SELECT  voucher_no, 
 amt_applied=SUM(amt_applied),  vo_amt_applied=SUM(vo_amt_applied),  vo_amt_disc_taken=SUM(vo_amt_disc_taken) 
INTO #amt_paid FROM #paying_vouchers GROUP BY  voucher_no UPDATE #vouchers SET 
 amt_applied = a.amt_applied - b.amt_applied,  vo_amt_applied = a.vo_amt_applied - b.vo_amt_applied, 
 vo_amt_disc_taken = a.vo_amt_disc_taken - b.vo_amt_disc_taken FROM #vouchers a, #amt_paid b 
WHERE a.trx_ctrl_num = b.voucher_no UPDATE #vouchers SET gain_home = (SIGN(vo_amt_applied * ( SIGN(1 + SIGN(@rate_home))*(@rate_home) + (SIGN(ABS(SIGN(ROUND(@rate_home,6))))/(@rate_home + SIGN(1 - ABS(SIGN(ROUND(@rate_home,6)))))) * SIGN(SIGN(@rate_home) - 1) )) * ROUND(ABS(vo_amt_applied * ( SIGN(1 + SIGN(@rate_home))*(@rate_home) + (SIGN(ABS(SIGN(ROUND(@rate_home,6))))/(@rate_home + SIGN(1 - ABS(SIGN(ROUND(@rate_home,6)))))) * SIGN(SIGN(@rate_home) - 1) )) + 0.0000001, @home_precision)) 
 - (SIGN(amt_applied * ( SIGN(1 + SIGN(@rate_home))*(@rate_home) + (SIGN(ABS(SIGN(ROUND(@rate_home,6))))/(@rate_home + SIGN(1 - ABS(SIGN(ROUND(@rate_home,6)))))) * SIGN(SIGN(@rate_home) - 1) )) * ROUND(ABS(amt_applied * ( SIGN(1 + SIGN(@rate_home))*(@rate_home) + (SIGN(ABS(SIGN(ROUND(@rate_home,6))))/(@rate_home + SIGN(1 - ABS(SIGN(ROUND(@rate_home,6)))))) * SIGN(SIGN(@rate_home) - 1) )) + 0.0000001, @home_precision)) 
UPDATE #vouchers SET gain_oper = (SIGN(vo_amt_applied * ( SIGN(1 + SIGN(@rate_oper))*(@rate_oper) + (SIGN(ABS(SIGN(ROUND(@rate_oper,6))))/(@rate_oper + SIGN(1 - ABS(SIGN(ROUND(@rate_oper,6)))))) * SIGN(SIGN(@rate_oper) - 1) )) * ROUND(ABS(vo_amt_applied * ( SIGN(1 + SIGN(@rate_oper))*(@rate_oper) + (SIGN(ABS(SIGN(ROUND(@rate_oper,6))))/(@rate_oper + SIGN(1 - ABS(SIGN(ROUND(@rate_oper,6)))))) * SIGN(SIGN(@rate_oper) - 1) )) + 0.0000001, @oper_precision)) 
 - (SIGN(amt_applied * ( SIGN(1 + SIGN(@rate_oper))*(@rate_oper) + (SIGN(ABS(SIGN(ROUND(@rate_oper,6))))/(@rate_oper + SIGN(1 - ABS(SIGN(ROUND(@rate_oper,6)))))) * SIGN(SIGN(@rate_oper) - 1) )) * ROUND(ABS(amt_applied * ( SIGN(1 + SIGN(@rate_oper))*(@rate_oper) + (SIGN(ABS(SIGN(ROUND(@rate_oper,6))))/(@rate_oper + SIGN(1 - ABS(SIGN(ROUND(@rate_oper,6)))))) * SIGN(SIGN(@rate_oper) - 1) )) + 0.0000001, @oper_precision)) 
DROP TABLE #amt_paid DELETE #vouchers WHERE (ABS((vo_amt_applied + vo_amt_disc_taken)-(0.0)) < 0.0000001) 
   IF ((SELECT COUNT(*) FROM #vouchers) = 0) BEGIN  SELECT @amt_applied_orig, @amt_disc_taken_orig 
 RETURN 0 END    SET ROWCOUNT 1 SELECT * INTO #aptrxapl_one FROM #vouchers ORDER BY trx_ctrl_num 
SET ROWCOUNT 0 SELECT @one_check_flag = ISNULL(one_check_flag,0) FROM #aptrxapl_one 
IF ( @one_check_flag = 0 ) BEGIN  DELETE #vouchers WHERE one_check_flag = 1 END 
ELSE BEGIN       DELETE #vouchers  INSERT #vouchers (  trx_ctrl_num,  trx_type, 
 nat_cur_code,  rate_type_home,  rate_home,  rate_oper,  terms_code,  date_discount, 
 date_applied,  vo_precision,  amt_paid_to_date,  amt_net,  vo_amt_applied,  vo_amt_disc_taken, 
 cross_rate,  amt_applied,  amt_disc_taken,  gain_home,  gain_oper,  one_check_flag, 
 used )  SELECT  trx_ctrl_num,  trx_type,  nat_cur_code,  rate_type_home,  rate_home, 
 rate_oper,  terms_code,  date_discount,  date_applied,  vo_precision,  amt_paid_to_date, 
 amt_net,  vo_amt_applied,  vo_amt_disc_taken,  cross_rate,  amt_applied,  amt_disc_taken, 
 gain_home,  gain_oper,  one_check_flag,  used  FROM #aptrxapl_one END DROP TABLE #aptrxapl_one 
SELECT @sequence_id = 1 WHILE (1=1) BEGIN  SELECT  @voucher_no = "",  @amt_applied = 0.0, 
 @amt_disc_taken = 0.0,  @vo_amt_applied = 0.0,  @vo_amt_disc_taken = 0.0      SET ROWCOUNT 1 
 SELECT  @voucher_no = trx_ctrl_num,  @amt_applied = amt_applied,  @amt_disc_taken = amt_disc_taken, 
 @vo_amt_applied = vo_amt_applied,  @vo_amt_disc_taken = vo_amt_disc_taken,  @vo_precision = vo_precision, 
 @cross_rate = cross_rate,  @gain_home = gain_home,  @gain_oper = gain_oper,  @nat_cur_code = nat_cur_code, 
 @cross_rate = cross_rate  FROM #vouchers  WHERE used = 0  IF @@rowcount = 0  BREAK 
 SET ROWCOUNT 0        IF (((@amt_payment) >= (@amt_applied) - 0.0000001) OR (@payment_type = 1 AND @payment_meth <> 1)) 
 BEGIN  INSERT #apinppdt3450(  trx_ctrl_num,  trx_type,  sequence_id,  apply_to_num, 
 apply_trx_type,  amt_applied,  amt_disc_taken,  line_desc,  void_flag,  payment_hold_flag, 
 vendor_code,  vo_amt_applied,  vo_amt_disc_taken,  gain_home,  gain_oper,  nat_cur_code, 
 cross_rate)  SELECT @settlement_ctrl_num,  4111,  @sequence_id,  @voucher_no,  4091, 
 @amt_applied,  @amt_disc_taken,  "",  0,  0,  @vendor_code,  @vo_amt_applied,  @vo_amt_disc_taken, 
 @gain_home,  @gain_oper,  @nat_cur_code,  @cross_rate      IF EXISTS (SELECT voucher_no FROM #paying_vouchers 
 WHERE voucher_no = @voucher_no)  BEGIN  UPDATE #paying_vouchers  SET  amt_applied = amt_applied + @amt_applied, 
 vo_amt_applied = vo_amt_applied + @vo_amt_applied,  vo_amt_disc_taken = vo_amt_disc_taken + @vo_amt_disc_taken 
 WHERE voucher_no = @voucher_no  END  ELSE  BEGIN  INSERT #paying_vouchers(  amt_applied, 
 vo_amt_applied,  vo_amt_disc_taken,  voucher_no,  payment_no)  SELECT @amt_applied, 
 @vo_amt_applied,  @vo_amt_disc_taken,  @voucher_no,  @trx_ctrl_num  END      SELECT @amt_payment = @amt_payment - @amt_applied 
 END      ELSE IF ( ((@amt_payment) > (0.0) + 0.0000001))  BEGIN  SELECT  @amt_applied = @amt_payment, 
 @amt_disc_taken = 0.0,  @vo_amt_applied = (SIGN(@amt_applied / @cross_rate) * ROUND(ABS(@amt_applied / @cross_rate) + 0.0000001, @vo_precision)), 
 @vo_amt_disc_taken = 0.0  INSERT #apinppdt3450(  trx_ctrl_num,  trx_type,  sequence_id, 
 apply_to_num,  apply_trx_type,  amt_applied,  amt_disc_taken,  line_desc,  void_flag, 
 payment_hold_flag,  vendor_code,  vo_amt_applied,  vo_amt_disc_taken,  gain_home, 
 gain_oper,  nat_cur_code)  SELECT @settlement_ctrl_num,  4111,  @sequence_id,  @voucher_no, 
 4091,  @amt_applied,  @amt_disc_taken,  "",  0,  0,  @vendor_code,  @vo_amt_applied, 
 @vo_amt_disc_taken,  @gain_home,  @gain_oper,  @nat_cur_code      IF EXISTS (SELECT voucher_no FROM #paying_vouchers 
 WHERE voucher_no = @voucher_no)  BEGIN  UPDATE #paying_vouchers  SET  amt_applied = amt_applied + @amt_applied, 
 vo_amt_applied = vo_amt_applied + @vo_amt_applied,  vo_amt_disc_taken = vo_amt_disc_taken + @vo_amt_disc_taken 
 WHERE voucher_no = @voucher_no  END  ELSE  BEGIN  INSERT #paying_vouchers(  amt_applied, 
 vo_amt_applied,  vo_amt_disc_taken,  voucher_no,  payment_no)  SELECT @amt_applied, 
 @vo_amt_applied,  @vo_amt_disc_taken,  @voucher_no,  @trx_ctrl_num  END  BREAK  END 
     ELSE  BREAK  UPDATE #vouchers  SET used=1  WHERE trx_ctrl_num=@voucher_no  SELECT @sequence_id = @sequence_id + 1 
END END DROP TABLE #vouchers                     SELECT SUM(amt_applied), SUM(amt_disc_taken) 
FROM #apinppdt3450 WHERE trx_ctrl_num = @settlement_ctrl_num DROP TABLE #paying_vouchers 
GO
GRANT EXECUTE ON  [dbo].[apstlldpyt_sp] TO [public]
GO
