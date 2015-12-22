SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO





























  



					  

























































 















































































































































































































































































































































































































































































































































































































































































































CREATE PROC [dbo].[ARCRCreateAgingRecs_SP]    @batch_ctrl_num varchar(16),
            @debug_level    smallint,
            @perf_level   smallint

AS








DECLARE
        @PERF_time_last     datetime

SELECT  @PERF_time_last = GETDATE()

















									







DECLARE
  @result   int,
  @precision    float,
  @payer_cust_code  varchar(8),
  @rate_home    float,
  @rate_oper    float,
  @date_aging   int,
  @currency_code  varchar(8)


IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "arcrcar.cpp", 80, "Entering ARCRCreateAgingRecs", @PERF_time_last OUTPUT

BEGIN
  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrcar.cpp" + ", line " + STR( 83, 5 ) + " -- ENTRY: "
  
  IF ( @debug_level > 0 )
  BEGIN
    SELECT "dumping #artrxpdt_work..."
    SELECT  "doc_ctrl_num = " + doc_ctrl_num +
      "apply_to_num = " + apply_to_num +
      "amt_applied = " + STR(amt_applied, 10, 2) +
      "inv_amt_applied = " + STR(inv_amt_applied, 10, 2 )
    FROM  #artrxpdt_work
    
    SELECT "dumping #arinppyt_work..."
    SELECT  "trx_ctrl_num = " + trx_ctrl_num +
      "rate_home = " + STR(rate_home, 10, 2)+
      "rate_oper = " + STR(rate_oper, 10, 2)
    FROM  #arinppyt_work
  END

  



  IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrcar.cpp" + ", line " + STR( 105, 5 ) + " -- MSG: " + "Insert records with inv_amt_applied > 0"
  INSERT #artrxage_work 
    (
  trx_ctrl_num,     doc_ctrl_num,     apply_to_num, 
  trx_type,       date_doc,       date_due, 
  date_aging,       customer_code,    salesperson_code,
  territory_code,     price_code,       amount, 
  paid_flag,      apply_trx_type,   ref_id, 
  group_id,       sub_apply_num,    sub_apply_type, 
  amt_fin_chg,      amt_late_chg,     amt_paid, 
  date_applied,     cust_po_num,      order_ctrl_num,
  payer_cust_code,    rate_home,      rate_oper,
  nat_cur_code,     true_amount,      db_action,
  date_paid,      journal_ctrl_num,   account_code,
  org_id  )    
  SELECT
  pdt.trx_ctrl_num,   pdt.doc_ctrl_num,     pdt.apply_to_num,
  pdt.trx_type,       pyt.date_doc,     0, 
  pdt.date_aging,     pdt.customer_code,          ' ',
  ' ',        ' ',        -pdt.inv_amt_applied, 
  0,        pdt.apply_trx_type,   pdt.sequence_id, 
  0,        pdt.sub_apply_num,    pdt.sub_apply_type, 
  0.0,        0.0,        0.0, 
  pyt.date_applied,     ' ',        ' ',
  pdt.payer_cust_code,    inv.rate_home,    inv.rate_oper,  
  pdt.inv_cur_code,   -pdt.amt_applied,   20,
  0,        ' ',        ' ',
  inv.org_id                                              
  FROM  #artrxpdt_work pdt, #arinppyt_work  pyt, #artrx_work inv
  WHERE pyt.batch_code = @batch_ctrl_num
  AND pdt.trx_ctrl_num = pyt.trx_ctrl_num
  AND pdt.trx_type = pyt.trx_type
  AND pdt.inv_amt_applied > 0.0
  AND pdt.sub_apply_num = inv.doc_ctrl_num
  AND pdt.sub_apply_type = inv.trx_type

  IF( @@error != 0 )
  BEGIN
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrcar.cpp" + ", line " + STR( 143, 5 ) + " -- EXIT: "
    RETURN 34563
  END
  
  IF (@debug_level > 0)
  BEGIN
    SELECT "Dumping artrxage records after creating aging records"
    SELECT substring("doc_ctrl_num = " + doc_ctrl_num +
      " trx_type = " + STR(trx_type,6) +
      " customer_code = " + customer_code +
      " territory_code = " + territory_code +
      " amount = " + STR(amount,10,2) +
      " true_amount = " + STR(true_amount,10,2) +
      " paid_flag = " + STR(paid_flag,2) +
      " amt_paid = " + STR(amt_paid, 10,2) +
      " rate_home = " + STR(rate_home,10,2) +
      " rate_oper = " + STR(rate_oper,10,2) +
      " nat_cur_code = " + nat_cur_code +
      " ref_id = " + STR(ref_id, 3) +
      " db_action = " + STR(db_action, 2),1, 255)	
    FROM #artrxage_work
  END
  
        


  IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrcar.cpp" + ", line " + STR( 169, 5 ) + " -- MSG: " + "Insert records with inv_amt_disc_taken > 0"
  INSERT #artrxage_work 
    (
  trx_ctrl_num,     doc_ctrl_num,     apply_to_num, 
  trx_type,       date_doc,       date_due, 
  date_aging,       customer_code,    salesperson_code,
  territory_code,     price_code,       amount, 
  paid_flag,      apply_trx_type,   ref_id, 
  group_id,       sub_apply_num,    sub_apply_type, 
  amt_fin_chg,      amt_late_chg,     amt_paid, 
  date_applied,     cust_po_num,      order_ctrl_num,
  payer_cust_code,    
  rate_home,      
  rate_oper,
  nat_cur_code,     true_amount,      db_action,
  date_paid,      journal_ctrl_num,   account_code,
  org_id 
  )      
  SELECT 
  pdt.trx_ctrl_num,   pdt.doc_ctrl_num,     pdt.apply_to_num, 
  2131,     pyt.date_doc,     0, 
  pdt.date_aging,     pdt.customer_code,    ' ',
  ' ',        ' ',        -pdt.inv_amt_disc_taken, 
  0,        pdt.apply_trx_type,   pdt.sequence_id, 
  0,        pdt.sub_apply_num,    pdt.sub_apply_type, 
  0.0,        0.0,        0.0, 
  pyt.date_applied,     ' ',        ' ',
        pdt.payer_cust_code,    inv.rate_home,    inv.rate_oper,
        pdt.inv_cur_code,   -pdt.inv_amt_disc_taken,  20,
  0,        ' ',        ' ',
  inv.org_id							
  FROM  #artrxpdt_work pdt, #arinppyt_work  pyt, #artrx_work inv
  WHERE pyt.batch_code = @batch_ctrl_num
  AND pdt.trx_ctrl_num = pyt.trx_ctrl_num
  AND pdt.trx_type = pyt.trx_type
  AND pdt.inv_amt_disc_taken > 0.0
  AND pdt.sub_apply_num = inv.doc_ctrl_num
  AND pdt.sub_apply_type = inv.trx_type
  
  IF( @@error != 0 )
  BEGIN
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrcar.cpp" + ", line " + STR( 210, 5 ) + " -- EXIT: "
    RETURN 34563
  END

  


  IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrcar.cpp" + ", line " + STR( 217, 5 ) + " -- MSG: " + "Insert records with inv_amt_wr_off > 0"
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
  payer_cust_code,    
  rate_home,      
  rate_oper,
  nat_cur_code,     true_amount,      db_action,
  date_paid,      journal_ctrl_num,   account_code,
  org_id 
  )      
  SELECT 
  pdt.trx_ctrl_num,   pdt.doc_ctrl_num,     pdt.apply_to_num, 
  2141,      pyt.date_doc,     0, 
  pdt.date_aging,     pdt.customer_code,    ' ',
  ' ',        ' ',        -pdt.inv_amt_wr_off, 
  0,        pdt.apply_trx_type,   pdt.sequence_id, 
  0,        pdt.sub_apply_num,    pdt.sub_apply_type, 
  0.0,        0.0,        0.0, 
  pyt.date_applied,     ' ',        ' ',
  pdt.payer_cust_code,    inv.rate_home,    inv.rate_oper,  
  pdt.inv_cur_code,   -pdt.inv_amt_wr_off,    20,
  0,        ' ',        ' ',
  inv.org_id							
  FROM  #artrxpdt_work pdt, #arinppyt_work  pyt, #artrx_work inv		
  WHERE pyt.batch_code = @batch_ctrl_num
  AND pdt.trx_ctrl_num = pyt.trx_ctrl_num
  AND pdt.trx_type = pyt.trx_type
  AND pdt.inv_amt_wr_off <> 0.0
  AND pdt.sub_apply_num = inv.doc_ctrl_num
  AND pdt.sub_apply_type = inv.trx_type
  
  IF( @@error != 0 )
  BEGIN
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrcar.cpp" + ", line " + STR( 258, 5 ) + " -- EXIT: "
    RETURN 34563
  END

  












  



  SELECT  age.territory_code,
    age.price_code,
    age.salesperson_code,
    age.order_ctrl_num,
    age.cust_po_num,
    age.date_due,
    age.doc_ctrl_num,
    age.date_aging,
    dbo.IBAcctMask_fn(acct.ar_acct_code,trx.org_id)as ar_acct_code
  INTO  #artrxage_inv
  FROM  #artrxage_work age, #artrx_work trx, araccts acct
  WHERE age.trx_type in (2021, 2031, 2071)
  AND age.doc_ctrl_num = trx.doc_ctrl_num
  AND age.trx_type = trx.trx_type
  AND trx.posting_code = acct.posting_code
  
  IF( @@error != 0 )
  BEGIN
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrcar.cpp" + ", line " + STR( 297, 5 ) + " -- EXIT: "
    RETURN 34563
  END

  UPDATE #artrxage_work
  SET territory_code = age2.territory_code,
    price_code = age2.price_code,
    salesperson_code = age2.salesperson_code,
    order_ctrl_num = age2.order_ctrl_num,
    cust_po_num = age2.cust_po_num,
    date_due = age2.date_due,
    account_code = age2.ar_acct_code
  FROM  #artrxage_inv age2
  WHERE #artrxage_work.sub_apply_num = age2.doc_ctrl_num
  AND #artrxage_work.date_aging = age2.date_aging
  AND #artrxage_work.db_action = 20 

  IF( @@error != 0 )
  BEGIN
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrcar.cpp" + ", line " + STR( 316, 5 ) + " -- EXIT: "
    RETURN 34563
  END

  


  IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrcar.cpp" + ", line " + STR( 323, 5 ) + " -- MSG: " + "Insert records with amt_on_acct"
  INSERT #artrxage_work 
    (
  trx_ctrl_num,     doc_ctrl_num,     apply_to_num, 
  trx_type,       date_doc,       date_due, 
  date_aging,       customer_code,    salesperson_code,
  territory_code,     price_code,       amount, 
  paid_flag,      apply_trx_type,   ref_id, 
  group_id,       sub_apply_num,    sub_apply_type, 
  amt_fin_chg,      amt_late_chg,     amt_paid, 
  date_applied,     cust_po_num,      order_ctrl_num,
  payer_cust_code,    rate_oper,      rate_home,
  nat_cur_code,     true_amount,      db_action,
  date_paid,      journal_ctrl_num,   account_code,
  org_id      
  )      
  SELECT 
  trx_ctrl_num,     doc_ctrl_num,     doc_ctrl_num, 
  2111,          date_doc,       0, 
  date_applied,     pyt.customer_code,    cust.salesperson_code,
  cust.territory_code,       cust.price_code,        -amt_payment,
  0,        2111,    0, 
  0,        doc_ctrl_num,     2111, 
  0.0,        0.0,        0.0, 
  date_applied,     " ",        " ",
  pyt.customer_code,    rate_oper,      rate_home,
  pyt.nat_cur_code,     -amt_payment,     20,
  SIGN(amt_payment - amt_on_acct) * date_applied,
          ' ',        dbo.IBAcctMask_fn(meth.on_acct_code,pyt.org_id),
  pyt.org_id 
  FROM  #arinppyt_work pyt, arpymeth meth, arcust cust
  WHERE batch_code = @batch_ctrl_num
  AND payment_type = 1    
  AND amt_on_acct > 0.0
  AND pyt.payment_code = meth.payment_code
  AND pyt.customer_code = cust.customer_code  
  IF( @@error != 0 )
  BEGIN
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrcar.cpp" + ", line " + STR( 361, 5 ) + " -- EXIT: "
    RETURN 34563
  END

  





  SELECT pdt.trx_ctrl_num, pdt.payer_cust_code, pdt.doc_ctrl_num, 
    SUM(pdt.amt_applied) offset_amount
  INTO  #age_offset
  FROM  #artrxpdt_work pdt, #arinppyt_work  pyt
  WHERE pdt.trx_ctrl_num = pyt.trx_ctrl_num
  AND pdt.trx_type = pyt.trx_type
  AND pdt.amt_applied > 0.0
  AND pyt.batch_code = @batch_ctrl_num
  GROUP BY pdt.trx_ctrl_num, pdt.payer_cust_code, pdt.doc_ctrl_num

  IF( @@error != 0 )
  BEGIN
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrcar.cpp" + ", line " + STR( 383, 5 ) + " -- EXIT: "
    RETURN 34563
  END



	IF ( EXISTS(SELECT 1 from arco with (nolock) where chargeback_flag = 1 ))
	BEGIN
		/* Begin mod: CB0001 - Deduct chargeback total from amount applied */
		UPDATE	#age_offset
		SET	offset_amount = offset.offset_amount - cb.total_chargebacks
		FROM	#age_offset offset, #arinppyt_work pyt, arcbtot cb
		WHERE	offset.trx_ctrl_num = pyt.trx_ctrl_num
		AND	pyt.trx_ctrl_num = cb.trx_ctrl_num
	
		/* Insert an entry for checks with no payments that have chargebacks and on account - The Emerald Group */
		INSERT #age_offset 	
		SELECT	cb.trx_ctrl_num, pyt.customer_code, pyt.doc_ctrl_num, 
					-total_chargebacks 
		FROM	arcbtot cb, #arinppyt_work pyt
		WHERE	cb.trx_ctrl_num = pyt.trx_ctrl_num
		/* Begin mod: CB121102 
		AND	cb.total_chargebacks > 0.0
		*/
		AND	cb.total_chargebacks <> 0.0
		/* End mod: CB121102 */
		AND	cb.trx_ctrl_num NOT IN 
		(SELECT	trx_ctrl_num 
		FROM	#age_offset)
		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcrcar.sp" + ", line " + STR( 370, 5 ) + " -- EXIT: "
			RETURN 34563
		END
		/* End mod: CB0001 */
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
  payer_cust_code,    rate_home,      rate_oper,
  nat_cur_code,     true_amount,      db_action,
  date_paid,      journal_ctrl_num,   account_code,
  org_id
  )      
  SELECT 
  pyt.trx_ctrl_num,   pyt.doc_ctrl_num,     pyt.doc_ctrl_num,
  age.trx_type,       pyt.date_doc,     0, 
  age.date_aging,     pyt.customer_code,          age.salesperson_code,
  age.territory_code,        age.price_code,        offset.offset_amount,
  0,        age.trx_type,     -1, 
  0,        pyt.doc_ctrl_num,     age.trx_type, 
  0.0,        0.0,        0.0, 
  pyt.date_applied,     ' ',        ' ',
  offset.payer_cust_code, pyt.rate_home,    pyt.rate_oper,  
  pyt.nat_cur_code,   offset.offset_amount, 20,
  0,        ' ',       dbo.IBAcctMask_fn(meth.on_acct_code,pyt.org_id),
  age.org_id									
  FROM  #arinppyt_work pyt, #age_offset offset, #artrxage_work age, arpymeth meth
  WHERE pyt.batch_code = @batch_ctrl_num
  AND pyt.trx_ctrl_num = offset.trx_ctrl_num
  AND pyt.doc_ctrl_num = offset.doc_ctrl_num
  AND pyt.customer_code = age.payer_cust_code
  AND pyt.doc_ctrl_num = age.doc_ctrl_num
  AND age.trx_type = 2111
  AND age.ref_id = 0
  AND pyt.payment_code = meth.payment_code

  IF( @@error != 0 )
  BEGIN
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrcar.cpp" + ", line " + STR( 442, 5 ) + " -- EXIT: "
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
  payer_cust_code,    rate_home,      rate_oper,
  nat_cur_code,     true_amount,      db_action,
  date_paid,      journal_ctrl_num,   account_code,
  org_id
  )      
  SELECT 
  pyt.trx_ctrl_num,   pyt.doc_ctrl_num,     pyt.doc_ctrl_num,
  2161,    pyt.date_doc,     0, 
  trx.date_aging,     pyt.customer_code,          trx.salesperson_code,
  trx.territory_code,        trx.price_code,        offset.offset_amount,
  0,        2161,    -1, 
  0,        pyt.doc_ctrl_num,     2161, 
  0.0,        0.0,        0.0, 
  pyt.date_applied,     ' ',        ' ',
  offset.payer_cust_code, pyt.rate_home,    pyt.rate_oper,  
  pyt.nat_cur_code,   offset.offset_amount, 20,
  0,        ' ',        dbo.IBAcctMask_fn(acct.cm_on_acct_code,pyt.org_id),
  trx.org_id								
  FROM  #arinppyt_work pyt, #age_offset offset, #artrx_work trx, araccts acct
  WHERE pyt.batch_code = @batch_ctrl_num
  AND pyt.trx_ctrl_num = offset.trx_ctrl_num
  AND pyt.doc_ctrl_num = offset.doc_ctrl_num
  AND pyt.customer_code = trx.customer_code
  AND pyt.doc_ctrl_num = trx.doc_ctrl_num
  AND trx.trx_type = 2111 
  AND trx.payment_type = 3
  AND trx.posting_code = acct.posting_code

  IF( @@error != 0 )
  BEGIN
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrcar.cpp" + ", line " + STR( 486, 5 ) + " -- EXIT: "
    RETURN 34563
  END

  IF (@debug_level > 0)
  BEGIN
    SELECT "Dumping artrxage records after creating aging records"
    SELECT  substring("doc_ctrl_num=" + doc_ctrl_num +
      " trx_type=" + STR(trx_type,6) +
      " customer_code=" + customer_code +
      " territory_code=" + territory_code +
      " amount=" + STR(amount,10,2) +
      " true_amount=" + STR(true_amount,10,2) +
      " paid_flag=" + STR(paid_flag,2) +
      " amt_paid=" + STR(amt_paid, 10,2) +
      " rate_home=" + STR(rate_home,10,2) +
      " rate_oper=" + STR(rate_oper,10,2) +
      " nat_cur_code=" + nat_cur_code +
      " ref_id=" + STR(ref_id, 3) +
      " db_action=" + STR(db_action, 2),1, 255)
    FROM #artrxage_work
  END

  DROP TABLE #age_offset
  
  






  UPDATE  #artrxage_work
  SET trx_type = 2032
  FROM  #arinppyt_work pyt
  WHERE pyt.batch_code = @batch_ctrl_num
  AND pyt.payment_type IN (3, 4)
  AND #artrxage_work.trx_ctrl_num = pyt.trx_ctrl_num
  AND #artrxage_work.trx_type = pyt.trx_type
  AND #artrxage_work.trx_type = 2111
  
  IF( @@error != 0 )
  BEGIN
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrcar.cpp" + ", line " + STR( 529, 5 ) + " -- EXIT: "
    RETURN 34563
  END
  
  



  UPDATE  #artrxage_work
  SET trx_type = 2161,
    apply_trx_type = 2161,
    sub_apply_type = 2161
  FROM  #arinppyt_work pyt
  WHERE pyt.batch_code = @batch_ctrl_num
  AND pyt.payment_type = 4
  AND #artrxage_work.trx_ctrl_num = pyt.trx_ctrl_num
  AND #artrxage_work.trx_type = pyt.trx_type
  AND #artrxage_work.trx_type = 2111
  AND #artrxage_work.ref_id = -1
  
  IF( @@error != 0 )
  BEGIN
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrcar.cpp" + ", line " + STR( 551, 5 ) + " -- EXIT: "
    RETURN 34563
  END
  
  IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "arcrcar.cpp", 555, "Leaving ARCMCreateAgingRecs_SP", @PERF_time_last OUTPUT
      RETURN 0 

END

GO
GRANT EXECUTE ON  [dbo].[ARCRCreateAgingRecs_SP] TO [public]
GO
