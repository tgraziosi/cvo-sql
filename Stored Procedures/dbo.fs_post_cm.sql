SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 20/06/2012 - Fix standard product 
  
  
CREATE PROCEDURE [dbo].[fs_post_cm] @process_ctrl_num varchar(16), @err1 INT OUT  
  
AS  
    
DECLARE @company_code varchar(8), @result int,   @debug_level smallint,   
 @batch_ctrl_num varchar(16), @perf_level smallint,  @only_error smallint,  @org_company varchar(8),  
 @rec_company varchar(8), @journal_ctrl_num varchar(16), @sequence_id int,  @settlement smallint,  
 @process_state smallint, @called_from  smallint,  @trx_ctrl_num varchar(16),  @next_num int,  
 @doc_ctrl_num varchar(16), @mask varchar(32),  @org_id varchar(30)  
  
SELECT  @company_code = company_code  
FROM  glco  
  
IF @@error != 0  
 RETURN @@error  
  
--SELECT  @org_id  = isnull((select value_str from config (nolock) where flag = 'INV_ORG_ID'),'')  
  
SELECT  @debug_level = 0,  @perf_level = 0,  @only_error = 1, @called_from = 0,   
 @org_company = @company_code, @rec_company = @company_code, @settlement = 1, @journal_ctrl_num = NULL,  
 @sequence_id = NULL,  @process_state = 3  
  
CREATE TABLE  #cminpdtl  ( timestamp  timestamp,   trx_type  smallint,   trx_ctrl_num  varchar(16),   
   doc_ctrl_num  varchar(16),  date_document  int,  description  varchar(40),   
   document1  varchar(40),  document2  varchar(40),   cash_acct_code  varchar(32),  
   amount_book  float,    reconciled_flag  smallint, closed_flag  smallint,  
   void_flag  smallint,   date_applied  int,  cleared_type    smallint,   
   apply_to_trx_num  varchar(16) NULL,  apply_to_trx_type smallint NULL, apply_to_doc_num varchar(16) NULL,  
   trx_state  smallint NULL,   mark_flag   smallint NULL, org_id    varchar(30) NULL  )   
  
CREATE UNIQUE CLUSTERED INDEX #cminpdtl_ind_0  ON #cminpdtl (trx_ctrl_num, doc_ctrl_num, trx_type, cash_acct_code )   
CREATE INDEX #cminpdtl_ind_1  ON #cminpdtl (cash_acct_code,trx_type,date_document,void_flag )       
  
CREATE TABLE #arinppyt ( trx_ctrl_num varchar(16), doc_ctrl_num varchar(16), trx_desc varchar(40),  
     batch_code varchar(16), trx_type smallint, non_ar_flag smallint, non_ar_doc_num varchar(16),   
    gl_acct_code varchar(32), date_entered int, date_applied int, date_doc int, customer_code varchar(8),  
    payment_code varchar(8), payment_type smallint, amt_payment float, amt_on_acct float, prompt1_inp varchar(30),  
    prompt2_inp varchar(30), prompt3_inp varchar(30), prompt4_inp varchar(30), deposit_num varchar(16),  
    bal_fwd_flag smallint, printed_flag smallint, posted_flag smallint, hold_flag smallint, wr_off_flag smallint,  
    on_acct_flag smallint, user_id smallint, max_wr_off float, days_past_due int, void_type smallint,  
    cash_acct_code varchar(32), origin_module_flag smallint NULL, process_group_num varchar(16) NULL,  
    trx_state smallint NULL, mark_flag smallint NULL, source_trx_ctrl_num varchar(16) NULL, source_trx_type smallint NULL,  
    nat_cur_code varchar(8), rate_type_home varchar(8), rate_type_oper varchar(8), rate_home float, rate_oper float,  
    amt_discount float NULL, reference_code varchar(32) NULL, org_id varchar(30 )  NULL  )   
CREATE UNIQUE INDEX #arinppyt_ind_0 ON #arinppyt ( trx_ctrl_num, trx_type )  
CREATE INDEX  #arinppyt_ind_1 ON #arinppyt (batch_code)    
  
CREATE TABLE #arinppdt ( trx_ctrl_num varchar(16), doc_ctrl_num varchar(16), sequence_id int, trx_type smallint,  
    apply_to_num varchar(16), apply_trx_type smallint, customer_code varchar(8), date_aging int, amt_applied float,  
    amt_disc_taken float, wr_off_flag smallint, amt_max_wr_off float, void_flag smallint, line_desc varchar(40),  
    sub_apply_num varchar(16), sub_apply_type smallint, amt_tot_chg float, amt_paid_to_date float, terms_code varchar(8),  
    posting_code varchar(8), date_doc int, amt_inv float, trx_state smallint NULL, mark_flag smallint NULL, gain_home float,  
    gain_oper float, inv_amt_applied float, inv_amt_disc_taken float, inv_amt_max_wr_off float, inv_cur_code varchar(8) , org_id varchar(30 )  NULL)  
CREATE UNIQUE INDEX arinppdt_ind_0 ON #arinppdt ( trx_ctrl_num, trx_type, sequence_id )        
  
CREATE TABLE #arpyerr ( trx_ctrl_num varchar(16), sequence_id int, error_code int )   
  
CREATE TABLE #arpybat ( date_applied int, process_group_num varchar(16), trx_type smallint, org_id varchar(30 )  )  
  
CREATE TABLE #gltrx( mark_flag        smallint NOT NULL, next_seq_id        int   NOT NULL,  
   trx_state        smallint NOT NULL, journal_type           varchar(8) NOT NULL,  
   journal_ctrl_num       varchar(16) NOT NULL, journal_description    varchar(30) NOT NULL,  
   date_entered      int  NOT NULL, date_applied           int  NOT NULL,  
   recurring_flag        smallint NOT NULL, repeating_flag        smallint NOT NULL,  
          reversing_flag        smallint NOT NULL, hold_flag              smallint NOT NULL,   
          posted_flag            smallint NOT NULL, date_posted            int NOT NULL,  
   source_batch_code      varchar(16) NOT NULL, process_group_num      varchar(16) NOT NULL,  
   batch_code             varchar(16) NOT NULL, type_flag        smallint NOT NULL,  
   intercompany_flag      smallint NOT NULL, company_code        varchar(8) NOT NULL,  
   app_id         smallint NOT NULL, home_cur_code  varchar(8) NOT NULL,  
   document_1  varchar(16) NOT NULL, trx_type  smallint NOT NULL,  
   user_id          smallint NOT NULL, source_company_code varchar(8) NOT NULL,  
   oper_cur_code           varchar(8) NOT NULL,  org_id     varchar(30)  NULL,     
   interbranch_flag  smallint )  
CREATE UNIQUE INDEX #gltrx_ind_0 ON #gltrx ( journal_ctrl_num )  
  
CREATE TABLE #gltrxdet(mark_flag  smallint NOT NULL,  
   trx_state  smallint NOT NULL,       journal_ctrl_num varchar(16) NOT NULL,  
          sequence_id  int NOT NULL,  rec_company_code varchar(8) NOT NULL,  
   company_id  smallint NOT NULL,       account_code  varchar(32) NOT NULL,  
   description             varchar(40) NOT NULL,       document_1  varchar(16) NOT NULL,  
          document_2  varchar(16) NOT NULL, reference_code  varchar(32) NOT NULL,   
   balance   float NOT NULL,  nat_balance  float NOT NULL,   
   nat_cur_code  varchar(8) NOT NULL, rate   float NOT NULL,  
          posted_flag  smallint NOT NULL,       date_posted  int NOT NULL,   
   trx_type  smallint NOT NULL, offset_flag  smallint NOT NULL,   
   seg1_code  varchar(32) NOT NULL, seg2_code  varchar(32) NOT NULL,   
   seg3_code  varchar(32) NOT NULL, seg4_code  varchar(32) NOT NULL,   
   seq_ref_id  int NOT NULL,  balance_oper  float NULL,   
   rate_oper  float NULL,   rate_type_home  varchar(8)  NULL,   
   rate_type_oper  varchar(8)  NULL,   org_id     varchar(30) NULL)  
CREATE INDEX #gltrxdet_ind_0 ON #gltrxdet ( journal_ctrl_num, sequence_id )  
CREATE INDEX #gltrxdet_ind_1 ON #gltrxdet ( journal_ctrl_num, account_code )  
   
CREATE TABLE #trxerror( journal_ctrl_num   varchar(16) NOT NULL, sequence_id    int NOT NULL, error_code    int NOT NULL)  
CREATE UNIQUE INDEX #trxerror_ind_0 ON #trxerror ( journal_ctrl_num, sequence_id, error_code )  
  
CREATE TABLE #batches ( date_applied  int NOT NULL, source_batch_code varchar(16) NOT NULL, org_id   varchar(30) NULL  )  
CREATE UNIQUE INDEX #batches_ind_0 ON    #batches ( date_applied,  source_batch_code )  
  
CREATE TABLE #offset_accts (  account_code varchar(32) NOT NULL,  org_code varchar(8) NOT NULL,  
     rec_code varchar(8) NOT NULL, sequence_id int  NOT NULL)  
  
  
CREATE TABLE #offsets (  
 journal_ctrl_num varchar(16) NOT NULL,  
 sequence_id  int NOT NULL,  
 company_code  varchar(8) NOT NULL,  
 company_id  smallint NOT NULL,  
 org_ic_acct    varchar(32) NOT NULL,  
 org_seg1_code  varchar(32) NOT NULL,  
 org_seg2_code  varchar(32) NOT NULL,  
 org_seg3_code  varchar(32) NOT NULL,  
 org_seg4_code  varchar(32) NOT NULL,  
 org_org_id  varchar(30) NOT NULL,  
 rec_ic_acct    varchar(32) NOT NULL,  
 rec_seg1_code  varchar(32) NOT NULL,  
 rec_seg2_code  varchar(32) NOT NULL,  
 rec_seg3_code  varchar(32) NOT NULL,  
 rec_seg4_code  varchar(32) NOT NULL,  
 rec_org_id  varchar(30) NOT NULL )  
  
 

EXEC @result = arinmkbt_sp @process_ctrl_num, @company_code, @debug_level  
if @result != 0   
   RETURN @result  
  
  
CREATE TABLE #deplock ( customer_code varchar(8), doc_ctrl_num varchar(16), trx_type smallint, lock_status smallint,  
    temp_flag smallint NULL )   
CREATE INDEX deplock_ind_0 ON #deplock( trx_type, doc_ctrl_num, customer_code )   
CREATE INDEX deplock_ind_1 ON #deplock( lock_status, doc_ctrl_num, trx_type, customer_code )   
CREATE TABLE #aractcus_work ( customer_code varchar(8), date_last_inv int NULL, date_last_cm int NULL,  
     date_last_adj int NULL, date_last_wr_off int NULL, date_last_pyt int NULL, date_last_nsf int NULL,   
    date_last_fin_chg int NULL, date_last_late_chg int NULL, date_last_comm int NULL, amt_last_inv float NULL,  
     amt_last_cm float NULL, amt_last_adj float NULL, amt_last_wr_off float NULL, amt_last_pyt float NULL,  
     amt_last_nsf float NULL, amt_last_fin_chg float NULL, amt_last_late_chg float NULL, amt_last_comm float NULL,  
     amt_age_bracket1 float NULL, amt_age_bracket2 float NULL, amt_age_bracket3 float NULL, amt_age_bracket4 float NULL,  
     amt_age_bracket5 float NULL, amt_age_bracket6 float NULL, amt_on_order float NULL, amt_inv_unposted float NULL,  
     last_inv_doc varchar(16) NULL, last_cm_doc varchar(16) NULL, last_adj_doc varchar(16) NULL,  
     last_wr_off_doc varchar(16) NULL, last_pyt_doc varchar(16) NULL, last_nsf_doc varchar(16) NULL,  
     last_fin_chg_doc varchar(16) NULL, last_late_chg_doc varchar(16) NULL, high_amt_ar float NULL,  
     high_amt_inv float NULL, high_date_ar int NULL, high_date_inv int NULL, num_inv int NULL, num_inv_paid int NULL,  
    num_overdue_pyt int NULL, avg_days_pay int NULL, avg_days_overdue int NULL, last_trx_time int NULL,  
     amt_balance float NULL, amt_on_acct float NULL, sum_days_overdue int NULL, sum_days_to_pay_off int NULL,  
     amt_age_b1_oper float NULL, amt_age_b2_oper float NULL, amt_age_b3_oper float NULL, amt_age_b4_oper float NULL,  
     amt_age_b5_oper float NULL, amt_age_b6_oper float NULL, amt_on_order_oper float NULL, amt_inv_unp_oper float NULL,  
    high_amt_ar_oper float NULL, high_amt_inv_oper float NULL, amt_balance_oper float NULL, amt_on_acct_oper float NULL,   
    last_inv_cur varchar(8) NULL, last_cm_cur varchar(8) NULL, last_adj_cur varchar(8) NULL, last_wr_off_cur varchar(8) NULL,   
    last_pyt_cur varchar(8) NULL, last_nsf_cur varchar(8) NULL, last_fin_chg_cur varchar(8) NULL,  
     last_late_chg_cur varchar(8) NULL, update_flag smallint NULL )   
CREATE INDEX aractcus_work_ind_0 ON #aractcus_work ( customer_code )   
  
CREATE TABLE #aractprc_work ( price_code varchar(8), date_last_inv int NULL, date_last_cm int NULL,  
     date_last_adj int NULL, date_last_wr_off int NULL, date_last_pyt int NULL, date_last_nsf int NULL,  
     date_last_fin_chg int NULL, date_last_late_chg int NULL, date_last_comm int NULL, amt_last_inv float NULL,   
    amt_last_cm float NULL, amt_last_adj float NULL, amt_last_wr_off float NULL, amt_last_pyt float NULL,  
     amt_last_nsf float NULL, amt_last_fin_chg float NULL, amt_last_late_chg float NULL, amt_last_comm float NULL,  
     amt_age_bracket1 float NULL, amt_age_bracket2 float NULL, amt_age_bracket3 float NULL, amt_age_bracket4 float NULL,   
    amt_age_bracket5 float NULL, amt_age_bracket6 float NULL, amt_on_order float NULL, amt_inv_unposted float NULL,  
     last_inv_doc varchar(16) NULL, last_cm_doc varchar(16) NULL, last_adj_doc varchar(16) NULL,  
     last_wr_off_doc varchar(16) NULL, last_pyt_doc varchar(16)NULL, last_nsf_doc varchar(16) NULL,  
     last_fin_chg_doc varchar(16) NULL, last_late_chg_doc varchar(16) NULL, high_amt_ar float NULL,  
     high_amt_inv float NULL, high_date_ar int NULL, high_date_inv int NULL, num_inv int NULL, num_inv_paid int NULL,  
     num_overdue_pyt int NULL, avg_days_pay int NULL, avg_days_overdue int NULL, last_trx_time int NULL,  
     sum_days_overdue int NULL, sum_days_to_pay_off int NULL, amt_balance float NULL, amt_age_b1_oper float NULL,  
     amt_age_b2_oper float NULL, amt_age_b3_oper float NULL, amt_age_b4_oper float NULL, amt_age_b5_oper float NULL,  
     amt_age_b6_oper float NULL, amt_on_order_oper float NULL, amt_inv_unp_oper float NULL, high_amt_ar_oper float NULL,  
     high_amt_inv_oper float NULL, amt_balance_oper float NULL, last_inv_cur varchar(8) NULL, last_cm_cur varchar(8) NULL,  
     last_adj_cur varchar(8) NULL, last_wr_off_cur varchar(8) NULL, last_pyt_cur varchar(8) NULL, last_nsf_cur varchar(8) NULL,  
     last_fin_chg_cur varchar(8) NULL, last_late_chg_cur varchar(8) NULL, update_flag smallint NULL )   
CREATE INDEX #aractprc_work_ind_0 ON #aractprc_work ( price_code )   
  
CREATE TABLE #aractshp_work ( customer_code varchar(8), ship_to_code varchar(8), date_last_inv int NULL,  
     date_last_cm int NULL, date_last_adj int NULL, date_last_wr_off int NULL, date_last_pyt int NULL,   
    date_last_nsf int NULL, date_last_fin_chg int NULL, date_last_late_chg int NULL, date_last_comm int NULL,  
     amt_last_inv float NULL, amt_last_cm float NULL, amt_last_adj float NULL, amt_last_wr_off float NULL,  
     amt_last_pyt float NULL, amt_last_nsf float NULL, amt_last_fin_chg float NULL, amt_last_late_chg float NULL,  
     amt_last_comm float NULL, amt_age_bracket1 float NULL, amt_age_bracket2 float NULL, amt_age_bracket3 float NULL,  
     amt_age_bracket4 float NULL, amt_age_bracket5 float NULL, amt_age_bracket6 float NULL, amt_on_order float NULL,  
     amt_inv_unposted float NULL, last_inv_doc varchar(16) NULL, last_cm_doc varchar(16) NULL, last_adj_doc varchar(16) NULL,  
     last_wr_off_doc varchar(16) NULL, last_pyt_doc varchar(16) NULL, last_nsf_doc varchar(16) NULL,  
     last_fin_chg_doc varchar(16) NULL, last_late_chg_doc varchar(16) NULL, high_amt_ar float NULL, high_amt_inv float NULL,  
     high_date_ar int NULL, high_date_inv int NULL, num_inv int NULL, num_inv_paid int NULL, num_overdue_pyt int NULL,  
     avg_days_pay int NULL, avg_days_overdue int NULL, last_trx_time int NULL, sum_days_overdue int NULL,  
     sum_days_to_pay_off int NULL, amt_balance float NULL, amt_age_b1_oper float NULL, amt_age_b2_oper float NULL,  
     amt_age_b3_oper float NULL, amt_age_b4_oper float NULL, amt_age_b5_oper float NULL, amt_age_b6_oper float NULL,  
     amt_on_order_oper float NULL, amt_inv_unp_oper float NULL, high_amt_ar_oper float NULL, high_amt_inv_oper float NULL,  
     amt_balance_oper float NULL, last_inv_cur varchar(8) NULL, last_cm_cur varchar(8) NULL, last_adj_cur varchar(8) NULL,  
     last_wr_off_cur varchar(8) NULL, last_pyt_cur varchar(8) NULL, last_nsf_cur varchar(8) NULL,   
    last_fin_chg_cur varchar(8) NULL, last_late_chg_cur varchar(8) NULL, update_flag smallint NULL )  
CREATE INDEX aractshp_work_ind_0 ON #aractshp_work ( customer_code, ship_to_code )   
   
CREATE TABLE #aractslp_work ( salesperson_code varchar(8), date_last_inv int NULL, date_last_cm int NULL,  
     date_last_adj int NULL, date_last_wr_off int NULL, date_last_pyt int NULL, date_last_nsf int NULL,  
     date_last_fin_chg int NULL, date_last_late_chg int NULL, date_last_comm int NULL, amt_last_inv float NULL,  
     amt_last_cm float NULL, amt_last_adj float NULL, amt_last_wr_off float NULL, amt_last_pyt float NULL,  
     amt_last_nsf float NULL, amt_last_fin_chg float NULL, amt_last_late_chg float NULL, amt_last_comm float NULL,  
     amt_age_bracket1 float NULL, amt_age_bracket2 float NULL, amt_age_bracket3 float NULL, amt_age_bracket4 float NULL,  
     amt_age_bracket5 float NULL, amt_age_bracket6 float NULL, amt_on_order float NULL, amt_inv_unposted float NULL,   
    last_inv_doc varchar(16) NULL, last_cm_doc varchar(16) NULL, last_adj_doc varchar(16) NULL,   
    last_wr_off_doc varchar(16) NULL, last_pyt_doc varchar(16) NULL, last_nsf_doc varchar(16) NULL,  
     last_fin_chg_doc varchar(16) NULL, last_late_chg_doc varchar(16) NULL, high_amt_ar float NULL,  
     high_amt_inv float NULL, high_date_ar int NULL,high_date_inv int NULL, num_inv int NULL, num_inv_paid int NULL,  
     num_overdue_pyt int NULL, avg_days_pay int NULL, avg_days_overdue int NULL, last_trx_time int NULL,  
     sum_days_overdue int NULL, sum_days_to_pay_off int NULL, amt_balance float NULL, amt_age_b1_oper float NULL,  
     amt_age_b2_oper float NULL, amt_age_b3_oper float NULL, amt_age_b4_oper float NULL, amt_age_b5_oper float NULL,  
     amt_age_b6_oper float NULL, amt_on_order_oper float NULL, amt_inv_unp_oper float NULL, high_amt_ar_oper float NULL,  
    high_amt_inv_oper float NULL, amt_balance_oper float NULL, last_inv_cur varchar(8) NULL, last_cm_cur varchar(8) NULL,  
    last_adj_cur varchar(8) NULL, last_wr_off_cur varchar(8) NULL, last_pyt_cur varchar(8) NULL,  
     last_nsf_cur varchar(8) NULL, last_fin_chg_cur varchar(8) NULL, last_late_chg_cur varchar(8) NULL, update_flag smallint NULL )   
CREATE INDEX aractslp_work_ind_0 ON #aractslp_work ( salesperson_code )   
   
CREATE TABLE #aractter_work ( territory_code varchar(8), date_last_inv int NULL, date_last_cm int NULL,  
     date_last_adj int NULL, date_last_wr_off int NULL, date_last_pyt int NULL, date_last_nsf int NULL,  
     date_last_fin_chg int NULL, date_last_late_chg int NULL, date_last_comm int NULL, amt_last_inv float NULL,  
     amt_last_cm float NULL, amt_last_adj float NULL, amt_last_wr_off float NULL, amt_last_pyt float NULL,   
    amt_last_nsf float NULL, amt_last_fin_chg float NULL, amt_last_late_chg float NULL, amt_last_comm float NULL,  
    amt_age_bracket1 float NULL, amt_age_bracket2 float NULL, amt_age_bracket3 float NULL,   
    amt_age_bracket4 float NULL, amt_age_bracket5 float NULL, amt_age_bracket6 float NULL, amt_on_order float NULL,   
    amt_inv_unposted float NULL, last_inv_doc varchar(16) NULL, last_cm_doc varchar(16) NULL, last_adj_doc varchar(16) NULL, last_wr_off_doc varchar(16) NULL, last_pyt_doc varchar(16) NULL,   
    last_nsf_doc varchar(16) NULL, last_fin_chg_doc varchar(16) NULL, last_late_chg_doc varchar(16) NULL,  
     high_amt_ar float NULL, high_amt_inv float NULL, high_date_ar int NULL, high_date_inv int NULL, num_inv int NULL,   
    num_inv_paid int NULL, num_overdue_pyt int NULL, avg_days_pay int NULL, avg_days_overdue int NULL, last_trx_time int NULL,  
     sum_days_overdue int NULL, sum_days_to_pay_off int NULL, amt_balance float NULL, amt_age_b1_oper float NULL,   
    amt_age_b2_oper float NULL, amt_age_b3_oper float NULL, amt_age_b4_oper float NULL, amt_age_b5_oper float NULL,   
    amt_age_b6_oper float NULL, amt_on_order_oper float NULL, amt_inv_unp_oper float NULL, high_amt_ar_oper float NULL,   
    high_amt_inv_oper float NULL, amt_balance_oper float NULL, last_inv_cur varchar(8) NULL, last_cm_cur varchar(8) NULL,   
    last_adj_cur varchar(8) NULL, last_wr_off_cur varchar(8) NULL, last_pyt_cur varchar(8) NULL, last_nsf_cur varchar(8) NULL,  
     last_fin_chg_cur varchar(8) NULL, last_late_chg_cur varchar(8) NULL, update_flag smallint NULL )  
CREATE INDEX #aractter_work_ind_0 ON #aractter_work ( territory_code )   
   
CREATE TABLE #arinpcdt_work ( trx_ctrl_num varchar(16), doc_ctrl_num varchar(16), sequence_id int, trx_type smallint, location_code varchar(8),   
    item_code varchar(30),bulk_flag smallint, date_entered int, line_desc varchar(60), qty_ordered float,  
    qty_shipped float, unit_code varchar(8), unit_price float,unit_cost float, extended_price float,  
     weight float, serial_id int, tax_code varchar(8), gl_rev_acct varchar(32), disc_prc_flag smallint,  
     discount_amt float, discount_prc float, commission_flag smallint, rma_num varchar(16),  
     return_code varchar(8), qty_returned float, qty_prev_returned float, new_gl_rev_acct varchar(32),  
     iv_post_flag smallint, oe_orig_flag smallint, calc_tax float, reference_code varchar(32) NULL,  
     new_reference_code varchar(32) NULL, db_action smallint, cust_po varchar(20) NULL, org_id varchar(30) NULL   )   
CREATE INDEX #arinpcdt_work_ind_0 ON #arinpcdt_work ( trx_ctrl_num )   
  
 CREATE TABLE #arinpchg_work ( trx_ctrl_num varchar(16), doc_ctrl_num varchar(16), doc_desc varchar(40),   
    apply_to_num varchar(16), apply_trx_type smallint, order_ctrl_num varchar(16), batch_code varchar(16),   
    trx_type smallint, date_entered int, date_applied int, date_doc int, date_shipped int, date_required int,  
     date_due int, date_aging int, customer_code varchar(8), ship_to_code varchar(8), salesperson_code varchar(8),  
     territory_code varchar(8), comment_code varchar(8), fob_code varchar(8), freight_code varchar(8), terms_code varchar(8),  
     fin_chg_code varchar(8), price_code varchar(8), dest_zone_code varchar(8), posting_code varchar(8),  
     recurring_flag smallint, recurring_code varchar(8), tax_code varchar(8), cust_po_num varchar(20), total_weight float,  
     amt_gross float, amt_freight float, amt_tax float, amt_tax_included float, amt_discount float, amt_net float,  
     amt_paid float, amt_due float, amt_cost float, amt_profit float, next_serial_id smallint, printed_flag smallint,  
     posted_flag smallint, hold_flag smallint, hold_desc varchar(40), user_id smallint, customer_addr1 varchar(40),   
    customer_addr2 varchar(40), customer_addr3 varchar(40), customer_addr4 varchar(40), customer_addr5 varchar(40),   
    customer_addr6 varchar(40), ship_to_addr1 varchar(40), ship_to_addr2 varchar(40), ship_to_addr3 varchar(40),   
    ship_to_addr4 varchar(40), ship_to_addr5 varchar(40), ship_to_addr6 varchar(40), attention_name varchar(40),  
     attention_phone varchar(30), amt_rem_rev float, amt_rem_tax float, date_recurring int, location_code varchar(8),  
     process_group_num varchar(16) NULL, source_trx_ctrl_num varchar(16) NULL, source_trx_type smallint NULL,  
    amt_discount_taken float NULL, amt_write_off_given float  NULL, nat_cur_code varchar(8), rate_type_home varchar(8),  
    rate_type_oper varchar(8), rate_home float, rate_oper float, edit_list_flag smallint,   
    db_action smallint, ddid   varchar(32) NULL, writeoff_code     varchar(8) NULL, vat_prc      float NULL, org_id varchar(30) NULL,
    customer_country_code varchar(3) NULL,  
    customer_city varchar(40) NULL,  
    customer_state varchar(40) NULL,  
    customer_postal_code varchar(15) NULL,  
    ship_to_country_code varchar(3) NULL,  
    ship_to_city varchar(40) NULL,  
    ship_to_state varchar(40) NULL,  
    ship_to_postal_code varchar(15) NULL )   
CREATE INDEX #arinpchg_work_ind_0 ON #arinpchg_work(trx_ctrl_num, trx_type, batch_code, apply_to_num )  
CREATE INDEX #arinpchg_work_ind_1 ON #arinpchg_work(apply_to_num, batch_code, apply_trx_type )  
CREATE INDEX #arinpchg_work_ind_2 ON #arinpchg_work(posting_code, batch_code )   
  
CREATE TABLE #arinpcom_work ( trx_ctrl_num varchar(16), trx_type smallint, sequence_id int, salesperson_code varchar(8),  
     amt_commission float, percent_flag smallint, exclusive_flag smallint, split_flag smallint, db_action smallint )   
CREATE INDEX arinpcom_work_ind_0 ON #arinpcom_work (trx_ctrl_num, trx_type, sequence_id )   
CREATE TABLE #arinptax_work ( trx_ctrl_num varchar(16), trx_type smallint, sequence_id int, tax_type_code varchar(8),  
         amt_taxable float, amt_gross float, amt_tax float, amt_final_tax float, db_action smallint )  
CREATE INDEX arinptax_work_ind_0 ON #arinptax_work (trx_ctrl_num, trx_type, sequence_id)  
CREATE INDEX #arinptax_work_ind_1 ON #arinptax_work ( trx_ctrl_num )   
  
CREATE TABLE #arsumcus_work ( customer_code varchar(8), date_from int NULL, date_thru int, num_inv int NULL,  
     num_inv_paid int NULL, num_cm int NULL, num_adj int NULL, num_wr_off int NULL, num_pyt int NULL,  
     num_overdue_pyt int NULL, num_nsf int NULL, num_fin_chg int NULL, num_late_chg int NULL, amt_inv float NULL,   
    amt_cm float NULL, amt_adj float NULL, amt_wr_off float NULL, amt_pyt float NULL, amt_nsf float NULL,   
    amt_fin_chg float NULL, amt_late_chg float NULL, amt_profit float NULL, prc_profit float NULL,   
    amt_comm float NULL, amt_disc_given float NULL, amt_disc_taken float NULL, amt_disc_lost float NULL,   
    amt_freight float NULL, amt_tax float NULL, avg_days_pay int NULL, avg_days_overdue int NULL, last_trx_time int NULL,  
     sum_days_overdue int NULL, sum_days_to_pay_off int NULL, amt_inv_oper float NULL, amt_cm_oper float NULL,  
     amt_adj_oper float NULL, amt_wr_off_oper float NULL, amt_pyt_oper float NULL, amt_nsf_oper float NULL,  
     amt_fin_chg_oper float NULL, amt_late_chg_oper float NULL, amt_disc_g_oper float NULL, amt_disc_t_oper float NULL,  
     amt_freight_oper float NULL, amt_tax_oper float NULL, update_flag smallint NULL )   
CREATE INDEX #arsumcus_work_ind_0 ON #arsumcus_work ( customer_code, date_thru )   
  
CREATE TABLE #arsumprc_work ( price_code varchar(8), date_from int NULL, date_thru int, num_inv int NULL,  
     num_inv_paid int NULL, num_cm int NULL, num_adj int NULL, num_wr_off int NULL, num_pyt int NULL, num_overdue_pyt int NULL,  
     num_nsf int NULL, num_fin_chg int NULL, num_late_chg int NULL, amt_inv float NULL, amt_cm float NULL, amt_adj float NULL,  
     amt_wr_off float NULL, amt_pyt float NULL, amt_nsf float NULL, amt_fin_chg float NULL, amt_late_chg float NULL,   
    amt_profit float NULL, prc_profit float NULL, amt_comm float NULL, amt_disc_given float NULL, amt_disc_taken float NULL,   
    amt_disc_lost float NULL, amt_freight float NULL, amt_tax float NULL, avg_days_pay int NULL, avg_days_overdue int NULL,   
    last_trx_time int NULL, sum_days_overdue int NULL, sum_days_to_pay_off int NULL, amt_inv_oper float NULL,  
    amt_cm_oper float NULL, amt_adj_oper float NULL, amt_wr_off_oper float NULL, amt_pyt_oper float NULL,   
    amt_nsf_oper float NULL, amt_fin_chg_oper float NULL, amt_late_chg_oper float NULL, amt_disc_g_oper float NULL,  
    amt_disc_t_oper float NULL, amt_freight_oper float NULL, amt_tax_oper float NULL, update_flag smallint NULL )  
CREATE INDEX arsumprc_work_ind_0 ON #arsumprc_work(price_code, date_thru)  
  
CREATE TABLE #arsumshp_work ( customer_code varchar(8), ship_to_code varchar(8), date_from int NULL, date_thru int NULL,  
     num_inv int NULL, num_inv_paid int NULL, num_cm int NULL, num_adj int NULL, num_wr_off int NULL,   
    num_pyt int NULL, num_overdue_pyt int NULL, num_nsf int NULL, num_late_chg int NULL, num_fin_chg int NULL,  
     amt_inv float NULL, amt_cm float NULL, amt_adj float NULL, amt_wr_off float NULL, amt_pyt float NULL, amt_nsf float NULL,  
     amt_late_chg float NULL, amt_fin_chg float NULL, amt_profit float NULL, prc_profit float NULL, amt_comm float NULL,   
    amt_disc_given float NULL, amt_disc_taken float NULL, amt_disc_lost float NULL, amt_freight float NULL, amt_tax float NULL,  
     avg_days_pay int NULL, avg_days_overdue int NULL, last_trx_time int NULL, sum_days_overdue int NULL,  
     sum_days_to_pay_off int NULL, amt_inv_oper float NULL, amt_cm_oper float NULL, amt_adj_oper float NULL,  
     amt_wr_off_oper float NULL, amt_pyt_oper float NULL, amt_nsf_oper float NULL, amt_fin_chg_oper float NULL,   
    amt_late_chg_oper float NULL, amt_disc_g_oper float NULL, amt_disc_t_oper float NULL, amt_freight_oper float NULL,  
     amt_tax_oper float NULL, update_flag smallint NULL )  
CREATE INDEX arsumshp_work_ind_0 ON #arsumshp_work ( customer_code, ship_to_code, date_thru )  
   
CREATE TABLE #arsumslp_work ( salesperson_code varchar(8), date_from int NULL, date_thru int NULL, num_inv int NULL,  
     num_inv_paid int NULL, num_cm int NULL, num_adj int NULL, num_wr_off int NULL, num_pyt int NULL, num_overdue_pyt int NULL,  
      num_nsf int NULL, num_fin_chg int NULL, num_late_chg int NULL, amt_inv float NULL, amt_cm float NULL, amt_adj float NULL,  
      amt_wr_off float NULL, amt_pyt float NULL, amt_nsf float NULL, amt_fin_chg float NULL, amt_late_chg float NULL,  
      amt_profit float NULL, prc_profit float NULL, amt_comm float NULL, amt_disc_given float NULL, amt_disc_taken float NULL,   
     amt_disc_lost float NULL, amt_freight float NULL, amt_tax float NULL, avg_days_pay int NULL, avg_days_overdue int NULL,   
     last_trx_time int NULL, sum_days_overdue int NULL, sum_days_to_pay_off int NULL, amt_inv_oper float NULL,  
      amt_cm_oper float NULL, amt_adj_oper float NULL, amt_wr_off_oper float NULL, amt_pyt_oper float NULL,   
     amt_nsf_oper float NULL, amt_fin_chg_oper float NULL, amt_late_chg_oper float NULL, amt_disc_g_oper float NULL,  
     amt_disc_t_oper float NULL, amt_freight_oper float NULL, amt_tax_oper float NULL, update_flag smallint NULL )   
CREATE INDEX #arsumslp_work_ind_0 ON #arsumslp_work ( salesperson_code, date_thru )    
  
CREATE TABLE #arsumter_work ( territory_code varchar(8), date_from int NULL, date_thru int, num_inv int NULL,  
     num_inv_paid int NULL, num_cm int NULL, num_adj int NULL, num_wr_off int NULL, num_pyt int NULL, num_overdue_pyt int NULL,  
     num_nsf int NULL, num_fin_chg int NULL, num_late_chg int NULL, amt_inv float NULL, amt_cm float NULL,   
    amt_adj float NULL, amt_wr_off float NULL, amt_pyt float NULL, amt_nsf float NULL, amt_fin_chg float NULL,  
     amt_late_chg float NULL, amt_profit float NULL, prc_profit float NULL, amt_comm float NULL, amt_disc_given float NULL,  
     amt_disc_taken float NULL, amt_disc_lost float NULL, amt_freight float NULL, amt_tax float NULL, avg_days_pay int NULL,  
     avg_days_overdue int NULL, last_trx_time int NULL, sum_days_overdue int NULL, sum_days_to_pay_off int NULL,   
    amt_inv_oper float NULL, amt_cm_oper float NULL, amt_adj_oper float NULL, amt_wr_off_oper float NULL,  
     amt_pyt_oper float NULL, amt_nsf_oper float NULL, amt_fin_chg_oper float NULL, amt_late_chg_oper float NULL,  
     amt_disc_g_oper float NULL, amt_disc_t_oper float NULL, amt_freight_oper float NULL, amt_tax_oper float NULL,   
    update_flag smallint NULL )   
CREATE INDEX arsumter_work_ind_0 ON #arsumter_work ( territory_code, date_thru )   
  
CREATE TABLE #artrx_work ( doc_ctrl_num varchar(16), trx_ctrl_num varchar(16), apply_to_num varchar(16),  
     apply_trx_type smallint, order_ctrl_num varchar(16), doc_desc varchar(40), batch_code varchar(16), trx_type smallint,   
    date_entered int, date_posted int, date_applied int, date_doc int, date_shipped int, date_required int, date_due int,   
    date_aging int, customer_code varchar(8), ship_to_code varchar(8), salesperson_code varchar(8),   
    territory_code varchar(8), comment_code varchar(8), fob_code varchar(8), freight_code varchar(8), terms_code varchar(8),  
     fin_chg_code varchar(8), price_code varchar(8), dest_zone_code varchar(8), posting_code varchar(8),   
    recurring_flag smallint, recurring_code varchar(8), tax_code varchar(8), payment_code varchar(8), payment_type smallint,   
    cust_po_num varchar(20), non_ar_flag smallint, gl_acct_code varchar(32), gl_trx_id varchar(16), prompt1_inp varchar(30),  
     prompt2_inp varchar(30), prompt3_inp varchar(30), prompt4_inp varchar(30), deposit_num varchar(16), amt_gross float,  
     amt_freight float, amt_tax float, amt_tax_included float, amt_discount float, amt_paid_to_date float, amt_net float,  
     amt_on_acct float, amt_cost float, amt_tot_chg float, amt_discount_taken float NULL, amt_write_off_given float NULL,  
     user_id smallint, void_flag smallint, paid_flag smallint, date_paid int, posted_flag smallint, commission_flag smallint,  
     cash_acct_code varchar(32), non_ar_doc_num varchar(16), purge_flag smallint NULL, process_group_num varchar(16) NULL,  
     temp_flag smallint NULL, source_trx_ctrl_num varchar(16) NULL, source_trx_type smallint NULL, nat_cur_code varchar(8),   
    rate_type_home varchar(8), rate_type_oper varchar(8), rate_home float, rate_oper float, reference_code varchar(32) NULL,   
    db_action smallint, org_id varchar(30) NULL  )   
CREATE INDEX artrx_work_ind_0 ON #artrx_work( doc_ctrl_num, trx_type, customer_code, payment_type, void_flag )  
CREATE INDEX artrx_work_ind_1 ON #artrx_work( apply_to_num, apply_trx_type, doc_ctrl_num, trx_type, customer_code )   
CREATE INDEX #artrx_work_ind_2 ON #artrx_work ( customer_code, trx_ctrl_num )  
CREATE TABLE #artrxage_work ( trx_ctrl_num varchar(16), trx_type smallint, ref_id int, doc_ctrl_num varchar(16),  
     order_ctrl_num varchar(16), cust_po_num varchar(20), apply_to_num varchar(16), apply_trx_type smallint,  
     sub_apply_num varchar(16), sub_apply_type smallint, date_doc int, date_due int, date_applied int, date_aging int,   
    customer_code varchar(8), payer_cust_code varchar(8), salesperson_code varchar(8), territory_code varchar(8),  
     price_code varchar(8), amount float, paid_flag smallint, group_id int, amt_fin_chg float, amt_late_chg float,  
     amt_paid float, db_action smallint, rate_home float, rate_oper float, nat_cur_code varchar(8), true_amount float,  
    date_paid int, journal_ctrl_num varchar(16), account_code varchar(32), org_id varchar(30) NULL  )  
CREATE INDEX artrxage_work_ind_0 ON #artrxage_work ( customer_code, trx_type, apply_trx_type, apply_to_num,doc_ctrl_num, date_aging )   
CREATE INDEX artrxage_work_ind_1 ON #artrxage_work ( doc_ctrl_num, trx_type, date_aging, customer_code )  
CREATE INDEX artrxage_work_ind_2 ON #artrxage_work ( doc_ctrl_num, customer_code, ref_id, trx_type )   
CREATE INDEX #artrxage_work_ind_3 ON #artrxage_work (customer_code, doc_ctrl_num, trx_type )   
CREATE INDEX #artrxage_work_ind_4 ON #artrxage_work (apply_to_num, apply_trx_type )   
  
CREATE TABLE #artrxcdt_work ( doc_ctrl_num varchar(16), trx_ctrl_num varchar(16), sequence_id int, trx_type smallint,  
     location_code varchar(8), item_code varchar(30), bulk_flag smallint, date_entered int, date_posted int, date_applied int,  
     line_desc varchar(60), qty_ordered float, qty_shipped float, unit_code varchar(8), unit_price float, weight float,  
     amt_cost float, serial_id int, tax_code varchar(8), gl_rev_acct varchar(32), discount_prc float, discount_amt float,   
    rma_num varchar(16), return_code varchar(8), qty_returned float, new_gl_rev_acct varchar(32), disc_prc_flag smallint,  
     extended_price float, calc_tax float, reference_code varchar(32) NULL, new_reference_code varchar(32) NULL, db_action smallint,  
    cust_po varchar(20) NULL, org_id varchar(30) NULL  )   
CREATE INDEX artrxcdt_work_ind_0 ON #artrxcdt_work (doc_ctrl_num,trx_type,sequence_id)   
CREATE INDEX artrxcdt_work_ind_1 ON #artrxcdt_work (item_code,location_code,bulk_flag)   
CREATE INDEX #artrxcdt_work_ind_2 ON #artrxcdt_work ( trx_ctrl_num )   
  
CREATE TABLE #artrxcom_work ( trx_ctrl_num varchar(16), trx_type smallint, doc_ctrl_num varchar(16), sequence_id int,  
     salesperson_code varchar(8), amt_commission float, percent_flag smallint, exclusive_flag smallint, split_flag smallint,  
     commission_flag smallint, db_action smallint )  
CREATE INDEX artrxcom_work_ind_0 ON #artrxcom_work ( trx_ctrl_num, sequence_id )  
CREATE INDEX artrxcom_work_ind_1 ON #artrxcom_work (salesperson_code)    
  
CREATE TABLE #artrxtax_work ( tax_type_code varchar(8), doc_ctrl_num varchar(16), trx_type smallint,  
     date_applied int, date_doc int, amt_gross float, amt_taxable float, amt_tax float, db_action smallint )   
CREATE UNIQUE INDEX #artrxtax_work_ind_0 ON #artrxtax_work (tax_type_code, doc_ctrl_num, trx_type)   
CREATE INDEX #artrxtax_work_ind_1 ON #artrxtax_work ( doc_ctrl_num )   
  
CREATE TABLE #artrxxtr_work ( rec_set smallint, amt_due float, amt_paid float, trx_type smallint,  
     trx_ctrl_num varchar(16), addr1 varchar(40) NULL, addr2 varchar(40) NULL, addr3 varchar(40) NULL,  
     addr4 varchar(40) NULL, addr5 varchar(40) NULL, addr6 varchar(40) NULL, ship_addr1 varchar(40) NULL,  
     ship_addr2 varchar(40) NULL, ship_addr3 varchar(40) NULL, ship_addr4 varchar(40) NULL, ship_addr5 varchar(40) NULL,  
     ship_addr6 varchar(40) NULL, attention_name varchar(40) NULL, attention_phone varchar(30) NULL, db_action smallint,  
    customer_country_code varchar(3) NULL,  
    customer_city varchar(40) NULL,  
    customer_state varchar(40) NULL,  
    customer_postal_code varchar(15) NULL,  
    ship_to_country_code varchar(3) NULL,  
    ship_to_city varchar(40) NULL,  
    ship_to_state varchar(40) NULL,  
    ship_to_postal_code varchar(15) NULL )   
CREATE UNIQUE INDEX artrxxtr_work_ind_0 ON #artrxxtr_work ( trx_type, trx_ctrl_num)  
CREATE INDEX #artrxxtr_work_ind_1 ON #artrxxtr_work ( trx_ctrl_num )   
  
CREATE TABLE #arinppdt_work ( trx_ctrl_num varchar(16), doc_ctrl_num varchar(16), sequence_id int,  
     trx_type smallint, apply_to_num varchar(16), apply_trx_type smallint, customer_code varchar(8),       payer_cust_code varchar(8) NULL, date_aging int, amt_applied float, amt_disc_taken float,   
    wr_off_flag smallint, amt_max_wr_off float, void_flag smallint, line_desc varchar(40), sub_apply_num varchar(16),  
     sub_apply_type smallint, amt_tot_chg float, amt_paid_to_date float, terms_code varchar(8), posting_code varchar(8),   
    date_doc int, amt_inv float, gain_home float, gain_oper float, inv_amt_applied float, inv_amt_disc_taken float,  
     inv_amt_max_wr_off float, inv_cur_code varchar(8), writeoff_code varchar(8), db_action smallint, temp_flag smallint NULL, org_id varchar(30) NULL  )   
CREATE INDEX arinppdt_work_ind_0 ON #arinppdt_work(apply_to_num, apply_trx_type, trx_ctrl_num, trx_type)  
CREATE INDEX arinppdt_work_ind_1 ON #arinppdt_work(trx_ctrl_num, trx_type, sequence_id)   
CREATE INDEX arinppdt_work_ind_2 ON #arinppdt_work(doc_ctrl_num, trx_type, sequence_id)   
CREATE INDEX #arinppdt_work_ind_3 ON #arinppdt_work (trx_ctrl_num)   
   
CREATE TABLE #arinppyt_work ( trx_ctrl_num varchar(16), doc_ctrl_num varchar(16), trx_desc varchar(40),   
    batch_code varchar(16), trx_type smallint, non_ar_flag smallint, non_ar_doc_num varchar(16), gl_acct_code varchar(32),  
     date_entered int, date_applied int, date_doc int, customer_code varchar(8), payment_code varchar(8), payment_type smallint,  
     amt_payment float, amt_on_acct float, prompt1_inp varchar(30), prompt2_inp varchar(30), prompt3_inp varchar(30),   
    prompt4_inp varchar(30), deposit_num varchar(16), bal_fwd_flag smallint, printed_flag smallint, posted_flag smallint,  
     hold_flag smallint, wr_off_flag smallint, on_acct_flag smallint,  
     user_id smallint, max_wr_off float, days_past_due int, void_type smallint,   
    cash_acct_code varchar(32), origin_module_flag smallint NULL, db_action smallint, process_group_num varchar(16) NULL,  
     temp_flag smallint NULL, source_trx_ctrl_num varchar(16) NULL, source_trx_type smallint NULL, nat_cur_code varchar(8),  
     rate_type_home varchar(8), rate_type_oper varchar(8), rate_home float, rate_oper float, amt_discount float NULL,  
     reference_code varchar(32) NULL, settlement_ctrl_num varchar(16) NULL, org_id varchar(30) NULL  )  
CREATE INDEX arinppyt_work_ind_0 ON #arinppyt_work( trx_ctrl_num, trx_type, customer_code )   
CREATE INDEX arinppyt_work_ind_1 ON #arinppyt_work( batch_code, trx_ctrl_num )  
CREATE INDEX arinppyt_work_ind_2 ON #arinppyt_work( cash_acct_code )   
CREATE INDEX arinppyt_work_ind_3 ON #arinppyt_work( customer_code )   
CREATE INDEX arinppyt_work_ind_4 ON #arinppyt_work( date_applied )   
CREATE INDEX arinppyt_work_ind_5 ON #arinppyt_work( payment_type )   
CREATE INDEX arinppyt_work_ind_6 ON #arinppyt_work( payment_code )  
CREATE INDEX #arinppyt_work_ind_7 ON #arinppyt_work (trx_ctrl_num )  
  
CREATE TABLE #artrxpdt_work ( doc_ctrl_num varchar(16), trx_ctrl_num varchar(16), sequence_id int, gl_trx_id varchar(16),  
     customer_code varchar(8), payer_cust_code varchar(8), trx_type smallint, apply_to_num varchar(16), apply_trx_type smallint,  
    date_aging int, date_applied int, amt_applied float, amt_disc_taken float, amt_wr_off float, void_flag smallint,   
    line_desc varchar(40), posted_flag smallint, sub_apply_num varchar(16), sub_apply_type smallint, amt_tot_chg float,  
     amt_paid_to_date float, terms_code varchar(8), posting_code varchar(8), gain_home float, gain_oper float,   
    inv_amt_applied float, inv_amt_disc_taken float, inv_amt_wr_off float, inv_cur_code varchar(8), writeoff_code varchar(8), org_id varchar(30) NULL ,  
    db_action smallint )   
CREATE INDEX #artrxpdt_work_ind_0 ON #artrxpdt_work( customer_code, doc_ctrl_num, trx_type, apply_trx_type, apply_to_num )   
CREATE INDEX #artrxpdt_work_ind_1 ON #artrxpdt_work ( trx_ctrl_num )    
  
  
CREATE TABLE #arnonardet_work ( trx_ctrl_num varchar (16) NOT NULL,trx_type smallint NULL, sequence_id         int NOT NULL,  
     line_desc           varchar (40) NOT NULL, tax_code            varchar ( 8) NOT NULL,  
    gl_acct_code        varchar (32) NOT NULL, unit_price float NOT NULL,extended_price      float NOT NULL, reference_code      varchar (8) NULL,amt_tax float NULL,qty_shipped float NULL,db_action smallint  NULL , org_id varchar(30) NULL )  
CREATE INDEX #arnonardet_work_ind_0  ON #arnonardet_work (trx_ctrl_num, trx_type, sequence_id)   
  
CREATE TABLE #artrxndet_work  
(  
 trx_ctrl_num varchar(16),  
 trx_type smallint,  
 sequence_id int,  
 line_desc varchar(40),  
 tax_code varchar(8),  
 gl_acct_code varchar(32),  
 unit_price float,  
 extended_price float,  
 reference_code varchar(32),  
 amt_tax  float,  
 qty_shipped float,  
 db_action smallint, org_id varchar(30) NULL   
)  
  
CREATE INDEX #artrxndet_work_ind_0   
ON #artrxndet_work (trx_ctrl_num, trx_type, sequence_id)  
  
TRUNCATE TABLE #arinppyt  
TRUNCATE TABLE #arinppdt   
  
  
CREATE TABLE #ewerror (module_id   smallint,  err_code  int,  info1 char(32), info2 char(32),   
    infoint int,  infofloat float, flag1 smallint,  trx_ctrl_num char(16),  sequence_id int,  source_ctrl_num char(16),   
   extra int)   
CREATE TABLE #arvalchg (trx_ctrl_num  varchar(16),  doc_ctrl_num  varchar(16),  doc_desc    varchar(40),   
    apply_to_num  varchar(16),  apply_trx_type  smallint,  order_ctrl_num  varchar(16),  batch_code    varchar(16),   
    trx_type    smallint,  date_entered  int,  date_applied  int,  date_doc    int,  date_shipped  int,  date_required int,  
     date_due    int,  date_aging     int,  customer_code varchar(8),  ship_to_code  varchar(8),  salesperson_code  varchar(8),  
     territory_code  varchar(8),  comment_code      varchar(8),  fob_code     varchar(8),  freight_code      varchar(8),   
    terms_code        varchar(8),  fin_chg_code      varchar(8),  price_code        varchar(8),   
    dest_zone_code    varchar(8),  posting_code      varchar(8),  recurring_flag    smallint,  recurring_code    varchar(8),  
     tax_code          varchar(8),  cust_po_num       varchar(20),  total_weight      float,  amt_gross         float,  
     amt_freight       float,  amt_tax     float,  amt_tax_included  float,  amt_discount      float,  amt_net     float,  
     amt_paid          float,  amt_due     float,  amt_cost          float,  amt_profit    float,  next_serial_id    smallint,  
     printed_flag      smallint,  posted_flag       smallint,  hold_flag         smallint,  hold_desc     varchar(40),   
    user_id     smallint,  customer_addr1  varchar(40),  customer_addr2  varchar(40),  customer_addr3  varchar(40),   
    customer_addr4  varchar(40),  customer_addr5  varchar(40),  customer_addr6  varchar(40),  ship_to_addr1 varchar(40),   
    ship_to_addr2 varchar(40),  ship_to_addr3 varchar(40),  ship_to_addr4 varchar(40),  ship_to_addr5 varchar(40),   
    ship_to_addr6 varchar(40),  attention_name  varchar(40),  attention_phone varchar(30),  amt_rem_rev       float,   
    amt_rem_tax       float,  date_recurring    int,  location_code     varchar(8),  process_group_num       varchar(16) NULL,   
    source_trx_ctrl_num     varchar(16) NULL,  source_trx_type smallint NULL,  amt_discount_taken      float NULL,    
   amt_write_off_given     float NULL,  nat_cur_code    varchar(8),  rate_type_home  varchar(8),   
    rate_type_oper  varchar(8),  rate_home       float,  rate_oper       float,  temp_flag smallint  NULL,org_id    varchar(30) NULL, interbranch_flag integer NULL, temp_flag2  integer NULL  )   
  
CREATE TABLE #arvalcdt (trx_ctrl_num  varchar(16),  doc_ctrl_num  varchar(16),  sequence_id   int,  trx_type    smallint,   
    location_code varchar(8),  item_code   varchar(30),  bulk_flag   smallint,  date_entered  int,  line_desc   varchar(60),  
     qty_ordered   float,  qty_shipped   float,  unit_code   varchar(8),  unit_price    float,  unit_cost float,    
   extended_price  float,  weight    float,  serial_id   int,  tax_code    varchar(8),  gl_rev_acct   varchar(32),   
    disc_prc_flag smallint,  discount_amt  float,  discount_prc  float,  commission_flag smallint,  rma_num   varchar(16),  
     return_code   varchar(8),  qty_returned  float,  qty_prev_returned float,  new_gl_rev_acct varchar(32),  
     iv_post_flag  smallint,  oe_orig_flag  smallint,  calc_tax    float,  reference_code  varchar(32) NULL,   
    new_reference_code varchar(32) NULL,  temp_flag     smallint NULL ,  org_id varchar(30) NULL, temp_flag2 integer NULL  )  
  
CREATE TABLE #arvaltax (trx_ctrl_num varchar(16),  trx_type          smallint,  sequence_id       int,   
    tax_type_code     varchar(8),  amt_taxable       float,  amt_gross float,  amt_tax     float,  amt_final_tax     float,  
     temp_flag     smallint NULL  )   
  
  
  
  
  
  
DECLARE print_doc CURSOR FOR  
 SELECT trx_ctrl_num FROM arinpchg   
 WHERE process_group_num = @process_ctrl_num  
 AND printed_flag = 0  
 AND (doc_ctrl_num is null OR doc_ctrl_num = '')  
   
  
OPEN print_doc  
  
FETCH NEXT FROM print_doc INTO @trx_ctrl_num  
  
WHILE @@FETCH_STATUS = 0  
BEGIN  
  
  
 UPDATE  ewnumber  
 SET  next_num  = next_num + 1  
 WHERE num_type = 2021  
  
 IF @@error != 0  
 BEGIN  
  RETURN -1  
 END  
  
 SELECT  @next_num  = next_num,  
  @mask  = mask  
 FROM ewnumber  
 WHERE num_type = 2021  
  
 EXEC fmtctlnm_sp @next_num,  
    @mask,  
    @doc_ctrl_num OUTPUT,  
    @result OUTPUT  
  
 IF (@result != 0)  
 BEGIN  
  RETURN -1  
 END  
  
 UPDATE  arinpchg  
 SET  doc_ctrl_num = @doc_ctrl_num  
 WHERE trx_ctrl_num = @trx_ctrl_num  
  
  
 SELECT @trx_ctrl_num = ''  
   
 FETCH NEXT FROM print_doc into @trx_ctrl_num  
END  
    
CLOSE print_doc  
DEALLOCATE print_doc  
    
  
  
SELECT @batch_ctrl_num = MIN(batch_ctrl_num)  
FROM batchctl   
WHERE process_group_num = @process_ctrl_num  
AND posted_flag = -1   
AND batch_ctrl_num > ''   
AND batch_type = 2030   
  
IF @batch_ctrl_num IS NULL  
 RETURN -1  
  
  
  
  
EXEC @result = ARCMPostBatch_SP @batch_ctrl_num, @debug_level, @perf_level   
  
if @result != 0   
   RETURN @result  
  
  
  
  
EXEC @result = arcmedt_sp @only_error, @debug_level  
  
if @result != 0   
   RETURN @result  
  
  
  
  
  
EXEC @result = ARCMPostBatch2_SP @batch_ctrl_num, @debug_level, @perf_level  
  
if @result != 0   
   RETURN @result  
  
  
TRUNCATE TABLE #ewerror   
CREATE TABLE #arvalpyt (trx_ctrl_num  varchar(16),  doc_ctrl_num  varchar(16),  trx_desc    varchar(40),   
    batch_code    varchar(16),  trx_type    smallint,  non_ar_flag   smallint,  non_ar_doc_num  varchar(16),   
    gl_acct_code  varchar(32),  date_entered  int,  date_applied  int,  date_doc    int,  customer_code varchar(8),   
    payment_code  varchar(8),  payment_type  smallint,  amt_payment   float,  amt_on_acct   float,   
    prompt1_inp   varchar(30),  prompt2_inp   varchar(30),  prompt3_inp   varchar(30),  prompt4_inp   varchar(30),  
     deposit_num   varchar(16),  bal_fwd_flag  smallint,  printed_flag  smallint,  posted_flag   smallint,   
    hold_flag   smallint,  wr_off_flag   smallint,  on_acct_flag  smallint,  
   user_id   smallint,  max_wr_off    float,  days_past_due int,  void_type   smallint,  cash_acct_code  varchar(32),  
     origin_module_flag  smallint  NULL,  process_group_num varchar(16) NULL,  temp_flag   smallint  NULL,   
    source_trx_ctrl_num varchar(16) NULL,  source_trx_type smallint  NULL,  nat_cur_code  varchar(8),    
    rate_type_home  varchar(8),  rate_type_oper  varchar(8),  rate_home   float,  rate_oper   float,    
   amt_discount  float NULL,  reference_code  varchar(32) NULL ,  org_id   varchar(30) NULL,  interbranch_flag integer NULL, temp_flag2  integer NULL  )    
  
CREATE TABLE #arvalpdt (trx_ctrl_num  varchar(16),  doc_ctrl_num  varchar(16),  sequence_id   int,   
    trx_type    smallint,  apply_to_num  varchar(16),  apply_trx_type  smallint,  customer_code varchar(8),   
    payer_cust_code varchar(8)  NULL,  date_aging    int,  amt_applied   float,  amt_disc_taken  float,   
    wr_off_flag   smallint,  amt_max_wr_off  float,  void_flag   smallint,  line_desc   varchar(40),   
    sub_apply_num varchar(16),  sub_apply_type  smallint,  amt_tot_chg   float,  amt_paid_to_date  float,    
   terms_code    varchar(8),  posting_code  varchar(8),  date_doc    int,  amt_inv   float,  gain_home   float,   
    gain_oper   float,  inv_amt_applied float,  inv_amt_disc_taken  float,  inv_amt_max_wr_off  float,   
   inv_cur_code  varchar(8),  temp_flag   smallint NULL,  writeoff_code  varchar(8) NULL, org_id varchar(30) NULL, temp_flag2 integer NULL )   
  
CREATE TABLE #arvalnonardet ( trx_ctrl_num varchar (16), sequence_id int, line_desc varchar (40),  
     tax_code varchar ( 8), gl_acct_code varchar (32), extended_price float, reference_code varchar (8),  
     temp_flag   smallint NULL, org_id   varchar(30) NULL, temp_flag2   integer NULL  )   
  
  
  
EXEC @result = ARPYSrcInsertValTables_SP @debug_level  
if @result != 0   
   RETURN @result  
  
  
  
  
EXEC @result = arcredt_sp @only_error, @called_from, @debug_level   
if @result != 0   
   RETURN @result  
  
  
  
  
EXEC @result = ARInsertPERRors_SP @process_ctrl_num, @batch_ctrl_num, @debug_level   
if @result != 0   
   RETURN @result  
  
  
  
  
EXEC @result = gltrxval_sp @org_company,@rec_company,@journal_ctrl_num,@sequence_id,@debug_level  
if @result != 0   
   RETURN @result  
  
  
  
  
EXEC @result = ARCMUpdateTables_SP @batch_ctrl_num, @debug_level, @perf_level   
  
if @result != 0   
   RETURN @result  
  
  
  
EXEC @result = arpymkbt_sp @process_ctrl_num, @company_code,@debug_level,@settlement   
if @result != 0   
   RETURN @result  
  
  
TRUNCATE TABLE #deplock  TRUNCATE TABLE #aractcus_work  TRUNCATE TABLE #aractprc_work TRUNCATE TABLE #aractshp_work TRUNCATE TABLE #aractslp_work   
TRUNCATE TABLE #aractter_work  TRUNCATE TABLE #arinpcdt_work TRUNCATE TABLE #arinpchg_work TRUNCATE TABLE #arinppdt_work TRUNCATE TABLE #arinppyt_work   
TRUNCATE TABLE #arsumcus_work  TRUNCATE TABLE #arsumprc_work  TRUNCATE TABLE #arsumshp_work TRUNCATE TABLE #arsumslp_work   TRUNCATE TABLE #arsumter_work   
TRUNCATE TABLE #artrx_work   TRUNCATE TABLE #artrxage_work   TRUNCATE TABLE #artrxpdt_work  TRUNCATE TABLE #arinptax_work  TRUNCATE TABLE #ewerror   
TRUNCATE TABLE #arvalpyt  TRUNCATE TABLE #arvalpdt  TRUNCATE TABLE #arvalnonardet   
  
  
  
EXEC @result = ARCRPostBatch_SP @batch_ctrl_num, @debug_level, @perf_level, @settlement   
if @result != 0   
   RETURN @result  
  
  
  
EXEC @result = arcredt_sp @only_error, @called_from, @debug_level  
if @result != 0   
   RETURN @result  
  
  
  
EXEC @result = ARCRPostBatch2_SP @batch_ctrl_num, @debug_level, @perf_level,@settlement   
if @result != 0   
   RETURN @result  
  
  
  
EXEC @result =  gltrxval_sp @org_company, @rec_company,@journal_ctrl_num, @sequence_id, @debug_level  
if @result != 0   
   RETURN @result  
  
  
TRUNCATE TABLE #ewerror  
CREATE TABLE #cminvdtl (rec_id int,trx_type smallint,trx_ctrl_num varchar(16), doc_ctrl_num varchar(16),date_document int,  
   description varchar(40), document1 varchar(40),document2 varchar(40),cash_acct_code varchar(32),  
    amount_book float,reconciled_flag smallint,  closed_flag smallint, void_flag smallint,  
   date_applied int,cleared_type smallint, apply_to_trx_num varchar(17), apply_to_trx_type smallint,   
    apply_to_doc_num varchar(16), flag smallint, org_id varchar(30))  
  
  
EXEC @result = cminval_sp  @result  
  
  
  
  
  
  
  
  
  
EXEC @result = ARCRUpdateTables_SP @batch_ctrl_num, @debug_level, @perf_level   
if @result != 0    
select @result    
   RETURN @result  
  
DROP TABLE #ewerror   
DROP TABLE #arvalpyt  DROP TABLE #arvalpdt  DROP TABLE #arvalnonardet   
DROP TABLE #arvalchg  DROP TABLE #arvalcdt  DROP TABLE #arvaltax   
DROP TABLE #deplock   
DROP TABLE #aractcus_work    
DROP TABLE #aractprc_work    
DROP TABLE #aractshp_work  DROP TABLE #aractslp_work  DROP TABLE #aractter_work    
DROP TABLE #arinpcdt_work  DROP TABLE #arinpchg_work  DROP TABLE #arinpcom_work  DROP TABLE #arinptax_work    
DROP TABLE #arsumcus_work  DROP TABLE #arsumprc_work  DROP TABLE #arsumshp_work  DROP TABLE #arsumslp_work    
DROP TABLE #arsumter_work  DROP TABLE #artrx_work  DROP TABLE #artrxage_work  DROP TABLE #artrxcdt_work   
DROP TABLE #artrxcom_work  DROP TABLE #artrxtax_work  DROP TABLE #artrxxtr_work DROP TABLE #artrxpdt_work   
DROP TABLE #arinppyt_work  DROP TABLE #arinppdt_work  DROP TABLE #arnonardet_work DROP TABLE #artrxndet_work  
DROP TABLE #gltrx  
DROP TABLE #gltrxdet  
DROP TABLE #trxerror  
DROP TABLE #batches  
DROP TABLE #offset_accts  
DROP TABLE #offsets  
  
  
  
EXEC @result =  glpsindp_sp @process_ctrl_num, @company_code, @debug_level  
if @result != 0   
   RETURN @result  
  
  
EXEC @result = pctrlupd_sp @process_ctrl_num, @process_state  
if @result != 0   
   RETURN @result  
  
DROP TABLE #cminpdtl  
  
RETURN 1  
  
GO
GRANT EXECUTE ON  [dbo].[fs_post_cm] TO [public]
GO
