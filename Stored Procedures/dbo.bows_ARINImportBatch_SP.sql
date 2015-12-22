SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
    
    
CREATE PROCEDURE [dbo].[bows_ARINImportBatch_SP]    
      @debug_level smallint = 0    
    
AS    
 DECLARE    
  @user_id  smallint,    
  @user_name  varchar(30),    
  @process_ctrl_num varchar(16),    
  @result   int,    
  @ARApplyDocPosted int    
    
BEGIN    
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/bows_arinib.sp' + ', line ' + STR( 23, 5 ) + ' -- ENTRY: '    
    
 SELECT  @user_name   = ARUserName,    
  @ARApplyDocPosted = ARApplyDocPosted    
 FROM  bows_Config    
    
 SELECT @user_id = ISNULL(@user_id,0)    
 IF @user_id = 0 BEGIN    
  SELECT @user_name = ISNULL(@user_name, (SELECT [name]    
    FROM [master]..[syslogins]    
    WHERE [sid] = SUSER_SID()))    
  SELECT @user_id = [user_id]    
  FROM ewusers_vw    
  WHERE [user_name] = @user_name    
 END    
    
 SELECT @process_ctrl_num = '1'    
    
 EXEC @result = bows_ARINImportSetDefaults_SP @process_ctrl_num,    
       @debug_level    
 IF ( @result != 0 )    
 BEGIN    
  IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/bows_arinib.sp' + ', line ' + STR( 53, 5 ) + ' -- MSG: ' + 'ARINImportSetDefaults_SP failed!'    
  RETURN @result    
 END    
    
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
    
CREATE TABLE #bows_invalid_acct (    
 trx_ctrl_num  varchar(16),    
 trx_type  smallint,    
 sequence_id  int,    
 account_code  varchar(32),    
 reference_code  varchar(32)    
)    
    
 EXEC @result = bows_arinval_sp @debug_level, @user_id    
    
CREATE TABLE #arinpage    
(    
 trx_ctrl_num  varchar(16),    
 sequence_id  int,    
 doc_ctrl_num  varchar(16),    
 apply_to_num  varchar(16),    
 apply_trx_type smallint,    
 trx_type  smallint,    
 date_applied  int,    
 date_due  int,    
 date_aging  int,    
 customer_code  varchar(8),    
 salesperson_code varchar(8),    
 territory_code varchar(8),    
 price_code  varchar(8),    
 amt_due  float,    
 trx_state  smallint NULL,    
 mark_flag  smallint NULL    
)    
    
CREATE UNIQUE INDEX arinpage_ind_0    
ON #arinpage ( trx_ctrl_num, trx_type, sequence_id )    
    
CREATE TABLE #arinptax    
(    
 trx_ctrl_num varchar(16),    
 trx_type smallint,    
 sequence_id int,    
 tax_type_code varchar(8),    
 amt_taxable float,    
 amt_gross float,    
 amt_tax float,    
 amt_final_tax float,    
 trx_state  smallint NULL,    
 mark_flag  smallint NULL    
)    
    
CREATE UNIQUE INDEX arinptax_ind_0    
 ON #arinptax ( trx_ctrl_num, trx_type, sequence_id )    
    
CREATE TABLE #arinprev    
(    
 timestamp timestamp,    
 trx_ctrl_num varchar(16),    
 sequence_id int,    
 rev_acct_code varchar(32),    
 apply_amt float,    
 trx_type smallint    
)    
    
CREATE TABLE #arinptmp    
(    
 timestamp  timestamp,    
 trx_ctrl_num  varchar(16),    
 doc_ctrl_num  varchar(16),    
 trx_desc  varchar(40),    
 date_doc  int,    
 customer_code  varchar(8),    
 payment_code  varchar(8),    
 amt_payment  float,    
 prompt1_inp  varchar(30),    
 prompt2_inp  varchar(30),    
 prompt3_inp  varchar(30),    
 prompt4_inp  varchar(30),    
 amt_disc_taken  float,    
 cash_acct_code  varchar(32)    
)    
    
CREATE TABLE #aritemp    
(    
 code varchar(8),    
 code2 varchar(8),    
 mark_flag smallint,    
 amt_home float,    
 amt_oper float    
)    
    
 EXEC @result = bows_ARINImportCreateRecords_SP  @process_ctrl_num,    
        @user_id,    
        @debug_level    
 IF ( @result != 0 )    
 BEGIN    
  IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/bows_arinib.sp' + ', line ' + STR( 75, 5 ) + ' -- MSG: ' + 'ARINImportLoadData_SP failed!'    
  RETURN @result    
 END    
    
CREATE TABLE #arvalchg    
(    
 trx_ctrl_num varchar(16),    
 doc_ctrl_num varchar(16),    
 doc_desc varchar(40),    
 apply_to_num varchar(16),    
 apply_trx_type smallint,    
 order_ctrl_num varchar(16),    
 batch_code varchar(16),    
 trx_type smallint,    
 date_entered int,    
 date_applied int,    
 date_doc int,    
 date_shipped int,    
 date_required int,    
 date_due int,    
 date_aging int,    
 customer_code varchar(8),    
 ship_to_code varchar(8),    
 salesperson_code varchar(8),    
 territory_code varchar(8),    
 comment_code varchar(8),    
 fob_code varchar(8),    
 freight_code varchar(8),    
 terms_code varchar(8),    
 fin_chg_code varchar(8),    
 price_code varchar(8),    
 dest_zone_code varchar(8),    
 posting_code varchar(8),    
 recurring_flag smallint,    
 recurring_code varchar(8),    
 tax_code varchar(8),    
 cust_po_num varchar(20),    
 total_weight float,    
 amt_gross float,    
 amt_freight float,    
 amt_tax float,    
 amt_tax_included float,    
 amt_discount float,    
 amt_net float,    
 amt_paid float,    
 amt_due float,    
 amt_cost float,    
 amt_profit float,    
 next_serial_id smallint,    
 printed_flag smallint,    
 posted_flag smallint,    
 hold_flag smallint,    
 hold_desc varchar(40),    
 user_id smallint,    
 customer_addr1 varchar(40),    
 customer_addr2 varchar(40),    
 customer_addr3 varchar(40),    
 customer_addr4 varchar(40),    
 customer_addr5 varchar(40),    
 customer_addr6 varchar(40),    
 ship_to_addr1 varchar(40),    
 ship_to_addr2 varchar(40),    
 ship_to_addr3 varchar(40),    
 ship_to_addr4 varchar(40),    
 ship_to_addr5 varchar(40),    
 ship_to_addr6 varchar(40),    
 attention_name varchar(40),    
 attention_phone varchar(30),    
 amt_rem_rev float,    
 amt_rem_tax float,    
 date_recurring int,    
 location_code varchar(8),    
 process_group_num varchar(16) NULL,    
 source_trx_ctrl_num varchar(16) NULL,    
 source_trx_type smallint NULL,    
 amt_discount_taken float NULL,    
 amt_write_off_given float NULL,    
 nat_cur_code varchar(8),    
 rate_type_home varchar(8),    
 rate_type_oper varchar(8),    
 rate_home float,    
 rate_oper float,    
 temp_flag smallint NULL,    
 org_id varchar(30) NULL,    
 interbranch_flag integer NULL,    
 temp_flag2 integer NULL    
)    
    
CREATE TABLE #arvalcdt    
(    
 trx_ctrl_num  varchar(16),    
 doc_ctrl_num  varchar(16),    
 sequence_id   int,    
 trx_type   smallint,    
 location_code  varchar(8),    
 item_code   varchar(30),    
 bulk_flag   smallint,    
 date_entered  int,    
 line_desc   varchar(60),    
 qty_ordered   float,    
 qty_shipped   float,    
 unit_code   varchar(8),    
 unit_price   float,    
 unit_cost   float,    
 extended_price float,    
 weight    float,    
 serial_id   int,    
 tax_code   varchar(8),    
 gl_rev_acct   varchar(32),    
 disc_prc_flag  smallint,    
 discount_amt  float,    
 discount_prc  float,    
 commission_flag smallint,    
 rma_num  varchar(16),    
 return_code   varchar(8),    
 qty_returned  float,    
 qty_prev_returned float,    
 new_gl_rev_acct varchar(32),    
 iv_post_flag  smallint,    
 oe_orig_flag  smallint,    
 calc_tax  float,    
 reference_code varchar(32) NULL,    
 new_reference_code varchar(32) NULL,    
 temp_flag  smallint NULL,    
 org_id  varchar(30) NULL,    
 temp_flag2 integer NULL    
)    
    
CREATE TABLE #arvalage    
(    
 trx_ctrl_num  varchar(16),    
 sequence_id  int,    
 doc_ctrl_num  varchar(16),    
 apply_to_num  varchar(16),    
 apply_trx_type smallint,    
 trx_type  smallint,    
 date_applied  int,    
 date_due  int,    
 date_aging  int,    
 customer_code  varchar(8),    
 salesperson_code varchar(8),    
 territory_code varchar(8),    
 price_code  varchar(8),    
 amt_due  float,    
 temp_flag   smallint NULL    
)    
    
CREATE TABLE #arvaltax    
(    
 trx_ctrl_num  varchar(16),    
 trx_type  smallint,    
 sequence_id  int,    
 tax_type_code  varchar(8),    
 amt_taxable  float,    
 amt_gross  float,    
 amt_tax   float,    
 amt_final_tax  float,    
 temp_flag   smallint NULL    
)    
    
CREATE TABLE #arvalrev    
(    
 trx_ctrl_num varchar(16),    
 sequence_id int,    
 rev_acct_code varchar(32),    
 apply_amt float,    
 trx_type smallint,    
 reference_code varchar(32) NULL,    
 temp_flag  smallint,    
 org_id varchar(30) NULL,     
 interbranch_flag integer NULL    
)    
    
CREATE TABLE #arvaltmp    
(    
 trx_ctrl_num  varchar(16),    
 doc_ctrl_num  varchar(16),    
 date_doc  int,    
 customer_code  varchar(8),    
 payment_code  varchar(8),    
 amt_payment  float,    
 amt_disc_taken float,    
 cash_acct_code varchar(32),    
 temp_flag   smallint NULL    
)    
    
 SET @result= -1    
 EXEC @result = ARINSrcInsertValTables_SP  @debug_level    
 IF ( @result != 0 )    
 BEGIN    
  IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/bows_arinib.sp' + ', line ' + STR( 94, 5 ) + ' -- MSG: ' + 'ARINSrcInsertValTables_SP failed!'    
  RETURN @result    
 END    
    
 IF @debug_level>5 BEGIN    
  SELECT '**** #arinpchg before validation ****'    
  SELECT * FROM #arinpchg    
  SELECT '**** #arinpcdt before validation ****'    
  SELECT * FROM #arinpcdt    
  SELECT '**** #arinpage before validation ****'    
  SELECT * FROM #arinpage    
  SELECT '**** #arinptax before validation ****'    
  SELECT * FROM #arinptax    
  SELECT '**** #arinpcom before validation ****'    
  SELECT * FROM #arinpcom    
  SELECT '**** #comments before validation ****'    
  SELECT * FROM #comments    
 END    
    
 EXEC @result = arinvedt_sp 1, @debug_level    
    
 IF ( @result != 0 )    
 BEGIN    
  IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/bows_arinib.sp' + ', line ' + STR( 119, 5 ) + ' -- MSG: ' + 'arinvedt_sp failed!'    
  RETURN @result    
 END    
    
 IF @debug_level>5 BEGIN    
  SELECT '**** #ewerror after validation ****'    
  SELECT * FROM #ewerror    
 END    
    
 IF NOT (@ARApplyDocPosted = 0) BEGIN    
  DELETE  e    
  FROM #ewerror e, #arinpchg a    
  WHERE e.err_code IN (20004,20204)    
  AND e.trx_ctrl_num = a.trx_ctrl_num    
  AND a.trx_type = 2032    
 END    
    
 DROP TABLE #arvalage    
 DROP TABLE #arvalchg    
 DROP TABLE #arvalcdt    
 DROP TABLE #arvaltax    
 DROP TABLE #arvalrev    
 DROP TABLE #arvaltmp    
    
 IF @debug_level>0 BEGIN    
  SELECT 'Dumping #ewerror...'    
  SELECT * FROM #ewerror    
 END    
    
 EXEC @result = bows_ARINImportSaveToPerm_SP @user_id,    
       @debug_level    
    
 IF ( @result != 0 )    
 BEGIN    
  IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/bows_arinib.sp' + ', line ' + STR( 173, 5 ) + ' -- MSG: ' + 'ARINImportSaveToPerm_SP failed!'    
  RETURN @result    
 END    
    
 DROP TABLE #arinpage    
 DROP TABLE #arinptax    
 DROP TABLE #arinprev    
 DROP TABLE #arinptmp    
 DROP TABLE #aritemp    
 DROP TABLE #comments    
 DROP TABLE #bows_invalid_acct    
    
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/bows_arinib.sp' + ', line ' + STR( 185, 5 ) + ' -- EXIT: '    
 RETURN 0    
END    
GO
GRANT EXECUTE ON  [dbo].[bows_ARINImportBatch_SP] TO [public]
GO
