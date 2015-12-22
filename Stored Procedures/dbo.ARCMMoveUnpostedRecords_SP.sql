SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARCMMoveUnpostedRecords_SP]  @batch_ctrl_num varchar(16),
            @debug_level    smallint = 0,
            @perf_level   smallint = 0
AS








DECLARE
        @PERF_time_last     datetime

SELECT  @PERF_time_last = GETDATE()

















									







DECLARE @result     int,
    @process_ctrl_num varchar(16),
    @user_id    smallint,
    @date_entered   int,
    @period_end   int,
    @batch_type   smallint

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "arcmmur.cpp", 68, "Entering ARCMMoveUnpostedRecords_SP", @PERF_time_last OUTPUT

BEGIN
  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmmur.cpp" + ", line " + STR( 71, 5 ) + " -- ENTRY: "

  



  EXEC @result = batinfo_sp @batch_ctrl_num,
          @process_ctrl_num OUTPUT,
          @user_id OUTPUT,
          @date_entered OUTPUT,
          @period_end OUTPUT,
          @batch_type OUTPUT

  IF( @result != 0 )
  BEGIN
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmmur.cpp" + ", line " + STR( 86, 5 ) + " -- EXIT: "
    RETURN 35011
  END

  INSERT  #artrx_work 
  (
    trx_ctrl_num,       doc_ctrl_num,       doc_desc,
    batch_code,       trx_type,       non_ar_flag,
    apply_to_num,       apply_trx_type,     gl_acct_code,
    date_posted,        date_applied,       date_doc,
    gl_trx_id,        customer_code,      payment_code,
    amt_net,        payment_type,       prompt1_inp,
    prompt2_inp,        prompt3_inp,        prompt4_inp,
    deposit_num,        void_flag,        amt_on_acct,
    paid_flag,        user_id,        posted_flag,
    date_entered,       date_paid,        order_ctrl_num,
    date_shipped,       date_required,      date_due,
    date_aging,       ship_to_code,       salesperson_code,
    territory_code,     comment_code,       fob_code,
    freight_code,       terms_code,       price_code,
    dest_zone_code,     posting_code,       recurring_flag,
    recurring_code,     cust_po_num,        amt_gross,
    amt_freight,        amt_tax,        amt_discount,
    amt_paid_to_date,     amt_cost,       amt_tot_chg,
    amt_discount_taken,     amt_write_off_given,      fin_chg_code,
    tax_code,       commission_flag,      cash_acct_code,
    non_ar_doc_num,     purge_flag,       db_action,
    source_trx_ctrl_num,      source_trx_type,      nat_cur_code,
    rate_type_home,     rate_type_oper,     rate_home,
    rate_oper,        amt_tax_included,	 org_id
  )
  SELECT  arinpchg.trx_ctrl_num,    arinpchg.doc_ctrl_num,    arinpchg.doc_desc,
    @batch_ctrl_num,      arinpchg.trx_type,      0,
    arinpchg.apply_to_num,    arinpchg.apply_trx_type,    " ",
    @date_entered,      arinpchg.date_applied,    arinpchg.date_doc,
    cm.journal_ctrl_num,      arinpchg.customer_code,   " ",
    arinpchg.amt_net,     0,          " ",
    " ",          " ",          " ",
    " ",          0,          0,
    0,          arinpchg.user_id,     1,
    arinpchg.date_entered,    0,          arinpchg.order_ctrl_num,
    arinpchg.date_shipped,    arinpchg.date_required,   arinpchg.date_due,
    arinpchg.date_aging,      arinpchg.ship_to_code,    arinpchg.salesperson_code,
    arinpchg.territory_code,    arinpchg.comment_code,    arinpchg.fob_code,
    arinpchg.freight_code,    arinpchg.terms_code,      arinpchg.price_code,
    arinpchg.dest_zone_code,    arinpchg.posting_code,    arinpchg.recurring_flag,
    arinpchg.recurring_code,    arinpchg.cust_po_num,   arinpchg.amt_gross,
    arinpchg.amt_freight,   arinpchg.amt_tax,     arinpchg.amt_discount,
    0,          arinpchg.amt_cost,      0,
    arinpchg.amt_discount_taken,  arinpchg.amt_write_off_given, arinpchg.fin_chg_code,
    arinpchg.tax_code,      0,          " ",
    " ",          0,          2,
    source_trx_ctrl_num,      source_trx_type,      arinpchg.nat_cur_code,
    arinpchg.rate_type_home,    arinpchg.rate_type_oper,    arinpchg.rate_home,
    arinpchg.rate_oper,     arinpchg.amt_tax_included,	arinpchg.org_id
  FROM  #arinpchg_work arinpchg, #arcmtemp cm
  WHERE arinpchg.trx_ctrl_num = cm.trx_ctrl_num
  IF( @@error != 0 )
  BEGIN
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmmur.cpp" + ", line " + STR( 145, 5 ) + " -- EXIT: "
    RETURN 34563
  END

  




  UPDATE  #artrx_work
  SET paid_flag = 1,
    db_action = artrx.db_action | 1
  FROM  #arinpchg_work arinpchg, #artrx_work artrx
  WHERE arinpchg.trx_ctrl_num = artrx.trx_ctrl_num
  AND arinpchg.trx_type = artrx.trx_type
  AND arinpchg.amt_net = 0.0
  IF( @@error != 0 )
  BEGIN
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmmur.cpp" + ", line " + STR( 163, 5 ) + " -- EXIT: "
    RETURN 34563
  END

  



  UPDATE  #arinpchg_work
  SET db_action = db_action | 4
  WHERE batch_code = @batch_ctrl_num
  IF( @@error != 0 )
  BEGIN
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmmur.cpp" + ", line " + STR( 176, 5 ) + " -- EXIT: "
    RETURN 34563
  END

  




  INSERT  #artrxtax_work
  (
    trx_type,     doc_ctrl_num,     tax_type_code,
    date_applied,     amt_gross,      amt_taxable,  
    amt_tax,      date_doc,     db_action
  )
  SELECT  arinptax.trx_type,    arinpchg.doc_ctrl_num,  arinptax.tax_type_code,
    arinpchg.date_applied,  (1-SIGN(arinpchg.recurring_flag-1)) * arinptax.amt_gross, arinptax.amt_taxable, 
    arinptax.amt_final_tax, arinpchg.date_doc,    2
  FROM  #arinptax_work arinptax, #arinpchg_work arinpchg
  WHERE batch_code = @batch_ctrl_num
  AND arinpchg.trx_ctrl_num = arinptax.trx_ctrl_num
  AND arinpchg.trx_type = arinptax.trx_type
  AND arinpchg.recurring_flag != 3
  IF( @@error != 0 )
  BEGIN
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmmur.cpp" + ", line " + STR( 201, 5 ) + " -- EXIT: "
    RETURN 34563
  END

  



  UPDATE  #arinptax_work
  SET db_action = arinptax.db_action | 4
  FROM  #arinpchg_work arinpchg, #arinptax_work arinptax
  WHERE batch_code = @batch_ctrl_num
  AND arinpchg.trx_ctrl_num = arinptax.trx_ctrl_num
  AND arinpchg.trx_type = arinptax.trx_type
  IF( @@error != 0 )
  BEGIN
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmmur.cpp" + ", line " + STR( 217, 5 ) + " -- EXIT: "
    RETURN 34563
  END

  


  INSERT  #artrxcom_work
  (
    trx_ctrl_num,     trx_type,     doc_ctrl_num, 
    sequence_id,      salesperson_code,   amt_commission, 
    percent_flag,     exclusive_flag,   split_flag, 
    commission_flag,    db_action
  )
  SELECT  arinpchg.trx_ctrl_num,  arinpchg.trx_type,    arinpchg.doc_ctrl_num,
    arinpcom.sequence_id, arinpcom.salesperson_code,  arinpcom.amt_commission, 
    arinpcom.percent_flag,  arinpcom.exclusive_flag,  arinpcom.split_flag,  
    0,  2
  FROM  #arinpchg_work arinpchg, #arinpcom_work arinpcom
  WHERE batch_code = @batch_ctrl_num
  AND arinpchg.trx_ctrl_num = arinpcom.trx_ctrl_num
  AND arinpchg.trx_type = arinpcom.trx_type
  IF( @@error != 0 )
  BEGIN
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmmur.cpp" + ", line " + STR( 241, 5 ) + " -- EXIT: "
    RETURN 34563
  END

  UPDATE  #arinpcom_work
  SET db_action = arinpcom.db_action | 4
  FROM  #arinpcom_work arinpcom, #arinpchg_work arinpchg
  WHERE batch_code = @batch_ctrl_num
  AND arinpchg.trx_ctrl_num = arinpcom.trx_ctrl_num
  AND arinpchg.trx_type = arinpcom.trx_type
  IF( @@error != 0 )
  BEGIN
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmmur.cpp" + ", line " + STR( 253, 5 ) + " -- EXIT: "
    RETURN 34563
  END

  INSERT  #artrxcdt_work
  (
    doc_ctrl_num,   trx_ctrl_num,   sequence_id,  
    trx_type,   location_code,  item_code,  
    bulk_flag,    date_entered,   date_posted,  
    date_applied,   line_desc,    qty_ordered,
    qty_shipped,    unit_code,    unit_price, 
    weight,   amt_cost,   serial_id,
    tax_code,   gl_rev_acct,    discount_prc, 
    discount_amt,   rma_num,    return_code,  
    qty_returned,   new_gl_rev_acct,  disc_prc_flag,
    db_action,    extended_price, calc_tax,
    reference_code,  org_id
  )
  SELECT
    h.doc_ctrl_num, d.trx_ctrl_num, d.sequence_id,  
    d.trx_type,   d.location_code,  d.item_code,  
    d.bulk_flag,    d.date_entered, @date_entered,  
    h.date_applied, d.line_desc,    d.qty_ordered,
    d.qty_shipped,  d.unit_code,    d.unit_price, 
    d.weight,   0,      d.serial_id,  
    d.tax_code,   d.gl_rev_acct,  d.discount_prc,
    d.discount_amt, d.rma_num,    d.return_code,
    d.qty_returned, d.new_gl_rev_acct,  d.disc_prc_flag,
    2,  d.extended_price, d.calc_tax,
    d.reference_code, d.org_id
  FROM  #arinpcdt_work d, #arinpchg_work h
  WHERE batch_code = @batch_ctrl_num
  AND h.trx_ctrl_num = d.trx_ctrl_num
  AND h.trx_type = d.trx_type
  IF( @@error != 0 )
  BEGIN
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmmur.cpp" + ", line " + STR( 289, 5 ) + " -- EXIT: "
    RETURN 34563
  END

  


  UPDATE  #arinpcdt_work
  SET db_action = d.db_action | 4
  FROM  #arinpchg_work h, #arinpcdt_work d
  WHERE h.batch_code = @batch_ctrl_num
  AND h.trx_ctrl_num = d.trx_ctrl_num
  AND h.trx_type = d.trx_type
  IF( @@error != 0 )
  BEGIN
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmmur.cpp" + ", line " + STR( 304, 5 ) + " -- EXIT: "
    RETURN 34563
  END
  



  INSERT  #artrxxtr_work
  (
    rec_set,    amt_due,    amt_paid,
    trx_type,   trx_ctrl_num,   addr1,
    addr2,      addr3,      addr4,
    addr5,      addr6,      ship_addr1,
    ship_addr2,   ship_addr3,   ship_addr4,
    ship_addr5,   ship_addr6,   attention_name,
    attention_phone, customer_country_code,	
	customer_city,	customer_state,	customer_postal_code,
	ship_to_country_code,	ship_to_city,	ship_to_state,
	ship_to_postal_code, db_action
  )
  SELECT  1,      a.amt_due,    a.amt_paid,
    a.trx_type,   a.trx_ctrl_num,   a.customer_addr1,
    a.customer_addr2, a.customer_addr3, a.customer_addr4,
    a.customer_addr5, a.customer_addr6, a.ship_to_addr1,
    a.ship_to_addr2,  a.ship_to_addr3,  a.ship_to_addr4,
    a.ship_to_addr5,  a.ship_to_addr6,  a.attention_name,
    a.attention_phone, b.customer_country_code,	
	b.customer_city,	b.customer_state,	b.customer_postal_code,
	b.ship_to_country_code,	b.ship_to_city,	b.ship_to_state,
	b.ship_to_postal_code, 2
  FROM  #arinpchg_work a, arinpchg b
  WHERE a.trx_ctrl_num = b.trx_ctrl_num
	AND a.trx_type = b.trx_type
	AND a.batch_code = @batch_ctrl_num

  IF( @@error != 0 )
  BEGIN
    IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmmur.cpp" + ", line " + STR( 332, 5 ) + " -- EXIT: "
    RETURN 34563
  END   

  IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "arcmmur.cpp", 336, "Leaving ARCMMoveUnpostedRecords_SP", @PERF_time_last OUTPUT
  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmmur.cpp" + ", line " + STR( 337, 5 ) + " -- EXIT: "
  RETURN 0 
END
GO
GRANT EXECUTE ON  [dbo].[ARCMMoveUnpostedRecords_SP] TO [public]
GO
