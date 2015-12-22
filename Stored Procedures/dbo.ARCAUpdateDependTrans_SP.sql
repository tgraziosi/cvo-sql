SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




CREATE PROC [dbo].[ARCAUpdateDependTrans_SP]  @batch_ctrl_num varchar(16),
            @process_ctrl_num varchar(16),
            @debug_level    smallint,
            @perf_level   smallint

AS








DECLARE
        @PERF_time_last     datetime

SELECT  @PERF_time_last = GETDATE()

















									







DECLARE
  @result   int,
  @date_applied   int



IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, 'arcaudt.cpp', 85, 'Entering ARCAUpdateDependTrans', @PERF_time_last OUTPUT

BEGIN
  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcaudt.cpp' + ', line ' + STR( 88, 5 ) + ' -- ENTRY: '
  
  








  






  



















  









    
  IF EXISTS(SELECT *    FROM #arinppyt_work
        WHERE void_type = 3
        AND batch_code = @batch_ctrl_num
            )
  BEGIN
    CREATE TABLE #on_acct_rec
    (
      doc_ctrl_num  varchar(16),
      trx_type  smallint,
      customer_code varchar(8)
    )

    CREATE TABLE #not_oa_rec
    (
      doc_ctrl_num  varchar(16),
      trx_type  smallint,
      customer_code varchar(8),
      missing_flag  smallint
    )
    
    




    INSERT  #on_acct_rec
    SELECT  DISTINCT age.doc_ctrl_num, age.trx_type, age.customer_code
    FROM  #artrxage_work age, #arinppdt_work pdt
    WHERE age.doc_ctrl_num = pdt.doc_ctrl_num
    AND age.customer_code = pdt.payer_cust_code
    AND pdt.trx_type = 2112
    AND age.ref_id = 0
    AND age.trx_type in (2111, 2161)
    AND pdt.temp_flag = 1
    IF( @@error != 0 )
    BEGIN
      IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcaudt.cpp' + ', line ' + STR( 173, 5 ) + ' -- EXIT: '
      RETURN 34563
    END

    
    IF (@debug_level > 0)
    BEGIN
      SELECT 'Dumping #on_acct_rec'
      SELECT  'doc_ctrl_num = ' + doc_ctrl_num +
        ' trx_type = ' + STR(trx_type,6) +
        ' customer_code = ' + customer_code 
      FROM #on_acct_rec
    END

    









    INSERT  #not_oa_rec
    SELECT  age.doc_ctrl_num, age.trx_type, age.payer_cust_code,1 
    FROM  #artrxage_work age, #arinppdt_work ipdt
    WHERE age.doc_ctrl_num = ipdt.doc_ctrl_num
    AND age.payer_cust_code = ipdt.payer_cust_code
    AND age.trx_type = 2111
    AND ipdt.trx_type = 2112
    AND age.ref_id > 0
    AND ipdt.temp_flag = 1
    GROUP BY age.doc_ctrl_num, age.trx_type, age.payer_cust_code
    IF( @@error != 0 )
    BEGIN
      IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcaudt.cpp' + ', line ' + STR( 209, 5 ) + ' -- EXIT: '
      RETURN 34563
    END

    




    UPDATE #not_oa_rec
    SET missing_flag = 0
    FROM  #on_acct_rec a, #not_oa_rec b
    WHERE a.doc_ctrl_num = b.doc_ctrl_num
    AND a.customer_code = b.customer_code
    IF( @@error != 0 )
    BEGIN
      IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcaudt.cpp' + ', line ' + STR( 225, 5 ) + ' -- EXIT: '
      RETURN 34563
    END
    
    IF (@debug_level > 0)
    BEGIN
      SELECT 'Dumping #on_acct_rec'
      SELECT  'doc_ctrl_num = ' + doc_ctrl_num +
        'trx_type = ' + STR(trx_type,6) +
        'customer_code = ' + customer_code +
        'missing_flag = ' + STR(missing_flag, 2 ) 
      FROM #not_oa_rec
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
    db_action,      nat_cur_code,     rate_home,
    rate_oper,      payer_cust_code,    true_amount,
    date_paid,      journal_ctrl_num,   account_code , org_id					
    )      
    SELECT  
    trx.trx_ctrl_num,   rec.doc_ctrl_num,   rec.doc_ctrl_num,
    2111,    trx.date_doc,     0,
    trx.date_doc,     pyt.customer_code,    cust.salesperson_code,
    cust.territory_code,        cust.price_code,        -trx.amt_net,
    0,        2111,    0,
    0,        rec.doc_ctrl_num,       2111,
    0,        0,        0,
    trx.date_applied,   ' ',        ' ',
    2,    trx.nat_cur_code,   trx.rate_home,
    trx.rate_oper,    trx.customer_code,    -trx.amt_net,
    pyt.date_applied,   trx.gl_trx_id,    meth.on_acct_code   , trx.org_id			
    FROM  #not_oa_rec rec, #arinppyt_work pyt, #artrx_work trx, arpymeth meth, arcust cust
    WHERE pyt.customer_code = rec.customer_code
    AND pyt.doc_ctrl_num = rec.doc_ctrl_num
    AND pyt.trx_type = 2112
    AND pyt.batch_code = @batch_ctrl_num
    AND rec.missing_flag = 1
    AND pyt.customer_code = trx.customer_code
    AND pyt.doc_ctrl_num = trx.doc_ctrl_num
    AND trx.trx_type = 2111
    AND trx.payment_type = 1
    AND trx.payment_code = meth.payment_code
    AND pyt.customer_code =cust.customer_code
    IF( @@error != 0 )
    BEGIN
      IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcaudt.cpp' + ', line ' + STR( 284, 5 ) + ' -- EXIT: '
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
    db_action,      nat_cur_code,     rate_home,
    rate_oper,      payer_cust_code,    true_amount,
    date_paid,      journal_ctrl_num,   account_code , org_id					
    )      
    SELECT  
    trx.trx_ctrl_num,   rec.doc_ctrl_num,   rec.doc_ctrl_num,
    2111,    trx.date_doc,     0,
    trx.date_doc,     pyt.customer_code,    cust.salesperson_code,
    cust.territory_code,        cust.price_code,        trx.amt_net,
    0,        2111,    -1,
    0,        rec.doc_ctrl_num,   2111,
    0,        0,        0,
    trx.date_applied,   ' ',        ' ',
    2,    trx.nat_cur_code,   trx.rate_home,
    trx.rate_oper,    trx.customer_code,    trx.amt_net,
    0,        trx.gl_trx_id,    meth.on_acct_code   , trx.org_id				
    FROM  #not_oa_rec rec, #arinppyt_work pyt, #artrx_work trx, arpymeth meth, arcust cust
    WHERE pyt.customer_code = rec.customer_code
    AND pyt.doc_ctrl_num = rec.doc_ctrl_num
    AND pyt.trx_type = 2112
    AND pyt.batch_code = @batch_ctrl_num
    AND rec.missing_flag = 1
    AND pyt.customer_code = trx.customer_code
    AND pyt.doc_ctrl_num = trx.doc_ctrl_num
    AND trx.trx_type = 2111
    AND trx.payment_type = 1
    AND trx.payment_code = meth.payment_code
    AND pyt.customer_code =cust.customer_code    
  DROP TABLE  #not_oa_rec
  DROP TABLE  #on_acct_rec

  END 

  




  CREATE TABLE #arpdt_voids
  (
    sub_apply_num   varchar(16),
    sub_apply_type  smallint,
    apply_to_num    varchar(16),
    apply_trx_type  smallint,
    date_aging    int,
    added     float,
    amt_discount    float
  )
  IF( @@error != 0 )
  BEGIN
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcaudt.cpp' + ', line ' + STR( 363, 5 ) + ' -- EXIT: '
    RETURN 34563
  END

  




  INSERT  #arpdt_voids
  SELECT  sub_apply_num, sub_apply_type, apply_to_num, apply_trx_type, date_aging, 
    sum(inv_amt_applied + inv_amt_disc_taken + inv_amt_max_wr_off),
    sum(inv_amt_disc_taken)
  FROM  #arinppdt_work
  WHERE temp_flag = 1
  GROUP BY sub_apply_num, sub_apply_type, apply_to_num, apply_trx_type, date_aging 

  IF( @@error != 0 )
  BEGIN
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcaudt.cpp' + ', line ' + STR( 382, 5 ) + ' -- EXIT: '
    RETURN 34563
  END

  IF (@debug_level >= 2)
  BEGIN
    SELECT 'dumping #arpdt_voids....'
    SELECT  'sub_apply_num = ' + sub_apply_num +
      'sub_apply_type = ' + STR(sub_apply_type, 8 ) +
      'apply_to_num = ' + apply_to_num +
      'apply_trx_type = ' + STR(apply_trx_type, 8 ) +
      'added = ' + STR(added, 10, 2) +
      'amt_discount = ' + STR(amt_discount, 10, 2)                                                                      
    FROM  #arpdt_voids
  END
  
  



  UPDATE #artrxage_work
  SET db_action = db_action | 1,
    amt_paid = amt_paid - added
  FROM  #artrxage_work age, #arpdt_voids pdt
  WHERE   age.doc_ctrl_num = pdt.sub_apply_num
  AND age.trx_type = pdt.sub_apply_type
  AND age.date_aging = pdt.date_aging
  
  IF( @@error != 0 )
  BEGIN
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcaudt.cpp' + ', line ' + STR( 412, 5 ) + ' -- EXIT: '
    RETURN 34563
  END


  



  SET ROWCOUNT 1
  
  SELECT @date_applied  = date_applied
  FROM  #arinppyt_work
  WHERE batch_code = @batch_ctrl_num
  
  SET ROWCOUNT 0
  
  








  
  UPDATE  #artrxage_work
  SET date_paid = SIGN(1 + SIGN(age.date_paid - @date_applied - 0.5)) * age.date_paid +
        SIGN(1 + SIGN(@date_applied - age.date_paid)) * @date_applied,  
    paid_flag = SIGN(pyt.trx_type - 2112),
    db_action = age.db_action | 1
  FROM  #arinppyt_work pyt, #artrxage_work age
  WHERE pyt.doc_ctrl_num = age.doc_ctrl_num
  AND pyt.customer_code = age.customer_code
  AND age.apply_to_num = age.doc_ctrl_num
  AND age.trx_type = age.apply_trx_type
  AND pyt.trx_type <= 2121
  AND pyt.batch_code = @batch_ctrl_num
  AND ref_id = 0
    
  IF( @@error != 0 )
  BEGIN
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcaudt.cpp' + ', line ' + STR( 455, 5 ) + ' -- EXIT: '
    RETURN 34563
  END

  
























  






  IF 1 = (  SELECT  SIGN(arsumcus_flag + aractcus_flag)
      FROM  arco
    )
  BEGIN
    INSERT  #arsumcus_pre ( customer_code, num_inv_paid )
    SELECT  customer_code, SUM(paid_flag)
    FROM  #artrx_work 
    WHERE trx_type <= 2031
    GROUP BY customer_code
  END
  


  IF 1 = (  SELECT  aractcus_flag
      FROM  arco
    )
  BEGIN
    DECLARE @home_precision smallint,
        @oper_precision smallint
    
    SELECT  @home_precision = curr_precision
    FROM  glco, glcurr_vw
    WHERE glco.home_currency = glcurr_vw.currency_code
    
    SELECT  @oper_precision = curr_precision
    FROM  glco, glcurr_vw
    WHERE glco.oper_currency = glcurr_vw.currency_code
    
    INSERT  #aractcus_pre
    SELECT  a.customer_code,
      SUM(ROUND(a.amt_on_acct * ( SIGN(1 + SIGN(a.rate_home))*(a.rate_home) + (SIGN(ABS(SIGN(ROUND(a.rate_home,6))))/(a.rate_home + SIGN(1 - ABS(SIGN(ROUND(a.rate_home,6)))))) * SIGN(SIGN(a.rate_home) - 1) ), @home_precision)),
      SUM(ROUND(a.amt_on_acct * ( SIGN(1 + SIGN(a.rate_oper))*(a.rate_oper) + (SIGN(ABS(SIGN(ROUND(a.rate_oper,6))))/(a.rate_oper + SIGN(1 - ABS(SIGN(ROUND(a.rate_oper,6)))))) * SIGN(SIGN(a.rate_oper) - 1) ), @oper_precision))
    FROM  #artrx_work a, #arinppyt_work b
    WHERE b.batch_code = @batch_ctrl_num
    AND a.doc_ctrl_num = b.doc_ctrl_num
    AND a.customer_code = b.customer_code
    AND a.void_flag = 0
    AND a.trx_type = 2111
    GROUP BY a.customer_code

  END 
  


  IF 1 = (  SELECT  SIGN(arsumprc_flag + aractprc_flag)
      FROM  arco
    )
  BEGIN
    INSERT  #arsumprc_pre ( price_code, num_inv_paid )
    SELECT  price_code, SUM(paid_flag)
    FROM  #artrx_work invoice_pre
    WHERE invoice_pre.trx_type <= 2031
    AND ( LTRIM(price_code) IS NOT NULL AND LTRIM(price_code) != ' ' )
    GROUP BY price_code
  END
  


  IF 1 = (  SELECT  SIGN(arsumslp_flag + aractslp_flag)
      FROM  arco
    )
  BEGIN
  INSERT  #arsumslp_pre ( salesperson_code, num_inv_paid )
  SELECT  salesperson_code, SUM(paid_flag)
  FROM  #artrx_work invoice_pre
  WHERE invoice_pre.trx_type <= 2031
  AND ( LTRIM(salesperson_code) IS NOT NULL AND LTRIM(salesperson_code) != ' ' )
  GROUP BY salesperson_code
  END
  


  IF 1 = (  SELECT  SIGN(arsumshp_flag + aractshp_flag)
      FROM  arco
    )
  BEGIN
  INSERT  #arsumshp_pre ( customer_code, ship_to_code, num_inv_paid )
  SELECT  customer_code, ship_to_code, SUM(paid_flag)
  FROM  #artrx_work invoice_pre
  WHERE invoice_pre.trx_type <= 2031
  AND ( LTRIM(ship_to_code) IS NOT NULL AND LTRIM(ship_to_code) != ' ' ) 
  GROUP BY customer_code, ship_to_code
  END
  


  IF 1 = (  SELECT  SIGN(arsumter_flag + aractter_flag)
      FROM  arco
    )
  BEGIN
  INSERT  #arsumter_pre ( territory_code, num_inv_paid )
  SELECT  territory_code, SUM(paid_flag)
  FROM  #artrx_work invoice_pre
  WHERE invoice_pre.trx_type <= 2031
  AND ( LTRIM(territory_code) IS NOT NULL AND LTRIM(territory_code) != ' ' )
  GROUP BY territory_code
  END

  




  UPDATE #artrx_work
  SET void_flag = 1,
    db_action = trx.db_action | 1
  FROM  #arinppyt_work pyt, #artrx_work trx
  WHERE pyt.doc_ctrl_num = trx.doc_ctrl_num
  AND pyt.customer_code = trx.customer_code
  AND trx.trx_type = 2111
  AND pyt.batch_code = @batch_ctrl_num
  AND pyt.trx_type between 2113 and 2121
  IF( @@error != 0 )
  BEGIN
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcaudt.cpp' + ', line ' + STR( 605, 5 ) + ' -- EXIT: '
    RETURN 34563
  END


  





  CREATE TABLE #inv_amts
  (
    apply_to_num    varchar(16),
    apply_trx_type  smallint,
    total     float,
    amt_discount    float
  )

  INSERT  #inv_amts
  SELECT  apply_to_num, apply_trx_type, sum(added), sum(amt_discount)
  FROM  #arpdt_voids pdt
  GROUP BY  apply_to_num, apply_trx_type
  IF( @@error != 0 )
  BEGIN
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcaudt.cpp' + ', line ' + STR( 630, 5 ) + ' -- EXIT: '
    RETURN 34563
  END

  DROP TABLE #arpdt_voids

  UPDATE #artrx_work
  SET amt_paid_to_date = amt_paid_to_date - total,
    paid_flag = SIGN(1 - SIGN(ROUND(amt_tot_chg - amt_paid_to_date + total,6))),
    date_paid = SIGN(1 + SIGN(date_paid - @date_applied - 0.5)) * date_paid +
        SIGN(1 + SIGN(@date_applied - date_paid)) * @date_applied,
    amt_discount_taken = amt_discount_taken - inv.amt_discount,       
    db_action = trx.db_action | 1
  FROM  #inv_amts inv, #artrx_work trx
  WHERE inv.apply_to_num = trx.doc_ctrl_num
  AND inv.apply_trx_type = trx.trx_type 
  IF( @@error != 0 )
  BEGIN
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcaudt.cpp' + ', line ' + STR( 648, 5 ) + ' -- EXIT: '
    RETURN 34563
  END

  IF (@debug_level >= 2)
  BEGIN
    SELECT 'dumping #artrx_work....'
    SELECT  'doc_ctrl_num = ' + doc_ctrl_num +
      'trx_type = ' + STR(trx_type, 8 ) +
      'amt_paid_to_date = ' + STR(amt_paid_to_date, 10, 2) +
      'amt_discount = ' + STR(amt_discount, 10, 2)                                                                      
    FROM  #artrx_work
  END

  DROP TABLE #inv_amts

  



  UPDATE  #artrxage_work
  SET paid_flag = SIGN(1 - SIGN(ABS(ROUND(trx.amt_paid_to_date - trx.amt_tot_chg,6)))),
    date_paid = trx.date_paid,
    db_action = trx.db_action | 1
  FROM  #artrx_work trx
  WHERE #artrxage_work.apply_to_num = trx.doc_ctrl_num
  AND #artrxage_work.apply_trx_type = trx.trx_type
  AND #artrxage_work.trx_type IN (2021, 2031, 2071)  
  AND trx.apply_to_num = trx.doc_ctrl_num
  AND trx.apply_trx_type = trx.trx_type

  
  





  CREATE TABLE #arinppdt_icr
  (
    doc_ctrl_num  varchar(16),
    customer_code varchar(8),
    sum_applied float
  )
  IF( @@error != 0 )
  BEGIN
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcaudt.cpp' + ', line ' + STR( 694, 5 ) + ' -- EXIT: '
    RETURN 34563
  END
  
  
  INSERT  #arinppdt_icr
    ( doc_ctrl_num, customer_code, sum_applied )
  SELECT  doc_ctrl_num, payer_cust_code, sum(amt_applied)
  FROM  #arinppdt_work
  WHERE trx_type = 2112
  AND temp_flag = 1
  GROUP BY doc_ctrl_num, payer_cust_code
  IF( @@error != 0 )
  BEGIN
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcaudt.cpp' + ', line ' + STR( 708, 5 ) + ' -- EXIT: '
    RETURN 34563
  END
  
  UPDATE #artrx_work
  SET amt_on_acct = amt_on_acct + sum_applied,
    db_action = trx.db_action | 1
  FROM  #arinppdt_icr pdt, #artrx_work trx
  WHERE pdt.doc_ctrl_num = trx.doc_ctrl_num
  AND pdt.customer_code = trx.customer_code
  AND trx.trx_type = 2111
  IF( @@error != 0 )
  BEGIN
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcaudt.cpp' + ', line ' + STR( 721, 5 ) + ' -- EXIT: '
    RETURN 34563
  END

  UPDATE  #artrx_work
  SET date_paid = age.date_paid,
    paid_flag = age.paid_flag,
    db_action = #artrx_work.db_action | 1
  FROM  #arinppyt_work pyt, #artrxage_work age
  WHERE pyt.doc_ctrl_num = age.doc_ctrl_num
  AND pyt.customer_code = age.customer_code
  AND age.apply_to_num = age.doc_ctrl_num
  AND age.trx_type = age.apply_trx_type
  AND age.ref_id = 0
  AND pyt.trx_type <= 2121
  AND pyt.batch_code = @batch_ctrl_num
  AND age.doc_ctrl_num = #artrx_work.doc_ctrl_num
  AND age.payer_cust_code = #artrx_work.customer_code
  AND #artrx_work.trx_type = 2111
  AND #artrx_work.payment_type IN (1,3)
    
  IF( @@error != 0 )
  BEGIN
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcaudt.cpp' + ', line ' + STR( 744, 5 ) + ' -- EXIT: '
    RETURN 34563
  END

  DROP TABLE #arinppdt_icr

  






  UPDATE  #artrxpdt_work
  SET void_flag = 1,
    db_action = tpdt.db_action | 1
  FROM  #artrxpdt_work tpdt, #arinppdt_work ipdt
  WHERE tpdt.doc_ctrl_num = ipdt.doc_ctrl_num
  AND tpdt.payer_cust_code = ipdt.payer_cust_code
  AND tpdt.date_aging = ipdt.date_aging
  AND tpdt.sub_apply_num = ipdt.sub_apply_num
  AND tpdt.trx_type = 2111
  AND ipdt.temp_flag = 1
  IF( @@error != 0 )
  BEGIN
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcaudt.cpp' + ', line ' + STR( 769, 5 ) + ' -- EXIT: '
    RETURN 34563
  END






















  
  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcaudt.cpp' + ', line ' + STR( 795, 5 ) + ' -- EXIT: '
  IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, 'arcaudt.cpp', 796, 'Leaving ARCAUpdateDependantTrans_SP', @PERF_time_last OUTPUT
    RETURN 0 

END   

GO
GRANT EXECUTE ON  [dbo].[ARCAUpdateDependTrans_SP] TO [public]
GO
