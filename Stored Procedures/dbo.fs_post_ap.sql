SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
   
      
CREATE PROCEDURE [dbo].[fs_post_ap] @user varchar(30), @process_group_num varchar(16),       
 @type int=4091, @err int OUT , @online_call int = 1 AS      
      
create table #vouchers ( match_ctrl_int int, trx_ctrl_num varchar(16), trx_type int)      
create index tv_0 on #vouchers (match_ctrl_int)      
create index tv_1 on #vouchers (trx_type, trx_ctrl_num)      
      
CREATE TABLE #adm_results      
(      
    module_id smallint,      
 err_code  int,      
 info1 char(32),      
 info2 char(255),      
 infoint int,      
 infofloat float,      
 flag1 smallint,      
 trx_ctrl_num char(16),      
 sequence_id int,      
 source_ctrl_num char(16),      
 extra int,      
    match_ctrl_int int,      
 ewerror_ind int      
)      
      
CREATE TABLE #ewerror      
(      
 module_id smallint,      
 err_code int,      
 info1 char(32),      
 info2 char(255),      
 infoint int,      
 infofloat float,      
 flag1 smallint,      
 trx_ctrl_num char(16),      
 sequence_id int,      
 source_ctrl_num char(16),      
 extra int      
)      
      
CREATE TABLE #apvovchg      
(      
 trx_ctrl_num  varchar(16),      
 trx_type  smallint,      
 doc_ctrl_num  varchar(16),      
 apply_to_num  varchar(16),      
 user_trx_type_code varchar(8),      
 batch_code  varchar(16),      
 po_ctrl_num  varchar(16),      
 vend_order_num  varchar(20),      
 ticket_num  varchar(20),      
 date_applied  int,      
 date_aging  int,      
 date_due  int,      
 date_doc  int,      
 date_entered  int,      
 date_received  int,      
 date_required  int,      
 date_recurring  int,      
 date_discount  int,      
 posting_code  varchar(8),      
 vendor_code  varchar(12),      
 pay_to_code  varchar(8),      
 branch_code  varchar(8),      
 class_code  varchar(8),      
 approval_code  varchar(8),      
 comment_code  varchar(8),      
 fob_code  varchar(8),      
 terms_code  varchar(8),      
 tax_code  varchar(8),      
 recurring_code  varchar(8),      
 location_code  varchar(8),      
 payment_code  varchar(8),      
 times_accrued  smallint,      
 accrual_flag  smallint,      
 drop_ship_flag  smallint,      
 posted_flag  smallint,      
 hold_flag  smallint,      
 add_cost_flag  smallint,      
 approval_flag smallint,      
 recurring_flag  smallint,      
 one_time_vend_flag smallint,      
 one_check_flag  smallint,      
 amt_gross  float,      
 amt_discount  float,      
 amt_tax   float,      
 amt_freight  float,      
 amt_misc  float,      
 amt_net   float,      
 amt_paid  float,      
 amt_due   float,      
 amt_tax_included float,      
 frt_calc_tax float,      
 doc_desc  varchar(40),      
 hold_desc  varchar(40),      
 user_id   smallint,      
 next_serial_id  smallint,      
 pay_to_addr1  varchar(40),      
 pay_to_addr2  varchar(40),      
 pay_to_addr3  varchar(40),      
 pay_to_addr4  varchar(40),      
 pay_to_addr5  varchar(40),      
 pay_to_addr6  varchar(40),      
 attention_name  varchar(40),      
 attention_phone  varchar(30),      
 intercompany_flag smallint,      
 company_code  varchar(8),      
 cms_flag  smallint,      
 nat_cur_code    varchar(8),      
 rate_type_home    varchar(8),      
 rate_type_oper   varchar(8),      
 rate_home     float,      
 rate_oper    float,      
 flag     smallint,      
 net_original_amt float,      
 org_id varchar(30) NULL,      
 interbranch_flag int NULL,      
 temp_flag int NULL,      
 amt_nonrecoverable_tax float NULL,      
 tax_freight_no_recoverable float,      
    pay_to_country_code varchar(3) null,      
    pay_to_city varchar(40) null,      
    pay_to_state varchar(40) null,      
    pay_to_postal_code varchar(15) null      
)      
      
CREATE INDEX apvovchg_ind_1 ON #apvovchg (trx_ctrl_num)      
      
      
CREATE TABLE #apdmvchg      
(      
 trx_ctrl_num  varchar(16),      
 trx_type   smallint,      
 doc_ctrl_num  varchar(16),      
 apply_to_num  varchar(16),      
 user_trx_type_code varchar(8),      
 batch_code   varchar(16),      
 po_ctrl_num   varchar(16),      
 vend_order_num  varchar(20),      
 ticket_num   varchar(20),    
 date_applied  int,      
 date_doc   int,      
 date_entered  int,      
 posting_code  varchar(8),      
 vendor_code   varchar(12),      
 pay_to_code   varchar(8),      
 branch_code   varchar(8),      
 class_code   varchar(8),      
 approval_code  varchar(8),      
 comment_code  varchar(8),      
 fob_code   varchar(8),      
 terms_code   varchar(8),      
 tax_code   varchar(8),      
 location_code  varchar(8),      
 posted_flag   smallint,      
 hold_flag   smallint,      
 amt_gross   float,      
 amt_discount  float,      
 amt_tax    float,      
 amt_freight   float,      
 amt_misc   float,      
 amt_net    float,      
 amt_restock   float,      
 amt_tax_included float,      
 frt_calc_tax  float,      
 doc_desc   varchar(40),      
 hold_desc   varchar(40),      
 user_id    smallint,      
 next_serial_id  smallint,      
 attention_name  varchar(40),      
 attention_phone  varchar(30),      
 intercompany_flag smallint,      
 company_code  varchar(8),      
 cms_flag   smallint,      
 nat_cur_code   varchar(8),      
 rate_type_home   varchar(8),      
 rate_type_oper  varchar(8),   rate_home    float,      
 rate_oper   float,      
 flag    smallint,      
 net_original_amt float,      
 org_id varchar(30) NULL,      
 interbranch_flag int NULL,      
 temp_flag int NULL,      
 amt_nonrecoverable_tax float NULL,      
 tax_freight_no_recoverable float      
)      
      
CREATE TABLE #apinpchg (      
 trx_ctrl_num  varchar(16),      
 trx_type   smallint,      
 doc_ctrl_num  varchar(16),      
 apply_to_num  varchar(16),       
   user_trx_type_code varchar(8),      
 batch_code   varchar(16),      
 po_ctrl_num   varchar(16),      
 vend_order_num  varchar(20),      
 ticket_num   varchar(20),      
 date_applied  int,      
 date_aging   int,      
 date_due   int,      
 date_doc   int,      
 date_entered  int,      
 date_received  int,      
 date_required  int,      
 date_recurring  int,      
 date_discount  int,      
 posting_code  varchar(8),      
 vendor_code   varchar(12),      
 pay_to_code   varchar(8),      
 branch_code   varchar(8),      
 class_code   varchar(8),      
 approval_code  varchar(8),      
 comment_code  varchar(8),      
 fob_code   varchar(8),      
 terms_code   varchar(8),      
 tax_code   varchar(8),      
 recurring_code  varchar(8),      
 location_code  varchar(8),      
 payment_code  varchar(8),      
 times_accrued  smallint,      
 accrual_flag  smallint,      
 drop_ship_flag  smallint,      
 posted_flag   smallint,      
 hold_flag   smallint,      
 add_cost_flag  smallint,      
 approval_flag  smallint,      
 recurring_flag  smallint,      
 one_time_vend_flag smallint,      
 one_check_flag  smallint,      
 amt_gross   float,      
 amt_discount  float,      
 amt_tax    float,      
 amt_freight   float,      
 amt_misc   float,      
 amt_net    float,      
 amt_paid   float,      
 amt_due    float,      
 amt_restock   float,      
 amt_tax_included float,      
 frt_calc_tax  float,      
 doc_desc   varchar(40),      
 hold_desc   varchar(40),      
 user_id    smallint,      
 next_serial_id  smallint,      
 pay_to_addr1  varchar(40),      
 pay_to_addr2  varchar(40),      
 pay_to_addr3  varchar(40),      
 pay_to_addr4  varchar(40),      
 pay_to_addr5  varchar(40),      
 pay_to_addr6  varchar(40),      
 attention_name  varchar(40),      
 attention_phone  varchar(30),      
 intercompany_flag smallint,      
 company_code  varchar(8),      
 cms_flag   smallint,      
 process_group_num varchar(16),      
 nat_cur_code   varchar(8),      
 rate_type_home   varchar(8),      
 rate_type_oper  varchar(8),      
 rate_home    float,      
 rate_oper   float,      
 trx_state  smallint NULL,      
 mark_flag smallint  NULL,      
 net_original_amt float,      
 org_id   varchar(30) NULL,      
 tax_freight_no_recoverable float,      
    pay_to_country_code varchar(3) null,      
    pay_to_city varchar(40) null,      
    pay_to_state varchar(40) null,      
    pay_to_postal_code varchar(15) null      
 )      
      
create table #apinpage (      
 trx_ctrl_num  varchar(16),      
 trx_type  smallint,      
 sequence_id  int,      
 date_applied  int,      
 date_due  int,      
 date_aging  int,      
 amt_due   float,      
 trx_state smallint NULL,      
 mark_flag smallint NULL      
 )      
      
CREATE TABLE #apinpcdt (      
 trx_ctrl_num   varchar(16),      
 trx_type  smallint,      
 sequence_id  int,      
 location_code  varchar(8),      
 item_code  varchar(30),      
 bulk_flag  smallint,      
 qty_ordered  float,      
 qty_received  float,      
 qty_returned  float,      
 qty_prev_returned  float,      
 approval_code   varchar(8),      
 tax_code  varchar(8),      
 return_code  varchar(8),      
 code_1099  varchar(8),      
 po_ctrl_num  varchar(16),      
 unit_code  varchar(8),      
 unit_price  float,      
 amt_discount  float,      
 amt_freight  float,      
 amt_tax  float,      
 amt_misc  float,      
 amt_extended  float,      
 calc_tax  float,      
 date_entered  int,      
 gl_exp_acct  varchar(32),      
 new_gl_exp_acct  varchar(32),      
 rma_num  varchar(20),      
 line_desc  varchar(60),      
 serial_id  int,      
 company_id  smallint,      
 iv_post_flag  smallint,      
 po_orig_flag  smallint,      
 rec_company_code  varchar(8),      
 new_rec_company_code varchar(8),      
 reference_code   varchar(32),      
 new_reference_code  varchar(32),      
 trx_state   smallint NULL,      
 mark_flag  smallint NULL,      
 org_id   varchar(30) NULL,      
 amt_nonrecoverable_tax float,      
 amt_tax_det float      
 )      
      
create table #apinptax (      
 trx_ctrl_num   varchar(16),      
 trx_type   smallint,      
 sequence_id   int,      
 tax_type_code   varchar(8),      
 amt_taxable   float,      
 amt_gross   float,      
 amt_tax    float,      
 amt_final_tax   float,      
 trx_state smallint NULL,      
 mark_flag smallint NULL      
 )      
      
create table #apinptaxdtl (      
 trx_ctrl_num   varchar(16),      
 sequence_id   int,      
 trx_type   smallint,      
 tax_sequence_id   int,      
 detail_sequence_id  int,      
 tax_type_code   varchar(8),      
 amt_taxable   float,      
 amt_gross   float,      
 amt_tax    float,      
 amt_final_tax   float,      
 recoverable_flag  integer,      
 account_code   varchar(32),      
 mark_flag smallint NULL      
 )      
      
CREATE TABLE #apvovcdt      
(      
 trx_ctrl_num  varchar(16),      
 trx_type   smallint,      
 sequence_id   int,      
 location_code  varchar(8),      
 item_code   varchar(30),      
 bulk_flag   smallint,      
 qty_ordered   float,      
 qty_received  float,      
 approval_code  varchar(8),      
 tax_code   varchar(8),      
 code_1099   varchar(8),      
 po_ctrl_num   varchar(16),      
 unit_code   varchar(8),      
 unit_price   float,      
 amt_discount  float,      
 amt_freight   float,      
 amt_tax   float,      
 amt_misc   float,      
 amt_extended  float,      
 calc_tax   float,      
 date_entered  int,      
 gl_exp_acct   varchar(32),      
 rma_num    varchar(20),      
 line_desc   varchar(60),      
 serial_id   int,      
 company_id   smallint,      
 iv_post_flag  smallint,      
 po_orig_flag  smallint,      
 rec_company_code varchar(8),      
 reference_code  varchar(32),      
 flag    smallint,      
 org_id   varchar(30) NULL,      
 temp_flag  integer NULL,      
 amt_nonrecoverable_tax float      
)      
CREATE INDEX apvovcdt_ind_1 ON #apvovcdt (trx_ctrl_num, sequence_id)      
      
CREATE TABLE #apvovage      
(      
 trx_ctrl_num  varchar(16),      
 trx_type  smallint,      
 sequence_id  int,      
 date_applied  int,      
 date_due  int,      
 date_aging  int,      
 amt_due   float      
)      
      
      
CREATE TABLE #apvovtax      
(      
 trx_ctrl_num   varchar(16),      
 trx_type   smallint,      
 sequence_id   int,      
 tax_type_code   varchar(8),      
 amt_taxable   float,      
 amt_gross   float,      
 amt_tax    float,      
 amt_final_tax   float      
)      
      
create table #apvovtaxdtl (      
 trx_ctrl_num   varchar(16),      
 sequence_id   int,      
 trx_type   smallint,      
 tax_sequence_id   int,      
 detail_sequence_id  int,      
 tax_type_code   varchar(8),      
 amt_taxable   float,      
 amt_gross   float,      
 amt_tax    float,      
 amt_final_tax   float,      
 recoverable_flag  integer,      
 account_code   varchar(32)      
 )      
      
CREATE TABLE #apdmvcdt      
(      
 trx_ctrl_num  varchar(16),      
 trx_type   smallint,      
 sequence_id   int,      
 location_code  varchar(8),      
 item_code   varchar(30),      
 bulk_flag   smallint,      
 qty_ordered   float,      
 qty_returned  float,      
 qty_prev_returned float,      
 approval_code  varchar(8),      
 tax_code   varchar(8),      
 return_code   varchar(8),      
 unit_code   varchar(8),      
 unit_price   float,      
 amt_discount  float,      
 amt_freight   float,      
 amt_tax   float,      
 amt_misc   float,      
 amt_extended  float,      
 calc_tax   float,      
 date_entered  int,      
 gl_exp_acct   varchar(32),      
 rma_num    varchar(20),      
 line_desc   varchar(60),      
 serial_id   int,      
 company_id   smallint,      
 iv_post_flag  smallint,      
 po_orig_flag  smallint,      
 rec_company_code varchar(8),      
 reference_code  varchar(32),      
 flag    smallint,      
 org_id   varchar(30) NULL,      
 temp_flag  integer NULL,      
 amt_nonrecoverable_tax float      
)      
      
CREATE TABLE #apdmvtax      
(      
 trx_ctrl_num   varchar(16),      
 trx_type   smallint,      
 sequence_id   int,      
 tax_type_code   varchar(8),      
 amt_taxable   float,      
 amt_gross   float,      
 amt_tax    float,      
 amt_final_tax   float      
)      
      
create table #apdmvtaxdtl (      
 trx_ctrl_num   varchar(16),      
 sequence_id   int,      
 trx_type   smallint,      
 tax_sequence_id   int,      
 detail_sequence_id  int,      
 tax_type_code   varchar(8),      
 amt_taxable   float,      
 amt_gross   float,      
 amt_tax    float,      
 amt_final_tax   float,      
 recoverable_flag  integer,      
 account_code   varchar(32)      
 )      
      
      
      
truncate table #ewerror            
truncate table #apvovchg           
truncate table #apdmvchg           
      
CREATE TABLE #apvovtmp      
(      
 trx_ctrl_num  varchar(16),      
 trx_type  smallint,      
 doc_ctrl_num  varchar(16),      
 trx_desc  varchar(40),      
 date_applied  int,      
 date_doc  int,      
 vendor_code  varchar(12),      
 payment_code  varchar(8),      
 code_1099  varchar(8),      
 cash_acct_code  varchar(32),      
 amt_payment  float,      
 amt_disc_taken  float,      
 payment_type  smallint,      
 approval_flag  smallint,      
 user_id   smallint      
)      
      
CREATE TABLE #apveacct      
(      
 db_name varchar(30),      
 vchr_num varchar(16),      
 line int,      
 type smallint,      
 acct_code varchar(32),      
 date_applied int,      
 reference_code varchar(32),      
 flag smallint,      
 org_id varchar(30) NULL      
)      
      
if not exists (select 1 from sysobjects where id = object_id('tempdb..#apvov_companies'))      
BEGIN      
 CREATE TABLE #apvov_companies  (  rec_company_code varchar(8),   trx_ctrl_num  varchar(16)  )       
 CREATE INDEX apvov_companies_ind_1 ON #apvov_companies (trx_ctrl_num, rec_company_code)       
END      
      
if not exists (select 1 from sysobjects where id = object_id('tempdb..#apdbv_companies'))      
BEGIN      
 CREATE TABLE #apdbv_companies  (  rec_company_code varchar(8),   trx_ctrl_num  varchar(16)  )       
 CREATE INDEX apdbv_companies_ind_1 ON #apdbv_companies (trx_ctrl_num, rec_company_code)       
END      
      
      
DECLARE  @approval_flag smallint,      
         @first_row smallint,              
         @intercompany_flag smallint,      
         @iv_post_flag smallint,      
         @next_serial_id smallint,      
         @one_check_flag smallint,      
         @po_orig_flag smallint,      
         @trx_type smallint,      
         @user_id smallint,      
         @i_eprocurement_ind int      
      
DECLARE  @pay_to_ind int,      
         @one_time_vend int      
      
DECLARE  @company_id int,       
   @divop int,       
         @date_applied int,      
         @date_aging int,      
         @date_discount int,      
         @date_due int,      
         @date_doc int,      
         @date_entered int,      
         @date_posted int,      
         @date_received int,      
         @date_recurring int,      
         @date_required int,      
         @discount_days int,      
         @iRow int,       
         @match_id int,      
         @period_end int,      
         @precision int,      
         @receipt int,      
         @result int,       
         @retval int,       
         @rid int,       
         @sequence int ,       
         @sequence_id int,      
         @serial_id int,      
         @terms_days int,       
         @terms_type int,       
         @xlp int      
      
DECLARE  @amt_due float,      
         @amt_discount float,      
         @amt_extended float,      
         @amt_final_tax float,      
         @amt_freight float,      
         @amt_gross float,      
         @amt_misc float,      
         @amt_misc_temp float,         
         @amt_net float,      
         @amt_paid float,      
         @amt_restock float,      
         @amt_tax float,      
         @amt_tax_included float,      
         @amt_taxable float,      
         @calc_tax float,      
         @frt_calc_tax float,      
         @qty_ordered float,      
         @qty_received float,      
         @qty_prev_returned float,      
         @rate_home float,      
         @rate_oper float,      
         @unit_price float      
      
DECLARE  @orig_curr_factor decimal(20,8),      
         @qty_returned decimal(20,8)      
      
DECLARE  @flag_1099 char(1),       
         @misc char(1),      
         @msg2 varchar(255), @msg varchar(32)      
      
DECLARE  @location varchar(5),       
         @approval_code varchar(8),      
         @branch_code varchar(8),      
         @class_code varchar(8),      
         @code1099 varchar(8),       
         @code_1099 varchar(8),      
         @comment_code varchar(8),       
         @company_code varchar(8),      
         @def_post varchar(8),       
         @fob_code varchar(8),      
         @home_curr varchar(8),       
         @nat_cur_code varchar(8),      
         @new_rec_company_code varchar(8),      
         @oper_curr varchar(8),       
         @posting_code varchar(8),      
         @pay_to_code varchar(8),      
         @payment_type varchar(8),      
         @rate_type_home varchar(8),      
         @rate_type_oper varchar(8),      
         @rec_company_code varchar(8),      
         @return_code varchar(8),      
         @terms_code varchar(8),      
         @tax_code varchar(8),      
         @tax_type_code varchar(8),      
         @user_trx_type_code varchar(8),      
         @unit_code varchar(8),      
         @location_code varchar(10),               
         @po_no varchar(16),      
         @vendor varchar(10),       
         @vendor_code varchar(12),      
         @batch_code varchar(16),      
         @batch_num varchar(16),       
         @doc_ctrl_num varchar(16),      
         @old_batch varchar(16),       
         @po_ctrl_num varchar(16),      
         @proc_po_no varchar(20),      
         @trx_ctrl_num varchar(16),      
         @voucher_no varchar(16),       
         @item_code varchar(30),          
         @rma_num varchar(20),      
         @vend_order_num varchar(20),      
         @attention_phone varchar(30),      
         @plt_name char(30),      
         @gl_exp_acct varchar(32),      
         @new_gl_exp_acct varchar(32),      
         @new_reference_code varchar(32),      
         @post varchar(32),       
         @reference_code varchar(32),      
         @attention_name varchar(40),      
         @doc_desc varchar(40),      
         @hold_desc varchar(40),      
         @payadd1 varchar(40),       
         @payadd2 varchar(40),       
         @payadd3 varchar(40),      
         @payadd4 varchar(40),       
         @pay_to_addr1 varchar(40),      
         @pay_to_addr2 varchar(40),      
         @pay_to_addr3 varchar(40),      
         @pay_to_addr4 varchar(40),      
         @pay_to_addr5 varchar(40),      
         @pay_to_addr6 varchar(40),      
         @pay_to_city varchar(40),      
         @pay_to_state varchar(40),      
         @pay_to_country_code varchar(3),      
         @pay_to_postal_code varchar(15),      
         @line_desc varchar(60),      
         @dbname varchar(255),      
  @tax_freight_no_recoverable float      
DECLARE  @po_ctrl_int int,            
  @part_no varchar(30)           
      
DECLARE  @inv_acct_no varchar(32),          
         @inv_ref_code varchar(32),         
  @status char(1),      
  @send_inv_acct int            
      
DECLARE  @ap_rate_type_home varchar(8)          
      
DECLARE  @RCV_MISC_IN_COGP char(1)           
DECLARE  @po_line int,            
  @net_original_amt float      
DECLARE  @mch_rate_home decimal(20,8), @mch_rate_oper decimal(20,8) -- mls 11/26/02 SCR 30368      
      
DECLARE  @issue_ref_code varchar(32)    -- mls 11/05/03 SCR 32021      
declare @tax_rc int, @err_msg varchar(255)      
      
declare @amt_nonrecoverable_tax float, @amt_tax_det float      
declare @org_id varchar(30), @h_org_id varchar(30)      
      
      
CREATE TABLE #apvobat (      
      date_applied int,      
      process_group_num varchar(16),      
      trx_type smallint,      
      hold_flag smallint,      
      org_id varchar(30)      
     )      
      
CREATE TABLE #apvtemp (      
      code varchar(12),      
      code2 varchar(8),      
      amt_net_home float,      
      amt_net_oper float      
     )      
      
      
SELECT @company_id = company_id,      
      
 @ap_rate_type_home   = glco.rate_type_home,          
 @rate_type_oper  = glco.rate_type_oper,      
 @home_curr   = glco.home_currency,      
 @oper_curr  = glco.oper_currency      
 FROM glco(nolock)      
      
set @i_eprocurement_ind = 0      
select @i_eprocurement_ind = 1      
from config(nolock) where flag = 'PUR_EPROCUREMENT' and upper(value_str) like 'Y%'      
      
SELECT @ap_rate_type_home = isnull(rate_type_home, @ap_rate_type_home),       
 @approval_code = case when aprv_voucher_flag = 1 and default_aprv_flag = 1  -- mls 4/24/03 SCR 31000      
    and @type = 4091 then isnull(default_aprv_code,'') else '' end,      
 @approval_flag = case when aprv_voucher_flag = 1       
    and @type = 4091 then 1 else 0 end      -- mls 4/24/03 SCR 31000      
 FROM apco(nolock)             
      
SELECT  @company_code  = company_code      
 FROM glcomp_vw (nolock)      
 WHERE company_id = @company_id      
      
select @intercompany_flag = 0            
      
SELECT @user_id = user_id      
 FROM glusers_vw (nolock)      
 WHERE lower(user_name) = lower(@user)      
      
IF @user_id is NULL      
 BEGIN      
 select @user_id = 1      
 END      
      
select @RCV_MISC_IN_COGP = isnull((select 'Y' from config (nolock) where flag = 'RCV_MISC_IN_COGP'        
  and Upper(substring(value_str,1,1)) = 'Y'),'N')      
      
select @err = 0, @xlp = 0      
      
SELECT @xlp = isnull((select min(match_ctrl_int)      
 FROM adm_pomchchg_all      
 WHERE match_posted_flag = -1 and      
 process_group_num = @process_group_num AND      
 trx_type = @type),0)      
      
if @xlp = 0      
begin      
  select @msg = 'OK'      
  select @msg2 = ''      
  set @err = 1000      
  set @result = 1      
  goto write_admresults      
end      
      
      
WHILE @xlp != 0      
 BEGIN      
      
 select @precision = isnull( (select curr_precision from glcurr_vw g (nolock), adm_pomchchg_all m       
   where g.currency_code=m.nat_cur_code and m.match_ctrl_int = @xlp), 1.0 )         
      
 SELECT  @trx_type = m.trx_type,      
         @user_trx_type_code = v.user_trx_type_code,      
         @po_ctrl_num = convert( varchar( 16 ), m.match_ctrl_int ),      
         @vend_order_num = m.vendor_invoice_no,      
         @doc_ctrl_num = m.vendor_invoice_no,      
         @date_applied = datediff( day, '01/01/1900', m.apply_date ) + 693596,      
         @date_aging = datediff( day, '01/01/1900', m.aging_date ) + 693596,      
         @date_due = datediff( day, '01/01/1900', m.due_date ) + 693596,      
         @date_doc = datediff( day, '01/01/1900', m.vendor_invoice_date ) + 693596,          
         @date_entered = datediff( day, '01/01/1900', getdate() ) + 693596,      
         @date_received = datediff( day, '01/01/1900', m.invoice_receive_date ) + 693596,      
         @date_required = datediff( day, '01/01/1900', m.due_date ) + 693596,      
         @date_recurring = 0,      
         @date_discount = datediff( day,'01/01/1900', m.discount_date ) + 693596,      
         @posting_code = v.posting_code,      
         @vendor_code = m.vendor_code,      
         @pay_to_code = m.vendor_remit_to,      
         @branch_code = v.branch_code,      
         @class_code = v.vend_class_code,      
--       @approval_code = ' ',         -- mls 4/24/03 SCR 31000      
         @fob_code = isnull( p.fob, v.fob_code ),             
               
  @terms_code = CASE isnull(m.terms_code,'')        
               WHEN '' THEN isnull( p.terms, v.terms_code )      
                     ELSE isnull(m.terms_code,'')        
                     END,      
  @tax_code = CASE isnull(m.tax_code,'')      
               WHEN '' THEN isnull( p.tax_code, v.tax_code )      
                     ELSE isnull(m.tax_code,'')      
                     END,      
         @location_code = m.location,      
--       @approval_flag = 0,          -- mls 4/24/03 SCR 31000      
         @one_check_flag = isnull(v.one_check_flag, 0),      
         @amt_gross = round( m.amt_gross - m.amt_tax_included + m.amt_nonrecoverable_incl_tax, @precision ) + m.amt_nonrecoverable_tax,      
         @amt_discount = round( m.amt_discount, @precision ),      
         @amt_tax = round( m.amt_tax, @precision ),      
         @amt_freight = round( m.amt_freight, @precision ),      
         @amt_misc = round( m.amt_misc, @precision ),      
         @amt_net = round( m.amt_due, @precision ),      
         @amt_paid = 0,      
         @amt_due = round( m.amt_due, @precision ),      
         @amt_restock = 0,      
         @amt_tax_included = round( m.amt_tax_included, @precision ),      
         @frt_calc_tax = 0,       
         @doc_desc = 'Match Number:' + convert( varchar( 16 ), m.match_ctrl_int ),      
         @hold_desc = ' ',      
         @next_serial_id = 0,      
         @process_group_num = m.process_group_num,      
         @nat_cur_code = m.nat_cur_code,      
         @match_id = m.match_ctrl_int,      
         @code_1099 = isnull(v.code_1099,''),      
         @payment_type = v.payment_code,      
         @comment_code = isnull(v.comment_code,''),      
  @rate_type_home = isnull(v.rate_type_home, @ap_rate_type_home),         
  @net_original_amt = round( m.amt_net, @precision ),      
         @mch_rate_home = isnull(m.curr_factor,0),     -- mls 11/26/02 SCR 30368      
         @mch_rate_oper = isnull(m.oper_factor,0),     -- mls 11/26/02 SCR 30368       
      
  @pay_to_ind = case when isnull(m.one_time_vend_ind,0) = 1 then 1 else 0 end,      
         @pay_to_addr1 = isnull(pay_to_addr1 , ''),      
         @pay_to_addr2 = isnull(pay_to_addr2 , ''),      
         @pay_to_addr3 = isnull(pay_to_addr3 , ''),      
         @pay_to_addr4 = isnull(pay_to_addr4 , ''),      
         @pay_to_addr5 = isnull(pay_to_addr5 , ''),      
         @pay_to_addr6 = isnull(pay_to_addr6 , ''),      
  @pay_to_city = isnull(pay_to_city , ''),      
         @pay_to_state = isnull(pay_to_state , ''),      
         @pay_to_country_code = isnull(pay_to_country_cd , ''),      
         @pay_to_postal_code = isnull(pay_to_zip , ''),      
  @attention_name = isnull(m.attention_name, ''),      
  @attention_phone = isnull(m.attention_phone,''),      
  @one_time_vend = isnull(m.one_time_vend_ind,0),      
  @tax_freight_no_recoverable = isnull(m.tax_freight_no_recoverable,0),      
         @h_org_id = m.organization_id ,      
     @trx_ctrl_num = m.trx_ctrl_num      
   FROM  adm_pomchchg_all m       
   LEFT OUTER JOIN purchase_all p ON m.po_no = p.po_key     -- mls 4/22/04 SCR 32659      
   Join adm_vend_all v on m.vendor_code = v.vendor_code      
   WHERE m.match_ctrl_int = @xlp      
      
 if @pay_to_code != '' and      
  (@pay_to_addr1 != '' or @pay_to_addr2 != '' or @pay_to_addr3 != '' or       
   @pay_to_addr4 != '' or @pay_to_addr5 != '' or @pay_to_addr6 != '')      
   select @pay_to_ind = 1      
      
 exec @retval = adm_mccurate_sp      
 @date_applied,@nat_cur_code,@home_curr,@rate_type_home,      
 @rate_home OUTPUT,0,@divop OUTPUT      
      
 if @retval <> 0      
 BEGIN      
 exec adm_post_ap_cancel_tax @msg2 out      
 select @err = -10      
  select @msg = 'Error with home currency rates'      
  select @msg2 = ''      
  set @result = @retval      
  goto write_admresults      
 END      
      
 if @rate_home = 0  select @rate_home = @mch_rate_home     --  mls 11/26/02 SCR 30368      
      
 exec @retval = adm_mccurate_sp      
 @date_applied,@nat_cur_code,@oper_curr,@rate_type_oper,      
 @rate_oper OUTPUT,0,@divop OUTPUT      
      
 if @retval <> 0      
 BEGIN      
 exec adm_post_ap_cancel_tax @msg2 out      
 select @err = -20      
  select @msg = 'Error with oper currency rates'      
  select @msg2 = ''      
  set @result = @retval      
  goto write_admresults      
 END      
      
 if @rate_oper = 0  select @rate_oper = @mch_rate_oper     --  mls 11/26/02 SCR 30368      
      
 if @pay_to_ind = 0      
 begin      
  if @pay_to_code <> ' '       
 Select @pay_to_addr1 = addr1,      
 @pay_to_addr2 = addr2,      
 @pay_to_addr3 = addr3,      
 @pay_to_addr4 = addr4,      
 @pay_to_addr5 = addr5,      
 @pay_to_addr6 = addr6,      
 @attention_name = attention_name,      
 @attention_phone = attention_phone,      
    @pay_to_city = city,      
    @pay_to_state = state,      
    @pay_to_postal_code = postal_code,      
    @pay_to_country_code = country_code      
 FROM appayto      
 WHERE vendor_code = @vendor_code AND pay_to_code = @pay_to_code      
ELSE      
 Select @pay_to_addr1 = addr1,      
 @pay_to_addr2 = addr2,      
 @pay_to_addr3 = addr3,      
 @pay_to_addr4 = addr4,      
 @pay_to_addr5 = addr5,      
 @pay_to_addr6 = addr6,      
 @attention_name = attention_name,      
 @attention_phone = attention_phone,      
    @pay_to_city = city,      
    @pay_to_state = state,      
    @pay_to_postal_code = postal_code,      
    @pay_to_country_code = country_code      
 FROM adm_vend_all      
 WHERE vendor_code = @vendor_code      
end      
      
set @proc_po_no = ''      
if @trx_type = 4091              
begin      
       
      
select @rid = (select min(match_line_num) FROM adm_pomchcdt (nolock) WHERE match_ctrl_int = @match_id)      
      
 select @po_no = po_ctrl_num      
 from adm_pomchcdt (nolock)      
 where match_ctrl_int = @match_id and      
 match_line_num = @rid      
      
 select @posting_code = posting_code,      
 @proc_po_no = proc_po_no      
 from purchase_all (nolock)      
 where po_no = @po_no      
end      
else                
begin      
  select @posting_code = isnull((select posting_code      
  from rtv_all (nolock) where match_ctrl_int = @match_id), @posting_code)      
end                
      
 select @amt_misc_temp = @amt_misc        
      
IF ( LTRIM(isnull(@trx_ctrl_num,'')) = '' )       
BEGIN        
  EXEC @result = apnewnum_sp @trx_type, @company_code, @trx_ctrl_num OUTPUT       
  IF ( @result != 0 )        
  BEGIN      
    exec adm_post_ap_cancel_tax @msg2 out      
    select @err = -40      
  select @msg = 'Error getting trx_ctrl_num'      
  select @msg2 = ''      
  select @result = @err      
  goto write_admresults      
  END      
  IF ( isnull(@trx_ctrl_num,'') = '' )        
  BEGIN      
    exec adm_post_ap_cancel_tax @msg2 out      
    select @err = -41      
  select @msg = 'trx_ctrl_num is blank'      
  select @msg2 = ''      
  select @result = @err      
  goto write_admresults      
  END      
      
  update adm_pomchchg_all set trx_ctrl_num = @trx_ctrl_num      
  where match_ctrl_int = @xlp      
END        
  
     
exec @tax_rc = fs_calculate_matchtax_wrap @match_id = @xlp, @online_call = 0,      
  @doctype = 3,@trx_ctrl_num = @trx_ctrl_num, @err_msg = @err_msg OUT      
if @tax_rc <> 1      
begin      
  insert #adm_results (      
    module_id,  err_code,  info1,   info2 ,      
    infoint,   infofloat ,  flag1 ,  trx_ctrl_num ,  sequence_id ,       
    source_ctrl_num , extra, match_ctrl_int, ewerror_ind)      
  select 4000, 105, 'Tax not calculated successfully',@err_msg,0,0,0,      
    @trx_ctrl_num,0,@xlp,0, @xlp, 0      
end      
else      
begin      
  insert #vouchers (match_ctrl_int, trx_ctrl_num, trx_type)      
  select @xlp, @trx_ctrl_num, @trx_type      
      
  SELECT @amt_gross = round( m.amt_gross - m.amt_tax_included + m.amt_nonrecoverable_incl_tax, @precision ) + m.amt_nonrecoverable_tax,      
         @amt_tax = round( m.amt_tax, @precision ),      
         @amt_net = round( m.amt_due, @precision ),      
         @amt_due = round( m.amt_due, @precision ),      
         @amt_tax_included = round( m.amt_tax_included, @precision ),      
         @net_original_amt = round( m.amt_net, @precision ),      
         @tax_freight_no_recoverable = isnull(m.tax_freight_no_recoverable,0)      
   FROM  adm_pomchchg m       
   WHERE m.match_ctrl_int = @xlp      
      
  update r      
  set amt_gross = @amt_gross,      
    amt_tax = @amt_tax,      
    doc_ctrl_num = @doc_ctrl_num      
  from gltcrecon r      
  where r.trx_ctrl_num = @trx_ctrl_num and r.trx_type = @trx_type      
      
       
INSERT #apinpchg(  trx_ctrl_num,  trx_type,  doc_ctrl_num,       
 apply_to_num,  user_trx_type_code,  batch_code,  po_ctrl_num,  vend_order_num,  ticket_num,       
 date_applied,  date_aging,  date_due,  date_doc,  date_entered,  date_received,       
 date_required,  date_recurring,  date_discount,  posting_code,  vendor_code,  pay_to_code,       
 branch_code,  class_code,  approval_code,  comment_code,  fob_code,  terms_code,       
 tax_code,  recurring_code,  location_code,  payment_code,  times_accrued,  accrual_flag,       
 drop_ship_flag,  posted_flag,  hold_flag,  add_cost_flag,  approval_flag,  recurring_flag,       
 one_time_vend_flag,  one_check_flag,  amt_gross,  amt_discount,  amt_tax,  amt_freight,       
 amt_misc,  amt_net ,  amt_paid,  amt_due,  amt_restock,  amt_tax_included,  frt_calc_tax,       
 doc_desc,  hold_desc,  user_id,  next_serial_id,  pay_to_addr1,  pay_to_addr2,  pay_to_addr3,       
 pay_to_addr4,  pay_to_addr5,  pay_to_addr6,  attention_name,  attention_phone,  intercompany_flag,       
 company_code,  cms_flag,  process_group_num,  nat_cur_code,  rate_type_home,  rate_type_oper,       
 rate_home,  rate_oper,  trx_state,  mark_flag,  net_original_amt, org_id, tax_freight_no_recoverable,      
 pay_to_country_code, pay_to_city, pay_to_state, pay_to_postal_code)      
VALUES (  @trx_ctrl_num,  @trx_type,  @doc_ctrl_num,  '',  @user_trx_type_code,       
 '',  @po_ctrl_num,  @vend_order_num,  '',  @date_applied,  @date_aging,       
 @date_due,  @date_doc,  @date_entered,  @date_received,  @date_required,  @date_recurring,       
 @date_discount,  @posting_code,  @vendor_code,  @pay_to_code,  @branch_code,  @class_code,       
 @approval_code,  @comment_code,  @fob_code,  @terms_code,  @tax_code,  '',       
 substring(@location_code,1,8),  @payment_type, 0,  0,  0,       
 0,  0,  0,  @approval_flag,  0,  @one_time_vend,       
 @one_check_flag,  @amt_gross,  @amt_discount,  @amt_tax,  @amt_freight,  @amt_misc,       
 @amt_net,  @amt_paid,  @amt_due,  @amt_restock,  @amt_tax_included,  @frt_calc_tax,       
 @doc_desc,  @hold_desc,  @user_id,  @next_serial_id,  @pay_to_addr1,  @pay_to_addr2,       
 @pay_to_addr3,  @pay_to_addr4,  @pay_to_addr5,  @pay_to_addr6,  @attention_name,       
 @attention_phone,  @intercompany_flag,  @company_code,  0,  @process_group_num,       
 @nat_cur_code,  @rate_type_home,  @rate_type_oper,  @rate_home,  @rate_oper,  0,       
 0,  @net_original_amt , @h_org_id, @tax_freight_no_recoverable,      
@pay_to_country_code, @pay_to_city, @pay_to_state, @pay_to_postal_code)      
      
  select @result = @@error      
IF ( @result != 0 )        
BEGIN      
  exec adm_post_ap_cancel_tax @msg2 out      
  select @err = -40      
  select @msg = 'Error inserting on #apinpchg'      
  select @msg2 = ''      
  goto write_admresults      
END      
      
 if @trx_type = 4091      
 BEGIN      
   SELECT @sequence_id = ISNULL(( select MAX( sequence_id )      
   FROM #apinpage       
   WHERE trx_ctrl_num = @trx_ctrl_num AND trx_type = @trx_type),0) + 1      
      
   INSERT #apinpage (      
 trx_ctrl_num,      
 trx_type,      
 sequence_id,      
 date_applied,      
 date_due,      
 date_aging,      
 amt_due,      
 trx_state,      
 mark_flag )      
   VALUES (      
 @trx_ctrl_num,      
 @trx_type,      
 @sequence_id,      
 @date_applied,      
 @date_due,      
 @date_aging,      
 @amt_due,      
 2,      
 0 )      
      
   select @result = @@error      
   IF ( @result != 0 )      
   BEGIN      
     exec adm_post_ap_cancel_tax @msg2 out      
     select @err = -50      
  select @msg = 'Error inserting on #apinpage'      
  select @msg2 = ''      
  goto write_admresults      
   END      
 END      
      
 select @rid = (select min(match_line_num) FROM adm_pomchcdt WHERE match_ctrl_int = @match_id)      
      
      
 WHILE @rid != 0      
 BEGIN      
      
 select @location_code = location,      
  @item_code = part_no,      
  @qty_ordered = qty_ordered,      
  @qty_received = CASE @type      
     WHEN 4091 THEN qty_invoiced      
    ELSE 0      
    END,      
  @qty_returned = CASE @type      
    WHEN 4092 THEN qty_invoiced      
    ELSE 0      
    END,      
  @tax_code = tax_code ,      
  @return_code = ' ',      
  @po_ctrl_num = po_ctrl_num,      
         @po_ctrl_int = po_ctrl_int,             
  @part_no = part_no,              
  @unit_code = ' ',      
  @unit_price = curr_cost,      
  @amt_discount = 0,      
  @amt_freight = 0,      
  @amt_tax = 0.0,       
  @amt_misc = 0,      
  @amt_extended = round(curr_cost * qty_invoiced,@precision),      
  @calc_tax = calc_tax,      
  @gl_exp_acct = gl_acct,      
  @rma_num = ' ',      
  @line_desc = convert(char(30),item_desc) + ' : '       
         + convert(varchar(16),po_ctrl_num) +       
  ' rcpt: ' + convert(varchar(16),receipt_no),              
  @serial_id = 0,      
  @reference_code = isnull(gl_ref_code,''),      
   @orig_curr_factor = curr_factor,      
  @misc = misc,      
  @receipt = receipt_no,      
  @amt_nonrecoverable_tax = amt_nonrecoverable_tax,      
         @amt_tax_det = amt_tax_det,      
         @org_id = organization_id      
 FROM adm_pomchcdt      
 WHERE match_ctrl_int = @xlp AND      
       match_line_num = @rid      
      
      
 update receipts_all set voucher_no = @trx_ctrl_num where receipt_no = @receipt      
      
 select @issue_ref_code = @reference_code      -- mls 11/05/03 SCR 32021      
 if @misc != 'Y'      
 BEGIN      
   select @send_inv_acct = 0             
      
   if @po_ctrl_num like 'R%'             
   begin      
     select @unit_code = min(unit_measure)      
     from rtv_list (nolock)      
     where rtv_no = @po_ctrl_int and part_no = @part_no       
   end      
   else      
   begin      
     select @unit_code = unit_measure,            
 @send_inv_acct = case when part_type = 'M' then 1 else 0 end,        
 @inv_acct_no = account_no,            
 @po_line = po_line             
     from receipts_all (nolock) where receipt_no = @receipt          
   end                
      
 if NOT exists (select * from inv_list where part_no=@item_code and location=@location_code)      
 BEGIN      
   SELECT @post = apacct_code      
   FROM locations_all (nolock)      
   WHERE location = @location_code      
      
   select @send_inv_acct = case when @po_ctrl_num like 'R%' then 0 else 1 end       
 END      
 ELSE      
 BEGIN       
   SELECT @post = acct_code,             
     @status = status              
   FROM inventory      
   WHERE part_no = @item_code and location = @location_code      
      
   if isnull(@status,'V') = 'V' and @po_ctrl_num not like 'R%'         
   begin      
     select @send_inv_acct = 1             
   end      
 END      
      
 if @RCV_MISC_IN_COGP = 'Y' select @send_inv_acct = 0          
 if @send_inv_acct = 0               
 begin      
   SELECT @gl_exp_acct = ap_cgp_code      
   FROM in_account      
   WHERE acct_code = @post      
      
   select @gl_exp_acct = dbo.adm_mask_acct_fn(@gl_exp_acct,@org_id)      
      
   select @issue_ref_code = ''        -- mls 11/05/03 SCR 32031 start      
   if exists (select 1 from glrefact (nolock) where @gl_exp_acct like account_mask and reference_flag > 1)      
   begin      
     if exists (select 1 from glratyp t (nolock), glref r (nolock)      
       where t.reference_type = r.reference_type and @gl_exp_acct like t.account_mask and      
     r.status_flag = 0 and r.reference_code  = @reference_code)      
     begin      
       select @issue_ref_code = @reference_code      
     end      
   end           -- mls 11/05/03 SCR 32031 end      
 end                
      
 END       
      
       
      
      
      
 if @orig_curr_factor <> @rate_home      
 BEGIN      
       
 select @rate_home = @rate_home      
 END      
      
  SELECT @sequence_id = ISNULL((select MAX( sequence_id )      
  FROM #apinpcdt       
  WHERE trx_ctrl_num = @trx_ctrl_num AND trx_type = @trx_type),0) + 1      
      
  if @i_eprocurement_ind = 1 and isnull(@proc_po_no,'') != ''      
    select @po_ctrl_num = @proc_po_no      
      
  INSERT #apinpcdt ( trx_ctrl_num,      
    trx_type, sequence_id, location_code, item_code, bulk_flag, qty_ordered, qty_received, qty_returned,      
    qty_prev_returned, approval_code, tax_code, return_code, code_1099, po_ctrl_num, unit_code,      
    unit_price, amt_discount, amt_freight, amt_tax, amt_misc, amt_extended, calc_tax, date_entered,      
    gl_exp_acct, new_gl_exp_acct, rma_num, line_desc, serial_id, company_id, iv_post_flag, po_orig_flag,      
    rec_company_code, new_rec_company_code, reference_code, new_reference_code, trx_state, mark_flag, org_id,      
    amt_nonrecoverable_tax, amt_tax_det)      
  VALUES ( @trx_ctrl_num, @trx_type, @sequence_id, substring(@location_code,1,8), @item_code, 0, @qty_ordered,      
    @qty_received, @qty_returned, 0, '', @tax_code, @return_code, @code_1099,      
    @po_ctrl_num, @unit_code, @unit_price, @amt_discount, @amt_freight, @amt_tax, @amt_misc, @amt_extended,      
    @calc_tax, @date_entered, @gl_exp_acct, '', @rma_num, @line_desc, 0, @company_id,      
    0, 1, @company_code, '', @issue_ref_code, '', 0, 0  , @org_id,      
    IsNull(@amt_nonrecoverable_tax,0), IsNull(@amt_tax_det,0))        -- CVO FIX      
      
  select @result = @@error      
  IF ( @result != 0 )      
  BEGIN      
    exec adm_post_ap_cancel_tax @msg2 out      
    select @err = -60      
  select @msg = 'Error inserting on #apinpcdt'      
  select @msg2 = ''      
  goto write_admresults      
  END      
      
insert #apinptaxdtl (trx_ctrl_num, sequence_id, trx_type, tax_sequence_id, detail_sequence_id, tax_type_code,      
  amt_taxable, amt_gross, amt_tax, amt_final_tax, recoverable_flag, account_code, mark_flag)      
select @trx_ctrl_num, t.sequence_id, @trx_type, t.tax_sequence_id, t.detail_sequence_id, t.tax_type_code,      
  t.amt_taxable, t.amt_gross, t.amt_tax, t.amt_final_tax, t.recoverable_flag, @gl_exp_acct, 0      
from adm_pomchtaxdtl t      
join adm_pomchcdt d on d.match_ctrl_int = t.match_ctrl_int and d.match_line_num = t.detail_sequence_id      
where t.match_ctrl_int = @match_id and t.detail_sequence_id = @rid      
      
  select @result = @@error      
  IF ( @result != 0 )      
  BEGIN      
    exec adm_post_ap_cancel_tax @msg2 out      
    select @err = -61      
  select @msg = 'Error inserting on #apinptaxdtl'      
  select @msg2 = ''      
  goto write_admresults      
  END      
      
 select @rid = isnull((select min(match_line_num)      
 FROM adm_pomchcdt      
 WHERE match_ctrl_int = @match_id AND       match_line_num > @rid),0)      
      
 END       
      
      
if @amt_misc_temp < 0 and @trx_type = 4092      -- mls 1/19/06 SCR 28441       
begin      
  select @gl_exp_acct = isnull((select misc_chg_acct_code      
    from apaccts where posting_code = @posting_code), NULL)      
      
  select @gl_exp_acct = dbo.adm_mask_acct_fn(@gl_exp_acct,@h_org_id)      
      
  SELECT @qty_ordered = 1, @qty_received = 1, @qty_returned = 0      
  IF @trx_type = 4092      
    select @qty_received = 0, @qty_returned = 1      
      
  SELECT @sequence_id = ISNULL((select MAX( sequence_id )      
  FROM #apinpcdt       
  WHERE trx_ctrl_num = @trx_ctrl_num AND trx_type = @trx_type),0) + 1      
      
  select @issue_ref_code = ''        -- mls 11/05/03 SCR 32031 start      
  if exists (select 1 from glrefact (nolock) where @gl_exp_acct like account_mask and reference_flag > 1)      
  begin      
    if not exists (select 1 from glratyp t (nolock), glref r (nolock)      
      where t.reference_type = r.reference_type and @gl_exp_acct like t.account_mask and      
      r.status_flag = 0 and r.reference_code  = @reference_code)      
    begin      
      select @issue_ref_code = ''      
    end      
  end           -- mls 11/05/03 SCR 32031 end      
      
  INSERT #apinpcdt ( trx_ctrl_num,      
    trx_type, sequence_id, location_code, item_code, bulk_flag, qty_ordered, qty_received, qty_returned,      
    qty_prev_returned, approval_code, tax_code, return_code, code_1099, po_ctrl_num, unit_code,      
    unit_price, amt_discount, amt_freight, amt_tax, amt_misc, amt_extended, calc_tax, date_entered,      
    gl_exp_acct, new_gl_exp_acct, rma_num, line_desc, serial_id, company_id, iv_post_flag, po_orig_flag,      
    rec_company_code, new_rec_company_code, reference_code, new_reference_code, trx_state, mark_flag, org_id,      
    amt_nonrecoverable_tax, amt_tax_det)      
  VALUES ( @trx_ctrl_num, @trx_type, @sequence_id, substring(@location_code,1,8), 'Misc Amount', 0, @qty_ordered,      
    @qty_received, @qty_returned, 0, '', @tax_code, @return_code, @code_1099,      
    @po_ctrl_num, 'EA', 0, 0, 0, 0, @amt_misc_temp, 0,      
    0, @date_entered, @gl_exp_acct, '', @rma_num, 'Miscellaneous Amount', 0, @company_id,      
    0, 1, @company_code, '', @issue_ref_code, '', 0, 0  , @h_org_id, 0, 0 )      
      
  select @result = @@error      
  IF ( @result != 0 )      
  BEGIN      
    exec adm_post_ap_cancel_tax @msg2 out      
    select @err = -61      
  select @msg = 'Error inserting on #apinpcdt (misc amt)'      
  select @msg2 = ''      
  goto write_admresults      
  END      
end        
      
      
 select @rid = isnull((select min(sequence_id) FROM adm_pomchtax WHERE match_ctrl_int = @match_id),0)      
 WHILE @rid != 0      
 BEGIN      
      
 SELECT @tax_type_code = tax_type_code,      
 @amt_taxable = amt_taxable,      
 @amt_gross  = amt_gross,      
 @amt_tax  = amt_tax,      
 @amt_final_tax = amt_final_tax      
 FROM adm_pomchtax      
 WHERE match_ctrl_int = @match_id AND      
 sequence_id = @rid      
      
SELECT @sequence_id = ISNULL((select MAX( sequence_id )      
FROM #apinptax       
WHERE trx_ctrl_num = @trx_ctrl_num      
AND trx_type = @trx_type),0) + 1      
      
INSERT #apinptax ( trx_ctrl_num, trx_type,      
 sequence_id, tax_type_code, amt_taxable, amt_gross, amt_tax, amt_final_tax, trx_state, mark_flag )      
VALUES ( @trx_ctrl_num, @trx_type,      
 @sequence_id, @tax_type_code, @amt_taxable, @amt_gross, @amt_tax, @amt_final_tax, 2,    0  )      
      
select @result = @@error      
IF ( @result != 0 )      
BEGIN      
  exec adm_post_ap_cancel_tax @msg2 out      
  select @err = -70      
  select @msg = 'Error inserting on #apinptax'      
  select @msg2 = ''      
  goto write_admresults      
END      
      
 select @rid = isnull((select min(sequence_id) FROM adm_pomchtax WHERE match_ctrl_int = @match_id and sequence_id > @rid),0)      
 END       
      
 end -- tax_rc = 1      
      
 SELECT @xlp = isnull((select min(match_ctrl_int)      
 FROM adm_pomchchg_all      
 WHERE match_ctrl_int > @xlp and      
 match_posted_flag = -1 and      
 process_group_num = @process_group_num and      
 trx_type = @type),0)      
      
 END       
      
 if @trx_type = 4091      
 BEGIN      
  if exists (select 1 from #apinpchg)      
  begin      
 EXEC @result = apvoval_sp      
      
 IF @result != 0      
 BEGIN      
   exec adm_post_ap_cancel_tax @msg2 out      
   select @err = -80      
  select @msg = 'Error with apvoval_sp'      
  select @msg2 = ''      
  goto write_admresults      
 END      
      
 EXEC @result = apvchedt_sp 1      
      
 IF @result != 0      
 BEGIN      
   exec adm_post_ap_cancel_tax @msg2 out      
   select @err = -90      
  select @msg = 'Error with apvchedt_sp'      
  select @msg2 = ''      
  goto write_admresults      
 END      
      
 select @dbname = db_name()      
      
 EXEC @result = apvedb_sp @dbname,@dbname,      
  0,       
    1,       
 0       
      
 IF @result != 0      
 BEGIN      
   exec adm_post_ap_cancel_tax @msg2 out      
   select @err = -100      
  select @msg = 'Error with apvedb_sp'      
  select @msg2 = ''      
  goto write_admresults      
 END      
      
 -- remove errors related to approval since that will be done in AP      
 delete from #ewerror where err_code in (10580,11400)     -- mls 4/24/03 SCR 31000      
      
 -- remove errors related to batch code not on batch table since creating the voucher in AP will put      
 -- the batch on the batchctl table      
 delete from #ewerror where err_code in (10040,20040)     -- mls 5/10/04 SCR 32704      
      
 if ( select count(*) from #ewerror) > 0      
 BEGIN      
   exec adm_post_ap_cancel_tax @msg2 out      
      
   UPDATE adm_pomchchg_all      
   SET match_posted_flag = 0,      
     process_group_num = NULL      
   WHERE process_group_num = @process_group_num      
      
   select @err = -105      
  insert #adm_results (      
    module_id,  err_code,  info1,   info2 ,      
    infoint,   infofloat ,  flag1 ,  trx_ctrl_num ,  sequence_id ,       
    source_ctrl_num , extra, match_ctrl_int, ewerror_ind)      
  select       
    e.module_id,  e.err_code,  e.info1,  e.info2 ,      
    e.infoint,   e.infofloat ,  e.flag1 ,  e.trx_ctrl_num, e.sequence_id,       
    e.source_ctrl_num , e.extra,  h.po_ctrl_num, 1      
  from #ewerror e      
  left outer join #apvovchg h on h.trx_ctrl_num = e.trx_ctrl_num      
  goto ret_process      
 END      
end -- exists #apinpchg      
 END      
ELSE      
 BEGIN      
  if exists (select 1 from #apinpchg)      
  begin      
      
 EXEC @result = apdmval_sp      
      
 IF @result != 0      
 BEGIN      
   exec adm_post_ap_cancel_tax @msg2 out      
   select @err = -80      
  select @msg = 'Error with apdmval_sp'      
  select @msg2 = ''      
  goto write_admresults      
 END      
      
 EXEC @result = apdbmedt_sp 1      
      
 IF @result != 0      
 BEGIN      
   exec adm_post_ap_cancel_tax @msg2 out      
   select @err = -90      
  select @msg = 'Error with apdbmedt_sp'      
  select @msg2 = ''      
  goto write_admresults      
 END      
      
 select @dbname = db_name()      
      
 EXEC @result = apdedb_sp @dbname,@dbname,      
  0,       
    1,       
 0       
      
 IF @result != 0      
 BEGIN      
   exec adm_post_ap_cancel_tax @msg2 out      
   select @err = -100      
  select @msg = 'Error with apdedb_sp'      
  select @msg2 = ''      
  goto write_admresults      
 END      
      
 if ( select count(*) from #ewerror) > 0      
 BEGIN      
   exec adm_post_ap_cancel_tax @msg2 out      
      
   UPDATE adm_pomchchg_all      
   SET match_posted_flag = 0,      
     process_group_num = NULL      
   WHERE process_group_num = @process_group_num      
      
   select @err = -105      
  insert #adm_results (      
    module_id,  err_code,  info1,   info2 ,      
    infoint,   infofloat ,  flag1 ,  trx_ctrl_num ,  sequence_id ,       
    source_ctrl_num , extra, match_ctrl_int, ewerror_ind)      
  select       
    e.module_id,  e.err_code,  e.info1,  e.info2 ,      
    e.infoint,   e.infofloat ,  e.flag1 ,  e.trx_ctrl_num, e.sequence_id,       
    e.source_ctrl_num , e.extra,  h.po_ctrl_num, 1      
  from #ewerror e      
  left outer join #apdmvchg h on h.trx_ctrl_num = e.trx_ctrl_num      
  goto ret_process      
 END      
  end -- exists apinpchg      
      
 END      
      
 BEGIN TRAN      
 if exists (select 1 from #apinpchg)      
 begin      
      
 EXEC @result = apvosav_sp @user_id      
      
 IF @result != 0      
 BEGIN      
 ROLLBACK TRAN      
 exec adm_post_ap_cancel_tax @msg2 out      
      
 UPDATE adm_pomchchg_all      
 SET match_posted_flag = 0      
 WHERE process_group_num = @process_group_num      
      
      
 SELECT @err = -110      
  select @msg = 'Error with apvosav_sp'      
  select @msg2 = ''      
  goto write_admresults      
 END      
      
 if @approval_code != ''        -- mls 1/7/05 SCR 34063 start      
 begin      
   DECLARE vouchers CURSOR LOCAL FOR      
     SELECT trx_ctrl_num FROM apinpchg where process_group_num = @process_group_num      
      
   OPEN vouchers      
   FETCH NEXT FROM vouchers INTO @trx_ctrl_num      
      
   While @@FETCH_STATUS = 0      
   begin      
     exec apaprmk_sp @trx_type,@trx_ctrl_num, @date_entered      
      
     select @trx_ctrl_num = isnull((select min(trx_ctrl_num) from apinpchg where process_group_num = @process_group_num      
       and trx_ctrl_num > @trx_ctrl_num),NULL)      
     FETCH NEXT FROM vouchers INTO @trx_ctrl_num      
   end      
      
   CLOSE vouchers      
   DEALLOCATE vouchers      
 end          -- mls 1/7/05 SCR 34063 end      
 end      
      
 UPDATE m      
 SET match_posted_flag = 1      
 from adm_pomchchg_all m, #vouchers v      
 where v.match_ctrl_int = m.match_ctrl_int      
   and m.process_group_num = @process_group_num      
      
 UPDATE m      
 SET match_posted_flag = 0,      
   process_group_num = NULL      
 from adm_pomchchg m      
 where m.process_group_num = @process_group_num and match_posted_flag != 1      
      
 COMMIT TRAN      
      
      
 SELECT @err = 1      
      
if @err = 1      
begin      
  select @msg = 'OK'      
  select @msg2 = ''      
  set @err = 1      
  set @result = 1      
end      
      
write_admresults:      
if not exists (select 1 from #adm_results)      
begin      
  if @err = 1      
  begin      
    insert #adm_results (      
      module_id,  err_code,  info1,   info2 ,      
      infoint,   infofloat ,  flag1 ,  trx_ctrl_num ,  sequence_id ,       
      source_ctrl_num , extra, match_ctrl_int, ewerror_ind)      
    select       
      18000,  @result,  @msg ,  @msg2,      
      0,   0 ,  '' ,  trx_ctrl_num, '',      
      trx_ctrl_num , '',  match_ctrl_int, 0      
    from #vouchers       
  end      
  else      
  begin      
    if @err = 1000 set @err = 1 -- no matches found      
    insert #adm_results (      
      module_id,  err_code,  info1,   info2 ,      
      infoint,   infofloat ,  flag1 ,  trx_ctrl_num ,  sequence_id ,       
      source_ctrl_num , extra, match_ctrl_int, ewerror_ind)      
    select       
      18000,  @result,  @msg ,  @msg2,      
      0,   0 ,  '' ,  '', '',      
      @trx_ctrl_num , '',  @xlp, 0          
  end      
end      
else      
begin      
  if @err = 1 set @err = -105      
end      
      
ret_process:      
if @online_call = 1      
begin   
 
    select @err, module_id,  e.err_code,  info1,        
      case when ewerror_ind = 0 then '' else info2 end ,      
      infoint,   infofloat ,  flag1 ,  trx_ctrl_num ,  sequence_id ,       
      case when source_ctrl_num = '' then convert(varchar,match_ctrl_int) else source_ctrl_num end ,       
      extra,   match_ctrl_int,      
   a.refer_to, a.field_desc,       
      case when ewerror_ind = 1 then a.err_desc else info2 end err_desc      
    from #adm_results e      
    left outer join apedterr a on a.err_code = e.err_code and e.ewerror_ind = 1      
end      
return @err      
GO
GRANT EXECUTE ON  [dbo].[fs_post_ap] TO [public]
GO
