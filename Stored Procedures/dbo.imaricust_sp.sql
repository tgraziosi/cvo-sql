SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


    CREATE PROC 
[dbo].[imaricust_sp] @company_code VARCHAR(8),
             @address_type int,
             @trial_flag int,
             @debug_level INT = 0,
             @userid INT = 0,
             @imaricust_sp_process_ctrl_num VARCHAR(16) = '' OUTPUT,
             @imaricust_sp_dummy VARCHAR(16) = '' OUTPUT,
             @imaricust_sp_Import_Identifier INT = 0 OUTPUT,
             @imaricust_sp_Override_User_Name VARCHAR(30) = ''
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
    

    SET NOCOUNT ON
    
    IF @debug_level > 1
        BEGIN
        SELECT 'Import Manager 7.3.6'
        END

    
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
    

    DECLARE @Customer_Number_Cursor_Allocated VARCHAR(3)
    DECLARE @Customer_Number_Cursor_Opened VARCHAR(3)    
    DECLARE @Customer_Number_customer_code VARCHAR(35)
    DECLARE @Customer_Number_INT INT
    DECLARE @Customer_Number_record_id_num INT
    SET @Routine_Name = 'imaricust_sp'        
    SET @Error_Table_Name = 'imcuserr_vw'
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': Entry.'
    
CREATE TABLE #imarcust 
       (company_code VARCHAR(8) NULL,
        customer_code VARCHAR(8) NULL,
        ship_to_code VARCHAR(8) NULL,
        address_name VARCHAR(40) NULL,
        short_name VARCHAR(10) NULL,
        addr1 VARCHAR(40) NULL,
        addr2 VARCHAR(40) NULL,
        addr3 VARCHAR(40) NULL,
        addr4 VARCHAR(40) NULL,
        addr5 VARCHAR(40) NULL,
        addr6 VARCHAR(40) NULL,
        addr_sort1 VARCHAR(40) NULL,
        addr_sort2 VARCHAR(40) NULL,
        addr_sort3 VARCHAR(40) NULL,
        address_type SMALLINT NULL,
        status_type SMALLINT NULL,
        attention_name VARCHAR(40) NULL,
        attention_phone VARCHAR(30) NULL,
        contact_name VARCHAR(40) NULL,
        contact_phone VARCHAR(30) NULL,
        tlx_twx VARCHAR(30) NULL,
        phone_1 VARCHAR(30) NULL,
        phone_2 VARCHAR(30) NULL,
        tax_code VARCHAR(8) NULL,
        terms_code VARCHAR(8) NULL,
        fob_code VARCHAR(8) NULL,
        freight_code VARCHAR(8) NULL,
        posting_code VARCHAR(8) NULL,
        location_code VARCHAR(8) NULL,
        alt_location_code VARCHAR(8) NULL,
        dest_zone_code VARCHAR(8) NULL,
        territory_code VARCHAR(8) NULL,
        salesperson_code VARCHAR(8) NULL,
        fin_chg_code VARCHAR(8) NULL,
        price_code VARCHAR(8) NULL,
        payment_code VARCHAR(8) NULL,
        vendor_code VARCHAR(12) NULL,
        affiliated_cust_code VARCHAR(8) NULL,
        print_stmt_flag SMALLINT NULL,
        stmt_cycle_code VARCHAR(8) NULL,
        inv_comment_code VARCHAR(8) NULL,
        stmt_comment_code VARCHAR(8) NULL,
        dunn_message_code VARCHAR(8) NULL,
        note VARCHAR(255) NULL,
        trade_disc_percent float NULL,
        invoice_copies SMALLINT NULL,
        iv_substitution SMALLINT NULL,
        ship_to_history SMALLINT NULL,
        check_credit_limit SMALLINT NULL,
        credit_limit float NULL,
        check_aging_limit SMALLINT NULL,
        aging_limit_bracket SMALLINT NULL,
        bal_fwd_flag SMALLINT NULL,
        ship_complete_flag SMALLINT NULL,
        resale_num VARCHAR(30) NULL,
        db_num VARCHAR(20) NULL,
        db_date int NULL,
        db_credit_rating VARCHAR(20) NULL,
        late_chg_type SMALLINT NULL,
        valid_payer_flag SMALLINT NULL,
        valid_soldto_flag SMALLINT NULL,
        valid_shipto_flag SMALLINT NULL,
        payer_soldto_rel_code char(8) NULL,
        across_na_flag SMALLINT NULL,
        date_opened VARCHAR(10) NULL,
        added_by_user_name VARCHAR(30) NULL,
        added_by_date VARCHAR(10) NULL,
        modified_by_user_name VARCHAR(30) NULL,
        modified_by_date VARCHAR(10) NULL,
        rate_type_home VARCHAR(8) NULL,
        rate_type_oper VARCHAR(8) NULL,
        limit_by_home SMALLINT NULL,
        nat_cur_code VARCHAR(8) NULL,
        one_cur_cust SMALLINT NULL,
        city VARCHAR(40) NULL,
        state VARCHAR(40) NULL,
        postal_code VARCHAR(15) NULL,
        country VARCHAR(40) NULL,
        remit_code VARCHAR(10) NULL,
        forwarder_code VARCHAR(10) NULL,
        freight_to_code VARCHAR(10) NULL,
        route_code VARCHAR(10) NULL,
        route_no int NULL,
        url VARCHAR(50) NULL,
        special_instr VARCHAR(255) NULL,
        guid VARCHAR(32) NULL,
        price_level char(1) NULL,
        ship_via_code VARCHAR(8) NULL,
        processed_flag int NULL,
        date_processed datetime NULL,
        batch_no INT NULL,
        record_id_num INT NULL,
        User_ID INT NULL,
        [contact_email] VARCHAR(255) NULL,
        [attention_email] VARCHAR(255) NULL,
        [ftp] VARCHAR(255) NULL,
        [dunning_group_id] VARCHAR(8) NULL,
        [consolidated_invoices] SMALLINT NULL,
        [writeoff_code] VARCHAR(8) NULL)

    DELETE imlog WHERE UPPER(module) = 'ARCUSTOMER' AND ([User_ID] = @userid OR @userid = 0)
    IF @trial_flag = 1
        BEGIN
        INSERT INTO imlog VALUES (getdate(), 'ARCUSTOMER', 1, '', '', '', 'Accounts Receivable Customers/Ship-Tos -- Begin (Validate) -- 7.3.6', @userid)
        END
    ELSE
        BEGIN
        INSERT INTO imlog VALUES (getdate(), 'ARCUSTOMER', 1, '', '', '', 'Accounts Receivable Customers/Ship-Tos -- Begin (Copy) -- 7.3.6', @userid)
        END
    
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

    IF @imaricust_sp_Import_Identifier = 0
            OR @imaricust_sp_Import_Identifier IS NULL
        BEGIN
        SET @imaricust_sp_Import_Identifier = @Import_Identifier
        --
        -- Purge records from the im# reporting tables.
        --
        EXEC @SP_Result = [CVO_Control]..imreportdata_clear_sp @imreportdata_clear_sp_T1 = 'im#imarcust',
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
        SET @Import_Identifier = @imaricust_sp_Import_Identifier
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
    EXEC @SP_Result = imaricust_Verify_Key_Data_sp @debug_level = @debug_level,
                                                   @userid = @userid
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' imaricust_Verify_Key_Data_sp 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Get Epicor User ID.
    --
    EXEC @SP_Result = imObtain_User_ID_sp @imObtain_User_ID_sp_Module = 'ARCUSTOMER',
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
        UPDATE [imarcust_vw]
                SET [processed_flag] = 0
                WHERE ([processed_flag] = 2 OR [processed_flag] IS NULL)
                        AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
                        AND [address_type] = @address_type
                        AND ([User_ID] = @userid OR @userid = 0)
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imarcust_vw 1A' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        END
    --
    -- Assign customer numbers for all records with a blank in customer_code.
    -- The permanent staging table is updated rather than the temporary counterpart
    -- because customer_code is needed to link the staging table records to any error
    -- records, etc.  This also allows the workbench user to see the assigned customer
    -- numbers in the grid after the import.
    --
    DECLARE Customer_Number_Cursor INSENSITIVE CURSOR FOR 
            SELECT [record_id_num] 
            FROM [imarcust_vw] 
            WHERE DATALENGTH(LTRIM(RTRIM(ISNULL([customer_code], '')))) = 0
                    AND ([processed_flag] = 0 OR [processed_flag] IS NULL)
                    AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
                    AND [address_type] = @address_type
                    AND ([User_ID] = @userid OR @userid = 0)
            ORDER BY [record_id_num]
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DECLARE + ' Customer_Number_Cursor 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
    SET @Customer_Number_Cursor_Allocated = 'YES'        
    OPEN Customer_Number_Cursor
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_OPEN + ' Customer_Number_Cursor 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
    SET @Customer_Number_Cursor_Opened = 'YES'        
    FETCH NEXT
            FROM Customer_Number_Cursor
            INTO @Customer_Number_record_id_num
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_FETCHNEXT + ' Customer_Number_Cursor 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
    WHILE NOT @@FETCH_STATUS = -1
        BEGIN
        EXEC ARGetNextControl_SP @num_type = 2090,
                                 @masked = @Customer_Number_customer_code OUTPUT,
                                 @num = @Customer_Number_INT OUTPUT,
                                 @debug_level = @debug_level
        UPDATE [imarcust_vw]
                SET [customer_code] = RTRIM(LTRIM(ISNULL(@Customer_Number_customer_code, '')))
                WHERE [record_id_num] = @Customer_Number_record_id_num
        FETCH NEXT
                FROM Customer_Number_Cursor
                INTO @Customer_Number_record_id_num
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_FETCHNEXT + ' Customer_Number_Cursor 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
        END
    CLOSE Customer_Number_Cursor
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CLOSE + ' Customer_Number_Cursor 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
    SET @Customer_Number_Cursor_Opened = 'NO'
    DEALLOCATE Customer_Number_Cursor
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DEALLOCATE + ' Customer_Number_Cursor 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
    SET @Customer_Number_Cursor_Allocated = 'NO'
    --
    



    INSERT INTO [#imarcust]
            SELECT RTRIM(LTRIM(ISNULL(ISNULL(company_code, ''), ''))),
                   customer_code,
                   ISNULL(ship_to_code, ''),
                   ISNULL(address_name, ''),
                   ISNULL(short_name, ''),
                   ISNULL(addr1, ''),
                   ISNULL(addr2, ''),
                   ISNULL(addr3, ''),
                   ISNULL(addr4, ''),
                   ISNULL(addr5, ''),
                   ISNULL(addr6, ''),
                   ISNULL(addr_sort1, ''),
                   ISNULL(addr_sort2, ''),
                   ISNULL(addr_sort3, ''),
                   ISNULL(address_type, 0),
                   ISNULL(status_type, 0),
                   ISNULL(attention_name, ''),
                   ISNULL(attention_phone, ''),
                   ISNULL(contact_name, ''),
                   ISNULL(contact_phone, ''),
                   ISNULL(tlx_twx, ''),
                   ISNULL(phone_1, ''),
                   ISNULL(phone_2, ''),
                   ISNULL(tax_code, ''),
                   ISNULL(terms_code, ''),
                   ISNULL(fob_code, ''),
                   ISNULL(freight_code, ''),
                   ISNULL(posting_code, ''),
                   ISNULL(location_code, ''),
                   ISNULL(alt_location_code, ''),
                   ISNULL(dest_zone_code, ''),
                   ISNULL(territory_code, ''),
                   ISNULL(salesperson_code, ''),
                   ISNULL(fin_chg_code, ''),
                   ISNULL(price_code, ''),
                   ISNULL(payment_code, ''),
                   ISNULL(vendor_code, ''),
                   ISNULL(affiliated_cust_code, ''),
                   ISNULL(print_stmt_flag, -1),
                   ISNULL(stmt_cycle_code, ''),
                   ISNULL(inv_comment_code, ''),
                   ISNULL(stmt_comment_code, ''),
                   ISNULL(dunn_message_code, ''),
                   ISNULL(note, ''),
                   ISNULL(trade_disc_percent, -1),
                   ISNULL(invoice_copies, -1),
                   ISNULL(iv_substitution, -1),
                   ISNULL(ship_to_history, -1),
                   ISNULL(check_credit_limit, -1),
                   credit_limit,
                   ISNULL(check_aging_limit, -1),
                   ISNULL(aging_limit_bracket, -1),
                   ISNULL(bal_fwd_flag, -1),
                   ISNULL(ship_complete_flag, -1),
                   ISNULL(resale_num, ''),
                   ISNULL(db_num, ''),
                   ISNULL(db_date, -1),
                   ISNULL(db_credit_rating, ''),
                   ISNULL(late_chg_type, -1),
                   ISNULL(valid_payer_flag, -1),
                   ISNULL(valid_soldto_flag, -1),
                   ISNULL(valid_shipto_flag, -1),
                   ISNULL(payer_soldto_rel_code, ''),
                   ISNULL(across_na_flag, -1),
                   date_opened,
                   ISNULL(added_by_user_name, ''),
                   added_by_date,
                   ISNULL(modified_by_user_name, ''),
                   modified_by_date,
                   ISNULL(rate_type_home, ''),
                   ISNULL(rate_type_oper, ''),
                   ISNULL(limit_by_home, -1),
                   ISNULL(nat_cur_code, ''),
                   ISNULL(one_cur_cust, -1),
                   ISNULL(city, ''),
                   ISNULL(state, ''),                 
                   ISNULL(postal_code, ''),
                   ISNULL(country, ''),
                   ISNULL(remit_code, ''),
                   ISNULL(forwarder_code, ''),
                   ISNULL(freight_to_code, ''),
                   ISNULL(route_code, ''),
                   ISNULL(route_no,0),
                   ISNULL(url, ''),
                   ISNULL(special_instr, ''),
                   ISNULL(guid, ''),
                   ISNULL(price_level, ''),
                   ISNULL(ship_via_code, ''),
                   ISNULL(processed_flag, 0),
                   date_processed,
                   batch_no,
                   record_id_num,
                   User_ID,
                   ISNULL([contact_email], ''),
                   ISNULL([attention_email], ''),
                   ISNULL([ftp], ''),
                   ISNULL([dunning_group_id], ''),
                   ISNULL([consolidated_invoices], 0),
                   ISNULL([writeoff_code], '')
                FROM [imarcust_vw]
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' #imarcust 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Copy the staging tables to their temporary counterparts.
    --
    SELECT *
            INTO [#imarcust_vw]
            FROM [#imarcust]
            WHERE [address_type] = @address_type
                    AND RTRIM(LTRIM(ISNULL([company_code], ''))) = @company_code
                    AND (NOT [processed_flag] = 1 OR [processed_flag] IS NULL)
                    AND ([User_ID] = @userid OR @userid = 0)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' #imarcust_vw 1A' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE [#imarcust_vw]
            SET [processed_flag] = 0    
    CREATE UNIQUE INDEX imarcust_vw_Index_1 ON #imarcust_vw 
            (company_code, 
            customer_code,
            ship_to_code,
            address_type) 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATEINDEX + ' imarcust_vw_Index_1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    DROP TABLE [#imarcust]
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DROPTABLE + ' #imarcust 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    IF @debug_level >= 3
        BEGIN
        SELECT '(3): ' + @Routine_Name + ': #imarcust_vw at the beginning of the import:'
        SELECT *
                FROM [#imarcust_vw]
        END        
    --
    -- Set the [Import Identifier] column in the header/main table.
    --        
    UPDATE [imarcust_vw]
            SET [Import Identifier] = @Import_Identifier
            WHERE RTRIM(LTRIM(ISNULL([company_code], ''))) = @company_code
                    AND (NOT [processed_flag] = 1 OR [processed_flag] IS NULL)
                    AND [address_type] = @address_type
                    AND ([User_ID] = @userid OR @userid = 0)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imarcust_vw 1A' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    EXEC @SP_Result = imaricust1_sp @company_code, 
                                    @address_type, 
                                    @trial_flag, 
                                    @debug_level,
                                    @userid
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' imarcust1_sp' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    IF NOT @SP_Result = 0
        BEGIN
        EXEC im_log_sp_error_sp @ILSE_Error_Code = @SP_Result,
                                @ILSE_SP_Name = 'imaricust1_sp',
                                @ILSE_String = '',
                                @ILSE_Procedure_Name = @Routine_Name,
                                @ILSE_Log_Activity = 'YES',
                                @im_log_sp_error_sp_User_ID = @userid
        GOTO Error_Return
        END    
    EXEC @SP_Result = imaricust2_sp @company_code, 
                                    @address_type, 
                                    @trial_flag, 
                                    @debug_level,
                                    @imaricust_sp_Import_Identifier,
                                    @userid
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' imarcust2_sp' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    IF NOT @SP_Result = 0
        BEGIN
        EXEC im_log_sp_error_sp @ILSE_Error_Code = @SP_Result,
                                @ILSE_SP_Name = 'imaricust2_sp',
                                @ILSE_String = '',
                                @ILSE_Procedure_Name = @Routine_Name,
                                @ILSE_Log_Activity = 'YES',
                                @im_log_sp_error_sp_User_ID = @userid
        GOTO Error_Return
        END
    IF @debug_level >= 3
        BEGIN
        SELECT '(3): ' + @Routine_Name + ': #imarcust_vw at the end of the import:'
        SELECT *
                FROM [#imarcust_vw]
        SELECT '(3): ' + @Routine_Name + ': imcuserr_vw at the end of the import:'
        SELECT *
                FROM [imcuserr_vw]
        END        
    IF @address_type = 0
        BEGIN        
        INSERT INTO imlog VALUES (getdate(), 'ARCUSTOMER', 1, '', '', '', 'Accounts Receivable Customers -- Import Identifier = ' + CAST(@Import_Identifier AS VARCHAR), @userid)
        END
    ELSE
        BEGIN        
        INSERT INTO imlog VALUES (getdate(), 'ARCUSTOMER', 1, '', '', '', 'Accounts Receivable Ship-Tos -- Import Identifier = ' + CAST(@Import_Identifier AS VARCHAR), @userid)
        END
    INSERT INTO imlog VALUES (getdate(), 'ARCUSTOMER', 1, '', '', '', 'Accounts Receivable Customers/Ship-Tos -- End', @userid)
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': Exit.'
    RETURN 0
Error_Return:
    IF @Customer_Number_Cursor_Opened = 'YES'
        CLOSE Customer_Number_Cursor        
    IF @Customer_Number_Cursor_Allocated = 'YES'
        DEALLOCATE Customer_Number_Cursor    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': Exit (ERROR).'
    RETURN -1    
GO
GRANT EXECUTE ON  [dbo].[imaricust_sp] TO [public]
GO
