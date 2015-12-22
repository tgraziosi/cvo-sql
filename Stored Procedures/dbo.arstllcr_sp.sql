SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[arstllcr_sp] @settlement_ctrl_num varchar(16),  @customer_code varchar(8), 
 @include_na smallint,  @load_option smallint,  @all_doc_date smallint,  @doc_date_from int, 
 @doc_date_to int,  @all_cur_code smallint,  @cur_code_from varchar(8),  @cur_code_to varchar(8), 
 @date_entered int,  @date_applied int,  @user_id smallint,  @auto_apply smallint 
AS DECLARE @new_trx_ctrl_num varchar(16),  @num int,  @cnt int    CREATE TABLE #arvpay 
(
 customer_code varchar(8),  customer_name varchar(40) NULL,  bal_fwd_flag smallint NULL, 
 seq_id smallint NULL 
)
IF ( @include_na = 1 )  EXEC arvalpay_sp @customer_code ELSE BEGIN  INSERT #arvpay( customer_code,customer_name, bal_fwd_flag ) 
 SELECT customer_code,customer_name, bal_fwd_flag FROM arcust  WHERE customer_code = @customer_code 
END    CREATE TABLE #avail_onacct_ld 
(
 customer_code varchar(8),  doc_ctrl_num varchar(16),  payment_type smallint,  amt_on_acct float, 
 in_use smallint 
)
   INSERT #avail_onacct_ld 
(
 customer_code, doc_ctrl_num, payment_type, amt_on_acct, in_use 
)
SELECT  t.customer_code, doc_ctrl_num, payment_type,amt_on_acct, 0 FROM artrx t, #arvpay p 
WHERE t.customer_code = p.customer_code AND trx_type = 2111 AND ( ( payment_type = case when @load_option = 0 then 1 else @load_option end ) 
 OR ( payment_type = case when @load_option = 0 then 3 else @load_option end ) ) 
AND void_flag = 0 AND amt_on_acct > 0 AND ( date_doc in ( @doc_date_from, @doc_date_to ) OR ( @all_doc_date = 1 ) ) 
AND ( nat_cur_code in ( @cur_code_from, @cur_code_to ) OR (@all_cur_code = 1) )  
  DELETE #avail_onacct_ld FROM #avail_onacct_ld a, arinppyt p WHERE p.trx_type = 2111 
AND p.payment_type in ( 2, 4 ) AND p.non_ar_flag = 0 AND a.doc_ctrl_num = p.doc_ctrl_num 
AND a.customer_code = p.customer_code     DELETE #avail_onacct_ld FROM #avail_onacct_ld a, #arinppyt4750 p 
WHERE p.trx_type = 2111 AND p.payment_type in ( 2, 4 ) AND p.non_ar_flag = 0 AND a.doc_ctrl_num = p.doc_ctrl_num 
AND p.customer_code = a.customer_code     INSERT #arinppyt4750 
(
 settlement_ctrl_num, trx_ctrl_num, doc_ctrl_num, trx_desc,  batch_code, trx_type, non_ar_flag, non_ar_doc_num, 
 gl_acct_code, date_entered, date_applied, date_doc,  customer_code, payment_code, payment_type, amt_payment, 
 amt_on_acct, prompt1_inp, prompt2_inp, prompt3_inp,  prompt4_inp, deposit_num, bal_fwd_flag, printed_flag, 
 posted_flag, hold_flag, wr_off_flag, on_acct_flag,  user_id, max_wr_off, days_past_due, void_type, 
 cash_acct_code, origin_module_flag, process_group_num, source_trx_ctrl_num,  source_trx_type, nat_cur_code, rate_type_home, rate_type_oper, 
 rate_home, rate_oper, amt_discount, reference_code,  doc_amount 
)
SELECT  @settlement_ctrl_num, "", p.doc_ctrl_num, "",  "", 2111, 0, "",  "", @date_entered, @date_applied, date_doc, 
 p.customer_code, payment_code, case when p.payment_type = 3 then 4 else 2 end, (@auto_apply * p.amt_on_acct), 
 ((1 - @auto_apply) * p.amt_on_acct), prompt1_inp, prompt2_inp, prompt3_inp,  prompt4_inp, "", c.bal_fwd_flag, 0, 
 0, 0, 0, 0,  @user_id, 0.0, 0, 0,  cash_acct_code, NULL, NULL, NULL,  NULL, nat_cur_code, rate_type_home, rate_type_oper, 
 rate_home, rate_oper, 0.0, "",  p.amt_on_acct FROM artrx p, #avail_onacct_ld a, #arvpay c 
WHERE p.doc_ctrl_num = a.doc_ctrl_num AND p.customer_code = a.customer_code AND p.customer_code = c.customer_code 
AND p.amt_on_acct > 0 AND void_flag = 0 AND non_ar_flag = 0 AND trx_type = 2111 DROP TABLE #arvpay 
DROP TABLE #avail_onacct_ld    INSERT #avail_onacct ( doc_ctrl_num, customer_code, cr_type, amt_on_acct , in_use ) 
SELECT doc_ctrl_num, customer_code, "", 0.0, 1 FROM #arinppyt4750 WHERE trx_ctrl_num = "" 
SELECT @cnt = 0    WHILE ( 1 = 1 ) BEGIN      EXEC ARGetNextControl_SP 2010,  @new_trx_ctrl_num OUTPUT, 
 @num OUTPUT  SET ROWCOUNT 1  UPDATE #arinppyt4750  SET trx_ctrl_num = @new_trx_ctrl_num 
 WHERE trx_ctrl_num =""  IF ( @@rowcount = 0 )  BEGIN  SET ROWCOUNT 0  BREAK  END 
 SET ROWCOUNT 0  SELECT @cnt = @cnt + 1 END SELECT @cnt RETURN 
GO
GRANT EXECUTE ON  [dbo].[arstllcr_sp] TO [public]
GO
