SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


    CREATE PROC 
[dbo].[IMAPValidateVoucher_sp] @db_userid char(40), 
                       @db_password char(40), 
                       @invoice_flag smallint, 
                       @debug_level int, 
                       @pcn varchar(16) OUTPUT,
                       @IMAPValidateVoucher_sp_company_code VARCHAR(8),
                       @userid INT = 0
    AS    
    DECLARE @Additional_Intercompany_Validation NVARCHAR(1000)  
    DECLARE @buf varchar(255)
    DECLARE @Database_Names_Cursor_Allocated VARCHAR(3)
    DECLARE @Database_Names_company_code VARCHAR(8)
    DECLARE @Database_Names_Cursor_Opened VARCHAR(3)
    DECLARE @Database_Names_db_name VARCHAR(128)     
    DECLARE @im_config_Validate_Errors_Only SMALLINT
    DECLARE @module_id SMALLINT
    DECLARE @process_ctrl_num VARCHAR(16)
    DECLARE @result numeric(16,0)
    DECLARE @spid int
    
    --
    -- CHECK_SQL_STATUS data items.
    -- 
    DECLARE @CSS_Intermediate_String NVARCHAR(1000)
    DECLARE @CSS_Log_String NVARCHAR(1000)
    --
    

    
    --
    -- Standard data.
    -- 
    DECLARE @Allow_Import_of_trx_ctrl_num NVARCHAR(1000)
    DECLARE @Error_Code INT
    DECLARE @Error_Table_Name NVARCHAR(200)
    DECLARE @Import_Identifier INT
    DECLARE @im_config_DATEFORMAT NVARCHAR(1000)
    DECLARE @January_First_Nineteen_Eighty VARCHAR(10)
    DECLARE @Process_User_ID INT
    DECLARE @Reset_processed_flag NVARCHAR(1000)
    DECLARE @Routine_Name NVARCHAR(200)
    DECLARE @ROLLBACK_On_Error VARCHAR(10)
    DECLARE @Row_Count INT
    DECLARE @SP_Result INT
    DECLARE @SQL NVARCHAR(4000)
    DECLARE @Text_String NVARCHAR(1000)
    DECLARE @Text_String_1 NVARCHAR(1000)
    DECLARE @Text_String_2 NVARCHAR(1000)
    DECLARE @Text_String_3 NVARCHAR(1000)
    --
    SET @ROLLBACK_On_Error = 'NO'
    --
    

    SET NOCOUNT ON
    
    --
    -- External strings
    --
    DECLARE @External_String NVARCHAR(1000)
    DECLARE @External_String_1 NVARCHAR(1000)
    DECLARE @External_String_2 NVARCHAR(1000)
    DECLARE @External_String_3 NVARCHAR(1000)
    DECLARE @External_String_4 NVARCHAR(1000)
    --
    DECLARE @External_String_BEGINTRANSACTION NVARCHAR(100)
    DECLARE @External_String_CLOSE NVARCHAR(100)
    DECLARE @External_String_COMMIT NVARCHAR(100)
    DECLARE @External_String_COMMITTRANSACTION NVARCHAR(100)
    DECLARE @External_String_CREATEINDEX NVARCHAR(100)
    DECLARE @External_String_CREATETABLE NVARCHAR(100)
    DECLARE @External_String_DEALLOCATE NVARCHAR(100)
    DECLARE @External_String_DECLARE NVARCHAR(100)
    DECLARE @External_String_DELETE NVARCHAR(100)
    DECLARE @External_String_DROPTABLE NVARCHAR(100)
    DECLARE @External_String_EXEC NVARCHAR(100)
    DECLARE @External_String_FETCHNEXT NVARCHAR(100)
    DECLARE @External_String_INSERT NVARCHAR(100)
    DECLARE @External_String_OPEN NVARCHAR(100)
    DECLARE @External_String_SELECT NVARCHAR(100)
    DECLARE @External_String_SET NVARCHAR(100)
    DECLARE @External_String_UPDATE NVARCHAR(100)
    --EXEC CVO_Control..[im_get_external_string_sp] @IGES_String_Name = 'CLOSE', @IGES_String = @External_String_CLOSE OUT
    SET @External_String_BEGINTRANSACTION = 'BEGIN TRANSACTION'
    SET @External_String_CLOSE = 'CLOSE'
    SET @External_String_COMMIT = 'COMMIT'
    SET @External_String_COMMITTRANSACTION = 'COMMIT TRANSACTION'
    SET @External_String_CREATEINDEX = 'CREATE INDEX'
    SET @External_String_CREATETABLE = 'CREATE TABLE'
    SET @External_String_DEALLOCATE = 'DEALLOCATE'
    SET @External_String_DECLARE = 'DECLARE'
    SET @External_String_DELETE = 'DELETE'
    SET @External_String_DROPTABLE = 'DROP TABLE'
    SET @External_String_EXEC = 'EXEC'
    SET @External_String_FETCHNEXT = 'FETCH NEXT'
    SET @External_String_INSERT = 'INSERT'
    SET @External_String_OPEN = 'OPEN'
    SET @External_String_SELECT = 'SELECT'
    SET @External_String_SET = 'SET'
    SET @External_String_UPDATE = 'UPDATE'
    --
    

    SET @Routine_Name = 'IMAPValidateVoucher_sp' 
    SET @Error_Table_Name = 'imvdmerr_vw'  
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': Entry.  ' + RTRIM(LTRIM(ISNULL(@db_userid, ''))) + ',' + RTRIM(LTRIM(CONVERT(CHAR(4),@invoice_flag))) + ',' + RTRIM(LTRIM(CONVERT(CHAR(5),@debug_level)))
    --
    -- Validate parameters.
    --    
    IF NOT @invoice_flag = 4091
            AND NOT @invoice_flag = 4092
        BEGIN
        EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = 'invalid transaction type 1', 
                                                     @IGES_String = @External_String_1 OUT 
        EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = 'invalid transaction type 2', 
                                                     @IGES_String = @External_String_2 OUT 
        EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = 'invalid transaction type 3', 
                                                     @IGES_String = @External_String_3 OUT 
        EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = 'invalid transaction type 4', 
                                                     @IGES_String = @External_String_4 OUT 
        SET @External_String = @External_String_1 + ' ''''' + CAST(@invoice_flag AS VARCHAR) + ''''' ' + @External_String_2 + ' ''''@invoice_flag'''' ' + @External_String_3 + ' ''''' + @Routine_Name + ''''' ' + @External_String_4                                             
        EXEC im_log_sp @IL_Text = @External_String,
                       @IL_Log_Activity = 'YES',
                       @im_log_sp_User_ID = @userid
        GOTO Error_Return
        END          
    --    
    IF @userid = 0
            SELECT @userid = USER_ID()
    SET @module_id = 4000  
    SET @im_config_Validate_Errors_Only = 1
    SELECT @im_config_Validate_Errors_Only = ISNULL([INT Value], 1)
            FROM [im_config]
            WHERE LTRIM(RTRIM(UPPER(ISNULL([Item Name], '')))) = 'V/DM VALIDATE ERRORS ONLY'
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' im_config 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
    
CREATE TABLE #apveacct
(
 db_name      varchar(128),
 vchr_num     varchar(16),
 line         int,
 type         smallint,
 acct_code    varchar(32),
 date_applied int,
 reference_code varchar(32),
 flag         smallint,
 org_id			varchar(30) NULL
)

    









CREATE TABLE #ewerror
(
    module_id smallint,
	err_code  int,
	info1 char(32),
	info2 char(32),
	infoint int,
	infofloat float,
	flag1 smallint,
	trx_ctrl_num char(16),
	sequence_id int,
	source_ctrl_num char(16),
	extra int
)

    IF @invoice_flag = 4091
        BEGIN
        SET @process_ctrl_num = ''
        EXEC @SP_Result = pctrladd_sp @process_ctrl_num OUTPUT,
                                      'Import Manager -- Voucher Validation', 
                                      @userid,
                                      @module_id, 
                                      @IMAPValidateVoucher_sp_company_code,
                                      @invoice_flag
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' pctrladd_sp' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        IF NOT @SP_Result = 0
            BEGIN
            EXEC im_log_sp_error_sp @ILSE_Error_Code = @SP_Result,
                                    @ILSE_SP_Name = 'pctrladd_sp',
                                    @ILSE_String = '',
                                    @ILSE_Procedure_Name = @Routine_Name,
                                    @ILSE_Log_Activity = 'YES',
                                    @im_log_sp_error_sp_User_ID = @userid
            GOTO Error_Return
            END     
        
CREATE TABLE #apvovchg
(
	trx_ctrl_num		varchar(16), 
    trx_type		smallint,	
	doc_ctrl_num		varchar(16),
    apply_to_num		varchar(16),
	user_trx_type_code	varchar(8),	
	batch_code		varchar(16),
	po_ctrl_num		varchar(16),	
	vend_order_num		varchar(20),
	ticket_num		varchar(20),	
	date_applied		int,
	date_aging		int,	   
	date_due		int,
	date_doc		int,	   
	date_entered		int,
	date_received		int,
	date_required		int,
	date_recurring		int,
	date_discount		int,	
	posting_code		varchar(8),	
    vendor_code		varchar(12),	
    pay_to_code		varchar(8),	
	branch_code		varchar(8),	
	class_code		varchar(8),	
	approval_code		varchar(8),
	comment_code		varchar(8),
	fob_code		varchar(8),
	terms_code		varchar(8),
	tax_code		varchar(8),
	recurring_code		varchar(8),
	location_code		varchar(8),
	payment_code		varchar(8),
	times_accrued		smallint,  
	accrual_flag		smallint,  
	drop_ship_flag		smallint,  
	posted_flag		smallint,
	hold_flag		smallint,
	add_cost_flag		smallint,
	approval_flag	smallint,  
    recurring_flag		smallint,  
	one_time_vend_flag	smallint,  
	one_check_flag		smallint,  
    amt_gross		float,
    amt_discount		float,
    amt_tax			float,
    amt_freight		float,
    amt_misc		float,
    amt_net			float,
	amt_paid		float,
	amt_due			float,
	amt_tax_included	float,
	frt_calc_tax	float,
	doc_desc		varchar(40), 
	hold_desc		varchar(40), 
	user_id			smallint, 
	next_serial_id		smallint,
	pay_to_addr1		varchar(40),  
	pay_to_addr2		varchar(40),  
	pay_to_addr3		varchar(40),  
	pay_to_addr4		varchar(40),  
	pay_to_addr5		varchar(40),
	pay_to_addr6		varchar(40),
	attention_name		varchar(40),
	attention_phone		varchar(30),
	intercompany_flag	smallint,
	company_code		varchar(8),
	cms_flag		smallint,
	nat_cur_code 			varchar(8),	 
	rate_type_home 			varchar(8),	 
	rate_type_oper			varchar(8),	 
	rate_home 				float,		   
	rate_oper				float,
	flag					smallint,
	net_original_amt		float,
	org_id				varchar(30) NULL,
	interbranch_flag		integer NULL,
	temp_flag			integer NULL,
	tax_freight_no_recoverable	float
)
CREATE INDEX apvovchg_ind_1 ON #apvovchg (trx_ctrl_num)


        
CREATE TABLE #apvovcdt
(
	trx_ctrl_num		varchar(16),
	trx_type			smallint,
	sequence_id			int,
	location_code		varchar(8),
	item_code			varchar(30),
	bulk_flag			smallint,
	qty_ordered			float,
	qty_received		float,
	approval_code		varchar(8),	
	tax_code			varchar(8),
	code_1099			varchar(8),
	po_ctrl_num			varchar(16),
	unit_code			varchar(8),
	unit_price			float,
	amt_discount		float,
	amt_freight 		float,
	amt_tax     		float,
	amt_misc    		float,
	amt_extended		float,
	calc_tax			float,
	date_entered		int,
	gl_exp_acct			varchar(32),
	rma_num				varchar(20),
	line_desc			varchar(60),
	serial_id			int,
	company_id			smallint,
	iv_post_flag		smallint,
	po_orig_flag		smallint,
	rec_company_code	varchar(8),
	reference_code		varchar(32),
	flag				smallint
	,org_id             varchar(30) NULL
	,temp_flag			integer NULL,
	amt_nonrecoverable_tax	float
)
CREATE INDEX apvovcdt_ind_1 ON #apvovcdt (trx_ctrl_num, sequence_id)



        
CREATE TABLE #apvovage
(
	trx_ctrl_num		varchar(16),
	trx_type		smallint,
	sequence_id		int,
	date_applied		int,
	date_due		int,
	date_aging		int,
	amt_due			float
)

        
CREATE TABLE #apvovtax
(
	trx_ctrl_num			varchar(16),
	trx_type			smallint,
	sequence_id			int,
	tax_type_code			varchar(8),
	amt_taxable			float,
	amt_gross			float,
	amt_tax				float,
	amt_final_tax			float
)

        










CREATE TABLE #apvovtaxdtl
(
	trx_ctrl_num		varchar(16),
	sequence_id		integer,
	trx_type		integer,
	tax_sequence_id		integer,
	detail_sequence_id	integer,
	tax_type_code		varchar(8),
	amt_taxable		float,
	amt_gross		float,
	amt_tax			float,
	amt_final_tax		float,
	recoverable_flag	integer,
	account_code		varchar(32)
)

        
CREATE TABLE #apvovtmp
(
	trx_ctrl_num		varchar(16),
	trx_type		smallint,
	doc_ctrl_num		varchar(16),
	trx_desc		varchar(40),
	date_applied		int,
	date_doc		int,
    vendor_code		varchar(12),
    payment_code		varchar(8),
	code_1099		varchar(8),
	cash_acct_code		varchar(32),
    amt_payment		float,
    amt_disc_taken		float,
	payment_type		smallint,
	approval_flag		smallint,
	user_id			smallint
)


        INSERT INTO #apvovchg (trx_ctrl_num,       trx_type,           doc_ctrl_num,      
                               apply_to_num,       user_trx_type_code, batch_code,     
                               po_ctrl_num,        vend_order_num,     ticket_num,     
                               date_applied,       date_aging,         date_due,       
                               date_doc,           date_entered,       date_received,  
                               date_required,      date_recurring,     date_discount,  
                               posting_code,       vendor_code,        pay_to_code,    
                               branch_code,        class_code,         approval_code,  
                               comment_code,       fob_code,           terms_code,     
                               tax_code,           recurring_code,     location_code,     
                               payment_code,       times_accrued,      accrual_flag,      
                               drop_ship_flag,     posted_flag,        hold_flag,       
                               add_cost_flag,      approval_flag,      recurring_flag,    
                               one_time_vend_flag, one_check_flag,     amt_gross,       
                               amt_discount,       amt_tax,            amt_freight,       
                               amt_misc,           amt_net,            amt_paid,       
                               amt_due,            amt_tax_included,   frt_calc_tax,   
                               doc_desc,           hold_desc,          user_id,           
                               next_serial_id,     pay_to_addr1,       pay_to_addr2,      
                               pay_to_addr3,       pay_to_addr4,       pay_to_addr5,      
                               pay_to_addr6,       attention_name,     attention_phone,   
                               intercompany_flag,  company_code,       cms_flag,       
                               nat_cur_code,       rate_type_home,     rate_type_oper,    
                               rate_home,          rate_oper,          flag,
			       org_id,		   tax_freight_no_recoverable,	interbranch_flag)
                SELECT trx_ctrl_num,       trx_type,           doc_ctrl_num,
                       apply_to_num,       user_trx_type_code, batch_code,
                       po_ctrl_num,        vend_order_num,     ticket_num,
                       date_applied,       date_aging,         date_due,
                       date_doc,           date_entered,       date_received,
                       date_required,      date_recurring,     date_discount,
                       posting_code,       vendor_code,        pay_to_code,
                       branch_code,        class_code,         approval_code,
                       comment_code,       fob_code,           terms_code,
                       tax_code,           recurring_code,     location_code,
                       payment_code,       times_accrued,      accrual_flag,
                       drop_ship_flag,     posted_flag,        hold_flag,
                       add_cost_flag,      approval_flag,      recurring_flag,
                       one_time_vend_flag, one_check_flag,     amt_gross,
                       amt_discount,       amt_tax,            amt_freight,
                       amt_misc,           amt_net,            amt_paid,
                       amt_due,            amt_tax_included,   frt_calc_tax,
                       doc_desc,           hold_desc,          user_id,            
                       next_serial_id,     pay_to_addr1,       pay_to_addr2,       
                       pay_to_addr3,       pay_to_addr4,       pay_to_addr5,       
                       pay_to_addr6,       attention_name,     attention_phone,    
                       intercompany_flag,  RTRIM(LTRIM(ISNULL(company_code, ''))), cms_flag,           
                       nat_cur_code,       rate_type_home,     rate_type_oper,     
                       rate_home,          rate_oper,          mark_flag,
		       org_id,		   tax_freight_no_recoverable,		0
                        FROM #apinpchg
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #apvovchg 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        INSERT INTO #apvovcdt (trx_ctrl_num,  trx_type,         sequence_id,            
                               location_code, item_code,        bulk_flag,            
                               qty_ordered,   qty_received,     approval_code,        
                               tax_code,      code_1099,        po_ctrl_num,   
                               unit_code,     unit_price,       amt_discount,        
                               amt_freight,   amt_tax,          amt_misc,            
                               amt_extended,  calc_tax,         date_entered,        
                               gl_exp_acct,   rma_num,          line_desc,            
                               serial_id,     company_id,       iv_post_flag,        
                               po_orig_flag,  rec_company_code, reference_code,        
                               flag,	      org_id,		amt_nonrecoverable_tax)
                SELECT trx_ctrl_num,  trx_type,               sequence_id,
                       location_code, item_code,              bulk_flag,
                       qty_ordered,   qty_received,           approval_code,   
                       tax_code,      code_1099,              po_ctrl_num,
                       unit_code,     unit_price,             amt_discount,
                       amt_freight,   amt_tax,                amt_misc,
                       amt_extended,  calc_tax,               date_entered,
                       gl_exp_acct,   rma_num,                line_desc,            
                       serial_id,     company_id,             iv_post_flag,         
                       po_orig_flag,  RTRIM(LTRIM(ISNULL(rec_company_code, ''))), reference_code,  
                       mark_flag,     org_id,		amt_nonrecoverable_tax
                        FROM #apinpcdt
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #apvovcdt 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        INSERT INTO #apvovage (trx_ctrl_num, trx_type, sequence_id,
                               date_applied, date_due, date_aging,
                               amt_due)
                SELECT trx_ctrl_num, trx_type, sequence_id,
                       date_applied, date_due, date_aging,
                       amt_due 
                        FROM #apinpage
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #apvovage 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        INSERT INTO #apvovtax (trx_ctrl_num,  trx_type,      sequence_id,
                               tax_type_code, amt_taxable,   amt_gross,
                               amt_tax,       amt_final_tax)
                SELECT trx_ctrl_num,  trx_type,      sequence_id,
                       tax_type_code, amt_taxable,   amt_gross,
                       amt_tax,       amt_final_tax
                        FROM #apinptax


      SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #apvovtaxdtl 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        INSERT INTO #apvovtaxdtl (	trx_ctrl_num,		sequence_id,		trx_type,
					tax_sequence_id,	detail_sequence_id,	tax_type_code,
					amt_taxable,		amt_gross,		amt_tax,
					amt_final_tax,		recoverable_flag,	account_code)
                SELECT 			trx_ctrl_num,		sequence_id,		trx_type,
					tax_sequence_id,	detail_sequence_id,	tax_type_code,
					amt_taxable,		amt_gross,		amt_tax,
					amt_final_tax,		recoverable_flag,	account_code
                        FROM #apinptaxdtl
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #apvovtax 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        INSERT INTO #apvovtmp (trx_ctrl_num,   trx_type,      doc_ctrl_num,
                               trx_desc,       date_applied,  date_doc,
                               vendor_code,    payment_code,  code_1099,
                               cash_acct_code, amt_payment,   amt_disc_taken,
                               payment_type,   approval_flag, user_id)
                SELECT trx_ctrl_num,   trx_type,      doc_ctrl_num,
                       trx_desc,       date_applied,  date_doc,
                       vendor_code,    payment_code,  code_1099,
                       cash_acct_code, amt_payment,   amt_disc_taken,
                       payment_type,   approval_flag, user_id 
                        FROM #apinptmp
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #apvovtmp 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        --
        EXEC @SP_Result = apvchedt_sp @im_config_Validate_Errors_Only, 
                                      @debug_level
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' apvchedt_sp 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        --
        -- apvchedt_sp currently only returns a 0, but this check is just good practice.
        --
        IF NOT @SP_Result = 0
            BEGIN
            EXEC im_log_sp_error_sp @ILSE_Error_Code = @SP_Result,
                                    @ILSE_SP_Name = 'apvchedt_sp',
                                    @ILSE_String = '',
                                    @ILSE_Procedure_Name = @Routine_Name,
                                    @ILSE_Log_Activity = 'YES',
                                    @im_log_sp_error_sp_User_ID = @userid
            GOTO Error_Return
            END                          
        --IF EXISTS (SELECT 1 FROM #apveacct WHERE NOT LTRIM(RTRIM(UPPER(ISNULL([db_name], '')))) = LTRIM(RTRIM(UPPER(ISNULL(DB_NAME(), '')))))
        --    BEGIN
        --    INSERT #ewerror
        --            SELECT @module_id, 10827, a.[db_name], '', 0, 0.0, 1, a.vchr_num, a.[line], '', 0
        --                    FROM #apveacct a
        --                    WHERE LTRIM(RTRIM(UPPER(ISNULL(a.[db_name], '')))) = LTRIM(RTRIM(UPPER(ISNULL(DB_NAME(), '')))) 
        --    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #ewerror 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        --    END

	--SCR 2304
	



















































































































































































































































































































































































































































                       









































CREATE TABLE #gltrx
(
	mark_flag			smallint NOT NULL,
	next_seq_id			int NOT NULL,
	trx_state			smallint NOT NULL,
	journal_type          		varchar(8) NOT NULL,
	journal_ctrl_num      		varchar(16) NOT NULL, 
	journal_description   		varchar(30) NOT NULL, 
	date_entered          		int NOT NULL,
	date_applied          		int NOT NULL,
	recurring_flag			smallint NOT NULL,
	repeating_flag			smallint NOT NULL,
	reversing_flag			smallint NOT NULL,
	hold_flag             		smallint NOT NULL,
	posted_flag           		smallint NOT NULL,
	date_posted           		int NOT NULL,
	source_batch_code		varchar(16) NOT NULL, 
	process_group_num		varchar(16) NOT NULL,
	batch_code             		varchar(16) NOT NULL, 
	type_flag			smallint NOT NULL,	
							
							
							
							
							
	intercompany_flag		smallint NOT NULL,	
	company_code			varchar(8) NOT NULL, 
	app_id				smallint NOT NULL,	


	home_cur_code		varchar(8) NOT NULL,		
	document_1		varchar(16) NOT NULL,	


	trx_type		smallint NOT NULL,		
	user_id			smallint NOT NULL,
	source_company_code	varchar(8) NOT NULL,
        oper_cur_code           varchar(8),         
	org_id			varchar(30) NULL,
	interbranch_flag	smallint
)

CREATE UNIQUE INDEX #gltrx_ind_0
	 ON #gltrx ( journal_ctrl_num )


	








































































































CREATE TABLE #gltrxdet
(
	mark_flag		smallint NOT NULL,
	trx_state		smallint NOT NULL,
        journal_ctrl_num	varchar(16) NOT NULL,
	sequence_id		int NOT NULL,
	rec_company_code	varchar(8) NOT NULL,	
	company_id		smallint NOT NULL,
        account_code		varchar(32) NOT NULL,	
	description		varchar(40) NOT NULL,
        document_1		varchar(16) NOT NULL, 	
        document_2		varchar(16) NOT NULL, 	
	reference_code		varchar(32) NOT NULL,	
        balance			float NOT NULL,		
	nat_balance		float NOT NULL,		
	nat_cur_code		varchar(8) NOT NULL,	
	rate			float NOT NULL,		
        posted_flag             smallint NOT NULL,
        date_posted		int NOT NULL,
	trx_type		smallint NOT NULL,
	offset_flag		smallint NOT NULL,	





	seg1_code		varchar(32) NOT NULL,
	seg2_code		varchar(32) NOT NULL,
	seg3_code		varchar(32) NOT NULL,
	seg4_code		varchar(32) NOT NULL,
	seq_ref_id		int NOT NULL,		
        balance_oper            float NULL,
        rate_oper               float NULL,
        rate_type_home          varchar(8) NULL,
	rate_type_oper          varchar(8) NULL,
	org_id			varchar(30) NULL
                                                
)

CREATE UNIQUE INDEX #gltrxdet_ind_0
	ON #gltrxdet ( journal_ctrl_num, sequence_id )

CREATE INDEX #gltrxdet_ind_1
	ON #gltrxdet ( journal_ctrl_num, account_code )

        EXEC @SP_Result = apvoval2_sp @process_ctrl_num,
                                      '', 
                                      @debug_level
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' apvoval2_sp 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
	DROP TABLE #gltrx
	DROP TABLE #gltrxdet	
        --
        -- apvoval2_sp currently only returns a 0 or a -3 and both of these values
        -- are acceptable as "not a stored procedure error". 
        --
        IF NOT @SP_Result = 0
                AND NOT @SP_Result = -3  
            BEGIN
            EXEC im_log_sp_error_sp @ILSE_Error_Code = @SP_Result,
                                    @ILSE_SP_Name = 'apvoval2_sp',
                                    @ILSE_String = '',
                                    @ILSE_Procedure_Name = @Routine_Name,
                                    @ILSE_Log_Activity = 'YES',
                                    @im_log_sp_error_sp_User_ID = @userid
            GOTO Error_Return
            END                                  
        --
        DROP TABLE #apvovchg
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DROPTABLE + ' #apvovchg 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        DROP TABLE #apvovcdt
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DROPTABLE + ' #apvovcdt 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        DROP TABLE #apvovage
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DROPTABLE + ' #apvovage 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        DROP TABLE #apvovtax
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DROPTABLE + ' #apvovtax 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
	DROP TABLE #apvovtaxdtl
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DROPTABLE + ' #apvovtaxdtl 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        DROP TABLE #apvovtmp
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DROPTABLE + ' #apvovtmp 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        --
        -- Ignore any 10580 errors by deleting them from the perror table.
        --
        DELETE
                FROM perror
                WHERE [err_code] = 10580
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DELETE + ' perror 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        --
        END
    IF @invoice_flag = 4092
        BEGIN
        SET @process_ctrl_num = ''
        EXEC @SP_Result = pctrladd_sp @process_ctrl_num OUTPUT,
                                      'Import Manager -- Debit Memo Validation', 
                                      @userid,
                                      @module_id, 
                                      @IMAPValidateVoucher_sp_company_code,
                                      @invoice_flag
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' pctrladd_sp' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        IF NOT @SP_Result = 0
            BEGIN
            EXEC im_log_sp_error_sp @ILSE_Error_Code = @SP_Result,
                                    @ILSE_SP_Name = 'pctrladd_sp',
                                    @ILSE_String = '',
                                    @ILSE_Procedure_Name = @Routine_Name,
                                    @ILSE_Log_Activity = 'YES',
                                    @im_log_sp_error_sp_User_ID = @userid
            GOTO Error_Return
            END     
        
CREATE TABLE #apdmvchg
(
	trx_ctrl_num		varchar(16),
    trx_type			smallint,
	doc_ctrl_num		varchar(16),
    apply_to_num		varchar(16),
	user_trx_type_code	varchar(8),
	batch_code			varchar(16),
	po_ctrl_num			varchar(16),
	vend_order_num		varchar(20),
	ticket_num			varchar(20),
	date_applied		int,
	date_doc			int,
	date_entered		int,
	posting_code		varchar(8),
    vendor_code			varchar(12),
    pay_to_code			varchar(8),
	branch_code			varchar(8),
	class_code			varchar(8),
	approval_code		varchar(8),
	comment_code		varchar(8),
	fob_code			varchar(8),
	terms_code			varchar(8),
	tax_code			varchar(8),
	location_code		varchar(8),
	posted_flag			smallint,
	hold_flag			smallint,
    amt_gross			float,
    amt_discount		float,
    amt_tax				float,
    amt_freight			float,
    amt_misc			float,
    amt_net				float,
	amt_restock			float,
	amt_tax_included	float,
	frt_calc_tax		float,
	doc_desc			varchar(40),
	hold_desc			varchar(40),
	user_id				smallint,
	next_serial_id		smallint,
	attention_name		varchar(40),
	attention_phone		varchar(30),
	intercompany_flag	smallint,
	company_code		varchar(8),
	cms_flag			smallint,
	nat_cur_code 		varchar(8),	 
	rate_type_home 		varchar(8),	 
	rate_type_oper		varchar(8),	 
	rate_home 			float,		   
	rate_oper			float,		   
	flag				smallint,
	payment_code		varchar(8), 			-- RDS Added fields
	amt_paid		float, 
	amt_due			float, 
	date_aging		int, 
	date_due		int, 
	date_received		int, 
	date_required		int, 
	date_recurring		int, 
	date_discount		int, 
	recurring_code		varchar(8), 
	times_accrued		smallint, 
	accrual_flag		smallint, 
	drop_ship_flag		smallint, 
	add_cost_flag		smallint, 
	approval_flag		smallint, 
	recurring_flag		smallint, 
	one_time_vend_flag	smallint, 
	one_check_flag		smallint, 
	pay_to_addr1		varchar(40), 
	pay_to_addr2		varchar(40), 
	pay_to_addr3		varchar(40), 
	pay_to_addr4		varchar(40), 
	pay_to_addr5		varchar(40), 
	pay_to_addr6		varchar(40),
	net_original_amt	float,
	org_id				varchar(30) NULL,
	interbranch_flag		integer NULL,
	temp_flag			integer NULL,
	tax_freight_no_recoverable	float
)

        
CREATE TABLE #apdmvcdt
(
	trx_ctrl_num		varchar(16),
	trx_type			smallint,
	sequence_id			int,
	location_code		varchar(8),
	item_code			varchar(30),
	bulk_flag			smallint,
	qty_ordered			float,
	qty_returned		float,
	qty_prev_returned	float,
	approval_code		varchar(8),
	tax_code			varchar(8),
	return_code			varchar(8),
	unit_code			varchar(8),
	unit_price			float,
	amt_discount		float,
	amt_freight 		float,
	amt_tax     		float,
	amt_misc    		float,
	amt_extended		float,
	calc_tax			float,
	date_entered		int,
	gl_exp_acct			varchar(32),
	rma_num				varchar(20),
	line_desc			varchar(60),
	serial_id			int,
	company_id			smallint,
	iv_post_flag		smallint,
	po_orig_flag		smallint,
	rec_company_code	varchar(8),
	reference_code		varchar(32),
	flag				smallint
	,org_id             varchar(30) NULL
	,temp_flag			integer NULL,
	amt_nonrecoverable_tax	float
)


	

        
CREATE TABLE #apdmvtax
(
	trx_ctrl_num			varchar(16),
	trx_type			smallint,
	sequence_id			int,
	tax_type_code			varchar(8),
	amt_taxable			float,
	amt_gross			float,
	amt_tax				float,
	amt_final_tax			float
)


	










CREATE TABLE #apdmvtaxdtl
(
	trx_ctrl_num		varchar(16),
	sequence_id		integer,
	trx_type		integer,
	tax_sequence_id		integer,
	detail_sequence_id	integer,
	tax_type_code		varchar(8),
	amt_taxable		float,
	amt_gross		float,
	amt_tax			float,
	amt_final_tax		float,
	recoverable_flag	integer,
	account_code		varchar(32)
)


        INSERT INTO #apdmvchg (trx_ctrl_num,    trx_type,           doc_ctrl_num, 
                               apply_to_num,    user_trx_type_code, batch_code, 
                               po_ctrl_num,     vend_order_num,     ticket_num, 
                               date_applied,    date_doc,           date_entered, 
                               posting_code,    vendor_code,        pay_to_code, 
                               branch_code,     class_code,         approval_code, 
                               comment_code,    fob_code,           terms_code, 
                               tax_code,        location_code,      posted_flag, 
                               hold_flag,       amt_gross,          amt_discount, 
                               amt_tax,         amt_freight,        amt_misc, 
                               amt_net,         amt_restock,        amt_tax_included, 
                               frt_calc_tax,    doc_desc,           hold_desc, 
                               user_id,         next_serial_id,     attention_name, 
                               attention_phone, intercompany_flag,  company_code, 
                               cms_flag,        nat_cur_code,       rate_type_home, 
                               rate_type_oper,  rate_home,          rate_oper, 
                               flag,            payment_code,       amt_paid, 
                               amt_due,         date_aging,         date_due, 
                               date_received,   date_required,      date_recurring, 
                               date_discount,   recurring_code,     times_accrued, 
                               accrual_flag,    drop_ship_flag,     add_cost_flag, 
                               approval_flag,   recurring_flag,     one_time_vend_flag, 
                               one_check_flag,  pay_to_addr1,       pay_to_addr2, 
                               pay_to_addr3,    pay_to_addr4,       pay_to_addr5, 
                               pay_to_addr6,	org_id,		    interbranch_flag,
			       temp_flag,	tax_freight_no_recoverable) 
                SELECT trx_ctrl_num,    trx_type,           doc_ctrl_num, 
                       apply_to_num,    user_trx_type_code, batch_code, 
                       po_ctrl_num,     vend_order_num,     ticket_num, 
                       date_applied,    date_doc,           date_entered, 
                       posting_code,    vendor_code,        pay_to_code, 
                       branch_code,     class_code,         approval_code, 
                       comment_code,    fob_code,           terms_code, 
                       tax_code,        location_code,      posted_flag, 
                       hold_flag,       amt_gross,          amt_discount, 
                       amt_tax,         amt_freight,        amt_misc, 
                       amt_net,         amt_restock,        amt_tax_included, 
                       frt_calc_tax,    doc_desc,           hold_desc, 
                       user_id,         next_serial_id,     attention_name, 
                       attention_phone, intercompany_flag,  company_code, 
                       cms_flag,        nat_cur_code,       rate_type_home, 
                       rate_type_oper,  rate_home,          rate_oper, 
                       0,               payment_code,       amt_paid, 
                       amt_due,         date_aging,         date_due, 
                       date_received,   date_required,      date_recurring, 
                       date_discount,   recurring_code,     times_accrued, 
                       accrual_flag,    drop_ship_flag,     add_cost_flag, 
                       approval_flag,   recurring_flag,     one_time_vend_flag, 
                       one_check_flag,  pay_to_addr1,       pay_to_addr2, 
                       pay_to_addr3,    pay_to_addr4,       pay_to_addr5, 
                       pay_to_addr6,	org_id,		    0,
		       0,	tax_freight_no_recoverable
                    FROM #apinpchg
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #apdmvchg 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        INSERT INTO #apdmvcdt (trx_ctrl_num,  trx_type,         sequence_id, 
                               location_code, item_code,        bulk_flag, 
                               qty_ordered,   qty_returned,     qty_prev_returned, 
                               approval_code, tax_code,         return_code, 
                               unit_code,     unit_price,       amt_discount, 
                               amt_freight,   amt_tax,          amt_misc, 
                               amt_extended,  calc_tax,         date_entered, 
                               gl_exp_acct,   rma_num,          line_desc, 
                               serial_id,     company_id,       iv_post_flag, 
                               po_orig_flag,  rec_company_code, reference_code, 
                               flag,	      org_id,          	temp_flag,
			       amt_nonrecoverable_tax) 
                SELECT trx_ctrl_num,  trx_type,         sequence_id, 
                       location_code, item_code,        bulk_flag, 
                       qty_ordered,   qty_returned,     qty_prev_returned, 
                       approval_code, tax_code,         return_code, 
                       unit_code,     unit_price,       amt_discount, 
                       amt_freight,   amt_tax,          amt_misc, 
                       amt_extended,  calc_tax,         date_entered, 
                       gl_exp_acct,   rma_num,          line_desc, 
                       serial_id,     company_id,       iv_post_flag, 
                       po_orig_flag,  rec_company_code, reference_code, 
                       0,	      org_id,          	0,
		       amt_nonrecoverable_tax 
                        FROM #apinpcdt
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #apdmvcdt 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        INSERT INTO #apdmvtax (trx_ctrl_num,  trx_type,      sequence_id,
                               tax_type_code, amt_taxable,   amt_gross,
                               amt_tax,       amt_final_tax)
                SELECT trx_ctrl_num,  trx_type,      sequence_id,
                       tax_type_code, amt_taxable,   amt_gross,
                       amt_tax,       amt_final_tax
                        FROM #apinptax
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #apdmvtax 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

        INSERT INTO #apdmvtaxdtl (	trx_ctrl_num,		sequence_id,		trx_type,
					tax_sequence_id,	detail_sequence_id,	tax_type_code,
					amt_taxable,		amt_gross,		amt_tax,
					amt_final_tax,		recoverable_flag,	account_code)
                SELECT 			trx_ctrl_num,		sequence_id,		trx_type,
					tax_sequence_id,	detail_sequence_id,	tax_type_code,
					amt_taxable,		amt_gross,		amt_tax,
					amt_final_tax,		recoverable_flag,	account_code
                 FROM #apinptaxdtl

	SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #apdmvtaxdtl 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
       
        EXEC @SP_Result = apdbmedt_sp @im_config_Validate_Errors_Only, 
                                      @debug_level
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' apdbmedt_sp 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        --
        -- apdbmedt_sp currently only returns a 0, but this check is just good practice.
        --
        IF NOT @SP_Result = 0
            BEGIN
            EXEC im_log_sp_error_sp @ILSE_Error_Code = @SP_Result,
                                    @ILSE_SP_Name = 'apdbmedt_sp',
                                    @ILSE_String = '',
                                    @ILSE_Procedure_Name = @Routine_Name,
                                    @ILSE_Log_Activity = 'YES',
                                    @im_log_sp_error_sp_User_ID = @userid
            GOTO Error_Return
            END                          
        --IF EXISTS (SELECT 1 FROM #apveacct WHERE NOT LTRIM(RTRIM(UPPER(ISNULL([db_name], '')))) = LTRIM(RTRIM(UPPER(ISNULL(DB_NAME(), '')))))
        --    BEGIN
        --    INSERT #ewerror
        --            SELECT @module_id, 10827, a.[db_name], '', 0, 0.0, 1, a.vchr_num, a.[line], '', 0
        --                    FROM #apveacct a
        --                    WHERE LTRIM(RTRIM(UPPER(ISNULL(a.[db_name], '')))) = LTRIM(RTRIM(UPPER(ISNULL(DB_NAME(), '')))) 
        --    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #ewerror 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        --    END
        EXEC @SP_Result = apdmval2_sp @process_ctrl_num,
                                      '', 
                                      @debug_level
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' apdmval2_sp 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        --
        -- apdmval2_sp currently only returns a 0 or a -3 and both of these values
        -- are acceptable as "not a stored procedure error". 
        --
        IF NOT @SP_Result = 0
                AND NOT @SP_Result = -3
            BEGIN
            EXEC im_log_sp_error_sp @ILSE_Error_Code = @SP_Result,
                                    @ILSE_SP_Name = 'apdmval2_sp',
                                    @ILSE_String = '',
                                    @ILSE_Procedure_Name = @Routine_Name,
                                    @ILSE_Log_Activity = 'YES'
            GOTO Error_Return
            END                                  
        --
        DROP TABLE #apdmvchg
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DROPTABLE + ' #apdmvchg 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        DROP TABLE #apdmvcdt
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DROPTABLE + ' #apdmvcdt 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        DROP TABLE #apdmvtax
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DROPTABLE + ' #apdmvtax 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        DROP TABLE #apdmvtaxdtl
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DROPTABLE + ' #apdmvtaxdtl 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

        END
    DROP TABLE #apveacct
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DROPTABLE + ' #apveacct 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Validate imaphdr.user_trx_type_code.
    --
    INSERT INTO perror 
            ([process_ctrl_num], [batch_code],  [module_id], 
             [err_code],         [info1],       [info2],
             [infoint],          [infofloat],   [flag1],
             [trx_ctrl_num],     [sequence_id], [source_ctrl_num],
             [extra]) 
            SELECT @process_ctrl_num,                   '', @module_id, 
                   90943, '', '',
                   0,                                   0,  0,
                   [trx_ctrl_num],                      0,  [ticket_num],
                   0
                    FROM [#apinpchg]
                    WHERE [trx_type] = 4091
                            AND NOT [user_trx_type_code] IN (SELECT [user_trx_type_code] FROM [apusrtyp] WHERE [system_trx_type] = 4091)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' perror 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    INSERT INTO perror 
            ([process_ctrl_num], [batch_code],  [module_id], 
             [err_code],         [info1],       [info2],
             [infoint],          [infofloat],   [flag1],
             [trx_ctrl_num],     [sequence_id], [source_ctrl_num],
             [extra]) 
            SELECT @process_ctrl_num,                   '', @module_id, 
                   90943, '', '',
                   0,                                   0,  0,
                   [trx_ctrl_num],                      0,  [ticket_num],
                   0
                    FROM [#apinpchg]
                    WHERE [trx_type] = 4092
                            AND NOT [user_trx_type_code] IN (SELECT [user_trx_type_code] FROM [apusrtyp] WHERE [system_trx_type] = 4092)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' perror 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Validate imapdtl.gl_exp_acct for single-company vouchers.
    --
    INSERT INTO perror 
            ([process_ctrl_num], [batch_code],  [module_id], 
             [err_code],         [info1],       [info2],
             [infoint],          [infofloat],   [flag1],
             [trx_ctrl_num],     [sequence_id], [source_ctrl_num],
             [extra]) 
            SELECT @process_ctrl_num,              '',              @module_id, 
                   90940,   '',              '',
                   0,                              0,               0,
                   a.[trx_ctrl_num],               b.[sequence_id], a.[ticket_num],
                   0
                    FROM [#apinpchg] a 
                    INNER JOIN [#apinpcdt] b
                            ON a.[trx_ctrl_num] = b.[trx_ctrl_num]
                    WHERE a.[trx_type] IN (4091, 4092)
                            AND NOT b.[gl_exp_acct] IN (SELECT [account_code] FROM [glchart] WHERE [inactive_flag] = 0)
                            AND (NOT a.[intercompany_flag] = 1 OR a.[intercompany_flag] IS NULL)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' perror 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- The default for Additional Intercompany Validation is 'Yes", but some customers
    -- might not have AP or GL set up in the receiving companies.  In that case, they can
    -- set the configuration tag to bypass the additional validation.
    --
    SET @Additional_Intercompany_Validation = 'YES'
    IF EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'im_config')
        BEGIN
        SELECT @Additional_Intercompany_Validation = UPPER([Text Value])
                FROM [im_config] 
                WHERE UPPER([Item Name]) = 'ADDITIONAL INTERCOMPANY VALIDATION'
        IF @@ROWCOUNT = 0
                OR @Additional_Intercompany_Validation IS NULL
                OR (NOT @Additional_Intercompany_Validation = 'NO' AND NOT @Additional_Intercompany_Validation = 'YES' AND NOT @Additional_Intercompany_Validation = 'TRUE' AND NOT @Additional_Intercompany_Validation = 'FALSE')
            SET @Additional_Intercompany_Validation = 'YES'
        IF @Additional_Intercompany_Validation = 'FALSE'
            SET @Additional_Intercompany_Validation = 'NO'
        END
    IF @Additional_Intercompany_Validation = 'YES'
        BEGIN
        --
        -- Validate imapdtl.gl_exp_acct for inter-company vouchers.
        --
        DECLARE [Database_Names] CURSOR FOR
                SELECT DISTINCT d.[rec_company_code],
                                e.[db_name]
                        FROM [#apinpchg] h
                        INNER JOIN [#apinpcdt] d
                                ON h.[trx_ctrl_num] = d.[trx_ctrl_num]
                        INNER JOIN [CVO_Control]..[ewcomp] e
                                ON d.[rec_company_code] = e.[company_code]
                        WHERE h.[intercompany_flag] = 1
                                AND NOT d.[rec_company_code] = @IMAPValidateVoucher_sp_company_code
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DECLARE + ' Database_Names 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        SET @Database_Names_Cursor_Allocated = 'YES'
        OPEN [Database_Names]
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_OPEN + ' Database_Names 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        SET @Database_Names_Cursor_Opened = 'YES'
        FETCH NEXT 
                FROM Database_Names
                INTO @Database_Names_company_code, 
                     @Database_Names_db_name
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_FETCHNEXT + ' Database_Names 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        WHILE NOT @@FETCH_STATUS = -1
            BEGIN
            SET @SQL = 'IF EXISTS (SELECT TABLE_NAME FROM [' + @Database_Names_db_name + '].INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = ''glchart'')'
                        + ' INSERT'
                                + ' INTO perror ([process_ctrl_num], [batch_code],  [module_id],'
                                +              ' [err_code],         [info1],       [info2],'
                                +              ' [infoint],          [infofloat],   [flag1],'
                                +              ' [trx_ctrl_num],     [sequence_id], [source_ctrl_num],'
                                +              ' [extra])'
                                + ' SELECT ''' + @process_ctrl_num + ''',  '''', ' + CAST(@module_id AS VARCHAR) + ' ,'
                                +        CAST(90940 AS VARCHAR) + ', '''',            '''','
                                +        ' 0,                                               0,               0,'
                                +        ' a.[trx_ctrl_num],                                b.[sequence_id], a.[ticket_num],'
                                +        ' 0'
                                +         ' FROM [#apinpchg] a'
                                +         ' INNER JOIN [#apinpcdt] b'
                                +                 ' ON a.[trx_ctrl_num] = b.[trx_ctrl_num]'
                                +         ' WHERE a.[trx_type] IN (4091, 4092)'
                                +                 ' AND a.[intercompany_flag] = 1'
                                +                 ' AND NOT b.[gl_exp_acct] IN (SELECT DISTINCT [account_code] FROM [' + @Database_Names_db_name + ']..[glchart] WHERE NOT [account_code] IS NULL)'
                                +                 ' AND b.[rec_company_code] = ''' + @Database_Names_company_code + ''''
            EXEC (@SQL)
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' @SQL 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            FETCH NEXT 
                    FROM [Database_Names]
                    INTO @Database_Names_company_code, 
                         @Database_Names_db_name
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_FETCHNEXT + ' Database_Names 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            END    
        CLOSE [Database_Names]
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CLOSE + ' Database_Names 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        SET @Database_Names_Cursor_Opened = 'NO'
        DEALLOCATE [Database_Names]
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DEALLOCATE + ' Database_Names_Cursor 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        SET @Database_Names_Cursor_Allocated = 'NO'
        END
    --
    -- Validate imapdtl.tax_code for single-company vouchers.
    --
    INSERT INTO perror 
            ([process_ctrl_num], [batch_code],  [module_id], 
             [err_code],         [info1],       [info2],
             [infoint],          [infofloat],   [flag1],
             [trx_ctrl_num],     [sequence_id], [source_ctrl_num],
             [extra]) 
            SELECT @process_ctrl_num,              '',              @module_id, 
                   90941,      '',              '',
                   0,                              0,               0,
                   a.[trx_ctrl_num],               0,               a.[ticket_num],
                   0
                    FROM [#apinpchg] a INNER JOIN [#apinpcdt] b
                            ON a.[trx_ctrl_num] = b.[trx_ctrl_num]
                    WHERE a.[trx_type] IN (4091, 4092)
                            AND NOT b.tax_code IN (SELECT [tax_code] FROM [aptax])
                            AND (NOT a.[intercompany_flag] = 1 OR a.[intercompany_flag] IS NULL)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' perror 4' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    IF @Additional_Intercompany_Validation = 'YES'
        BEGIN    
        --
        -- Validate imapdtl.tax_code for inter-company vouchers.  The initial "IF EXISTS"
        -- in the large INSERT statment is used to determine if the receiving company
        -- has Accounts Payable installed.  If not, then the tax_code validation will be skipped.
        --
        DECLARE [Database_Names] CURSOR FOR
                SELECT DISTINCT d.[rec_company_code],
                                e.[db_name]
                        FROM [#apinpchg] h
                        INNER JOIN [#apinpcdt] d
                                ON h.[trx_ctrl_num] = d.[trx_ctrl_num]
                        INNER JOIN [CVO_Control]..[ewcomp] e
                                ON d.[rec_company_code] = e.[company_code]
                        WHERE h.[intercompany_flag] = 1
                                AND NOT d.[rec_company_code] = @IMAPValidateVoucher_sp_company_code
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DECLARE + ' Database_Names 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        SET @Database_Names_Cursor_Allocated = 'YES'
        OPEN [Database_Names]
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_OPEN + ' Database_Names 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        SET @Database_Names_Cursor_Opened = 'YES'
        FETCH NEXT 
                FROM Database_Names
                INTO @Database_Names_company_code, 
                     @Database_Names_db_name
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_FETCHNEXT + ' Database_Names 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        WHILE NOT @@FETCH_STATUS = -1
            BEGIN
            SET @SQL = 'IF EXISTS (SELECT TABLE_NAME FROM [' + @Database_Names_db_name + '].INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = ''aptax'')'
                        + ' INSERT'
                           +      ' INTO perror ([process_ctrl_num], [batch_code],  [module_id],'
                           +                   ' [err_code],         [info1],       [info2],'
                           +                   ' [infoint],          [infofloat],   [flag1],'
                           +                   ' [trx_ctrl_num],     [sequence_id], [source_ctrl_num],'
                           +                   ' [extra])'
                           +      ' SELECT ''' + @process_ctrl_num + ''', '''', ' + CAST(@module_id AS VARCHAR) + ' ,'
                           +             CAST(90941 AS VARCHAR) + ',   '''', '''','
                           +             ' 0,                             0,    0,'
                           +             ' a.[trx_ctrl_num],              0,    a.[ticket_num],'
                           +             ' 0'
                           +              ' FROM [#apinpchg] a'
                           +              ' INNER JOIN [#apinpcdt] b'
                           +                      ' ON a.[trx_ctrl_num] = b.[trx_ctrl_num]'
                           +              ' WHERE a.[trx_type] IN (4091, 4092)'
                           +                      ' AND a.[intercompany_flag] = 1'
                           +                      ' AND NOT b.[tax_code] IN (SELECT DISTINCT [tax_code] FROM [aptax] WHERE NOT [tax_code] IS NULL)'
                           +                      ' AND b.[rec_company_code] = ''' + @Database_Names_company_code + ''''
            EXEC (@SQL)
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' @SQL 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            FETCH NEXT 
                    FROM [Database_Names]
                    INTO @Database_Names_company_code, 
                         @Database_Names_db_name
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_FETCHNEXT + ' Database_Names 4' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            END    
        CLOSE [Database_Names]
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CLOSE + ' Database_Names 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        SET @Database_Names_Cursor_Opened = 'NO'
        DEALLOCATE [Database_Names]
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DEALLOCATE + ' Database_Names_Cursor 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        SET @Database_Names_Cursor_Allocated = 'NO'
        END
    --
    -- Mark the process as complete.
    --
    EXEC @SP_Result = pctrlupd_sp @process_ctrl_num,
                                  3
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' pctrlupd_sp' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    IF NOT @SP_Result = 0
        BEGIN
        EXEC im_log_sp_error_sp @ILSE_Error_Code = @SP_Result,
                                @ILSE_SP_Name = 'pctrlupd_sp',
                                @ILSE_String = '',
                                @ILSE_Procedure_Name = @Routine_Name,
                                @ILSE_Log_Activity = 'YES',
                                @im_log_sp_error_sp_User_ID = @userid
        GOTO Error_Return
        END 
    SET @pcn = @process_ctrl_num
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': Exit.'
    RETURN 0
    --
Error_Return:
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': Exit (ERROR).'
    RETURN -1    
GO
GRANT EXECUTE ON  [dbo].[IMAPValidateVoucher_sp] TO [public]
GO
