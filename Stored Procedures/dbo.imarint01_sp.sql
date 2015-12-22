SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

     
    CREATE PROC 
[dbo].[imarint01_sp] @company_code VARCHAR(8), 
             @method_flag SMALLINT, 
             @print_flag SMALLINT,
             @total_flag SMALLINT, 
             @post_flag SMALLINT, 
             @invoice_flag SMALLINT, 
             @validation_flag SMALLINT, 
             @close_batch_flag SMALLINT,
             @db_userid VARCHAR(40) = 'ABSENT', 
             @db_password VARCHAR(40) = '', 
             @debug_level INT,
             @perf_level SMALLINT,
             @userid INT = 0,
             @imarint01_sp_process_ctrl_num_Validation VARCHAR(16) = '' OUTPUT,
             @imarint01_sp_process_ctrl_num_Posting VARCHAR(16) = '' OUTPUT,
             @imarint01_sp_Import_Identifier INT = 0 OUTPUT,
             @imarint01_sp_Application_Name VARCHAR(30) = 'Import Manager',
             @imarint01_sp_Override_User_Name VARCHAR(30) = '',
             @imarint01_sp_TPS_int_value INT = NULL
    AS      
    DECLARE @amt_cost FLOAT       
    DECLARE @amt_discount FLOAT       
    DECLARE @amt_discount_taken FLOAT 
    DECLARE @amt_due FLOAT
    DECLARE @amt_final_tax FLOAT
    DECLARE @amt_freight FLOAT       
    DECLARE @amt_gmd FLOAT
    DECLARE @amt_gross  FLOAT     
    DECLARE @amt_included_tax FLOAT
    DECLARE @amt_net FLOAT 
    DECLARE @amt_paid FLOAT       
    DECLARE @amt_profit FLOAT
    DECLARE @amt_rem_rev FLOAT     
    DECLARE @amt_rem_tax FLOAT  
    DECLARE @amt_tax FLOAT 
    DECLARE @amt_taxable FLOAT          
    DECLARE @amt_write_off_given FLOAT
    DECLARE @apply_date               INT
    DECLARE @apply_to_num VARCHAR(16)
    DECLARE @apply_trx_type SMALLINT
    DECLARE @arco_default_tax_type SMALLINT 
    DECLARE @artemcus_tax_code VARCHAR(8)  
    DECLARE @attention VARCHAR(40)
    DECLARE @batch_code VARCHAR(16)
    DECLARE @batch_ctrl_num VARCHAR(16) 
    DECLARE @batch_flag SMALLINT
    DECLARE @batch_type SMALLINT
    DECLARE @bill_to VARCHAR(8)  
    DECLARE @bill_to_name VARCHAR(30)
    DECLARE @buf VARCHAR(255)
    DECLARE @bulk_flag SMALLINT
    DECLARE @buyer_ref_no VARCHAR(25) 
    DECLARE @calc_tax FLOAT
    DECLARE @chDateAging VARCHAR(10)
    DECLARE @chDateApplied VARCHAR(10)
    DECLARE @chDateDoc VARCHAR(10)
    DECLARE @chDateDue VARCHAR(10)
    DECLARE @chDateShipped VARCHAR(10)
    DECLARE @comment_code VARCHAR(8)
    DECLARE @commission_flag SMALLINT
    DECLARE @credit_apr_flag SMALLINT    
    DECLARE @cur_date       INT
    DECLARE @cur_time       INT
    DECLARE @current_appdate INT
    DECLARE @cus_rev_account VARCHAR(32)
    DECLARE @cust_phone VARCHAR(30) 
    DECLARE @cust_po_num VARCHAR(25)
    DECLARE @customer_code VARCHAR(8)
    DECLARE @date_aging               INT
    DECLARE @date_aging_error CHAR(255)
    DECLARE @date_applied            INT
    DECLARE @date_applied_error CHAR(255)
    DECLARE @date_doc               INT         
    DECLARE @date_doc_error CHAR(255)
    DECLARE @date_due_error CHAR(255)
    DECLARE @date_entered            INT
    DECLARE @date_recurring        INT  
    DECLARE @date_requested         INT
    DECLARE @date_required INT
    DECLARE @date_shipped            INT
    DECLARE @date_shipped_error CHAR(255)
    DECLARE @Default_addr1 VARCHAR(40)
    DECLARE @Default_addr2 VARCHAR(40)
    DECLARE @Default_addr3 VARCHAR(40)
    DECLARE @Default_addr4 VARCHAR(40)
    DECLARE @Default_addr5 VARCHAR(40)
    DECLARE @Default_addr6 VARCHAR(40)
    DECLARE @Default_attention_name VARCHAR(40)
    DECLARE @Default_attention_phone VARCHAR(30)
    DECLARE @Default_comment_code VARCHAR(8)
    DECLARE @Default_dest_zone_code VARCHAR(8)
    DECLARE @Default_fin_chg_code VARCHAR(8)
    DECLARE @Default_fob_code VARCHAR(8)
    DECLARE @Default_freight_code VARCHAR(8)
    DECLARE @Default_nat_cur_code VARCHAR(8)
    DECLARE @Default_posting_code VARCHAR(8)
    DECLARE @Default_price_code VARCHAR(8)
    DECLARE @Default_rate_type_home VARCHAR(8)
    DECLARE @Default_rate_type_oper VARCHAR(8)
    DECLARE @Default_salesperson_code VARCHAR(8)
    DECLARE @Default_tax_code VARCHAR(8)  
    DECLARE @Default_terms_code VARCHAR(8)
    DECLARE @Default_territory_code VARCHAR(8)  
    DECLARE @Default_writeoff_code VARCHAR(8)
    DECLARE @dest_zone_code VARCHAR(8)
    DECLARE @detail_date_entered INT
    DECLARE @disc_prc FLOAT
    DECLARE @disc_prc_flag SMALLINT
    DECLARE @discount_amt FLOAT
    --DECLARE @discount_prc FLOAT
    DECLARE @divide_flag_h SMALLINT
    DECLARE @doc_ctrl_num VARCHAR(16)
    DECLARE @doc_desc VARCHAR(40)  
    DECLARE @due_date               INT 
    DECLARE @dump CHAR(16)
    DECLARE @error_flag SMALLINT    
    DECLARE @ext_ship_price FLOAT
    DECLARE @extended_price FLOAT
    DECLARE @fin_chg_code VARCHAR(8)  
    DECLARE @fob_code VARCHAR(8)
    DECLARE @freight_amt FLOAT       
    DECLARE @freight_code VARCHAR(8)  
    DECLARE @gl_rev_acct VARCHAR(32)
    DECLARE @hdr_tax_code VARCHAR(8)
    DECLARE @hold_desc VARCHAR(40)
    DECLARE @hold_flag SMALLINT
    DECLARE @home_currency CHAR(8)
    DECLARE @im_config_batch_description VARCHAR(30)
    DECLARE @im_config_Default_printed_flag INT
    DECLARE @im_config_printed_flag_Processing_Method NVARCHAR(1000)
    DECLARE @imardtl_vw_date_entered VARCHAR(10)
	DECLARE @cust_po VARCHAR(20)												
    DECLARE @imardtl_vw_new_gl_rev_acct VARCHAR(32)
    DECLARE @imardtl_vw_oe_orig_flag SMALLINT
    DECLARE @imardtl_vw_qty_prev_returned FLOAT
    DECLARE @imarhdr_vw_amt_paid FLOAT
    DECLARE @imarhdr_vw_amt_rem_rev FLOAT
    DECLARE @imarhdr_vw_amt_rem_tax FLOAT
    DECLARE @imarhdr_vw_amt_tax_included FLOAT
    DECLARE @imarhdr_vw_amt_write_off_given FLOAT
    DECLARE @imarhdr_vw_attention_name VARCHAR(40)
    DECLARE @imarhdr_vw_attention_phone VARCHAR(30)
    DECLARE @imarhdr_vw_customer_addr1 VARCHAR(40) 
    DECLARE @imarhdr_vw_customer_addr2 VARCHAR(40) 
    DECLARE @imarhdr_vw_customer_addr3 VARCHAR(40) 
    DECLARE @imarhdr_vw_customer_addr4 VARCHAR(40) 
    DECLARE @imarhdr_vw_customer_addr5 VARCHAR(40) 
    DECLARE @imarhdr_vw_customer_addr6 VARCHAR(40) 
    DECLARE @imarhdr_vw_date_entered VARCHAR(10)
    DECLARE @imarhdr_vw_date_recurring VARCHAR(10)
    DECLARE @imarhdr_vw_date_required VARCHAR(10)
    DECLARE @imarhdr_vw_dest_zone_code VARCHAR(8)
    DECLARE @imarhdr_vw_fin_chg_code VARCHAR(8)
    DECLARE @imarhdr_vw_fob_code VARCHAR(8)
    DECLARE @imarhdr_vw_freight_code VARCHAR(8)
    DECLARE @imarhdr_vw_location_code VARCHAR(8)
    DECLARE @imarhdr_vw_price_code VARCHAR(8)
    DECLARE @imarhdr_vw_printed_flag SMALLINT
    DECLARE @imarhdr_vw_ship_to_addr1 VARCHAR(40) 
    DECLARE @imarhdr_vw_ship_to_addr2 VARCHAR(40) 
    DECLARE @imarhdr_vw_ship_to_addr3 VARCHAR(40) 
    DECLARE @imarhdr_vw_ship_to_addr4 VARCHAR(40) 
    DECLARE @imarhdr_vw_ship_to_addr5 VARCHAR(40) 
    DECLARE @imarhdr_vw_ship_to_addr6 VARCHAR(40) 
    DECLARE @imarhdr_vw_source_trx_type SMALLINT 
    DECLARE @imarhdr_vw_total_weight FLOAT
    DECLARE @imarhdr_vw_vat_prc FLOAT
    DECLARE @imarhdr_vw_writeoff_code VARCHAR(8)
	DECLARE @imarhdr_vw_org_id varchar(30)				
	DECLARE @det_org_id varchar(30)						
    DECLARE @imincrh_sp_printed_flag INT
    DECLARE @inp_seq_id            INT         
    DECLARE @interface_mode SMALLINT
    DECLARE @item_code VARCHAR(30) 
    DECLARE @iv_ctrl_num VARCHAR(16) 
    DECLARE @iv_post_flag SMALLINT  
    DECLARE @last_order VARCHAR(16)
    DECLARE @last_sequence_id INT
    DECLARE @last_sqid                INT
    DECLARE @line_desc VARCHAR(60)
    DECLARE @line_freight FLOAT       
    DECLARE @line_sequence_id         INT
    DECLARE @line_serial_id        INT         
    DECLARE @location_code VARCHAR(8)  
    DECLARE @module_id SMALLINT
    DECLARE @Monotonic_Computed_sequence_id INT
    DECLARE @Monotonic_Cursor_Allocated VARCHAR(3)
    DECLARE @Monotonic_Cursor_Opened VARCHAR(3)
    DECLARE @Monotonic_Previous_source_ctrl_num VARCHAR(16)
    DECLARE @Monotonic_sequence_id INT
    DECLARE @Monotonic_source_ctrl_num VARCHAR(16)
    DECLARE @more_seq_id           INT         
    DECLARE @more_ser_id SMALLINT    
    DECLARE @nat_cur_code VARCHAR(8)
    DECLARE @new_batch_code VARCHAR(16)
    DECLARE @new_bcn VARCHAR(16)
    DECLARE @new_gl_rev_acct VARCHAR(32)
    DECLARE @new_qty_remaining FLOAT       
    DECLARE @next_serial_id SMALLINT
    DECLARE @num           INT
    DECLARE @oe_orig_flag SMALLINT
    DECLARE @ord_ctrl_num VARCHAR(16) 
    DECLARE @ord_seq VARCHAR(16) 
    DECLARE @order_ctrl_num VARCHAR(16)
    DECLARE @order_num VARCHAR(16) 
    DECLARE @Original_extended_price FLOAT
    DECLARE @outer_doc_num VARCHAR(16)
    DECLARE @position SMALLINT
    DECLARE @posted_flag SMALLINT
    DECLARE @posting_code VARCHAR(8)
    DECLARE @precision_gl SMALLINT
    DECLARE @prepay_amt FLOAT    
    DECLARE @prepay_discount FLOAT     
    DECLARE @prepay_doc_num VARCHAR(16)
    DECLARE @prestat SMALLINT
    DECLARE @price_code VARCHAR(8)
    DECLARE @pricing_date             INT
    DECLARE @printed_flag SMALLINT
    DECLARE @process_ctrl_num CHAR(16)
    DECLARE @process_ctrl_num_Posting VARCHAR(16)
    DECLARE @process_description VARCHAR(40) 
    DECLARE @process_group_num VARCHAR(16) 
    DECLARE @process_parent_app SMALLINT 
    DECLARE @process_parent_company VARCHAR(8)
    DECLARE @prompt1 VARCHAR(30)
    DECLARE @prompt2 VARCHAR(30)
    DECLARE @prompt3 VARCHAR(30)
    DECLARE @prompt4 VARCHAR(30)
    DECLARE @qty_ordered FLOAT
    DECLARE @qty_prev_returned FLOAT
    DECLARE @qty_remaining FLOAT       
    DECLARE @qty_returned FLOAT  
    DECLARE @qty_shipped FLOAT
    DECLARE @qty_to_ship FLOAT       
    DECLARE @rate_home FLOAT
    DECLARE @rate_oper FLOAT
    DECLARE @rate_type_home VARCHAR(8)
    DECLARE @rate_type_oper VARCHAR(8)
    DECLARE @recurring_code VARCHAR(8)
    DECLARE @recurring_flag SMALLINT
    DECLARE @reference_code VARCHAR(32)
    DECLARE @result                INT
    DECLARE @ret_status       INT
    DECLARE @return_code VARCHAR(8)
    DECLARE @rma_num VARCHAR(16)
    DECLARE @rowcount               INT
    DECLARE @salesperson_code VARCHAR(8)
    DECLARE @sequence_id              INT
    DECLARE @serial_id             INT
    DECLARE @ship_date             INT         
    DECLARE @ship_to VARCHAR(8)  
    DECLARE @ship_to_addr1 VARCHAR(40)
    DECLARE @ship_to_addr2 VARCHAR(40) 
    DECLARE @ship_to_addr3 VARCHAR(40)
    DECLARE @ship_to_addr4 VARCHAR(40) 
    DECLARE @ship_to_addr5 VARCHAR(40)
    DECLARE @ship_to_addr6 VARCHAR(40) 
    DECLARE @ship_to_code VARCHAR(8)
    DECLARE @ship_to_name VARCHAR(30) 
    DECLARE @ship_via_code VARCHAR(8)
    DECLARE @source_ctrl_num VARCHAR(16)
    DECLARE @source_trx_type SMALLINT
    DECLARE @spid                   INT
    DECLARE @tax_code VARCHAR(8)  
    DECLARE @tax_code_item VARCHAR(8)
    DECLARE @tax_code_vendor VARCHAR(12)
    DECLARE @tax_type_code CHAR(8)
    DECLARE @terms_code VARCHAR(8)  
    DECLARE @territory_code VARCHAR(8)  
    DECLARE @to_currency CHAR(8)
    DECLARE @total_freight FLOAT       
    DECLARE @total_tax FLOAT
    DECLARE @total_weight FLOAT       
    DECLARE @trx_ctrl_num VARCHAR(16)
    DECLARE @trx_type SMALLINT    
    DECLARE @unit_code VARCHAR(8)  
    DECLARE @unit_cost  FLOAT
    DECLARE @unit_price FLOAT
    DECLARE @User_Name VARCHAR(30)
    DECLARE @user_ref_no VARCHAR(25)
    DECLARE @val_mode SMALLINT
    DECLARE @weight FLOAT
    
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

    DELETE [imlog] WHERE UPPER([module]) = 'ARINVOICE' AND ([User_ID] = @userid OR @userid = 0)
    IF @method_flag = 2
        BEGIN
        INSERT INTO [imlog] VALUES (GETDATE(), 'ARINVOICE', 1, '', '', '', 'Accounts Receivable Invoices/Credit Memos -- Begin (Copy) -- 7.3 Service Pack 1', @userid)
        END
    ELSE
        BEGIN
        INSERT INTO [imlog] VALUES (GETDATE(), 'ARINVOICE', 1, '', '', '', 'Accounts Receivable Invoices/Credit Memos -- Begin (Validate) -- 7.3 Service Pack 1', @userid)
        END
    SET @Routine_Name = 'imarint01_sp'
    SET @Error_Table_Name = 'imicmerr_vw'
    
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
    IF @imarint01_sp_Import_Identifier = 0
            OR @imarint01_sp_Import_Identifier IS NULL
        BEGIN
        SET @imarint01_sp_Import_Identifier = @Import_Identifier
        --
        -- Purge records from the im# reporting tables.
        --
        EXEC @SP_Result = [CVO_Control]..imreportdata_clear_sp @imreportdata_clear_sp_T1 = 'im#imarhdr',
                                                            @imreportdata_clear_sp_T2 = 'im#imardtl',
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
        SET @Import_Identifier = @imarint01_sp_Import_Identifier
        END    
    
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
    EXEC @SP_Result = imarint01_Verify_Key_Data_sp @debug_level = @debug_level,
                                                   @userid = @userid
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' imarint01_Verify_Key_Data_sp 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Get Epicor User ID.
    --
    EXEC @SP_Result = imObtain_User_ID_sp @imObtain_User_ID_sp_Module = 'ARINVOICE',
                                          @imObtain_User_ID_sp_User_ID = @Process_User_ID OUT,
                                          @imObtain_User_ID_sp_User_Name = @User_Name OUT,
                                          @userid = @userid,
                                          @imObtain_User_ID_sp_Override_User_Name = @imarint01_sp_Override_User_Name
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' imObtain_User_ID_sp' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    IF NOT @SP_Result = 0
        BEGIN
        EXEC im_log_sp_error_sp @ILSE_Error_Code = @SP_Result,
                                @ILSE_SP_Name = 'imObtain_User_ID_sp',
                                @ILSE_String = '',
                                @ILSE_Procedure_Name = @Routine_Name,
                                @ILSE_Log_Activity = 'YES'
        GOTO Error_Return
        END
    --    
    SET @company_code = RTRIM(LTRIM(ISNULL(@company_code, '')))
    --
    -- Validate parameters.
    --    
    IF NOT @invoice_flag = 2031
            AND NOT @invoice_flag = 2032
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
    -- Create temp tables
    --
    















create table #arinpcdt 
(
	link			varchar(16) NULL,
	trx_ctrl_num	 	varchar(16) NULL,
	doc_ctrl_num	 	varchar(16) NULL,
	sequence_id	 	int NULL,
	trx_type	 	smallint NULL,
	location_code	 	varchar(8) NULL,
	item_code	 	varchar(30) NULL,
	bulk_flag	 	smallint NULL,
	date_entered	 	int NULL,
	line_desc	 	varchar(60) NULL,
	qty_ordered	 	float NULL,
	qty_shipped	 	float NULL,
	unit_code	 	varchar(8) NULL,
	unit_price	 	float,
	unit_cost	 	float NULL,
	weight	 		float NULL,
	serial_id	 	int NULL,
	tax_code	 	varchar(8) NULL,
	gl_rev_acct	 	varchar(32) NULL,
	disc_prc_flag	 	smallint NULL,
	discount_amt	 	float NULL,
	commission_flag	smallint NULL,
	rma_num		varchar(16) NULL,
	return_code	 	varchar(8) NULL,
	qty_returned	 	float NULL,
	qty_prev_returned	float NULL,
	new_gl_rev_acct	varchar(32) NULL,
	iv_post_flag	 	smallint NULL,
	oe_orig_flag	 	smallint NULL,
	discount_prc		float NULL,	
	extended_price	float NULL,	
	calc_tax		float NULL,
	reference_code	varchar(32)	NULL,
	trx_state		smallint	NULL,
	mark_flag		smallint	NULL,
	cust_po 		VARCHAR(20) NULL,	
	new_reference_code	varchar(32) NULL,
	org_id 			varchar(30) NULL
)

CREATE INDEX arinpcdt_ind_0 
	ON #arinpcdt ( trx_ctrl_num, trx_type, sequence_id )

    
CREATE TABLE #arinpage
(
	trx_ctrl_num		varchar(16),
	sequence_id		int,	
	doc_ctrl_num		varchar(16),
	apply_to_num		varchar(16),
	apply_trx_type	smallint,
	trx_type		smallint,
	date_applied		int,
	date_due		int,
	date_aging		int,
	customer_code		varchar(8),
	salesperson_code	varchar(8),
	territory_code	varchar(8),
	price_code		varchar(8),
	amt_due		float,
	trx_state		smallint	NULL,
	mark_flag		smallint	NULL
)


CREATE UNIQUE INDEX arinpage_ind_0 
ON #arinpage ( trx_ctrl_num, trx_type, sequence_id )

    

















CREATE TABLE #arinpchg
(
  link      varchar(16) NULL,
  trx_ctrl_num    varchar(16) NULL,
  doc_ctrl_num    varchar(16) NULL,
  doc_desc    varchar(40) NULL,
  apply_to_num    varchar(16) NULL,
  apply_trx_type  smallint NULL,
  order_ctrl_num  varchar(16) NULL,
  batch_code    varchar(16) NULL,
  trx_type    smallint NULL,
  date_entered    int NULL,
  date_applied    int NULL,
  date_doc    int NULL,
  date_shipped    int NULL,
  date_required   int NULL,
  date_due    int NULL,
  date_aging    int NULL,
  customer_code   varchar(8),
  ship_to_code    varchar(8) NULL,
  salesperson_code  varchar(8) NULL,
  territory_code  varchar(8) NULL,
  comment_code    varchar(8) NULL,
  fob_code    varchar(8) NULL,
  freight_code    varchar(8) NULL,
  terms_code    varchar(8) NULL,
  fin_chg_code    varchar(8) NULL,
  price_code    varchar(8) NULL,
  dest_zone_code  varchar(8) NULL,
  posting_code    varchar(8) NULL,
  recurring_flag  smallint NULL,
  recurring_code  varchar(8) NULL,
  tax_code    varchar(8) NULL,
  cust_po_num   varchar(20) NULL,
  total_weight    float NULL,
  amt_gross   float NULL,
  amt_freight   float NULL,
  amt_tax   float NULL,
  amt_tax_included  float NULL,
  amt_discount    float NULL,
  amt_net   float NULL,
  amt_paid    float NULL,
  amt_due   float NULL,
  amt_cost    float NULL,
  amt_profit    float NULL,
  next_serial_id  smallint NULL,
  printed_flag    smallint NULL,
  posted_flag   smallint NULL,
  hold_flag   smallint NULL,
  hold_desc   varchar(40) NULL,
  user_id   smallint NULL,
  customer_addr1  varchar(40) NULL,
  customer_addr2  varchar(40) NULL,
  customer_addr3  varchar(40) NULL,
  customer_addr4  varchar(40) NULL,
  customer_addr5  varchar(40) NULL,
  customer_addr6  varchar(40) NULL,
  ship_to_addr1   varchar(40) NULL,
  ship_to_addr2   varchar(40) NULL,
  ship_to_addr3   varchar(40) NULL,
  ship_to_addr4   varchar(40) NULL,
  ship_to_addr5   varchar(40) NULL,
  ship_to_addr6   varchar(40) NULL,
  attention_name  varchar(40) NULL,
  attention_phone varchar(30) NULL,
  amt_rem_rev   float NULL,
  amt_rem_tax   float NULL,
  date_recurring  int NULL,
  location_code   varchar(8) NULL,
  process_group_num varchar(16) NULL,
  trx_state   smallint NULL,
  mark_flag   smallint   NULL,
  amt_discount_taken  float NULL,
  amt_write_off_given float NULL, 
  source_trx_ctrl_num varchar(16) NULL,
  source_trx_type smallint NULL,
  nat_cur_code    varchar(8) NULL,  
  rate_type_home  varchar(8) NULL,  
  rate_type_oper  varchar(8) NULL,  
  rate_home   float NULL, 
  rate_oper   float NULL, 
  edit_list_flag  smallint NULL,
  ddid      varchar(32) NULL,
  writeoff_code	varchar(8)	NULL DEFAULT '',
  [vat_prc] FLOAT NULL,
  org_id	varchar(30)	NULL
)

CREATE INDEX #arinpchg_ind_0 
ON #arinpchg ( trx_ctrl_num, trx_type )
CREATE INDEX  #arinpchg_ind_1 
ON  #arinpchg (batch_code)

    




















CREATE TABLE #arinpcom
(
	trx_ctrl_num	varchar(16),
	trx_type	smallint,
	sequence_id	int,
	salesperson_code	varchar(8),
	amt_commission	float,
	percent_flag	smallint,
	exclusive_flag	smallint,
	split_flag	smallint, 
	trx_state smallint NULL,
	mark_flag smallint NULL
	)

CREATE UNIQUE INDEX arinpcom_ind_0 
ON #arinpcom ( trx_ctrl_num, trx_type, sequence_id )

    


















CREATE TABLE #arinptax
(
	trx_ctrl_num	varchar(16),
	trx_type	smallint,
	sequence_id	int,
	tax_type_code	varchar(8),
	amt_taxable	float,
	amt_gross	float,
	amt_tax	float,
	amt_final_tax	float,
	trx_state 	smallint	NULL,
	mark_flag 	smallint	NULL
)

CREATE UNIQUE INDEX arinptax_ind_0 
	ON #arinptax ( trx_ctrl_num, trx_type, sequence_id )

    















CREATE TABLE #arinbat
(
	date_applied		int, 
	process_group_num	varchar(16),
	trx_type		smallint,
	batch_ctrl_num char(16) NULL,
	flag			smallint
)

    
CREATE TABLE #aritemp
(
	code varchar(8),
	code2 varchar(8),
	mark_flag	smallint,
	amt_home float,
	amt_oper float
)

    
CREATE TABLE #arbatnum
(
	date_applied		int,
	process_group_num	varchar(16),
	trx_type		smallint,
	flag			smallint,
	batch_ctrl_num		char(16) NULL,
	batch_description   char(30)            NULL,
	company_code        char(8)             NULL,
	seq			numeric identity
)

    
CREATE TABLE #arbatsum
(
	batch_ctrl_num char(16) NOT NULL,
	actual_number int NOT NULL,
	actual_total float NOT NULL
)

    






CREATE TABLE #arinptmp
(
        timestamp		timestamp,
	trx_ctrl_num		varchar(16),	
	doc_ctrl_num		varchar(16),	
	trx_desc		varchar(40),
	date_doc		int,
        customer_code		varchar(8),
	payment_code		varchar(8),
        amt_payment		float,
	prompt1_inp		varchar(30),
	prompt2_inp		varchar(30),
	prompt3_inp		varchar(30),
	prompt4_inp		varchar(30),
	amt_disc_taken		float,
	cash_acct_code		varchar(32)
)


    --
    --  Initialize variables
    --
    SELECT @module_id = 2000,
           @val_mode = 2,
           @doc_ctrl_num = '',
           @apply_to_num = '',
           @apply_trx_type = 0,
           @batch_code = '',
           @recurring_flag = 0,
           @recurring_code = '',
           @next_serial_id = 1,
           @posted_flag = 0,
           @process_group_num = '', 
           @amt_discount_taken = 0, 
           @source_ctrl_num = '',
           @date_shipped = 0,
           @amt_cost = 0,
           @amt_profit = 0,
           @tax_code =  '',
           @interface_mode = 2,   
           @rma_num = '',
           @line_desc = '',
           @qty_returned = 0,  
           @unit_cost = 0,
           @weight = 0,
           @spid = @@spid,
           @tax_code_vendor = '',
           @reference_code = ''
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @module_id 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END  
    SELECT @im_config_batch_description = RTRIM(LTRIM(ISNULL(UPPER(ISNULL([Text Value], 'Import Manager Batch')), '')))
            FROM [CVO_Control]..[im_config]
            WHERE RTRIM(LTRIM(ISNULL(UPPER([Item Name]), ''))) = 'BATCH DESCRIPTION'
                    AND [INT Value] = @Process_User_ID
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' im_config 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
    SELECT @im_config_printed_flag_Processing_Method = RTRIM(LTRIM(ISNULL(UPPER(ISNULL([Text Value], '')), '')))
            FROM [im_config]
            WHERE RTRIM(LTRIM(ISNULL(UPPER([Item Name]), ''))) = 'PRINTED_FLAG PROCESSING METHOD'
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' im_config 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': printed_flag Processing Method = ''' + @im_config_printed_flag_Processing_Method + ''''
    IF @im_config_printed_flag_Processing_Method = 'NEW'    
        BEGIN    
        SELECT @im_config_Default_printed_flag = ISNULL([INT Value], 0)
                FROM [im_config]
                WHERE RTRIM(LTRIM(ISNULL(UPPER([Item Name]), ''))) = 'DEFAULT PRINTED_FLAG'
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' im_config 4' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
        IF NOT @im_config_Default_printed_flag = 0
                AND NOT @im_config_Default_printed_flag = 1
            BEGIN
            EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = 'Invalid im_config.Default printed_flag', 
                                                         @IGES_String = @External_String OUT 
            EXEC im_log_sp @IL_Text = @External_String,
                           @IL_Log_Activity = 'YES',
                           @im_log_sp_User_ID = @userid
            GOTO Error_Return    
            END    
        END
    ELSE
        BEGIN
        IF NOT @print_flag = 0
                AND NOT @print_flag = 1
            BEGIN    
            EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = 'Invalid @print_flag', 
                                                         @IGES_String = @External_String OUT 
            EXEC im_log_sp @IL_Text = @External_String,
                           @IL_Log_Activity = 'YES',
                           @im_log_sp_User_ID = @userid
            GOTO Error_Return    
            END
        SET @imincrh_sp_printed_flag = @print_flag
        END
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': Default printed_flag = ''' + CAST(@im_config_Default_printed_flag AS VARCHAR) + ''''
    SELECT @arco_default_tax_type = [default_tax_type] 
            FROM [arco]
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @arco_default_tax_type 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    IF NOT @arco_default_tax_type = 0
            AND NOT @arco_default_tax_type = 1
            AND NOT @arco_default_tax_type = 2
        BEGIN
        EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = 'Invalid Default Tax Type', 
                                                     @IGES_String = @External_String OUT 
        EXEC im_log_sp @IL_Text = @External_String,
                       @IL_Log_Activity = 'YES',
                       @im_log_sp_User_ID = @userid
        GOTO Error_Return    
        END     
    SELECT @artemcus_tax_code = [tax_code]
            FROM [artemcus] 
            INNER JOIN [arco] 
                    ON [artemcus].template_code = [arco].template_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @artemcus_tax_code 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END           
    IF DATALENGTH(LTRIM(RTRIM(ISNULL(@artemcus_tax_code, '')))) = 0
        BEGIN
        EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = 'Invalid Default Tax Code', 
                                                     @IGES_String = @External_String OUT 
        EXEC im_log_sp @IL_Text = @External_String,
                       @IL_Log_Activity = 'YES',
                       @im_log_sp_User_ID = @userid
        GOTO Error_Return
        END
    EXEC @SP_Result = appdate_sp @current_appdate OUTPUT 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' appdate_sp 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    IF @SP_Result = 0
        BEGIN
        EXEC im_log_sp_error_sp @ILSE_Error_Code = @SP_Result,
                                @ILSE_SP_Name = 'appdate_sp',
                                @ILSE_String = '@current_appdate',
                                @ILSE_Procedure_Name = @Routine_Name,
                                @ILSE_Log_Activity = 'YES',
                                @im_log_sp_error_sp_User_ID = @userid
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
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': Reset processed_flag = ''' + @Reset_processed_flag + ''''
    IF @Reset_processed_flag = 'YES'
        BEGIN
        UPDATE [imarhdr_vw]
                SET [processed_flag] = 0
                    WHERE ([processed_flag] = 2 OR [processed_flag] IS NULL)
                        AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
                        AND [trx_type] = @invoice_flag
                        AND ([User_ID] = @userid OR @userid = 0)
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imarhdr_vw 1A' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        UPDATE [imardtl_vw]
                SET [processed_flag] = 0
                    WHERE ([processed_flag] = 2 OR [processed_flag] IS NULL)
                        AND RTRIM(LTRIM(ISNULL([company_code], ''))) = @company_code
                        AND [trx_type] = @invoice_flag
                        AND ([User_ID] = @userid OR @userid = 0)
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imardtl_vw 1A' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        END    
    --
    -- Get the "Allow Import of trx_ctrl_num" config table entry.
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
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': Allow Import of trx_ctrl_num = ''' + @Allow_Import_of_trx_ctrl_num + ''''
    




        
    SELECT * 
            INTO [#imarhdr_vw]
            FROM [imarhdr_vw] 
            WHERE RTRIM(LTRIM(ISNULL([company_code], ''))) = @company_code
                    AND [trx_type] = @invoice_flag
                    AND (NOT [processed_flag] = 1 OR [processed_flag] IS NULL)
                    AND ([User_ID] = @userid OR @userid = 0)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' #imarhdr_vw 1A' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    SELECT *
            INTO [#imardtl_vw]
            FROM [imardtl_vw]  
            WHERE RTRIM(LTRIM(ISNULL([company_code], ''))) = @company_code
                    AND [trx_type] = @invoice_flag
                    AND (NOT [processed_flag] = 1 OR [processed_flag] IS NULL)
                    AND ([User_ID] = @userid OR @userid = 0)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' #imardtl_vw 1A' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE [#imarhdr_vw]
            SET [processed_flag] = 0     
    UPDATE [#imardtl_vw]
            SET [processed_flag] = 0     
    CREATE UNIQUE INDEX imarhdr_vw_Index_1 ON #imarhdr_vw 
            (company_code,
            source_ctrl_num) 
    --
    -- The trx_ctrl_num column is ignored.  Set it to an empty string.
    --
    IF NOT @Allow_Import_of_trx_ctrl_num = 'YES'
        BEGIN
        UPDATE #imarhdr_vw
                SET trx_ctrl_num = ''
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarhdr_vw 9' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        UPDATE #imardtl_vw
                SET trx_ctrl_num = ''
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imardtl_vw 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        END
    --    
    CREATE UNIQUE INDEX imardtl_vw_Index_1 ON #imardtl_vw
            (company_code,
            source_ctrl_num,
            sequence_id)
    --
    -- Set the [Import Identifier] column.
    --
    UPDATE [imarhdr_vw]
            SET [Import Identifier] = @Import_Identifier
            WHERE RTRIM(LTRIM(ISNULL([company_code], ''))) = @company_code
                    AND [trx_type] = @invoice_flag
                    AND (NOT [processed_flag] = 1 OR [processed_flag] IS NULL)
                    AND ([User_ID] = @userid OR @userid = 0)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imarhdr_vw 2A' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    UPDATE [imardtl_vw]
            SET [Import Identifier] = @Import_Identifier
            WHERE RTRIM(LTRIM(ISNULL([company_code], ''))) = @company_code
                    AND [trx_type] = @invoice_flag
                    AND (NOT [processed_flag] = 1 OR [processed_flag] IS NULL)
                    AND ([User_ID] = @userid OR @userid = 0)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imardtl_vw 2A' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    --
    -- Verify that the sequence_id values are monotonically increasing.
    --
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': Begin checking for monotonically-increasing sequence ids'
    SELECT DISTINCT source_ctrl_num, 
           cnt = COUNT(*), 
           maxid = MAX(sequence_id), 
           flg = 0
            INTO #temp_imarintsp
            FROM #imardtl_vw
            WHERE RTRIM(LTRIM(ISNULL([company_code], ''))) = @company_code      
            GROUP BY source_ctrl_num
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' #temp_imarintsp 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
    UPDATE #imarhdr_vw 
            SET processed_flag = 2
            FROM #imarhdr_vw a, #temp_imarintsp b
            WHERE a.source_ctrl_num = b.source_ctrl_num 
                    AND b.cnt <> b.maxid
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarhdr_vw 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
    INSERT INTO perror (process_ctrl_num, batch_code, module_id, err_code, info1, info2, infoint, infofloat, flag1, trx_ctrl_num, sequence_id, source_ctrl_num, extra ) 
            SELECT 'imarint01temp', '', @module_id, 20940, source_ctrl_num, '', 0, 0.0, 0, '', 0, source_ctrl_num, 0
                    FROM #temp_imarintsp
                    WHERE cnt <> maxid
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' perror 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    IF @Row_Count > 0
        BEGIN
        DECLARE Monotonic_Cursor INSENSITIVE CURSOR FOR 
                SELECT source_ctrl_num, sequence_id 
                FROM [#imardtl_vw] 
                ORDER BY source_ctrl_num, sequence_id
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DECLARE + ' Monotonic_Cursor 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
        SET @Monotonic_Cursor_Allocated = 'YES'        
        OPEN Monotonic_Cursor
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_OPEN + ' Monotonic_Cursor 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
        SET @Monotonic_Cursor_Opened = 'YES'        
        FETCH NEXT
                FROM Monotonic_Cursor
                INTO @Monotonic_source_ctrl_num, @Monotonic_sequence_id
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_FETCHNEXT + ' Monotonic_Cursor 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
        SET @Monotonic_Previous_source_ctrl_num = @Monotonic_source_ctrl_num
        SET @Monotonic_Computed_sequence_id = 0
        WHILE NOT @@FETCH_STATUS = -1
            BEGIN
            SET @Monotonic_Computed_sequence_id = @Monotonic_Computed_sequence_id + 1
            IF @Monotonic_source_ctrl_num = @Monotonic_Previous_source_ctrl_num
                BEGIN
                IF NOT @Monotonic_sequence_id = @Monotonic_Computed_sequence_id
                    BEGIN
                    UPDATE perror
                            SET infoint = @Monotonic_Computed_sequence_id - 1
                            WHERE process_ctrl_num = 'imarint01temp'
                                    AND source_ctrl_num = @Monotonic_source_ctrl_num 
                    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' perror 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
                    END
                END
            ELSE
                BEGIN
                SET @Monotonic_Computed_sequence_id = 1
                SET @Monotonic_Previous_source_ctrl_num = @Monotonic_source_ctrl_num
                END
            FETCH NEXT
                    FROM Monotonic_Cursor
                    INTO @Monotonic_source_ctrl_num, @Monotonic_sequence_id
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
        SELECT '(3): ' + @Routine_Name + ': End of sequence ID check.  source_ctrl_num for records with bad sequences:'
        SELECT * 
                FROM #temp_imarintsp
                WHERE NOT [cnt] = [maxid]
        END
    DROP TABLE #temp_imarintsp
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DROPTABLE + ' #temp_imarintsp 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END   
    --    
    BEGIN SELECT @date_applied_error = ISNULL(err_desc, 'Invalid date_applied') FROM aredterr WHERE e_code = 20935 INSERT INTO perror (process_ctrl_num, batch_code, module_id, err_code, info1, info2, infoint, infofloat, flag1, trx_ctrl_num, sequence_id, source_ctrl_num, extra ) SELECT 'imarint01temp', '', @module_id, 20935, date_applied, source_ctrl_num, 0, 0.0, 0, source_ctrl_num, 0, source_ctrl_num, 0 FROM #imarhdr_vw WHERE (ISDATE(date_applied) = 0 AND date_applied <> '') AND trx_type = @invoice_flag AND company_code = @company_code AND processed_flag = 0 END
    BEGIN SELECT @date_doc_error = ISNULL(err_desc, 'Invalid document_date') FROM aredterr WHERE e_code = 20936 INSERT INTO perror (process_ctrl_num, batch_code, module_id, err_code, info1, info2, infoint, infofloat, flag1, trx_ctrl_num, sequence_id, source_ctrl_num, extra ) SELECT 'imarint01temp', '', @module_id, 20936, date_doc, source_ctrl_num, 0, 0.0, 0, source_ctrl_num, 0, source_ctrl_num, 0 FROM #imarhdr_vw WHERE (ISDATE(date_doc) = 0 AND date_doc <> '') AND trx_type = @invoice_flag AND company_code = @company_code AND processed_flag = 0 END
    BEGIN SELECT @date_due_error = ISNULL(err_desc, 'Invalid due_date') FROM aredterr WHERE e_code = 20937 INSERT INTO perror (process_ctrl_num, batch_code, module_id, err_code, info1, info2, infoint, infofloat, flag1, trx_ctrl_num, sequence_id, source_ctrl_num, extra ) SELECT 'imarint01temp', '', @module_id, 20937, date_due, source_ctrl_num, 0, 0.0, 0, source_ctrl_num, 0, source_ctrl_num, 0 FROM #imarhdr_vw WHERE (ISDATE(date_due) = 0 AND date_due <> '') AND trx_type = @invoice_flag AND company_code = @company_code AND processed_flag = 0 END
    BEGIN SELECT @date_shipped_error = ISNULL(err_desc, 'Invalid date_shipped') FROM aredterr WHERE e_code = 20938 INSERT INTO perror (process_ctrl_num, batch_code, module_id, err_code, info1, info2, infoint, infofloat, flag1, trx_ctrl_num, sequence_id, source_ctrl_num, extra ) SELECT 'imarint01temp', '', @module_id, 20938, date_shipped, source_ctrl_num, 0, 0.0, 0, source_ctrl_num, 0, source_ctrl_num, 0 FROM #imarhdr_vw WHERE (ISDATE(date_shipped) = 0 AND date_shipped <> '') AND trx_type = @invoice_flag AND company_code = @company_code AND processed_flag = 0 END
    BEGIN SELECT @date_aging_error = ISNULL(err_desc, 'Invalid date_aging') FROM aredterr WHERE e_code = 20939 INSERT INTO perror (process_ctrl_num, batch_code, module_id, err_code, info1, info2, infoint, infofloat, flag1, trx_ctrl_num, sequence_id, source_ctrl_num, extra ) SELECT 'imarint01temp', '', @module_id, 20939, date_aging, source_ctrl_num, 0, 0.0, 0, source_ctrl_num, 0, source_ctrl_num, 0 FROM #imarhdr_vw WHERE (ISDATE(date_aging) = 0 AND date_aging <> '') AND trx_type = @invoice_flag AND company_code = @company_code AND processed_flag = 0 END
    IF @debug_level >= 3
        BEGIN
        SELECT '(3): ' + @Routine_Name + ': Dump of perror after DATE_PROTECT:'
        SELECT * FROM perror 
                WHERE process_ctrl_num = 'imarint01temp'
        END
    --
    -- Default the tax code in the header staging table.  @arco_default_tax_type values are
    -- as follows:
    --     0 -- Get the default value from arcust or, if a ship-to code was provided, 
    --          get the default value from arshipto.  Note that arcust and arshipto are
    --          both views on the armaster table.  In the UPDATE statement, a ship_to_code
    --          provided in the header staging table would cause the JOIN to join records
    --          in armaster that also had a value in the ship_to_code column (effectively
    --          the arshipto view), and no value in the staging heder table would join records
    --          in armaster that also do not have a value in the ship_to_column (effectively
    --          the arcust view).
    --          in the  
    --     1 -- Undefined in this context
    --     2 -- Get the default value from artemcus  
    --
    IF @arco_default_tax_type = 0
        BEGIN
        UPDATE [#imarhdr_vw]
                SET [tax_code] = a.[tax_code]
                FROM [#imarhdr_vw] h
                INNER JOIN [armaster] a
                        ON a.[customer_code] = h.[customer_code]
			                    AND RTRIM(LTRIM(ISNULL(a.[ship_to_code], ''))) = RTRIM(LTRIM(ISNULL(h.[ship_to_code], '')))
                WHERE DATALENGTH(LTRIM(RTRIM(ISNULL(h.[tax_code], '')))) = 0
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarhdr_vw 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
        END
    IF @arco_default_tax_type = 2
        BEGIN
        UPDATE #imarhdr_vw
                SET tax_code = @artemcus_tax_code
                WHERE DATALENGTH(LTRIM(RTRIM(ISNULL(tax_code, '')))) = 0
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarhdr_vw 4' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
        END
    UPDATE [#imarhdr_vw]
            SET [tax_code] = @artemcus_tax_code
            WHERE DATALENGTH(LTRIM(RTRIM(ISNULL([tax_code], '')))) = 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarhdr_vw 5' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
    IF (@debug_level >= 3)  
        BEGIN
        SELECT '(3): ' + @Routine_Name + ': Done updating default rate types.'
        END
    SELECT @precision_gl = 2
    SELECT @precision_gl = curr_precision
            FROM glco, glcurr_vw
            WHERE glco.home_currency = glcurr_vw.currency_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @precision_gl' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
    -- 
    -- Get the first invoice 
    --
    SELECT @ship_to_name = '',    
           @buyer_ref_no = '',    
           @amt_freight = 0,  
           @user_ref_no = '',
           @unit_code = '',
           @amt_gross = 0,
           @amt_tax = 0,
           @amt_discount = 0,
           @amt_net = 0,
           @amt_due = 0,
           @amt_profit = 0,
           @total_freight = 0,
           @total_tax = 0,
           @inp_seq_id = 0, 
           @amt_included_tax = 0,
           @rma_num = '', 
           @return_code = '',  
           @iv_post_flag = 0,  
           @qty_returned = 0,  
           @unit_cost = 0 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @ship_to_name' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
    SELECT @order_num = ''
    SELECT @outer_doc_num = ''
    IF (@debug_level >= 3)  
        BEGIN
        SELECT '(3): ' + @Routine_Name + ': Begin pseudo cursor'
        END
    WHILE ( 1 = 1 )
        BEGIN 
        SET ROWCOUNT 1
        -- 
        -- Check if the transaction selected is 'invoice' 
        --
        IF @invoice_flag IN (2032, 2031)      
            BEGIN
            SELECT @source_ctrl_num = source_ctrl_num,
                   @bill_to = customer_code,
                   @ship_to = ship_to_code
                    FROM #imarhdr_vw
                    WHERE source_ctrl_num > @outer_doc_num
                            AND (processed_flag = 0 OR processed_flag IS NULL)
                            AND trx_type = @invoice_flag
                            AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
                    ORDER BY source_ctrl_num
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' #imarhdr_vw 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
            END
        ELSE
            BEGIN
            SELECT @source_ctrl_num = source_ctrl_num,
                   @bill_to = customer_code,
                   @ship_to = ship_to_code
                    FROM #imarhdr_vw
                    WHERE source_ctrl_num > @outer_doc_num
                            AND (processed_flag = 0 OR processed_flag IS NULL)
                            AND trx_type IN (2031, 2032)
                            AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
                    ORDER BY source_ctrl_num
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' #imarhdr_vw 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
            END
        SET ROWCOUNT 0
        IF (@Row_Count = 0) 
            BREAK
        SELECT @outer_doc_num = @source_ctrl_num
        --
        -- Get defaults from arcust.
        --                       
        IF EXISTS (SELECT 1 FROM arcust WHERE customer_code = @bill_to)
            BEGIN
            SELECT @bill_to_name = ISNULL(customer_name, ''),
                   @Default_territory_code = ISNULL(territory_code, ''),
                   @Default_salesperson_code = ISNULL(salesperson_code, ''),
                   @Default_tax_code = ISNULL(tax_code, ''),
                   @Default_terms_code = ISNULL(terms_code, ''),
                   @Default_posting_code = ISNULL(posting_code, ''),
                   @Default_comment_code = ISNULL(inv_comment_code, ''),
                   @Default_rate_type_home =  ISNULL(rate_type_home, ''),
                   @Default_rate_type_oper =  ISNULL(rate_type_oper, ''),
                   @Default_nat_cur_code = ISNULL(nat_cur_code, ''),
                   @Default_attention_name = ISNULL(attention_name, ''),
                   @Default_attention_phone = ISNULL(attention_phone, ''),
                   @Default_addr1 = ISNULL(addr1, ''),
                   @Default_addr2 = ISNULL(addr2, ''),
                   @Default_addr3 = ISNULL(addr3, ''),
                   @Default_addr4 = ISNULL(addr4, ''),
                   @Default_addr5 = ISNULL(addr5, ''),
                   @Default_addr6 = ISNULL(addr6, ''),
                   @Default_dest_zone_code = ISNULL(dest_zone_code, ''),
                   @Default_fin_chg_code = ISNULL(fin_chg_code, ''),
                   @Default_fob_code = ISNULL(fob_code, ''),
                   @Default_freight_code = ISNULL(freight_code, ''),
                   @Default_price_code = ISNULL(price_code, ''),
                   @Default_writeoff_code = ISNULL([writeoff_code], '')
                    FROM arcust
                    WHERE customer_code = @bill_to
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' arcust 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
            END
        ELSE
            BEGIN
            SELECT @bill_to_name = '',
                   @Default_territory_code ='',
                   @Default_salesperson_code= '',
                   @Default_tax_code = '',
                   @Default_terms_code = '',
                   @Default_posting_code = '',
                   @Default_comment_code = '',
                   @Default_rate_type_home = '',
                   @Default_rate_type_oper = '',
                   @Default_nat_cur_code = '',
                   @Default_attention_name = '',
                   @Default_attention_phone = '',
                   @Default_addr1 = '',
                   @Default_addr2 = '',
                   @Default_addr3 = '',
                   @Default_addr4 = '',
                   @Default_addr5 = '',
                   @Default_addr6 = '',
                   @Default_dest_zone_code = '',
                   @Default_fin_chg_code = '',
                   @Default_fob_code = '',
                   @Default_freight_code = '',
                   @Default_price_code = '',
                   @Default_writeoff_code = ''
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @bill_to_name 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
            END
        --
        -- Get defaults from arshipto.
        --                       
        IF NOT DATALENGTH(LTRIM(RTRIM(ISNULL(@ship_to, '')))) = 0
            BEGIN
            SELECT @ship_to_name = ISNULL(ship_to_name, ''),
                   @ship_to_addr1 = ISNULL(addr1, ''),
                   @ship_to_addr2 = ISNULL(addr2, ''),
                   @ship_to_addr3 = ISNULL(addr3, ''),
                   @ship_to_addr4 = ISNULL(addr4, ''),
                   @ship_to_addr5 = ISNULL(addr5, ''), 
                   @ship_to_addr6 = ISNULL(addr6, ''),
                   @Default_attention_name = ISNULL(attention_name, ''),
                   @Default_attention_phone = ISNULL(attention_phone, ''),
                   @Default_posting_code = ISNULL(posting_code, ''),
                   @Default_terms_code = ISNULL(terms_code, ''),
                   @Default_tax_code = ISNULL(tax_code, ''),
                   @Default_salesperson_code = ISNULL(salesperson_code, ''),
                   @Default_territory_code = ISNULL(territory_code, ''),
                   @Default_fob_code = ISNULL(fob_code, ''),
                   @Default_dest_zone_code = ISNULL(dest_zone_code, ''),
                   @Default_freight_code = ISNULL(freight_code, ''),
                   @Default_rate_type_home =  ISNULL(rate_type_home, ''),
                   @Default_rate_type_oper =  ISNULL(rate_type_oper, ''),
                   @Default_nat_cur_code = ISNULL(nat_cur_code, ''),
                   @Default_writeoff_code = ISNULL([writeoff_code], '')
                    FROM [arshipto]
                    WHERE [customer_code] = @bill_to
                            AND [ship_to_code] = @ship_to
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' arshipto 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
            END
        ELSE
            BEGIN
            SELECT @ship_to_name = '',    
                   @ship_to_addr1 = '',
                   @ship_to_addr2 = '',
                   @ship_to_addr3 = '',
                   @ship_to_addr4 = '',
                   @ship_to_addr5 = '',
                   @ship_to_addr6 = ''    
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @ship_to_name 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
            END
        --
        -- Get the information from imarhdr
        --                       
        IF (@debug_level >= 3)  
            BEGIN
            SELECT '(3): ' + @Routine_Name + ': #imarhdr_vw:'
            SELECT *
                    FROM #imarhdr_vw
                    WHERE source_ctrl_num = @source_ctrl_num
                            AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' #imarhdr_vw 4' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
            END
        SELECT @doc_desc = ISNULL(doc_desc, ''),
               @apply_to_num = apply_to_num,
               @apply_trx_type = apply_trx_type,        
               @chDateApplied = date_applied,
               @chDateDoc = date_doc,
               @chDateDue = date_due,
               @chDateShipped = date_shipped,
               @chDateAging = date_aging,
               @trx_type = trx_type,        
               @posting_code = ISNULL(posting_code, ''),
               @comment_code = ISNULL(comment_code, ''),
               @cust_po_num = ISNULL(cust_po_num, ''),            
               @hold_flag = hold_flag,
               @hold_desc = ISNULL(hold_desc, ''),    
               @territory_code = ISNULL(territory_code, ''),
               @salesperson_code = ISNULL(salesperson_code, ''),
               @terms_code = ISNULL(terms_code, ''),
               @doc_ctrl_num = ISNULL(doc_ctrl_num, ''),     
               @order_ctrl_num = ISNULL(order_ctrl_num, ''),
               @trx_ctrl_num = ISNULL(trx_ctrl_num, ''),
               @customer_code = ISNULL(customer_code, ''),
               @ship_to_code = ISNULL(ship_to_code, ''),
               @recurring_flag = recurring_flag,
               @recurring_code = ISNULL(recurring_code, ''),
               @tax_code = ISNULL(tax_code, ''),
               @nat_cur_code = ISNULL(nat_cur_code, ''),
               @rate_type_home = ISNULL(rate_type_home, ''),
               @rate_type_oper = ISNULL(rate_type_oper, ''),
               @rate_home = ISNULL(rate_home, 0),
               @rate_oper = ISNULL(rate_oper, 0),
               @prepay_discount = ISNULL(prepay_discount, 0),     
               @prepay_amt = ISNULL(prepay_amt, 0),
               @prompt1 = ISNULL(prompt1, ''),
               @prompt2 = ISNULL(prompt2, ''),
               @prompt3 = ISNULL(prompt3, ''),
               @prompt4 = ISNULL(prompt4, ''),
               @prepay_doc_num = ISNULL(prepay_doc_num, ''),
               @amt_freight = ISNULL(amt_freight, 0),
               @imarhdr_vw_amt_paid = ISNULL(amt_paid, 0),
               @imarhdr_vw_amt_rem_rev = ISNULL(amt_rem_rev, 0),
               @imarhdr_vw_amt_rem_tax = ISNULL(amt_rem_tax, 0),
               @imarhdr_vw_amt_tax_included = ISNULL(amt_tax_included, 0),
               @imarhdr_vw_amt_write_off_given = ISNULL(amt_write_off_given, 0),
               @imarhdr_vw_attention_name = ISNULL(attention_name, @Default_attention_name),
               @imarhdr_vw_attention_phone = ISNULL(attention_phone, @Default_attention_phone),
               @imarhdr_vw_date_entered = ISNULL(date_entered, ''),
               @imarhdr_vw_date_recurring = ISNULL(date_recurring, ''),
               @imarhdr_vw_date_required = ISNULL(date_required, ''),
               @imarhdr_vw_dest_zone_code = ISNULL(dest_zone_code, @Default_dest_zone_code),
               @imarhdr_vw_fin_chg_code = ISNULL(fin_chg_code, @Default_fin_chg_code),
               @imarhdr_vw_fob_code = ISNULL(fob_code, @Default_fob_code),
               @imarhdr_vw_freight_code = ISNULL(freight_code, @Default_freight_code),
               @imarhdr_vw_location_code = ISNULL(location_code, ''),
               @imarhdr_vw_price_code = ISNULL(price_code, @Default_price_code),
               @imarhdr_vw_printed_flag = ISNULL(printed_flag, @im_config_Default_printed_flag),
               @imarhdr_vw_customer_addr1 = ISNULL(customer_addr1, @Default_addr1),
               @imarhdr_vw_customer_addr2 = ISNULL(customer_addr2, @Default_addr2),
               @imarhdr_vw_customer_addr3 = ISNULL(customer_addr3, @Default_addr3),
               @imarhdr_vw_customer_addr4 = ISNULL(customer_addr4, @Default_addr4),
               @imarhdr_vw_customer_addr5 = ISNULL(customer_addr5, @Default_addr5),
               @imarhdr_vw_customer_addr6 = ISNULL(customer_addr6, @Default_addr6),
               @imarhdr_vw_ship_to_addr1 = ISNULL(ship_to_addr1, @ship_to_addr1),
               @imarhdr_vw_ship_to_addr2 = ISNULL(ship_to_addr2, @ship_to_addr2),
               @imarhdr_vw_ship_to_addr3 = ISNULL(ship_to_addr3, @ship_to_addr3),
               @imarhdr_vw_ship_to_addr4 = ISNULL(ship_to_addr4, @ship_to_addr4),
               @imarhdr_vw_ship_to_addr5 = ISNULL(ship_to_addr5, @ship_to_addr5),
               @imarhdr_vw_ship_to_addr6 = ISNULL(ship_to_addr6, @ship_to_addr6),
               @imarhdr_vw_source_trx_type = ISNULL(source_trx_type, ''),
               @imarhdr_vw_total_weight = ISNULL(total_weight, 0),
               @imarhdr_vw_writeoff_code = ISNULL([writeoff_code], @Default_writeoff_code),
               @imarhdr_vw_vat_prc = ISNULL(vat_prc, 0),
               @imarhdr_vw_org_id = ISNULL(org_id, '')					
                FROM #imarhdr_vw
                WHERE source_ctrl_num = @source_ctrl_num
                        AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' #imarhdr_vw 5' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        IF @invoice_flag = 2031
            SET @imarhdr_vw_writeoff_code = ''
        IF @im_config_printed_flag_Processing_Method = 'NEW'
            BEGIN
            SET @imincrh_sp_printed_flag = @imarhdr_vw_printed_flag
            IF @imarhdr_vw_printed_flag NOT IN (0, 1)
                SET @imincrh_sp_printed_flag = 0
            END
        --
        -- Set @date_xxx values (INT, where valid) from @chDatexxx (VARCHAR) values.
        -- Note that the @date_xxx variables are used for two purposes; if the date
        -- in @chDatexxx is valid then the @date_xxx variable is set to 1 and immediately
        -- set to the converted @chDatexxx value.  If the date in @chDatexxx is not valid
        -- then the @date_xxx variable is set to 0 and this causes the value to be
        -- set from another date. 
        --            
        SELECT @date_applied = ISDATE(ISNULL(@chDateApplied, ''))
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @date_applied 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
        IF @date_applied = 1
            BEGIN
            SELECT @date_applied = DATEDIFF(dd, @January_First_Nineteen_Eighty, CONVERT(datetime, ISNULL(@chDateApplied, 0))) + 722815
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @date_applied 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
            END
        SELECT @date_doc = ISDATE(ISNULL(@chDateDoc, ''))
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @date_doc 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
        IF @date_doc = 1
            BEGIN
            SELECT @date_doc = DATEDIFF(dd, @January_First_Nineteen_Eighty, CONVERT(datetime, ISNULL(@chDateDoc, 0))) + 722815
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @date_doc 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
            END
        SELECT @due_date = ISDATE(ISNULL(@chDateDue, ''))
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @due_date 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
        IF @due_date = 1
            BEGIN
            SELECT @due_date = DATEDIFF(dd, @January_First_Nineteen_Eighty, CONVERT(datetime, ISNULL(@chDateDue, 0))) + 722815
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @due_date 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
            END
        SELECT @date_shipped = ISDATE(ISNULL(@chDateShipped, ''))
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @date_shipped 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
        IF @date_shipped = 1
            BEGIN
            SELECT @date_shipped = DATEDIFF(dd, @January_First_Nineteen_Eighty, CONVERT(datetime, ISNULL(@chDateShipped, 0))) + 722815
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @date_shipped 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
            END
        SELECT @date_aging = ISDATE(ISNULL(@chDateAging, ''))
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @date_aging 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
        IF @date_aging = 1
            BEGIN
            SELECT @date_aging = DATEDIFF(dd, @January_First_Nineteen_Eighty, CONVERT(datetime, ISNULL(@chDateAging, 0))) + 722815
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @date_aging 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
            END
        SELECT @date_entered = ISDATE(ISNULL(@imarhdr_vw_date_entered, ''))
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @date_entered 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
        IF @date_entered = 1
            BEGIN
            SELECT @date_entered = DATEDIFF(dd, @January_First_Nineteen_Eighty, CONVERT(datetime, ISNULL(@imarhdr_vw_date_entered, 0))) + 722815
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @date_entered 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
            END
        SELECT @date_recurring = ISDATE(ISNULL(@imarhdr_vw_date_recurring, ''))
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @date_recurring 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
        IF @date_recurring = 1
            BEGIN
            SELECT @date_recurring = DATEDIFF(dd, @January_First_Nineteen_Eighty, CONVERT(datetime, ISNULL(@imarhdr_vw_date_recurring, 0))) + 722815
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @date_recurring 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
            END
        SELECT @date_required = ISDATE(ISNULL(@imarhdr_vw_date_required, ''))
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @date_required 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
        IF @date_required = 1
            BEGIN
            SELECT @date_required = DATEDIFF(dd, @January_First_Nineteen_Eighty, CONVERT(datetime, ISNULL(@imarhdr_vw_date_required, 0))) + 722815
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @date_required 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
            END
        --
        -- Assign values for missing dates.
        --
        IF @date_applied = 0
            SET @date_applied = @current_appdate
        IF @date_doc = 0
            SET @date_doc = @date_applied 
        IF @date_shipped = 0
            SET @date_shipped = @date_doc
        IF @date_aging = 0
            SET @date_aging = @date_doc
        IF @date_entered = 0
            SET @date_entered = @current_appdate
        --
        -- Note that terms_code is used by imdtdue_sp, so it needs to be defaulted 
        -- before the call to imdtdue_sp.
        --    
        IF DATALENGTH(LTRIM(RTRIM(ISNULL(@terms_code, '')))) = 0
            SET @terms_code = @Default_terms_code
        --
        -- Determine due date and set @date_required if needed.
        --
        IF @due_date = 0
            BEGIN
            EXEC @SP_Result = imdtdue_sp 2000, 
                                         @terms_code, 
                                         @date_doc, 
                                         @due_date OUTPUT,
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
        IF @due_date IS NULL
           SET @due_date = @date_doc
        IF @date_required = 0
            SET @date_required = @due_date
        --    
        IF DATALENGTH(LTRIM(RTRIM(ISNULL(@posting_code, '')))) = 0
            SET @posting_code = @Default_posting_code 
        IF DATALENGTH(LTRIM(RTRIM(ISNULL(@comment_code, '')))) = 0
            SET @comment_code = @Default_comment_code 
        IF DATALENGTH(LTRIM(RTRIM(ISNULL(@tax_code, '')))) = 0
            SET @tax_code = @Default_tax_code 
        SELECT @hdr_tax_code = @tax_code    
        IF DATALENGTH(LTRIM(RTRIM(ISNULL(@territory_code, '')))) = 0
            SET @territory_code = @Default_territory_code
        IF DATALENGTH(LTRIM(RTRIM(ISNULL(@salesperson_code, '')))) = 0
            SET @salesperson_code = @Default_salesperson_code
	


        IF DATALENGTH(LTRIM(RTRIM(ISNULL(@imarhdr_vw_org_id, '')))) = 0
            SET @imarhdr_vw_org_id = dbo.sm_get_current_org_fn()
	
		--
        -- Get multicurrency information   
        --
        IF DATALENGTH(LTRIM(RTRIM(ISNULL(@rate_type_home, '')))) = 0
            SET @rate_type_home = @Default_rate_type_home
        IF DATALENGTH(LTRIM(RTRIM(ISNULL(@rate_type_oper, '')))) = 0
            SET @rate_type_oper = @Default_rate_type_oper
        IF DATALENGTH(LTRIM(RTRIM(ISNULL(@nat_cur_code, '')))) = 0
            SET @nat_cur_code = @Default_nat_cur_code
        SET @batch_ctrl_num = ''    
        --
        -- Generate header
        --
        IF DATALENGTH(LTRIM(RTRIM(ISNULL(@trx_ctrl_num, '')))) = 0
            BEGIN
            IF @method_flag IN (0,1)
                SELECT @trx_ctrl_num = @source_ctrl_num
            END
        IF @trx_type = 2032
            SELECT @due_date = 0,
                   @amt_due = 0,
                   @amt_discount_taken = 0,  
                   @date_shipped = 0,
                   @date_aging = 0,
                   @imarhdr_vw_date_required = ''
        SELECT @position = NULL
        SELECT @position = position
                FROM glcurr_vw
                WHERE currency_code = @nat_cur_code
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @position 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
        IF @position IS NULL 
            SELECT @nat_cur_code = @Default_nat_cur_code 
        IF @hold_flag NOT IN (0, 1, 13)
                OR @hold_flag IS NULL
            BEGIN
            IF (@debug_level >= 3)  
                SELECT '(3): ' + @Routine_Name + ': For trx_ctrl_num = ' + ISNULL(@trx_ctrl_num, 'NULL') + ', hold_flag changed from ' + CAST(ISNULL(@hold_flag, 'NULL') AS VARCHAR) + ' to 0.'
            SET @hold_flag = 0
            END
        IF @hold_flag = 13    
            SET @hold_flag = 0
        IF @trx_type = 2032
            IF @recurring_flag = 0
                SELECT @recurring_flag = 1
        IF @debug_level >= 3
            SELECT '(3): ' + @Routine_Name + ': Before imincrh_sp: @trx_ctrl_num = ' + RTRIM(ISNULL(@trx_ctrl_num, 'NULL'))
        EXEC @pricing_date = imincrh_sp @module_id = @module_id, 
                                        @val_mode = @validation_flag, 
                                        @trx_ctrl_num = @trx_ctrl_num OUTPUT, 
                                        @doc_ctrl_num = @doc_ctrl_num, 
                                        @doc_desc = @doc_desc, 
                                        @apply_to_num = @apply_to_num,  
                                        @apply_trx_type = @apply_trx_type, 
                                        @order_ctrl_num = @order_ctrl_num, 
                                        @batch_code = @batch_code, 
                                        @trx_type = @trx_type, 
                                        @date_entered = @date_entered, 
                                        @date_applied = @date_applied,
                                        @date_doc = @date_doc, 
                                        @date_shipped = @date_shipped, 
                                        @date_required = @date_required, 
                                        @date_due = @due_date, 
                                        @date_aging = @date_aging, 
                                        @customer_code = @bill_to, 
                                        @ship_to_code = @ship_to, 
                                        @salesperson_code = @salesperson_code, 
                                        @territory_code = @territory_code, 
                                        @comment_code = @comment_code, 
                                        @fob_code = @imarhdr_vw_fob_code, 
                                        @freight_code = @imarhdr_vw_freight_code, 
                                        @terms_code = @terms_code, 
                                        @fin_chg_code = @imarhdr_vw_fin_chg_code, 
                                        @price_code = @imarhdr_vw_price_code, 
                                        @dest_zone_code = @imarhdr_vw_dest_zone_code, 
                                        @posting_code = @posting_code, 
                                        @recurring_flag = @recurring_flag, 
                                        @recurring_code = @recurring_code, 
                                        @tax_code = @tax_code, 
                                        @cust_po_num = @cust_po_num, 
                                        @total_weight = @imarhdr_vw_total_weight, 
                                        @amt_gross = @amt_gross, 
                                        @amt_freight = @amt_freight, 
                                        @amt_tax = @amt_tax, 
                                        @amt_discount = @amt_discount, 
                                        @amt_net = @amt_net, 
                                        @amt_paid = @imarhdr_vw_amt_paid, 
                                        @amt_due = @amt_due, 
                                        @amt_cost = @amt_cost, 
                                        @amt_profit = @amt_profit, 
                                        @next_serial_id = @next_serial_id, 
                                        @printed_flag = @imincrh_sp_printed_flag,
                                        @posted_flag = @posted_flag, 
                                        @hold_flag = @hold_flag, 
                                        @hold_desc = @hold_desc, 
                                        @user_id = @Process_User_ID, 
                                        @customer_addr1 = @imarhdr_vw_customer_addr1, 
                                        @customer_addr2 = @imarhdr_vw_customer_addr2, 
                                        @customer_addr3 = @imarhdr_vw_customer_addr3, 
                                        @customer_addr4 = @imarhdr_vw_customer_addr4, 
                                        @customer_addr5 = @imarhdr_vw_customer_addr5, 
                                        @customer_addr6 = @imarhdr_vw_customer_addr6, 
                                        @ship_to_addr1 = @imarhdr_vw_ship_to_addr1, 
                                        @ship_to_addr2 = @imarhdr_vw_ship_to_addr2, 
                                        @ship_to_addr3 = @imarhdr_vw_ship_to_addr3, 
                                        @ship_to_addr4 = @imarhdr_vw_ship_to_addr4, 
                                        @ship_to_addr5 = @imarhdr_vw_ship_to_addr5, 
                                        @ship_to_addr6 = @imarhdr_vw_ship_to_addr6, 
                                        @attention_name = @imarhdr_vw_attention_name, 
                                        @attention_phone = @imarhdr_vw_attention_phone, 
                                        @amt_rem_rev = @imarhdr_vw_amt_rem_rev, 
                                        @amt_rem_tax = @imarhdr_vw_amt_rem_tax, 
                                        @date_recurring = @date_recurring, 
                                        @location_code = @imarhdr_vw_location_code, 
                                        @process_group_num = '', -- This will be set in imarint01a_sp
                                        @amt_discount_taken = @amt_discount_taken,  
                                        @amt_write_off_given = @imarhdr_vw_amt_write_off_given, 
                                        @source_trx_ctrl_num = @source_ctrl_num, 
                                        @source_trx_type = @imarhdr_vw_source_trx_type, 
                                        @nat_cur_code = @nat_cur_code, 
                                        @rate_type_home = @rate_type_home, 
                                        @rate_type_oper = @rate_type_oper, 
                                        @amt_tax_included = @imarhdr_vw_amt_tax_included, 
                                        @rate_home = @rate_home, 
                                        @rate_oper = @rate_oper,
                                        @debug_level = @debug_level, 
                                        @userid = @userid,
                                        @writeoff_code = @imarhdr_vw_writeoff_code,
                                        @vat_prc = @imarhdr_vw_vat_prc,
                                        @org_id = @imarhdr_vw_org_id				
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' imincrh_sp' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        IF (@debug_level >= 3)  
            BEGIN
            SELECT '(3): ' + @Routine_Name + ': After imincrh_sp.  Records from #arinpchg WHERE trx_ctrl_num = ' + RTRIM(ISNULL(@trx_ctrl_num, 'NULL'))
            SELECT * from #arinpchg
                    WHERE trx_ctrl_num = @trx_ctrl_num
            END
        --  
        -- Create invoice detail for every detail line.
        --
        SELECT @last_sequence_id = 0
        WHILE (1 = 1)
          BEGIN
            SET ROWCOUNT 1
            SELECT @dump = order_ctrl_num, 
                   @sequence_id = sequence_id 
                    FROM #imardtl_vw
                    WHERE source_ctrl_num = @source_ctrl_num
                            AND sequence_id > @last_sequence_id
                            AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
                    ORDER BY sequence_id
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @dump' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
            SET ROWCOUNT 0
            IF @Row_Count = 0 
                BREAK
            SELECT @last_sequence_id = @sequence_id
            IF @debug_level >= 3  
              BEGIN
                SELECT '(3): ' + @Routine_Name + ': Record from #imardtl_vw:'
                SELECT * 
                        FROM [#imardtl_vw]
                        WHERE [source_ctrl_num] = @source_ctrl_num
                                AND [sequence_id] = @sequence_id
                                AND RTRIM(LTRIM(ISNULL([company_code], ''))) = @company_code
              END
            SELECT @location_code = ISNULL(location_code, ''),
                   @item_code = ISNULL(item_code, ''),
                   @qty_shipped = ISNULL(qty_shipped, 0),
                   @qty_ordered = ISNULL(qty_ordered, 0),
                   @qty_returned = ISNULL(qty_returned, 0),
                   @unit_code = ISNULL(unit_code, ''),
                   @unit_price = ISNULL(unit_price, 0),
                   @unit_cost = ISNULL(unit_cost, 0),
                   @weight = ISNULL(weight, 0),
                   @tax_code = tax_code,
                   @gl_rev_acct= gl_rev_acct,
                   @disc_prc_flag = ISNULL([disc_prc_flag], 0),
                   @discount_amt = ISNULL(discount_amt, 0),
                   @rma_num = ISNULL(rma_num, ''),
                   @return_code = ISNULL(return_code, ''),
                   @line_desc = ISNULL(line_desc, ''),
                   @reference_code = ISNULL(reference_code, ''),
                   @bulk_flag = ISNULL(bulk_flag, 0),
                   @calc_tax = ISNULL(calc_tax, 0),
                   @commission_flag = ISNULL(commission_flag, 0),
                   @imardtl_vw_date_entered = date_entered,
                   @imardtl_vw_new_gl_rev_acct = ISNULL(new_gl_rev_acct, ''),
                   @imardtl_vw_oe_orig_flag = ISNULL(oe_orig_flag, 0),
                   @imardtl_vw_qty_prev_returned = ISNULL(qty_prev_returned, 0),	
                   @cust_po = ISNULL(cust_po,''),											
				   @det_org_id  = ISNULL(org_id,'') 										
                    FROM [#imardtl_vw]
                    WHERE [source_ctrl_num] = @source_ctrl_num
                            AND [sequence_id] = @sequence_id
                            AND RTRIM(LTRIM(ISNULL([company_code], ''))) = @company_code
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' #imardtl_vw 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
            IF @trx_type = 2031
                SET @iv_post_flag = 1
            IF @trx_type = 2032
              BEGIN
                IF DATALENGTH(LTRIM(RTRIM(ISNULL(@item_code, '')))) = 0
                    SELECT @iv_post_flag = 0
                ELSE
                    SELECT @iv_post_flag = 1
                IF DATALENGTH(LTRIM(RTRIM(ISNULL(@return_code, '')))) = 0
                  BEGIN
                    SET ROWCOUNT 1
                    SELECT @return_code = [return_code]
                            FROM [arreturn]
                    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' arreturn' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
                    SET ROWCOUNT 0
                    IF DATALENGTH(LTRIM(RTRIM(ISNULL(@return_code, '')))) = 0
                        SET @return_code = ''
                  END
              END    
            




            IF DATALENGTH(LTRIM(RTRIM(ISNULL(@tax_code, '')))) = 0
                SELECT @tax_code = @hdr_tax_code
		


			


			IF DATALENGTH(LTRIM(RTRIM(ISNULL(@det_org_id, '')))) = 0 
			BEGIN
			--  IF DATALENGTH(LTRIM(RTRIM(ISNULL(@gl_rev_acct, '')))) = 0 
			--    SET @det_org_id = @imarhdr_vw_org_id
			--  ELSE
			    SET @det_org_id = dbo.IBOrgbyAcct_fn(@gl_rev_acct)
			END
		
            

                       
            IF DATALENGTH(LTRIM(RTRIM(ISNULL(@gl_rev_acct, '')))) = 0
              BEGIN
                IF (@trx_type = 2032)
                  BEGIN
                    SELECT @gl_rev_acct = dbo.IBAcctMask_fn(sales_ret_acct_code, @det_org_id)	
                            FROM araccts 
                            WHERE posting_code = @posting_code
                    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' araccts 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
                  END
                ELSE
                  BEGIN
                    SELECT @gl_rev_acct = dbo.IBAcctMask_fn(rev_acct_code, @det_org_id) 		
                            FROM araccts 
                            WHERE posting_code = @posting_code
                    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' araccts 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
                  END
              END
            IF DATALENGTH(LTRIM(RTRIM(ISNULL(@gl_rev_acct, '')))) = 0
                SET @gl_rev_acct = ''
            SELECT @detail_date_entered = ISDATE(ISNULL(@imardtl_vw_date_entered, 0))
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @detail_date_entered 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
            IF @detail_date_entered = 1
              BEGIN
                SELECT @detail_date_entered = DATEDIFF(dd, @January_First_Nineteen_Eighty, CONVERT(datetime, ISNULL(@imardtl_vw_date_entered, 0))) + 722815
                SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @detail_date_entered 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
              END
            IF @detail_date_entered = 0
                SET @detail_date_entered = @current_appdate    
            


            IF @trx_type = 2031
                SELECT @extended_price = (SIGN(@unit_price * @qty_shipped) * ROUND(ABS(@unit_price * @qty_shipped) + 0.0000001, @precision_gl))
            ELSE
                SELECT @extended_price = (SIGN(@unit_price * @qty_returned) * ROUND(ABS(@unit_price * @qty_returned) + 0.0000001, @precision_gl))
            SELECT @Original_extended_price = @extended_price
            IF @discount_amt IS NULL
                SELECT @discount_amt = 0.0
            --
            -- @disc_prc_flag indicates whether @discount_amt is a percentage (1) or a simple
            -- amount (0).
            --
            IF @disc_prc_flag = 1
              BEGIN
                SELECT @disc_prc = @discount_amt
                SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @disc_prc 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
                --SELECT @discount_amt = ROUND(@extended_price * (@discount_prc / 100), @precision_gl)
				SELECT @discount_amt = ROUND(@extended_price * (@disc_prc / 100), @precision_gl)
                SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @discount_amt 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
                SELECT @extended_price = @extended_price - @discount_amt
                SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @extended_price 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
              END
            ELSE
              BEGIN
                SELECT @extended_price = @extended_price - @discount_amt
                SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @extended_price 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
                IF @Original_extended_price > 0
                  BEGIN
                    SELECT @disc_prc = (@discount_amt / @Original_extended_price) * 100
                    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @disc_prc 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
                  END    
                ELSE
                  BEGIN
                    SET @disc_prc = 0
                  END    
              END
            --
            -- For credit memos, the document control number in the detail row must be blank
            -- or it will fail the edits at posting time
            --
            IF @trx_type = 2032
                SET @doc_ctrl_num = ''
            --    
            EXEC @SP_Result = arincrd_sp @module_id, 
                                         @validation_flag, 
                                         @trx_ctrl_num, 
                                         @doc_ctrl_num, 
                                         @sequence_id, 
                                         @trx_type, 
                                         @location_code, 
                                         @item_code, 
                                         @bulk_flag, 
                                         @detail_date_entered, 
                                         @line_desc, 
                                         @qty_ordered, 
                                         @qty_shipped, 
                                         @unit_code,  
                                         @unit_price, 
                                         @unit_cost, 
                                         @weight, 
                                         @sequence_id, 
                                         @tax_code, 
                                         @gl_rev_acct, 
                                         @disc_prc_flag, 
                                         @discount_amt,  
                                         @commission_flag, 
                                         @rma_num, 
                                         @return_code, 
                                         @qty_returned, 
                                         @imardtl_vw_qty_prev_returned, 
                                         @imardtl_vw_new_gl_rev_acct, 
                                         @iv_post_flag, 
                                         @imardtl_vw_oe_orig_flag, 
                                         @disc_prc, 
                                         @extended_price,
                                         @calc_tax,
                                         @reference_code,
										 @cust_po,											
										 @det_org_id										
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' arincrd_sp' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            IF NOT @SP_Result = 0
              BEGIN
                EXEC im_log_sp_error_sp @ILSE_Error_Code = @SP_Result,
                                        @ILSE_SP_Name = 'arincrd_sp',
                                        @ILSE_String = '',
                                        @ILSE_Procedure_Name = @Routine_Name,
                                        @ILSE_Log_Activity = 'YES',
                                        @im_log_sp_error_sp_User_ID = @userid
                GOTO Error_Return
              END    
            IF (@debug_level >= 3)  
              BEGIN
                SELECT '(3): ' + @Routine_Name + ': Dump work table #arinpcdt after detail creation:'
                SELECT * from #arinpcdt 
                        WHERE trx_ctrl_num = @trx_ctrl_num
                                AND sequence_id = @sequence_id 
              END
          END
        IF NOT DATALENGTH(LTRIM(RTRIM(ISNULL(@prepay_doc_num, '')))) = 0
          BEGIN
            EXEC @SP_Result = imarpp01_sp @trx_ctrl_num,
                                          @prepay_doc_num, 
                                          @date_doc, 
                                          @customer_code, 
                                          @prepay_amt, 
                                          @prepay_discount, 
                                          @prompt1, 
                                          @prompt2,
                                          @prompt3, 
                                          @prompt4, 
                                          @debug_level,
                                          @userid,
										  @imarhdr_vw_org_id									
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' imarpp01_sp' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            IF NOT @SP_Result = 0
              BEGIN
                EXEC im_log_sp_error_sp @ILSE_Error_Code = @SP_Result,
                                        @ILSE_SP_Name = 'imarpp01_sp',
                                        @ILSE_String = '',
                                        @ILSE_Procedure_Name = @Routine_Name,
                                        @ILSE_Log_Activity = 'YES',
                                        @im_log_sp_error_sp_User_ID = @userid
                GOTO Error_Return
              END    
            END
        --
        -- Put the trx_ctrl_num value in the temporary staging table record.
        -- This is for the benefit of the UPDATE that sets amt_net.
        --
        UPDATE #imarhdr_vw
                SET trx_ctrl_num = @trx_ctrl_num
                WHERE source_ctrl_num = @source_ctrl_num
                        AND trx_ctrl_num = ''
                        AND (processed_flag = 0 OR processed_flag IS NULL)
                        AND trx_type = @invoice_flag
                        AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarhdr_vw 6' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
        UPDATE #imardtl_vw
                SET trx_ctrl_num = @trx_ctrl_num
                WHERE source_ctrl_num = @source_ctrl_num
                        AND trx_ctrl_num = ''
                        AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imardtl_vw 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
      END 
    EXEC @SP_Result = imartax_sp '',
                                 @userid, 
                                 @debug_level
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' imartax_sp' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    IF NOT @SP_Result = 0
        BEGIN
        EXEC im_log_sp_error_sp @ILSE_Error_Code = @SP_Result,
                                @ILSE_SP_Name = 'imartax_sp',
                                @ILSE_String = '',
                                @ILSE_Procedure_Name = @Routine_Name,
                                @ILSE_Log_Activity = 'YES',
                                @im_log_sp_error_sp_User_ID = @userid
        GOTO Error_Return
        END 
    --      
    EXEC @SP_Result = imarint01a_sp @company_code, 
                                    @validation_flag, 
                                    @db_userid, 
                                    @db_password, 
                                    @invoice_flag, 
                                    @debug_level, 
                                    @module_id,
                                    @process_ctrl_num OUTPUT, 
                                    @userid
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' imarint01a_sp' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    IF NOT @SP_Result = 0
        BEGIN
        EXEC im_log_sp_error_sp @ILSE_Error_Code = @SP_Result,
                                @ILSE_SP_Name = 'imarint01a_sp',
                                @ILSE_String = '',
                                @ILSE_Procedure_Name = @Routine_Name,
                                @ILSE_Log_Activity = 'YES',
                                @im_log_sp_error_sp_User_ID = @userid
        GOTO Error_Return
        END
    SET @imarint01_sp_process_ctrl_num_Validation = @process_ctrl_num    
    IF (@debug_level >= 3)  
        BEGIN
        SELECT '(3): ' + @Routine_Name + ': Dump of #arinpchg before save:'
        SELECT * from #arinpchg
        SELECT '(3): ' + @Routine_Name + ': Dump of #arinpcdt before save:'
        SELECT * from #arinpcdt
        END
    --
    -- Copy records to the im# tables.
    --
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': Copy records to the im# tables'
    INSERT INTO [CVO_Control]..im#imarhdr 
            ([Import Identifier], [Import Company],   [Import Date],
             company_code,        process_ctrl_num,   source_ctrl_num,
             order_ctrl_num,      trx_ctrl_num,       doc_desc,
             doc_ctrl_num,        apply_to_num,       apply_trx_type,
             trx_type,            date_applied,       date_doc,
             date_shipped,        date_due,           date_aging,
             customer_code,       ship_to_code,       salesperson_code,
             territory_code,      comment_code,       posting_code,
             terms_code,          cust_po_num,        hold_flag,
             hold_desc,           recurring_flag,     recurring_code,
             tax_code,            nat_cur_code,       rate_type_home,
             rate_type_oper,      rate_home,          rate_oper,
             prepay_discount,     prepay_amt,         prepay_doc_num,
             prompt1,             prompt2,            prompt3,
             prompt4,             amt_paid,           amt_rem_rev,
             amt_rem_tax,         amt_tax_included,   amt_write_off_given,
             attention_name,      attention_phone,    customer_addr1,
             customer_addr2,      customer_addr3,     customer_addr4,
             customer_addr5,      customer_addr6,     date_entered,
             date_recurring,      date_required,      dest_zone_code,
             fin_chg_code,        fob_code,           freight_code,
             location_code,       price_code,         printed_flag,
             ship_to_addr1,       ship_to_addr2,      ship_to_addr3,
             ship_to_addr4,       ship_to_addr5,      ship_to_addr6,
             source_trx_type,     total_weight,       amt_freight,
             processed_flag,      date_processed,     [batch_no],
             [record_id_num],     [User_ID],          [writeoff_code],
             [vat_prc], 		  org_id)											
            SELECT @Import_Identifier,  @company_code,      GETDATE(),
                   company_code,        process_ctrl_num,   source_ctrl_num,
                   order_ctrl_num,      trx_ctrl_num,       doc_desc,
                   doc_ctrl_num,        apply_to_num,       apply_trx_type,
                   trx_type,            date_applied,       date_doc,
                   date_shipped,        date_due,           date_aging,
                   customer_code,       ship_to_code,       salesperson_code,
                   territory_code,      comment_code,       posting_code,
                   terms_code,          cust_po_num,        hold_flag,
                   hold_desc,           recurring_flag,     recurring_code,
                   tax_code,            nat_cur_code,       rate_type_home,
                   rate_type_oper,      rate_home,          rate_oper,
                   prepay_discount,     prepay_amt,         prepay_doc_num,
                   prompt1,             prompt2,            prompt3,
                   prompt4,             amt_paid,           amt_rem_rev,
                   amt_rem_tax,         amt_tax_included,   amt_write_off_given,
                   attention_name,      attention_phone,    customer_addr1,
                   customer_addr2,      customer_addr3,     customer_addr4,
                   customer_addr5,      customer_addr6,     date_entered,
                   date_recurring,      date_required,      dest_zone_code,
                   fin_chg_code,        fob_code,           freight_code,
                   location_code,       price_code,         printed_flag,
                   ship_to_addr1,       ship_to_addr2,      ship_to_addr3,
                   ship_to_addr4,       ship_to_addr5,      ship_to_addr6,
                   source_trx_type,     total_weight,       amt_freight,
                   processed_flag,      date_processed,     [batch_no],
                   [record_id_num],     [User_ID],          [writeoff_code],
                   [vat_prc],			org_id											   
                    FROM #imarhdr_vw
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' [CVO_Control]..im#imarhdr 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END                
    --
    -- Set amt_net for the benefit of the report.
    --
    UPDATE [CVO_Control]..[im#imarhdr] 
            SET [amt_net] = b.[amt_net]
            FROM [CVO_Control]..[im#imarhdr] a
            INNER JOIN [#arinpchg] b
                    ON a.[trx_ctrl_num] = b.[trx_ctrl_num]
                            AND a.[trx_type] = b.[trx_type]
            WHERE a.[Import Identifier] = @imarint01_sp_Import_Identifier
                    AND a.[company_code] = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' [CVO_Control]..[im#imarhdr] 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END                
    --
    INSERT INTO [CVO_Control]..im#imardtl 
            ([Import Identifier], [Import Company],  [Import Date],
             company_code,        process_ctrl_num,  source_ctrl_num,
             order_ctrl_num,      trx_ctrl_num,      sequence_id,
             trx_type,            location_code,     item_code,
             line_desc,           qty_ordered,       qty_shipped,
             qty_returned,        unit_code,         unit_price,
             unit_cost,           weight,            tax_code,
             gl_rev_acct,         disc_prc_flag,     discount_amt,
             rma_num,             return_code,       reference_code,
             bulk_flag,           calc_tax,          commission_flag,
             date_entered,        new_gl_rev_acct,   oe_orig_flag,
             qty_prev_returned,   processed_flag,    [batch_no],
             [record_id_num],     [User_ID],		 [cust_po],                 
			 org_id)															
            SELECT @Import_Identifier, @company_code,     GETDATE(),
                   company_code,       process_ctrl_num,  source_ctrl_num,
                   order_ctrl_num,     trx_ctrl_num,      sequence_id,
                   trx_type,           location_code,     item_code,
                   line_desc,          qty_ordered,       qty_shipped,
                   qty_returned,       unit_code,         unit_price,
                   unit_cost,          weight,            tax_code,
                   gl_rev_acct,        disc_prc_flag,     discount_amt,
                   rma_num,            return_code,       reference_code,
                   bulk_flag,          calc_tax,          commission_flag,
                   date_entered,       new_gl_rev_acct,   oe_orig_flag,
                   qty_prev_returned,  processed_flag,    [batch_no],
                   [record_id_num],    [User_ID],		  [cust_po],                
				   org_id															
                    FROM #imardtl_vw
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' [CVO_Control]..im#imardtl 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END                
    --    
    -- At this point, #arinpchg contains all header records that are in a to-be-saved
    -- state and also that have been validated (and trx_state set appropriately).
    -- A "final" import will call imarinsav_sp which will remove the records from #arinpchg,
    -- and a "trial" import will not call imarinsav_sp.  To update the staging tables with 
    -- appropriate values for processed_flag, etc., using #arinpchg.trx_state as the 
    -- determining factor, the updates will be done prior to calling imarinsav_sp for a 
    -- "final" import or simply at the "ELSE" condition for a "trial" import. 
    --    
    IF @method_flag = 2
        BEGIN    
        --
        -- If we are in batch mode then create a "feed" batchctl record with 
        -- the desired description.  imarinsav_sp will call ARCreateBatchBlock_SP
        -- which will create another record in batchctl using the description from the
        -- "feed" record.  For the desired description to be taken from the "feed" record,
        -- @imarinsav_sp_process_group_num must match the value placed into
        -- batchctl.process_group_num.
        -- 
        IF EXISTS(SELECT * FROM arco WHERE batch_proc_flag = 1)
            BEGIN
            EXEC @ret_status = ARGetNextControl_SP 2100, 
                                                   @new_bcn OUTPUT, 
                                                   @num OUTPUT
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' ARGetNextControl_SP' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            IF NOT @ret_status = 0
                BEGIN
                EXEC im_log_sp_error_sp @ILSE_Error_Code = @ret_status,
                                        @ILSE_SP_Name = 'ARGetNextControl_SP',
                                        @ILSE_String = '',
                                        @ILSE_Procedure_Name = @Routine_Name,
                                        @ILSE_Log_Activity = 'YES',
                                        @im_log_sp_error_sp_User_ID = @userid
                GOTO Error_Return
                END 
            SET @new_bcn = UPPER(@new_bcn)       
            SET @cur_time = DATEPART(hour, getdate()) * 3600 + DATEPART(minute, getdate()) * 60 + DATEPART(second, getdate())
            SET @batch_type = 2010 
                              * sign(sign(@invoice_flag - 2031) + 1) 
                              * abs(sign(@invoice_flag - 2051)) 
                              * abs(sign(@invoice_flag - 2032)) 
                              + 2040 
                              * abs(sign(@invoice_flag - 2031)) 
                              * sign(sign(@invoice_flag - 2051) + 1) 
                              * abs(sign(@invoice_flag - 2032)) 
                              + 2030 
                              * abs(sign(@invoice_flag - 2031)) 
                              * abs(sign(@invoice_flag - 2051)) 
                              * sign(sign(@invoice_flag - 2032) + 1)
            INSERT INTO batchctl (timestamp,      batch_ctrl_num,   batch_description,        
                                  start_date,     start_time,       completed_date,        
                                  completed_time, control_number,   control_total,    
                                  actual_number,  actual_total,     batch_type,
                                  document_name,  hold_flag,        posted_flag,
                                  void_flag,      selected_flag,    number_held,
                                  date_applied,   date_posted,      time_posted,    
                                  start_user,     completed_user,   posted_user,
                                  company_code,   selected_user_id, process_group_num,
                                  page_fill_1,    page_fill_2,      page_fill_3,        
                                  page_fill_4,    page_fill_5,      page_fill_6,    
                                  page_fill_7,    page_fill_8)
                    VALUES (NULL,             @new_bcn,  @im_config_batch_description, 
                            @current_appdate, @cur_time, 0,
                            0,                0,         0,        
                            0,                0,         @batch_type,
                            'IM Transaction', 0,         0,                
                            0,                0,         0,            
                            0,                0,         0,        
                            '',               '',        '',
                            @company_code,    0,         @process_ctrl_num,
                            NULL,             NULL,      NULL,            
                            NULL,             NULL,      NULL,        
                            NULL,             NULL)
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' batchctl 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
            END
        UPDATE [#arinpchg]
                SET [next_serial_id] = (SELECT MAX([serial_id]) + 1 from [#arinpcdt] WHERE [trx_ctrl_num] = [#arinpchg].[trx_ctrl_num])
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' arinpchg 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        --
        -- Before imarinsav_sp is called (which will delete the records from #arinpchg),
        -- insert records into artrxxtr using information from #arinpchg.  The JOIN 
        -- and WHERE will prevent duplicate records from being inserted.
        --
        INSERT INTO [artrxxtr] (timestamp,  rec_set,      amt_due,        amt_paid,
                                trx_type,   trx_ctrl_num, addr1,          addr2,
                                addr3,      addr4,        addr5,          addr6,
                                ship_addr1, ship_addr2,   ship_addr3,     ship_addr4,
                                ship_addr5, ship_addr6,   attention_name, attention_phone)
                SELECT NULL,             1,                h.amt_due,        h.amt_paid,
                       h.trx_type,       h.trx_ctrl_num,   h.customer_addr1, h.customer_addr2,
                       h.customer_addr3, h.customer_addr4, h.customer_addr5, h.customer_addr6,
                       h.ship_to_addr1,  h.ship_to_addr2,  h.ship_to_addr3,  h.ship_to_addr4,
                       h.ship_to_addr5,  h.ship_to_addr6,  h.attention_name, h.attention_phone
                        FROM [#arinpchg] h
                        LEFT OUTER JOIN [artrxxtr]
                                ON h.[trx_ctrl_num] = [artrxxtr].[trx_ctrl_num]
                        WHERE [artrxxtr].[trx_ctrl_num] IS NULL        
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' artrxxtr 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        --
        IF @debug_level >= 3
            SELECT '(3): ' + @Routine_Name + ': Before imarinsav_sp'
        EXEC @SP_Result = imarinsav_sp @proc_user_id = @Process_User_ID,
                                       @new_batch_code = @new_batch_code OUTPUT,
                                       @debug_level = @debug_level,
                                       @userid = @userid,
                                       @imarinsav_sp_process_group_num = @process_ctrl_num    
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' imarinsav_sp' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        IF NOT @SP_Result = 0
            BEGIN
            EXEC im_log_sp_error_sp @ILSE_Error_Code = @SP_Result,
                                    @ILSE_SP_Name = 'imarinsav_sp',
                                    @ILSE_String = '',
                                    @ILSE_Procedure_Name = @Routine_Name,
                                    @ILSE_Log_Activity = 'YES',
                                    @im_log_sp_error_sp_User_ID = @userid
            GOTO Error_Return
            END    
        IF @debug_level >= 3    
            SELECT '(3): ' + @Routine_Name + ': After imarinsav_sp.'
        --
        -- Note that imbatch_sp uses the processed_flag value of 1, so it is important
        -- that this update come before the call to imbatch_sp.  imbatch_sp uses
        -- the trx_ctrl_num value so it also needs to be put in #imarhdr_vw here. 
        --
        UPDATE #imarhdr_vw
                SET processed_flag = 1,
                    trx_ctrl_num = b.trx_ctrl_num,
                    date_processed = GETDATE()     
                FROM #imarhdr_vw a, arinpchg b
                WHERE a.source_ctrl_num = b.source_trx_ctrl_num
                        AND a.customer_code = b.customer_code
                        AND a.trx_type = b.trx_type
                        AND NOT a.processed_flag = 2
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarhdr_vw 7' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        UPDATE #imardtl_vw
                SET processed_flag = 1
                FROM #imardtl_vw a, #imarhdr_vw b
                WHERE a.source_ctrl_num = b.source_ctrl_num
                        AND RTRIM(LTRIM(ISNULL(a.company_code, ''))) = RTRIM(LTRIM(ISNULL(b.company_code, '')))
                        AND a.trx_type = b.trx_type
                        AND b.processed_flag = 1
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imardtl_vw 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        --
        IF (@close_batch_flag = 1)
            BEGIN
            EXEC @SP_Result = imbatch_sp @company_code, 
                                         @invoice_flag,
                                         @debug_level,
                                         @userid,
                                         @User_Name
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' imbatch_sp' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            IF NOT @SP_Result = 0
                BEGIN
                EXEC im_log_sp_error_sp @ILSE_Error_Code = @SP_Result,
                                        @ILSE_SP_Name = 'imbatch_sp',
                                        @ILSE_String = '',
                                        @ILSE_Procedure_Name = @Routine_Name,
                                        @ILSE_Log_Activity = 'YES',
                                        @im_log_sp_error_sp_User_ID = @userid
                GOTO Error_Return
                END    
            END
        --
        -- After imarinsav_sp is called delete the "feed" batchctl record since
        -- ARCreateBatchBlock_SP created another batchctl record.
        --
        IF EXISTS(SELECT * FROM arco WHERE batch_proc_flag = 1)
            BEGIN
            DELETE batchctl 
                    WHERE UPPER(batch_ctrl_num) = UPPER(@new_bcn)
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DELETE + ' batchctl 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            END
        END
    --
    -- Set processed_flag in the header as appropriate for those detail records
    -- where the processed_flag is not 0.
    --
    UPDATE #imarhdr_vw
            SET processed_flag = b.processed_flag
            FROM #imarhdr_vw a, #imardtl_vw b
            WHERE (b.processed_flag = 1 OR b.processed_flag = 2)
                    AND a.source_ctrl_num = b.source_ctrl_num
                    AND (a.processed_flag = 0 OR a.processed_flag IS NULL)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarhdr_vw 8' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Copy the processed_flag values from the temporary staging tables to the
    -- permanent staging tables.
    --        
    EXEC @SP_Result = imarint01b_sp @process_ctrl_num, 
                                    @company_code, 
                                    @invoice_flag,
                                    @method_flag, 
                                    @debug_level,
                                    @userid
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' imarint01b_sp' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    IF NOT @SP_Result = 0
        BEGIN
        EXEC im_log_sp_error_sp @ILSE_Error_Code = @SP_Result,
                                @ILSE_SP_Name = 'imarint01b_sp',
                                @ILSE_String = '',
                                @ILSE_Procedure_Name = @Routine_Name,
                                @ILSE_Log_Activity = 'YES',
                                @im_log_sp_error_sp_User_ID = @userid
        GOTO Error_Return
        END
    --
    -- imarint01_Errors_sp will compose an error message consisting of the description
    -- from aredterr appended with the value from perror.infoint if infoint is not zero
    -- (otherwise it will append a space).  This update will prevent any error messages
    -- from apearing that have an inappropriate number at the end. 
    --
    UPDATE perror
            SET [infoint] = 0
            WHERE NOT ([module_id] = @module_id AND [err_code] = 20940)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' perror 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --    
    


    
    SET @imarint01_sp_process_ctrl_num_Posting = ''
    IF @method_flag = 2
            AND @post_flag = 1
        BEGIN
        EXEC @SP_Result = IMARPostInvoice_sp @db_userid, 
                                             @db_password, 
                                             @invoice_flag, 
                                             @debug_level, 
                                             @perf_level, 
                                             @process_ctrl_num_Posting OUTPUT,
                                             @userid,
                                             @imarint01_sp_Application_Name,
                                             @User_Name,
                                             @imarint01_sp_TPS_int_value
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' IMARPostInvoice_sp' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        IF NOT @SP_Result = 0
            BEGIN
            EXEC im_log_sp_error_sp @ILSE_Error_Code = @SP_Result,
                                    @ILSE_SP_Name = 'IMARPostInvoice_sp',
                                    @ILSE_String = '',
                                    @ILSE_Procedure_Name = @Routine_Name,
                                    @ILSE_Log_Activity = 'YES',
                                    @im_log_sp_error_sp_User_ID = @userid
            GOTO Error_Return
            END    
        SET @imarint01_sp_process_ctrl_num_Posting = @process_ctrl_num_Posting    
        END
    IF @invoice_flag = 2031 
        BEGIN     
        INSERT INTO [imlog] VALUES (GETDATE(), 'ARINVOICE', 1, '', '', '', 'Accounts Receivable Invoices -- Import Identifier = ' + CAST(@Import_Identifier AS VARCHAR), @userid)
        INSERT INTO [imlog] VALUES (GETDATE(), 'ARINVOICE', 1, '', '', '', 'Accounts Receivable Invoices -- process_ctrl_num (Validation) = ' + ISNULL(@process_ctrl_num, 'NULL'), @userid)
        





    
        END
    ELSE    
        BEGIN     
        INSERT INTO [imlog] VALUES (GETDATE(), 'ARINVOICE', 1, '', '', '', 'Accounts Receivable Credit Memos -- Import Identifier = ' + CAST(@Import_Identifier AS VARCHAR), @userid)
        INSERT INTO [imlog] VALUES (GETDATE(), 'ARINVOICE', 1, '', '', '', 'Accounts Receivable Credit Memos -- process_ctrl_num (Validation) = ' + ISNULL(@process_ctrl_num, 'NULL'), @userid)
        





    
        END
    INSERT INTO [imlog] VALUES (GETDATE(), 'ARINVOICE', 1, '', '', '', 'Accounts Receivable Invoices/Credit Memos -- End', @userid)
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
GRANT EXECUTE ON  [dbo].[imarint01_sp] TO [public]
GO
