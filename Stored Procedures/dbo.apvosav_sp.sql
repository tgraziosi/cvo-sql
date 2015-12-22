SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS OFF
GO
    
    
CREATE  PROCEDURE [dbo].[apvosav_sp]  @proc_user_id smallint, @batch_code varchar(16) = NULL,    
                              @debug smallint = 0, @batch_source varchar(16) = NULL    
        
AS    
    
BEGIN    
    
DECLARE     
  @start_user_id  smallint,    
  @tran_started           smallint,    
  @batch_module_id    smallint,     
  @batch_date_applied     int,                
  @batch_trx_type   smallint,    
  @trx_type         smallint,    
  @home_company     varchar(8),    
  @result           smallint,    
  @new_batch_code    varchar(16),    
  @vend_flag        smallint,    
  @pto_flag         smallint,    
  @cls_flag         smallint,    
  @bch_flag         smallint,    
  @batch_desc    varchar(30),    
  @hold_flag         smallint,    
  @org_id     varchar(30),      
  @str_msg    varchar(255)    
    
     
    
    
 IF NOT EXISTS (SELECT * FROM #apinpchg)    
    RETURN 0    
    
     
 SELECT  @tran_started = 0    
    
    
    
    
    
 SELECT  @vend_flag = apactvnd_flag,    
 @pto_flag = apactpto_flag,    
 @cls_flag = apactcls_flag,    
 @bch_flag = apactbch_flag    
  FROM    apco    
    
     
    
    
    
    
 UPDATE  #apinpchg    
 SET     intercompany_flag = 1    
 FROM    #apinpchg h, #apinpcdt d    
 WHERE   h.trx_ctrl_num = d.trx_ctrl_num    
 AND     h.company_code != d.rec_company_code    
    
 IF (@batch_source IS NOT NULL)    
    
  IF (SELECT batch_desc_flag from apco (NOLOCK)) = 1    
   BEGIN    
    SELECT @batch_desc = batch_description FROM batchctl (NOLOCK) WHERE batch_ctrl_num = @batch_source    
   END    
  ELSE    
   BEGIN    
    EXEC appgetstring_sp "STR_CREATED_FROM", @str_msg OUT    
    SELECT @batch_desc = @str_msg + @batch_source    
   END    
    
    
     
    
    
    
 IF EXISTS(      SELECT  *    
   FROM    apco    
   WHERE   batch_proc_flag = 1 )    
 BEGIN    
  INSERT #apvobat    
  SELECT  DISTINCT    date_applied,     
          process_group_num,    
       trx_type,    
       hold_flag,    
       org_id     
  FROM    #apinpchg    
    
      
    
    
    
  IF @@rowcount > 1    
      SELECT @batch_code = NULL    
    
 END    
     
 SELECT @home_company = company_code from glco    
    
     
    
    
 SELECT  @start_user_id = isnull((select  b.user_id    
 FROM batchctl a, ewusers_vw b    
 WHERE a.batch_ctrl_num = @batch_source    
 AND a.start_user = b.user_name), @proc_user_id) -- mls 1/9/02 SCR 27778    
    
     
    
    
    
    
 IF ( @@trancount = 0 )    
 BEGIN    
  BEGIN TRANSACTION    
  SELECT  @tran_started = 1    
 END    
     
    
    
    
 IF EXISTS(      SELECT  *    
   FROM    apco    
   WHERE   batch_proc_flag = 1 )    
 BEGIN    
  IF ( @batch_code IS NULL )    
   BEGIN    
      
     
    WHILE 1=1    
    BEGIN    
     SELECT  @batch_date_applied = NULL    
     SELECT  @batch_date_applied = MIN( date_applied )    
     FROM    #apvobat    
       
     IF ( @batch_date_applied IS NULL )    
      break    
       
       
     SELECT @trx_type = MIN( trx_type ),    
            @org_id   = MIN (org_id)     
     FROM   #apvobat    
     WHERE  date_applied = @batch_date_applied    
    
     SELECT @hold_flag = MIN( hold_flag )    
     FROM   #apvobat    
     WHERE  date_applied = @batch_date_applied    
       
     IF     @trx_type = 4091    
            SELECT @batch_trx_type = 4010    
        ELSE IF @trx_type = 4021    
         SELECT @batch_trx_type = 4050    
     ELSE IF @trx_type = 4092    
            SELECT @batch_trx_type = 4030    
    
    
     SELECT @new_batch_code = NULL    
      
     EXEC    @result = apnxtbat_sp       
        @batch_module_id,    
        @batch_source,    
        @batch_trx_type,    
        @start_user_id,    
        @batch_date_applied,    
        @home_company,    
        @new_batch_code OUTPUT,    
        @batch_desc,    
        @org_id     
    
     IF ( @result != 0 )    
      RETURN  @result    
        
     UPDATE  #apinpchg    
     SET     batch_code = @new_batch_code    
     WHERE   date_applied = @batch_date_applied    
     AND     trx_type = @trx_type    
     AND  org_id = @org_id    
     AND hold_flag = @hold_flag    
    
     UPDATE batchctl    
     SET actual_number = (SELECT COUNT(*) FROM #apinpchg    
          WHERE batch_code = @new_batch_code),    
      actual_total = (SELECT ISNULL(SUM(amt_net),0.0) FROM #apinpchg    
          WHERE batch_code = @new_batch_code),    
      number_held = (SELECT COUNT(*) FROM #apinpchg    
          WHERE batch_code = @new_batch_code    
          AND hold_flag = 1)    
     WHERE batch_ctrl_num = @new_batch_code    
    
     UPDATE batchctl    
     SET hold_flag = SIGN(number_held)    
     WHERE batch_ctrl_num = @new_batch_code    
         
             
     DELETE  #apvobat    
     WHERE   date_applied = @batch_date_applied    
     AND trx_type = @trx_type    
     AND hold_flag = @hold_flag    
     AND org_id = @org_id        
    
     SELECT @new_batch_code = NULL     
    
       
    END    
   END    
  ELSE    
   BEGIN    
        
    SELECT @new_batch_code = @batch_code    
    
    SELECT     @trx_type = trx_type,     
        @batch_date_applied = date_applied,    
        @org_id = org_id     
       FROM   #apvobat    
    
    IF     @trx_type = 4091    
           SELECT @batch_trx_type = 4010    
       ELSE IF @trx_type = 4021    
        SELECT @batch_trx_type = 4050    
    ELSE IF @trx_type = 4092    
           SELECT @batch_trx_type = 4030    
    
    EXEC    @result = apnxtbat_sp       
       @batch_module_id,    
       '',    
       @batch_trx_type,    
       @start_user_id,    
       @batch_date_applied,    
       @home_company,    
       @new_batch_code OUTPUT,    
       @batch_desc,    
       @org_id     
    
    UPDATE  #apinpchg    
    SET     batch_code = @new_batch_code    
    
    UPDATE batchctl    
    SET actual_number = (SELECT COUNT(*) FROM #apinpchg),    
     actual_total = (SELECT ISNULL(SUM(amt_net),0.0) FROM #apinpchg),    
     number_held = (SELECT COUNT(*) FROM #apinpchg     
         WHERE hold_flag = 1)    
    WHERE batch_ctrl_num = @new_batch_code    
    
    UPDATE batchctl    
    SET hold_flag = SIGN(number_held)    
       WHERE batch_ctrl_num = @new_batch_code    
      END    
      
 END    
    
    
EXEC @result = apvoact_sp @debug    
IF (@result != 0)    
     RETURN  @result    
    
    
    
    
    
    
    
  INSERT apinpage  (    
 timestamp,    
 trx_ctrl_num,    
 trx_type,    
 sequence_id,    
 date_applied,    
 date_due,    
 date_aging,    
 amt_due     )    
    
   SELECT  NULL,    
 trx_ctrl_num,    
 trx_type,    
 sequence_id,    
 date_applied,    
 date_due,    
 date_aging,    
 amt_due    
    
 FROM    #apinpage    
    
 IF ( @@error != 0 )    
 BEGIN    
  rollback transaction    
  RETURN  -1    
 END    
    
    
    
    
     
if exists (SELECT 1 FROM tempdb..syscolumns WHERE id = OBJECT_ID('tempdb..#apinpchg')    
  AND name = 'pay_to_country_code')    
begin    
 EXEC('    
 INSERT  apinpchg (          
 timestamp,    
 trx_ctrl_num,    
 trx_type,    
 doc_ctrl_num,    
 apply_to_num,    
 user_trx_type_code,    
 batch_code,    
 po_ctrl_num,    
 vend_order_num,    
 ticket_num,    
 date_applied,    
 date_aging,    
 date_due,    
 date_doc,    
 date_entered,    
 date_received,    
 date_required,    
 date_recurring,    
 date_discount,    
 posting_code,    
 vendor_code,    
 pay_to_code,    
 branch_code,    
 class_code,    
 approval_code,    
 comment_code,    
 fob_code,    
 terms_code,    
 tax_code,    
 recurring_code,    
 location_code,    
 payment_code,    
 times_accrued,    
 accrual_flag,    
 drop_ship_flag,    
 posted_flag,    
 hold_flag,    
 add_cost_flag,    
 approval_flag,    
 recurring_flag,    
 one_time_vend_flag,    
 one_check_flag,    
 amt_gross,    
 amt_discount,    
 amt_tax,    
 amt_freight,    
 amt_misc,    
 amt_net ,    
 amt_paid,    
 amt_due,    
 amt_restock,    
 amt_tax_included,    
 frt_calc_tax,    
 doc_desc,    
 hold_desc,    
 user_id,    
 next_serial_id,    
 pay_to_addr1,    
 pay_to_addr2,    
 pay_to_addr3,    
 pay_to_addr4,    
 pay_to_addr5,    
 pay_to_addr6,    
 attention_name,    
 attention_phone,    
 intercompany_flag,    
 company_code,    
 cms_flag,    
 process_group_num,      
 nat_cur_code,      
 rate_type_home,      
 rate_type_oper,      
 rate_home,         
 rate_oper,    
 net_original_amt,    
        org_id,    
 tax_freight_no_recoverable,    
     
 pay_to_country_code,    
    pay_to_city,    
    pay_to_state,    
    pay_to_postal_code    
)    
       
 SELECT          NULL,    
   trx_ctrl_num,    
 trx_type,    
 doc_ctrl_num,    
 apply_to_num,    
 user_trx_type_code,    
 batch_code,    
 po_ctrl_num,    
 vend_order_num,    
 ticket_num,    
 date_applied,    
 date_aging,    
 date_due,    
 date_doc,    
 date_entered,    
 date_received,    
 date_required,    
 date_recurring,    
 date_discount,    
 posting_code,    
 vendor_code,    
 pay_to_code,    
 branch_code,    
 class_code,    
 approval_code,    
 comment_code,    
 fob_code,    
 terms_code,    
 tax_code,    
 recurring_code,    
 location_code,    
 payment_code,    
 times_accrued,    
 accrual_flag,    
 drop_ship_flag,    
 posted_flag,    
 hold_flag,    
 add_cost_flag,    
 approval_flag,    
 recurring_flag,    
 one_time_vend_flag,    
 one_check_flag,    
 amt_gross,    
 amt_discount,    
 amt_tax,    
 amt_freight,    
 amt_misc,    
 amt_net ,    
 amt_paid,    
 amt_due,    
 amt_restock,    
 amt_tax_included,    
 frt_calc_tax,    
 doc_desc,    
 hold_desc,    
 user_id,    
 next_serial_id,    
 pay_to_addr1,    
 pay_to_addr2,    
 pay_to_addr3,    
 pay_to_addr4,    
 pay_to_addr5,    
 pay_to_addr6,    
 attention_name,    
 attention_phone,    
 intercompany_flag,    
 company_code,    
 cms_flag,    
 process_group_num,    
 nat_cur_code,      
 rate_type_home,      
 rate_type_oper,      
 rate_home,         
 rate_oper,    
 net_original_amt,    
        org_id,    
 tax_freight_no_recoverable,    
     
 pay_to_country_code,    
    pay_to_city,    
    pay_to_state,    
    pay_to_postal_code    
 FROM    #apinpchg')    
    
 IF ( @@error != 0 )    
 BEGIN    
  rollback transaction    
  RETURN  -1    
 END    
end    
else    
begin    
 INSERT  apinpchg (          
     
 timestamp,    
 trx_ctrl_num,    
 trx_type,    
 doc_ctrl_num,    
 apply_to_num,    
 user_trx_type_code,    
 batch_code,    
 po_ctrl_num,    
 vend_order_num,    
 ticket_num,    
 date_applied,    
 date_aging,    
 date_due,    
 date_doc,    
 date_entered,    
 date_received,    
 date_required,    
 date_recurring,    
 date_discount,    
 posting_code,    
 vendor_code,    
 pay_to_code,    
 branch_code,    
 class_code,    
 approval_code,    
 comment_code,    
 fob_code,    
 terms_code,    
 tax_code,    
 recurring_code,    
 location_code,    
 payment_code,    
 times_accrued,    
 accrual_flag,    
 drop_ship_flag,    
 posted_flag,    
 hold_flag,    
 add_cost_flag,    
 approval_flag,    
 recurring_flag,    
 one_time_vend_flag,    
 one_check_flag,    
 amt_gross,    
 amt_discount,    
 amt_tax,    
 amt_freight,    
 amt_misc,    
 amt_net ,    
 amt_paid,    
 amt_due,    
 amt_restock,    
 amt_tax_included,    
 frt_calc_tax,    
 doc_desc,    
 hold_desc,    
 user_id,    
 next_serial_id,    
 pay_to_addr1,    
 pay_to_addr2,    
 pay_to_addr3,    
 pay_to_addr4,    
 pay_to_addr5,    
 pay_to_addr6,    
 attention_name,    
 attention_phone,    
 intercompany_flag,    
 company_code,    
 cms_flag,    
 process_group_num,      
 nat_cur_code,      
 rate_type_home,      
 rate_type_oper,      
 rate_home,         
 rate_oper,    
 net_original_amt,    
        org_id,    
 tax_freight_no_recoverable    
)    
       
 SELECT          NULL,    
   trx_ctrl_num,    
 trx_type,    
 doc_ctrl_num,    
 apply_to_num,    
 user_trx_type_code,    
 batch_code,    
 po_ctrl_num,    
 vend_order_num,    
 ticket_num,    
 date_applied,    
 date_aging,    
 date_due,    
 date_doc,    
 date_entered,    
 date_received,    
 date_required,    
 date_recurring,    
 date_discount,    
 posting_code,    
 vendor_code,    
 ISNULL(pay_to_code,''),    
 branch_code,    
 class_code,    
 approval_code,    
 comment_code,    
 fob_code,    
 terms_code,    
 tax_code,    
 recurring_code,    
 location_code,    
 payment_code,    
 times_accrued,    
 accrual_flag,    
 drop_ship_flag,    
 posted_flag,    
 hold_flag,    
 add_cost_flag,    
 approval_flag,    
 recurring_flag,    
 one_time_vend_flag,    
 one_check_flag,    
 amt_gross,    
 amt_discount,    
 amt_tax,    
 amt_freight,    
 amt_misc,    
 amt_net ,    
 amt_paid,    
 amt_due,    
 amt_restock,    
 amt_tax_included,    
 frt_calc_tax,    
 doc_desc,    
 hold_desc,    
 user_id,    
 next_serial_id,    
 pay_to_addr1,    
 pay_to_addr2,    
 pay_to_addr3,    
 pay_to_addr4,    
 pay_to_addr5,    
 pay_to_addr6,    
 attention_name,    
 attention_phone,    
 intercompany_flag,    
 company_code,    
 cms_flag,    
 process_group_num,    
 nat_cur_code,      
 rate_type_home,      
 rate_type_oper,      
 rate_home,         
 rate_oper,    
 net_original_amt,    
        org_id,    
 tax_freight_no_recoverable    
 FROM    #apinpchg    
    
 IF ( @@error != 0 )    
 BEGIN    
  rollback transaction    
  RETURN  -1    
 END    
end    
    
     
    
    
 INSERT  apinpcdt (    
  timestamp,    
 trx_ctrl_num,    
 trx_type,    
 sequence_id,    
 location_code,    
 item_code,    
 bulk_flag,    
 qty_ordered,    
 qty_received,    
 qty_returned,    
 qty_prev_returned,    
 approval_code,    
 tax_code,    
 return_code,    
 code_1099,    
 po_ctrl_num,    
 unit_code,    
 unit_price,    
 amt_discount,    
 amt_freight,    
 amt_tax,    
 amt_misc,    
 amt_extended,    
 calc_tax,    
 date_entered,    
 gl_exp_acct,    
 new_gl_exp_acct,    
 rma_num,    
 line_desc,    
 serial_id,    
 company_id,    
 iv_post_flag,    
 po_orig_flag,    
 rec_company_code,    
 new_rec_company_code,    
 reference_code,    
 new_reference_code,    
 org_id,    
 amt_nonrecoverable_tax,    
 amt_tax_det )    
        
 SELECT  NULL,    
  trx_ctrl_num,    
 trx_type,    
 sequence_id,    
 location_code,    
 item_code,    
 bulk_flag,    
 qty_ordered,    
 qty_received,    
 qty_returned,    
 qty_prev_returned,    
 approval_code,    
 tax_code,    
 return_code,    
 code_1099,    
 po_ctrl_num,    
 unit_code,    
 unit_price,    
 amt_discount,    
 amt_freight,    
 amt_tax,    
 amt_misc,    
 amt_extended,    
 calc_tax,    
 date_entered,    
 gl_exp_acct,    
 new_gl_exp_acct,    
 rma_num,    
 line_desc,    
 serial_id,    
 company_id,    
 iv_post_flag,    
 po_orig_flag,    
 rec_company_code,    
 new_rec_company_code,    
 reference_code,    
 new_reference_code,    
 org_id,    
 amt_nonrecoverable_tax,    
 amt_tax_det          
 FROM    #apinpcdt    
    
 IF ( @@error != 0 )    
 BEGIN    
  rollback transaction    
  RETURN  -1    
 END    
    
    
    
    
    
    
 INSERT apinptax  (    
 timestamp,    
 trx_ctrl_num,    
 trx_type,    
 sequence_id,    
 tax_type_code,    
 amt_taxable,    
 amt_gross,    
 amt_tax,    
 amt_final_tax   )    
 SELECT    
 NULL,    
 trx_ctrl_num,    
 trx_type,    
 sequence_id,    
 tax_type_code,    
 amt_taxable,    
 amt_gross,    
 amt_tax,    
 amt_final_tax    
FROM #apinptax    
    
IF ( @@error != 0 )    
 BEGIN    
  rollback transaction    
  RETURN  -1    
 END    
      
    
    
 INSERT apinptaxdtl  (    
 timestamp,    
 trx_ctrl_num,    
 sequence_id,    
 trx_type,    
 tax_sequence_id,    
 detail_sequence_id,    
 tax_type_code,    
 amt_taxable,    
 amt_gross,    
 amt_tax,    
 amt_final_tax,    
 recoverable_flag,    
 account_code                          
   )    
 SELECT    
 NULL,    
 trx_ctrl_num,    
 sequence_id,    
 trx_type,    
 tax_sequence_id,    
 detail_sequence_id,    
 tax_type_code,    
 amt_taxable,    
 amt_gross,    
 amt_tax,    
 amt_final_tax,    
 recoverable_flag,    
 account_code         
FROM #apinptaxdtl    
    
IF ( @@error != 0 )    
 BEGIN    
  rollback transaction    
  RETURN  -1    
 END    
    
    
     
    
    
    
    
    
    
 EXEC    @result = apvousv_sp    
 IF ( @result != 0 )    
  RETURN  @result    
      
    
    
     
    
    
    
 EXEC @result = APVOPsaReTrxDel_sp    
 IF ( @result != 0 )    
  RETURN  @result    
     
    
    
    
    
  DELETE #apinpchg    
  DELETE #apinpcdt    
  DELETE #apinpage    
  DELETE #apinptax    
  DELETE #apinptaxdtl    
    
  DELETE #apvobat    
    
    
    
 IF ( @tran_started = 1 )    
 BEGIN    
  COMMIT TRANSACTION    
  SELECT  @tran_started = 0    
 END    
     
    
    
    
    
       
END 
GO
GRANT EXECUTE ON  [dbo].[apvosav_sp] TO [public]
GO
