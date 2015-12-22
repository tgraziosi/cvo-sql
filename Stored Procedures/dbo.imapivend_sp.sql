SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


    CREATE PROC 
[dbo].[imapivend_sp] @company_code VARCHAR(8),
             @address_type INT,
             @trial_flag INT,
             @debug_level INT = 0,
             @userid INT = 0,
             @imapivend_sp_process_ctrl_num VARCHAR(16) = '' OUTPUT,
             @imapivend_sp_Dummy_1 VARCHAR(16) = '' OUTPUT,
             @imapivend_sp_Import_Identifier INT = 0 OUTPUT,
             @imapivend_sp_Override_User_Name VARCHAR(30) = ''
    AS  
    
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
    

    DECLARE @Record_Count INT
    
    CREATE TABLE #imapvnd 
            (company_code VARCHAR(8) NOT NULL,
             vendor_code VARCHAR(12) NOT NULL,
             pay_to_code VARCHAR(8) NULL,
             address_name VARCHAR(40) NOT NULL,
             short_name VARCHAR(10) NOT NULL,
             addr1 VARCHAR(40) NOT NULL,
             addr2 VARCHAR(40) NOT NULL,
             addr3 VARCHAR(40) NOT NULL,
             addr4 VARCHAR(40) NOT NULL,
             addr5 VARCHAR(40) NOT NULL,
             addr6 VARCHAR(40) NOT NULL,
             addr_sort1 VARCHAR(40) NOT NULL,
             addr_sort2 VARCHAR(40) NOT NULL,
             addr_sort3 VARCHAR(40) NOT NULL,
             address_type SMALLINT NOT NULL,
             status_type SMALLINT NOT NULL,
             attention_name VARCHAR(40) NOT NULL,
             attention_phone VARCHAR(30) NOT NULL,
             contact_name VARCHAR(40) NOT NULL,
             contact_phone VARCHAR(30) NOT NULL,
             tlx_twx VARCHAR(30) NOT NULL,
             phone_1 VARCHAR(30) NOT NULL,
             phone_2 VARCHAR(30) NOT NULL,
             tax_code VARCHAR(8) NOT NULL,
             terms_code VARCHAR(8) NOT NULL,
             fob_code VARCHAR(8) NOT NULL,
             posting_code VARCHAR(8) NOT NULL,
             location_code VARCHAR(8) NOT NULL,
             orig_zone_code VARCHAR(8) NOT NULL,
             customer_code VARCHAR(8) NULL,
             affiliated_vend_code VARCHAR(12) NULL,
             alt_vendor_code VARCHAR(12) NULL,
             comment_code VARCHAR(8) NULL,
             vend_class_code VARCHAR(8) NULL,
             branch_code VARCHAR(8) NULL,
             pay_to_hist_flag SMALLINT NULL,
             item_hist_flag SMALLINT NULL,
             credit_limit_flag SMALLINT NULL,
             credit_limit FLOAT NULL,
             aging_limit_flag SMALLINT NULL,
             aging_limit FLOAT NULL,
             restock_chg_flag SMALLINT NULL,
             restock_chg FLOAT NULL,
             prc_flag SMALLINT NULL,
             vend_acct VARCHAR(20) NULL,
             tax_id_num VARCHAR(20) NULL,
             flag_1099 SMALLINT NULL,
             exp_acct_code VARCHAR(32) NULL,
             amt_max_check FLOAT NULL,
             lead_time SMALLINT NULL,
             doc_ctrl_num VARCHAR(16) NULL,
             one_check_flag SMALLINT NULL,
             dup_voucher_flag SMALLINT NULL,
             dup_amt_flag SMALLINT NULL,
             code_1099 VARCHAR(8) NULL,
             user_trx_type_code VARCHAR(8) NULL,
             payment_code VARCHAR(8) NULL,
             limit_by_home SMALLINT NULL,
             rate_type_home VARCHAR(8) NULL,
             rate_type_oper VARCHAR(8) NULL,
             nat_cur_code VARCHAR(8) NULL,
             one_cur_vendor SMALLINT NULL,
             cash_acct_code VARCHAR(32) NULL,
             city VARCHAR(40) NOT NULL,
             state VARCHAR(40) NOT NULL,
             postal_code VARCHAR(15) NOT NULL,
             country VARCHAR(40) NOT NULL,
             freight_code VARCHAR(8),
             url VARCHAR(255) NOT NULL,
             note VARCHAR(255) NOT NULL,
             processed_flag int NULL,
             date_processed DATETIME NULL,
             batch_no INT NULL,
             record_id_num INT NULL,
             User_ID INT NULL,
             [attention_email] VARCHAR(255) NULL,
             [contact_email] VARCHAR(255) NULL,
             [ftp] VARCHAR(255) NULL,
             [country_code] VARCHAR(3) NULL)

    SET NOCOUNT ON
    
    IF @debug_level > 1
        BEGIN
        SELECT 'Import Manager 7.3'
        END

    DELETE imlog WHERE UPPER(module) = 'APVENDOR' AND ([User_ID] = @userid OR @userid = 0)
    IF @trial_flag = 1
        BEGIN
        INSERT INTO imlog VALUES (getdate(), 'APVENDOR', 1, '', '', '', 'Accounts Payable Vendors/Remit-Tos -- Begin (Validate) -- 7.3', @userid)
        END
    ELSE
        BEGIN
        INSERT INTO imlog VALUES (getdate(), 'APVENDOR', 1, '', '', '', 'Accounts Payable Vendors/Remit-Tos -- Begin (Copy) -- 7.3', @userid)
        END
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': Entry.'
    SET @Routine_Name = 'imapivend_sp'        
    SET @Error_Table_Name = 'imvnderr_vw'
    
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

    IF @imapivend_sp_Import_Identifier = 0
            OR @imapivend_sp_Import_Identifier IS NULL
        BEGIN
        SET @imapivend_sp_Import_Identifier = @Import_Identifier
        --
        -- Purge records from the im# reporting tables.
        --
        EXEC @SP_Result = [CVO_Control]..imreportdata_clear_sp @imreportdata_clear_sp_T1 = 'im#imapvnd',
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
        SET @Import_Identifier = @imapivend_sp_Import_Identifier
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
    EXEC @SP_Result = imapivend_Verify_Key_Data_sp @debug_level = @debug_level,
                                                   @userid = @userid
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' imapivend_Verify_Key_Data_sp 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Get Epicor User ID.
    --
    EXEC @SP_Result = imObtain_User_ID_sp @imObtain_User_ID_sp_Module = 'APVENDOR',
                                          @imObtain_User_ID_sp_User_ID = @Process_User_ID OUT,
                                          @imObtain_User_ID_sp_User_Name = @External_String OUT,
                                          @userid = @userid
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
    SET @company_code = RTRIM(LTRIM(ISNULL(@company_code, '')))
    --
    -- Validate parameters.
    --    
    IF NOT @address_type = 0
            AND NOT @address_type = 1
            AND NOT @address_type = 2
        BEGIN
        EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = 'invalid transaction type 1', 
                                                     @IGES_String = @External_String_1 OUT 
        EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = 'invalid transaction type 2', 
                                                     @IGES_String = @External_String_2 OUT 
        EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = 'invalid transaction type 3', 
                                                     @IGES_String = @External_String_3 OUT 
        EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = 'invalid transaction type 4', 
                                                     @IGES_String = @External_String_4 OUT 
        SET @External_String = @External_String_1 + ' ''''' + CAST(@address_type AS VARCHAR) + ''''' ' + @External_String_2 + ' ''''@address_type'''' ' + @External_String_3 + ' ''''' + @Routine_Name + ''''' ' + @External_String_4                                             
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
        SELECT @Reset_processed_flag = UPPER([Text Value])
                FROM [im_config] 
                WHERE UPPER([Item Name]) = 'RESET PROCESSED_FLAG'
        IF @@ROWCOUNT = 0
                OR @Reset_processed_flag IS NULL
                OR (NOT @Reset_processed_flag = 'NO' AND NOT @Reset_processed_flag = 'YES' AND NOT @Reset_processed_flag = 'TRUE' AND NOT @Reset_processed_flag = 'FALSE')
            SET @Reset_processed_flag = 'NO'
        IF @Reset_processed_flag = 'TRUE'
            SET @Reset_processed_flag = 'YES'
        END
    IF @Reset_processed_flag = 'YES'
        BEGIN
        UPDATE [imapvnd_vw]
                SET [processed_flag] = 0
                WHERE ([processed_flag] = 2 OR [processed_flag] IS NULL)
                        AND RTRIM(LTRIM(ISNULL([company_code], ''))) = @company_code
                        AND [address_type] = @address_type
                        AND ([User_ID] = @userid OR @userid = 0)
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imapvnd_vw 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
        END
    --    
    UPDATE [imapvnd_vw]
            SET [pay_to_code] = ''
            WHERE [pay_to_code] IS NULL    
                    AND ([User_ID] = @userid OR @userid = 0)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imapvnd 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    





    INSERT INTO [#imapvnd]
            SELECT RTRIM(LTRIM(ISNULL(company_code, ''))),
                   vendor_code,
                   pay_to_code,
                   address_name,
                   short_name,
                   addr1 varchar,
                   addr2 varchar,
                   addr3 varchar,
                   addr4 varchar,
                   addr5 varchar,
                   addr6 varchar,
                   addr_sort1,
                   addr_sort2,
                   addr_sort3,
                   address_type,
                   ISNULL(status_type, -1),
                   attention_name,
                   attention_phone,
                   contact_name,
                   contact_phone,
                   tlx_twx,
                   phone_1,
                   phone_2,
                   tax_code,
                   terms_code,
                   fob_code,
                   posting_code,
                   location_code,
                   orig_zone_code,
                   ISNULL(customer_code, ''),
                   ISNULL(affiliated_vend_code, ''),
                   ISNULL(alt_vendor_code, ''),
                   ISNULL(comment_code, ''),
                   ISNULL(vend_class_code, ''),
                   ISNULL(branch_code, ''),
                   ISNULL(pay_to_hist_flag, -1),
                   ISNULL(item_hist_flag, -1),
                   ISNULL(credit_limit_flag, -1),
                   credit_limit,
                   ISNULL(aging_limit_flag, -1),
                   ISNULL(aging_limit, -1),
                   ISNULL(restock_chg_flag, -1),
                   ISNULL(restock_chg, -1),
                   ISNULL(prc_flag, -1),
                   ISNULL(vend_acct, ''),
                   ISNULL(tax_id_num, ''),
                   ISNULL(flag_1099, -1),
                   ISNULL(exp_acct_code, ''),
                   ISNULL(amt_max_check, -1),
                   ISNULL(lead_time, -1),
                   ISNULL(doc_ctrl_num, ''),
                   ISNULL(one_check_flag, -1),
                   ISNULL(dup_voucher_flag, 0),
                   ISNULL(dup_amt_flag, -1),
                   ISNULL(code_1099, ''),
                   ISNULL(user_trx_type_code, ''),
                   ISNULL(payment_code, ''),
                   ISNULL(limit_by_home, -1),
                   ISNULL(rate_type_home, ''),
                   ISNULL(rate_type_oper, ''),
                   ISNULL(nat_cur_code, ''),
                   ISNULL(one_cur_vendor, -1),
                   ISNULL(cash_acct_code, ''),
                   city,
                   state,
                   postal_code,
                   country,
                   freight_code,
                   url,
                   note,
                   ISNULL(processed_flag, 0),
                   date_processed,
                   batch_no,
                   record_id_num,
                   [User_ID],
                   ISNULL([attention_email], ''),
                   ISNULL([contact_email], ''),
                   ISNULL([ftp], ''),
                   ISNULL([country_code], '')
            FROM [imapvnd_vw]
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #imapvnd 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    --
    -- Copy the staging tables to their temporary counterparts.
    --                
    SELECT *
            INTO [#imapvnd_vw]
            FROM [#imapvnd]
            WHERE RTRIM(LTRIM(ISNULL([company_code], ''))) = @company_code
                    AND [address_type] = @address_type
                    AND (NOT [processed_flag] = 1 OR [processed_flag] IS NULL)
                    AND ([User_ID] = @userid OR @userid = 0)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' #imapvnd_vw 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    UPDATE [#imapvnd_vw]
            SET [processed_flag] = 0    
    CREATE UNIQUE INDEX imapvnd_vw_Index_1 ON #imapvnd_vw 
            (company_code, 
            vendor_code, 
            pay_to_code, 
            address_type) 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATEINDEX + ' imapvnd_vw_Index_1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    DROP TABLE [#imapvnd]
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DROPTABLE + ' #imapvnd 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    IF @debug_level >= 3
        BEGIN
        SELECT '(3): ' + @Routine_Name + ': #imapvnd_vw at the beginning of the import:'
        SELECT *
                FROM [#imapvnd_vw]
        END        
    --
    -- Set the [Import Identifier] column in the header/main table.
    --        
    UPDATE [imapvnd_vw]
            SET [Import Identifier] = @Import_Identifier
            WHERE RTRIM(LTRIM(ISNULL([company_code], ''))) = @company_code
                    AND (NOT [processed_flag] = 1 OR [processed_flag] IS NULL)
                    AND [address_type] = @address_type
                    AND ([User_ID] = @userid OR @userid = 0)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imapvnd_vw 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Global validations.
    --
    SELECT @Record_Count = COUNT(*) 
            FROM [imapdft]
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' imapdft 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    IF @Record_Count = 0        
        BEGIN
        EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = 'imapdft empty', 
                                                     @IGES_String = @External_String OUT 
        EXEC im_log_sp @IL_Text = @External_String,
                       @IL_Log_Activity = 'YES',
                       @im_log_sp_User_ID = @userid
        GOTO Error_Return
        END
    --
    -- If processing vendors (or "one-time" vendors) then the pay_to_code field
    -- cannot be populated.  Issue an error message if any of the records contain data
    -- in the pay_to_code field.
    --    
    IF @address_type = 0
            OR @address_type = 2
        BEGIN
        SELECT @Record_Count = COUNT(*) 
                FROM [#imapvnd_vw]
                WHERE NOT DATALENGTH(LTRIM(RTRIM(ISNULL([pay_to_code], '')))) = 0
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' imapdft 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
        IF @Record_Count > 0        
            BEGIN
            EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = 'Vendors pay_to_code present 1', 
                                                         @IGES_String = @External_String OUT 
            EXEC im_log_sp @IL_Text = @External_String,
                           @IL_Log_Activity = 'YES',
                           @im_log_sp_User_ID = @userid
            EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = 'Vendors pay_to_code present 2', 
                                                         @IGES_String = @External_String OUT 
            EXEC im_log_sp @IL_Text = @External_String,
                           @IL_Log_Activity = 'YES',
                           @im_log_sp_User_ID = @userid
            GOTO Error_Return
            END
        END        
    --
    -- Make sure pay_to_code is an empty string for vendors.
    --
    IF @address_type = 0
            OR @address_type = 2
        BEGIN    
        UPDATE [#imapvnd_vw]
                SET [pay_to_code] = ''
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imapvnd_vw 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        END
    --
    -- Perform main import. 
    --
    EXEC @SP_Result = imapivend1_sp @company_code, 
                                    @address_type, 
                                    @trial_flag, 
                                    @debug_level,
                                    @userid
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' imapivend1_sp 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    IF NOT @SP_Result = 0
        BEGIN
        EXEC im_log_sp_error_sp @ILSE_Error_Code = @SP_Result,
                                @ILSE_SP_Name = 'imapivend1_sp',
                                @ILSE_String = '',
                                @ILSE_Procedure_Name = @Routine_Name,
                                @ILSE_Log_Activity = 'YES',
                                @im_log_sp_error_sp_User_ID = @userid
        GOTO Error_Return
        END                                 
    EXEC @SP_Result = imapivend2_sp @company_code, 
                                    @address_type, 
                                    @trial_flag, 
                                    @debug_level,
                                    @Import_Identifier,
                                    @userid
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' imapivend2_sp 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    IF NOT @SP_Result = 0
        BEGIN
        EXEC im_log_sp_error_sp @ILSE_Error_Code = @SP_Result,
                                @ILSE_SP_Name = 'imapivend2_sp',
                                @ILSE_String = '',
                                @ILSE_Procedure_Name = @Routine_Name,
                                @ILSE_Log_Activity = 'YES',
                                @im_log_sp_error_sp_User_ID = @userid
        GOTO Error_Return
        END 
    IF @debug_level >= 3
        BEGIN
        SELECT '(3): ' + @Routine_Name + ': #imapvnd_vw at the end of the import:'
        SELECT *
                FROM [#imapvnd_vw]
        SELECT '(3): ' + @Routine_Name + ': imvnderr_vw at the end of the import:'
        SELECT *
                FROM [imvnderr_vw]
        END        
    IF @address_type = 0
            OR @address_type = 2
        BEGIN    
        INSERT INTO imlog VALUES (getdate(), 'APVENDOR', 1, '', '', '', 'Accounts Payable Vendors -- Import Identifier = ' + CAST(@Import_Identifier AS VARCHAR), @userid)
        END
    ELSE    
        BEGIN    
        INSERT INTO imlog VALUES (getdate(), 'APVENDOR', 1, '', '', '', 'Accounts Payable Remit-Tos -- Import Identifier = ' + CAST(@Import_Identifier AS VARCHAR), @userid)
        END
    INSERT INTO imlog VALUES (getdate(), 'APVENDOR', 1, '', '', '', 'Accounts Payable Vendors/Remit-Tos -- End', @userid)
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': Exit.'
    RETURN 0
Error_Return:
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': Exit (ERROR).'      
    RETURN -1    
GO
GRANT EXECUTE ON  [dbo].[imapivend_sp] TO [public]
GO
