SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 20/06/2012 - Fix standard product  
  
CREATE PROCEDURE [dbo].[arinpchg_sp] @batch_ctrl_num varchar( 16 ),  
     @debug_level  smallint = 0,  
     @perf_level  smallint = 0  
WITH RECOMPILE  
AS  
  
  
  
  
  
  
  
  
DECLARE  
        @PERF_time_last     datetime  
  
SELECT  @PERF_time_last = GETDATE()  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
           
  
  
  
  
  
  
  
DECLARE  
 @status  int  
  
SELECT  @status = 0  
  
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arinpchg.cpp' + ', line ' + STR( 43, 5 ) + ' -- ENTRY: '  
  
IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, 'arinpchg.cpp', 45, 'entry arinpchg_sp', @PERF_time_last OUTPUT  
  
  
  
  
  
  
  
  
  
  
  
  
  
DELETE arinpchg  
FROM #arinpchg_work a, arinpchg b  
WHERE a.trx_ctrl_num = b.trx_ctrl_num  
AND a.trx_type = b.trx_type   
AND db_action > 0  
  
SELECT @status = @@error  
  
IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, 'arinpchg.cpp', 67, 'delete arinpchg: delete action', @PERF_time_last OUTPUT  
  
IF ( @status = 0 )  
BEGIN  
 INSERT arinpchg_all   
       (   
        trx_ctrl_num,  doc_ctrl_num,  doc_desc,  
         apply_to_num,  apply_trx_type, order_ctrl_num,  
        batch_code,        trx_type,         date_entered,  
        date_applied,        date_doc,         date_shipped,  
        date_required,      date_due,         date_aging,  
        customer_code,      ship_to_code,        salesperson_code,  
        territory_code,      comment_code,        fob_code,  
         freight_code,  terms_code,         fin_chg_code,  
        price_code,         dest_zone_code,      posting_code,  
        recurring_flag,      recurring_code,      tax_code,  
        cust_po_num,         total_weight,        amt_gross,  
        amt_freight,         amt_tax,         amt_discount,  
        amt_net,         amt_paid,         amt_due,  
        amt_cost,         amt_profit,         next_serial_id,  
  printed_flag,        posted_flag,         hold_flag,  
         hold_desc,         user_id,        customer_addr1,  
        customer_addr2, customer_addr3,      customer_addr4,  
  customer_addr5, customer_addr6,      ship_to_addr1,  
         ship_to_addr2,       ship_to_addr3,       ship_to_addr4,  
  ship_to_addr5,       ship_to_addr6,       attention_name,  
        attention_phone,     amt_rem_rev,         amt_rem_tax,  
         date_recurring,      location_code, amt_discount_taken,  
         amt_write_off_given, source_trx_ctrl_num, source_trx_type,   
  nat_cur_code,  rate_type_home, rate_type_oper,    
  rate_home,  rate_oper,  edit_list_flag,  
  amt_tax_included, ddid,   writeoff_code,  
  vat_prc ,  org_id,  
  customer_city , customer_state , customer_postal_code,  customer_country_code,  
  ship_to_city,  ship_to_state,  ship_to_postal_code, ship_to_country_code  
 )  
 SELECT trx_ctrl_num,  doc_ctrl_num,  doc_desc,  
  apply_to_num,  apply_trx_type, order_ctrl_num,  
  batch_code,  trx_type,  date_entered,  
  date_applied,  date_doc,  date_shipped,  
  date_required, date_due,  date_aging,  
  customer_code, ship_to_code,  salesperson_code,  
  territory_code, comment_code,  fob_code,  
  freight_code,  terms_code,  fin_chg_code,  
  price_code,  dest_zone_code, posting_code,  
  recurring_flag, recurring_code, tax_code,  
  cust_po_num,  total_weight,  amt_gross,  
  amt_freight,  amt_tax,  amt_discount,  
  amt_net,  amt_paid,  amt_due,  
  amt_cost,  amt_profit,  next_serial_id,  
  printed_flag,  posted_flag,  hold_flag,  
  hold_desc,  user_id,  customer_addr1,  
  customer_addr2, customer_addr3, customer_addr4,    
  customer_addr5, customer_addr6, ship_to_addr1,  
  ship_to_addr2, ship_to_addr3, ship_to_addr4,  
  ship_to_addr5, ship_to_addr6, attention_name,  
  attention_phone, amt_rem_rev,  amt_rem_tax,  
  date_recurring, location_code, amt_discount_taken,  
  amt_write_off_given, source_trx_ctrl_num, source_trx_type,  
  nat_cur_code,  rate_type_home, rate_type_oper,    
  rate_home,  rate_oper,  edit_list_flag,  
  amt_tax_included, ddid,   writeoff_code,  
  vat_prc,  org_id,  
  customer_city , customer_state , customer_postal_code,  customer_country_code,  
  ship_to_city,  ship_to_state,  ship_to_postal_code, ship_to_country_code  
    
 FROM #arinpchg_work  
 WHERE db_action > 0  
 AND  db_action < 4  
  
 SELECT @status = @@error  
  
 IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, 'arinpchg.cpp', 134, 'insert arinpchg: insert action', @PERF_time_last OUTPUT  
END  
  
  
IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, 'arinpchg.cpp', 138, 'exit arinpchg_sp', @PERF_time_last OUTPUT  
  
RETURN @status  
  
GO
GRANT EXECUTE ON  [dbo].[arinpchg_sp] TO [public]
GO
