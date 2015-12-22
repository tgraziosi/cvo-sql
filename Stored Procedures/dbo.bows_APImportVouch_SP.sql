SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
            
CREATE PROCEDURE [dbo].[bows_APImportVouch_SP]                
   @debug_level smallint = 0                
AS                
                
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
 net_original_amt  float,                
 org_id   varchar(30),                 interbranch_flag smallint,                
 temp_flag  smallint,                
 tax_freight_no_recoverable float --Added RCGT                
)                
CREATE INDEX apvovchg_ind_1 ON #apvovchg (trx_ctrl_num)            
                
CREATE TABLE #apvovcdt                
(                
 trx_ctrl_num  varchar(16),                
 trx_type   smallint,                
 sequence_id   int,                
 location_code  varchar(8),                
 item_code  varchar(30),                
 bulk_flag   smallint,                
 qty_ordered   float,                
 qty_received  float,                
 approval_code  varchar(8),                
 tax_code   varchar(8),                
 code_1099   varchar(8),                
 po_ctrl_num varchar(16),                
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
 org_id    varchar(30),                
 temp_flag   smallint,                
 amt_nonrecoverable_tax float --Added RCGT                
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
                
CREATE TABLE #apvobat (                
      date_applied int,                
      process_group_num varchar(16),                
      trx_type smallint,                
      hold_flag smallint,                
      org_id   varchar(30)                
     )                
                
CREATE TABLE #apveacct                
(                
 db_name varchar(128),                
 vchr_num varchar(16),                
 line int,                
 type smallint,                
 acct_code varchar(32),                
 date_applied int,                
 reference_code varchar(32),                
 flag smallint,                 
 org_id nvarchar(30) -->>8.1RCGT, RGM                
                
)                
                
CREATE TABLE #apvtemp (                
      code varchar(12),                
      code2 varchar(8),                
      amt_net_home float,                
      amt_net_oper float                
     )                
                
CREATE TABLE #apterms                
(                
 date_doc int,                
 terms_code varchar(8),                
 date_due int,                
 date_discount int                
)                
                
CREATE TABLE #bows_invalid_acct (                
 trx_ctrl_num  varchar(16),                
 trx_type  smallint,                
 sequence_id  int,                
 account_code  varchar(32),                
 reference_code  varchar(32)                
)                
                
CREATE TABLE #comments                
(                
 company_code varchar(8),                
 key_1 varchar(32),                
 key_type smallint,                
 sequence_id int,                
 date_created int,                
 created_by smallint,                
 date_updated int,                
 updated_by smallint,                
 link_path varchar(255),       
 note varchar(255)                
)                
                
CREATE TABLE #apvov_companies                
(                 
 rec_company_code varchar(8),                
 trx_ctrl_num  varchar(16)                
)                
CREATE INDEX apvov_companies_ind_1 ON #apvov_companies (trx_ctrl_num, rec_company_code)                
                
                
                
-->>8.1RCGT, RGM                
CREATE TABLE #apvovtaxdtl                
(                
 trx_ctrl_num varchar (16),                
 sequence_id int,                 
 trx_type int,                
 tax_sequence_id int,                
 detail_sequence_id int,                
 tax_type_code varchar(8),                
 amt_taxable float,                
 amt_gross   float,                
 amt_tax float,                
 amt_final_tax float,                
 recoverable_flag int,                
 account_code varchar(32)                
)                
-->>8.1RCGT, RGM                
                
--Begin Rev 3                
CREATE TABLE #txinfo_id                
 (                
  id_col   numeric identity,                
  control_number varchar(16),                
  sequence_id  int,                
  tax_type_code  varchar(8),                
  currency_code  varchar(8)                
 )                
--End Rev 3                
                
DECLARE @approval_flag smallint,                
 @intercompany_flag smallint,                
 @iv_post_flag smallint,                
 @next_serial_id smallint,                
 @one_check_flag smallint,                
 @po_orig_flag smallint,                
 @trx_type smallint,                
 @user_id smallint                
                
DECLARE @company_id int,                
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
 @period_end int,                
 @precision int,                
 @result int,                
 @sequence int ,                
 @sequence_id int,                
 @in_sequence_id int,                
 @serial_id int,                
 @terms_days int,                
 @terms_type int                
                
DECLARE @amt_due float,                
 @amt_discount float,                
 @amt_extended float,                
 @amt_final_tax float,                
 @amt_freight float,                
 @amt_gross float,                
 @amt_misc float,                
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
 @unit_price float,                
 @qty_returned decimal(20,8),                
 @flag_1099 char(1),                
 @location varchar(5),                
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
 @po_no varchar(10),                
 @vendor varchar(10),                
 @vendor_code varchar(12),              
 @batch_code varchar(16),                
 @batch_num varchar(16),                
 @doc_ctrl_num varchar(16),                
 @old_batch varchar(16),                
 @po_ctrl_num varchar(16),                
 @trx_ctrl_num varchar(16),                
 @in_trx_ctrl_num varchar(16),                
 @voucher_no varchar(16),                
 @item_code varchar(30),                
 @rma_num varchar(20),                
 @vend_order_num varchar(20),                
 @attention_phone varchar(30),                
 @plt_name char(30),                
 @gl_exp_acct varchar(32),                
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
 @line_desc varchar(60),                
 @dbname varchar(255),                
  @apply_to_num varchar(16),                
  @ticket_num varchar(20),                
  @recurring_code varchar(8),                
  @recurring_flag smallint,                
 @rate_type_home_ap varchar(8),                
 @rate_type_oper_ap varchar(8),                
 @org_id_hdr varchar(30),                
 @org_id_det varchar(30),                
 @no_recoverable_taxes float -->>8.1RCGT, RGM                
                
                
DECLARE @inv_acct_no varchar(32),                
 @inv_ref_code varchar(32),                
  @status char(1),                
  @send_inv_acct int,                
  @process_group_num varchar(16),                
  @datenow int,                
  @err int,                
  @err_proc varchar(32),                
  @err_info varchar(32)                
                
DECLARE @user_name   varchar(30),                
 @batch_description  varchar(30),                
 @batch_close_flg  int,                
 @batch_hold_flg  int,                
 @completed_date  int,                
 @completed_time  int,                
 @error_account_flg int,                
 @error_account_code varchar(32),                
 @use_psaTrx  int,                
@line_count  int,                
 @trx_ctrl_num_int int,                
 @APApplyDocPosted int,                
 @hold_flag  smallint                
                
DECLARE @approval_code_dtl varchar(8)                 
                
select * into #apinpchg_input from #apinpchg                
select * into #apinpcdt_input from #apinpcdt                
truncate table #apinpchg                
truncate table #apinpcdt                
truncate table #ewerror                      
SELECT  @err   = 0,                
 @err_info = '',                
 @datenow  = datediff( day, '01/01/1900', getdate() ) + 693596,                
 @process_group_num = '1',                
 @in_trx_ctrl_num  = CHAR(0),                
 @precision  = 2                
                
SELECT  @company_id   = company_id,                
  @home_curr   = glco.home_currency,                
  @oper_curr  = glco.oper_currency                
FROM  glco(nolock)                
                
SELECT  @company_code  = company_code                
FROM  glcomp_vw (nolock)                
WHERE  company_id = @company_id                
                
SELECT  @user_name   = APUserName,                
 @batch_description  = APBatchDescription,                
 @batch_close_flg  = APBatchCloseFlag,                
 @batch_hold_flg  = APBatchHoldFlag,                
 @error_account_flg = APErrorAccountFlag,                
 @error_account_code = ErrorAccountCode,                
 @APApplyDocPosted = APApplyDocPosted,                
 @po_orig_flag  = 0--po_orig_flag --SCR 13284 --fzambada                
FROM  bows_Config                
                
IF ISNULL(@user_id,0) = 0 BEGIN                
 SELECT @user_name = ISNULL(@user_name, (SELECT [name]                
    FROM [master]..[syslogins]                
    WHERE [sid] = SUSER_SID()))                
 SELECT @user_id = [user_id]                
 FROM ewusers_vw                
 WHERE [user_name] = @user_name                
END                
                
SELECT  @intercompany_flag = intercompany_flag,                
 @rate_type_home_ap = rate_type_home,                
 @rate_type_oper_ap = rate_type_oper                
 FROM apco                
                
WHILE (1=1) BEGIN                
                
 SET ROWCOUNT 1                
 SELECT  @in_trx_ctrl_num  = ISNULL(trx_ctrl_num,''),                
  @nat_cur_code   = nat_cur_code,                
  @rate_type_home  = ISNULL(rate_type_home, @rate_type_home_ap),                
  @rate_type_oper  = ISNULL(rate_type_oper, @rate_type_oper_ap),                
  @vendor_code  = vendor_code                
   FROM #apinpchg_input                
   WHERE ISNULL(trx_ctrl_num,'') > @in_trx_ctrl_num                
  ORDER BY trx_ctrl_num                
                
 IF @@rowcount=0 BREAK                
 SET ROWCOUNT 0                
                
 IF NOT EXISTS(SELECT 1 FROM apvend WHERE vendor_code = @vendor_code) BEGIN                
  BEGIN INSERT #ewerror SELECT 4000, 40210,@vendor_code,'',0,0.0, 1, @in_trx_ctrl_num,0, '', 0 BEGIN SELECT @result = @@error IF @result<>0 BEGIN SELECT @err = 5, @err_proc='bows_APImportVouch_SP' GOTO lbFinal END END END                
  CONTINUE                
 END                
                
  SELECT @precision = ISNULL((SELECT curr_precision                
     FROM glcurr_vw                
     WHERE glcurr_vw.currency_code=@nat_cur_code), 2)                
                
 SELECT @amt_gross = SUM((SIGN(d.amt_extended) * ROUND(ABS(d.amt_extended) + 0.0000001, @precision)))                
  FROM #apinpcdt_input d                
 WHERE d.trx_ctrl_num = @in_trx_ctrl_num                
 GROUP BY d.trx_ctrl_num                
                
 UPDATE #apinpchg_input                
   SET amt_gross= CASE WHEN (SIGN(amt_gross) * ROUND(ABS(amt_gross) + 0.0000001, @precision))=0.0 THEN @amt_gross ELSE amt_gross END,                
  amt_net = CASE WHEN (SIGN(amt_gross) * ROUND(ABS(amt_gross) + 0.0000001, @precision))=0.0 THEN @amt_gross ELSE amt_net END,                
  amt_due = CASE WHEN (SIGN(amt_gross) * ROUND(ABS(amt_gross) + 0.0000001, @precision))=0.0 THEN @amt_gross ELSE amt_due END                
 WHERE trx_ctrl_num = @in_trx_ctrl_num                
                
  SELECT                
  @trx_ctrl_num   = @in_trx_ctrl_num,                
  @doc_ctrl_num  = h.doc_ctrl_num,                
  @trx_type   = h.trx_type,                
  @user_trx_type_code  = ISNULL(h.user_trx_type_code,v.user_trx_type_code),  --v.user_trx_type_code,        --fzambada        
  @batch_code  = '',                
  @po_ctrl_num   = isnull(h.po_ctrl_num, ''),--'', --rev 9                
  @vend_order_num  = '',                
  @apply_to_num  = CASE  WHEN trx_type=4092 THEN h.apply_to_num                
      ELSE ''                
      END,                
  @ticket_num  = '',                
  @recurring_code  = ISNULL(recurring_code,''),                
/*Change Dates*/            
@date_applied   = CASE ISNULL(h.date_entered,0) WHEN 0 THEN @datenow ELSE h.date_entered END,--@datenow, --CASE ISNULL(h.date_applied,0) WHEN 0 THEN @datenow ELSE h.date_applied END,                
  @date_aging   = CASE ISNULL(h.date_entered,0) WHEN 0 THEN @datenow ELSE h.date_entered END,--@datenow, --CASE ISNULL(h.date_aging,0) WHEN 0 THEN @datenow ELSE h.date_aging END,                
  --@date_due   = ISNULL(h.date_due,0),                
@date_due   = CASE ISNULL(h.date_aging,0) WHEN 0 THEN @datenow ELSE h.date_aging END,      --fzambada          
  --@date_doc   = @datenow, --CASE ISNULL(h.date_doc,0) WHEN 0 THEN @datenow ELSE h.date_doc END,                
@date_entered=CASE ISNULL(h.date_entered,0) WHEN 0 THEN @datenow ELSE h.date_entered END,        --fzambada          
--@date_entered   = @datenow, --        
  @date_doc=@date_entered,        
  @date_received   = @date_entered,--@datenow, --CASE ISNULL(h.date_received,0) WHEN 0 THEN @datenow ELSE h.date_received END,                
  @date_required   = @date_entered,--@datenow,--CASE ISNULL(h.date_required,0) WHEN 0 THEN @datenow ELSE h.date_required END,                
  @date_recurring  = @date_entered,--@datenow, --CASE ISNULL(h.date_recurring,0) WHEN 0 THEN 0 ELSE h.date_recurring END,                
  @date_discount   = @date_entered,--@datenow, --ISNULL(h.date_discount,0),                
/*End Change Dates */          
  @posting_code   = v.posting_code,                
  @vendor_code   = h.vendor_code,                
  @pay_to_code   = CASE ISNULL(h.pay_to_code,'') WHEN '' THEN v.pay_to_code ELSE h.pay_to_code END,                
  @pay_to_addr1   = h.pay_to_addr1,                
  @pay_to_addr2   = h.pay_to_addr2,                
  @pay_to_addr3   = h.pay_to_addr3,                
  @pay_to_addr4   = h.pay_to_addr4,                
  @pay_to_addr5   = h.pay_to_addr5,                
  @pay_to_addr6   = h.pay_to_addr6,                
  @attention_name  = h.attention_name,                
  @attention_phone = h.attention_phone,                
  @branch_code   = CASE ISNULL(h.branch_code,'') WHEN '' THEN v.branch_code ELSE h.branch_code END,                
  @class_code   = CASE ISNULL(h.class_code,'') WHEN '' THEN v.vend_class_code ELSE h.class_code END,                
        @approval_code   = ISNULL(h.approval_code,''),                
  @fob_code   = v.fob_code,                
  @terms_code   = CASE ISNULL(h.terms_code,'') WHEN '' THEN v.terms_code ELSE h.terms_code END,                
  @tax_code   = CASE ISNULL(h.tax_code,'') WHEN '' THEN v.tax_code ELSE h.tax_code END,                
  @location_code   = CASE ISNULL(h.location_code,'') WHEN '' THEN v.location_code ELSE h.location_code END,                
  @approval_flag   = ISNULL(h.approval_flag,0),                
  @one_check_flag  = 0,                
  @amt_gross   = (SIGN(h.amt_gross) * ROUND(ABS(h.amt_gross) + 0.0000001, @precision)),                
  @amt_discount   = (SIGN(h.amt_discount) * ROUND(ABS(h.amt_discount) + 0.0000001, @precision)),                
  @amt_tax   = (SIGN(h.amt_tax) * ROUND(ABS(h.amt_tax) + 0.0000001, @precision)),                
  @amt_freight   = (SIGN(h.amt_freight) * ROUND(ABS(h.amt_freight) + 0.0000001, @precision)),                
  @amt_misc   = (SIGN(h.amt_misc) * ROUND(ABS(h.amt_misc) + 0.0000001, @precision)),                
  @amt_net   = (SIGN(h.amt_net) * ROUND(ABS(h.amt_net) + 0.0000001, @precision)),                
  @amt_paid   = 0,                
  @amt_due   = (SIGN(h.amt_due) * ROUND(ABS(h.amt_due) + 0.0000001, @precision)),                
  @amt_restock   = 0,                
  @amt_tax_included  = ISNULL((SIGN(h.amt_tax_included) * ROUND(ABS(h.amt_tax_included) + 0.0000001, @precision)),0.0),                
  @frt_calc_tax   = 0,                
  @doc_desc   = ISNULL(h.doc_desc,''),                
  @hold_desc   = ISNULL(h.hold_desc,''),                
  @hold_flag  = ISNULL(h.hold_flag,13),                
  @next_serial_id  = 0,                
  @process_group_num  = '',                
  @code_1099    = isnull(v.code_1099,''), -- Rev 1                
  --@code_1099    = v.code_1099,  -- Rev 1                  
  @payment_type   = CASE ISNULL(h.payment_code,'') WHEN '' THEN v.payment_code ELSE h.payment_code END,                  
  @comment_code   = CASE ISNULL(h.comment_code,'') WHEN '' THEN isnull(v.comment_code,'') ELSE isnull(h.comment_code,'') END, -- Rev 1                
  --@comment_code   = CASE ISNULL(h.comment_code,'') WHEN '' THEN v.comment_code ELSE h.comment_code END,    -- Rev 1                
                  
  @recurring_flag  = ISNULL(h.recurring_flag,0),                
  @rate_home  = h.rate_home,                
  @rate_oper  = h.rate_oper,                 
  @intercompany_flag = ISNULL(h.intercompany_flag,  @intercompany_flag),                
  @org_id_hdr   = ISNULL(h.org_id, '')                
  FROM #apinpchg_input h, apvend v                
 WHERE h.trx_ctrl_num = @in_trx_ctrl_num                
  AND h.vendor_code = v.vendor_code               
          
/*          
select 'date debug'          
--select * from #apinpchg_input          
select @date_entered        
select @datenow   --fzambaa           
  */              
 IF @rate_home IS NULL BEGIN                
   EXEC @result = CVO_Control..mccurate_sp  @date_applied,@nat_cur_code,@home_curr,@rate_type_home,                
       @rate_home OUTPUT,0,@divop OUTPUT                
   IF ISNULL(@result,-1) <> 0 BEGIN                
   BEGIN INSERT #ewerror SELECT 4000, 18004,@nat_cur_code + '-' + @home_curr + '-' + @rate_type_home,'',0,0.0, 1, @in_trx_ctrl_num,0, '', 0 BEGIN SELECT @result = @@error IF @result<>0 BEGIN SELECT @err = 5, @err_proc='bows_APImportVouch_SP' GOTO lbFinal 
 
    
      
        
           
END END END                
   CONTINUE                
   END                
 END                
                
 IF @rate_oper IS NULL BEGIN                
   EXEC @result = CVO_Control..mccurate_sp @date_applied,@nat_cur_code,@oper_curr,@rate_type_oper,                
       @rate_oper OUTPUT,0,@divop OUTPUT                
   IF ISNULL(@result,-1) <> 0 BEGIN                
   BEGIN INSERT #ewerror SELECT 4000, 18004,@nat_cur_code + '-' + @oper_curr + '-' + @rate_type_oper,'',0,0.0, 1, @in_trx_ctrl_num,0, '', 0 BEGIN SELECT @result = @@error IF @result<>0 BEGIN SELECT @err = 5, @err_proc='bows_APImportVouch_SP' GOTO lbFinal 
  
    
      
        
          
END END END                
   CONTINUE                
   END                
 END                
                
 IF @pay_to_code <> ''                
   SELECT                
   @pay_to_addr1 = ISNULL(@pay_to_addr1,addr1),                
   @pay_to_addr2 = ISNULL(@pay_to_addr2,addr2),                
    @pay_to_addr3 = ISNULL(@pay_to_addr3,addr3),                
   @pay_to_addr4 = ISNULL(@pay_to_addr4,addr4),                
   @pay_to_addr5 = ISNULL(@pay_to_addr5,addr5),                
   @pay_to_addr6 = ISNULL(@pay_to_addr6,addr6),                
   @attention_name = ISNULL(@attention_name,attention_name),                
   @attention_phone = ISNULL(@attention_phone,attention_phone)                
    FROM appayto              
    WHERE vendor_code = @vendor_code                
   AND pay_to_code = @pay_to_code                
 ELSE                
   SELECT                
   @pay_to_addr1 = ISNULL(@pay_to_addr1,addr1),                
   @pay_to_addr2 = ISNULL(@pay_to_addr2,addr2),                
    @pay_to_addr3 = ISNULL(@pay_to_addr3,addr3),                
   @pay_to_addr4 = ISNULL(@pay_to_addr4,addr4),                
   @pay_to_addr5 = ISNULL(@pay_to_addr5,addr5),                
   @pay_to_addr6 = ISNULL(@pay_to_addr6,addr6),                
   @attention_name = ISNULL(@attention_name,attention_name),                
   @attention_phone = ISNULL(@attention_phone,attention_phone)                
    FROM apvend                
    WHERE vendor_code = @vendor_code                
                
 IF (@trx_type=4092) AND (ISNULL(@apply_to_num,'')<>'') BEGIN                
                
  --Begin rev 7                
  IF EXISTS(select 1 from apinpchg where apply_to_num=@apply_to_num)                
  BEGIN                
   declare @unpostedDebitMemoNum varchar(32)                
   set @unpostedDebitMemoNum = (select trx_ctrl_num from apinpchg where apply_to_num=@apply_to_num)                 
   BEGIN INSERT #ewerror SELECT 4000, -1,'There is an unposted Debit Memo for this Apply-To Voucher Number. Please Post the existing Debit Memo.','  Apply-To Num: ' + @apply_to_num +  ',  Debit Memo Num: ' + @unpostedDebitMemoNum,0,0.0, 1, @trx_ctrl_num, 
  
    
     
0        
          
          
              
, '', 0  GOTO lbFinal END                  
  END                
  --End rev 7                
                
  IF NOT EXISTS(SELECT 1 FROM apvohdr WHERE trx_ctrl_num=@apply_to_num) BEGIN                
   IF (@APApplyDocPosted = 0) BEGIN                
                
    BEGIN INSERT #ewerror SELECT 4000, 20020,@apply_to_num,'',0,0.0, 1, @trx_ctrl_num,0, '', 0 BEGIN SELECT @result = @@error IF @result<>0 BEGIN SELECT @err = 5, @err_proc='bows_APImportVouch_SP' GOTO lbFinal END END END                
    CONTINUE                
   END                
   ELSE BEGIN                
    INSERT INTO #bows_doc_notes (                
     trx_ctrl_num,                
     trx_type,                
     link,                
     note,                
     position_mode                
    )                
    SELECT @trx_ctrl_num,                
     @trx_type,                
     'HEADER:APPLY TO DOC',                
     'The debit memo is applied to a voucher ' + @apply_to_num +                
      ' which is not found in posted vouchers.' +                
      CASE                
      WHEN (@APApplyDocPosted = 1) THEN ' Debit Memo placed on hold. Voucher should be posted prior to Debit Memo.'                
      ELSE ' Debit memo amount is placed on account.'                
      END,                
     -1                
                
    IF (@APApplyDocPosted = 1) BEGIN                
                
     SET @hold_flag = 1            
     IF (@hold_desc='')                
      SET @hold_desc = 'Invalid Apply To. See Notes!'                
    END                
    IF (@APApplyDocPosted = 2)                 
     SET @apply_to_num = ''                
   END                
  END                
  ELSE BEGIN                
   --in rev 7, modified the following validation, the apply_to_num should be set to '' only when the sum of this debit memo                
   --plus the amt_paid_to_date exceeds the posted voucher (apvohdr table) net amount                 
   IF (EXISTS(SELECT 1 FROM apvohdr WHERE trx_ctrl_num = @apply_to_num AND ABS(amt_paid_to_date + @amt_net) > ABS(amt_net) ) OR --((ABS(amt_paid_to_date)) > (0.0) + 0.0000001)) OR                
    EXISTS(SELECT 1 FROM apinppdt WHERE apply_to_num = @apply_to_num) )                
    SET @apply_to_num = ''                
  END                
                
 END                
                
 EXEC @result = apvocrh_sp                
    4000,                
     2,                
    @trx_ctrl_num OUT,                
    @trx_type,                
     @doc_ctrl_num,                
    @apply_to_num,                
    @user_trx_type_code,                
    @batch_code,                
    @po_ctrl_num,                
    @vend_order_num,                
    @ticket_num,                
    @date_applied,                
    @date_aging,                
    @date_due,                
    @date_doc,                
    @date_entered,                
    @date_received,                
    @date_required,                
    @date_recurring,                
    @date_discount,                
    @posting_code,                
    @vendor_code,                
    @pay_to_code,                
    @branch_code,                
    @class_code,                
    @approval_code,                
    @comment_code,                
    @fob_code,                
    @terms_code,                
    @tax_code,                
    @recurring_code,                
    @location_code,                
    @payment_type, --payment code                
    0,                
    0,                
    0,                
    0,                
    @hold_flag,                
    0,                
    @approval_flag,                
    @recurring_flag,                
    0,                
    @one_check_flag ,                
    @amt_gross,        @amt_discount,                
    @amt_tax,                
    @amt_freight,                
    @amt_misc,                
    @amt_net,                
    @amt_paid,                
    @amt_due,                
    @amt_restock,                
    @amt_tax_included,                
    @frt_calc_tax,                
    @doc_desc,                
    @hold_desc,                
    @user_id,                
    @next_serial_id ,                
    @pay_to_addr1,                
    @pay_to_addr2,                
    @pay_to_addr3,                
    @pay_to_addr4,                
    @pay_to_addr5,                
    @pay_to_addr6,                
    @attention_name,                
    @attention_phone,                
    @intercompany_flag,                
    @company_code,                
    0,                
    @process_group_num,                
    @nat_cur_code ,                
    @rate_type_home ,                
    @rate_type_oper,                
    @rate_home,                
    @rate_oper,                
    @net_original_amt = @amt_net,                 
    @org_id = @org_id_hdr                
 IF (@result<>0) OR (@@error<>0) BEGIN SELECT @err = 30, @err_proc='apvocrh_sp', @err_info='error saving header' GOTO lbFinal END                
                
 SELECT @in_sequence_id = -1                
 WHILE (2=2) BEGIN                
                
  SET ROWCOUNT 1                
  SELECT                 
   @in_sequence_id = sequence_id,                
   @location_code  = ISNULL(location_code,''),                
    @item_code  = ISNULL(item_code,''),                
    @qty_ordered  = qty_ordered,                
    @qty_received  = qty_received,                
    @qty_returned  = CASE  WHEN trx_type=4091 THEN 0                
      WHEN (trx_type=4092) AND (ISNULL(qty_returned,0)=0) THEN 1                
      WHEN (trx_type=4092) AND (ISNULL(qty_returned,0)>0) THEN qty_returned                
      ELSE 0                
      END,                
    @tax_code  = CASE ISNULL(tax_code,'') WHEN '' THEN @tax_code ELSE tax_code END,                
    @return_code  = ISNULL(return_code,''),                
    @po_ctrl_num  = ISNULL(po_ctrl_num,''),                
   @unit_code  = ISNULL(unit_code,''),      @unit_price  = unit_price,                
    @amt_discount  = amt_discount,                
    @amt_freight  = amt_freight,                
    @amt_tax  = (SIGN(amt_tax) * ROUND(ABS(amt_tax) + 0.0000001, @precision)),                
    @amt_misc  = (SIGN(amt_misc) * ROUND(ABS(amt_misc) + 0.0000001, @precision)),                
    @amt_extended  = (SIGN(amt_extended) * ROUND(ABS(amt_extended) + 0.0000001, @precision)),                
    @calc_tax  = (SIGN(calc_tax) * ROUND(ABS(calc_tax) + 0.0000001, @precision)),                
    @gl_exp_acct  = ISNULL(gl_exp_acct,''),                
    @rma_num  = rma_num,                
    @line_desc  = ISNULL(line_desc,''),                
    @serial_id  = serial_id,                
    @reference_code = ISNULL(reference_code,''),                
    @company_id = ISNULL(company_id, @company_id),                
    @rec_company_code = ISNULL(rec_company_code, @company_code),                
    @org_id_det = ISNULL(org_id, ''),                
   @approval_code_dtl = ISNULL(approval_code,'')                
    FROM #apinpcdt_input                
    WHERE  trx_ctrl_num = @in_trx_ctrl_num                
    AND sequence_id > @in_sequence_id                
   ORDER BY trx_ctrl_num, sequence_id                
                
  IF @@rowcount=0 BREAK                
  SET ROWCOUNT 0                
                
   EXEC @result = apvocrd_sp                
     4000,                
       2,                
      @trx_ctrl_num,                
      @trx_type,                
      @sequence_id OUTPUT,                
      @location_code ,                
      @item_code,                
      0, --@bulk_flag                
      @qty_ordered ,                
     @qty_received,                
      @qty_returned,                
      0, --@qty_prev_returned                
      @approval_code_dtl,                
      @tax_code,                
      @return_code,                
      @code_1099,                
      @po_ctrl_num ,                
      @unit_code ,                
      @unit_price ,                
      @amt_discount ,                
      @amt_freight ,                
      @amt_tax ,                
      @amt_misc ,                
      @amt_extended ,                
      @calc_tax,                
      @date_entered,                
      @gl_exp_acct,                
      '', --@new_gl_exp_acct                
      @rma_num ,                
      @line_desc ,                
      0,                
      @company_id,                
      0, --@iv_post_flag,                
      1, --@po_orig_flag,                
      @rec_company_code ,                
      '',--@new_rec_company_code                
      @reference_code ,                
      '',                
      @org_id = @org_id_det                
  IF (@result<>0) OR (@@error<>0) BEGIN SELECT @err = 50, @err_proc='apvocrd_sp', @err_info='error saving detail' GOTO lbFinal END                
                
  END                
 SET ROWCOUNT 0                
                
END                
SET ROWCOUNT 0                
                
SELECT @trx_ctrl_num = NULL                
                
 IF NOT EXISTS(SELECT 1 FROM #apinpchg) GOTO lbFinal                
                
 INSERT  #apterms (                
  date_doc,                
  terms_code,                
date_due,                
  date_discount)                
 SELECT DISTINCT                
  date_doc,                
  terms_code,                
   0,                
   0                
 FROM #apinpchg                
 WHERE date_due = 0 OR date_discount = 0                
                
 EXEC @result = apterms_sp                
 IF (@result<>0) OR (@@error<>0) BEGIN SELECT @err = 55, @err_proc='ap_terms_sp', @err_info='error in calculating date due' GOTO lbFinal END                
                
 UPDATE h                
 SET date_due = CASE WHEN h.date_due=0 THEN t.date_due ELSE h.date_due END,                
  date_discount = CASE WHEN h.date_discount=0 THEN t.date_discount ELSE h.date_discount END                
 FROM #apinpchg h, #apterms t                
 WHERE h.terms_code = t.terms_code                
 AND h.date_doc = t.date_doc                
                
-->>8.1RCGT, RGM                
IF((SELECT TOP 1 isnull(tax_calculated_mode, 1) FROM #bows_apinptax_link) = 1 OR  --Rev 3                
 (SELECT COUNT(1) FROM #bows_apinptax_link) = 0)  --Rev 3                
BEGIN                 
                
 --Begin Rev 3                
 IF((SELECT TOP 1 isnull(tax_calculated_mode, 1) FROM #bows_apinptax_link) = 1)  --Rev 3                
 BEGIN                
  DELETE #apinptaxdtl                
  DELETE #bows_apinptax_link                
 END                
 --End Rev 3                
                
 EXEC @result = bows_APImportVouchTax_SP @debug_level=@debug_level                
 IF (@result<>0) OR (@@error<>0) BEGIN SELECT @err = 60, @err_proc='APImportVouchTax_SP', @err_info='error in calculating tax' GOTO lbFinal END                
                
 --Begin Rev 3                
 DECLARE @recoverable_flag int                
 DECLARE @amt_nonrecoverable_tax float                
 DECLARE @amt_tax_det         float                
                
 INSERT #apinptaxdtl(                 
    trx_ctrl_num,    sequence_id,   trx_type,                   
    tax_sequence_id,   detail_sequence_id,  tax_type_code,                    
    amt_taxable,    amt_gross,   amt_tax,                
    amt_final_tax,    recoverable_flag,  account_code)                 
 SELECT   #txdetail.control_number,  id.sequence_id,   #apinpcdt.trx_type,                    
    #apinpcdt.sequence_id,   #apinpcdt.sequence_id,  #txdetail.tax_type_code,                 
    round((#apinpcdt.amt_extended), @precision), round((#apinpcdt.amt_extended), @precision),                 
    #txdetail.amt_taxable, #txdetail.amt_taxable, --round((#txdetail.amt_taxable), @precision), round((#txdetail.amt_taxable), @precision),  --rev 8                
    type.recoverable_flag,  #apinpcdt.gl_exp_acct                 
 FROM   #txdetail, #apinpcdt, aptxtype type, #txinfo_id id                
 WHERE  #txdetail.control_number  = #apinpcdt.trx_ctrl_num                 
 AND    #txdetail.reference_number  = #apinpcdt.sequence_id                
 AND    type.tax_type_code   = #txdetail.tax_type_code                
 AND    #txdetail.control_number  = id.control_number                 
 AND    #txdetail.tax_type_code          = id.tax_type_code                
 AND    type.cents_code_flag = 0                
 AND   ( type.tax_based_type != 2)                
 AND   ( type.tax_range_flag  = 0 OR ( type.tax_range_flag  = 1 AND type.tax_range_type != 0))                 
 AND   ( type.base_range_flag = 0 OR ( type.base_range_flag = 1 AND type.base_range_type != 2 ))                
                
 DECLARE update_header SCROLL CURSOR FOR                
  SELECT  tax.trx_ctrl_num ,  tax.tax_type_code                
  FROM  #apinptax tax, aptxtype type                
  WHERE tax.tax_type_code  = type.tax_type_code                
  AND     type.tax_based_type  = 2                 
  AND  recoverable_flag  = 0                
  ORDER BY tax.trx_ctrl_num, tax.tax_type_code                
                 
 OPEN update_header                
                 
 FETCH update_header INTO @trx_ctrl_num, @tax_type_code                
                
 WHILE @@FETCH_STATUS = 0                
 BEGIN                
                 
  SELECT  @amt_nonrecoverable_tax = SUM(amt_final_tax)                
  FROM #apinptax                
  WHERE trx_ctrl_num  = @trx_ctrl_num                
  AND tax_type_code  = @tax_type_code                
                 
  UPDATE #apinpchg                
  SET tax_freight_no_recoverable  = tax_freight_no_recoverable + ISNULL(@amt_nonrecoverable_tax,0)                
  WHERE trx_ctrl_num    = @trx_ctrl_num                
                 
                 
  FETCH update_header INTO @trx_ctrl_num, @tax_type_code                
                 
 END                
                 
 CLOSE update_header                
 DEALLOCATE update_header                
                
 DECLARE trx_ctrl_num_sum SCROLL CURSOR FOR                
   SELECT  #apinptaxdtl.trx_ctrl_num, #apinptaxdtl.detail_sequence_id, #apinptaxdtl.amt_final_tax, #apinptaxdtl.recoverable_flag                
   FROM  #apinptaxdtl                
   ORDER BY #apinptaxdtl.trx_ctrl_num, #apinptaxdtl.sequence_id                
                 
 OPEN trx_ctrl_num_sum                 
                 
 FETCH trx_ctrl_num_sum      
 INTO @trx_ctrl_num, @sequence_id, @amt_final_tax, @recoverable_flag                
                 
 SELECT @amt_nonrecoverable_tax= 0                
 SELECT @amt_tax_det = 0                  
                
 WHILE @@FETCH_STATUS = 0                
 BEGIN                
  IF @recoverable_flag = 0                
  BEGIN                
          SELECT @amt_tax_det = 0                
   SELECT @amt_nonrecoverable_tax = @amt_final_tax                
         END                
       ELSE                 
  BEGIN                
   SELECT @amt_nonrecoverable_tax = 0                
         SELECT @amt_tax_det = @amt_final_tax                 
  END                
                    
  UPDATE  #apinpcdt                
  SET  amt_nonrecoverable_tax  = amt_nonrecoverable_tax + @amt_nonrecoverable_tax,                
   amt_tax_det   = amt_tax_det + @amt_tax_det                
  WHERE  #apinpcdt.trx_ctrl_num  = @trx_ctrl_num                
  AND  #apinpcdt.sequence_id  = @sequence_id                  
                   
  FETCH trx_ctrl_num_sum                
  INTO @trx_ctrl_num, @sequence_id,@amt_final_tax,@recoverable_flag                
                 
 END                
                
 CLOSE trx_ctrl_num_sum                
 DEALLOCATE trx_ctrl_num_sum                
                
 --End Rev 3                
                
END                
ELSE                
BEGIN                
                
 UPDATE  #apinptaxdtl                 
 SET amt_taxable =  (SIGN(amt_taxable) * ROUND(ABS(amt_taxable) + 0.0000001, @precision)),                
  amt_gross = (SIGN(amt_gross) * ROUND(ABS(amt_gross) + 0.0000001, @precision))--,                 
  --amt_tax =  (SIGN(amt_tax) * ROUND(ABS(amt_tax) + 0.0000001, @precision)),  --Rev 8                 
  --amt_final_tax = (SIGN(amt_final_tax) * ROUND(ABS(amt_final_tax) + 0.0000001, @precision)) --Rev 8                 
                
                
 INSERT INTO #apinptax (                
  trx_ctrl_num,                
  trx_type,                
  tax_type_code,                
  trx_state,                
  mark_flag         
 )                
 SELECT  trx_ctrl_num,                  
  trx_type,                
  tax_type_code,                
  2,                
  0                
 FROM  #apinptaxdtl                
 GROUP BY tax_type_code, trx_ctrl_num, trx_type                
                
                
 -->> SUMMARIZE INTO #apinptax TABLE BY TAX TYPE.                
 UPDATE  #apinptax                 
 SET amt_taxable =  (SIGN(sum_amt_taxable) * ROUND(ABS(sum_amt_taxable) + 0.0000001, @precision)),                
  amt_gross = (SIGN(sum_amt_gross) * ROUND(ABS(sum_amt_gross) + 0.0000001, @precision)),                 
  amt_tax =  (SIGN(sum_amt_tax) * ROUND(ABS(sum_amt_tax) + 0.0000001, @precision)),                  
  amt_final_tax = (SIGN(sum_amt_final_tax) * ROUND(ABS(sum_amt_final_tax) + 0.0000001, @precision))                 
 FROM (                
   SELECT                 
    SUM(ISNULL(amt_taxable, 0))  sum_amt_taxable,                 
    SUM(ISNULL(amt_gross,0))  sum_amt_gross,                 
    SUM(ISNULL(amt_tax, 0))  sum_amt_tax,                 
    SUM(ISNULL(amt_final_tax, 0))  sum_amt_final_tax,                 
    tax_type_code,                
    trx_ctrl_num  --Rev 5                 
   FROM  #apinptaxdtl                 
   GROUP BY tax_type_code, trx_ctrl_num --Rev 5                
  ) taxdtl                 
 WHERE  #apinptax.tax_type_code = taxdtl.tax_type_code                
  and #apinptax.trx_ctrl_num = taxdtl.trx_ctrl_num --Rev 5                
                
 -->> UPDATE THE SEQUENCE ID'S FOR #apinptax TABLE.                
 DECLARE @sequencial_id_tax int                
 SET @sequencial_id_tax = 0                
 UPDATE  #apinptax                
 SET  @sequencial_id_tax = @sequencial_id_tax + 1,                
  sequence_id = @sequencial_id_tax                
                
 -- >> Update the amt_non_recoverable of the detail table.                 
 UPDATE  #apinpcdt                 
 SET amt_nonrecoverable_tax = (SIGN(sum_amt_final_tax) * ROUND(ABS(sum_amt_final_tax) + 0.0000001, @precision))                  
 FROM   (                
   SELECT  SUM(ISNULL(amt_final_tax, 0)) sum_amt_final_tax,                 
    detail_sequence_id, trx_ctrl_num --Rev 10                 
   FROM  #apinptaxdtl                 
   WHERE  #apinptaxdtl.recoverable_flag = 0                 
   GROUP BY trx_ctrl_num, detail_sequence_id --Rev 10                
  ) detail_tax                
 WHERE #apinpcdt.sequence_id = detail_tax.detail_sequence_id                
  and #apinpcdt.trx_ctrl_num = detail_tax.trx_ctrl_num --Rev 10                
                
 -- >> Update the amt_tax_det of the detail table.                
 UPDATE  #apinpcdt                
 SET amt_tax_det = (SIGN(sum_amt_final_tax) * ROUND(ABS(sum_amt_final_tax) + 0.0000001, @precision))                  
 FROM   (                
   SELECT  SUM(ISNULL(amt_final_tax, 0)) sum_amt_final_tax,                 
    detail_sequence_id,                 
    trx_ctrl_num --Rev 5                
   FROM  #apinptaxdtl                 
   WHERE  #apinptaxdtl.recoverable_flag = 1                 
   GROUP BY trx_ctrl_num, detail_sequence_id  --Rev 5                
  ) detail_tax                
 WHERE #apinpcdt.sequence_id = detail_tax.detail_sequence_id                
  and #apinpcdt.trx_ctrl_num = detail_tax.trx_ctrl_num --Rev 5                
                
 UPDATE  #apinpcdt                
 SET calc_tax = (SIGN(sum_amt_final_tax) * ROUND(ABS(sum_amt_final_tax) + 0.0000001, @precision))                  
 FROM   ( SELECT  SUM(ISNULL(amt_final_tax, 0)) sum_amt_final_tax,                 
    detail_sequence_id,                 
    trx_ctrl_num --Rev 5                 
   FROM  #apinptaxdtl                 
   GROUP BY trx_ctrl_num, detail_sequence_id  --Rev 5                
  ) detail_tax                
 WHERE #apinpcdt.sequence_id = detail_tax.detail_sequence_id                
  and #apinpcdt.trx_ctrl_num = detail_tax.trx_ctrl_num --Rev 5                
END                
-->>8.1RCGT, RGM                
                
                
--After tax calculation we need to adjust some values in the header                
SELECT @trx_ctrl_num=CHAR(0)            
WHILE (4=4) BEGIN                
 SET ROWCOUNT 1                
 SELECT  @trx_ctrl_num  = ISNULL(trx_ctrl_num,''),                
  @trx_type  = trx_type,                
  @date_applied = date_applied,                
   @date_due = date_due,                
  @date_aging = date_aging,                
  @nat_cur_code = nat_cur_code                
   FROM #apinpchg                
   WHERE ISNULL(trx_ctrl_num,'') > @trx_ctrl_num                
  ORDER BY trx_ctrl_num                
                
 IF @@rowcount=0 BREAK                
 SET ROWCOUNT 0                
  SELECT @precision = ISNULL((SELECT curr_precision                
     FROM glcurr_vw                
     WHERE glcurr_vw.currency_code=@nat_cur_code), 1.0 )                
                
 SELECT @amt_tax_included=0, @amt_tax=0                
 -->>8.1RCGT, RGM                
 -->> E4SE Object will always have a Tax INCLUDED = NO, Tax Included will always be 0.  However, when using Integration Hub, this could be 1, so this code shouldn't be removed.                
 SELECT @amt_tax_included = (SIGN(ISNULL(SUM(a.amt_final_tax),0)) * ROUND(ABS(ISNULL(SUM(a.amt_final_tax),0)) + 0.0000001, @precision))                
  FROM #apinptax a, artxtype t                
  WHERE a.tax_type_code = t.tax_type_code                
  AND t.tax_included_flag = 1                
  AND a.trx_ctrl_num = @trx_ctrl_num                
                
 SELECT  @amt_tax = (SIGN(ISNULL(SUM(a.amt_final_tax),0)) * ROUND(ABS(ISNULL(SUM(a.amt_final_tax),0)) + 0.0000001, @precision))                
 FROM  #apinptaxdtl a, artxtype t                
 WHERE  a.tax_type_code = t.tax_type_code                
  AND  a.trx_ctrl_num = @trx_ctrl_num and a.recoverable_flag = 1                
        
                
 -->>8.1RCGT, RGM                
 SELECT @no_recoverable_taxes = (SIGN(ISNULL(SUM(a.amt_nonrecoverable_tax),0)) * ROUND(ABS(ISNULL(SUM(a.amt_nonrecoverable_tax),0)) + 0.0000001, @precision))                 
 FROM #apinpcdt a                
 --, artax t                
 WHERE a.trx_ctrl_num = @trx_ctrl_num                
 --AND a.tax_code = t.tax_code                
 --AND (t.tax_included_flag = 0 or t.tax_included_flag = 1)                
                 
                 
 -->>8.1RCGT, RGM                
 UPDATE #apinpchg                
 SET amt_gross  = (SIGN(amt_gross-@amt_tax_included+@no_recoverable_taxes) * ROUND(ABS(amt_gross-@amt_tax_included+@no_recoverable_taxes) + 0.0000001, @precision)),                
  amt_tax_included = @amt_tax_included,                
  amt_tax   = (SIGN(@amt_tax) * ROUND(ABS(@amt_tax) + 0.0000001, @precision)),                
  amt_net   = (SIGN(amt_gross+@amt_tax-@amt_tax_included+@no_recoverable_taxes) * ROUND(ABS(amt_gross+@amt_tax-@amt_tax_included+@no_recoverable_taxes) + 0.0000001, @precision)),                
  amt_due   = (SIGN(amt_gross+@amt_tax-@amt_tax_included+@no_recoverable_taxes) * ROUND(ABS(amt_gross+@amt_tax-@amt_tax_included+@no_recoverable_taxes) + 0.0000001, @precision)),                
  @amt_due  = (SIGN(amt_gross+@amt_tax-@amt_tax_included+@no_recoverable_taxes) * ROUND(ABS(amt_gross+@amt_tax-@amt_tax_included+@no_recoverable_taxes) + 0.0000001, @precision)),                
  net_original_amt = (SIGN(amt_gross+@amt_tax-@amt_tax_included+@no_recoverable_taxes) * ROUND(ABS(amt_gross+@amt_tax-@amt_tax_included+@no_recoverable_taxes) + 0.0000001, @precision))                
 WHERE trx_ctrl_num = @trx_ctrl_num                
                
                
 EXEC @result = apvocra_sp  4000,                
     2,                
      @trx_ctrl_num,                
     @trx_type,                
      0, --@sequence_id                
      @date_applied,                
      @date_due,                
     @date_aging,                
     @amt_due                
 IF (@result<>0) OR (@@error<>0) BEGIN SELECT @err = 55, @err_proc='apvocra_sp', @err_info='' GOTO lbFinal END                
END -- (4=4)                
SET ROWCOUNT 0                
                
IF ((ISNULL(@error_account_flg,1)=1) AND (NOT @error_account_code IS NULL))                
BEGIN                
 INSERT #bows_invalid_acct(                
  trx_ctrl_num,                
  trx_type,                
  sequence_id,                
  account_code,                
  reference_code)                
 SELECT                
  trx_ctrl_num,                
  trx_type,                
  sequence_id,                
  gl_exp_acct,                
  reference_code                
 FROM #apinpcdt                
 WHERE #apinpcdt.gl_exp_acct NOT IN (SELECT account_code FROM glchart_vw WHERE account_code=#apinpcdt.gl_exp_acct)                
 IF (@result<>0) OR (@@error<>0) BEGIN SELECT @err = 220, @err_proc='bows_APImportVouch_SP', @err_info='comments' GOTO lbFinal END                
                
 UPDATE #apinpcdt                
 SET gl_exp_acct = @error_account_code,                
  reference_code = ''                
 FROM #apinpcdt, #bows_invalid_acct                
 WHERE #apinpcdt.trx_ctrl_num = #bows_invalid_acct.trx_ctrl_num                
 AND #apinpcdt.trx_type = #bows_invalid_acct.trx_type                
 AND #apinpcdt.sequence_id = #bows_invalid_acct.sequence_id                
 IF (@result<>0) OR (@@error<>0) BEGIN SELECT @err = 220, @err_proc='bows_APImportVouch_SP', @err_info='comments' GOTO lbFinal END                
                
 INSERT INTO #bows_doc_notes (                
  trx_ctrl_num,                
  trx_type,                
  sequence_id,                
  note,                
  show_line_mode,                
  position_mode                
 )                
 SELECT trx_ctrl_num,                
  trx_type,                
  sequence_id,                
  'Invalid account:' + RTRIM(account_code) +                
   CASE WHEN ISNULL(reference_code,'')='' THEN '' ELSE ';' + CHAR(13) + 'Reference code:' + reference_code END,                
  1,                 
  -1                 
 FROM #bows_invalid_acct                
 ORDER BY trx_ctrl_num, sequence_id                
 BEGIN SELECT @result = @@error IF @result<>0 BEGIN SELECT @err = 220, @err_proc='bows_APImportVouch_SP' GOTO lbFinal END END                
                
 UPDATE  #apinpchg                
 SET hold_flag = 1,                
  hold_desc = 'Invalid accounts. See Notes!'                
 FROM #apinpchg, #apinpcdt, #bows_invalid_acct                
 WHERE #apinpchg.trx_ctrl_num = #bows_invalid_acct.trx_ctrl_num                
 AND #apinpcdt.trx_type = #bows_invalid_acct.trx_type                
 BEGIN SELECT @result = @@error IF @result<>0 BEGIN SELECT @err = 220, @err_proc='bows_APImportVouch_SP' GOTO lbFinal END END                
END                
                
IF EXISTS(SELECT 1 FROM #bows_doc_notes) BEGIN                
                
 UPDATE  #bows_doc_notes                
 SET mark_flag = 0                
                
 INSERT #bows_doc_notes(                
  trx_ctrl_num, trx_type,sequence_id,                
  link,note,show_line_mode,position_mode,mark_flag)                
 SELECT trx_ctrl_num, trx_type,sequence_id,                
  link,note,show_line_mode,position_mode,1                
 FROM #bows_doc_notes                
 ORDER BY trx_ctrl_num, position_mode, sequence_id                
                
 INSERT #comments(                
   company_code,                
  key_1,                
   key_type,                
  sequence_id,                
  date_created,                
   created_by,                
   date_updated,                
  updated_by,                
  link_path,                
   note)                
 SELECT @company_code,                
  trx_ctrl_num,                
  trx_type,                
  note_sequence + 1 -                
   ISNULL((SELECT MIN(b.note_sequence)                
   FROM #bows_doc_notes b                
   WHERE b.trx_ctrl_num = a.trx_ctrl_num                
   AND b.mark_flag=1),0),                
  @datenow,                
  @user_id,                
  @datenow,                
  @user_id,                
  CASE                
    WHEN (show_line_mode=1) and (not sequence_id is null) THEN                
   LEFT(('Line: ' + convert(varchar,sequence_id) +             
 CASE WHEN link IS NULL THEN '' ELSE ';' + link END), 255)                
    ELSE link                
  END,                
  CASE         
   WHEN (show_line_mode=2) and (not sequence_id is null) THEN                
 LEFT(('Line: ' + convert(varchar,sequence_id) + ';' + ISNULL(note,'')), 255)                
   ELSE note                
  END                
 FROM #bows_doc_notes a                
 WHERE a.mark_flag = 1                
 ORDER BY note_sequence                
 BEGIN SELECT @result = @@error IF @result<>0 BEGIN SELECT @err = 220, @err_proc='bows_APImportVouch_SP' GOTO lbFinal END END                
END                
                
SELECT @trx_ctrl_num = NULL                
                
IF @debug_level>5 BEGIN                
 SELECT '**** #apinpchg before validation ****'                
 SELECT * FROM #apinpchg                
 SELECT '**** #apinpcdt before validation ****'                
 SELECT * FROM #apinpcdt                
 SELECT '**** #apinpage before validation ****'                
 SELECT * FROM #apinpage                
 SELECT '**** #apinptax before validation ****'                
 SELECT * FROM #apinptax                
 SELECT '**** #apinptaxdtl before validation ****'                
 SELECT * FROM #apinptaxdtl                
 SELECT '**** #comments before validation ****'                
 SELECT * FROM #comments                
END                
                
EXEC @result = apvoval_sp @debug_level=@debug_level          
IF (@result<>0) OR (@@error<>0) BEGIN SELECT @err = 70, @err_proc='apvoval_sp', @err_info='error during voucher validation' GOTO lbFinal END                
                
-- EXEC @result = apvchedt_sp  1,  --CMW01                
EXEC @result = apvchedt_sp  1,  --CMW01                
     @debug_level=@debug_level                
IF (@result<>0) OR (@@error<>0) BEGIN SELECT @err = 80, @err_proc='apvoedt_sp', @err_info='' GOTO lbFinal END                
                
IF @debug_level>5 BEGIN                
 SELECT '**** #ewerror after validation ****'                
 SELECT * FROM #ewerror                
END                
                
IF NOT (@APApplyDocPosted = 0) BEGIN                
 DELETE  e                
 FROM #ewerror e, #apinpchg a                
 WHERE e.err_code IN (10020,20020)                
 AND e.trx_ctrl_num = a.trx_ctrl_num                
 AND a.trx_type = 4092                
END                
                
SELECT @dbname = db_name()                
                
EXEC @result = apvedb_sp  @dbname,                
    @dbname,                
     0, --@flag,                
    1, --Only Errors                
     @debug_level=@debug_level                
IF (@result<>0) OR (@@error<>0) BEGIN SELECT @err = 90, @err_proc='apvedb_sp', @err_info='' GOTO lbFinal END                
                
 SELECT @use_psaTrx = 0                
 --IF EXISTS( SELECT name FROM sysobjects WHERE name = 'bows_psaTrx')    --fzambada Original              
 --Fzambada cut project code from A2K Vouchers              
 IF NOT EXIsTs (select top 1 taskuid from #bows_psaTrx where taskuid=9999)              
 BEGIN              
  IF EXISTS( SELECT name FROM sysobjects WHERE name = 'bows_psaTrx')--fzambada              
  SELECT @use_psaTrx = 1                
 END              
               
 --End Fzambada              
               
 IF (@use_psaTrx = 1) BEGIN                
                
  INSERT  #ewerror                
  SELECT  4000,                
    18001,                
    #bows_psaTrx.ProjectCode,                
   '',                
   0,                
   0.0,                
   1,                
   #bows_psaTrx.ControlNumber,                
   #bows_psaTrx.SequenceID,                
  '',                
    0                
  FROM #bows_psaTrx                
  WHERE #bows_psaTrx.ProjectCode NOT IN (SELECT ProjectCode FROM bows_psaTask)                
  AND #bows_psaTrx.TaskUID <> -1                
  AND #bows_psaTrx.InterCompanyFlag = 0                
  BEGIN SELECT @result = @@error IF @result<>0 BEGIN SELECT @err = 110, @err_proc='bows_APImportVouch_SP' GOTO lbFinal END END                
                
  INSERT  #ewerror                
  SELECT  4000,                
    18002,                
    #bows_psaTrx.TaskUID,                
   '',                
   0,                
   0.0,     
   1,                
   #bows_psaTrx.ControlNumber,                
   #bows_psaTrx.SequenceID,                
   '',                
    0                
  FROM #bows_psaTrx                
  WHERE #bows_psaTrx.TaskUID NOT IN (SELECT b.TaskUID FROM bows_psaTask b WHERE b.ProjectCode=#bows_psaTrx.ProjectCode)                
  AND #bows_psaTrx.TaskUID <> -1                
  AND #bows_psaTrx.InterCompanyFlag = 0                
  BEGIN SELECT @result = @@error IF @result<>0 BEGIN SELECT @err = 120, @err_proc='bows_APImportVouch_SP' GOTO lbFinal END END                
                
  INSERT  #ewerror                
  SELECT  4000,                
    18003,                
    #bows_psaTrx.ExpenseTypeCode,                
   '',                
   0,                
   0.0,                
   1,                
   #bows_psaTrx.ControlNumber,                
   #bows_psaTrx.SequenceID,                
   '',                
    0                
  FROM #bows_psaTrx                
  WHERE #bows_psaTrx.ExpenseTypeCode NOT IN (SELECT ExpenseTypeCode FROM bows_psaExpenseType)                
  BEGIN SELECT @result = @@error IF @result<>0 BEGIN SELECT @err = 130, @err_proc='bows_APImportVouch_SP' GOTO lbFinal END END                
 END    
                
IF EXISTS(SELECT 1 FROM #ewerror) BEGIN                
                
 DELETE #apinpchg                
 FROM #ewerror                
 WHERE #apinpchg.trx_ctrl_num = #ewerror.trx_ctrl_num                
 BEGIN SELECT @result = @@error IF @result<>0 BEGIN SELECT @err = 140, @err_proc='bows_APImportVouch_SP' GOTO lbFinal END END                
                
 DELETE #apinpcdt                
 FROM #ewerror                
 WHERE #apinpcdt.trx_ctrl_num = #ewerror.trx_ctrl_num                
 AND #apinpcdt.trx_ctrl_num NOT IN (SELECT trx_ctrl_num FROM #apinpchg)                
 BEGIN SELECT @result = @@error IF @result<>0 BEGIN SELECT @err = 150, @err_proc='bows_APImportVouch_SP' GOTO lbFinal END END                
                
 DELETE #apinpage                
 FROM #ewerror                
 WHERE #apinpage.trx_ctrl_num = #ewerror.trx_ctrl_num                
 BEGIN SELECT @result = @@error IF @result<>0 BEGIN SELECT @err = 160, @err_proc='bows_APImportVouch_SP' GOTO lbFinal END END                
                
 DELETE #apinptax                
 FROM #ewerror                
 WHERE #apinptax.trx_ctrl_num = #ewerror.trx_ctrl_num                
 BEGIN SELECT @result = @@error IF @result<>0 BEGIN SELECT @err = 170, @err_proc='bows_APImportVouch_SP' GOTO lbFinal END END                
                
 IF (@use_psaTrx = 1) BEGIN                
  DELETE #bows_psaTrx                
  FROM #ewerror                
  WHERE #bows_psaTrx.ControlNumber = #ewerror.trx_ctrl_num                
  BEGIN SELECT @result = @@error IF @result<>0 BEGIN SELECT @err = 175, @err_proc='bows_APImportVouch_SP' GOTO lbFinal END END                
 END                
                
 DELETE #comments                
 FROM #ewerror                
 WHERE #comments.key_1 = #ewerror.trx_ctrl_num                
 BEGIN SELECT @result = @@error IF @result<>0 BEGIN SELECT @err = 176, @err_proc='bows_APImportVouch_SP' GOTO lbFinal END END                
END                
                
                
 IF NOT EXISTS(SELECT 1 FROM #apinpchg) GOTO lbFinal                
                
 SELECT @trx_ctrl_num_int = -1                
 WHILE (8=8) BEGIN                
  SET ROWCOUNT 1                
  SELECT  @trx_ctrl_num_int  = b.trx_ctrl_num_int,                
   @trx_type   = a.trx_type                
    FROM  #apinpchg a, #bows_apinpchg_link b                
  WHERE a.trx_ctrl_num = b.trx_ctrl_num                
  AND b.trx_ctrl_num_int > @trx_ctrl_num_int                
   ORDER BY b.trx_ctrl_num_int                
                
  IF @@rowcount=0 BREAK                
  SET ROWCOUNT 0                
                
  SELECT @trx_ctrl_num = NULL                
  EXEC @result = apnewnum_sp @trx_type, @company_code, @trx_ctrl_num OUTPUT                
  IF (@result<>0) OR (@@error<>0) BEGIN SELECT @err = 180, @err_proc='apnewnum_sp', @err_info='Error getting control number' GOTO lbFinal END                
                
  UPDATE  #bows_apinpchg_link                
   SET  new_trx_ctrl_num = @trx_ctrl_num,                
   imported_flag = 1                
   WHERE trx_ctrl_num_int = @trx_ctrl_num_int                
  BEGIN SELECT @result = @@error IF @result<>0 BEGIN SELECT @err = 185, @err_proc='bows_APImportVouch_SP' GOTO lbFinal END END                
 END -- (8=8)                
 SET ROWCOUNT 0                
                
 UPDATE  a                
  SET  a.trx_ctrl_num = b.new_trx_ctrl_num                
 FROM #apinpchg a, #bows_apinpchg_link b                
 WHERE  a.trx_ctrl_num = b.trx_ctrl_num                
 BEGIN SELECT @result = @@error IF @result<>0 BEGIN SELECT @err = 186, @err_proc='bows_APImportVouch_SP' GOTO lbFinal END END                
                
 UPDATE  a                
  SET  a.trx_ctrl_num = b.new_trx_ctrl_num, a.item_code = a.item_code + ' ' + b.new_trx_ctrl_num  --Rev SCR 6965                
 FROM #apinpcdt a, #bows_apinpchg_link b                
 WHERE  a.trx_ctrl_num = b.trx_ctrl_num                
 BEGIN SELECT @result = @@error IF @result<>0 BEGIN SELECT @err = 187, @err_proc='bows_APImportVouch_SP' GOTO lbFinal END END                
                
 UPDATE  a                
  SET  a.trx_ctrl_num = b.new_trx_ctrl_num                
 FROM #apinpage a, #bows_apinpchg_link b                
 WHERE  a.trx_ctrl_num = b.trx_ctrl_num                
 BEGIN SELECT @result = @@error IF @result<>0 BEGIN SELECT @err = 188, @err_proc='bows_APImportVouch_SP' GOTO lbFinal END END                
                
 UPDATE  a                
  SET  a.trx_ctrl_num = b.new_trx_ctrl_num                
 FROM #apinptax a, #bows_apinpchg_link b                
 WHERE  a.trx_ctrl_num = b.trx_ctrl_num                
 BEGIN SELECT @result = @@error IF @result<>0 BEGIN SELECT @err = 189, @err_proc='bows_APImportVouch_SP' GOTO lbFinal END END                
                
 -->>8.1RCGT, RGM                
 UPDATE  a                
 SET  a.trx_ctrl_num = b.new_trx_ctrl_num                
 FROM #apinptaxdtl a, #bows_apinpchg_link b            
 WHERE  a.trx_ctrl_num = b.trx_ctrl_num                
 BEGIN SELECT @result = @@error IF @result<>0 BEGIN SELECT @err = 189, @err_proc='bows_APImportVouch_SP' GOTO lbFinal END END                
 -->>8.1RCGT, RGM                
                
 IF (@use_psaTrx = 1) BEGIN                
  UPDATE  a                
   SET  a.ControlNumber = b.new_trx_ctrl_num                
  FROM #bows_psaTrx a, #bows_apinpchg_link b                
  WHERE  a.ControlNumber = b.trx_ctrl_num                
  BEGIN SELECT @result = @@error IF @result<>0 BEGIN SELECT @err = 190, @err_proc='bows_APImportVouch_SP' GOTO lbFinal END END                
                
  --begin rev 4                
  UPDATE  a                
   SET  a.ProjectName = (select distinct tsk.ProjectName from bows_psaTask tsk left outer join bows_psaTrx trx on tsk.ProjectCode = trx.ProjectCode and tsk.RevisionNum = trx.RevisionNum and tsk.TaskUID = trx.TaskUID where tsk.ProjectCode = a.ProjectCode)
  
    
      
        
           
            
             
,                
    a.OpportunityCode = (select distinct tsk.OpportunityCode from bows_psaTask tsk left outer join bows_psaTrx trx on tsk.ProjectCode = trx.ProjectCode and tsk.RevisionNum = trx.RevisionNum and tsk.TaskUID = trx.TaskUID where tsk.ProjectCode = a.ProjectCode)                
  FROM #bows_psaTrx a                
  BEGIN SELECT @result = @@error IF @result<>0 BEGIN SELECT @err = 190, @err_proc='bows_APImportVouch_SP' GOTO lbFinal END END                
  --end rev 4                
 END                
                
 UPDATE  a                
  SET  a.key_1 = b.new_trx_ctrl_num                
 FROM #comments a, #bows_apinpchg_link b                
 WHERE  a.key_1 = b.trx_ctrl_num                
 BEGIN SELECT @result = @@error IF @result<>0 BEGIN SELECT @err = 191, @err_proc='bows_APImportVouch_SP' GOTO lbFinal END END                
                
 IF @debug_level>5 BEGIN                
  SELECT '**** #apinpchg before save ****'                
  SELECT * FROM #apinpchg                
  SELECT '**** #apinpcdt before save ****'                
  SELECT * FROM #apinpcdt                
  SELECT '**** #apinpage before save ****'                
  SELECT * FROM #apinpage                
  SELECT '**** #apinptax before save ****'                
  SELECT * FROM #apinptax                
  SELECT '**** #apinptaxdtl before save ****'  --Rev 3                
  SELECT * FROM #apinptaxdtl  --Rev 3                
  IF (@use_psaTrx = 1) BEGIN                
   SELECT '**** #bows_psaTrx before save ****'                
   SELECT * FROM #bows_psaTrx                
  END                
  SELECT '**** #comments before save ****'                
  SELECT * FROM #comments                
 END                
                
                
 exec appdate_sp @completed_date output                
 exec apptime_sp @completed_time output                
                
 BEGIN TRANSACTION SaveVoucher                
                
 SELECT @vendor_code = CHAR(0)                
 WHILE (3=3) BEGIN                
  SET ROWCOUNT 1                
  SELECT  @vendor_code  = h.vendor_code,                
   @branch_code  = v.branch_code,                
    @class_code  = v.vend_class_code,                
   @pay_to_code  = v.pay_to_code                
    FROM  #apinpchg h, apvend v                
    WHERE  h.vendor_code > @vendor_code                
   AND  h.vendor_code = v.vendor_code                
   ORDER  BY h.vendor_code                
                
  IF @@rowcount=0 BREAK                
  SET ROWCOUNT 0                
                
  EXEC @result = apactinp_sp @vendor_code,                
      @pay_to_code,                
      @class_code,                
      @branch_code,                
 0.0,                
      1,                
      1                
  IF (@result <> 0) OR (@@error <> 0) BEGIN                
   ROLLBACK TRANSACTION SaveVoucher                
   SELECT @err = 200, @err_proc='apactinp_sp', @err_info=''                
    GOTO lbFinal                
  END                
 END                
 SET ROWCOUNT 0                
                
 IF (@use_psaTrx = 1) BEGIN                
                
  INSERT bows_psaTask(                
   ProjectCode,                
   RevisionNum,                
   TaskUID,                
   TaskName,                
   StatusCode                
  )                
  SELECT                
   DISTINCT ProjectCode,                
   0,                
   TaskUID,                
   ProjectCode,                
   'I'                
  FROM  #bows_psaTrx                
  WHERE #bows_psaTrx.TaskUID = -1              
  AND  NOT EXISTS (SELECT 1 FROM bows_psaTask WHERE bows_psaTask.TaskUID=-1 AND bows_psaTask.ProjectCode=#bows_psaTrx.ProjectCode)                
                
  IF ( @@error != 0 )                
  BEGIN                
   ROLLBACK TRANSACTION SaveVoucher                
   SELECT @err = 204, @err_proc='bows_apimvo', @err_info='error during inserting internal project task'                
    GOTO lbFinal                
  END                
                
  INSERT bows_psaTrx(                
  ControlNumber,                
  TransactionType,                
  SequenceID,                
  PostedFlag,                
  ProjectCode,                
  RevisionNum,                
  TaskUID,                
  ExpenseTypeCode,                
  ResourceID,                
  ExpenseID,                
  PrepaidFlag,                
  Origin,                
  ClosedFlag,         
  ProjectSiteURN,                
  InterCompanyFlag,                
  ProjectName,OpportunityCode --rev 6                
  )                
  SELECT                
  ControlNumber,                
  TransactionType,                
  SequenceID,                
  PostedFlag,                
  ProjectCode,                
  RevisionNum,                
  TaskUID,                
  ExpenseTypeCode,                
  ResourceID,                
  ExpenseID,                
  PrepaidFlag,                
  Origin,                
  ClosedFlag,                
  ProjectSiteURN,                
  InterCompanyFlag,                
  ProjectName,OpportunityCode --rev 6                
  FROM #bows_psaTrx p, #apinpcdt a                
  WHERE p.ControlNumber = a.trx_ctrl_num                
 AND p.TransactionType = a.trx_type                
  AND p.SequenceID = a.sequence_id                
                
  IF ( @@error != 0 )                
  BEGIN                
   ROLLBACK TRANSACTION SaveVoucher                
   SELECT @err = 205, @err_proc='bows_apimvo', @err_info='error during inserting project data'                
    GOTO lbFinal                
  END                
 END                
 --SCR 13284                
 if (@po_orig_flag != 1)                
 begin                 
  UPDATE  #apinpcdt                
   SET  #apinpcdt.po_orig_flag = @po_orig_flag                
 end                
 --SCR 13284                
                
 EXEC @result = apvosav_sp @user_id        
 IF (@result <> 0) OR (@@error <> 0) BEGIN                
  ROLLBACK TRANSACTION SaveVoucher                
  SELECT @err = 410, @err_proc='apvosav_sp', @err_info='error during final save proc'                
   GOTO lbFinal                
 END                
                
 IF EXISTS(SELECT 1 FROM #comments)                
 BEGIN                
  INSERT comments(                
    company_code,                
    key_1,                
    key_type,                
   sequence_id,                
    date_created,                
    created_by,                
    date_updated,                
   updated_by,                
   link_path,                
    note)                
  SELECT                
    company_code,                
    key_1,                
    key_type,                
   sequence_id,                
    date_created,                
    created_by,                
    date_updated,                
   updated_by,                
   link_path,                
    note                
  FROM #comments                
 END                
                
 IF EXISTS( SELECT 1 FROM apco WHERE batch_proc_flag = 1 )                
 BEGIN                
  /*                
  **AAM SCR 6897: Change the saving date format.                
  **SELECT @batch_description = ISNULL(@batch_description, 'Imported batch') + ': ' + CONVERT(char(12), GETDATE(), 3)                
  */                
  SELECT @batch_description = ISNULL(@batch_description, 'Imported batch') + ': ' + CONVERT(char(12), GETDATE(), 1)                
  IF ((ISNULL(@batch_close_flg,1) = 1) AND (ISNULL(@batch_hold_flg,0) = 0))                
  BEGIN                
   UPDATE  batchctl                
   SET batch_description = @batch_description,                
    completed_user = batchctl.start_user,                
    completed_date = @completed_date,               
    completed_time = @completed_time,                
    control_number = batchctl.actual_number,                
    control_total = batchctl.actual_total                
   FROM batchctl, apinpchg, #bows_apinpchg_link                
   WHERE  batchctl.batch_ctrl_num = apinpchg.batch_code                
   AND apinpchg.trx_ctrl_num = #bows_apinpchg_link.new_trx_ctrl_num                
   IF ( @@error != 0 )                
   BEGIN                
    ROLLBACK TRANSACTION SaveVoucher                
    SELECT @err = 222, @err_proc='bows_apimvo', @err_info='error during updating batch info'                
     GOTO lbFinal                
   END                
  END ELSE                
  BEGIN                
   UPDATE  batchctl                
   SET batch_description = @batch_description,                
    hold_flag = ISNULL(@batch_hold_flg,0)                
   FROM batchctl, apinpchg, #bows_apinpchg_link                
   WHERE  batchctl.batch_ctrl_num = apinpchg.batch_code                
   AND apinpchg.trx_ctrl_num = #bows_apinpchg_link.new_trx_ctrl_num          
   IF ( @@error != 0 )                
   BEGIN                
    ROLLBACK TRANSACTION SaveVoucher                
    SELECT @err = 222, @err_proc='bows_apimvo', @err_info='error during updating batch info'                
     GOTO lbFinal                
   END                
  END                
                
  IF (ISNULL(@batch_hold_flg,0)=0)                
  BEGIN                
   UPDATE  batchctl                
   SET hold_flag = 1                
   FROM batchctl, apinpchg, #bows_invalid_acct                
   WHERE  batchctl.batch_ctrl_num = apinpchg.batch_code                
   AND apinpchg.trx_ctrl_num = #bows_invalid_acct.trx_ctrl_num                
   AND apinpchg.trx_type = #bows_invalid_acct.trx_type                
  END                
 END                
                
 COMMIT TRANSACTION SaveVoucher                
                
SELECT @err = 0                
                
lbFinal:                
                
DROP TABLE #apinpage                
DROP TABLE #apinptax                
DROP TABLE #apinpchg_input    
DROP TABLE #apinpcdt_input                
DROP TABLE #bows_invalid_acct                
DROP TABLE #comments                
                
DROP TABLE #apvovchg                
DROP TABLE #apvovcdt                
DROP TABLE #apvovage                
DROP TABLE #apvovtax                
DROP TABLE #apvovtmp                
DROP TABLE #apvobat                
DROP TABLE #apvtemp                
DROP TABLE #apveacct                
DROP TABLE #apterms                
DROP TABLE #apvov_companies                
                
--Begin Rev 3                
DROP TABLE #txdetail                
DROP TABLE #txinfo_id                
--End Rev 3                
                
IF @err<>0 BEGIN                
 INSERT #ewerror( module_id, err_code,                
 info1,info2,infoint,infofloat,                
 flag1,trx_ctrl_num,sequence_id, source_ctrl_num,extra)                
 SELECT 4000, @err,                
 'PROC:' + @err_proc+ '.',@err_info,@result,0.0,                
 0, @trx_ctrl_num,0,'',0                
END                
                
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/arimvo.sp' + ', line ' + STR( 124, 5 ) + ' -- EXIT: '                
RETURN @err 
GO
GRANT EXECUTE ON  [dbo].[bows_APImportVouch_SP] TO [public]
GO
