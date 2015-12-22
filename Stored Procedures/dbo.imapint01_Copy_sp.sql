SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

    
    CREATE procedure 
[dbo].[imapint01_Copy_sp] @imapint01_Copy_sp_Batch_Number INT = 0,
                  @imapint01_Copy_sp_Starting_Record_Number INT = 0,
                  @imapint01_Copy_sp_Ending_Record_Number INT = 0,
                  @imapint01_Copy_sp_Flag_Bits INT = 0,
                  @debug_level INT = 0,
                  @imapint01_Copy_sp_Record_Type INT = 4091,
                  @imapint01_Copy_sp_Import_Identifier INT = 0,
                  @imapint01_Copy_sp_db_userid VARCHAR(40) = 'ABSENT',
                  @imapint01_Copy_sp_db_password VARCHAR(40) = '',
                  @userid INT = 0,
                  @imapint01_Copy_sp_Application_Name VARCHAR(30) = 'Import Manager',
                  @imapint01_Copy_sp_Override_User_Name VARCHAR(30) = '',
                  @imapint01_Copy_sp_TPS_int_value INT = NULL
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
    

    DECLARE @close_batch_flag SMALLINT
    DECLARE @company_code VARCHAR(8)
    DECLARE @Dummy VARCHAR(16)
    DECLARE @post_flag INT
    DECLARE @process_ctrl_num VARCHAR(16)
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
    

    SET @Routine_Name = 'imapint01_Copy_sp'        
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': Entry.'
    --
    -- Obtain company_code
    --
    SELECT @company_code = LTRIM(RTRIM(ISNULL([company_code], '')))
        FROM [glco]
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @company_code 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
    --
    -- Call the regular SP, passing values for:
    --     @debug
    --     @company_code
    --     Trial/Final flag (hard-coded as appropriate)
    --     Record type (hard-coded as appropriate)
    --     User ID
    --     Any other unused values (hard-coded as blank or 0) 
    --
    SET @close_batch_flag = 0
    IF (@imapint01_Copy_sp_Flag_Bits & 0x1) > 0
        SET @close_batch_flag = 1
    SET @post_flag = 0
    IF (@imapint01_Copy_sp_Flag_Bits & 0x2) > 0
        SET @post_flag = 1
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': Before imapint01_sp.'
    IF @imapint01_Copy_sp_Import_Identifier = 0    
            OR @imapint01_Copy_sp_Import_Identifier IS NULL
        BEGIN    
        EXEC @SP_Result = imapint01_sp @method_flag = 2,
                                       @post_flag = @post_flag,
                                       @invoice_flag = @imapint01_Copy_sp_Record_Type,
                                       @close_batch_flag = @close_batch_flag,
                                       @db_userid = @imapint01_Copy_sp_db_userid,
                                       @db_password = @imapint01_Copy_sp_db_password,
                                       @debug_level = @debug_level,
                                       @perf_level = 0,
                                       @userid = @userid,
                                       @imapint01_sp_process_ctrl_num_Validation = @Dummy OUTPUT,
                                       @imapint01_sp_process_ctrl_num_Posting = @process_ctrl_num OUTPUT,
                                       @imapint01_sp_Import_Identifier = @imapint01_Copy_sp_Import_Identifier OUTPUT,
                                       @imapint01_sp_Override_User_Name = @imapint01_Copy_sp_Override_User_Name,
                                       @imapint01_sp_TPS_int_value = @imapint01_Copy_sp_TPS_int_value
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' imapint01_sp 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        END
    ELSE    
        BEGIN    
        EXEC @SP_Result = imapint01_sp @method_flag = 2,
                                       @post_flag = @post_flag,
                                       @invoice_flag = @imapint01_Copy_sp_Record_Type,
                                       @close_batch_flag = @close_batch_flag,
                                       @db_userid = '',
                                       @db_password = '',
                                       @debug_level = @debug_level,
                                       @perf_level = 0,
                                       @userid = @userid,
                                       @imapint01_sp_process_ctrl_num_Validation = @Dummy OUTPUT,
                                       @imapint01_sp_process_ctrl_num_Posting = @process_ctrl_num OUTPUT,
                                       @imapint01_sp_Import_Identifier = @imapint01_Copy_sp_Import_Identifier,
                                       @imapint01_sp_Override_User_Name = @imapint01_Copy_sp_Override_User_Name,
                                       @imapint01_sp_TPS_int_value = @imapint01_Copy_sp_TPS_int_value
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' imapint01_sp 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        END
    IF NOT @SP_Result = 0
        BEGIN
        EXEC im_log_sp_error_sp @ILSE_Error_Code = @SP_Result,
                                @ILSE_SP_Name = 'imapint01_sp',
                                @ILSE_String = '',
                                @ILSE_Procedure_Name = @Routine_Name,
                                @ILSE_Log_Activity = 'YES',
                                @im_log_sp_error_sp_User_ID = @userid
        GOTO Error_Return
        END    
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': After imapint01_sp.'
    SET @Import_Identifier = @imapint01_Copy_sp_Import_Identifier
    --
    -- Insert a "Trial"/"Final" line for the report. 
    --
    INSERT INTO [CVO_Control]..[im_reportlines] ([Import Identifier],
                                              [Import Company],
                                              [Import Date],
                                              [Order],
                                              [Text],
                                              [User_ID])
            VALUES (@Import_Identifier,
                    @company_code,
                    GETDATE(),
                    1,
                    'Final (Copy)',
                    @userid)
    --
    
    --
    -- Import_Epilog_2
    --
    -- Update the im_processes table.
    --
    IF EXISTS (SELECT 1 FROM [CVO_Control]..[im_processes] WHERE [SPID] = @@SPID)
        BEGIN
        UPDATE [CVO_Control]..[im_processes]
                SET [process_ctrl_num_Posting] = @process_ctrl_num,
                    [Import Identifier] = @Import_Identifier
                WHERE [SPID] = @@SPID
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' [CVO_Control]..[im_processes] 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        END
    ELSE
        BEGIN    
        INSERT INTO [CVO_Control]..[im_processes] ([SPID],
                                                [process_ctrl_num_Validation], 
                                                [process_ctrl_num_Posting], 
                                                [Import Identifier]) 
                SELECT @@SPID,
                       NULL,
                       @process_ctrl_num,
                       @Import_Identifier
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' [CVO_Control]..[im_processes] 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        END
    --    

    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': Exit.'
    RETURN 0
Error_Return:
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': Exit (ERROR).'
    RETURN -1    
GO
GRANT EXECUTE ON  [dbo].[imapint01_Copy_sp] TO [public]
GO
