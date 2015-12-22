SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

    
    CREATE procedure 
[dbo].[imglintsp_Validate_sp] @imglintsp_Validate_sp_Batch_Number INT = 0,
                      @imglintsp_Validate_sp_Starting_Record_Number INT = 0,
                      @imglintsp_Validate_sp_Ending_Record_Number INT = 0,
                      @imglintsp_Validate_sp_Dummy_1 INT = 0,
                      @debug_level INT = 0,
                      @imglintsp_Validate_sp_Dummy_2 INT = 0,
                      @imglintsp_Validate_sp_Import_Identifier INT = 0,
                      @userid INT = 0,
                      @imglintsp_Validate_sp_Application_Name VARCHAR(30) = 'Import Manager',
                      @imglintsp_Validate_sp_Override_User_Name VARCHAR(30) = ''
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
    

    DECLARE @company_code VARCHAR(8)
    DECLARE @Dummy VARCHAR(16)
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
    

    SET @Routine_Name = 'imglintsp_Validate_sp'        
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
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': Before imglintsp_sp.'
    IF @imglintsp_Validate_sp_Import_Identifier = 0    
            OR @imglintsp_Validate_sp_Import_Identifier IS NULL
        BEGIN        
        EXEC @SP_Result = imglintsp_sp @company_code = @company_code,
                                       @init_mode = 0,
                                       @method_flag = 0,
                                       @debug_level = @debug_level,
                                       @userid = @userid,
                                       @imglintsp_sp_process_ctrl_num = @process_ctrl_num OUTPUT,
                                       @imglintsp_sp_dummy = @Dummy OUTPUT,
                                       @imglintsp_sp_Import_Identifier = @imglintsp_Validate_sp_Import_Identifier OUTPUT,
                                       @imglintsp_sp_Override_User_Name = @imglintsp_Validate_sp_Override_User_Name
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' imglintsp_sp 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        END
    ELSE    
        BEGIN        
        EXEC @SP_Result = imglintsp_sp @company_code = @company_code,
                                       @init_mode = 0,
                                       @method_flag = 0,
                                       @debug_level = @debug_level,
                                       @userid = @userid,
                                       @imglintsp_sp_process_ctrl_num = @process_ctrl_num OUTPUT,
                                       @imglintsp_sp_dummy = @Dummy OUTPUT,
                                       @imglintsp_sp_Import_Identifier = @imglintsp_Validate_sp_Import_Identifier,
                                       @imglintsp_sp_Override_User_Name = @imglintsp_Validate_sp_Override_User_Name
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' imglintsp_sp 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        END
    IF NOT @SP_Result = 0
        BEGIN
        EXEC im_log_sp_error_sp @ILSE_Error_Code = @SP_Result,
                                @ILSE_SP_Name = 'imglintsp_sp',
                                @ILSE_String = '',
                                @ILSE_Procedure_Name = @Routine_Name,
                                @ILSE_Log_Activity = 'YES',
                                @im_log_sp_error_sp_User_ID = @userid
        GOTO Error_Return
        END    
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': After imglintsp_sp.'
    SET @Import_Identifier = @imglintsp_Validate_sp_Import_Identifier
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
                    'Trial (Validation)',
                    @userid)
    --
    
    --
    -- Import_Epilog_1
    --
    -- Update the im_processes table.
    --
    IF EXISTS (SELECT 1 FROM [CVO_Control]..[im_processes] WHERE [SPID] = @@SPID)
        BEGIN
        UPDATE [CVO_Control]..[im_processes]
                SET [process_ctrl_num_Validation] = @process_ctrl_num,
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
                       @process_ctrl_num,
                       NULL,
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
GRANT EXECUTE ON  [dbo].[imglintsp_Validate_sp] TO [public]
GO
