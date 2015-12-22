SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO





























  



					  

























































 






























































































































































































































































































































































































































































































































































































































































































































CREATE PROC  [dbo].[ARCMCreateOnAccountRecords_SP]  @batch_ctrl_num varchar( 16 ),
              @debug_level    smallint = 0,
              @perf_level   smallint = 0
AS








DECLARE
        @PERF_time_last     datetime

SELECT  @PERF_time_last = GETDATE()

















									







DECLARE
  @result     int,
  @process_ctrl_num varchar(16),
  @user_id    smallint,
  @date_entered   int,
  @period_end   int,
  @batch_type   smallint,
  @min_apply_to_num varchar(16),
  @org_open_amt   float,
  @last_apply_to_num  varchar(16),
  @loop_amt_net   float,
  @loop_trx_ctrl_num  varchar(16),
  @loop_trx_type  smallint,
  @last_trx_ctrl_num  varchar(16),
  @loop_amt_on_acct float

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "arcmcoar.cpp", 76, "Entering ARCMCreateOnAccountRecords_SP", @PERF_time_last OUTPUT

BEGIN
  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmcoar.cpp" + ", line " + STR( 79, 5 ) + " -- ENTRY: "

  



  
  EXEC @result = batinfo_sp @batch_ctrl_num,
          @process_ctrl_num OUTPUT,
          @user_id OUTPUT,
          @date_entered OUTPUT, 
          @period_end OUTPUT,
          @batch_type OUTPUT
  IF( @result != 0 )
  BEGIN
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmcoar.cpp" + ", line " + STR( 94, 5 ) + " -- EXIT: "
    RETURN 35011
  END

  







CREATE TABLE #arcmcr
(	
	trx_ctrl_num	varchar(16),
	trx_type		smallint,
	apply_to_num	varchar(16),
	apply_trx_type	smallint,
	open_amt		float,
	cr_trx_ctrl_num	varchar(16),
	on_acct_flag	smallint,
	date_aging		int,
	amt_net			float,
	amt_on_acct		float,
	amt_applied		float NULL
)


  















  


  INSERT  #arcmcr
  (
    trx_ctrl_num,   trx_type,   apply_to_num,
    apply_trx_type, open_amt,   cr_trx_ctrl_num,
    on_acct_flag,   date_aging,   amt_net,
    amt_on_acct
  )
  SELECT
    trx_ctrl_num,   trx_type,   apply_to_num,
    apply_trx_type, 0.0,      ' ',
    0,      0,      amt_net,
    0.0
  FROM  #arinpchg_work
  WHERE batch_code = @batch_ctrl_num
    AND recurring_flag = 1
  IF( @@error != 0 )
  BEGIN
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmcoar.cpp" + ", line " + STR( 143, 5 ) + " -- EXIT: "
    RETURN 34563
  END

  


  INSERT  #arcmcr
  (
    trx_ctrl_num,   trx_type,   apply_to_num,
    apply_trx_type, amt_net,    open_amt,
    cr_trx_ctrl_num,  date_aging,   on_acct_flag,
    amt_on_acct
  )
  SELECT
    trx_ctrl_num,   trx_type,   apply_to_num,
    apply_trx_type, amt_tax,    0.0,
    ' ',      0,      0,
    0.0
  FROM  #arinpchg_work
  WHERE recurring_flag = 2
    AND batch_code = @batch_ctrl_num
  IF( @@error != 0 )
  BEGIN
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmcoar.cpp" + ", line " + STR( 167, 5 ) + " -- EXIT: "
    RETURN 34563
  END
  
  


  INSERT  #arcmcr
  (
    trx_ctrl_num,   trx_type,   apply_to_num,
    apply_trx_type, amt_net,    open_amt,
    cr_trx_ctrl_num,  date_aging,   on_acct_flag,
    amt_on_acct
  )
  SELECT
    trx_ctrl_num,   trx_type,   apply_to_num,
    apply_trx_type, amt_freight,    0.0,
    ' ',      0,      0,
    0.0
  FROM  #arinpchg_work
  WHERE recurring_flag = 3
    AND batch_code = @batch_ctrl_num
  IF( @@error != 0 )
  BEGIN
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmcoar.cpp" + ", line " + STR( 191, 5 ) + " -- EXIT: "
    RETURN 34563
  END

  


  INSERT  #arcmcr
  (
    trx_ctrl_num,   trx_type,         apply_to_num,
    apply_trx_type, amt_net,          open_amt,
    cr_trx_ctrl_num,  date_aging,         on_acct_flag,
    amt_on_acct
  )
  SELECT
    trx_ctrl_num,   trx_type,         apply_to_num,
    apply_trx_type, amt_tax + amt_freight,      0.0,
    ' ',      0,            0,
    0.0
  FROM  #arinpchg_work
  WHERE recurring_flag = 4
  AND batch_code = @batch_ctrl_num
  IF( @@error != 0 )
  BEGIN
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmcoar.cpp" + ", line " + STR( 215, 5 ) + " -- EXIT: "
    RETURN 34563
  END

  


  IF( @debug_level >= 3 )
  BEGIN
    SELECT  "Rows in #arcmcr after calculating amt_net"
    SELECT  "trx_ctrl_num:trx_type:apply_to_num:apply_trx_type:amt_net"
    SELECT  trx_ctrl_num + ":" +
      STR(trx_type, 6) + ":" +
      apply_to_num + ":" +
      STR(apply_trx_type, 6) + ":" +
      STR(amt_net, 10, 4)
    FROM  #arcmcr
  END

  



  UPDATE  #arcmcr
  SET apply_to_num = master.apply_to_num,
    apply_trx_type = master.apply_trx_type,
    date_aging = master.date_aging
  FROM  #artrx_work master, #arcmcr cr
  WHERE cr.apply_to_num = master.doc_ctrl_num
  AND cr.apply_trx_type = master.trx_type
  IF( @@error != 0 )
  BEGIN
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmcoar.cpp" + ", line " + STR( 247, 5 ) + " -- EXIT: "
    RETURN 34563
  END
  


  IF( @debug_level >= 3 )
  BEGIN
    SELECT  "Rows in #arcmcr after getting master information"
    SELECT  "trx_ctrl_num:trx_type:apply_to_num:apply_trx_type"
    SELECT  trx_ctrl_num + ":" +
      STR(trx_type, 6) + ":" +
      apply_to_num + ":" +
      STR(apply_trx_type, 6)
    FROM  #arcmcr
  END

  



  UPDATE  #arcmcr
  SET open_amt = artrx.amt_tot_chg - artrx.amt_paid_to_date
  FROM  #artrx_work artrx, #arcmcr cr
  WHERE artrx.doc_ctrl_num = cr.apply_to_num
  AND artrx.trx_type = cr.apply_trx_type
  AND artrx.amt_tot_chg - artrx.amt_paid_to_date > 0.0
  IF( @@error != 0 )
  BEGIN
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmcoar.cpp" + ", line " + STR( 276, 5 ) + " -- EXIT: "
    RETURN 34563
  END

  



  IF( @debug_level >= 3 )
  BEGIN
    SELECT  "Rows in #arcmcr after getting open_amt of master information"
    SELECT  "trx_ctrl_num:trx_type:open_amt"
    SELECT  trx_ctrl_num + ":" +
      STR(trx_type, 6) + ":" +
      STR(open_amt, 10, 4)
    FROM  #arcmcr
  END

  





  SELECT  apply_to_num, count(*) total_ct
  INTO  #multi_apply
  FROM  #arcmcr
  GROUP BY apply_to_num
    
  




  UPDATE  #multi_apply
  SET total_ct =  1
  WHERE ( LTRIM(apply_to_num) IS NULL OR LTRIM(apply_to_num) = " " )

  











  UPDATE  #arcmcr
  SET amt_on_acct = a.amt_net - a.open_amt,
    on_acct_flag = 1
  FROM  #arcmcr a, #multi_apply b
  WHERE a.apply_to_num = b.apply_to_num
  AND b.total_ct = 1
  AND a.amt_net - a.open_amt > 0.0
  IF( @@error != 0 )
  BEGIN
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmcoar.cpp" + ", line " + STR( 335, 5 ) + " -- EXIT: "
    RETURN 34563
  END


  IF EXISTS ( SELECT COUNT(*) FROM #multi_apply WHERE total_ct > 1)
  BEGIN
    SELECT  @min_apply_to_num = ""
          
    WHILE(1 = 1)
    BEGIN
      SELECT @last_apply_to_num = @min_apply_to_num,
        @min_apply_to_num = ""
        
      



      SET ROWCOUNT 1
      
      SELECT  @min_apply_to_num = a.apply_to_num,
        @org_open_amt = a.open_amt
      FROM  #arcmcr a, #multi_apply b
      WHERE a.apply_to_num = b.apply_to_num
      AND b.total_ct > 1
      AND a.apply_to_num > @last_apply_to_num
      ORDER BY a.apply_to_num, a.trx_ctrl_num
        
      IF( @@error != 0 )
      BEGIN
        IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmcoar.cpp" + ", line " + STR( 365, 5 ) + " -- EXIT: "
        RETURN 34563
      END

      SET ROWCOUNT 0  
        
        
      IF( @min_apply_to_num = "")
        BREAK
          
      




      SELECT @loop_trx_ctrl_num = ""
        
      WHILE( 1= 1 )
      BEGIN
        SELECT @last_trx_ctrl_num = @loop_trx_ctrl_num,
          @loop_trx_ctrl_num = ""
          
        SET ROWCOUNT 1
        
        SELECT  @loop_trx_ctrl_num = trx_ctrl_num,
          @loop_trx_type = trx_type,
          @loop_amt_net = amt_net,
          @loop_amt_on_acct = amt_on_acct
        FROM  #arcmcr
        WHERE apply_to_num = @min_apply_to_num
        AND trx_ctrl_num > @last_trx_ctrl_num
        ORDER BY trx_ctrl_num
        
        IF @@rowcount = 0
        BEGIN
          SET ROWCOUNT 0
          BREAK
        END
        
        SET ROWCOUNT 0
        
        IF ( @org_open_amt - @loop_amt_net >= 0.0 )
        BEGIN
          UPDATE  #arcmcr
          SET amt_on_acct = 0.0,
            on_acct_flag = 0,
            open_amt = @org_open_amt
          FROM  #arcmcr
          WHERE trx_ctrl_num = @loop_trx_ctrl_num
          AND trx_type = @loop_trx_type
          AND apply_to_num = @min_apply_to_num
          
          IF( @@error != 0 )
          BEGIN
            IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmcoar.cpp" + ", line " + STR( 419, 5 ) + " -- EXIT: "
            RETURN 34563
          END
          
          SELECT  @org_open_amt = @org_open_amt - @loop_amt_net
        END
        ELSE
        BEGIN
          UPDATE  #arcmcr
          SET amt_on_acct = @loop_amt_net - @org_open_amt,
            open_amt = @org_open_amt,
            on_acct_flag = 1
          FROM  #arcmcr
          WHERE trx_ctrl_num = @loop_trx_ctrl_num
          AND trx_type = @loop_trx_type
          AND apply_to_num = @min_apply_to_num
          
          IF( @@error != 0 )
          BEGIN
            IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmcoar.cpp" + ", line " + STR( 438, 5 ) + " -- EXIT: "
            RETURN 34563
          END
          
          SELECT  @org_open_amt = 0.0
          
        END 
      END
    END 
  
  END

  DROP TABLE #multi_apply
  
  





  UPDATE  #arcmcr
  SET amt_applied = amt_net - amt_on_acct
  FROM  #arcmcr
  IF( @@error != 0 )
  BEGIN
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmcoar.cpp" + ", line " + STR( 463, 5 ) + " -- EXIT: "
    RETURN 34563
  END

  



  UPDATE  #arcmcr
  SET amt_on_acct = amt_net,
    on_acct_flag = 1
  FROM  #arcmcr
  WHERE apply_trx_type = 0
  AND amt_applied = 0.0
  IF( @@error != 0 )
  BEGIN
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmcoar.cpp" + ", line " + STR( 479, 5 ) + " -- EXIT: "
    RETURN 34563
  END

  








  
  EXEC @result = ARCMCreateOnAccountPayments_SP @batch_ctrl_num,
                @debug_level,
                @perf_level
  IF( @result != 0 )
  BEGIN
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmcoar.cpp" + ", line " + STR( 498, 5 ) + " -- EXIT: "
    RETURN @result
  END

  


  IF( @debug_level >= 2 )
  BEGIN
    SELECT  "Rows in #arcmcr - trx_ctrl_num:trx_type:cr_trx_ctrl_num:amt_net"
    SELECT  trx_ctrl_num + ":" +
      STR(trx_type, 7) + ":" +
      cr_trx_ctrl_num + ":" +
      STR(amt_net, 10, 4)
    FROM  #arcmcr
  END   

  





  INSERT  #artrx_work
  (
    trx_ctrl_num,     doc_ctrl_num,     doc_desc, 
    batch_code,     trx_type,     non_ar_flag, 
    apply_to_num,     apply_trx_type,   gl_acct_code, 
    date_posted,      date_applied,     date_doc, 
    gl_trx_id,      customer_code,    payment_code, 
    amt_net,      payment_type,     prompt1_inp,  
    prompt2_inp,      prompt3_inp,      prompt4_inp,  
    deposit_num,      void_flag,      amt_on_acct,
    paid_flag,      user_id,      posted_flag,
    date_entered,     date_paid,      order_ctrl_num, 
    date_shipped,     date_required,    date_due,   
    date_aging,     ship_to_code,     salesperson_code,   
    territory_code,   comment_code,     fob_code, 
    freight_code,     terms_code,     price_code, 
    dest_zone_code,   posting_code,     recurring_flag, 
    recurring_code,   cust_po_num,      amt_gross,  
    amt_freight,      amt_tax,      amt_discount,   
    amt_paid_to_date,   amt_cost,     amt_tot_chg,    
    amt_discount_taken,   amt_write_off_given,    fin_chg_code,     
    tax_code,     commission_flag,    cash_acct_code,   
    non_ar_doc_num,     purge_flag,     process_group_num,      
    db_action,      source_trx_ctrl_num,    source_trx_type,    
    nat_cur_code,     rate_type_home,   rate_type_oper,
    rate_home,      rate_oper,      amt_tax_included,
    org_id
  )
  SELECT  cr.cr_trx_ctrl_num,   arinpchg.doc_ctrl_num,  arinpchg.doc_desc,
    batch_code,     2111,       0,
    " ",        0,        " ",
    @date_entered,    arinpchg.date_applied,  arinpchg.date_doc,  
    trx.journal_ctrl_num, arinpchg.customer_code, " ",
    cr.amt_net,     3,        " ",        
    " ",        " ",        " ",
    " ",        0,        cr.amt_net,
    0,        arinpchg.user_id,   -1,
    arinpchg.date_entered,  arinpchg.date_applied,  " ",    
    0,        0,        arinpchg.date_doc,      
    arinpchg.date_doc,    arinpchg.ship_to_code,  arinpchg.salesperson_code, 
    territory_code,   " ",        " ",    
    " ",        arinpchg.terms_code,    arinpchg.price_code,  
    " ",        arinpchg.posting_code,  0,    
    " ",        " ",        0.0,    
    0.0,        0.0,        0.0,    
    0.0,        0.0,        0.0,    
    0.0,        0.0,        " ",        
    " ",        0,        " ",        
    " ",        0,        process_group_num,    
    2,    arinpchg.trx_ctrl_num,  arinpchg.trx_type,
    arinpchg.nat_cur_code,  arinpchg.rate_type_home,  arinpchg.rate_type_oper,
    arinpchg.rate_home,   arinpchg.rate_oper,   0.0,
    arinpchg.org_id
  FROM  #arinpchg_work arinpchg, #arcmcr cr, #arcmtemp trx
  WHERE arinpchg.trx_ctrl_num = cr.trx_ctrl_num
  AND arinpchg.trx_ctrl_num = trx.trx_ctrl_num
  IF( @@error != 0 )
  BEGIN
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmcoar.cpp" + ", line " + STR( 579, 5 ) + " -- EXIT: "
    RETURN 34563
  END

  


  INSERT  #artrxage_work
  (
    trx_ctrl_num,       trx_type,     ref_id,   
    doc_ctrl_num,       apply_to_num,     apply_trx_type, 
    sub_apply_num,      sub_apply_type,   date_doc, 
    date_due,       date_aging,     customer_code,
    salesperson_code,       territory_code,     price_code, 
    amount,       paid_flag,      group_id, 
    amt_fin_chg,        amt_late_chg,     amt_paid, 
    order_ctrl_num,     cust_po_num,      date_applied,
    db_action,        date_paid,      nat_cur_code,
    rate_home,        rate_oper,      true_amount,
    payer_cust_code,      journal_ctrl_num,   account_code,
    org_id      
  )
  SELECT  cr.cr_trx_ctrl_num,     2161,    0,        
    arinpchg.doc_ctrl_num,    arinpchg.doc_ctrl_num,  2161,    
    arinpchg.doc_ctrl_num,    2161,    arinpchg.date_doc,  
    arinpchg.date_doc,      arinpchg.date_doc,    arinpchg.customer_code,
    arinpchg.salesperson_code,  arinpchg.territory_code,   arinpchg.price_code, 
    -cr.amt_net,        0,        0,    
    0,          0,        0,    
    arinpchg.order_ctrl_num,    arinpchg.cust_po_num, arinpchg.date_applied,
    2,      0,        arinpchg.nat_cur_code,
    arinpchg.rate_home,     arinpchg.rate_oper,   -cr.amt_net,
    arinpchg.customer_code,   tmp.journal_ctrl_num, dbo.IBAcctMask_fn(acct.cm_on_acct_code,arinpchg.org_id),      
    arinpchg.org_id
  FROM  #arinpchg_work arinpchg, #arcmcr cr, #arcmtemp tmp, araccts acct
  WHERE arinpchg.trx_ctrl_num = cr.trx_ctrl_num
  AND arinpchg.trx_ctrl_num = tmp.trx_ctrl_num
  AND arinpchg.posting_code = acct.posting_code
  IF( @@error != 0 )
  BEGIN
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmcoar.cpp" + ", line " + STR( 619, 5 ) + " -- EXIT: "
    RETURN 34563
  END
  
  DROP TABLE #arcmcr

  IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "arcmcoar.cpp", 625, "Leaving ARCMCreateOnAccountRecords_SP", @PERF_time_last OUTPUT
  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmcoar.cpp" + ", line " + STR( 626, 5 ) + " -- EXIT: "
  RETURN 0 
END
GO
GRANT EXECUTE ON  [dbo].[ARCMCreateOnAccountRecords_SP] TO [public]
GO
