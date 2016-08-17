SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[ARCACreateAgingRecs_SP]    @batch_ctrl_num varchar(16),  
            @debug_level    smallint,  
            @perf_level   smallint    
AS  
  
DECLARE  
        @PERF_time_last     datetime  
  
SELECT  @PERF_time_last = GETDATE()  
  
  
DECLARE  
  @result int,  
  @precision  float  
  
  
IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "arcacar.cpp", 77, "Entering ARCACreateAgingRecs", @PERF_time_last OUTPUT  
  
BEGIN  
  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcacar.cpp" + ", line " + STR( 80, 5 ) + " -- ENTRY: "  
  
  
IF ( EXISTS(SELECT 1 from arco with (nolock) where chargeback_flag = 1 ))  
BEGIN  
  INSERT #artrxage_work   
  (  
  trx_ctrl_num, doc_ctrl_num, apply_to_num,   
  trx_type, date_doc, date_due,   
  date_aging, customer_code, salesperson_code,  
  territory_code, price_code, amount,   
  paid_flag, apply_trx_type, ref_id,   
  group_id, sub_apply_num, sub_apply_type,   
  amt_fin_chg, amt_late_chg, amt_paid,   
  date_applied, cust_po_num, order_ctrl_num,  
  db_action, payer_cust_code, nat_cur_code,  
  rate_home, rate_oper, true_amount,  
  date_paid,      journal_ctrl_num, account_code, org_id   
  )   
  SELECT   
  pdt.trx_ctrl_num, pdt.doc_ctrl_num, pdt.apply_to_num,   
  pdt.trx_type, pdt.date_doc, 0,   
  pdt.date_aging, pdt.customer_code, ' ',  
  ' ', ' ', pdt.inv_amt_applied,   
  0, pdt.apply_trx_type, pdt.sequence_id,   
  0, pdt.sub_apply_num, pdt.sub_apply_type,   
  0.0, 0.0, 0.0,   
  pyt.date_applied, ' ', ' ',  
  20, pyt.customer_code, pdt.inv_cur_code,  
  age.rate_home, age.rate_oper, pdt.amt_applied,  
  0, ' ', ' ' , age.org_id  
  FROM #arinppdt_work pdt, #arinppyt_work pyt, #artrxage_work age  
  WHERE pdt.trx_ctrl_num = pyt.trx_ctrl_num  
  AND pdt.trx_type = pyt.trx_type  
  AND pdt.amt_applied > 0.0  
  AND pyt.batch_code = @batch_ctrl_num  
  AND pdt.doc_ctrl_num = age.doc_ctrl_num  
  AND age.trx_type in (2111, 2032)  
  AND pdt.payer_cust_code = age.payer_cust_code  
  AND pdt.sequence_id = age.ref_id  
   
  AND age.apply_trx_type <> 2161  
   
END  
ELSE  
BEGIN  
  INSERT #artrxage_work   
  (  
  trx_ctrl_num, doc_ctrl_num, apply_to_num,   
  trx_type, date_doc, date_due,   
  date_aging, customer_code, salesperson_code,  
  territory_code, price_code, amount,   
  paid_flag, apply_trx_type, ref_id,   
  group_id, sub_apply_num, sub_apply_type,   
  amt_fin_chg, amt_late_chg, amt_paid,   
  date_applied, cust_po_num, order_ctrl_num,  
  db_action, payer_cust_code, nat_cur_code,  
  rate_home, rate_oper, true_amount,  
  date_paid,      journal_ctrl_num, account_code, org_id   
  )   
  SELECT   
  pdt.trx_ctrl_num, pdt.doc_ctrl_num, pdt.apply_to_num,   
  pdt.trx_type, pdt.date_doc, 0,   
  pdt.date_aging, pdt.customer_code, ' ',  
  ' ', ' ', pdt.inv_amt_applied,   
  0, pdt.apply_trx_type, pdt.sequence_id,   
  0, pdt.sub_apply_num, pdt.sub_apply_type,   
  0.0, 0.0, 0.0,   
  pyt.date_applied, ' ', ' ',  
  20, pyt.customer_code, pdt.inv_cur_code,  
  age.rate_home, age.rate_oper, pdt.amt_applied,  
  0, ' ', ' ' , age.org_id  
  FROM #arinppdt_work pdt, #arinppyt_work pyt, #artrxage_work age  
  WHERE pdt.trx_ctrl_num = pyt.trx_ctrl_num  
  AND pdt.trx_type = pyt.trx_type  
  AND pdt.amt_applied > 0.0  
  AND pyt.batch_code = @batch_ctrl_num  
  AND pdt.doc_ctrl_num = age.doc_ctrl_num  
  AND age.trx_type in (2111, 2032)  
  AND pdt.payer_cust_code = age.payer_cust_code  
  AND pdt.sequence_id = age.ref_id  
END  
  
  IF( @@error != 0 )  
  BEGIN  
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcacar.cpp" + ", line " + STR( 195, 5 ) + " -- EXIT: "  
    RETURN 34563  
  END  
  
  
  INSERT  #artrxage_work   
    (  
  trx_ctrl_num,     doc_ctrl_num,     apply_to_num,   
  trx_type,       date_doc,       date_due,   
  date_aging,       customer_code,    salesperson_code,  
  territory_code,     price_code,       amount,   
  paid_flag,      apply_trx_type,   ref_id,   
  group_id,       sub_apply_num,    sub_apply_type,   
  amt_fin_chg,      amt_late_chg,     amt_paid,   
  date_applied,     cust_po_num,      order_ctrl_num,  
  db_action,      payer_cust_code,    nat_cur_code,  
  rate_home,      rate_oper,      true_amount,  
  date_paid,      journal_ctrl_num, account_code, org_id   
  )        
  SELECT   
  pdt.trx_ctrl_num,   pdt.doc_ctrl_num,     pdt.apply_to_num,   
  2132,    pdt.date_doc,     0,   
  pdt.date_aging,     pdt.customer_code,    ' ',  
  ' ',        ' ',        pdt.inv_amt_disc_taken,   
  0,        pdt.apply_trx_type,   pdt.sequence_id,   
  0,        pdt.sub_apply_num,    pdt.sub_apply_type,   
  0,        0,        0,   
  pyt.date_applied,     ' ',        ' ',  
  20,       pyt.customer_code,    pdt.inv_cur_code,  
  trx.rate_home,    trx.rate_oper,    pdt.inv_amt_disc_taken,  
  0,        ' ',        ' ' , trx.org_id      
  FROM  #arinppdt_work pdt, #arinppyt_work  pyt, #artrx_work trx  
  WHERE pdt.trx_ctrl_num = pyt.trx_ctrl_num  
  AND pdt.trx_type = pyt.trx_type  
  AND pdt.inv_amt_disc_taken > 0.0  
  AND pyt.batch_code = @batch_ctrl_num  
  AND pdt.sub_apply_num = trx.doc_ctrl_num  
  AND pdt.sub_apply_type = trx.trx_type  
  
  IF( @@error != 0 )  
  BEGIN  
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcacar.cpp" + ", line " + STR( 241, 5 ) + " -- EXIT: "  
    RETURN 34563  
  END  
  
    
  
  
  
  INSERT  #artrxage_work   
  (  
  trx_ctrl_num,     doc_ctrl_num,     apply_to_num,   
  trx_type,       date_doc,       date_due,   
  date_aging,       customer_code,    salesperson_code,  
  territory_code,     price_code,       amount,   
  paid_flag,      apply_trx_type,   ref_id,   
  group_id,       sub_apply_num,    sub_apply_type,   
  amt_fin_chg,      amt_late_chg,     amt_paid,   
  date_applied,     cust_po_num,      order_ctrl_num,  
  db_action,      payer_cust_code,    nat_cur_code,  
  rate_home,      rate_oper,      true_amount,  
  date_paid,      journal_ctrl_num, account_code , org_id  
  )        
  SELECT   
  pdt.trx_ctrl_num,   pdt.doc_ctrl_num,     pdt.apply_to_num,   
  2142,      pdt.date_doc,     0,   
  pdt.date_aging,     pdt.customer_code,    ' ',  
  ' ',        ' ',        pdt.inv_amt_max_wr_off,   
  0,        pdt.apply_trx_type,   pdt.sequence_id,   
  0,        pdt.sub_apply_num,    pdt.sub_apply_type,   
  0,        0,        0,   
  pyt.date_applied,     ' ',        ' ',  
  20,       pyt.customer_code,    pdt.inv_cur_code,  
  trx.rate_home,    trx.rate_oper,    pdt.inv_amt_max_wr_off,  
  0,        ' ',        ' ' , trx.org_id  
  FROM  #arinppdt_work pdt, #arinppyt_work  pyt, #artrx_work trx    
  WHERE pdt.trx_ctrl_num = pyt.trx_ctrl_num  
  AND pdt.trx_type = pyt.trx_type  
  AND pdt.wr_off_flag = 1  
  AND pdt.inv_amt_max_wr_off <> 0.0  
  AND pyt.batch_code = @batch_ctrl_num  
  AND pdt.sub_apply_num = trx.doc_ctrl_num  
  AND pdt.sub_apply_type = trx.trx_type  
  
  IF( @@error != 0 )  
  BEGIN  
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcacar.cpp" + ", line " + STR( 286, 5 ) + " -- EXIT: "  
    RETURN 34563  
  END  
  
  
  
  SELECT  age.territory_code,  
    age.price_code,  
    age.salesperson_code,  
    age.order_ctrl_num,  
    age.cust_po_num,  
    age.date_due,  
    age.doc_ctrl_num,  
    age.trx_type,  
    age.date_aging,  
    dbo.IBAcctMask_fn(acct.ar_acct_code,trx.org_id) as ar_acct_code  
  INTO  #artrxage_inv  
  FROM  #artrxage_work age, #artrx_work trx, araccts acct  
  WHERE age.trx_type IN ( 2021, 2031, 2071)  
  AND age.doc_ctrl_num = trx.doc_ctrl_num  
  AND age.trx_type = trx.trx_type   
  AND trx.posting_code = acct.posting_code  
  
  IF( @@error != 0 )  
  BEGIN  
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcacar.cpp" + ", line " + STR( 326, 5 ) + " -- EXIT: "  
    RETURN 34563  
  END  
  
  UPDATE #artrxage_work  
  SET territory_code = age2.territory_code,  
    price_code = age2.price_code,  
    salesperson_code = age2.salesperson_code,  
    order_ctrl_num = age2.order_ctrl_num,  
    cust_po_num = age2.cust_po_num,  
    date_due = age2.date_due,  
    account_code = age2.ar_acct_code,  
    journal_ctrl_num = trx.journal_ctrl_num,  
    db_action = 2  
  FROM  #artrxage_work, #artrxage_inv age2, #arcatemp trx  
  WHERE #artrxage_work.sub_apply_num = age2.doc_ctrl_num  
  AND #artrxage_work.sub_apply_type = age2.trx_type  
  AND #artrxage_work.date_aging = age2.date_aging  
  AND #artrxage_work.trx_ctrl_num = trx.trx_ctrl_num  
  AND #artrxage_work.db_action = 20   
  
  IF( @@error != 0 )  
  BEGIN  
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcacar.cpp" + ", line " + STR( 349, 5 ) + " -- EXIT: "  
    RETURN 34563  
  END  
    
  
        
  INSERT  #artrxage_work   
    (  
  trx_ctrl_num,     doc_ctrl_num,     apply_to_num,   
  trx_type,       date_doc,       date_due,   
  date_aging,       customer_code,    salesperson_code,  
  territory_code,     price_code,       amount,   
  paid_flag,      apply_trx_type,   ref_id,   
  group_id,       sub_apply_num,    sub_apply_type,   
  amt_fin_chg,      amt_late_chg,     amt_paid,   
  date_applied,     cust_po_num,      order_ctrl_num,  
  db_action,      payer_cust_code,    nat_cur_code,  
  rate_home,      rate_oper,      true_amount,  
  date_paid,      journal_ctrl_num,   account_code , org_id  
  )        
  SELECT   
  pyt.trx_ctrl_num,   age.doc_ctrl_num,     age.doc_ctrl_num,   
  pyt.trx_type,       pyt.date_doc,     age.date_due,   
  age.date_aging,     pyt.customer_code,    age.salesperson_code,  
  age.territory_code,        age.price_code,        -age.amount,   
  1,        age.trx_type,     age.ref_id,   
  0,        age.doc_ctrl_num,     age.trx_type,   
  0,        0,        0,   
  pyt.date_applied,     age.order_ctrl_num,     age.cust_po_num,  
  2,    age.customer_code,    age.nat_cur_code,  
  age.rate_home,    age.rate_oper,    -age.amount,  
  0,        gl.journal_ctrl_num,    dbo.IBAcctMask_fn(meth.on_acct_code,pyt.org_id)      , age.org_id     
  FROM  #artrxage_work age, #arinppyt_work  pyt, arpymeth meth, #arcatemp gl  
  WHERE age.doc_ctrl_num = pyt.doc_ctrl_num  
  AND age.customer_code = pyt.customer_code  
  AND age.trx_type = 2111  
  AND pyt.trx_type between 2113 and 2121  
  AND pyt.batch_code = @batch_ctrl_num  
  AND pyt.payment_code = meth.payment_code  
  AND pyt.trx_ctrl_num = gl.trx_ctrl_num  
  AND age.ref_id = 0  
    
  IF( @@error != 0 )  
  BEGIN  
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcacar.cpp" + ", line " + STR( 400, 5 ) + " -- EXIT: "  
    RETURN 34563  
  END  
  
    
  
  
  
  
  
  SELECT pdt.trx_ctrl_num, arca.journal_ctrl_num, pdt.payer_cust_code, pdt.doc_ctrl_num,   
    SUM(pdt.amt_applied) offset_amount  
  INTO  #age_offset  
  FROM  #arinppdt_work pdt, #arinppyt_work  pyt, #arcatemp arca  
  WHERE pdt.trx_ctrl_num = pyt.trx_ctrl_num  
  AND pdt.trx_type = pyt.trx_type  
  AND pyt.trx_ctrl_num = arca.trx_ctrl_num  
  AND pdt.amt_applied > 0.0  
  AND pyt.batch_code = @batch_ctrl_num  
  GROUP BY pdt.trx_ctrl_num, arca.journal_ctrl_num, pdt.payer_cust_code, pdt.doc_ctrl_num  
  
  IF( @@error != 0 )  
  BEGIN  
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcacar.cpp" + ", line " + STR( 423, 5 ) + " -- EXIT: "  
    RETURN 34563  
  END  
  
  IF (@debug_level > 0)  
  BEGIN  
    SELECT "Dumping #age_offset..."   
    SELECT "trx_ctrl_num = " + trx_ctrl_num +  
      "payer_cust_code = " + payer_cust_code +  
      "doc_ctrl_num = " + doc_ctrl_num +  
      "offset_amount = " + STR(offset_amount, 10, 2)  
    FROM #age_offset  
  END  
    
  
  
IF ( EXISTS(SELECT 1 from arco with (nolock) where chargeback_flag = 1 ))  
BEGIN  
   
  
    
  SELECT trx.doc_ctrl_num, trx.customer_code, sum(total_chargebacks) total_chargebacks  
  INTO #arcbtot  
  FROM arcbtot cb, #arinppyt_work pyt, artrx trx  
  WHERE pyt.doc_ctrl_num = trx.doc_ctrl_num  
  AND pyt.customer_code = trx.customer_code  
  AND trx.trx_ctrl_num = cb.trx_ctrl_num  
  GROUP BY trx.doc_ctrl_num, trx.customer_code  
    
   
  IF NOT EXISTS (SELECT trx_ctrl_num FROM #age_offset)  
   UPDATE #artrxage_work  
   SET amount = amount + isnull(total_chargebacks,0),  
    true_amount = true_amount +  isnull(total_chargebacks,0)  
   FROM #arinppyt_work pyt, #artrxage_work age  
   LEFT OUTER JOIN #arcbtot cb ON age.doc_ctrl_num = cb.doc_ctrl_num  AND age.payer_cust_code = cb.customer_code   
   WHERE pyt.batch_code = @batch_ctrl_num  
   AND pyt.doc_ctrl_num = age.doc_ctrl_num  
   AND age.doc_ctrl_num = age.apply_to_num  
   AND age.ref_id = 0  
   AND age.trx_type = 2113  
    
   
  INSERT #artrxage_work   
   (  
  trx_ctrl_num,   doc_ctrl_num,  apply_to_num,   
  trx_type,    date_doc,   date_due,   
  date_aging,    customer_code,  salesperson_code,  
   territory_code,   price_code,   amount,   
   paid_flag,    apply_trx_type, ref_id,   
   group_id,    sub_apply_num,  sub_apply_type,   
   amt_fin_chg,   amt_late_chg,  amt_paid,   
   date_applied,   cust_po_num,   order_ctrl_num,  
   db_action,   payer_cust_code, nat_cur_code,  
   rate_home,   rate_oper,  true_amount,  
   date_paid,   journal_ctrl_num,  account_code, org_id   
  )   
  SELECT   
  pyt.trx_ctrl_num,  pyt.doc_ctrl_num,   pyt.doc_ctrl_num,   
  pyt.trx_type,    pyt.date_doc,   0,   
  age.date_aging,   offset.payer_cust_code,  age.salesperson_code,  
   age.territory_code,         age.price_code,   -offset.offset_amount + isnull(total_chargebacks,0),   
   0,     age.trx_type,   -1,   
   0,     pyt.doc_ctrl_num,   age.trx_type,   
   0.0,    0.0,    0.0,   
   pyt.date_applied,   ' ',     ' ',  
   2,  pyt.customer_code,  pyt.nat_cur_code,  
  age.rate_home,  age.rate_oper,  -offset.offset_amount + isnull(total_chargebacks,0),  
  0,    offset.journal_ctrl_num, dbo.IBAcctMask_fn(meth.on_acct_code,pyt.org_id), age.org_id     
    
  FROM #arinppyt_work pyt, #age_offset offset, arpymeth meth,   
   #artrxage_work age  
   LEFT OUTER JOIN #arcbtot cb ON age.doc_ctrl_num = cb.doc_ctrl_num AND age.payer_cust_code = cb.customer_code   
    
  WHERE pyt.batch_code = @batch_ctrl_num  
  AND pyt.trx_ctrl_num = offset.trx_ctrl_num  
  AND pyt.doc_ctrl_num = offset.doc_ctrl_num  
  AND pyt.void_type != 3   
  AND pyt.customer_code = age.payer_cust_code  
  AND pyt.doc_ctrl_num = age.doc_ctrl_num  
  AND age.trx_type = 2111  
  AND age.ref_id = 0  
  AND pyt.payment_code = meth.payment_code  
   
   
   
  INSERT #artrxage_work   
  (  
  trx_ctrl_num, doc_ctrl_num, apply_to_num,   
  trx_type, date_doc, date_due,   
  date_aging, customer_code, salesperson_code,  
  territory_code, price_code, amount,   
  paid_flag, apply_trx_type, ref_id,   
  group_id, sub_apply_num, sub_apply_type,   
  amt_fin_chg, amt_late_chg, amt_paid,   
  date_applied, cust_po_num, order_ctrl_num,  
  db_action, payer_cust_code, nat_cur_code,  
  rate_home, rate_oper, true_amount,  
  date_paid, journal_ctrl_num, account_code, org_id  
  )   
  SELECT   
  pyt.trx_ctrl_num, pyt.doc_ctrl_num, pyt.doc_ctrl_num,   
  age.trx_type, pyt.date_doc, 0,   
  age.date_aging, offset.payer_cust_code, age.salesperson_code,  
  age.territory_code, age.price_code, -offset.offset_amount,   
  0, age.trx_type, -1,   
  0, pyt.doc_ctrl_num, age.trx_type,   
  0.0, 0.0, 0.0,   
  pyt.date_applied, ' ', ' ',  
  2, pyt.customer_code, pyt.nat_cur_code,  
  age.rate_home, age.rate_oper, -offset.offset_amount,  
  0, offset.journal_ctrl_num, dbo.IBAcctMask_fn(meth.on_acct_code,pyt.org_id), age.org_id     
  FROM #arinppyt_work pyt, #age_offset offset, #artrxage_work age, arpymeth meth  
  WHERE pyt.batch_code = @batch_ctrl_num  
  AND pyt.trx_ctrl_num = offset.trx_ctrl_num  
  AND pyt.doc_ctrl_num = offset.doc_ctrl_num  
  AND pyt.void_type = 3   
  AND pyt.customer_code = age.payer_cust_code  
  AND pyt.doc_ctrl_num = age.doc_ctrl_num  
  AND age.trx_type = 2111  
  AND age.ref_id = 0  
  AND pyt.payment_code = meth.payment_code  
    
END  
ELSE  
BEGIN  
   
  INSERT #artrxage_work   
  (  
  trx_ctrl_num, doc_ctrl_num, apply_to_num,   
  trx_type, date_doc, date_due,   
  date_aging, customer_code, salesperson_code,  
  territory_code, price_code, amount,   
  paid_flag, apply_trx_type, ref_id,   
  group_id, sub_apply_num, sub_apply_type,   
  amt_fin_chg, amt_late_chg, amt_paid,   
  date_applied, cust_po_num, order_ctrl_num,  
  db_action, payer_cust_code, nat_cur_code,  
  rate_home, rate_oper, true_amount,  
  date_paid, journal_ctrl_num, account_code, org_id  
  )   
  SELECT   
  pyt.trx_ctrl_num, pyt.doc_ctrl_num, pyt.doc_ctrl_num,   
  pyt.trx_type, pyt.date_doc, 0,   
  age.date_aging, offset.payer_cust_code, age.salesperson_code,  
  age.territory_code, age.price_code, -offset.offset_amount,   
  0, age.trx_type, -1,   
  0, pyt.doc_ctrl_num, age.trx_type,   
  0.0, 0.0, 0.0,   
  pyt.date_applied, ' ', ' ',  
  2, pyt.customer_code, pyt.nat_cur_code,  
  age.rate_home, age.rate_oper, -offset.offset_amount,  
  0, offset.journal_ctrl_num, dbo.IBAcctMask_fn(meth.on_acct_code,pyt.org_id), age.org_id    
  FROM #arinppyt_work pyt, #age_offset offset, #artrxage_work age, arpymeth meth  
  WHERE pyt.batch_code = @batch_ctrl_num  
  AND pyt.trx_ctrl_num = offset.trx_ctrl_num  
  AND pyt.doc_ctrl_num = offset.doc_ctrl_num  
  AND pyt.void_type != 3   
  AND pyt.customer_code = age.payer_cust_code  
  AND pyt.doc_ctrl_num = age.doc_ctrl_num  
  AND age.trx_type = 2111  
  AND age.ref_id = 0  
  AND pyt.payment_code = meth.payment_code  
   
  
 
  
   INSERT  #artrxage_work   
     (  
   trx_ctrl_num,     doc_ctrl_num,   apply_to_num,   
   trx_type,       date_doc,     date_due,   
   date_aging,       customer_code,  salesperson_code,  
   territory_code,     price_code,     amount,   
   paid_flag,      apply_trx_type, ref_id,   
   group_id,       sub_apply_num,  sub_apply_type,   
   amt_fin_chg,      amt_late_chg,   amt_paid,   
   date_applied,     cust_po_num,    order_ctrl_num,  
   db_action,      payer_cust_code,  nat_cur_code,  
   rate_home,      rate_oper,    true_amount,  
   date_paid,      journal_ctrl_num,   account_code , org_id  
   )        
   SELECT   
   pyt.trx_ctrl_num,   pyt.doc_ctrl_num,     pyt.doc_ctrl_num,   
   age.trx_type,           pyt.date_doc,     0,   
   age.date_aging,     offset.payer_cust_code,   age.salesperson_code,  
   age.territory_code,        age.price_code,        -offset.offset_amount,   
   0,        age.trx_type,     -1,   
   0,        pyt.doc_ctrl_num,     age.trx_type,   
   0.0,        0.0,        0.0,   
   pyt.date_applied,     ' ',        ' ',  
   2,    pyt.customer_code,    pyt.nat_cur_code,  
   age.rate_home,    age.rate_oper,    -offset.offset_amount,  
   0,        offset.journal_ctrl_num,  dbo.IBAcctMask_fn(meth.on_acct_code,pyt.org_id) , age.org_id     
   FROM  #arinppyt_work pyt, #age_offset offset, #artrxage_work age, arpymeth meth  
   WHERE pyt.batch_code = @batch_ctrl_num  
   AND pyt.trx_ctrl_num = offset.trx_ctrl_num  
   AND pyt.doc_ctrl_num = offset.doc_ctrl_num  
   AND pyt.void_type = 3    
   AND pyt.customer_code = age.payer_cust_code  
   AND pyt.doc_ctrl_num = age.doc_ctrl_num  
   AND age.trx_type = 2111  
   AND age.ref_id = 0  
   AND pyt.payment_code = meth.payment_code  
  
END  
    
  
    
   
  IF( @@error != 0 )  
  BEGIN  
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcacar.cpp" + ", line " + STR( 690, 5 ) + " -- EXIT: "  
    RETURN 34563  
  END  
  
  INSERT  #artrxage_work   
    (  
  trx_ctrl_num,     doc_ctrl_num,   apply_to_num,   
  trx_type,       date_doc,     date_due,   
  date_aging,       customer_code,  salesperson_code,  
  territory_code,     price_code,     amount,   
  paid_flag,      apply_trx_type, ref_id,   
  group_id,       sub_apply_num,  sub_apply_type,   
  amt_fin_chg,      amt_late_chg,   amt_paid,   
  date_applied,     cust_po_num,    order_ctrl_num,  
  db_action,      payer_cust_code,  nat_cur_code,  
  rate_home,      rate_oper,    true_amount,  
  date_paid,      journal_ctrl_num, account_code , org_id  
  )        
  SELECT   
  pyt.trx_ctrl_num,   pyt.doc_ctrl_num,     pyt.doc_ctrl_num,   
  2161,          pyt.date_doc,     0,   
  trx.date_aging,     offset.payer_cust_code,   trx.salesperson_code,  
  trx.territory_code,        trx.price_code,        -offset.offset_amount,   
  0,        2161,    -1,   
  0,        pyt.doc_ctrl_num,     2161,   
  0.0,        0.0,        0.0,   
  pyt.date_applied,     ' ',        ' ',  
  2,    pyt.customer_code,    pyt.nat_cur_code,  
  trx.rate_home,    trx.rate_oper,    -offset.offset_amount,  
  0,        offset.journal_ctrl_num,  dbo.IBAcctMask_fn(acct.cm_on_acct_code,trx.org_id)     , trx.org_id     
  FROM  #arinppyt_work pyt, #age_offset offset, #artrx_work trx, araccts acct  
  WHERE pyt.batch_code = @batch_ctrl_num  
  AND pyt.trx_ctrl_num = offset.trx_ctrl_num  
  AND pyt.doc_ctrl_num = offset.doc_ctrl_num  
  AND pyt.void_type = 3    
  AND pyt.customer_code = trx.customer_code  
  AND pyt.doc_ctrl_num = trx.doc_ctrl_num  
  AND trx.trx_type = 2111  
  AND trx.payment_type = 3  
  AND trx.posting_code = acct.posting_code  
  
  
  IF( @@error != 0 )  
  BEGIN  
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcacar.cpp" + ", line " + STR( 734, 5 ) + " -- EXIT: "  
    RETURN 34563  
  END  
  
   
  
 IF( @@error != 0 )  
 BEGIN  
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/arcacar.sp' + ', line ' + STR( 528, 5 ) + ' -- EXIT: '  
 RETURN 34563  
 END  
  
 IF ( EXISTS(SELECT 1 from arco with (nolock) where chargeback_flag = 1 ))  
 BEGIN  
  
   
  
  
  
    
  
  CREATE TABLE #artrxage_cb  
  (   
  trx_ctrl_num  varchar(16),  
  trx_type  smallint,  
  ref_id int,  
  doc_ctrl_num  varchar(16),  
  order_ctrl_num varchar(16),  
  cust_po_num  varchar(20),  
  apply_to_num  varchar(16),  
  apply_trx_type smallint,  
  sub_apply_num  varchar(16),  
  sub_apply_type smallint,  
  date_doc  int,  
  date_due  int,  
  date_applied  int,  
  date_aging  int,   
  customer_code  varchar(8),  
  payer_cust_code varchar(8),  
  salesperson_code varchar(8),  
  territory_code varchar(8),  
  price_code  varchar(8),  
  amount   float,  
  paid_flag  smallint,  
  group_id  int,  
  amt_fin_chg  float,  
  amt_late_chg  float,  
  amt_paid  float,  
  db_action  smallint,  
  rate_home  float,  
  rate_oper  float,  
  nat_cur_code  varchar(8),  
  true_amount  float,  
  date_paid  int,  
  journal_ctrl_num varchar(16),  
  account_code  varchar(32),  
  org_id   varchar(30) NULL  
  )  
  
  CREATE INDEX artrxage_cb_ind_0  
  ON #artrxage_cb( customer_code, trx_type, apply_trx_type, apply_to_num,   
  doc_ctrl_num, date_aging )  
  
  CREATE INDEX artrxage_cb_ind_1  
  ON #artrxage_cb( doc_ctrl_num, trx_type, date_aging, customer_code )  
  
  CREATE INDEX artrxage_cb_ind_2  
  ON #artrxage_cb( doc_ctrl_num, customer_code, ref_id, trx_type )  
  
  CREATE INDEX #artrxage_cb_ind_3   
  ON #artrxage_cb ( customer_code, doc_ctrl_num, trx_type )   
  
  CREATE INDEX #artrxage_work_ind_4   
  ON #artrxage_cb ( apply_to_num, apply_trx_type )  
  
  
    
  INSERT  #artrxage_cb   
   (  
  trx_ctrl_num,   doc_ctrl_num,   apply_to_num,   
  trx_type,    date_doc,    date_due,   
  date_aging,    customer_code,   salesperson_code,  
   territory_code,   price_code,    amount,   
   paid_flag,    apply_trx_type,  ref_id,   
   group_id,    sub_apply_num,   sub_apply_type,   
   amt_fin_chg,   amt_late_chg,   amt_paid,   
   date_applied,   cust_po_num,    order_ctrl_num,  
   db_action,   payer_cust_code,  nat_cur_code,  
   rate_home,   rate_oper,   true_amount,  
   date_paid,   journal_ctrl_num,  account_code, org_id   
  )   
   
  SELECT DISTINCT  
    
  pyt.trx_ctrl_num,  age.doc_ctrl_num,  age.apply_to_num,   
  age.trx_type,    age.date_doc,   age.date_due,   
  age.date_aging,   age.customer_code,  age.salesperson_code,  
   age.territory_code,   age.price_code,  age.amount,   
   age.paid_flag,    age.apply_trx_type, age.ref_id,   
   age.group_id,    age.sub_apply_num,  age.sub_apply_type,   
   age.amt_fin_chg,  age.amt_late_chg,  age.amt_paid,   
   age.date_applied,   age.cust_po_num,  age.order_ctrl_num,  
   0,    age.payer_cust_code, age.nat_cur_code,  
   age.rate_home,   age.rate_oper,  age.true_amount,  
   age.date_paid,   age.journal_ctrl_num, dbo.IBAcctMask_fn(age.account_code,age.org_id), age.org_id  
  FROM artrxage age, artrx cb, #arinppyt_work pyt, artrx chk  
  WHERE chk.doc_ctrl_num = pyt.doc_ctrl_num  
  AND cb.prompt1_inp = chk.trx_ctrl_num  
  AND age.trx_ctrl_num = cb.trx_ctrl_num  
  AND (cb.doc_ctrl_num like 'CB%' or cb.doc_ctrl_num like 'CA%')  
  AND pyt.trx_type between 2113 and 2121  
   
  AND cb.void_flag = 0  
   
  
  IF( @@error != 0 )  
  BEGIN  
   IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/arcacar.sp' + ', line ' + STR( 480, 5 ) + ' -- EXIT: '  
   RETURN 34563  
  END  
      
   
    
  INSERT  #artrxage_cb   
   (  
  trx_ctrl_num,   doc_ctrl_num,   apply_to_num,   
  trx_type,    date_doc,    date_due,   
  date_aging,    customer_code,   salesperson_code,  
   territory_code,   price_code,    amount,   
   paid_flag,    apply_trx_type,  ref_id,   
   group_id,    sub_apply_num,   sub_apply_type,   
   amt_fin_chg,   amt_late_chg,   amt_paid,   
   date_applied,   cust_po_num,    order_ctrl_num,  
   db_action,   payer_cust_code,  nat_cur_code,  
   rate_home,   rate_oper,   true_amount,  
   date_paid,   journal_ctrl_num,  account_code, org_id   
  )   
  SELECT DISTINCT  
  pyt.trx_ctrl_num,  age.doc_ctrl_num,  age.apply_to_num,   
  age.trx_type,    age.date_doc,   age.date_due,   
  age.date_aging,   age.customer_code,  age.salesperson_code,  
   age.territory_code,   age.price_code,  age.amount,   
   age.paid_flag,    age.apply_trx_type, age.ref_id,   
   age.group_id,    age.sub_apply_num,  age.sub_apply_type,   
   age.amt_fin_chg,  age.amt_late_chg,  age.amt_paid,   
   age.date_applied,   age.cust_po_num,  age.order_ctrl_num,  
   0,    age.payer_cust_code, age.nat_cur_code,  
   age.rate_home,   age.rate_oper,  age.true_amount,  
   age.date_paid,   age.journal_ctrl_num, dbo.IBAcctMask_fn(age.account_code,age.org_id), age.org_id  
  FROM artrxage age, artrx cb, #arinppyt_work pyt, artrx chk  
  WHERE chk.doc_ctrl_num = pyt.doc_ctrl_num  
  AND cb.prompt1_inp = chk.trx_ctrl_num  
  AND age.trx_ctrl_num = cb.trx_ctrl_num  
  AND (cb.doc_ctrl_num like 'CB%' or cb.doc_ctrl_num like 'CA%')  
  AND  pyt.trx_type = 2112  
  AND cb.void_flag = 0  
  AND EXISTS (SELECT * FROM artrxage ir, #arinppdt_work dt  
       WHERE ir.trx_ctrl_num = cb.trx_ctrl_num   
       AND ir.trx_type=2111  
       AND ir.apply_to_num = dt.apply_to_num)  
  
  
  
  IF( @@error != 0 )  
  BEGIN  
   IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/arcacar.sp' + ', line ' + STR( 489, 5 ) + ' -- EXIT: '  
   RETURN 34563  
  END  
  
    
  INSERT  #artrxage_cb   
   (  
  trx_ctrl_num,   doc_ctrl_num,   apply_to_num,   
  trx_type,    date_doc,    date_due,   
  date_aging,    customer_code,   salesperson_code,  
   territory_code,   price_code,    amount,   
   paid_flag,    apply_trx_type,  ref_id,   
   group_id,    sub_apply_num,   sub_apply_type,   
   amt_fin_chg,   amt_late_chg,   amt_paid,   
   date_applied,   cust_po_num,    order_ctrl_num,  
   db_action,   payer_cust_code,  nat_cur_code,  
   rate_home,   rate_oper,   true_amount,  
   date_paid,   journal_ctrl_num,  account_code, org_id   
  )   
  SELECT DISTINCT  
  cb.trx_ctrl_num,  age.doc_ctrl_num,  age.apply_to_num,   
  age.trx_type,    age.date_doc,   age.date_due,   
  age.date_aging,   age.customer_code,  age.salesperson_code,  
   age.territory_code,   age.price_code,  age.amount,   
   age.paid_flag,    age.apply_trx_type, age.ref_id,   
   age.group_id,    age.sub_apply_num,  age.sub_apply_type,   
   age.amt_fin_chg,  age.amt_late_chg,  age.amt_paid,   
   age.date_applied,   age.cust_po_num,  age.order_ctrl_num,  
   0,    age.payer_cust_code, age.nat_cur_code,  
   age.rate_home,   age.rate_oper,  age.true_amount,  
   age.date_paid,   age.journal_ctrl_num, dbo.IBAcctMask_fn(age.account_code,age.org_id), age.org_id  
  FROM artrxage age, #artrxage_cb cb  
  WHERE age.doc_ctrl_num = cb.doc_ctrl_num  
  AND age.doc_ctrl_num = age.apply_to_num  
  AND  cb.trx_type= 2111  
  AND age.trx_type = 2161  
  
  
  IF( @@error != 0 )  
  BEGIN  
   IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/arcacar.sp' + ', line ' + STR( 489, 5 ) + ' -- EXIT: '  
   RETURN 34563  
  END  
   
  
    
  INSERT  #artrxage_work   
   (  
  trx_ctrl_num,   doc_ctrl_num,   apply_to_num,   
  trx_type,    date_doc,    date_due,   
  date_aging,    customer_code,   salesperson_code,  
   territory_code,   price_code,    amount,   
   paid_flag,    apply_trx_type,  ref_id,   
   group_id,    sub_apply_num,   sub_apply_type,   
   amt_fin_chg,   amt_late_chg,   amt_paid,   
   date_applied,   cust_po_num,    order_ctrl_num,  
   db_action,   payer_cust_code,  nat_cur_code,  
   rate_home,   rate_oper,   true_amount,  
   date_paid,   journal_ctrl_num,  account_code, org_id   
  )   
   
  SELECT DISTINCT  
   
  pyt.trx_ctrl_num,  pyt.doc_ctrl_num,   age.doc_ctrl_num,   
  pyt.trx_type,    pyt.date_doc,   age.date_due,   
  age.date_aging,   age.customer_code,   ' ',  
   
   ' ',     ' ',    
  CASE   
     WHEN age.trx_type = 2111 THEN age.amount  
     ELSE -age.amount  
  END,  
   
   1,     age.trx_type,   age.ref_id,   
   0,     age.doc_ctrl_num,   age.trx_type,   
   0,    0,     0,   
   pyt.date_applied,   age.order_ctrl_num,   age.cust_po_num,  
   2,  age.customer_code,  age.nat_cur_code,  
  age.rate_home,  age.rate_oper,  -age.amount,  
  0,    gl.journal_ctrl_num, dbo.IBAcctMask_fn(meth.on_acct_code,pyt.org_id), age.org_id      
  FROM #artrxage_cb age, #arinppyt_work pyt, arpymeth meth, #arcatemp gl  
  WHERE   
  
  age.trx_type in (2031, 2161, 2111 )  
  ANd age.trx_ctrl_num = pyt.trx_ctrl_num  
   
  AND  pyt.trx_type between 2112 and 2121  
   
  AND pyt.batch_code = @batch_ctrl_num  
  AND pyt.payment_code = meth.payment_code  
  AND pyt.trx_ctrl_num = gl.trx_ctrl_num  
  AND age.doc_ctrl_num = age.apply_to_num  
    
    
  IF( @@error != 0 )  
  BEGIN  
   IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/arcacar.sp' + ', line ' + STR( 481, 5 ) + ' -- EXIT: '  
   RETURN 34563  
  END  
  
   
    
  INSERT  #artrxage_work  
   (  
  trx_ctrl_num,   doc_ctrl_num,   apply_to_num,   
  trx_type,    date_doc,    date_due,   
  date_aging,    customer_code,   salesperson_code,  
   territory_code,   price_code,    amount,   
   paid_flag,    apply_trx_type,  ref_id,   
   group_id,    sub_apply_num,   sub_apply_type,   
   amt_fin_chg,   amt_late_chg,   amt_paid,   
   date_applied,   cust_po_num,    order_ctrl_num,  
   db_action,   payer_cust_code,  nat_cur_code,  
   rate_home,   rate_oper,   true_amount,  
   date_paid,   journal_ctrl_num,  account_code, org_id  
  )   
  SELECT   
  age.trx_ctrl_num,  age.doc_ctrl_num,  age.apply_to_num,   
  age.trx_type,    age.date_doc,   age.date_due,   
  age.date_aging,   age.customer_code,  age.salesperson_code,  
   age.territory_code,   age.price_code,  age.amount,   
   age.paid_flag,    age.apply_trx_type, age.ref_id,   
   age.group_id,    age.sub_apply_num,  age.sub_apply_type,   
   age.amt_fin_chg,  age.amt_late_chg,  age.amt_paid,   
   age.date_applied,   age.cust_po_num,  age.order_ctrl_num,  
   2,    age.payer_cust_code, age.nat_cur_code,  
   age.rate_home,   age.rate_oper,  age.true_amount,  
   age.date_paid,   age.journal_ctrl_num, dbo.IBAcctMask_fn(age.account_code,age.org_id), age.org_id  
  FROM artrxage age, artrx cb, #arinppyt_work pyt, artrx chk  
  WHERE chk.doc_ctrl_num = pyt.doc_ctrl_num  
  AND cb.prompt1_inp = chk.trx_ctrl_num  
  AND age.trx_ctrl_num = cb.trx_ctrl_num  
  AND (cb.doc_ctrl_num like 'CB%' or cb.doc_ctrl_num like 'CA%')  
  AND pyt.trx_type between 2113 and 2121  
   
  AND  cb.void_flag = 0  
   
   
  AND NOT EXISTS (SELECT * FROM #artrxage_work WHERE #artrxage_work.trx_ctrl_num = cb.trx_ctrl_num)  
   
  
  IF( @@error != 0 )  
  BEGIN  
   IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/arcacar.sp' + ', line ' + STR( 480, 5 ) + ' -- EXIT: '  
   RETURN 34563  
  END  
   
  INSERT  #artrxage_work  
   (  
  trx_ctrl_num,   doc_ctrl_num,   apply_to_num,   
  trx_type,    date_doc,    date_due,   
  date_aging,    customer_code,   salesperson_code,  
   territory_code,   price_code,    amount,   
   paid_flag,    apply_trx_type,  ref_id,   
   group_id,    sub_apply_num,   sub_apply_type,   
   amt_fin_chg,   amt_late_chg,   amt_paid,   
   date_applied,   cust_po_num,    order_ctrl_num,  
   db_action,   payer_cust_code,  nat_cur_code,  
   rate_home,   rate_oper,   true_amount,  
   date_paid,   journal_ctrl_num,  account_code, org_id  
  )   
  SELECT   
  age.trx_ctrl_num,  age.doc_ctrl_num,  age.apply_to_num,   
  age.trx_type,    age.date_doc,   age.date_due,   
  age.date_aging,   age.customer_code,  age.salesperson_code,  
   age.territory_code,   age.price_code,  age.amount,   
   age.paid_flag,    age.apply_trx_type, age.ref_id,   
   age.group_id,    age.sub_apply_num,  age.sub_apply_type,   
   age.amt_fin_chg,  age.amt_late_chg,  age.amt_paid,   
   age.date_applied,   age.cust_po_num,  age.order_ctrl_num,  
   2,    age.payer_cust_code, age.nat_cur_code,  
   age.rate_home,   age.rate_oper,  age.true_amount,  
   age.date_paid,   age.journal_ctrl_num, dbo.IBAcctMask_fn(age.account_code,age.org_id), age.org_id   
  FROM artrxage age, artrx cb, #arinppyt_work pyt, artrx chk  
  WHERE chk.doc_ctrl_num = pyt.doc_ctrl_num  
  AND cb.prompt1_inp = chk.trx_ctrl_num  
  AND age.trx_ctrl_num = cb.trx_ctrl_num  
  AND (cb.doc_ctrl_num like 'CB%' or cb.doc_ctrl_num like 'CA%')  
  AND pyt.trx_type =2112  
  AND  cb.void_flag = 0  
   
  AND NOT EXISTS (SELECT * FROM #artrxage_work WHERE #artrxage_work.trx_ctrl_num = cb.trx_ctrl_num)  
   
  
  
  IF( @@error != 0 )  
  BEGIN  
   IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/arcacar.sp' + ', line ' + STR( 480, 5 ) + ' -- EXIT: '  
   RETURN 34563  
  END  
   
  
  
  UPDATE #artrxage_work   
  SET paid_flag = 1  
   
  FROM #artrxage_work age, artrx cb, #arinppyt_work pyt, artrx chk, #artrxage_cb acb  
   
  WHERE chk.doc_ctrl_num = pyt.doc_ctrl_num  
  AND cb.prompt1_inp = chk.trx_ctrl_num  
  AND age.trx_ctrl_num = cb.trx_ctrl_num  
  AND cb.doc_ctrl_num like 'CB%'   
   
  AND pyt.trx_type between 2112 and 2121  
  AND cb.doc_ctrl_num = acb.apply_to_num  
   
  
   
    
    
  INSERT #artrx_work (doc_ctrl_num,  trx_ctrl_num,  apply_to_num,  apply_trx_type,  
     order_ctrl_num,  doc_desc,  batch_code,  trx_type,    
     date_entered, date_posted, date_applied,  date_doc,  
     date_shipped,  date_required,  date_due,  date_aging,   
     customer_code,  ship_to_code,  posting_code,  salesperson_code,  
     territory_code,  comment_code,  fob_code,  freight_code,   
     terms_code,  fin_chg_code,  price_code,  recurring_flag,  
     recurring_code,  tax_code,  payment_code,  payment_type,   
     cust_po_num,  non_ar_flag,  gl_acct_code,  gl_trx_id,  
     prompt1_inp,  prompt2_inp,  prompt3_inp,  prompt4_inp,  
     deposit_num,  amt_gross,  amt_freight,  amt_tax,  amt_tax_included,  
     amt_discount,  amt_paid_to_date,  amt_net,  amt_on_acct,    
     amt_cost,  amt_tot_chg,  user_id,  void_flag,  
     paid_flag,  date_paid,  posted_flag,  commission_flag,  
     cash_acct_code,  non_ar_doc_num,  purge_flag, dest_zone_code,  
     nat_cur_code, rate_type_home, rate_type_oper, rate_home,  
     rate_oper, amt_discount_taken, amt_write_off_given, org_id, db_action)    
  SELECT   trx.doc_ctrl_num,  trx.trx_ctrl_num,  trx.apply_to_num,  trx.apply_trx_type,  
     trx.order_ctrl_num,  trx.doc_desc,  trx.batch_code,  trx.trx_type,    
     trx.date_entered, trx.date_posted, trx.date_applied,  trx.date_doc,  
     trx.date_shipped,  trx.date_required,  trx.date_due,  trx.date_aging,   
     trx.customer_code,  trx.ship_to_code,  trx.posting_code,  trx.salesperson_code,  
     trx.territory_code,  trx.comment_code,  trx.fob_code,  trx.freight_code,   
     trx.terms_code,  trx.fin_chg_code,  trx.price_code,  trx.recurring_flag,  
     trx.recurring_code,  trx.tax_code,  trx.payment_code,  trx.payment_type,   
     trx.cust_po_num,  trx.non_ar_flag,  trx.gl_acct_code,  trx.gl_trx_id,  
     trx.prompt1_inp,  trx.prompt2_inp,  trx.prompt3_inp,  trx.prompt4_inp,  
     trx.deposit_num,  trx.amt_gross,  trx.amt_freight,  trx.amt_tax,  trx.amt_tax_included,  
     trx.amt_discount,  trx.amt_paid_to_date,  trx.amt_net,  trx.amt_on_acct,    
     trx.amt_cost,  trx.amt_tot_chg,  trx.user_id,  trx.void_flag,  
     trx.paid_flag,  trx.date_paid,  trx.posted_flag,  trx.commission_flag,  
     trx.cash_acct_code,  trx.non_ar_doc_num,  trx.purge_flag, trx.dest_zone_code,  
     trx.nat_cur_code, trx.rate_type_home, trx.rate_type_oper, trx.rate_home,  
     trx.rate_oper, trx.amt_discount_taken, trx.amt_write_off_given, trx.org_id, 1  
  FROM artrx trx, #arinppyt_work pyt, artrx chk  
  WHERE chk.doc_ctrl_num = pyt.doc_ctrl_num  
  AND trx.prompt1_inp = chk.trx_ctrl_num  
  AND (trx.doc_ctrl_num like 'CB%' or trx.doc_ctrl_num like 'CA%')  
   
  AND pyt.trx_type between 2112 and 2121  
  AND trx.void_flag = 0  
   
   
  AND NOT EXISTS (SELECT * FROM #artrx_work WHERE #artrx_work.trx_ctrl_num = trx.trx_ctrl_num)  
   
  
   
  INSERT #artrx_work (doc_ctrl_num,  trx_ctrl_num,  apply_to_num,  apply_trx_type,  
     order_ctrl_num,  doc_desc,  batch_code,  trx_type,    
     date_entered, date_posted, date_applied,  date_doc,  
     date_shipped,  date_required,  date_due,  date_aging,   
     customer_code,  ship_to_code,  posting_code,  salesperson_code,  
     territory_code,  comment_code,  fob_code,  freight_code,   
     terms_code,  fin_chg_code,  price_code,  recurring_flag,  
     recurring_code,  tax_code,  payment_code,  payment_type,   
     cust_po_num,  non_ar_flag,  gl_acct_code,  gl_trx_id,  
     prompt1_inp,  prompt2_inp,  prompt3_inp,  prompt4_inp,  
     deposit_num,  amt_gross,  amt_freight,  amt_tax,  amt_tax_included,  
     amt_discount,  amt_paid_to_date,  amt_net,  amt_on_acct,    
     amt_cost,  amt_tot_chg,  user_id,  void_flag,  
     paid_flag,  date_paid,  posted_flag,  commission_flag,  
     cash_acct_code,  non_ar_doc_num,  purge_flag, dest_zone_code,  
     nat_cur_code, rate_type_home, rate_type_oper, rate_home,  
     rate_oper, amt_discount_taken, amt_write_off_given, org_id, db_action)    
  SELECT   trx.doc_ctrl_num,  trx.trx_ctrl_num,  trx.apply_to_num,  trx.apply_trx_type,  
     trx.order_ctrl_num,  trx.doc_desc,  trx.batch_code,  trx.trx_type,    
     trx.date_entered, trx.date_posted, trx.date_applied,  trx.date_doc,  
     trx.date_shipped,  trx.date_required,  trx.date_due,  trx.date_aging,   
     trx.customer_code,  trx.ship_to_code,  trx.posting_code,  trx.salesperson_code,  
     trx.territory_code,  trx.comment_code,  trx.fob_code,  trx.freight_code,   
     trx.terms_code,  trx.fin_chg_code,  trx.price_code,  trx.recurring_flag,  
     trx.recurring_code,  trx.tax_code,  trx.payment_code,  trx.payment_type,   
     trx.cust_po_num,  trx.non_ar_flag,  trx.gl_acct_code,  trx.gl_trx_id,  
     trx.prompt1_inp,  trx.prompt2_inp,  trx.prompt3_inp,  trx.prompt4_inp,  
     trx.deposit_num,  trx.amt_gross,  trx.amt_freight,  trx.amt_tax,  trx.amt_tax_included,  
     trx.amt_discount,  trx.amt_paid_to_date,  trx.amt_net,  trx.amt_on_acct,    
     trx.amt_cost,  trx.amt_tot_chg,  trx.user_id,  trx.void_flag,  
     trx.paid_flag,  trx.date_paid,  trx.posted_flag,  trx.commission_flag,  
     trx.cash_acct_code,  trx.non_ar_doc_num,  trx.purge_flag, trx.dest_zone_code,  
     trx.nat_cur_code, trx.rate_type_home, trx.rate_type_oper, trx.rate_home,  
     trx.rate_oper, trx.amt_discount_taken, trx.amt_write_off_given, trx.org_id, 1  
  FROM artrx trx, #arinppyt_work pyt, artrx chk, #artrx_work wrk  
  WHERE chk.doc_ctrl_num = pyt.doc_ctrl_num  
  AND wrk.prompt1_inp = chk.trx_ctrl_num  
  AND trx.doc_ctrl_num = wrk.doc_ctrl_num  
  AND wrk.trx_type = 2032  
  AND trx.doc_ctrl_num like 'CA%'  
  AND trx.trx_type = 2111  
  AND pyt.trx_type between 2112 and 2121  
  AND trx.void_flag = 0  
  AND trx.prompt1_inp = ''  
   
   
  AND NOT EXISTS (SELECT * FROM #artrx_work WHERE #artrx_work.trx_ctrl_num = trx.trx_ctrl_num)  
   
  
  
    
  UPDATE #artrx_work  
  SET amt_paid_to_date = isnull(round(trx.amt_paid_to_date + age.amount,2),0),  
   void_flag = 1,  
   paid_flag = 1  
  FROM #artrxage_cb age, #arinppyt_work pyt, arpymeth meth, #arcatemp gl, #artrx_work trx  
  WHERE   
 age.trx_type = 2031  
  ANd age.trx_ctrl_num = pyt.trx_ctrl_num  
   
  AND pyt.trx_type between 2112 and 2121  
   
  AND pyt.batch_code = @batch_ctrl_num  
  AND pyt.payment_code = meth.payment_code  
  AND pyt.trx_ctrl_num = gl.trx_ctrl_num  
  AND trx.customer_code = age.customer_code  
  AND trx.doc_ctrl_num = age.doc_ctrl_num  
  AND trx.trx_type = 2031  
  
    
  UPDATE #artrx_work  
  SET amt_on_acct = 0,  
   void_flag = 1  
  FROM #artrxage_cb age, #arinppyt_work pyt, arpymeth meth, #arcatemp gl, #artrx_work trx  
  WHERE   
  
  
  
  
 pyt.trx_type between 2112 and 2121  
   
  AND pyt.batch_code = @batch_ctrl_num  
  AND pyt.payment_code = meth.payment_code  
  AND pyt.trx_ctrl_num = gl.trx_ctrl_num  
  AND trx.customer_code = age.customer_code  
  AND trx.doc_ctrl_num = age.doc_ctrl_num  
  AND trx.trx_type in (2111,2032)  
  
      
  INSERT  #artrxage_work   
   (  
  trx_ctrl_num,   doc_ctrl_num,   apply_to_num,   
  trx_type,    date_doc,    date_due,   
  date_aging,    customer_code,   salesperson_code,  
   territory_code,   price_code,    amount,   
   paid_flag,    apply_trx_type,  ref_id,   
   group_id,    sub_apply_num,   sub_apply_type,   
   amt_fin_chg,   amt_late_chg,   amt_paid,   
   date_applied,   cust_po_num,    order_ctrl_num,  
   db_action,   payer_cust_code,  nat_cur_code,  
   rate_home,   rate_oper,   true_amount,  
   date_paid,   journal_ctrl_num,  account_code, org_id  
  )   
   
  SELECT DISTINCT  
   
  pyt.trx_ctrl_num,  pyt.doc_ctrl_num,   inv.apply_to_num,   
  pyt.trx_type,    pyt.date_doc,    inv.date_due,   
  inv.date_aging,   inv.customer_code,   ' ',  
   ' ',     ' ',     -inv.amount,   
   1,     inv.apply_trx_type,   inv.ref_id,   
   0,     inv.sub_apply_num,   inv.sub_apply_type,   
   0,    0,     0,   
   pyt.date_applied,   inv.order_ctrl_num,   inv.cust_po_num,  
   2,  inv.customer_code,  inv.nat_cur_code,  
  inv.rate_home,  inv.rate_oper,  -inv.amount,  
  0,    gl.journal_ctrl_num,  dbo.IBAcctMask_fn(meth.on_acct_code,pyt.org_id) , inv.org_id         
  FROM #artrxage_cb age, #arinppyt_work pyt, arpymeth meth, #arcatemp gl, artrxage inv  
  WHERE   
  
 age.trx_type in (2031, 2111, 2161)  
   
  ANd age.trx_ctrl_num = pyt.trx_ctrl_num  
   
  AND pyt.trx_type between 2112 and 2121  
   
  AND pyt.batch_code = @batch_ctrl_num  
  AND pyt.payment_code = meth.payment_code  
  AND pyt.trx_ctrl_num = gl.trx_ctrl_num  
  AND age.doc_ctrl_num = inv.doc_ctrl_num  
  AND inv.trx_type = 2111  
   
  AND  inv.apply_trx_type = 2031  
   
    
  IF( @@error != 0 )  
  BEGIN  
   IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/arcacar.sp' + ', line ' + STR( 482, 5 ) + ' -- EXIT: '  
   RETURN 34563  
  END  
  
    
  UPDATE #artrx_work  
  SET amt_paid_to_date = isnull(round(trx.amt_paid_to_date + inv.amount,2),0)  
  FROM #artrxage_cb age, #arinppyt_work pyt, arpymeth meth, #arcatemp gl, artrxage inv, #artrx_work trx   
  WHERE   
  
 age.trx_type in (2031, 2111)  
   
  ANd age.trx_ctrl_num = pyt.trx_ctrl_num  
   
  AND  pyt.trx_type between 2112 and 2121  
   
  AND pyt.batch_code = @batch_ctrl_num  
  AND pyt.payment_code = meth.payment_code  
  AND pyt.trx_ctrl_num = gl.trx_ctrl_num  
  AND age.doc_ctrl_num = inv.doc_ctrl_num  
  AND inv.trx_type = 2111  
  AND trx.doc_ctrl_num = inv.apply_to_num  
  AND trx.trx_type = 2031   
  AND trx.customer_code = age.customer_code  
  
  DROP TABLE #artrxage_cb  
  
  
  
   
  
  
   
  INSERT  #artrxage_work   
   (  
  trx_ctrl_num,   doc_ctrl_num,   apply_to_num,   
  trx_type,    date_doc,    date_due,   
  date_aging,    customer_code,   salesperson_code,  
   territory_code,   price_code,    amount,   
   paid_flag,    apply_trx_type,  ref_id,   
   group_id,    sub_apply_num,   sub_apply_type,   
   amt_fin_chg,   amt_late_chg,   amt_paid,   
   date_applied,   cust_po_num,    order_ctrl_num,  
   db_action,   payer_cust_code,  nat_cur_code,  
   rate_home,   rate_oper,   true_amount,  
   date_paid,   journal_ctrl_num,  account_code, org_id  
  )   
   
  SELECT DISTINCT  
    
  pyt.trx_ctrl_num,  pyt.doc_ctrl_num,   age.apply_to_num,   
  pyt.trx_type,    pyt.date_doc,    age.date_due,   
  age.date_aging,   age.customer_code,   ' ',  
   ' ',     ' ',     -age.amount,   
   1,     age.apply_trx_type,   age.ref_id,   
   0,     age.sub_apply_num,   age.sub_apply_type,   
   0,    0,     0,   
   pyt.date_applied,   age.order_ctrl_num,   age.cust_po_num,  
   2,  age.customer_code,  age.nat_cur_code,  
  age.rate_home,  age.rate_oper,  -age.amount,  
  0,    gl.journal_ctrl_num,  dbo.IBAcctMask_fn(meth.on_acct_code,pyt.org_id) , age.org_id         
  FROM artrxage age, #arinppyt_work pyt, arpymeth meth, #arcatemp gl  
  WHERE age.trx_type = 2111  
  AND age.doc_ctrl_num = pyt.doc_ctrl_num  
  AND age.apply_trx_type = 2161  
  AND pyt.trx_type between 2113 and 2121   
  AND pyt.batch_code = @batch_ctrl_num  
  AND pyt.payment_code = meth.payment_code  
  AND pyt.trx_ctrl_num = gl.trx_ctrl_num  
    
  
  INSERT #artrx_work (doc_ctrl_num,  trx_ctrl_num,  apply_to_num,  apply_trx_type,  
     order_ctrl_num,  doc_desc,  batch_code,  trx_type,    
     date_entered, date_posted, date_applied,  date_doc,  
     date_shipped,  date_required,  date_due,  date_aging,   
     customer_code,  ship_to_code,  posting_code,  salesperson_code,  
     territory_code,  comment_code,  fob_code,  freight_code,   
     terms_code,  fin_chg_code,  price_code,  recurring_flag,  
     recurring_code,  tax_code,  payment_code,  payment_type,   
     cust_po_num,  non_ar_flag,  gl_acct_code,  gl_trx_id,  
     prompt1_inp,  prompt2_inp,  prompt3_inp,  prompt4_inp,  
     deposit_num,  amt_gross,  amt_freight,  amt_tax,  amt_tax_included,  
     amt_discount,  amt_paid_to_date,  amt_net,  amt_on_acct,    
     amt_cost,  amt_tot_chg,  user_id,  void_flag,  
     paid_flag,  date_paid,  posted_flag,  commission_flag,  
     cash_acct_code,  non_ar_doc_num,  purge_flag, dest_zone_code,  
     nat_cur_code, rate_type_home, rate_type_oper, rate_home,  
     rate_oper, amt_discount_taken, amt_write_off_given, org_id, db_action)    
  SELECT   trx.doc_ctrl_num,  trx.trx_ctrl_num,  trx.apply_to_num,  trx.apply_trx_type,  
     trx.order_ctrl_num,  trx.doc_desc,  trx.batch_code,  trx.trx_type,    
     trx.date_entered, trx.date_posted, trx.date_applied,  trx.date_doc,  
     trx.date_shipped,  trx.date_required,  trx.date_due,  trx.date_aging,   
     trx.customer_code,  trx.ship_to_code,  trx.posting_code,  trx.salesperson_code,  
     trx.territory_code,  trx.comment_code,  trx.fob_code,  trx.freight_code,   
     trx.terms_code,  trx.fin_chg_code,  trx.price_code,  trx.recurring_flag,  
     trx.recurring_code,  trx.tax_code,  trx.payment_code,  trx.payment_type,   
     trx.cust_po_num,  trx.non_ar_flag,  trx.gl_acct_code,  trx.gl_trx_id,  
     trx.prompt1_inp,  trx.prompt2_inp,  trx.prompt3_inp,  trx.prompt4_inp,  
     trx.deposit_num,  trx.amt_gross,  trx.amt_freight,  trx.amt_tax,  trx.amt_tax_included,  
     trx.amt_discount,  trx.amt_paid_to_date,  trx.amt_net,  round(trx.amt_on_acct + age.amount,2),    
     trx.amt_cost,  trx.amt_tot_chg,  trx.user_id,  trx.void_flag,  
     0,  trx.date_paid,  trx.posted_flag,  trx.commission_flag,  
     trx.cash_acct_code,  trx.non_ar_doc_num,  trx.purge_flag, trx.dest_zone_code,  
     trx.nat_cur_code, trx.rate_type_home, trx.rate_type_oper, trx.rate_home,  
     trx.rate_oper, trx.amt_discount_taken, trx.amt_write_off_given, trx.org_id, 1  
  FROM artrxage age, #arinppyt_work pyt, artrx trx  
  WHERE age.trx_type = 2111  
  AND age.doc_ctrl_num = pyt.doc_ctrl_num  
  AND age.apply_trx_type = 2161  
  AND  pyt.trx_type between 2113 and 2121  
  AND pyt.batch_code = @batch_ctrl_num  
  AND trx.doc_ctrl_num = age.apply_to_num  
  AND trx.trx_type = 2111  
  AND  trx.payment_type = 3   
  AND trx.customer_code = age.customer_code   
  
   
  
  
   
 IF EXISTS (SELECT count(*)  
  FROM #artrxage_work   
  WHERE trx_type in (2112, 2113)  
  GROUP BY trx_ctrl_num, trx_type, ref_id, doc_ctrl_num, apply_to_num, apply_trx_type, sub_apply_num, sub_apply_type, customer_code, payer_cust_code, amount, db_action, true_amount  
  HAVING count(*) >1 )  
 BEGIN  
    
  CREATE TABLE #artrxage_work_hold  
  (   
   trx_ctrl_num  varchar(16),  
   trx_type  smallint,  
   ref_id int,  
   doc_ctrl_num  varchar(16),  
   order_ctrl_num varchar(16),  
   cust_po_num  varchar(20),  
   apply_to_num  varchar(16),  
   apply_trx_type smallint,  
   sub_apply_num  varchar(16),  
   sub_apply_type smallint,  
   date_doc  int,  
   date_due  int,  
   date_applied  int,  
   date_aging  int,   
   customer_code  varchar(8),  
   payer_cust_code varchar(8),  
   salesperson_code varchar(8),  
   territory_code varchar(8),  
   price_code  varchar(8),  
   amount   float,  
   paid_flag  smallint,  
   group_id  int,  
   amt_fin_chg  float,  
   amt_late_chg  float,  
   amt_paid  float,  
   db_action  smallint,  
   rate_home  float,  
   rate_oper  float,  
   nat_cur_code  varchar(8),  
   true_amount  float,  
   date_paid  int,  
   journal_ctrl_num varchar(16),  
   account_code  varchar(32),
	org_id varchar(30) -- v1.0 Org_id column missing 
  )  
    
  INSERT #artrxage_work_hold   
  SELECT  trx_ctrl_num,  
   trx_type,  
   ref_id,  
   doc_ctrl_num,  
   max(order_ctrl_num),  
   max(cust_po_num),  
   apply_to_num,  
   apply_trx_type,  
   sub_apply_num,  
   sub_apply_type,  
   max(date_doc),  
   max(date_due),  
   max(date_applied),  
   max(date_aging),   
   customer_code,  
   payer_cust_code,  
   max(salesperson_code),  
   max(territory_code),  
   max(price_code),  
   amount,  
   max(paid_flag),  
   max(group_id),  
   max(amt_fin_chg),  
   max(amt_late_chg),  
   max(amt_paid),  
   db_action,  
   max(rate_home),  
   max(rate_oper),  
   max(nat_cur_code),  
   true_amount,  
   max(date_paid),  
   max(journal_ctrl_num),  
   max(account_code),
	'CVO' -- v1.0 Org_id column missing    
  FROM #artrxage_work  
  GROUP BY trx_ctrl_num, trx_type, ref_id, doc_ctrl_num, apply_to_num, apply_trx_type, sub_apply_num, sub_apply_type, customer_code, payer_cust_code, amount, db_action, true_amount  
  
  TRUNCATE TABLE #artrxage_work  
  
  INSERT #artrxage_work SELECT DISTINCT * FROM #artrxage_work_hold  
  
  DROP TABLE #artrxage_work_hold  
 END  
  
  
END  
  
 IF (@debug_level > 0)  
 BEGIN  
 SELECT 'Dumping artrxage records after creating aging records'  
  
 END  
  
 IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, 'tmp/arcacar.sp', 551, 'Leaving ARCMCreateAgingRecs_SP', @PERF_time_last OUTPUT  
 RETURN 0   
  
END  
  
GO
GRANT EXECUTE ON  [dbo].[ARCACreateAgingRecs_SP] TO [public]
GO
