SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

     
    CREATE PROC 
[dbo].[imarint01b_sp] @process_ctrl_num char(16), 
              @company_code VARCHAR(8), 
              @invoice_flag smallint,
              @method_flag SMALLINT, 
              @debug_level TINYINT = 0,
              @userid INT = 0
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
    

    SET @Routine_Name = 'imarint01b_sp'
    SET @Error_Table_Name = 'imicmerr_vw'         
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': Entry.'
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
    -- Copy processed_flag and other items from the temporary staging tables 
    -- to the permanent staging tables.
    --        
    IF @method_flag = 2
        BEGIN              
        UPDATE [CVO_Control]..imarhdr
                SET [process_ctrl_num] = @process_ctrl_num,
                    [processed_flag] = b.[processed_flag],
                    [date_processed] = b.[date_processed],
                    [trx_ctrl_num] = b.[trx_ctrl_num]
                FROM [CVO_Control]..[imarhdr] a 
                INNER JOIN [#imarhdr_vw] b    
                        ON a.[source_ctrl_num] = b.[source_ctrl_num]
                                AND RTRIM(LTRIM(ISNULL(a.[company_code], ''))) = RTRIM(LTRIM(ISNULL(b.[company_code], '')))
                                AND a.[trx_type] = b.[trx_type]
                WHERE RTRIM(LTRIM(ISNULL(a.[company_code], ''))) = @company_code
                        AND a.[trx_type] = @invoice_flag
                        AND (NOT a.[processed_flag] = 1 OR a.[processed_flag] IS NULL)
                        AND b.[processed_flag] = 1
                        AND (a.[User_ID] = @userid OR @userid = 0)
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' [CVO_Control]..[imarhdr] 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END   
        UPDATE [CVO_Control]..[imarhdr]
                SET [process_ctrl_num] = @process_ctrl_num,
                    [processed_flag] = b.[processed_flag],
                    [date_processed] = b.[date_processed]
                FROM [CVO_Control]..[imarhdr] a 
                INNER JOIN [#imarhdr_vw] b    
                        ON a.[source_ctrl_num] = b.[source_ctrl_num]
                                AND RTRIM(LTRIM(ISNULL(a.[company_code], ''))) = RTRIM(LTRIM(ISNULL(b.[company_code], '')))
                                AND a.[trx_type] = b.[trx_type]
                WHERE RTRIM(LTRIM(ISNULL(a.[company_code], ''))) = @company_code
                        AND a.[trx_type] = @invoice_flag
                        AND (NOT a.[processed_flag] = 1 OR a.[processed_flag] IS NULL)
                        AND b.[processed_flag] = 2
                        AND (a.[User_ID] = @userid OR @userid = 0)
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' [CVO_Control]..[imarhdr] 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END   
        UPDATE [CVO_Control]..[imardtl]
                SET [process_ctrl_num] = @process_ctrl_num,
                    [processed_flag] = b.[processed_flag],
                    [trx_ctrl_num] = b.[trx_ctrl_num]
                FROM [CVO_Control]..[imardtl] a 
                INNER JOIN [#imardtl_vw] b    
                        ON a.[source_ctrl_num] = b.[source_ctrl_num]
                                AND RTRIM(LTRIM(ISNULL(a.[company_code], ''))) = RTRIM(LTRIM(ISNULL(b.[company_code], '')))
                                AND a.[trx_type] = b.[trx_type]
                                AND a.[sequence_id] = b.[sequence_id] 
                WHERE RTRIM(LTRIM(ISNULL(a.company_code, ''))) = @company_code
                        AND b.trx_type = @invoice_flag
                        AND (NOT a.processed_flag = 1 OR a.processed_flag IS NULL)
                        AND b.[processed_flag] = 1
                        AND (a.[User_ID] = @userid OR @userid = 0)
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' [CVO_Control]..imardtl 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END   
        UPDATE [CVO_Control]..imardtl
                SET [process_ctrl_num] = @process_ctrl_num,
                    [processed_flag] = b.[processed_flag]
                FROM [CVO_Control]..[imardtl] a 
                INNER JOIN [#imardtl_vw] b    
                        ON a.[source_ctrl_num] = b.[source_ctrl_num]
                                AND RTRIM(LTRIM(ISNULL(a.[company_code], ''))) = RTRIM(LTRIM(ISNULL(b.[company_code], '')))
                                AND a.[trx_type] = b.[trx_type]
                                AND a.[sequence_id] = b.[sequence_id] 
                WHERE RTRIM(LTRIM(ISNULL(a.company_code, ''))) = @company_code
                        AND b.trx_type = @invoice_flag
                        AND (NOT a.[processed_flag] = 1 OR a.[processed_flag] IS NULL)
                        AND b.[processed_flag] = 2
                        AND (a.[User_ID] = @userid OR @userid = 0)
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' [CVO_Control]..imardtl 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END   
        END
    ELSE
        BEGIN    
        UPDATE [CVO_Control]..imarhdr
                SET process_ctrl_num = @process_ctrl_num,
                    processed_flag = b.processed_flag,
                    date_processed = b.date_processed
                FROM [CVO_Control]..imarhdr a 
                INNER JOIN #imarhdr_vw b    
                        ON a.source_ctrl_num = b.source_ctrl_num
                                AND RTRIM(LTRIM(ISNULL(a.company_code, ''))) = RTRIM(LTRIM(ISNULL(b.company_code, '')))
                                AND a.trx_type = b.trx_type
                WHERE RTRIM(LTRIM(ISNULL(a.company_code, ''))) = @company_code
                        AND a.trx_type = @invoice_flag
                        AND (NOT a.[processed_flag] = 1 OR a.[processed_flag] IS NULL)
                        AND (a.[User_ID] = @userid OR @userid = 0)
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' [CVO_Control]..imarhdr 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END   
        UPDATE [CVO_Control]..imardtl
                SET process_ctrl_num = @process_ctrl_num,
                    processed_flag = b.processed_flag
                FROM [CVO_Control]..imardtl a 
                INNER JOIN #imardtl_vw b    
                        ON a.source_ctrl_num = b.source_ctrl_num
                                AND RTRIM(LTRIM(ISNULL(a.company_code, ''))) = RTRIM(LTRIM(ISNULL(b.company_code, '')))
                                AND a.trx_type = b.trx_type
                                AND a.[sequence_id] = b.[sequence_id]
                WHERE RTRIM(LTRIM(ISNULL(a.company_code, ''))) = @company_code
                        AND b.trx_type = @invoice_flag
                        AND (NOT a.[processed_flag] = 1 OR a.[processed_flag] IS NULL)
                        AND (a.[User_ID] = @userid OR @userid = 0)
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' [CVO_Control]..imardtl 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END   
        END
    --
    -- Make sure that perror.trx_ctrl_num contains a value so the x_Errors_sp routine 
    -- can retrieve the errors.  A link in that routine needs to be made using one of
    -- these combinations:
    --     * perror.trx_ctrl_num = staging.trx_ctrl_num
    --     * perror.trx_ctrl_num = staging.source_ctrl_num
    --     * perror.source_ctrl_num = staging.source_ctrl_num 
    --
    UPDATE [perror]
            SET [perror].[trx_ctrl_num] = b.[source_ctrl_num]
            FROM [perror] a
            INNER JOIN [CVO_Control]..[imarhdr] b
                    ON a.[process_ctrl_num] = b.[process_ctrl_num]
                            AND a.[source_ctrl_num] = b.[source_ctrl_num]
            WHERE RTRIM(LTRIM(ISNULL(b.company_code, ''))) = @company_code
                    AND b.[trx_type] = @invoice_flag
                    AND b.[processed_flag] = 2
                    AND a.[sequence_id] = 0
                    AND (RTRIM(LTRIM(ISNULL(a.[trx_ctrl_num], ''))) = '' OR a.[trx_ctrl_num] IS NULL)
                    AND (b.[User_ID] = @userid OR @userid = 0)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' perror 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END   
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': Exit.'
    RETURN 0
Error_Return:
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': Exit (ERROR).'
    RETURN -1    
GO
GRANT EXECUTE ON  [dbo].[imarint01b_sp] TO [public]
GO
