SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


    CREATE PROC 
[dbo].[imglintsp_sp] @company_code VARCHAR(8),
             @init_mode SMALLINT,
             @method_flag SMALLINT,
             @debug_level INT,
             @userid INT = 0,
             @imglintsp_sp_process_ctrl_num VARCHAR(16) = '' OUTPUT,
             @imglintsp_sp_dummy VARCHAR(16) = '' OUTPUT,
             @imglintsp_sp_Import_Identifier INT = 0 OUTPUT,
             @imglintsp_sp_Override_User_Name VARCHAR(30) = '' 
    AS 
    DECLARE @document_1 VARCHAR(16),
            @glcomp_vw_db_name VARCHAR(128),
            @last_document_1 VARCHAR(16),
            @result INT,
            @journal_ctrl_num CHAR(16),
            @process_ctrl_num CHAR(16),
            @journal_description CHAR(30),
            @date_entered INT,
            @date_applied INT,
            @reversing_flag SMALLINT,
            @type_flag SMALLINT,
            @intercompany_flag SMALLINT,
            @rec_company_code CHAR(8),
            @description CHAR(40),
            @document_2 CHAR(16),
            @reference_code CHAR(32),
            @balance FLOAT,
            @nat_balance FLOAT,
            @nat_cur_code VARCHAR(8),
            @rate FLOAT,
            @total FLOAT,
            @total_natural FLOAT,
            @module_id SMALLINT,
            @val_mode INT,
            @GLTM_IMMEDIATE SMALLINT,
            @GLTM_DELAYED SMALLINT,
            @0 INT,
            @trx_type SMALLINT,
            @batch_code CHAR(8),
            @source_batch_code CHAR(16),
            @source_company_code CHAR(8),
            @hold_flag SMALLINT,
            @err_msg CHAR(80),
            @last_sequence_id INT,
            @account_code VARCHAR(32),
            @seg1_code VARCHAR(32),
            @seg2_code VARCHAR(32),
            @seg3_code VARCHAR(32),
            @seg4_code VARCHAR(32),
            @sequence_id INT,
            @offset_flag INT,
            @recurring_flag SMALLINT,
            @repeating_flag SMALLINT,
            @journal_type CHAR(8),
            @home_cur_code CHAR(8),
            @seq_ref_id INT,
            @process_description VARCHAR(40), 
            @process_parent_app SMALLINT, 
            @process_parent_company VARCHAR(8),
            @error_flag SMALLINT,
            @max_sequence INT,
            @description_seg2 CHAR(40),
            @description_seg3 CHAR(40),
            @date_today INT,
            @process_host_id VARCHAR(8),
            @process_kpid INT,
            @rowcount INT,
            @precision_gl SMALLINT,
            @oper_currency_code VARCHAR(8),
            @home_currency_code CHAR(8),
            @oper_rate_type CHAR(8),
            @home_rate_type CHAR(8),
            @rate_type_oper CHAR(8),
            @rate_type_home CHAR(8),
            @rate_oper FLOAT,
            @balance_oper FLOAT,
            @max_value SMALLINT,
            @date_processed     datetime
    DECLARE @apply_date_error CHAR(80)
    DECLARE @batch_flag INT
    DECLARE @batch_type SMALLINT
    DECLARE @Current_Detail_Record_Number INT
    DECLARE @Current_Header_Record_Number INT
    DECLARE @cur_date INT
    DECLARE @cur_time INT
    DECLARE @Database_Names_Cursor_Allocated VARCHAR(3)
    DECLARE @Database_Names_company_code VARCHAR(8)
    DECLARE @Database_Names_Cursor_Opened VARCHAR(3)
    DECLARE @Database_Names_db_name VARCHAR(128)
    DECLARE @entry_date_error CHAR(80)
    DECLARE @IMGL_journal_ctrl_num INT
    DECLARE @im_config_Overwrite_document_2 VARCHAR(5)
    DECLARE @mask VARCHAR(16)
    DECLARE @Monotonic_document_1 VARCHAR(16)
    DECLARE @Monotonic_Previous_document_1 VARCHAR(32)
    DECLARE @Monotonic_sequence_id INT
    DECLARE @Monotonic_Computed_sequence_id INT
    DECLARE @Monotonic_Cursor_Allocated VARCHAR(3)
    DECLARE @Monotonic_Cursor_Opened VARCHAR(3)
    DECLARE @new_bcn VARCHAR(16)
    DECLARE @next_number INT
    DECLARE @ret_status INT
    DECLARE @tran_started INT
    DECLARE @trial_flag SMALLINT
    DECLARE @Total_Detail_Records INT
    DECLARE @Total_Header_Records INT
    DECLARE @User_Name VARCHAR(30)
    DECLARE @Zero_Rate_Cursor_Allocated VARCHAR(3)
    DECLARE @Zero_Rate_Cursor_Opened VARCHAR(3)
    DECLARE @Zero_Rate_from_currency VARCHAR(8)
    DECLARE @Zero_Rate_to_currency VARCHAR(8)
    DECLARE @Zero_Rate_rate_type VARCHAR(8)
    DECLARE @org_id VARCHAR(30)
    DECLARE @interbranch_flag smallint
    DECLARE @org_id_det	 VARCHAR(30)
	

    SET NOCOUNT ON
    
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

    DELETE imlog WHERE UPPER(module) = 'GLTRX' AND ([User_ID] = @userid OR @userid = 0)
    IF @method_flag = 2
        BEGIN
        INSERT INTO imlog VALUES (getdate(), 'GLTRX', 1, '', '', '', 'General Ledger Transactions -- Begin (Copy) -- 7.3', @userid)
        END
    ELSE
        BEGIN
        INSERT INTO imlog VALUES (getdate(), 'GLTRX', 1, '', '', '', 'General Ledger Transactions -- Begin (Validate) -- 7.3', @userid)
        END
    SET @Routine_Name = 'imglintsp_sp'        
    SET @Error_Table_Name = 'imglterr_vw'
    
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

    SET @IMGL_journal_ctrl_num = 0
    SET @Monotonic_Cursor_Allocated = 'NO'
    SET @Monotonic_Cursor_Opened = 'NO'
    IF @imglintsp_sp_Import_Identifier = 0
            OR @imglintsp_sp_Import_Identifier IS NULL
        BEGIN
        SET @imglintsp_sp_Import_Identifier = @Import_Identifier
        --
        -- Purge records from the im# reporting tables.
        --
        EXEC @SP_Result = [CVO_Control]..imreportdata_clear_sp @imreportdata_clear_sp_T1 = 'im#imglhdr',
                                                            @imreportdata_clear_sp_T2 = 'im#imgldtl',
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
        SET @Import_Identifier = @imglintsp_sp_Import_Identifier
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
    EXEC @SP_Result = imglintsp_Verify_Key_Data_sp @debug_level = @debug_level,
                                                   @userid = @userid
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' imglintsp_Verify_Key_Data_sp 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Get Epicor User ID.
    --
    EXEC @SP_Result = imObtain_User_ID_sp @imObtain_User_ID_sp_Module = 'GLTRX',
                                          @imObtain_User_ID_sp_User_ID = @Process_User_ID OUT,
                                          @imObtain_User_ID_sp_User_Name = @External_String OUT,
                                          @userid = @userid,
                                          @imObtain_User_ID_sp_Override_User_Name = @imglintsp_sp_Override_User_Name
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
    CREATE TABLE [#gltrx] (mark_flag SMALLINT, 
                           next_seq_id INT,  
                           trx_state SMALLINT, 
                           journal_type VARCHAR(8),  
                           journal_ctrl_num VARCHAR(16),   
                           journal_description VARCHAR(30),   
                           date_entered INT, 
                           date_applied INT,  
                           recurring_flag SMALLINT,
                           repeating_flag SMALLINT,  
                           reversing_flag SMALLINT, 
                           hold_flag SMALLINT,  
                           posted_flag SMALLINT, 
                           date_posted INT,  
                           source_batch_code VARCHAR(16),  
                           process_group_num VARCHAR(16),  
                           batch_code VARCHAR(16),  
                           type_flag SMALLINT, 
                           intercompany_flag SMALLINT,  
                           company_code VARCHAR(8),   
                           app_id SMALLINT,  
                           home_cur_code VARCHAR(8),   
                           document_1 VARCHAR(16),  
                           trx_type SMALLINT,  
                           user_id SMALLINT, 
                           source_company_code VARCHAR(8), 
                           oper_cur_code VARCHAR(8),	
			   org_id	varchar(30) NULL,
			   interbranch_flag	smallint NULL)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATETABLE + ' #gltrx 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END         
    CREATE UNIQUE CLUSTERED INDEX #gltrx_ind_0 
            ON #gltrx ( journal_ctrl_num ) 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATETABLE + ' #gltrx_ind_0 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END         
    CREATE TABLE [#gltrxdet] (mark_flag SMALLINT,  
                              trx_state SMALLINT, 
                              journal_ctrl_num VARCHAR(16),  
                              sequence_id INT, 
                              rec_company_code VARCHAR(8),   
                              company_id SMALLINT, 
                              account_code VARCHAR(32),   
                              description VARCHAR(40), 
                              document_1 VARCHAR(16),   
                              document_2 VARCHAR(16),  
                              reference_code VARCHAR(32),  
                              balance FLOAT,   
                              nat_balance FLOAT, 
                              nat_cur_code VARCHAR(8),   
                              rate FLOAT,   
                              posted_flag SMALLINT, 
                              date_posted INT,  
                              trx_type SMALLINT,  
                              offset_flag SMALLINT, 
                              seg1_code VARCHAR(32),  
                              seg2_code VARCHAR(32), 
                              seg3_code VARCHAR(32),  
                              seg4_code VARCHAR(32),  
                              seq_ref_id INT,
                              balance_oper FLOAT, 
                              rate_oper FLOAT, 
                              rate_type_home VARCHAR(8), 
                              rate_type_oper VARCHAR(8),
			      org_id			varchar(30) NULL)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATETABLE + ' #gltrxdet 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END         
    CREATE UNIQUE CLUSTERED INDEX #gltrxdet_ind_0 
            ON #gltrxdet (journal_ctrl_num, sequence_id ) 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATETABLE + ' #gltrxdet_ind_0 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END         
    CREATE NONCLUSTERED INDEX #gltrxdet_ind_1 
            ON #gltrxdet (journal_ctrl_num,nat_cur_code ) 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATETABLE + ' #gltrxdet_ind_1 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END         
    CREATE TABLE [#trxerror] (journal_ctrl_num VARCHAR(16),  
                              sequence_id INT, 
                              error_code INT)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATETABLE + ' #trxerror 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END         
    CREATE NONCLUSTERED INDEX #trxerror_ind_0 
            ON #trxerror ( journal_ctrl_num,  sequence_id, error_code ) 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATETABLE + ' #trxerror_ind_0 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END         
    CREATE TABLE [#batches] (date_applied INT,  
                             source_batch_code VARCHAR(16))
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATETABLE + ' #batches 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END         
    CREATE UNIQUE CLUSTERED INDEX #batches_ind_0 
            ON #batches (date_applied,  source_batch_code ) 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATETABLE + ' #batches_ind_0 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END         
   CREATE TABLE	#offsets (
		journal_ctrl_num	varchar(16)	 NULL,
		sequence_id		int	  NULL,
		company_code		varchar(8)	  NULL,
		company_id		smallint	  NULL,
		org_ic_acct  		varchar(32)	  NULL,
		org_seg1_code		varchar(32)	  NULL,
		org_seg2_code		varchar(32)	  NULL,
		org_seg3_code		varchar(32)	  NULL,
		org_seg4_code		varchar(32)	  NULL,
		org_org_id		    varchar(30)   NULL,
		rec_ic_acct  		varchar(32)	  NULL,
		rec_seg1_code		varchar(32)	  NULL,
		rec_seg2_code		varchar(32)	  NULL,
		rec_seg3_code		varchar(32)	  NULL,
		rec_seg4_code		varchar(32)	  NULL,
		rec_org_id		    varchar(30)   NULL )
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATETABLE + ' #offsets 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END         
    CREATE UNIQUE CLUSTERED INDEX #offsets_ind_0 
            ON #offsets ( journal_ctrl_num, sequence_id ) 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATETABLE + ' #offsets_ind_0 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END         
    CREATE TABLE [#offset_accts] (account_code VARCHAR(32),  
                                  org_code VARCHAR(8), 
                                  rec_code VARCHAR(8),  
                                  sequence_id INT ) 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATETABLE + ' #offset_accts 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END         
    CREATE UNIQUE CLUSTERED INDEX #offset_accts_ind_0  
            ON #offset_accts( rec_code, account_code, org_code ) 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATETABLE + ' #offset_accts_ind_0 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END         
    CREATE TABLE [#pcontrol] (process_ctrl_num VARCHAR(16),
                              process_parent_app SMALLINT,
                              process_parent_company VARCHAR(8),  
                              process_description VARCHAR(40),
                              process_user_id SMALLINT,
                              process_server_id INT,  
                              process_host_id VARCHAR(8),
                              process_kpid INT,
                              process_start_date datetime,
                              process_end_date datetime NULL, 
                              process_state SMALLINT)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATETABLE + ' #pcontrol 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END         
    CREATE UNIQUE CLUSTERED INDEX #pcontrol_ind_0
            ON #pcontrol ( process_ctrl_num ) 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATETABLE + ' #pcontrol_ind_0 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    --         
    -- Initialize variables
    --
    SELECT @module_id = 6000,
           @offset_flag = 0,
           @sequence_id = 0,
           @recurring_flag = 0,
           @repeating_flag = 0,
           @reversing_flag = 0,
           @source_batch_code = '',
           @batch_code = '',
           @hold_flag = 0,
           @journal_ctrl_num = '',
           @GLTM_IMMEDIATE = 1,
           @GLTM_DELAYED = 2,
           @offset_flag = 0,
           @seq_ref_id = 0,
           @0 = 0,
           @process_description = 'Import Manager GL Transactions',
           @process_parent_app = 6000, 
           @process_ctrl_num = '', 
           @error_flag = 0,
           @last_sequence_id = 0,
           @last_document_1 = '', 
           @max_sequence = 0,
           @description_seg2 = '',
           @description_seg3 = '',
           @process_host_id = '',
           @process_kpid = 0,
           @rec_company_code = ''
    SET @trial_flag = 0       
    IF @method_flag < 2
        SET @trial_flag = 1       
    SET @im_config_Overwrite_document_2 = 'YES'
    IF EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'im_config')
        BEGIN
        SELECT @im_config_Overwrite_document_2 = RTRIM(LTRIM(ISNULL(UPPER([Text Value]), '')))
                FROM [im_config] 
                WHERE RTRIM(LTRIM(ISNULL(UPPER([Item Name]), ''))) = 'OVERWRITE DOCUMENT_2'
        IF @@ROWCOUNT = 0
                OR @im_config_Overwrite_document_2 IS NULL
                OR (NOT @im_config_Overwrite_document_2 = 'NO' AND NOT @im_config_Overwrite_document_2 = 'YES' AND NOT @im_config_Overwrite_document_2 = 'TRUE' AND NOT @im_config_Overwrite_document_2 = 'FALSE')
            SET @im_config_Overwrite_document_2 = 'YES'
        IF @im_config_Overwrite_document_2 = 'FALSE'
            SET @im_config_Overwrite_document_2 = 'NO'
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
        UPDATE [imglhdr_vw]
                SET [processed_flag] = 0
                WHERE ([processed_flag] = 2 OR [processed_flag] IS NULL)
                        AND RTRIM(LTRIM(ISNULL([company_code], ''))) = @company_code
                        AND ([User_ID] = @userid OR @userid = 0)
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imglhdr_vw 1A' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
        UPDATE [imgldtl_vw]
                SET [processed_flag] = 0
                WHERE ([processed_flag] = 2 OR [processed_flag] IS NULL)
                        AND RTRIM(LTRIM(ISNULL([company_code], ''))) = @company_code
                        AND ([User_ID] = @userid OR @userid = 0)
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imgldtl_vw 1A' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
        END
    --
    -- Copy the staging tables to their temporary counterparts.
    --
    SELECT *
    INTO [#imglhdr_vw]
            FROM [imglhdr_vw]
            WHERE RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
                    AND (NOT [processed_flag] = 1 OR [processed_flag] IS NULL)
                    AND ([User_ID] = @userid OR @userid = 0)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' #imglhdr_vw 1A' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    SELECT *
    INTO [#imgldtl_vw]
            FROM [imgldtl_vw]
            WHERE RTRIM(LTRIM(ISNULL([company_code], ''))) = @company_code
                    AND (NOT [processed_flag] = 1 OR [processed_flag] IS NULL)
                    AND ([User_ID] = @userid OR @userid = 0)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' #imgldtl_vw 1A' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    UPDATE [#imglhdr_vw]
            SET [processed_flag] = 0    
    UPDATE [#imgldtl_vw]
            SET [processed_flag] = 0    
    CREATE UNIQUE INDEX imglhdr_vw_Index_1 ON #imglhdr_vw
            (company_code,
            document_1) 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATEINDEX + ' imglhdr_vw_Index_1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    CREATE UNIQUE INDEX imgldtl_vw_Index_1 ON #imgldtl_vw
            (company_code,
            document_1,
            sequence_id) 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATEINDEX + ' imgldtl_vw_Index_1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    CREATE NONCLUSTERED INDEX #imgldtl_vw_Index_2 ON #imgldtl_vw
            (document_1,
            sequence_id) 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATEINDEX + ' imgldtl_vw_Index_2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    --
    -- Set the [Import Identifier] column.
    --        
    UPDATE [imglhdr_vw]
            SET [Import Identifier] = @Import_Identifier
            WHERE RTRIM(LTRIM(ISNULL([company_code], ''))) = @company_code
                    AND (NOT [processed_flag] = 1 OR [processed_flag] IS NULL)
                    AND ([User_ID] = @userid OR @userid = 0)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imglhdr_vw 2A' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    UPDATE [imgldtl_vw]
            SET [Import Identifier] = @Import_Identifier
            WHERE RTRIM(LTRIM(ISNULL([company_code], ''))) = @company_code
                    AND (NOT [processed_flag] = 1 OR [processed_flag] IS NULL)
                    AND ([User_ID] = @userid OR @userid = 0)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imgldtl_vw 2A' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    --
    -- Verify that sequence_id values are monotonically increasing.
    --
    SELECT DISTINCT journal_ctrl_num, 
                    document_1, 
                    cnt = COUNT(*), 
                    maxid = MAX(sequence_id), 
                    flg=0
            INTO #temp_imglintsp
            FROM #imgldtl_vw
            WHERE RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
            GROUP BY journal_ctrl_num, document_1
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' #temp_imglintsp 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    UPDATE #imglhdr_vw 
            SET processed_flag = 2
            FROM #imglhdr_vw #imglhdr_vw, #temp_imglintsp b
            WHERE #imglhdr_vw.journal_ctrl_num = b.journal_ctrl_num 
                    AND #imglhdr_vw.document_1 = b.document_1
                    AND b.cnt <> b.maxid
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imglhdr_vw 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    INSERT INTO imglterr_vw 
            SELECT NULL, '', @company_code, document_1, journal_ctrl_num, 0, 9999, 'Detail record sequence_id has a gap after', @userid
            FROM #temp_imglintsp
            WHERE cnt <> maxid
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' imglterr_vw 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    IF @Row_Count > 0
        BEGIN
        DECLARE Monotonic_Cursor INSENSITIVE CURSOR FOR 
                SELECT document_1, sequence_id 
                FROM [#imgldtl_vw] 
                ORDER BY document_1, sequence_id
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DECLARE + ' Monotonic_Cursor 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
        SET @Monotonic_Cursor_Allocated = 'YES'        
        OPEN Monotonic_Cursor
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_OPEN + ' Monotonic_Cursor 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
        SET @Monotonic_Cursor_Opened = 'YES'        
        FETCH NEXT
                FROM Monotonic_Cursor
                INTO @Monotonic_document_1, @Monotonic_sequence_id
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_FETCHNEXT + ' Monotonic_Cursor 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
        SET @Monotonic_Previous_document_1 = @Monotonic_document_1
        SET @Monotonic_Computed_sequence_id = 0
        WHILE NOT @@FETCH_STATUS = -1
            BEGIN
            SET @Monotonic_Computed_sequence_id = @Monotonic_Computed_sequence_id + 1
            IF @Monotonic_document_1 = @Monotonic_Previous_document_1
                BEGIN
                IF NOT @Monotonic_sequence_id = @Monotonic_Computed_sequence_id
                    BEGIN
                    UPDATE imglterr_vw
                            SET [e_ldesc] = RTRIM(LTRIM(ISNULL([e_ldesc], ''))) + ' ' + CAST(@Monotonic_Computed_sequence_id - 1 AS VARCHAR)
                            WHERE document_1 = @Monotonic_document_1
                                    AND ([User_ID] = @userid OR @userid = 0)
                    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imglterr_vw 1A' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
                    END
                END
            ELSE
                BEGIN
                SET @Monotonic_Computed_sequence_id = 1
                SET @Monotonic_Previous_document_1 = @Monotonic_document_1
                END
            FETCH NEXT
                    FROM Monotonic_Cursor
                    INTO @Monotonic_document_1, @Monotonic_sequence_id
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_FETCHNEXT + ' Monotonic_Cursor 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
            END
        CLOSE Monotonic_Cursor
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CLOSE + ' Monotonic_Cursor 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
        SET @Monotonic_Cursor_Opened = 'NO'
        DEALLOCATE Monotonic_Cursor
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DEALLOCATE + ' Monotonic_Cursor 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
        SET @Monotonic_Cursor_Allocated = 'NO'        
        END
    DROP TABLE #temp_imglintsp
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DROPTABLE + ' #temp_imglintsp 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    --
    SELECT @entry_date_error = ISNULL(e_ldesc, 'Invalid entry date')
            FROM glerrdef
            WHERE e_code = 1022
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' glerrdef 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    SELECT @apply_date_error = ISNULL(e_ldesc, 'Invalid apply date')
            FROM glerrdef
            WHERE e_code = 1023
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' glerrdef 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    INSERT INTO imglterr_vw
            SELECT NULL, '', @company_code, document_1, journal_ctrl_num, 0, 1022, @entry_date_error, @userid
            FROM #imglhdr_vw
            WHERE ISDATE(date_entered) = 0 
                    AND NOT DATALENGTH(LTRIM(RTRIM(ISNULL(date_entered, '')))) = 0
                    AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code 
                    AND processed_flag = 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' imglterr_vw 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    INSERT INTO imglterr_vw
            SELECT NULL, '', @company_code, document_1, journal_ctrl_num, 0, 1023, @apply_date_error, @userid
                    FROM #imglhdr_vw
                    WHERE ISDATE(date_applied) = 0 
                            AND NOT DATALENGTH(LTRIM(RTRIM(ISNULL(date_applied, '')))) = 0
                            AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code 
                            AND processed_flag = 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' imglterr_vw 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    UPDATE #imglhdr_vw
            SET #imglhdr_vw.processed_flag = 2
            FROM #imglhdr_vw #imglhdr_vw, imglterr_vw b
            WHERE #imglhdr_vw.journal_ctrl_num = b.journal_ctrl_num
                    AND #imglhdr_vw.document_1 = b.document_1
                    AND b.e_code = 1022
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imglhdr_vw 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    --
    -- Check for duplicate journal control numbers.
    --
    SELECT @External_String = ISNULL([e_ldesc], 'Duplicate') + ' in gltrx'
            FROM [glerrdef]
            WHERE [e_code] = 9931
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' glerrdef 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    INSERT INTO imglterr_vw 
            SELECT NULL, b.process_group_num, a.company_code, a.document_1, a.journal_ctrl_num, 0, 9931, @External_String, @userid
                    FROM #imglhdr_vw a INNER JOIN gltrx_all b
                    ON a.journal_ctrl_num = b.journal_ctrl_num
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' imglterr_vw 4' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imglhdr_vw 
            SET processed_flag = 2
            FROM #imglhdr_vw a, gltrx b
            WHERE a.journal_ctrl_num = b.journal_ctrl_num 
                    AND a.document_1 = b.document_1
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imglhdr_vw 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    CREATE TABLE #rates (from_currency VARCHAR(8), 
                         to_currency VARCHAR(8), 
                         rate_type VARCHAR(8), 
                         date_applied INT, 
                         rate FLOAT)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATETABLE + ' #rates 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    --
    -- Get rounding precision.
    --
    SET @precision_gl = 2
    SELECT @precision_gl = curr_precision
            FROM glco, glcurr_vw
            WHERE glco.home_currency = glcurr_vw.currency_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' glco 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    --
    SELECT @home_currency_code = home_currency,
           @oper_currency_code = oper_currency,
           @oper_rate_type = rate_type_oper,
           @home_rate_type = rate_type_home
            FROM glco
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' glco 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    --
    -- Assign default values.
    --
    IF @debug_level >= 3
        BEGIN
        SELECT '(3): ' + @Routine_Name + ': #imglhdr_vw before assigning default currency information:'
        SELECT *
                FROM #imglhdr_vw
                ORDER BY [document_1]
        SELECT '(3): ' + @Routine_Name + ': #imgldtl_vw before assigning default currency information:'
        SELECT *
                FROM #imgldtl_vw
                ORDER BY [document_1], [sequence_id]
        END
    UPDATE #imgldtl_vw
            SET nat_cur_code = @home_currency_code
            WHERE DATALENGTH(LTRIM(RTRIM(ISNULL(nat_cur_code, '')))) = 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imglhdr_vw 4' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    UPDATE #imgldtl_vw
            SET rate_type_home = @home_rate_type
            WHERE DATALENGTH(LTRIM(RTRIM(ISNULL(rate_type_home, '')))) = 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imgldtl_vw 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    UPDATE #imgldtl_vw
            SET rate_type_oper = @oper_rate_type
            WHERE DATALENGTH(LTRIM(RTRIM(ISNULL(rate_type_oper, '')))) = 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imgldtl_vw 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    UPDATE #imglhdr_vw
            SET home_cur_code = @home_currency_code
            WHERE DATALENGTH(LTRIM(RTRIM(ISNULL(home_cur_code, '')))) = 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imglhdr_vw 5' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    UPDATE #imglhdr_vw
            SET oper_cur_code = @oper_currency_code
            WHERE DATALENGTH(LTRIM(RTRIM(ISNULL(oper_cur_code, '')))) = 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imglhdr_vw 6' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    INSERT INTO #rates
            SELECT DISTINCT b.nat_cur_code, #imglhdr_vw.home_cur_code, b.rate_type_home, DATEDIFF(dd, @January_First_Nineteen_Eighty, CONVERT(DATETIME, #imglhdr_vw.date_applied)) + 722815, 0.0
                    FROM #imglhdr_vw #imglhdr_vw, #imgldtl_vw b
                    WHERE #imglhdr_vw.document_1 = b.document_1
                            AND RTRIM(LTRIM(ISNULL(#imglhdr_vw.company_code, ''))) = RTRIM(LTRIM(ISNULL(b.company_code, '')))
                            AND RTRIM(LTRIM(ISNULL(#imglhdr_vw.company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #rates 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    EXEC [CVO_Control]..mcrates_sp
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' [CVO_Control]..mcrates_sp 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    IF (@debug_level >= 3)  
        BEGIN
        SELECT '(3): ' + @Routine_Name + ': Dump of rate_type_home #rates table'
        SELECT * FROM #rates
        END
    IF (SELECT COUNT([rate]) FROM [#rates] WHERE [rate] = 0) > 0
        BEGIN
        EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = 'imglintsp_sp 3', 
                                                     @IGES_String = @External_String OUT
        DECLARE Zero_Rate_Cursor INSENSITIVE CURSOR FOR 
                SELECT DISTINCT from_currency, to_currency, rate_type 
                FROM [#rates] 
                WHERE [rate] = 0
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DECLARE + ' Zero_Rate_Cursor 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
        SET @Zero_Rate_Cursor_Allocated = 'YES'        
        OPEN Zero_Rate_Cursor
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_OPEN + ' Zero_Rate_Cursor 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
        SET @Zero_Rate_Cursor_Opened = 'YES'        
        FETCH NEXT
                FROM Zero_Rate_Cursor
                INTO @Zero_Rate_from_currency, @Zero_Rate_to_currency, @Zero_Rate_rate_type
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_FETCHNEXT + ' Zero_Rate_Cursor 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
        WHILE NOT @@FETCH_STATUS = -1
            BEGIN
            EXEC im_Make_Displayable_sp @IMD_Input_String = @Zero_Rate_from_currency,
                                        @IMD_Output_String = @Text_String_1 OUTPUT
            EXEC im_Make_Displayable_sp @IMD_Input_String = @Zero_Rate_to_currency,
                                        @IMD_Output_String = @Text_String_2 OUTPUT
            EXEC im_Make_Displayable_sp @IMD_Input_String = @Zero_Rate_rate_type,
                                        @IMD_Output_String = @Text_String_3 OUTPUT
            SET @SQL = 'INSERT INTO [imlog] ([now], [module], [text]) SELECT GETDATE(), ''GLTRX'', N''General Ledger Transactions -- ' + @External_String + '''''' + @Text_String_1 + '''''/''''' + @Text_String_2 + '''''/''''' + @Text_String_3 + ''''''''
            EXEC (@SQL)
            FETCH NEXT
                    FROM Zero_Rate_Cursor
                    INTO @Zero_Rate_from_currency, @Zero_Rate_to_currency, @Zero_Rate_rate_type
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_FETCHNEXT + ' Zero_Rate_Cursor 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
            END
        CLOSE Zero_Rate_Cursor
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CLOSE + ' Zero_Rate_Cursor 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
        SET @Zero_Rate_Cursor_Opened = 'NO'
        DEALLOCATE Zero_Rate_Cursor
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DEALLOCATE + ' Zero_Rate_Cursor 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
        SET @Zero_Rate_Cursor_Allocated = 'NO'
        END
    UPDATE #imgldtl_vw
            SET rate = b.rate
            FROM #imgldtl_vw #imgldtl_vw, #rates b, #imglhdr_vw c
            WHERE #imgldtl_vw.document_1 = c.document_1
                    AND #imgldtl_vw.rate = 0.0
                    AND #imgldtl_vw.nat_cur_code = b.from_currency
                    AND c.home_cur_code = b.to_currency
                    AND #imgldtl_vw.rate_type_home = b.rate_type
                    AND datediff(dd, @January_First_Nineteen_Eighty, CONVERT(datetime, c.date_applied)) + 722815 = b.date_applied
                    AND RTRIM(LTRIM(ISNULL(c.company_code, ''))) = RTRIM(LTRIM(ISNULL(#imgldtl_vw.company_code, '')))
                    AND RTRIM(LTRIM(ISNULL(c.company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imgldtl_vw 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    IF (SELECT COUNT([rate]) FROM #imgldtl_vw WHERE [rate] = 0) > 0
        BEGIN
        EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = 'imglintsp_sp 1', 
                                                     @IGES_String = @External_String OUT 
        INSERT INTO imlog VALUES (getdate(), 'GLTRX', 1, '', '', '', 'General Ledger Transactions -- ' + @External_String, @userid)
        END
    DELETE #rates
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DELETE + ' #rates 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    INSERT INTO #rates
            SELECT DISTINCT b.nat_cur_code, #imglhdr_vw.oper_cur_code, b.rate_type_oper, datediff(dd, @January_First_Nineteen_Eighty, CONVERT(datetime, #imglhdr_vw.date_applied)) + 722815, 0.0
            FROM #imglhdr_vw #imglhdr_vw, #imgldtl_vw b
            WHERE #imglhdr_vw.document_1 = b.document_1
                    AND RTRIM(LTRIM(ISNULL(#imglhdr_vw.company_code, ''))) = RTRIM(LTRIM(ISNULL(b.company_code, '')))
                    AND RTRIM(LTRIM(ISNULL(#imglhdr_vw.company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #rates 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    EXEC [CVO_Control]..mcrates_sp
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' [CVO_Control]..mcrates_sp 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    IF (@debug_level >= 3)  
        BEGIN
        SELECT '(3): ' + @Routine_Name + ': Dump of rate_type_oper #rates table:'
        SELECT * FROM #rates
        END
    IF (SELECT COUNT([rate]) FROM [#rates] WHERE [rate] = 0) > 0
        BEGIN
        EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = 'imglintsp_sp 4', 
                                                     @IGES_String = @External_String OUT 
        DECLARE Zero_Rate_Cursor INSENSITIVE CURSOR FOR 
                SELECT DISTINCT from_currency, to_currency, rate_type 
                FROM [#rates] 
                WHERE [rate] = 0
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DECLARE + ' Zero_Rate_Cursor 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
        SET @Zero_Rate_Cursor_Allocated = 'YES'        
        OPEN Zero_Rate_Cursor
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_OPEN + ' Zero_Rate_Cursor 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
        SET @Zero_Rate_Cursor_Opened = 'YES'        
        FETCH NEXT
                FROM Zero_Rate_Cursor
                INTO @Zero_Rate_from_currency, @Zero_Rate_to_currency, @Zero_Rate_rate_type
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_FETCHNEXT + ' Zero_Rate_Cursor 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
        WHILE NOT @@FETCH_STATUS = -1
            BEGIN
            EXEC im_Make_Displayable_sp @IMD_Input_String = @Zero_Rate_from_currency,
                                        @IMD_Output_String = @Text_String_1 OUTPUT
            EXEC im_Make_Displayable_sp @IMD_Input_String = @Zero_Rate_to_currency,
                                        @IMD_Output_String = @Text_String_2 OUTPUT
            EXEC im_Make_Displayable_sp @IMD_Input_String = @Zero_Rate_rate_type,
                                        @IMD_Output_String = @Text_String_3 OUTPUT
	    SET @SQL = 'INSERT INTO [imlog] ([now], [module], [text]) SELECT GETDATE(), ''GLTRX'', N''General Ledger Transactions -- ' + @External_String + '''''' + @Text_String_1 + '''''/''''' + @Text_String_2 + '''''/''''' + @Text_String_3 + ''''''''
            EXEC (@SQL)
            FETCH NEXT
                    FROM Zero_Rate_Cursor
                    INTO @Zero_Rate_from_currency, @Zero_Rate_to_currency, @Zero_Rate_rate_type
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_FETCHNEXT + ' Zero_Rate_Cursor 4' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
            END
        CLOSE Zero_Rate_Cursor
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CLOSE + ' Zero_Rate_Cursor 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
        SET @Zero_Rate_Cursor_Opened = 'NO'
        DEALLOCATE Zero_Rate_Cursor
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DEALLOCATE + ' Zero_Rate_Cursor 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
        SET @Zero_Rate_Cursor_Allocated = 'NO'
        END
    UPDATE #imgldtl_vw
            SET rate_oper = b.rate
            FROM #imgldtl_vw #imgldtl_vw, #rates b, #imglhdr_vw c
            WHERE #imgldtl_vw.document_1 = c.document_1
                    AND #imgldtl_vw.rate_oper = 0.0
                    AND #imgldtl_vw.nat_cur_code = b.from_currency
                    AND c.oper_cur_code = b.to_currency
                    AND #imgldtl_vw.rate_type_oper = b.rate_type
                    AND datediff(dd, @January_First_Nineteen_Eighty, CONVERT(datetime, c.date_applied))+722815 = b.date_applied
                    AND RTRIM(LTRIM(ISNULL(c.company_code, ''))) = RTRIM(LTRIM(ISNULL(#imgldtl_vw.company_code, '')))
                    AND RTRIM(LTRIM(ISNULL(c.company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imgldtl_vw 4' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    IF (SELECT COUNT(rate_oper) FROM #imgldtl_vw WHERE rate_oper = 0) > 0
        BEGIN
        EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = 'imglintsp_sp 2', 
                                                     @IGES_String = @External_String OUT 
        INSERT INTO imlog VALUES (getdate(), 'GLTRX', 1, '', '', '', 'General Ledger Transactions -- ' + @External_String, @userid)
        END
    UPDATE #imgldtl_vw
            SET balance = ROUND(nat_balance * ( SIGN(1 + SIGN(rate))*(rate) + (SIGN(ABS(SIGN(ROUND(rate,6))))/(rate + SIGN(1 - ABS(SIGN(ROUND(rate,6)))))) * SIGN(SIGN(rate) - 1) ), @precision_gl)
            WHERE balance = 0
                    OR balance IS NULL
                    AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imgldtl_vw 5' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    UPDATE #imgldtl_vw
            SET balance_oper = ROUND(nat_balance * ( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ), @precision_gl)
            WHERE balance_oper = 0
                    OR balance_oper IS NULL
                    AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imgldtl_vw 6' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    IF @debug_level >= 3
        BEGIN
        SELECT '(3): ' + @Routine_Name + ': #imglhdr_vw after assigning default currency information:'
        SELECT *
                FROM #imglhdr_vw
                ORDER BY [document_1]
        SELECT '(3): ' + @Routine_Name + ': #imgldtl_vw after assigning default currency information:'
        SELECT *
                FROM #imgldtl_vw
                ORDER BY [document_1], [sequence_id]
        END
    --
    -- Validate imglhdr.home_cur_code.
    --
    SELECT @External_String = ISNULL([e_ldesc], 'Invalid imglhdr.home_cur_code')
            FROM [glerrdef]
            WHERE [e_code] = 9933
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' glerrdef 5' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    INSERT INTO imglterr_vw
            SELECT NULL, '', @company_code, document_1, journal_ctrl_num, 0, 9933, @External_String, @userid
            FROM #imglhdr_vw
            WHERE NOT home_cur_code IN (SELECT currency_code FROM glcurr_vw) 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' imglterr_vw 5' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    --
    -- Validate imglhdr.oper_cur_code.
    --
    SELECT @External_String = ISNULL([e_ldesc], 'Invalid imglhdr.oper_cur_code')
            FROM [glerrdef]
            WHERE [e_code] = 9932
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' glerrdef 5' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    INSERT INTO imglterr_vw
            SELECT NULL, '', @company_code, document_1, journal_ctrl_num, 0, 9932, @External_String, @userid
            FROM #imglhdr_vw
            WHERE NOT oper_cur_code IN (SELECT currency_code FROM glcurr_vw) 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' imglterr_vw 6' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    --
    -- Verify that any customer-supplied balances are correct.
    --
    SELECT @External_String = ISNULL(e_ldesc, 'out of balance')
            FROM glerrdef
            WHERE e_code = 2008
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' glerrdef 6' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = 'imglintsp_sp 5', 
                                                 @IGES_String = @External_String_1 OUT 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' [CVO_Control]..[im_get_external_string_sp] 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

    INSERT INTO imglterr_vw
            SELECT NULL, '', @company_code, document_1, journal_ctrl_num, sequence_id, 2008, @External_String + @External_String_1, @userid
                    FROM #imgldtl_vw
                    WHERE NOT ROUND(balance, @precision_gl) = 
							(CASE WHEN rate > 0 THEN ROUND(nat_balance * ABS(rate), @precision_gl)
							      WHEN rate < 0 THEN ROUND(nat_balance / ABS(rate), @precision_gl) 
								  ELSE 0.0 END)
						  AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' imglterr_vw 7' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    SELECT @External_String = ISNULL(e_ldesc, 'out of balance oper')
            FROM glerrdef
            WHERE e_code = 2043
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' glerrdef 5' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = 'imglintsp_sp 6', 
                                                 @IGES_String = @External_String_1 OUT 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' [CVO_Control]..[im_get_external_string_sp] 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    INSERT INTO imglterr_vw
            SELECT NULL, '', @company_code, document_1, journal_ctrl_num, sequence_id, 2043, @External_String + @External_String_1, @userid
                    FROM #imgldtl_vw
                    WHERE NOT ROUND(balance_oper, @precision_gl) = 
							(CASE WHEN rate_oper > 0 THEN ROUND(nat_balance * ABS(rate_oper), @precision_gl)
							      WHEN rate_oper < 0 THEN ROUND(nat_balance / ABS(rate_oper), @precision_gl)  
								  ELSE 0.0 END)
                            AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' imglterr_vw 8' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

    SELECT @val_mode = @GLTM_DELAYED
    SELECT @process_host_id = hostprocess,
           @process_kpid = kpid
            FROM [master]..[sysprocesses]
            WHERE  spid = @@spid
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' [master]..[sysprocesses]' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    SELECT @process_parent_company = @company_code,
           @rec_company_code  = @company_code
    EXEC @SP_Result = pctrladd_sp @process_ctrl_num OUTPUT,
                                  @process_description, 
                                  @Process_User_ID,
                                  @process_parent_app, 
                                  @process_parent_company  
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
    -- 
    -- Loop through records in the header staging table.
    --
    SELECT @Total_Header_Records = COUNT(*) FROM #imglhdr_vw
    SET @Current_Header_Record_Number = 0
    WHILE 1 = 1 
        BEGIN
        SELECT TOP 1 @document_1 = document_1
                FROM #imglhdr_vw  
                WHERE document_1 > @last_document_1
                        AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
                        AND processed_flag = 0 
                ORDER BY company_code, document_1         
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' #imglhdr_vw 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        IF @Row_Count = 0 
            BREAK  
        --
        -- For the benefit of watching the import via SQL Profiler.
        -- 
        SET @Current_Header_Record_Number = @Current_Header_Record_Number + 1    
        SET @SQL = 'SELECT ''' + @Routine_Name + ': Header ' + CAST(@Current_Header_Record_Number AS VARCHAR) + ' of ' + CAST(@Total_Header_Records AS VARCHAR) + ''''
        EXEC (@SQL)
        --
        SELECT @sequence_id = 0
        SELECT @journal_ctrl_num = journal_ctrl_num,
               @journal_type = ISNULL(journal_type, ''),
               @journal_description = ISNULL(journal_description, ''),
               @date_entered = datediff(dd, @January_First_Nineteen_Eighty, CONVERT(datetime, date_entered)) + 722815,
               @date_applied = datediff(dd, @January_First_Nineteen_Eighty, CONVERT(datetime, date_applied)) + 722815,
               @recurring_flag = ISNULL(recurring_flag, 0),
               @repeating_flag = ISNULL(repeating_flag, 0), 
               @reversing_flag = ISNULL(reversing_flag, 0),
               @type_flag = ISNULL(type_flag, 0),
               @hold_flag = ISNULL(hold_flag, 0),
               @home_cur_code = ISNULL(home_cur_code, ''),
               @oper_currency_code = ISNULL(oper_cur_code, ''),
               @intercompany_flag = ISNULL(intercompany_flag, 0),
   	       @org_id = ISNULL(org_id, ''),
	       @interbranch_flag = ISNULL(interbranch_flag, 0)
                FROM #imglhdr_vw  
                WHERE RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
                        AND document_1 = @document_1
                        AND processed_flag = 0
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' #imglhdr_vw 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
        -- 
        -- Set transaction type.
        --
        IF @type_flag = 1
            SELECT @trx_type = 101
        ELSE
            SELECT @trx_type = 111
        -- 
        -- If the transaction is intercompany it will be put on hold.
        -- The current standard procedure gltrxval_sp can not validate accounts across 
        -- databases.
        --
        IF @intercompany_flag = 1
            SELECT @trx_type = 112    
        ELSE
            SELECT @trx_type = 111
        IF (@debug_level >= 3)  
            SELECT '(3): ' + @Routine_Name + ': Before gltrxcrh_sp'
        --
        -- If this is a trial run and the staging table journal_ctrl_num is absent,
        -- set @journal_ctrl_num to some non-empty string so that gltrxcrh_sp will not
        -- call gltrxnew_sp and cause the glnumber table to be updated. 
        --
        IF @trial_flag = 1
                AND DATALENGTH(LTRIM(RTRIM(ISNULL(@journal_ctrl_num, '')))) = 0
            BEGIN    
            SET @IMGL_journal_ctrl_num = @IMGL_journal_ctrl_num + 1
            SET @journal_ctrl_num = 'IMGL' + CAST(@IMGL_journal_ctrl_num AS VARCHAR)
            END
        -- 
        -- Create #gltrx header.
        --
        EXEC @result = gltrxcrh_sp @process_ctrl_num,
                                   0,
                                   @module_id,
                                   @val_mode, 
                                   @journal_type,
                                   @journal_ctrl_num OUTPUT, 
                                   @journal_description,
                                   @date_entered,
                                   @date_applied,            
                                   @recurring_flag,
                                   @repeating_flag,
                                   @reversing_flag,
                                   @source_batch_code,
                                   @type_flag, 
                                   @company_code,
                                   @company_code, 
                                   @home_cur_code,
                                   @document_1,
                                   @trx_type,
                                   @Process_User_ID,
                                   @hold_flag,
                                   @oper_currency_code,
                                   @debug_level,
				   @org_id,
				   @interbranch_flag

        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' gltrxcrh_sp' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        IF NOT @result = 0
            BEGIN  
            EXEC glgetmsg_sp @result, 
                             @err_msg OUTPUT
            SELECT @err_msg
            IF @debug_level >= 3
                SELECT '(3): ' + @Routine_Name + ': Exit (ERROR).'
            RETURN @result
            END
        IF (@debug_level >= 3)  
            BEGIN
            SELECT '(3): ' + @Routine_Name + ': After gltrxcrh_sp.'
            SELECT '(3): ' + @Routine_Name + ': #gltrx:'
            SELECT * 
                    FROM #gltrx
            END
        --
        -- Create a record of gltrxdet for this account.
        --
        SELECT @Total_Detail_Records = COUNT(*) FROM #imgldtl_vw WHERE document_1 = @document_1
        SET @Current_Detail_Record_Number = 0
        WHILE 1 = 1 
            BEGIN
            -- 
            -- Get data from detail staging table.
            --
            SELECT @sequence_id = 0
            SELECT TOP 1 @sequence_id = sequence_id
                    FROM #imgldtl_vw  
                    WHERE document_1 = @document_1
                            AND sequence_id > @last_sequence_id
                    ORDER BY document_1, sequence_id        
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' #imgldtl_vw 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
            IF @Row_Count = 0 
                BREAK
            --
            -- For the benefit of watching the import via SQL Profiler.
            -- 
            SET @Current_Detail_Record_Number = @Current_Detail_Record_Number + 1
            SET @SQL = 'SELECT ''' + @Routine_Name + ': Detail ' + CAST(@Current_Detail_Record_Number AS VARCHAR) + ' of ' + CAST(@Total_Detail_Records AS VARCHAR) + ''''
            EXEC (@SQL)
            --
            SELECT @rec_company_code = RTRIM(LTRIM(ISNULL(ISNULL(rec_company_code, ''), ''))),
                   @description = ISNULL(description, ''),
                   @account_code = ISNULL(account_code, ''),
                   @document_2 = ISNULL(document_2, ''),
                   @reference_code = ISNULL(reference_code, ''),
                   @balance  = ISNULL(balance, 0),
                   @nat_balance = ISNULL(nat_balance, 0),
                   @nat_cur_code = ISNULL(nat_cur_code, ''),
                   @rate = ISNULL(rate, 0),
                   @rate_oper = ISNULL(rate_oper, 0),
                   @rate_type_home = ISNULL(rate_type_home, ''),
                   @rate_type_oper = ISNULL(rate_type_oper, ''),
                   @balance_oper = ISNULL(balance_oper, 0),
		   @org_id_det = ISNULL(org_id, '')
                    FROM #imgldtl_vw  
                    WHERE document_1 = @document_1
                            AND sequence_id = @sequence_id
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' #imgldtl_vw 4' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
            --
            -- document_2 must equal journal_ctrl_num in order for 
            -- account profile drill down to work.
            --
            IF @im_config_Overwrite_document_2 = 'YES'
                SELECT @document_2 = @journal_ctrl_num
            IF DATALENGTH(LTRIM(RTRIM(ISNULL(@rec_company_code, '')))) = 0
                SELECT @rec_company_code = @company_code  
            IF (@debug_level >= 3)  
                BEGIN
                SELECT '(3): ' + @Routine_Name + ': Before gltrxcrd_sp'
                END  
   	   IF DATALENGTH(LTRIM(RTRIM(ISNULL(@org_id_det, '')))) = 0
                SELECT @org_id_det = dbo.IBOrgbyAcct_fn(@account_code)
  
            EXEC @result = gltrxcrd_sp @module_id,   
                                       2,                
                                       @journal_ctrl_num,
                                       @sequence_id,          
                                       @rec_company_code,  
                                       @account_code, 
                                       @description,   
                                       @document_1,
                                       @document_2,
                                       @reference_code,
                                       @balance,          
                                       @nat_balance,    
                                       @nat_cur_code,     
                                       @rate,    
                                       @trx_type,
                                       @seq_ref_id,
                                       @balance_oper,
                                       @rate_oper,
                                       @rate_type_home,
                                       @rate_type_oper,
                                       @debug_level,
				       @org_id_det

            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' gltrxcrd_sp' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            IF (@result != 0)  
                BEGIN  
                EXEC glgetmsg_sp @result, 
                                 @err_msg OUTPUT
                SELECT @err_msg
                IF @debug_level >= 3
                    SELECT '(3): ' + @Routine_Name + ': Exit (ERROR).'
                RETURN @result
                END
            IF (@debug_level >= 3)  
                BEGIN
                SELECT '(3): ' + @Routine_Name + ': After gltrxcrd_sp: #gltrxdet (record added):'
                SELECT * 
                        FROM #gltrxdet
                        WHERE [sequence_id] = @sequence_id
                                AND [document_1] = @document_1
                END    
            SELECT @last_sequence_id = @sequence_id
            END
        --
        -- imgltrxvfy_sp will check for the oddball way that the sum of FLOATs may not actually 
        -- equal the sum of the FLOATs.  It will generate a detail record to offset the 
        -- rounding error into the rounding account.
        --
        EXEC @SP_Result = imgltrxvfy_sp @journal_ctrl_num, 
                                        @debug_level,
                                        @userid
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' imgltrxvfy_sp' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        IF NOT @SP_Result = 0
            BEGIN
            EXEC im_log_sp_error_sp @ILSE_Error_Code = @SP_Result,
                                    @ILSE_SP_Name = 'imgltrxvfy_sp',
                                    @ILSE_String = '',
                                    @ILSE_Procedure_Name = @Routine_Name,
                                    @ILSE_Log_Activity = 'YES',
                                    @im_log_sp_error_sp_User_ID = @userid
            GOTO Error_Return
            END
        UPDATE #gltrx
                SET intercompany_flag = @intercompany_flag
                WHERE journal_ctrl_num = @journal_ctrl_num
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #gltrx 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
        SELECT @last_document_1 = @document_1
        SELECT @last_sequence_id = 0
        END
    --
    -- Validate transactions.
    --
    -- Records are inserted into #trxerror for any errors found
    -- by gltrxval_sp.  These records are then copied to imglterr_vw.  Note that early
    -- validation (done by imglintsp_sp) may have already inserted some records
    -- into this table.    
    --
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': Begin validation phase'
    EXEC @result = imgltrxval_sp @company_code,
                                 @company_code,
                                 NULL,
                                 NULL,
                                 @debug_level

    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' gltrxval_sp' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    DELETE FROM [gledtlst]
            WHERE [spid] = @@SPID
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DELETE + ' [gledtlst] 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    CREATE TABLE #gltrxedt1 (
		journal_ctrl_num	varchar(16), 
		sequence_id		int,
		journal_description	varchar(30),
		journal_type 		varchar(8),
		date_entered 		int,
		date_applied		int,
		batch_code		varchar(16),
		hold_flag		smallint,
		home_cur_code		varchar(8),
		intercompany_flag	smallint,
		company_code		varchar(8) NULL,
		source_batch_code	varchar(16),
		type_flag		smallint,
		user_id			smallint,
	        source_company_code     varchar(8),
		account_code		varchar(32),
		account_description	varchar(40),	
		rec_company_code	varchar(8),
		nat_cur_code		varchar(8),
		document_1		varchar(16), 
		description		varchar(40),
		reference_code		varchar(32),
		balance			float,
		nat_balance		float,
		trx_type		smallint,
		offset_flag		smallint,
		seq_ref_id		int,
		temp_flag		smallint,
	        spid                    smallint,
	        oper_cur_code      	varchar(8)      NULL,
	        balance_oper            float           NULL,
		db_name			varchar(128),
		controlling_org_id 	varchar(30) NULL, 
		detail_org_id 		varchar(30) NULL, 
		interbranch_flag int NULL
	          ) 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATETABLE + ' [#gltrxedt1] 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    









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

    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATETABLE + ' #ewerror 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    SELECT @glcomp_vw_db_name = RTRIM(LTRIM(ISNULL([db_name], '')))
            FROM [glcomp_vw]
            WHERE [company_code] = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' [glcomp_vw] 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    INSERT INTO [#gltrxedt1] (journal_ctrl_num,  sequence_id,         journal_description,  
                              journal_type,      date_entered,        date_applied,  
                              batch_code,        hold_flag,           home_cur_code,  
                              intercompany_flag, company_code,        source_batch_code,  
                              type_flag,         user_id,             source_company_code,  
                              account_code,      account_description, rec_company_code,  
                              nat_cur_code,      document_1,          description,  
                              reference_code,    balance,             nat_balance,  
                              trx_type,          offset_flag,         seq_ref_id,  
                              temp_flag,         spid,                oper_cur_code,  
                              balance_oper,      db_name, 	      controlling_org_id,
			      detail_org_id,	 interbranch_flag)  
            SELECT h.journal_ctrl_num,  d.sequence_id,     h.journal_description,
                   h.journal_type,      h.date_entered,    h.date_applied,
                   h.batch_code,        h.hold_flag,       h.home_cur_code,  
                   h.intercompany_flag, h.company_code,    h.source_batch_code,
                   h.type_flag,         h.user_id,         h.source_company_code,
                   d.account_code,      '',                d.rec_company_code,  
                   d.nat_cur_code,      d.document_1,      d.description,  
                   d.reference_code,    d.balance,         d.nat_balance, 
                   d.trx_type,          d.offset_flag,     d.seq_ref_id,  
                   0,                   @@SPID,            h.oper_cur_code,  
                   d.balance_oper,      @glcomp_vw_db_name,h.org_id,
		   d.org_id,		CASE WHEN h.org_id <> d.org_id THEN 1 ELSE 0 END
                    FROM [#gltrx] h
                    INNER JOIN [#gltrxdet] d
                            ON h.[journal_ctrl_num] = d.[journal_ctrl_num]  
                    WHERE (h.[posted_flag] = 0 OR h.[posted_flag] = -1) 
                            AND h.[hold_flag] = 0 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' [#gltrxedt1] 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    INSERT INTO [#gltrxedt1] (journal_ctrl_num,  sequence_id,         journal_description,  
                              journal_type,      date_entered,        date_applied,  
                              batch_code,        hold_flag,           home_cur_code,  
                              intercompany_flag, company_code,        source_batch_code,  
                              type_flag,         user_id,             source_company_code,  
                              account_code,      account_description, rec_company_code,  
                              nat_cur_code,      document_1,          description,  
                              reference_code,    balance,             nat_balance,  
                              trx_type,          offset_flag,         seq_ref_id,  
                              temp_flag,         spid,                oper_cur_code,  
                              balance_oper,      db_name,  	      controlling_org_id,
			      detail_org_id,	 interbranch_flag)  
            SELECT journal_ctrl_num,  -1,           journal_description,  
                   journal_type,      date_entered, date_applied, 
                   batch_code,        hold_flag,    home_cur_code,  
                   intercompany_flag, company_code, source_batch_code,  
                   type_flag,         user_id,      source_company_code,  
                   '',                '',           '',  
                   '',                '',           '',  
                   '',                0.0,          0.0,  
                   trx_type,          0,            0,  
                   0,                 @@SPID,       oper_cur_code,  
                   0.0,               '' , 	   org_id,
		   org_id,	      0
                    FROM [#gltrx]
                    WHERE ([posted_flag] = 0 OR [posted_flag] = -1)
                            AND [hold_flag] = 0 


    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' [#gltrxedt1] 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    EXEC @SP_Result = [gledtval_sp] @process_mode = 1,
                                    @debug_level = @debug_level
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' [gledtval_sp] 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    IF NOT @SP_Result = 0
        BEGIN
        EXEC im_log_sp_error_sp @ILSE_Error_Code = @SP_Result,
                                @ILSE_SP_Name = 'gledtval_sp',
                                @ILSE_String = '',
                                @ILSE_Procedure_Name = @Routine_Name,
                                @ILSE_Log_Activity = 'YES',
                                @im_log_sp_error_sp_User_ID = @userid
        GOTO Error_Return
        END
    --
    -- Perform inter-company validations.
    --
    DECLARE [Database_Names] CURSOR FOR
            SELECT DISTINCT d.[rec_company_code],
                            e.[db_name]
                    FROM [#imglhdr_vw] h
                    INNER JOIN [#imgldtl_vw] d
                            ON h.[document_1] = d.[document_1]
                    INNER JOIN [CVO_Control]..[ewcomp] e
                            ON d.[rec_company_code] = e.[company_code]
                    WHERE h.[intercompany_flag] = 1
                            AND NOT d.[rec_company_code] = @company_code 
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
        SET @SQL = 'USE ' + @Database_Names_db_name
                 + ' EXEC glvedb_sp @db_name = ''' + @Database_Names_db_name + ''','
                 +                ' @header_db = ''' + @glcomp_vw_db_name + ''','
                 +                ' @process_mode = 1,'
                 +                ' @flag = 0,'
                 +                ' @debug_level = ' + CAST(@debug_level AS VARCHAR)
        EXEC (@SQL)         
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
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' [glvedb_sp] 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --        
    INSERT INTO [#trxerror] (journal_ctrl_num, sequence_id, error_code) 
            SELECT DISTINCT h.journal_ctrl_num, 0, e.[err_code]
                    FROM [#ewerror] e
                    INNER JOIN [#gltrx] h
                            ON e.[trx_ctrl_num] = h.[journal_ctrl_num]
                    WHERE e.[sequence_id] = 0        
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #trxerror 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    INSERT INTO [#trxerror] (journal_ctrl_num, sequence_id, error_code) 
            SELECT DISTINCT d.journal_ctrl_num, e.[sequence_id], e.[err_code]
                    FROM [#ewerror] e
                    INNER JOIN [#gltrxdet] d
                            ON e.[trx_ctrl_num] = d.[journal_ctrl_num]
                    WHERE NOT e.[sequence_id] = 0        
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #trxerror 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    DROP TABLE [#ewerror]
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DROPTABLE + ' [#ewerror] 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': End validation phase: ' + RTRIM(LTRIM(CONVERT(CHAR(5),@result)))
    --
    -- Delete all of the errors with e_code 1011 ("The account code does not match any 
    -- Intercompany offset account code mask").  For an intercompany transaction this error 
    -- can occur even if the account is valid.
    --
    DELETE FROM #trxerror
            WHERE error_code = 1011 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DELETE + ' #trxerror 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    --
    -- Additional validation for intercompany
    --
    SELECT @max_value = MAX(intercompany_flag)
            FROM #gltrx 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' #gltrx 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    IF (@debug_level >= 3)
        BEGIN
        SELECT '(3): ' + @Routine_Name + ': @max_value = ' + CAST(ISNULL(@max_value, 0) AS VARCHAR)      
        END    
    IF @max_value = 1
        BEGIN
        EXEC imglchk_sp @debug_level,
                        @userid
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' imglchk_sp' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        END
    INSERT INTO #trxerror (journal_ctrl_num, sequence_id, error_code) 
            SELECT g.journal_ctrl_num, d.[sequence_id], 9934
                    FROM [#imglhdr_vw] h
                    INNER JOIN [#imgldtl_vw] d
                            ON h.[document_1] = d.[document_1]
                    LEFT OUTER JOIN [CVO_Control]..ewcoco e
                            ON d.[company_code] = e.[org_code]
                                    AND d.[rec_company_code] = e.[rec_code]
                    INNER JOIN [#gltrx] g
                            ON h.[document_1] = g.[document_1]                
                    WHERE h.[intercompany_flag] = 1
                            AND NOT d.[company_code] = d.[rec_company_code]
                            AND e.[org_code] IS NULL
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #trxerror 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Verify that all headers have details.
    --
    INSERT INTO #trxerror (journal_ctrl_num, sequence_id, error_code ) 
            SELECT a.journal_ctrl_num, 0, 9930
            FROM #gltrx a LEFT OUTER JOIN #gltrxdet b ON (a.journal_ctrl_num = b.journal_ctrl_num)
            GROUP BY a.journal_ctrl_num
            HAVING COUNT(b.journal_ctrl_num) = 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #trxerror 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    IF (@debug_level >= 3)  
        BEGIN
        SELECT '(3): ' + @Routine_Name + ': #trxerror, #gltrx, and #gltrxdet:'
        SELECT * FROM #trxerror
        SELECT * FROM #gltrx
        SELECT * FROM #gltrxdet
        END 
    UPDATE #gltrx
            SET trx_state = 3
            FROM #gltrx t, #trxerror e
            WHERE t.journal_ctrl_num = e.journal_ctrl_num
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #gltrx 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    --
    -- Add messages to imglterr_vw for errors found by the standard product routines.
    --
    INSERT imglterr_vw (process_ctrl_num, company_code, document_1, journal_ctrl_num, sequence_id, e_code, e_ldesc, [User_ID])
            SELECT a.process_group_num, RTRIM(LTRIM(ISNULL(a.company_code, ''))), a.document_1, a.journal_ctrl_num, b.sequence_id, b.error_code, c.e_ldesc, @userid 
            FROM #gltrx a , #trxerror b, glerrdef c
            WHERE a.journal_ctrl_num = b.journal_ctrl_num
                    AND b.error_code = c.e_code  
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imglterr_vw 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    --
    -- All validation has been completed.  All records are now in imglterr_vw.  
    -- Sync up processed_flag in the header and detail, and then copy processed_flag 
    -- back to the permanent staging tables.  Note that this code only applies to a 
    -- trial import because the updates done in gltrxusv_sp will override these. 
    --
    UPDATE [#imglhdr_vw]
            SET [#imglhdr_vw].[processed_flag] = 2
            FROM [#imglhdr_vw] h
            INNER JOIN [imglterr_vw] e
                    ON h.document_1 = e.document_1
                            AND h.company_code = e.company_code
            WHERE (e.sequence_id < 1 OR e.sequence_id IS NULL) 
                    AND (e.[User_ID] = @userid OR @userid = 0)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imglhdr_vw 8A' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE [#imgldtl_vw]
            SET [#imgldtl_vw].[processed_flag] = 2
            FROM [#imgldtl_vw] d
            INNER JOIN [imglterr_vw] e
                    ON d.document_1 = e.document_1
                            AND d.sequence_id = e.sequence_id
                            AND d.company_code = e.company_code
            WHERE e.sequence_id > 0                
                    AND (e.[User_ID] = @userid OR @userid = 0)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imgldtl_vw 7A' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imglhdr_vw
            SET processed_flag = b.processed_flag
            FROM #imglhdr_vw a, #imgldtl_vw b
            WHERE b.processed_flag = 2
                    AND (NOT a.processed_flag = 1 OR a.processed_flag IS NULL)
                    AND a.document_1 = b.document_1
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imglhdr_vw 9A' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE imglhdr_vw
            SET processed_flag = h2.processed_flag
            FROM imglhdr_vw h1 
            INNER JOIN #imglhdr_vw h2
                    ON h1.company_code = h2.company_code
                            AND h1.document_1 = h2.document_1
            WHERE (NOT h1.processed_flag = 1 OR h1.processed_flag IS NULL) 
                    AND (h2.processed_flag = 1 OR h2.processed_flag = 2)
                    AND (h1.[User_ID] = @userid OR @userid = 0)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imglhdr_vw 3A' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE imgldtl_vw
            SET processed_flag = d2.processed_flag
            FROM imgldtl_vw d1 
            INNER JOIN #imgldtl_vw d2
                    ON d1.company_code = d2.company_code
                            AND d1.document_1 = d2.document_1
                            AND d1.sequence_id = d2.sequence_id
            WHERE (NOT d1.processed_flag = 1 OR d1.processed_flag IS NULL) 
                    AND (d2.processed_flag = 1 OR d2.processed_flag = 2)
                    AND (d1.[User_ID] = @userid OR @userid = 0)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imgldtl_vw 3A' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --    
    -- Exclude the records with errors from further processing.   
    --    
    UPDATE [#gltrx]
            SET [trx_state] = 3
            FROM [#gltrx] 
            INNER JOIN [imglterr_vw]
                    ON [#gltrx].[document_1] = [imglterr_vw].[document_1]
            WHERE RTRIM(LTRIM(ISNULL([imglterr_vw].[company_code], ''))) = RTRIM(LTRIM(ISNULL(@company_code, '')))        
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #gltrx 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    DELETE [#gltrxdet]
            FROM [#gltrxdet]
            INNER JOIN [#gltrx]
                    ON [#gltrx].[document_1] = [#gltrxdet].[document_1]
            WHERE [#gltrx].[trx_state] = 3
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DELETE + ' #gltrxdet 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    DELETE
            FROM [#gltrx]
            WHERE [trx_state] = 3
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DELETE + ' #gltrx 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    --
    SELECT @Row_Count = COUNT(*) FROM #gltrx
    IF @Row_Count = 0
        BEGIN
        IF @debug_level >= 3
            SELECT '(3): ' + @Routine_Name + ': There are no records remaining for processing.'
        END   
    ELSE
        BEGIN    
        IF NOT @trial_flag = 1
            BEGIN
            --
            -- If running in "batch" mode then create a batchctl record 
            -- with our description and process_ctrl_num.  This is done so that
            -- gltrxbat_sp (called by gltrxsav_sp) will have an existing record
            -- in the batchctl table from which it can obtain the batch_description
            -- text and process_ctrl_num value.  This is the only reason for its
            -- creation.  After gltrxsav_sp is called, the batchctl record created
            -- here will be deleted. 
            --
            IF EXISTS (SELECT * FROM glco WHERE batch_proc_flag = 1)
                BEGIN
                --
                -- Generate a new batch_ctrl_num
                --
                SELECT @tran_started = 0
                IF @@trancount = 0
                    BEGIN
                    BEGIN TRAN
                    SELECT @tran_started = 1
                    END
                SELECT @mask = batch_ctrl_num_mask, 
                       @next_number = next_batch_ctrl_num
                        FROM glnumber 
                        (HOLDLOCK)
                SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' glnumber 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
                --
                -- Loop until the batch number that we create is not in batchctl.
                -- We don't want to attempt to put an existing batch number into
                -- the table since the user might have entered a batch number manually.
                --
                WHILE 1 = 1
                    BEGIN
                    --       
                    -- Update the glnumber table to reflect reality
                    --
                    UPDATE glnumber 
                            SET next_batch_ctrl_num = @next_number + 1
                    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' glnumber 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
                    -- 
                    -- Create the batch number 
                    --
                    EXEC fmtctlnm_sp @next_number, 
                                     @mask, 
                                     @new_bcn OUTPUT, 
                                     @ret_status OUTPUT
                    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' fmtctlnm_sp' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
                    IF (@ret_status != 0)
                        BEGIN
                        IF (@tran_started = 1)
                            ROLLBACK TRAN
                        SET @tran_started = 0    
                        EXEC im_log_sp_error_sp @ILSE_Error_Code = @SP_Result,
                                                @ILSE_SP_Name = 'fmtctlnm_sp',
                                                @ILSE_String = '',
                                                @ILSE_Procedure_Name = @Routine_Name,
                                                @ILSE_Log_Activity = 'YES',
                                                @im_log_sp_error_sp_User_ID = @userid
                        GOTO Error_Return
                        END
                    IF NOT EXISTS(SELECT 1 FROM batchctl WHERE batch_ctrl_num = @new_bcn )
                        BREAK
                    SELECT @next_number = next_batch_ctrl_num
                            FROM glnumber
                    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' glnumber 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
                    END
                IF (@tran_started = 1)
                    COMMIT TRAN
                EXEC appdate_sp @cur_date OUTPUT
                SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' appdate_sp' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
                SET @batch_type = 6010
                SET @cur_time = datepart(hour, getdate()) * 3600 + datepart(minute, getdate()) * 60 + datepart(second, getdate())
                --  
                -- To change the batch description, modify the text for the 
                -- batch_description column.
                --
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
                        VALUES (NULL,             @new_bcn,  'IM Batch',
                                @cur_date,        @cur_time, 0,
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
                UPDATE #gltrx 
                        SET source_batch_code = @new_bcn
                SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #gltrx 4' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
                END
            IF (@debug_level >= 3)  
                BEGIN
                SELECT '(3): ' + @Routine_Name + ': After inserting records into batchctl and updating #gltrx'
                SELECT '(3): ' + @Routine_Name + ':     #gltrx:'
                SELECT * 
                        FROM #gltrx
                SELECT '(3): ' + @Routine_Name + ':     #gltrxdet:'
                SELECT * 
                        FROM #gltrxdet
                END
            IF @debug_level >= 3
                SELECT '(3): ' + @Routine_Name + ': Before gltrxsav_sp'
            EXEC @result = gltrxsav_sp @process_ctrl_num = @process_ctrl_num,
                                       @org_company = @company_code,
                                       @debug = @debug_level ,
                                       @interface_flag = 1, 
                                       @userid = @userid
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' gltrxsav_sp' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            IF @debug_level >= 3
                SELECT '(3): ' + @Routine_Name + ': After gltrxsav_sp.  ' + RTRIM(LTRIM(CONVERT(CHAR(5),@result)))
            --
            -- After everything is done, get rid of the batchctl row we created earlier.
            --
            IF EXISTS (SELECT * FROM glco WHERE batch_proc_flag = 1)
                BEGIN
                DELETE batchctl 
                        WHERE batch_ctrl_num = @new_bcn
                SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DELETE + ' batchctl 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
                END
            --
            --  Determine today's date
            --
            EXEC appdate_sp @date_today OUTPUT
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' appdate_sp' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            IF (@init_mode & 0x1) > 0
                BEGIN
                --
                -- Mark the batch as complete.
                --
                EXEC @SP_Result = imbatch_sp @company_code, 
                                             0,
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
            IF (@init_mode & 0x2) > 0
                BEGIN
                --    
                -- Post transactions.
                --
                IF @debug_level >= 3
                    SELECT '(3): ' + @Routine_Name + ': Posting transactions for final import.'
                --
                --  Ensure posting of only one process control number.
                --
                DELETE #pcontrol
                SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DELETE + ' #pcontrol 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
                --
                -- Insert the process control number to post.
                --
                INSERT #pcontrol (process_ctrl_num,    process_parent_app, process_parent_company,  
                                  process_description, process_user_id,    process_server_id,  
                                  process_host_id,     process_kpid,       process_start_date, 
                                  process_end_date,    process_state)
                        VALUES (@process_ctrl_num,    @process_parent_app, @process_parent_company,
                                @process_description, @Process_User_ID,    @@spid, 
                                @process_host_id,     @process_kpid,       getdate(), 
                                NULL,                 1)
                SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #pcontrol 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
                IF @debug_level >= 3
                    BEGIN 
                    SELECT '(3): ' + @Routine_Name + ': Before glappstd_sp.'
                    END
                EXEC @result = glappstd_sp @module_id, 
                                           @date_today, 
                                           @@spid, 
                                           @Process_User_ID, 
                                           1,
                                           @error_flag OUTPUT, 
                                           @debug_level
                SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' glappstd_sp' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
                IF @debug_level >= 3
                    BEGIN
                    SELECT '(3): ' + @Routine_Name + ': After glappstd_sp'
                    SELECT '(3): ' + @Routine_Name + ':     Posting result: ' + CAST(@result AS VARCHAR)
                    SELECT '(3): ' + @Routine_Name + ':     Error flag: ' + CAST(@error_flag AS VARCHAR)
                    END
                IF (@result != 0)
                    BEGIN  
                    EXEC pctrlupd_sp @process_ctrl_num, 
                                     2
                    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' pctrlupd_sp 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
                    IF @debug_level >= 3
                        SELECT '(3): ' + @Routine_Name + ': Exit (ERROR).'
                    RETURN @result
                    END
                END    
            ELSE
                BEGIN
                UPDATE [batchctl] 
                        SET [posted_flag] = 0 
                        WHERE [process_group_num] = @process_ctrl_num                
                SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' batchctl 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
                END    
            END
        EXEC pctrlupd_sp @process_ctrl_num, 
                         3
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' pctrlupd_sp 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        END
    --
    -- Copy records to the im# tables.
    --
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': Copy records to the im# tables'
    INSERT INTO [CVO_Control]..im#imglhdr
            ([Import Identifier], [Import Company],    [Import Date],
             journal_type,        journal_ctrl_num,    journal_description,
             date_entered,        date_applied,        recurring_flag,
             repeating_flag,      reversing_flag,      type_flag,
             intercompany_flag,   company_code,        home_cur_code,
             oper_cur_code,       document_1,          processed_flag,
             date_processed,      [batch_no],          [record_id_num],
             [User_ID],		  [org_id],	       [interbranch_flag])
            SELECT @Import_Identifier, @company_code,       GETDATE(),
                   journal_type,       journal_ctrl_num,    journal_description,
                   date_entered,       date_applied,        recurring_flag,
                   repeating_flag,     reversing_flag,      type_flag,
                   intercompany_flag,  company_code,        home_cur_code,
                   oper_cur_code,      document_1,          processed_flag,
                   date_processed,     [batch_no],          [record_id_num],
                   [User_ID],          [org_id],	       [interbranch_flag]
                    FROM #imglhdr_vw
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' [CVO_Control]..im#imglhdr 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    INSERT INTO [CVO_Control]..im#imgldtl
            ([Import Identifier], [Import Company], [Import Date],
             company_code,        journal_ctrl_num, sequence_id,
             rec_company_code,    account_code,     description,
             document_1,          document_2,       reference_code,
             balance,             balance_oper,     nat_balance,
             nat_cur_code,        rate,             rate_oper,
             rate_type_home,      rate_type_oper,   processed_flag,
             [batch_no],          [record_id_num],  [User_ID],
	     [org_id])  
            SELECT @Import_Identifier, @company_code,    GETDATE(),                             
                   company_code,       journal_ctrl_num, sequence_id,
                   rec_company_code,   account_code,     description,
                   document_1,         document_2,       reference_code,
                   balance,            balance_oper,     nat_balance,
                   nat_cur_code,       rate,             rate_oper,
                   rate_type_home,     rate_type_oper,   processed_flag,
                   [batch_no],         [record_id_num],  [User_ID],
		   [org_id]  
                    FROM #imgldtl_vw
    --                
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' [CVO_Control]..im#imgldtl 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    DROP TABLE #rates
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DROPTABLE + ' #rates 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    DROP TABLE #gltrx
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DROPTABLE + ' #gltrx 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    DROP TABLE #gltrxdet
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DROPTABLE + ' #gltrxdet 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    DROP TABLE #trxerror 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DROPTABLE + ' #trxerror 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    DROP TABLE #batches 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DROPTABLE + ' #batches 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    DROP TABLE #offsets 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DROPTABLE + ' #offsets 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    DROP TABLE #pcontrol 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DROPTABLE + ' #pcontrol 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    DROP TABLE #offset_accts 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DROPTABLE + ' #offset_accts 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    SET @imglintsp_sp_process_ctrl_num = @process_ctrl_num
    INSERT INTO imlog VALUES (getdate(), 'GLTRX', 1, '', '', '', 'General Ledger Transactions -- Import Identifier = ' + CAST(@Import_Identifier AS VARCHAR), @userid)
    INSERT INTO imlog VALUES (getdate(), 'GLTRX', 1, '', '', '', 'General Ledger Transactions -- process_ctrl_num = ' + ISNULL(@process_ctrl_num, 'NULL'), @userid)
    INSERT INTO imlog VALUES (getdate(), 'GLTRX', 1, '', '', '', 'General Ledger Transactions -- End', @userid)
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': Exit.'
    RETURN 0
Error_Return:
    IF @Monotonic_Cursor_Opened = 'YES'
        CLOSE Monotonic_Cursor
    IF @Monotonic_Cursor_Allocated = 'YES'
        DEALLOCATE Monotonic_Cursor
    IF @Zero_Rate_Cursor_Opened = 'YES'
        CLOSE Zero_Rate_Cursor
    IF @Zero_Rate_Cursor_Allocated = 'YES'
        DEALLOCATE Zero_Rate_Cursor
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': Exit (ERROR).'
    RETURN -1    
GO
GRANT EXECUTE ON  [dbo].[imglintsp_sp] TO [public]
GO
