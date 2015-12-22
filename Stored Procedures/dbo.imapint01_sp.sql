SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


    CREATE PROC 
[dbo].[imapint01_sp] @method_flag SMALLINT, 
             @post_flag SMALLINT,
             @invoice_flag SMALLINT, 
             @close_batch_flag SMALLINT,
             @db_userid VARCHAR(40) = 'ABSENT',  
             @db_password VARCHAR(40) = '', 
             @debug_level INT,
             @perf_level SMALLINT,
             @userid INT = 0,
             @imapint01_sp_process_ctrl_num_Validation VARCHAR(16) = '' OUTPUT,
             @imapint01_sp_process_ctrl_num_Posting VARCHAR(16) = '' OUTPUT,
             @imapint01_sp_Import_Identifier INT = 0 OUTPUT,
             @imapint01_sp_Application_Name VARCHAR(30) = 'Import Manager',
             @imapint01_sp_Override_User_Name VARCHAR(30) = '',
             @imapint01_sp_TPS_int_value INT = NULL 
    AS      
    DECLARE @date_applied INT,
            @hold_flag SMALLINT,
            @hold_desc VARCHAR(40),
            @last_sequence_id SMALLINT,
            @unit_price FLOAT,
            @gl_exp_acct VARCHAR(32),
            @return_code VARCHAR(8),
            @sequence_id                int,
            @location_code VARCHAR(8),  
            @item_code VARCHAR(18), 
            @vendor_code VARCHAR(12), 
            @vend_branch_code CHAR(8),
            @vendor_name VARCHAR(40),
            @pay_to_code VARCHAR(8),
            @pay_to_name VARCHAR(40),
            @addr1 VARCHAR(40),
            @addr2 VARCHAR(40), 
            @addr3 VARCHAR(40),
            @addr4 VARCHAR(40), 
            @addr5 VARCHAR(40),
            @addr6 VARCHAR(40),
            @attention_phone VARCHAR(40),
            @vend_phone VARCHAR(30), 
            @vend_po_num VARCHAR(25),
            @date_doc                int, 
            @date_due                int, 
            @date_aging                int,        
            @date_requested                int,
            @date_received                int,
            @date_required                int,
            @date_discount                int,
            @date_entered                 int,
            @detail_date_entered INT,
            @date_recurring               int,
            @tax_code VARCHAR(8),
            @vend_tax_code VARCHAR(8),  
            @terms_code VARCHAR(8),
            @vend_terms_code VARCHAR(8),  
            @fob_code VARCHAR(8),
            @posting_code VARCHAR(8),
            @vend_posting_code VARCHAR(8),
            @vend_contact_phone VARCHAR(30),
            @payment_code VARCHAR(8),
            @vend_payment_code VARCHAR(8),
            @vend_territory_code VARCHAR(8),
            @ticket_num VARCHAR(20),
            @code_1099 VARCHAR(8),
            @branch_code VARCHAR(8),
            @class_code VARCHAR(8),
            @approval_code VARCHAR(8),
            @vend_order_num VARCHAR(20),
            @attention_name VARCHAR(40),
            @trx_ctrl_num VARCHAR(16),
            @qty_received FLOAT,
            @error_flag SMALLINT,    
            @apply_date                int, 
            @line_freight FLOAT,       
            @doc_desc VARCHAR(40),  
            @comment_code VARCHAR(8),
            @vend_comment_code VARCHAR(8),
            @unit_code VARCHAR(8),  
            @outer_order_num VARCHAR(16),
            @amt_gross FLOAT,
            @amt_extended FLOAT,
            @amt_misc FLOAT,     
            @amt_freight FLOAT,       
            @amt_tax FLOAT, 
            @amt_net FLOAT, 
            @amt_paid FLOAT,       
            @amt_due FLOAT,
            @amt_profit FLOAT,
            @amt_tax_included FLOAT,
            @frt_calc_tax FLOAT,
            @calc_tax FLOAT,
            @trx_type SMALLINT,    
            @tax_type_code     CHAR(8),
            @amt_taxable FLOAT,
            @amt_final_tax FLOAT,
            @result SMALLINT,
            @precision_gl SMALLINT,
            @iv_orig_flag SMALLINT,
            @times_accrued SMALLINT,
            @accrual_flag SMALLINT,
            @drop_ship_flag SMALLINT,
            @add_cost_flag SMALLINT,
            @approval_flag SMALLINT,
            @one_time_vend_flag SMALLINT,
            @one_check_flag SMALLINT,
            @rec_company_code VARCHAR(8),
            @new_company_code VARCHAR(8),
            @reference_code VARCHAR(32),
            @new_reference_code VARCHAR(32),
            @intercompany_flag SMALLINT,
            @company_code VARCHAR(8),
            @cms_flag SMALLINT,
            @vend_location_code VARCHAR(8),
            @one_time_vend_code CHAR(8),
            @default_exp_flag SMALLINT,
            @po_orig_flag SMALLINT,
            @company_id SMALLINT,
            @module_id SMALLINT,
            @val_mode SMALLINT,
            @doc_ctrl_num VARCHAR(16),
            @apply_to_num VARCHAR(16),
            @apply_trx_type SMALLINT,
            @user_trx_type_code VARCHAR(8),
            @batch_code VARCHAR(16),
            @recurring_flag SMALLINT,
            @recurring_code VARCHAR(8),
            @next_serial_id SMALLINT,
            @printed_flag SMALLINT,
            @posted_flag SMALLINT,
            @amt_restock FLOAT,     
            @process_group_num VARCHAR(16), 
            @interface_mode SMALLINT,
            @bulk_flag SMALLINT,
            @rma_num VARCHAR(16),
            @line_desc VARCHAR(60),
            @qty_ordered FLOAT, 
            @amt_gmd FLOAT, 
            @qty_returned FLOAT,  
            @qty_prev_returned FLOAT,
            @unit_cost FLOAT,
            @new_gl_exp_acct VARCHAR(32),
            @iv_post_flag SMALLINT,  
            @oe_orig_flag SMALLINT,
            @po_ctrl_num VARCHAR(16),
            @serial_id int,
            @source_trx_ctrl_num CHAR(16),
            @dump CHAR(16),
            @apactvnd_flag int,
            @apactpto_flag int,
            @apactcls_flag int,
            @apactbch_flag int,
            @process_ctrl_num CHAR(16),
            @process_ctrl_num_Posting CHAR(16),
            @spid int,
            @aprv_voucher_flag SMALLINT,
            @default_aprv_code CHAR(8),
            @nat_cur_code VARCHAR(8),
            @rate_type_home VARCHAR(8),
            @rate_type_oper VARCHAR(8), 
            @rate_home FLOAT,
            @rate_oper FLOAT,
            @default_tax_type SMALLINT,
            @default_tax_code VARCHAR(8),
            @tax_code_vendor VARCHAR(12),
            @tax_code_item VARCHAR(8),
            @validation_flag SMALLINT,
            @process_description VARCHAR(40), 
            @process_parent_app SMALLINT, 
            @process_parent_company varCHAR(8),
            @rowcount                int,
            @buf CHAR(255),
            @chDateApplied CHAR(10),
            @chDateDoc CHAR(10),
            @chDateDue CHAR(10),
            @chDateAging CHAR(10),
            @chDateReceived CHAR(10),
            @chDateRequired CHAR(10),
            @chDateDiscount CHAR(10)
    DECLARE @date_applied_error CHAR(255)
    DECLARE @date_aging_error CHAR(255)
    DECLARE @date_due_error CHAR(255)
    DECLARE @date_doc_error CHAR(255)
    DECLARE @date_received_error CHAR(255)
    DECLARE @date_required_error CHAR(255)
    DECLARE @date_discount_error CHAR(255)
    DECLARE @imapdtl_vw_amt_discount FLOAT       
    DECLARE @imapdtl_vw_amt_freight FLOAT
    DECLARE @imapdtl_vw_amt_misc FLOAT
    DECLARE @imapdtl_vw_bulk_flag SMALLINT
    DECLARE @imapdtl_vw_calc_tax FLOAT
    DECLARE @imapdtl_vw_code_1099 VARCHAR(8)
    DECLARE @imapdtl_vw_date_entered CHAR(10)
    DECLARE @imapdtl_vw_location_code VARCHAR(8)
    DECLARE @imapdtl_vw_new_gl_exp_acct VARCHAR(32)
    DECLARE @imapdtl_vw_new_reference_code VARCHAR(32)
    DECLARE @imapdtl_vw_po_orig_flag SMALLINT  
    DECLARE @imapdtl_vw_qty_prev_returned FLOAT  
    DECLARE @imapdtl_vw_rma_num VARCHAR(16)  
    DECLARE @imaphdr_vw_add_cost_flag SMALLINT
    DECLARE @imaphdr_vw_attention_name VARCHAR(40)
    DECLARE @imaphdr_vw_attention_phone VARCHAR(40)
    DECLARE @imaphdr_vw_amt_freight FLOAT
    DECLARE @imaphdr_vw_amt_misc FLOAT
    DECLARE @imaphdr_vw_amt_paid FLOAT
    DECLARE @imaphdr_vw_amt_restock FLOAT
    DECLARE @imaphdr_vw_amt_tax_included FLOAT
    DECLARE @imaphdr_vw_class_code VARCHAR(8)
    DECLARE @imaphdr_vw_cms_flag SMALLINT
    DECLARE @imaphdr_vw_date_entered CHAR(10)
    DECLARE @imaphdr_vw_date_recurring CHAR(10)
    DECLARE @imaphdr_vw_drop_ship_flag SMALLINT
    DECLARE @imaphdr_vw_fob_code VARCHAR(8)
    DECLARE @imaphdr_vw_frt_calc_tax FLOAT
    DECLARE @imaphdr_vw_location_code VARCHAR(8)
    DECLARE @imaphdr_vw_one_check_flag SMALLINT
    DECLARE @imaphdr_vw_recurring_code VARCHAR(8)
    DECLARE @imaphdr_vw_recurring_flag SMALLINT
    DECLARE @imaphdr_vw_times_accrued SMALLINT
    DECLARE @imaphdr_vw_user_trx_type_code VARCHAR(8)
    DECLARE @imaphdr_vw_vend_order_num VARCHAR(20)
    DECLARE @Monotonic_source_trx_ctrl_num VARCHAR(16)
    DECLARE @Monotonic_Previous_source_trx_ctrl_num VARCHAR(16)
    DECLARE @Monotonic_sequence_id INT
    DECLARE @Monotonic_Computed_sequence_id INT
    DECLARE @Monotonic_Cursor_Allocated VARCHAR(3)
    DECLARE @Monotonic_Cursor_Opened VARCHAR(3)
    DECLARE @User_Name VARCHAR(30)
    DECLARE @hdr_org_id VARCHAR(30)    
    DECLARE @det_org_id VARCHAR(30)           		     
    DECLARE @tax_freight_no_recoverable float
    DECLARE @amt_nonrecoverable_tax float
    DECLARE @amt_tax_det float


    
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
    
    IF @debug_level > 1
        BEGIN
        SELECT 'Import Manager 7.3 Service Pack 1'
        END

    DELETE imlog WHERE UPPER(module) = 'APVOUCHER' AND ([User_ID] = @userid OR @userid = 0)
    IF @method_flag = 2
        BEGIN
        INSERT INTO imlog VALUES (getdate(), 'APVOUCHER', 1, '', '', '', 'Accounts Payable Vouchers/Debit Memos -- Begin (Copy) -- 7.3', @userid)
        END
    ELSE
        BEGIN
        INSERT INTO imlog VALUES (getdate(), 'APVOUCHER', 1, '', '', '', 'Accounts Payable Vouchers/Debit Memos -- Begin (Validate) -- 7.3', @userid)
        END
    SET @Routine_Name = 'imapint01_sp'
    SET @Error_Table_Name = 'imvdmerr_vw'
    
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
    

    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': Entry.'
    
    --
    -- Standard_Process_1
    --
    -- Update and retrieve the current timestamp value from the control database.  
    -- Perform the update to insure that the timestamp value is unique.  An IF EXISTS
    -- with an INSERT is used here rather than having the table initially populated
    -- with a DAT file to avoid problems with the record possibly being deleted
    -- after the initial DBUPDATE.
    --
    IF EXISTS(SELECT 1 FROM [CVO_Control]..[im_DBTS])
        UPDATE [CVO_Control]..[im_DBTS]
                SET [Blank] = ''
    ELSE
        INSERT INTO [CVO_Control]..[im_DBTS]
                VALUES (NULL, '')
    SELECT @Import_Identifier = CAST([DBTS] AS INT)
        FROM [CVO_Control]..[im_DBTS]
    --
    -- Verify that @debug_level is within range.
    --
    IF @debug_level < 0
            OR @debug_level > 10
        BEGIN
        EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = 'Invalid @debug_level -- part 1',
                                                     @IGES_String = @External_String_1 OUT 
        EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = 'Invalid @debug_level -- part 2',
                                                     @IGES_String = @External_String_2 OUT 
        INSERT INTO [imlog] ([now], [text])
                VALUES (GETDATE(), @External_String_1 + '''' + @Routine_Name + '''' + @External_String_2)
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' @debug_level check' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END  
        SET @debug_level = 3      
        END   
    --
    -- Setting to 0 if NULL will prevent other "equal to 0" tests from thinking that @userid
    -- was set to non-zero.
    --
    IF @userid IS NULL
        SET @userid = 0
    --

    
    --
    -- Standard_Process_2
    --
    -- Get and set DATEFORMAT if specified in the config table.
    --
    SET @im_config_DATEFORMAT = 'mdy'
    SELECT @im_config_DATEFORMAT = LOWER(ISNULL([Text Value], 'mdy'))
            FROM [im_config]
            WHERE LTRIM(RTRIM(UPPER(ISNULL([Item Name], '')))) = 'DATEFORMAT'
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' DATEFORMAT' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': DATEFORMAT = ''' + @im_config_DATEFORMAT + ''''
    IF NOT @im_config_DATEFORMAT = 'mdy'
            AND NOT @im_config_DATEFORMAT = 'ymd'
            AND NOT @im_config_DATEFORMAT = 'dmy'
        BEGIN
        SET @im_config_DATEFORMAT = 'mdy'
        IF @debug_level >= 3
            SELECT '(3): ' + @Routine_Name + ': DATEFORMAT = ''' + @im_config_DATEFORMAT + ''''
        END
    SET @January_First_Nineteen_Eighty = '1/1/80'
    SET DATEFORMAT mdy
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SET + ' DATEFORMAT 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    IF @im_config_DATEFORMAT = 'dmy'
        BEGIN
        SET @January_First_Nineteen_Eighty = '1/1/80'
        SET DATEFORMAT dmy
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SET + ' DATEFORMAT 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        END
    IF @im_config_DATEFORMAT = 'ymd'
        BEGIN
        SET @January_First_Nineteen_Eighty = '80/1/1'
        SET DATEFORMAT ymd
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SET + ' DATEFORMAT 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        END
    --

    SET @Monotonic_Cursor_Allocated = 'NO'        
    SET @Monotonic_Cursor_Opened = 'NO'
    IF @imapint01_sp_Import_Identifier = 0
            OR @imapint01_sp_Import_Identifier IS NULL
        BEGIN
        SET @imapint01_sp_Import_Identifier = @Import_Identifier
        --
        -- Purge records from the im# reporting tables.
        --
        EXEC @SP_Result = [CVO_Control]..imreportdata_clear_sp @imreportdata_clear_sp_T1 = 'im#imaphdr',
                                                            @imreportdata_clear_sp_T2 = 'im#imapdtl',
                                                            @debug_level = @debug_level,
                                                            @userid = @userid
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' [CVO_Control]..imreportdata_clear_sp 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END                                                    
        IF NOT @SP_Result = 0
            BEGIN
            EXEC im_log_sp_error_sp @ILSE_Error_Code = @SP_Result,
                                    @ILSE_SP_Name = 'imreportdata_clear_sp',
                                    @ILSE_String = '',
                                    @ILSE_Procedure_Name = @Routine_Name,
                                    @ILSE_Log_Activity = 'YES',
                                    @im_log_sp_error_sp_User_ID = @userid
            GOTO Error_Return
            END
        --    
        END
    ELSE
        BEGIN
        SET @Import_Identifier = @imapint01_sp_Import_Identifier
        END    
    --
    -- Create some temporary tables.
    --
    




















CREATE TABLE #apinpcdt   (
	trx_ctrl_num			varchar(16),
	trx_type            	smallint,
	sequence_id         	int,
	location_code       	varchar(8),
	item_code           	varchar(30),
	bulk_flag           	smallint,
	qty_ordered         	float,
	qty_received        	float,
	qty_returned        	float,
	qty_prev_returned   	float,
	approval_code			varchar(8),
	tax_code            	varchar(8),
	return_code         	varchar(8),
	code_1099           	varchar(8),
	po_ctrl_num         	varchar(16),
	unit_code           	varchar(8),
	unit_price          	float,
	amt_discount        	float,
	amt_freight         	float,
	amt_tax             	float,
	amt_misc            	float,
	amt_extended        	float,
	calc_tax            	float,
	date_entered        	int,
	gl_exp_acct         	varchar(32),
	new_gl_exp_acct     	varchar(32),
	rma_num             	varchar(20),
	line_desc           	varchar(60),
	serial_id           	int,
	company_id          	smallint,
	iv_post_flag        	smallint,
	po_orig_flag        	smallint,
	rec_company_code    	varchar(8),
	new_rec_company_code	varchar(8),
	reference_code			varchar(32),
	new_reference_code		varchar(32),
	trx_state        		smallint NULL,
	mark_flag           	smallint NULL,
	org_id		varchar(30) NULL,
	amt_nonrecoverable_tax	float,
	amt_tax_det		float

	)


    




















create table #apinpage   (
	trx_ctrl_num 	varchar(16),
	trx_type		smallint,
	sequence_id		int,
	date_applied 	int,
	date_due		int,
	date_aging		int,
	amt_due			float,
	trx_state    smallint    NULL,
	mark_flag       smallint     NULL
	)

    

















CREATE TABLE  #apinpchg  (
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
	date_aging			int,
	date_due			int,
	date_doc			int,
	date_entered		int,
	date_received		int,
	date_required		int,
	date_recurring		int,
	date_discount		int,
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
	recurring_code		varchar(8),
	location_code		varchar(8),
	payment_code		varchar(8),
	times_accrued		smallint,
	accrual_flag		smallint,
	drop_ship_flag		smallint,
	posted_flag			smallint,
	hold_flag			smallint,
	add_cost_flag		smallint,
	approval_flag		smallint,
	recurring_flag		smallint,
	one_time_vend_flag	smallint,
	one_check_flag		smallint,
	amt_gross			float,
	amt_discount		float,
	amt_tax				float,
	amt_freight			float,
	amt_misc			float,
	amt_net				float,
	amt_paid			float,
	amt_due				float,
	amt_restock			float,
	amt_tax_included	float,
	frt_calc_tax		float,
	doc_desc			varchar(40),
	hold_desc			varchar(40),
	user_id				smallint,
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
	cms_flag			smallint,
	process_group_num   varchar(16),
	nat_cur_code 		varchar(8),	 
	rate_type_home 		varchar(8),	 
	rate_type_oper		varchar(8),	 
	rate_home 			float,		   
	rate_oper			float,		   
	trx_state        	smallint    NULL,
	mark_flag           smallint	 NULL,
	net_original_amt	float,
	org_id		varchar(30) NULL,
	tax_freight_no_recoverable float
	)


    




















create table #apinptax   (
	trx_ctrl_num			varchar(16),
	trx_type			smallint,
	sequence_id			int,
	tax_type_code			varchar(8),
	amt_taxable			float,
	amt_gross			float,
	amt_tax				float,
	amt_final_tax			float,
	trx_state        smallint    NULL,
	mark_flag           smallint     NULL
	)


    










CREATE TABLE #apinptaxdtl
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
	account_code		varchar(32),
	mark_flag 		smallint NULL
)

    
CREATE TABLE #apinptmp
(
        timestamp		timestamp,
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
	user_id			smallint,	
	db_action			smallint
)


    















CREATE TABLE #apvobat (
						date_applied int, 
						process_group_num varchar(16),
						trx_type smallint,
						hold_flag smallint
					)

    















CREATE TABLE #apvtemp (
					 code varchar(12),
					 code2 varchar(8),
					 amt_net_home float,
					 amt_net_oper float
					)

    
CREATE TABLE #rates ( 
	from_currency 		varchar(8), 
	to_currency 		varchar(8), 
	rate_type 		varchar(8), 
	date_applied 		int, 
	rate 			float )

    -- 
    --  Initialize variables
    --
    SELECT @validation_flag = 1,
           @module_id = 4000,
           @val_mode = 2,
           @interface_mode = 2,    
           @apply_to_num = '',
           @date_due = 0,
           @po_ctrl_num = '',
           @doc_ctrl_num = '',
           @source_trx_ctrl_num = '',
           @ticket_num = '',
           @apply_trx_type = 0,
           @batch_code = '',
           @accrual_flag = 0,
           @posted_flag = 0,
           @hold_flag = 0,
           @one_time_vend_flag = 0,
           @next_serial_id = 1,
           @process_group_num = '', 
           @tax_code =  '',
           @line_desc = '',
           @qty_returned = 0,  
           @unit_cost = 0,
           @iv_orig_flag = 0,
           @new_company_code = '',
           @default_tax_type = 1,
           @tax_code_vendor = '',
           @tax_code_item = '',
           @spid = @@spid
    
    --
    -- Verify that glco.translation_rounding_acct is present (not blank or NULL).
    --
    DECLARE @glco_translation_rounding_acct VARCHAR(32)
    SELECT @glco_translation_rounding_acct = translation_rounding_acct
            FROM glco
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' glco.translation_rounding_acct' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    IF DATALENGTH(LTRIM(RTRIM(ISNULL(@glco_translation_rounding_acct, '')))) = 0
        BEGIN
        EXEC CVO_Control..[im_get_external_string_sp] 'glco tra',
                                                   @Text_String OUT
        EXEC im_log_sp @Text_String,
                       'YES',
                       @userid
        --
        -- In addition to logging, send the error to the report.
        --               
        SET @Text_String_1 = 'INSERT INTO [' + @Error_Table_Name + '] ([company_code], [e_ldesc], [User_ID]) VALUES (''' + @company_code + ''', ''' + @Text_String + ''', ' + CAST(@userid AS VARCHAR) + ')'
        EXEC (@Text_String_1)
        --
        GOTO Error_Return
        END        
    --

    --
    -- Verify key staging table data. 
    --
    EXEC @SP_Result = imapint01_Verify_Key_Data_sp @debug_level = @debug_level,
                                                   @userid = @userid
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' imapint01_Verify_Key_Data_sp 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Get Epicor User ID.
    --
    EXEC @SP_Result = imObtain_User_ID_sp @imObtain_User_ID_sp_Module = 'APVOUCHER',
                                          @imObtain_User_ID_sp_User_ID = @Process_User_ID OUT,
                                          @imObtain_User_ID_sp_User_Name = @User_Name OUT,
                                          @userid = @userid,
                                          @imObtain_User_ID_sp_Override_User_Name = @imapint01_sp_Override_User_Name
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' imObtain_User_ID_sp' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    IF NOT @SP_Result = 0
        BEGIN
        EXEC im_log_sp_error_sp @ILSE_Error_Code = @SP_Result,
                                @ILSE_SP_Name = 'imObtain_User_ID_sp',
                                @ILSE_String = '',
                                @ILSE_Procedure_Name = @Routine_Name,
                                @ILSE_Log_Activity = 'YES',
                                @im_log_sp_error_sp_User_ID = @userid
        GOTO Error_Return
        END
    -- 
    -- Get company_code and curr_precision from glco. 
    --
    SELECT @precision_gl = curr_precision,
           @company_code = RTRIM(LTRIM(ISNULL(company_code, '')))    
            FROM glco, glcurr_vw
            WHERE glco.home_currency = glcurr_vw.currency_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' glco' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
    If DATALENGTH(LTRIM(RTRIM(ISNULL(@precision_gl, '')))) = 0
        SET @precision_gl = 2                  
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
    -- Conditionally flag any records marked in error during a previous run as "not processed".
    -- This will allow a "trial" run to report records that have errors, and then
    -- allow a "final" run to produce a proper report.
    --
    SET @Reset_processed_flag = 'NO'
    IF EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'im_config')
        BEGIN
        SELECT @Reset_processed_flag = RTRIM(LTRIM(ISNULL(UPPER([Text Value]), '')))
                FROM [im_config] 
                WHERE RTRIM(LTRIM(ISNULL(UPPER([Item Name]), ''))) = 'RESET PROCESSED_FLAG'
        IF @@ROWCOUNT = 0
                OR @Reset_processed_flag IS NULL
                OR (NOT @Reset_processed_flag = 'NO' AND NOT @Reset_processed_flag = 'YES' AND NOT @Reset_processed_flag = 'TRUE' AND NOT @Reset_processed_flag = 'FALSE')
            SET @Reset_processed_flag = 'NO'
        IF @Reset_processed_flag = 'TRUE'
            SET @Reset_processed_flag = 'YES'
        END
    IF @Reset_processed_flag = 'YES'
        BEGIN
        UPDATE [imaphdr_vw]
                SET [processed_flag] = 0
                WHERE ([processed_flag] = 2 OR [processed_flag] IS NULL)
                        AND RTRIM(LTRIM(ISNULL([company_code], ''))) = @company_code
                        AND [trx_type] = @invoice_flag
                        AND ([User_ID] = @userid OR @userid = 0)
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imaphdr_vw 1A' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        UPDATE [imapdtl_vw]
                SET [processed_flag] = 0
                WHERE ([processed_flag] = 2 OR [processed_flag] IS NULL)
                        AND RTRIM(LTRIM(ISNULL([company_code], ''))) = @company_code
                        AND ([User_ID] = @userid OR @userid = 0)
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imapdtl_vw 1A' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        END
    --
    -- Get the "Allow Import of trx_ctrl_num" config table entry..
    --
    SET @Allow_Import_of_trx_ctrl_num = 'NO'
    IF EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'im_config')
        BEGIN
        SELECT @Allow_Import_of_trx_ctrl_num = RTRIM(LTRIM(ISNULL(UPPER([Text Value]), '')))
                FROM [im_config] 
                WHERE RTRIM(LTRIM(ISNULL(UPPER([Item Name]), ''))) = 'ALLOW IMPORT OF TRX_CTRL_NUM'
        IF @@ROWCOUNT = 0
                OR @Allow_Import_of_trx_ctrl_num IS NULL
                OR (NOT @Allow_Import_of_trx_ctrl_num = 'NO' AND NOT @Allow_Import_of_trx_ctrl_num = 'YES' AND NOT @Allow_Import_of_trx_ctrl_num = 'TRUE' AND NOT @Allow_Import_of_trx_ctrl_num = 'FALSE')
            SET @Allow_Import_of_trx_ctrl_num = 'NO'
        IF @Allow_Import_of_trx_ctrl_num = 'TRUE'
            SET @Allow_Import_of_trx_ctrl_num = 'YES'
        END
    






    SELECT *
            INTO [#imaphdr_vw]
            FROM [imaphdr_vw]
            WHERE RTRIM(LTRIM(ISNULL([company_code], ''))) = @company_code
                    AND [trx_type] = @invoice_flag
                    AND (NOT [processed_flag] = 1 OR [processed_flag] IS NULL)         
                    AND ([User_ID] = @userid OR @userid = 0)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' #imaphdr_vw 1A' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    SELECT *
            INTO [#imapdtl_vw]
            FROM [imapdtl_vw] 
            WHERE RTRIM(LTRIM(ISNULL([company_code], ''))) = @company_code
                    AND [trx_type] = @invoice_flag
                    AND (NOT [processed_flag] = 1 OR [processed_flag] IS NULL)         
                    AND ([User_ID] = @userid OR @userid = 0)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' #imapdtl_vw 1A' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE [#imaphdr_vw]
            SET [processed_flag] = 0    
    UPDATE [#imapdtl_vw]
            SET [processed_flag] = 0    
    CREATE UNIQUE INDEX imaphdr_vw_Index_1 ON #imaphdr_vw 
            (company_code, 
             source_trx_ctrl_num) 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATEINDEX + ' imaphdr_vw_Index_1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    CREATE UNIQUE INDEX imapdtl_vw_Index_1 ON #imapdtl_vw 
            (company_code, 
             source_trx_ctrl_num,
             sequence_id)  
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATEINDEX + ' imapdtl_vw_Index_1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- The trx_ctrl_num column is ignored.  Set it to an empty string.
    --
    IF NOT @Allow_Import_of_trx_ctrl_num = 'YES'
        BEGIN
        UPDATE #imaphdr_vw
                SET trx_ctrl_num = ''
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imaphdr_vw 5' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        UPDATE #imapdtl_vw
                SET trx_ctrl_num = ''
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imapdtl_vw 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        END
    --    
    -- Set the [Import Identifier] column.
    --        
    UPDATE [imaphdr_vw]
            SET [Import Identifier] = @Import_Identifier
            WHERE RTRIM(LTRIM(ISNULL([company_code], ''))) = @company_code
                    AND [trx_type] = @invoice_flag
                    AND (NOT [processed_flag] = 1 OR [processed_flag] IS NULL)
                    AND ([User_ID] = @userid OR @userid = 0)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imaphdr_vw 2A' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE [imapdtl_vw]
            SET [Import Identifier] = @Import_Identifier
            WHERE RTRIM(LTRIM(ISNULL([company_code], ''))) = @company_code
                    AND [trx_type] = @invoice_flag
                    AND (NOT [processed_flag] = 1 OR [processed_flag] IS NULL)
                    AND ([User_ID] = @userid OR @userid = 0)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imapdtl_vw 2A' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --    
    -- Set rec_company_code.
    --        
    UPDATE [#imapdtl_vw]
            SET [rec_company_code] = d.[company_code]
            FROM [#imapdtl_vw] d
            INNER JOIN [#imaphdr_vw] h
                    ON h.[source_trx_ctrl_num] = d.[source_trx_ctrl_num]
            WHERE (h.[intercompany_flag] = 0 OR h.[intercompany_flag] IS NULL)
                    AND (DATALENGTH(LTRIM(RTRIM(ISNULL(d.[rec_company_code], '')))) = 0)                 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imaphdr_vw 2A' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Verify that sequence_id values are monotonically increasing.
    -- 
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': Begin checking for monotonically-increasing sequence IDs'
    SELECT DISTINCT a.source_trx_ctrl_num, 
                    cnt = COUNT(*), 
                    maxid = MAX(a.sequence_id), 
                    flg = 0
            INTO #temp_imapintsp
            FROM #imapdtl_vw a, #imaphdr_vw b
            WHERE RTRIM(LTRIM(ISNULL(a.company_code, ''))) = @company_code
                    AND a.source_trx_ctrl_num = b.source_trx_ctrl_num
                    AND b.processed_flag = 0
            GROUP BY a.source_trx_ctrl_num
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' #temp_imapintsp' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
    INSERT INTO perror (process_ctrl_num, batch_code, module_id, err_code, info1, info2, infoint, infofloat, flag1, trx_ctrl_num, sequence_id, source_ctrl_num, extra ) 
            SELECT 'imapint01temp', '', @module_id, 90938, source_trx_ctrl_num, '', 0, 0, 0, '', 0, source_trx_ctrl_num, 0
            FROM #temp_imapintsp
            WHERE cnt <> maxid
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' perror 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    IF @Row_Count > 0
        BEGIN
        DECLARE Monotonic_Cursor INSENSITIVE CURSOR FOR 
                SELECT source_trx_ctrl_num, sequence_id 
                FROM [#imapdtl_vw] 
                ORDER BY source_trx_ctrl_num, sequence_id
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DECLARE + ' Monotonic_Cursor 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
        SET @Monotonic_Cursor_Allocated = 'YES'        
        OPEN Monotonic_Cursor
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_OPEN + ' Monotonic_Cursor 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
        SET @Monotonic_Cursor_Opened = 'YES'        
        FETCH NEXT
                FROM Monotonic_Cursor
                INTO @Monotonic_source_trx_ctrl_num, @Monotonic_sequence_id
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_FETCHNEXT + ' Monotonic_Cursor 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
        SET @Monotonic_Previous_source_trx_ctrl_num = @Monotonic_source_trx_ctrl_num
        SET @Monotonic_Computed_sequence_id = 0
        WHILE NOT @@FETCH_STATUS = -1
            BEGIN
            SET @Monotonic_Computed_sequence_id = @Monotonic_Computed_sequence_id + 1
            IF @Monotonic_source_trx_ctrl_num = @Monotonic_Previous_source_trx_ctrl_num
                BEGIN
                IF NOT @Monotonic_sequence_id = @Monotonic_Computed_sequence_id
                    BEGIN
                    UPDATE perror
                            SET infoint = @Monotonic_Computed_sequence_id - 1
                            WHERE process_ctrl_num = 'imapint01temp'
                                    AND source_ctrl_num = @Monotonic_source_trx_ctrl_num 
                    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' perror 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
                    END
                END
            ELSE
                BEGIN
                SET @Monotonic_Computed_sequence_id = 1
                SET @Monotonic_Previous_source_trx_ctrl_num = @Monotonic_source_trx_ctrl_num
                END
            FETCH NEXT
                    FROM Monotonic_Cursor
                    INTO @Monotonic_source_trx_ctrl_num, @Monotonic_sequence_id
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_FETCHNEXT + ' Monotonic_Cursor 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
            END
        CLOSE Monotonic_Cursor
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CLOSE + ' Monotonic_Cursor 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
        SET @Monotonic_Cursor_Opened = 'NO'
        DEALLOCATE Monotonic_Cursor
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DEALLOCATE + ' Monotonic_Cursor 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
        SET @Monotonic_Cursor_Allocated = 'NO'        
        END        
    IF @debug_level >= 3
        BEGIN
        SELECT '(3): ' + @Routine_Name + ': End of sequence ID check.  source_trx_ctrl_num for records with bad sequences:'
        SELECT * 
                FROM #temp_imapintsp
                WHERE NOT [cnt] = [maxid]
        END
    DROP TABLE #temp_imapintsp
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DROPTABLE + ' #temp_imapintsp' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
    --
    BEGIN SELECT @date_applied_error = ISNULL(err_desc, 'Invalid date_applied') FROM apedterr WHERE err_code = 90931 INSERT INTO perror (process_ctrl_num, batch_code, module_id, err_code, info1, info2, infoint, infofloat, flag1, trx_ctrl_num, sequence_id, source_ctrl_num, extra ) SELECT 'imapint01temp', '', @module_id, 90931, date_applied, source_trx_ctrl_num, 0, 0.0, 0, source_trx_ctrl_num, 0, source_trx_ctrl_num, 0 FROM #imaphdr_vw WHERE (ISDATE(date_applied) = 0 AND date_applied <> '') AND trx_type = @invoice_flag AND company_code = @company_code AND processed_flag = 0 END
    BEGIN SELECT @date_aging_error = ISNULL(err_desc, 'Invalid date_aging') FROM apedterr WHERE err_code = 90932 INSERT INTO perror (process_ctrl_num, batch_code, module_id, err_code, info1, info2, infoint, infofloat, flag1, trx_ctrl_num, sequence_id, source_ctrl_num, extra ) SELECT 'imapint01temp', '', @module_id, 90932, date_aging, source_trx_ctrl_num, 0, 0.0, 0, source_trx_ctrl_num, 0, source_trx_ctrl_num, 0 FROM #imaphdr_vw WHERE (ISDATE(date_aging) = 0 AND date_aging <> '') AND trx_type = @invoice_flag AND company_code = @company_code AND processed_flag = 0 END
    BEGIN SELECT @date_due_error = ISNULL(err_desc, 'Invalid date_due') FROM apedterr WHERE err_code = 90933 INSERT INTO perror (process_ctrl_num, batch_code, module_id, err_code, info1, info2, infoint, infofloat, flag1, trx_ctrl_num, sequence_id, source_ctrl_num, extra ) SELECT 'imapint01temp', '', @module_id, 90933, date_due, source_trx_ctrl_num, 0, 0.0, 0, source_trx_ctrl_num, 0, source_trx_ctrl_num, 0 FROM #imaphdr_vw WHERE (ISDATE(date_due) = 0 AND date_due <> '') AND trx_type = @invoice_flag AND company_code = @company_code AND processed_flag = 0 END
    BEGIN SELECT @date_doc_error = ISNULL(err_desc, 'Invalid date_doc') FROM apedterr WHERE err_code = 90934 INSERT INTO perror (process_ctrl_num, batch_code, module_id, err_code, info1, info2, infoint, infofloat, flag1, trx_ctrl_num, sequence_id, source_ctrl_num, extra ) SELECT 'imapint01temp', '', @module_id, 90934, date_doc, source_trx_ctrl_num, 0, 0.0, 0, source_trx_ctrl_num, 0, source_trx_ctrl_num, 0 FROM #imaphdr_vw WHERE (ISDATE(date_doc) = 0 AND date_doc <> '') AND trx_type = @invoice_flag AND company_code = @company_code AND processed_flag = 0 END
    BEGIN SELECT @date_received_error = ISNULL(err_desc, 'Invalid date_received') FROM apedterr WHERE err_code = 90935 INSERT INTO perror (process_ctrl_num, batch_code, module_id, err_code, info1, info2, infoint, infofloat, flag1, trx_ctrl_num, sequence_id, source_ctrl_num, extra ) SELECT 'imapint01temp', '', @module_id, 90935, date_received, source_trx_ctrl_num, 0, 0.0, 0, source_trx_ctrl_num, 0, source_trx_ctrl_num, 0 FROM #imaphdr_vw WHERE (ISDATE(date_received) = 0 AND date_received <> '') AND trx_type = @invoice_flag AND company_code = @company_code AND processed_flag = 0 END
    BEGIN SELECT @date_required_error = ISNULL(err_desc, 'Invalid date_required') FROM apedterr WHERE err_code = 90936 INSERT INTO perror (process_ctrl_num, batch_code, module_id, err_code, info1, info2, infoint, infofloat, flag1, trx_ctrl_num, sequence_id, source_ctrl_num, extra ) SELECT 'imapint01temp', '', @module_id, 90936, date_required, source_trx_ctrl_num, 0, 0.0, 0, source_trx_ctrl_num, 0, source_trx_ctrl_num, 0 FROM #imaphdr_vw WHERE (ISDATE(date_required) = 0 AND date_required <> '') AND trx_type = @invoice_flag AND company_code = @company_code AND processed_flag = 0 END
    BEGIN SELECT @date_discount_error = ISNULL(err_desc, 'Invalid date_discount') FROM apedterr WHERE err_code = 90937 INSERT INTO perror (process_ctrl_num, batch_code, module_id, err_code, info1, info2, infoint, infofloat, flag1, trx_ctrl_num, sequence_id, source_ctrl_num, extra ) SELECT 'imapint01temp', '', @module_id, 90937, date_discount, source_trx_ctrl_num, 0, 0.0, 0, source_trx_ctrl_num, 0, source_trx_ctrl_num, 0 FROM #imaphdr_vw WHERE (ISDATE(date_discount) = 0 AND date_discount <> '') AND trx_type = @invoice_flag AND company_code = @company_code AND processed_flag = 0 END
    IF @debug_level >= 3
        BEGIN
        SELECT '(3): ' + @Routine_Name + ': Dump of perror after DATE_PROTECT:'
        SELECT * FROM perror 
                WHERE process_ctrl_num = 'imapint01temp'
        END
    SELECT @one_time_vend_code = one_time_vend_code,
           @default_exp_flag = default_exp_flag,
           @aprv_voucher_flag = aprv_voucher_flag,
           @default_aprv_code = default_aprv_code
            FROM apco
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' apco 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
    SELECT @default_tax_type = default_tax_type,
           @default_tax_code = tax_code
            FROM apco
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' apco 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
    EXEC @SP_Result = imrates_sp @company_code, 
                                 @debug_level,
                                 @userid 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' imrates_sp' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    IF NOT @SP_Result = 0
        BEGIN
        EXEC im_log_sp_error_sp @ILSE_Error_Code = @SP_Result,
                                @ILSE_SP_Name = 'imrates_sp',
                                @ILSE_String = '',
                                @ILSE_Procedure_Name = @Routine_Name,
                                @ILSE_Log_Activity = 'YES',
                                @im_log_sp_error_sp_User_ID = @userid
        GOTO Error_Return
        END    
    





    IF @default_tax_type = 1            
        BEGIN
        UPDATE #imaphdr_vw
                SET tax_code = v.tax_code
                FROM #imaphdr_vw i, apvend v
                WHERE i.tax_code = ''
                        AND v.vendor_code = i.vendor_code
                        AND RTRIM(LTRIM(ISNULL(i.company_code, ''))) = @company_code
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imaphdr_vw 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
        END
    IF @default_tax_type = 2            
        BEGIN
        UPDATE #imaphdr_vw
                SET tax_code = @tax_code_item
                WHERE tax_code = ''
                        AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imaphdr_vw 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
        END                
    IF @default_tax_type = 3            
        BEGIN
        UPDATE #imaphdr_vw
                SET tax_code = @default_tax_code
                WHERE tax_code = ''
                        AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imaphdr_vw 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
        END
    


    SELECT @addr1 = '',
           @addr2 = '',
           @addr3 = '',
           @addr4 = '',
           @addr5 = '',
           @addr6 = '',
           @unit_code = '',
           @amt_tax = 0,
           @amt_profit = 0,
           @return_code = '',  
           @iv_post_flag = 0,  
           @oe_orig_flag = 0,
           @qty_returned = 0,  
           @unit_cost = 0 
    SELECT @outer_order_num = ''
    IF (@debug_level >= 3)  
        SELECT '(3): ' + @Routine_Name + ': Begin loop' 
    WHILE (1 = 1)
        BEGIN 
        SET ROWCOUNT 1
        


        IF @invoice_flag IN (4091, 4092)       
            BEGIN
            SELECT @source_trx_ctrl_num = source_trx_ctrl_num,
                   @vendor_code = vendor_code,
                   @pay_to_code = pay_to_code
                    FROM #imaphdr_vw
                    WHERE source_trx_ctrl_num > @outer_order_num
                            AND processed_flag = 0
                            AND trx_type = @invoice_flag
                            AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
                    ORDER BY source_trx_ctrl_num
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' #imaphdr_vw 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
            END
        ELSE
            BEGIN
            


            SELECT @source_trx_ctrl_num = source_trx_ctrl_num,
                   @vendor_code = vendor_code,
                   @pay_to_code = pay_to_code
                    FROM #imaphdr_vw
                    WHERE source_trx_ctrl_num > @outer_order_num
                            AND processed_flag = 0
                            AND trx_type IN (4091,4092)
                            AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
                    ORDER BY source_trx_ctrl_num
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' #imaphdr_vw 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
            END        
        SET ROWCOUNT 0
        IF (@Row_Count = 0) 
            BREAK
        SELECT @outer_order_num = @source_trx_ctrl_num 
        IF (@debug_level >= 3)  
            SELECT '(3): ' + @Routine_Name + ': @outer_order_num = ' + ISNULL(@outer_order_num, 'NULL')
           

                       
        IF EXISTS (SELECT @vendor_code FROM apvend WHERE vendor_code = @vendor_code)
            BEGIN
            SELECT @vendor_name = vendor_name,
                   @attention_name = attention_name,    
                   @attention_phone = attention_phone,    
                   @vend_contact_phone = contact_phone,  
                   @vend_posting_code = posting_code,
                   @vend_comment_code = comment_code,
                   @vend_terms_code = terms_code,   
                   @vend_tax_code = tax_code,    
                   @vend_location_code = location_code,
                   @vend_payment_code = payment_code,
                   @code_1099 = code_1099,
                   @vend_branch_code = branch_code
                    FROM apvend
                    WHERE vendor_code = @vendor_code
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' apvend 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
            END
        ELSE
            BEGIN
            SELECT @vendor_name = '',
                   @attention_name = '',
                   @attention_phone = '',
                   @vend_contact_phone = '',
                   @vend_posting_code = '',
                   @vend_comment_code = '',
                   @vend_terms_code = '',
                   @vend_tax_code = '',
                   @vend_location_code = '',
                   @vend_payment_code = '',
                   @code_1099 = '',
                   @vend_branch_code ='DATA'
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @vendor_name' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
            END
        

                       
        IF NOT DATALENGTH(LTRIM(RTRIM(ISNULL(@pay_to_code, '')))) = 0
            BEGIN    
            SELECT @addr1 = addr1,
                   @addr2 = addr2,
                   @addr3 = addr3, 
                   @addr4 = addr4,
                   @addr5 = addr5, 
                   @addr6 = addr6
                    FROM appayto
                    WHERE vendor_code = @vendor_code
                            AND pay_to_code = @pay_to_code
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' appayto' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
            END
        


                        
        SELECT @trx_ctrl_num = trx_ctrl_num,
               @branch_code = branch_code,
               @trx_type = trx_type,
               @doc_desc = ISNULL(doc_desc, ''),
               @po_ctrl_num = ISNULL(po_ctrl_num, ''),    
               @ticket_num = ticket_num,
               @doc_ctrl_num = doc_ctrl_num,
               @apply_to_num = ISNULL(apply_to_num, ''),
               @chDateApplied = date_applied,
               @chDateDoc = date_doc,
               @chDateDue = date_due,
               @chDateAging = date_aging,
               @chDateReceived = date_received,
               @chDateRequired = date_required,
               @chDateDiscount = date_discount,
               @payment_code = ISNULL(payment_code, ''),
               @posting_code = ISNULL(posting_code, ''),
               @comment_code = ISNULL(comment_code, ''),
               @terms_code = ISNULL(terms_code, ''),
               @hold_flag = hold_flag,
               @hold_desc = ISNULL(hold_desc, ''),    
               @intercompany_flag = intercompany_flag,
               @nat_cur_code = nat_cur_code,
               @rate_type_home = rate_type_home,
               @rate_type_oper = rate_type_oper,
               @rate_home = ISNULL(rate_home, 0),
               @rate_oper = ISNULL(rate_oper, 0),
               @tax_code = tax_code,
               @approval_code = ISNULL(approval_code, ''),
               @approval_flag = ISNULL(approval_flag, 0),
               @imaphdr_vw_add_cost_flag = ISNULL(add_cost_flag, 0),
               @imaphdr_vw_amt_freight = ISNULL(amt_freight, 0),
               @imaphdr_vw_amt_misc = ISNULL(amt_misc, 0),
               @imaphdr_vw_amt_paid = ISNULL(amt_paid, 0),
               @imaphdr_vw_amt_restock = ISNULL(amt_restock, 0),
               @imaphdr_vw_amt_tax_included = ISNULL(amt_tax_included, 0),
               @imaphdr_vw_attention_name = ISNULL(attention_name, @attention_name),
               @imaphdr_vw_attention_phone = ISNULL(attention_phone, @attention_phone),
               @imaphdr_vw_class_code = class_code,
               @imaphdr_vw_cms_flag = ISNULL(cms_flag, 0),
               @imaphdr_vw_date_entered = ISNULL(date_entered, ''),
               @imaphdr_vw_date_recurring = ISNULL(date_recurring, ''),
               @imaphdr_vw_drop_ship_flag = ISNULL(drop_ship_flag, 0),
               @imaphdr_vw_fob_code = fob_code,
               @imaphdr_vw_frt_calc_tax = ISNULL(frt_calc_tax, 0),
               @imaphdr_vw_location_code = location_code,
               @imaphdr_vw_one_check_flag = ISNULL(one_check_flag, 0),
               @imaphdr_vw_recurring_code = ISNULL(recurring_code, ''),
               @imaphdr_vw_recurring_flag = ISNULL(recurring_flag, 0),
               @imaphdr_vw_times_accrued = ISNULL(times_accrued, 0),
               @imaphdr_vw_user_trx_type_code = ISNULL(user_trx_type_code, '') ,
               @imaphdr_vw_vend_order_num = ISNULL(vend_order_num, ''),
 	       @hdr_org_id = ISNULL(org_id, ''),          
	       @tax_freight_no_recoverable = tax_freight_no_recoverable
                FROM #imaphdr_vw
                WHERE source_trx_ctrl_num =  @source_trx_ctrl_num
                        AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' #imaphdr_vw 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
        IF (@debug_level >= 3)  
            BEGIN
            SELECT '(3): ' + @Routine_Name + ': #imaphdr_vw WHERE source_trx_ctrl_num = ' + ISNULL(@source_trx_ctrl_num, 'NULL') + ' AND TRIM(company_code) = ' + @company_code
            SELECT * FROM #imaphdr_vw 
                    WHERE source_trx_ctrl_num = @source_trx_ctrl_num 
                            AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' #imaphdr_vw 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
            END
        --
        -- Assign default values to header columns..
        --
        -- The @date_x variables will be set to intermediate values of 0 or 1 
        -- depending on their validity; set to actual dates here if they equal 1, and set
        -- set to actual dates later in the code if they equal 0. 
        --
        SELECT @date_applied = ISDATE(ISNULL(@chDateApplied, ''))
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @date_applied 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
        IF @date_applied = 1
            BEGIN
            SELECT @date_applied = datediff(dd, @January_First_Nineteen_Eighty, CONVERT(datetime, ISNULL(@chDateApplied, 0))) + 722815
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @date_applied 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
            END
        SELECT @date_doc = ISDATE(ISNULL(@chDateDoc, ''))
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @date_doc 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
        IF @date_doc = 1
            BEGIN
            SELECT @date_doc = datediff(dd, @January_First_Nineteen_Eighty, CONVERT(datetime, ISNULL(@chDateDoc, 0))) + 722815
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @date_doc 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
            END
        SELECT @date_due = ISDATE(ISNULL(@chDateDue, ''))
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @date_due 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
        IF @date_due = 1
            BEGIN
            SELECT @date_due = datediff(dd, @January_First_Nineteen_Eighty, CONVERT(datetime, ISNULL(@chDateDue, 0))) + 722815
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @date_due 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
            END
        SELECT @date_aging = ISDATE(ISNULL(@chDateAging, ''))
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @date_aging 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
        IF @date_aging = 1
            BEGIN
            SELECT @date_aging = datediff(dd, @January_First_Nineteen_Eighty, CONVERT(datetime, ISNULL(@chDateAging, 0))) + 722815
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @date_aging 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
            END
        SELECT @date_received = ISDATE(ISNULL(@chDateReceived, ''))
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @date_received 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
        IF @date_received = 1
            BEGIN
            SELECT @date_received = datediff(dd, @January_First_Nineteen_Eighty, CONVERT(datetime, ISNULL(@chDateReceived, 0))) + 722815
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @date_received 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
            END
        SELECT @date_required = ISDATE(ISNULL(@chDateRequired, ''))
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @date_required 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
        IF @date_required = 1
            BEGIN
            SELECT @date_required = datediff(dd, @January_First_Nineteen_Eighty, CONVERT(datetime, ISNULL(@chDateRequired, 0))) + 722815
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @date_required 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
            END
        SELECT @date_discount = ISDATE(ISNULL(@chDateDiscount, ''))
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @date_discount 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
        IF @date_discount = 1
            BEGIN
            SELECT @date_discount = datediff(dd, @January_First_Nineteen_Eighty, CONVERT(datetime, ISNULL(@chDateDiscount, 0))) + 722815
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @date_discount 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
            END
        SELECT @date_entered = ISDATE(ISNULL(@imaphdr_vw_date_entered, ''))
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @date_entered 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
        IF @date_entered = 1
            BEGIN
            SELECT @date_entered = datediff(dd, @January_First_Nineteen_Eighty, CONVERT(datetime, ISNULL(@imaphdr_vw_date_entered, 0))) + 722815
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @date_entered 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
            END
        SELECT @date_recurring = ISDATE(ISNULL(@imaphdr_vw_date_recurring, ''))
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @date_recurring 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
        IF @date_recurring = 1
            BEGIN
            SELECT @date_recurring = datediff(dd, @January_First_Nineteen_Eighty, CONVERT(datetime, ISNULL(@imaphdr_vw_date_recurring, 0))) + 722815
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @date_recurring 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
            END
        --
        -- For a one-time vendor, obtain name, address, and phone number from the 
        -- staging table.
        --    
        IF @vendor_code = @one_time_vend_code
            BEGIN
            SELECT @one_time_vend_flag = 1
            SELECT @addr1 = pay_to_addr1,
                   @addr2 = pay_to_addr2,
                   @addr3 = pay_to_addr3,
                   @addr4 = pay_to_addr4,
                   @addr5 = pay_to_addr5,
                   @addr6 = pay_to_addr6,
                   @attention_name = attention_name,
                   @attention_phone = attention_phone
                    FROM #imaphdr_vw
                    WHERE source_trx_ctrl_num = @source_trx_ctrl_num
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' #imaphdr_vw 4' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            END
        ELSE
            BEGIN
            SELECT @one_time_vend_flag = 0
            SET @attention_name = @imaphdr_vw_attention_name
            SET @attention_phone = @imaphdr_vw_attention_phone
            END
        --    

	   IF DATALENGTH(LTRIM(RTRIM(ISNULL(@hdr_org_id, '')))) = 0
            BEGIN
			SELECT @hdr_org_id = dbo.sm_get_current_org_fn()
            END    
        IF DATALENGTH(LTRIM(RTRIM(ISNULL(@posting_code, '')))) = 0
            BEGIN
            IF (@vend_posting_code IS NOT NULL)
                BEGIN
                SELECT @posting_code = @vend_posting_code 
                SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @posting_code' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
                END
            END    
        IF DATALENGTH(LTRIM(RTRIM(ISNULL(@tax_code, '')))) = 0
            BEGIN
            IF (@vend_tax_code IS NOT NULL)
                BEGIN
                SELECT @tax_code = @vend_tax_code 
                SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @tax_code' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
                END
            END
        IF DATALENGTH(LTRIM(RTRIM(ISNULL(@terms_code, '')))) = 0
            BEGIN
            IF (@vend_terms_code IS NOT NULL)
                BEGIN
                SELECT @terms_code = @vend_terms_code 
                SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @terms_code' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
                END
            END    
        IF DATALENGTH(LTRIM(RTRIM(ISNULL(@comment_code, '')))) = 0
            BEGIN
            IF (@vend_comment_code IS NOT NULL)
                BEGIN
                SELECT @comment_code = @vend_comment_code 
                SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @comment_code' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
                END
            END    
        IF DATALENGTH(LTRIM(RTRIM(ISNULL(@branch_code, '')))) = 0
            BEGIN
            IF (@vend_branch_code IS NOT NULL)
                BEGIN
                SELECT @branch_code = @vend_branch_code
                SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @branch_code' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
                END
            END    
        IF DATALENGTH(LTRIM(RTRIM(ISNULL(@payment_code, '')))) = 0
            BEGIN
            IF (@vend_payment_code IS NOT NULL)
                BEGIN
                SELECT @payment_code = @vend_payment_code
                SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @payment_code' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
                END
            END    
        IF DATALENGTH(LTRIM(RTRIM(ISNULL(@imaphdr_vw_class_code, '')))) = 0
            BEGIN    
            IF EXISTS (SELECT vendor_code FROM apvend WHERE vendor_code = @vendor_code)
                BEGIN
                SELECT @imaphdr_vw_class_code = vend_class_code
                        FROM apvend
                        WHERE vendor_code = @vendor_code
                SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' apvend 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
                END
            ELSE
                SET @imaphdr_vw_class_code = ''
            END    
        IF DATALENGTH(LTRIM(RTRIM(ISNULL(@imaphdr_vw_fob_code, '')))) = 0
            BEGIN    
            IF EXISTS (SELECT vendor_code FROM apvend WHERE vendor_code = @vendor_code)
                BEGIN
                SELECT @imaphdr_vw_fob_code = fob_code
                        FROM apvend
                        WHERE vendor_code = @vendor_code
                SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' apvend 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
                END
            ELSE
                SET @imaphdr_vw_fob_code = ''
            END    
        IF @imaphdr_vw_location_code IS NULL
            BEGIN    
            IF EXISTS (SELECT vendor_code FROM apvend WHERE vendor_code = @vendor_code)
                BEGIN
                SELECT @imaphdr_vw_location_code = location_code
                        FROM apvend
                        WHERE vendor_code = @vendor_code
                SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' apvend 4' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
                END
            ELSE
                SET @imaphdr_vw_location_code = ''
            END
        IF @imaphdr_vw_location_code IS NULL
            SET @imaphdr_vw_location_code = ''
        IF @imaphdr_vw_one_check_flag IS NULL
            BEGIN    
            IF EXISTS (SELECT vendor_code FROM apvend WHERE vendor_code = @vendor_code)
                BEGIN
                SELECT @imaphdr_vw_one_check_flag = one_check_flag
                        FROM apvend
                        WHERE vendor_code = @vendor_code
                SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' apvend 5' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
                END
            ELSE
                SET @imaphdr_vw_one_check_flag = 0
            END    
        IF DATALENGTH(LTRIM(RTRIM(ISNULL(@imaphdr_vw_user_trx_type_code, '')))) = 0
            BEGIN    
            IF EXISTS (SELECT vendor_code FROM apvend WHERE vendor_code = @vendor_code)
                BEGIN
                SELECT @imaphdr_vw_user_trx_type_code = user_trx_type_code
                        FROM apvend
                        WHERE vendor_code = @vendor_code
                SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' apvend 6' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
                END
            ELSE
                SET @imaphdr_vw_user_trx_type_code = 'VOUCHER'
            END    
        



        IF (@aprv_voucher_flag = 1)
            BEGIN
            IF (@approval_code = '')
                BEGIN
                SELECT @approval_code = @default_aprv_code
                SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @approval_code' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
                END
            END
        



        IF @date_applied = 0
            BEGIN
            EXEC @SP_Result = appdate_sp @date_applied OUTPUT
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' appdate_sp 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            IF @SP_Result = 0
                BEGIN
                EXEC im_log_sp_error_sp @ILSE_Error_Code = @SP_Result,
                                        @ILSE_SP_Name = 'appdate_sp',
                                        @ILSE_String = '@date_applied',
                                        @ILSE_Procedure_Name = @Routine_Name,
                                        @ILSE_Log_Activity = 'YES',
                                        @im_log_sp_error_sp_User_ID = @userid
                GOTO Error_Return
                END
            END        
        IF @date_doc = 0
            BEGIN
            SELECT @date_doc =  @date_applied 
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @date_doc 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
            END
        IF @date_aging = 0
            BEGIN
            SELECT @date_aging = @date_doc
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @date_aging 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
            END
        IF @date_received = 0
            BEGIN
            SELECT @date_received = @date_doc
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @date_received 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
            END
        IF @date_discount = 0
            BEGIN
            SELECT @date_discount = @date_doc
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @date_discount 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
            END
        IF @date_required = 0
            BEGIN
            SELECT @date_required = @date_doc
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @date_required 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
            END
        IF @date_entered = 0
            BEGIN
            EXEC @SP_Result = appdate_sp @date_entered OUTPUT
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' appdate_sp 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            IF @SP_Result = 0
                BEGIN
                EXEC im_log_sp_error_sp @ILSE_Error_Code = @SP_Result,
                                        @ILSE_SP_Name = 'appdate_sp',
                                        @ILSE_String = '@date_entered',
                                        @ILSE_Procedure_Name = @Routine_Name,
                                        @ILSE_Log_Activity = 'YES',
                                        @im_log_sp_error_sp_User_ID = @userid
                GOTO Error_Return
                END
            END
        IF @date_recurring = 0
            BEGIN
            EXEC @SP_Result = appdate_sp @date_recurring OUTPUT
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' appdate_sp 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            IF @SP_Result = 0
                BEGIN
                EXEC im_log_sp_error_sp @ILSE_Error_Code = @SP_Result,
                                        @ILSE_SP_Name = 'appdate_sp',
                                        @ILSE_String = '@date_recurring',
                                        @ILSE_Procedure_Name = @Routine_Name,
                                        @ILSE_Log_Activity = 'YES',
                                        @im_log_sp_error_sp_User_ID = @userid
                GOTO Error_Return
                END
            END
        


        IF (@debug_level >= 3)  
            SELECT  '(3): ' + @Routine_Name + ': Before imdtdue_sp: @date_due, @terms_code, @date_doc: ' + CAST(@date_due AS VARCHAR) + ', ' + CAST(@terms_code AS VARCHAR) + ', ' + CAST(@date_doc AS VARCHAR)
        IF @date_due = 0
            BEGIN    
            EXEC @SP_Result = imdtdue_sp @module_id,
                                         @terms_code,
                                         @date_doc,
                                         @date_due OUTPUT,
                                         @debug_level,
                                         @userid
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' imdtdue_sp' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            IF NOT @SP_Result = 0
                BEGIN
                EXEC im_log_sp_error_sp @ILSE_Error_Code = @SP_Result,
                                        @ILSE_SP_Name = 'imdtdue_sp',
                                        @ILSE_String = '',
                                        @ILSE_Procedure_Name = @Routine_Name,
                                        @ILSE_Log_Activity = 'YES',
                                        @im_log_sp_error_sp_User_ID = @userid
                GOTO Error_Return
                END    
            END
        IF (@debug_level >= 3)  
            BEGIN
            SELECT '(3): ' + @Routine_Name + ': After imdtdue_sp:'
            SELECT '(3): ' + @Routine_Name + ': @date_due = ' + CAST(@date_due AS VARCHAR)
            END
        IF @date_due = 0 
                OR @date_due IS NULL 
            SELECT @date_due = @date_doc    
        


        IF DATALENGTH(LTRIM(RTRIM(ISNULL(@trx_ctrl_num, '')))) = 0 
                AND @method_flag < 2
            BEGIN
            SELECT @trx_ctrl_num = @source_trx_ctrl_num
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @trx_ctrl_num' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
            END
        IF @trx_type = 4092
            SELECT @date_due = 0,
                   @date_discount = 0
        IF @hold_flag NOT IN (0, 1, 13)
                OR @hold_flag IS NULL
            BEGIN
            IF (@debug_level >= 3)  
                SELECT '(3): ' + @Routine_Name + ': For trx_ctrl_num = ' + ISNULL(@trx_ctrl_num, 'NULL') + ', hold_flag changed from ' + CAST(ISNULL(@hold_flag, 'NULL') AS VARCHAR) + ' to 0.'
            SET @hold_flag = 0
            END
        IF @hold_flag = 0    
            SET @hold_flag = 13    
        IF (@debug_level >= 3)  
            SELECT '(3): ' + @Routine_Name + ': Before apvocrh_sp: @trx_ctrl_num = ' + RTRIM(ISNULL(@trx_ctrl_num, 'NULL'))
        --
        -- Note that 0 is passed for some of the fields.  These are amount fields that are
        -- re-calculated by imaptax_sp.
        --    
        EXEC @SP_Result = apvocrh_sp @module_id = @module_id,                    
                                     @val_mode = @val_mode,                     
                                     @trx_ctrl_num = @trx_ctrl_num OUTPUT,          
                                     @trx_type = @trx_type,                     
                                     @doc_ctrl_num = @doc_ctrl_num,                 
                                     @apply_to_num = @apply_to_num,                 
                                     @user_trx_type_code = @imaphdr_vw_user_trx_type_code,
                                     @batch_code = @batch_code,                   
                                     @po_ctrl_num = @po_ctrl_num,                  
                                     @vend_order_num = @imaphdr_vw_vend_order_num,    
                                     @ticket_num = @ticket_num,                   
                                     @date_applied = @date_applied,                 
                                     @date_aging = @date_aging,                   
                                     @date_due = @date_due,                     
                                     @date_doc = @date_doc,                     
                                     @date_entered = @date_entered,                 
                                     @date_received = @date_received,                
                                     @date_required = @date_required,                
                                     @date_recurring = @date_recurring,               
                                     @date_discount = @date_discount,                
                                     @posting_code = @posting_code,                 
                                     @vendor_code = @vendor_code,                  
                                     @pay_to_code = @pay_to_code,                  
                                     @branch_code = @branch_code,                  
                                     @class_code = @imaphdr_vw_class_code,        
                                     @approval_code = @approval_code,                
                                     @comment_code = @comment_code,                 
                                     @fob_code = @imaphdr_vw_fob_code,          
                                     @terms_code = @terms_code,                   
                                     @tax_code = @tax_code,                     
                                     @recurring_code = @imaphdr_vw_recurring_code,    
                                     @location_code = @imaphdr_vw_location_code,     
                                     @payment_code = @payment_code,                 
                                     @times_accrued = @imaphdr_vw_times_accrued,     
                                     @accrual_flag = @accrual_flag,                 
                                     @drop_ship_flag = @imaphdr_vw_drop_ship_flag,    
                                     @posted_flag = @posted_flag,                  
                                     @hold_flag = @hold_flag,                    
                                     @add_cost_flag = @imaphdr_vw_add_cost_flag,     
                                     @approval_flag = @approval_flag,                
                                     @recurring_flag = @imaphdr_vw_recurring_flag,    
                                     @one_time_vend_flag = @one_time_vend_flag,           
                                     @one_check_flag = @imaphdr_vw_one_check_flag,    
                                     @amt_gross = 0,                             
                                     @amt_discount = 0,                             
                                     @amt_tax = 0,                             
                                     @amt_freight = @imaphdr_vw_amt_freight,       
                                     @amt_misc = @imaphdr_vw_amt_misc,          
                                     @amt_net = 0,                             
                                     @amt_paid = 0,                             
                                     @amt_due = 0,                             
                                     @amt_restock = @imaphdr_vw_amt_restock,       
                                     @amt_tax_included = 0,                             
                                     @frt_calc_tax = @imaphdr_vw_frt_calc_tax,      
                                     @doc_desc = @doc_desc,                     
                                     @hold_desc = @hold_desc,                    
                                     @user_id = @Process_User_ID,                       
                                     @next_serial_id = @next_serial_id,               
                                     @pay_to_addr1 = @addr1,                        
                                     @pay_to_addr2 = @addr2,                        
                                     @pay_to_addr3 = @addr3,                        
                                     @pay_to_addr4 = @addr4,                        
                                     @pay_to_addr5 = @addr5,                        
                                     @pay_to_addr6 = @addr6,                        
                                     @attention_name = @attention_name,               
                                     @attention_phone = @attention_phone,              
                                     @intercompany_flag = @intercompany_flag,            
                                     @company_code = @company_code,                 
                                     @cms_flag = @imaphdr_vw_cms_flag,          
                                     @process_group_num = @process_group_num,            
                                     @nat_cur_code = @nat_cur_code,                 
                                     @rate_type_home = @rate_type_home,               
                                     @rate_type_oper = @rate_type_oper,               
                                     @rate_home = @rate_home,                    
                                     @rate_oper = @rate_oper,                     
                                     @net_original_amt = 0,
  				     @org_id =  @hdr_org_id ,          
				     @tax_freight_no_recoverable =  @tax_freight_no_recoverable

        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' apvocrh_sp' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        IF NOT @SP_Result = 0
            BEGIN
            EXEC im_log_sp_error_sp @ILSE_Error_Code = @SP_Result,
                                    @ILSE_SP_Name = 'apvocrh_sp',
                                    @ILSE_String = '',
                                    @ILSE_Procedure_Name = @Routine_Name,
                                    @ILSE_Log_Activity = 'YES',
                                    @im_log_sp_error_sp_User_ID = @userid
            GOTO Error_Return
            END    
        IF (@debug_level >= 3)  
            BEGIN
            SELECT '(3): ' + @Routine_Name + ': After apvocrh_sp.  Records from #apinpchg WHERE trx_ctrl_num = ' + RTRIM(ISNULL(@trx_ctrl_num, 'NULL'))
            SELECT * FROM #apinpchg 
                    WHERE RTRIM(trx_ctrl_num) = @trx_ctrl_num
            END
        


        IF @trx_type = 4091
            BEGIN
            EXEC @SP_Result = apvocra_sp @module_id,  
                                         @interface_mode,  
                                         @trx_ctrl_num, 
                                         @trx_type,  
                                         1,                                 
                                         @date_applied,  
                                         @date_due,  
                                         @date_aging,  
                                         @amt_due
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' apvocra_sp' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            IF NOT @SP_Result = 0
                BEGIN
                EXEC im_log_sp_error_sp @ILSE_Error_Code = @SP_Result,
                                        @ILSE_SP_Name = 'apvocra_sp',
                                        @ILSE_String = '',
                                        @ILSE_Procedure_Name = @Routine_Name,
                                        @ILSE_Log_Activity = 'YES',
                                        @im_log_sp_error_sp_User_ID = @userid
                GOTO Error_Return
                END    
            END
        IF (@debug_level >= 3)  
            BEGIN
            SELECT '(3): ' + @Routine_Name + ': #apinpage WHERE trx_ctrl_num = ' + ISNULL(@trx_ctrl_num, 'NULL')
            SELECT * FROM #apinpage 
                    WHERE trx_ctrl_num = @trx_ctrl_num 
            END
        


        SELECT @last_sequence_id = 0
        WHILE 1 = 1
            BEGIN
            SET ROWCOUNT 1
            SELECT @dump = source_trx_ctrl_num,
                   @sequence_id = sequence_id 
                    FROM #imapdtl_vw
                    WHERE source_trx_ctrl_num = @source_trx_ctrl_num
                            AND sequence_id > @last_sequence_id
                            AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
                    ORDER BY source_trx_ctrl_num, sequence_id
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' #imapdtl_vw 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
            SET ROWCOUNT 0
            IF (@Row_Count = 0 
                    OR @sequence_id IS NULL)
                BREAK
            SELECT @last_sequence_id = @sequence_id
            

 
            IF @trx_type = 4091
                BEGIN
                SELECT @imapdtl_vw_location_code = ISNULL(location_code, ''),
                       @po_ctrl_num = ISNULL(po_ctrl_num, ''),
                       @item_code = ISNULL(item_code, ''),
                       @qty_ordered = ISNULL(qty_ordered, 0),
                       @qty_received = ISNULL(qty_received, 0),
                       @qty_returned = ISNULL(qty_returned, 0),
                       @tax_code = ISNULL(tax_code, ''),
                       @unit_code = ISNULL(unit_code, ''), 
                       @unit_price = ISNULL(unit_price, 0), 
                       @imapdtl_vw_amt_discount = ISNULL(amt_discount, 0),
                       @amt_tax = ISNULL(amt_tax, 0),
                       @gl_exp_acct = gl_exp_acct,
                       @line_desc = ISNULL(line_desc, ''),
                       @reference_code = ISNULL(reference_code, ''),
                       @approval_code = ISNULL(approval_code,''),
                       @rec_company_code = RTRIM(LTRIM(ISNULL(ISNULL(rec_company_code, ''), ''))),
                       @imapdtl_vw_amt_freight = ISNULL(amt_freight, 0),
                       @imapdtl_vw_amt_misc = ISNULL(amt_misc, 0),
                       @imapdtl_vw_bulk_flag = ISNULL(bulk_flag, 0),
                       @imapdtl_vw_calc_tax = ISNULL(calc_tax, 0),
                       @imapdtl_vw_code_1099 = ISNULL(code_1099, @code_1099),
                       @imapdtl_vw_date_entered = date_entered,
                       @imapdtl_vw_new_gl_exp_acct = ISNULL(new_gl_exp_acct, ''),
                       @imapdtl_vw_new_reference_code = ISNULL(new_reference_code, ''),
                       @imapdtl_vw_po_orig_flag = ISNULL(po_orig_flag, 0),  
                       @imapdtl_vw_qty_prev_returned = ISNULL(qty_prev_returned, 0), 
                       @imapdtl_vw_rma_num = ISNULL(rma_num, ''),
		       @det_org_id = ISNULL(org_id, ''),
		       @amt_nonrecoverable_tax = ISNULL(amt_nonrecoverable_tax, 0),
		       @amt_tax_det = ISNULL(amt_tax_det, 0)
                        FROM #imapdtl_vw
                        WHERE source_trx_ctrl_num = @source_trx_ctrl_num
                                AND sequence_id = @sequence_id
                                AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
                SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' #imapdtl_vw 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
                END
            ELSE
                BEGIN
                

 
                SELECT @imapdtl_vw_location_code = ISNULL(location_code, ''),
                       @item_code = ISNULL(item_code, ''), 
                       @qty_returned = ISNULL(qty_returned, 0),
                       @qty_received = ISNULL(qty_received, 0),
                       @unit_code = ISNULL(unit_code, ''),
                       @unit_price = ISNULL(unit_price, 0),
                       @tax_code = ISNULL(tax_code, ''),
                       @gl_exp_acct = gl_exp_acct,
                       @imapdtl_vw_amt_discount = ISNULL(amt_discount, 0),
                       @return_code = return_code,
                       @po_ctrl_num = ISNULL(po_ctrl_num, ''),
                       @line_desc = ISNULL(line_desc, ''),
                       @reference_code = ISNULL(reference_code, ''),
                       @approval_code = ISNULL(approval_code,''),
                       @rec_company_code = RTRIM(LTRIM(ISNULL(ISNULL(rec_company_code, ''), ''))),
                       @imapdtl_vw_amt_freight = ISNULL(amt_freight, 0),
                       @imapdtl_vw_amt_misc = ISNULL(amt_misc, 0),
                       @imapdtl_vw_bulk_flag = ISNULL(bulk_flag, 0),
                       @imapdtl_vw_calc_tax = ISNULL(calc_tax, 0),
                       @imapdtl_vw_code_1099 = ISNULL(code_1099, @code_1099),
                       @imapdtl_vw_date_entered = date_entered,
                       @imapdtl_vw_new_gl_exp_acct = ISNULL(new_gl_exp_acct, ''),
                       @imapdtl_vw_new_reference_code = ISNULL(new_reference_code, ''),
                       @imapdtl_vw_po_orig_flag = ISNULL(po_orig_flag, 0),  
                       @imapdtl_vw_qty_prev_returned = ISNULL(qty_prev_returned, 0), 
                       @imapdtl_vw_rma_num = ISNULL(rma_num, ''),
		       @det_org_id = ISNULL(org_id, ''),
		       @amt_nonrecoverable_tax = ISNULL(amt_nonrecoverable_tax, 0),
		       @amt_tax_det = ISNULL(amt_tax_det, 0)
                        FROM #imapdtl_vw
                        WHERE source_trx_ctrl_num = @source_trx_ctrl_num
                                AND sequence_id = @sequence_id
                                AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
                SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' #imapdtl_vw 4' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
                END
            



                       
            IF DATALENGTH(LTRIM(RTRIM(ISNULL(@gl_exp_acct, '')))) = 0
                BEGIN
                IF (@default_exp_flag = 1)
                    BEGIN
                    SELECT @gl_exp_acct = exp_acct_code
                            FROM apvend
                            WHERE vendor_code = @vendor_code
                    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' apvend 5' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
                    END
                END
	    

    
            IF DATALENGTH(LTRIM(RTRIM(ISNULL(@det_org_id, '')))) = 0
                BEGIN
			SELECT @det_org_id = dbo.IBOrgbyAcct_fn (@gl_exp_acct)
                END
            IF DATALENGTH(LTRIM(RTRIM(ISNULL(@tax_code, '')))) = 0
                BEGIN
                IF ( @vend_tax_code IS NOT NULL)
                    SELECT @tax_code = @vend_tax_code 
                END
            IF @trx_type = 4092
                SELECT @qty_ordered = 0,
                       @amt_extended = (SIGN(@unit_price * @qty_returned) * ROUND(ABS(@unit_price * @qty_returned) + 0.0000001, @precision_gl))     
            ELSE
                SELECT @qty_returned = 0,
                       @amt_extended = (SIGN(@unit_price * @qty_received) * ROUND(ABS(@unit_price * @qty_received) + 0.0000001, @precision_gl))
            SELECT @amt_extended = ROUND(@amt_extended, @precision_gl)
            SELECT @serial_id = @sequence_id
            --
            -- If apco.aprv_voucher_flag is 1 and imaphdr.approval_code
            -- is blank then set approval_code to apco.default_aprv_code.
            --
            IF (@aprv_voucher_flag = 1)
                BEGIN
                IF (@approval_code = '')
                    BEGIN
                    SELECT @approval_code = @default_aprv_code
                    END
                END
            SELECT @company_id = company_id    
                    FROM glcomp_vw
                    WHERE RTRIM(LTRIM(ISNULL(company_code, ''))) = @rec_company_code
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' glcomp_vw 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
            IF @company_id IS NULL
                BEGIN
                SELECT @company_id = ISNULL(company_id, 0)    
                        FROM glcomp_vw
                        WHERE RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
                SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' glcomp_vw 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
                END
            SELECT @detail_date_entered = ISDATE(ISNULL(@imapdtl_vw_date_entered, 0))
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @detail_date_entered 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
            IF @detail_date_entered = 1
                BEGIN
                SELECT @detail_date_entered = datediff(dd, @January_First_Nineteen_Eighty, CONVERT(datetime, ISNULL(@imapdtl_vw_date_entered, 0))) + 722815
                SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @detail_date_entered 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
                END
            IF @detail_date_entered = 0
                SET @detail_date_entered = @date_entered    
            IF (@debug_level >= 3)  
                SELECT '(3): ' + @Routine_Name + ': Before apvocrd_sp'
            EXEC @SP_Result = apvocrd_sp @module_id,  
                                         @interface_mode,  
                                         @trx_ctrl_num, 
                                         @trx_type,  
                                         @sequence_id,  
                                         @imapdtl_vw_location_code, 
                                         @item_code,  
                                         @imapdtl_vw_bulk_flag,   
                                         @qty_ordered,  
                                         @qty_received,  
                                         @qty_returned,  
                                         @imapdtl_vw_qty_prev_returned,  
                                         @approval_code, 
                                         @tax_code,  
                                         @return_code,  
                                         @imapdtl_vw_code_1099,  
                                         @po_ctrl_num,  
                                         @unit_code, 
                                         @unit_price,
                                         @imapdtl_vw_amt_discount,
                                         @imapdtl_vw_amt_freight,
                                         @amt_tax,
                                         @imapdtl_vw_amt_misc,
                                         @amt_extended,
                                         @imapdtl_vw_calc_tax,
                                         @detail_date_entered, 
                                         @gl_exp_acct, 
                                         @imapdtl_vw_new_gl_exp_acct, 
                                         @imapdtl_vw_rma_num, 
                                         @line_desc,  
                                         @serial_id,  
                                         @company_id, 
                                         @iv_orig_flag,  
                                         @imapdtl_vw_po_orig_flag,  
                                         @rec_company_code,
                                         @new_company_code,
                                         @reference_code,  
                                         @imapdtl_vw_new_reference_code,
					 @det_org_id,
					 @amt_nonrecoverable_tax,
					 @amt_tax_det

            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' apvocrd_sp' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            IF NOT @SP_Result = 0
                BEGIN
                EXEC im_log_sp_error_sp @ILSE_Error_Code = @SP_Result,
                                        @ILSE_SP_Name = 'apvocrd_sp',
                                        @ILSE_String = '',
                                        @ILSE_Procedure_Name = @Routine_Name,
                                        @ILSE_Log_Activity = 'YES',
                                        @im_log_sp_error_sp_User_ID = @userid
                GOTO Error_Return
                END    
            IF (@debug_level >= 3)  
                SELECT '(3): ' + @Routine_Name + ': Before apvocrd_sp'
            IF (@debug_level >= 3)  
                BEGIN
                SELECT '(3): ' + @Routine_Name + ': #apinpcdt WHERE trx_ctrl_num = ' + ISNULL(@trx_ctrl_num, 'NULL') + ' AND sequence_id = ' + CAST(@sequence_id AS VARCHAR)
                SELECT * FROM #apinpcdt 
                        WHERE trx_ctrl_num = @trx_ctrl_num
                                AND sequence_id = @sequence_id 
                END
            END
        END 
    IF (@debug_level >= 3)
        BEGIN
        SELECT '(3): ' + @Routine_Name + ': Entire #apinpchg:'
        SELECT * FROM #apinpchg
        SELECT '(3): ' + @Routine_Name + ': Entire #apinpcdt:'
        SELECT * FROM #apinpcdt
        SELECT '(3): ' + @Routine_Name + ': Entire #apinptax:'
        SELECT * FROM #apinptax
        SELECT '(3): ' + @Routine_Name + ': Entire #apinpage:'
        SELECT * FROM #apinpage
        END
    


    EXEC @SP_Result = imaptax_sp '',
                                 @userid, 
                                 @debug_level
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' imaptax_sp' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    IF NOT @SP_Result = 0
        BEGIN
        EXEC im_log_sp_error_sp @ILSE_Error_Code = @SP_Result,
                                @ILSE_SP_Name = 'imaptax_sp',
                                @ILSE_String = '',
                                @ILSE_Procedure_Name = @Routine_Name,
                                @ILSE_Log_Activity = 'YES',
                                @im_log_sp_error_sp_User_ID = @userid
        GOTO Error_Return
        END    
    




    IF (@aprv_voucher_flag = 1)
            AND (@invoice_flag = 4091)
        BEGIN
        IF @debug_level >= 3
            SELECT '(3): ' + @Routine_Name + ': Voucher approval is turned on.'
        DECLARE approval_cursor CURSOR FOR
                SELECT trx_ctrl_num
                FROM #apinpchg
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DECLARE + ' approval_cursor' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
        OPEN approval_cursor
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_OPEN + ' approval_cursor' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
        FETCH NEXT 
                FROM approval_cursor
                INTO @trx_ctrl_num
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_FETCHNEXT + ' approval_cursor 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        WHILE (@@FETCH_STATUS <> -1)
            BEGIN
            IF @@FETCH_STATUS <> -2
                BEGIN
                DELETE apaprtrx 
                        WHERE trx_ctrl_num = @trx_ctrl_num
                SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DELETE + ' apaprtrx 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
                EXEC @SP_Result = imaprmk_sp 4091, 
                                             @trx_ctrl_num, 
                                             @date_entered,
                                             @debug_level,
                                             @userid
                SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' imaprmk_sp' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
                IF NOT @SP_Result = 0
                    BEGIN
                    EXEC im_log_sp_error_sp @ILSE_Error_Code = @SP_Result,
                                            @ILSE_SP_Name = 'imaprmk_sp',
                                            @ILSE_String = '',
                                            @ILSE_Procedure_Name = @Routine_Name,
                                            @ILSE_Log_Activity = 'YES',
                                            @im_log_sp_error_sp_User_ID = @userid
                    GOTO Error_Return
                    END    
                IF (@debug_level >= 3)
                    BEGIN
                    SELECT '(3): ' + @Routine_Name + ': apaprtrx WHERE trx_ctrl_num = ' + ISNULL(@trx_ctrl_num, 'NULL')
                    SELECT * FROM apaprtrx 
                            WHERE trx_ctrl_num = @trx_ctrl_num
                    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' apaprtrx' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
                    END
                FETCH NEXT 
                       FROM [approval_cursor]
                       INTO @trx_ctrl_num
                SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_FETCHNEXT + ' approval_cursor 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
                END
            END
        CLOSE [approval_cursor]
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CLOSE + ' approval_cursor' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
        DEALLOCATE [approval_cursor]
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DEALLOCATE + ' approval_cursor' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
        END
    --
    -- Sync up processed_flag in the header and detail.
    --
    UPDATE #imaphdr_vw
            SET processed_flag = d.processed_flag
            FROM [#imaphdr_vw] h
            INNER JOIN [#imapdtl_vw] d
                    ON d.[source_trx_ctrl_num] = h.[source_trx_ctrl_num]
            WHERE d.processed_flag <> 0
                    AND h.processed_flag = 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imaphdr_vw 4' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
    UPDATE #imapdtl_vw
            SET processed_flag = b.processed_flag
            FROM #imapdtl_vw a, #imaphdr_vw b
            WHERE b.processed_flag <> 0
                    AND a.source_trx_ctrl_num = b.source_trx_ctrl_num
                    AND a.processed_flag = 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imapdtl_vw 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
    --
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': Before imapint01a_sp.'
    EXEC @SP_Result = imapint01a_sp @validation_flag,
                                    @company_code,
                                    @invoice_flag,
                                    @method_flag,
                                    @close_batch_flag,
                                    @post_flag,
                                    @db_userid,
                                    @db_password,
                                    @debug_level,
                                    @perf_level,
                                    @process_ctrl_num OUTPUT,
                                    @userid,
                                    @Import_Identifier,
                                    @Process_User_ID,
                                    @User_Name
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' imapint01a_sp' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    IF NOT @SP_Result = 0
        BEGIN
        EXEC im_log_sp_error_sp @ILSE_Error_Code = @SP_Result,
                                @ILSE_SP_Name = 'imapint01a_sp',
                                @ILSE_String = '',
                                @ILSE_Procedure_Name = @Routine_Name,
                                @ILSE_Log_Activity = 'YES',
                                @im_log_sp_error_sp_User_ID = @userid
        GOTO Error_Return
        END    
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': After imapint01a_sp.'
    



    IF (@aprv_voucher_flag = 1) 
            AND (@invoice_flag = 4091) 
            AND (@method_flag <> 2)
        BEGIN
        IF @debug_level >= 3
            SELECT '(3): ' + @Routine_Name + ': Voucher approval is turned on and this is a trial import.'
        DELETE apaprtrx
                FROM apaprtrx a, #apinpchg b
                WHERE a.trx_ctrl_num = b.trx_ctrl_num
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DELETE + ' apaprtrx 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
        END
    --
    -- Some records in the perror table relating to detail records in with errors 
    -- do not have a proper value for the sequence_id column.  Setting those 0s to -1s
    -- will enable imapint01_Errors_sp to retrieve them.
    --
    UPDATE [perror]
            SET [sequence_id] = -1
            WHERE [process_ctrl_num] = @process_ctrl_num
                    AND [sequence_id] = 0
                    AND [err_code] IN (SELECT [INT Value] FROM [im_config] WHERE UPPER([Item Name]) = 'DETAIL ERROR WITHOUT SEQUENCE_ID')
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' perror 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END                
    --     
    -- imapint01_Errors_sp will compose an error message consisting of the description
    -- from aredterr appended with the value from perror.infoint if infoint is not zero
    -- (otherwise it will append a space).  This update will prevent any error messages
    -- from apearing that have an inappropriate number at the end. 
    --
    UPDATE perror
            SET [infoint] = 0
            WHERE NOT ([module_id] = @module_id AND [err_code] = 90938)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' perror 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --    
    



    SET @imapint01_sp_process_ctrl_num_Posting = ''
    IF @method_flag = 2
            AND @post_flag = 1
        BEGIN
        IF @invoice_flag IN (4091, 4093) 
            BEGIN
            EXEC @SP_Result = IMAPPostVoucher_sp @db_userid, 
                                                 @db_password, 
                                                 4091, 
                                                 @debug_level, 
                                                 @perf_level, 
                                                 @process_ctrl_num_Posting OUTPUT,
                                                 @userid,
                                                 @imapint01_sp_Application_Name,
                                                 @User_Name,
                                                 @imapint01_sp_TPS_int_value
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' IMAPPostVoucher_sp' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            IF NOT @SP_Result = 0
                BEGIN
                EXEC im_log_sp_error_sp @ILSE_Error_Code = @SP_Result,
                                        @ILSE_SP_Name = 'IMAPPostVoucher_sp',
                                        @ILSE_String = '4091',
                                        @ILSE_Procedure_Name = @Routine_Name,
                                        @ILSE_Log_Activity = 'YES',
                                        @im_log_sp_error_sp_User_ID = @userid
                RETURN -1
                END    
            END
        IF @invoice_flag IN (4092, 4093)
            BEGIN
            EXEC @SP_Result = IMAPPostVoucher_sp @db_userid, 
                                                 @db_password, 
                                                 4092, 
                                                 @debug_level, 
                                                 @perf_level, 
                                                 @process_ctrl_num_Posting OUTPUT,
                                                 @userid
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' IMAPPostVoucher_sp' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            IF NOT @SP_Result = 0
                BEGIN
                EXEC im_log_sp_error_sp @ILSE_Error_Code = @SP_Result,
                                        @ILSE_SP_Name = 'IMAPPostVoucher_sp',
                                        @ILSE_String = '4092',
                                        @ILSE_Procedure_Name = @Routine_Name,
                                        @ILSE_Log_Activity = 'YES',
                                        @im_log_sp_error_sp_User_ID = @userid
                RETURN -1
                END    
            END
        SET @imapint01_sp_process_ctrl_num_Posting = @process_ctrl_num_Posting
        END
    SET @imapint01_sp_process_ctrl_num_Validation = @process_ctrl_num
    IF @invoice_flag = 4091 
        BEGIN
        INSERT INTO imlog VALUES (getdate(), 'APVOUCHER', 1, '', '', '', 'Accounts Payable Vouchers -- Import Identifier = ' + CAST(@Import_Identifier AS VARCHAR), @userid)
        INSERT INTO imlog VALUES (getdate(), 'APVOUCHER', 1, '', '', '', 'Accounts Payable Vouchers -- process_ctrl_num (Validation) = ' + ISNULL(@process_ctrl_num, 'NULL'), @userid)
        





        
        END
    ELSE    
        BEGIN
        INSERT INTO imlog VALUES (getdate(), 'APVOUCHER', 1, '', '', '', 'Accounts Payable Debit Memos -- Import Identifier = ' + CAST(@Import_Identifier AS VARCHAR), @userid)
        INSERT INTO imlog VALUES (getdate(), 'APVOUCHER', 1, '', '', '', 'Accounts Payable Debit Memos -- process_ctrl_num (Validation) = ' + ISNULL(@process_ctrl_num, 'NULL'), @userid)
        





        
        END
    INSERT INTO imlog VALUES (getdate(), 'APVOUCHER', 1, '', '', '', 'Accounts Payable Vouchers/Debit Memos -- End', @userid)
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': Exit.'
    RETURN 0
Error_Return:
    IF @Monotonic_Cursor_Opened = 'YES'
        CLOSE Monotonic_Cursor        
    IF @Monotonic_Cursor_Allocated = 'YES'
        DEALLOCATE Monotonic_Cursor
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': Exit (ERROR).'
    RETURN -1    
GO
GRANT EXECUTE ON  [dbo].[imapint01_sp] TO [public]
GO
