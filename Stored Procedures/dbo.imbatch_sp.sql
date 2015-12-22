SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


    CREATE PROC 
[dbo].[imbatch_sp] @company_code VARCHAR(8), 
           @trx_type int,
           @debug_level SMALLINT,
           @userid INT = 0,
           @imbatch_sp_User_Name VARCHAR(30) = ''
    AS      
    DECLARE @batch_code CHAR(16),
            @complete_date INT,
            @complete_time INT,
            @complete_user CHAR(30),
            @date_applied INT,
            @rowcount INT
    DECLARE @Message_String VARCHAR(250)
    DECLARE @precision_gl INT        
    DECLARE @Transaction_Count INT
    
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
    

    SET @Routine_Name = 'imbatch_sp'        
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': Entry.  @company_code = ' + LTRIM(@company_code) + ', ' + RTRIM(LTRIM(CONVERT(CHAR(5),@trx_type)))
    
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

    


    IF @trx_type = 0
        BEGIN
        IF EXISTS (SELECT 1 FROM glco WHERE batch_proc_flag = 0)
            BEGIN
            IF @debug_level >= 3
                SELECT '(3): ' + @Routine_Name + ': Batch processing is not enabled'
            RETURN
            END
        END
    IF @trx_type = 2031 
            OR @trx_type = 2032
        BEGIN
        IF EXISTS (SELECT 1 FROM arco WHERE batch_proc_flag = 0)
            BEGIN
            IF @debug_level >= 3
                SELECT '(3): ' + @Routine_Name + ': Batch processing is not enabled'
            RETURN
            END
        END
    IF @trx_type = 4091 
            OR @trx_type = 4092
        BEGIN
        IF EXISTS (SELECT 1 FROM apco WHERE batch_proc_flag = 0)
            BEGIN
            IF @debug_level >= 3
                SELECT '(3): ' + @Routine_Name + ': Batch processing is not enabled'
            RETURN
            END
        END
    


    SELECT @complete_date = datediff(dd, @January_First_Nineteen_Eighty, CONVERT(datetime, getdate())) + 722815,
           @complete_time = datepart(hh, getdate()) * 3600 + datepart(mi, getdate()) * 60 + datepart(ss, getdate())
    IF DATALENGTH(LTRIM(RTRIM(ISNULL(@imbatch_sp_User_Name, '')))) = 0       
        SET @complete_user = SUSER_SNAME()
    ELSE
        SET @complete_user = @imbatch_sp_User_Name
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @complete_date' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    


    SELECT @precision_gl = 2
    SELECT @precision_gl = curr_precision
            FROM glco, glcurr_vw
            WHERE glco.home_currency = glcurr_vw.currency_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' glco 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    

 
    SELECT @batch_code = ''
    IF @trx_type = 0
        BEGIN
        SET ROWCOUNT 1
        SELECT DISTINCT @batch_code = a.batch_code 
                FROM gltrx a, #imglhdr_vw b 
                WHERE a.document_1 = b.document_1 
                        AND b.processed_flag = 1
                        AND NOT b.document_1 = ''
                        AND a.batch_code > @batch_code
                ORDER BY a.batch_code
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' gltrx 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        SET ROWCOUNT 0
        SELECT @Transaction_Count = COUNT(*) 
                FROM [gltrx]
                WHERE [batch_code] = @batch_code
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' gltrx 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        END
    IF @trx_type = 2031 
            OR @trx_type = 2032
        BEGIN
        SET ROWCOUNT 1
        SELECT DISTINCT @batch_code = a.batch_code 
                FROM arinpchg a, #imarhdr_vw b 
                WHERE a.trx_ctrl_num = b.trx_ctrl_num 
                        AND b.processed_flag = 1
                        AND NOT b.trx_ctrl_num = ''
                        AND a.batch_code > @batch_code
                ORDER BY a.batch_code
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' arinpchg 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        SET ROWCOUNT 0
        END
    IF @trx_type = 4091 
            OR @trx_type = 4092
        BEGIN
        SET ROWCOUNT 1
        SELECT DISTINCT @batch_code = a.batch_code 
                FROM apinpchg a, #imaphdr_vw b 
                WHERE a.trx_ctrl_num = b.trx_ctrl_num 
                        AND b.processed_flag = 1
                        AND NOT b.trx_ctrl_num = ''
                        AND a.batch_code > @batch_code
                ORDER BY a.batch_code
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' apinpchg 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        SET ROWCOUNT 0
        END
    WHILE (@Row_Count = 1)
        BEGIN
        IF @debug_level >= 3
            SELECT '(3): ' + @Routine_Name + ': Processing @batch_code = ' + @batch_code
        


        IF @trx_type = 2031 
                OR @trx_type = 2032
            BEGIN
            IF EXISTS (SELECT 1 FROM arinpchg WHERE printed_flag = 0 AND batch_code = @batch_code)
                BEGIN
                SET @Message_String = 'WARNING: Batch ' + RTRIM(LTRIM(@batch_code)) + ' not marked as completed because it contains unprinted transactions.'
                EXEC im_log_sp @Message_String,
                               'YES',
                               @userid
                SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' im_log_sp 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
                GOTO NEXTBATCH
                END        
            END
        SELECT @date_applied = date_applied
                FROM batchctl
                WHERE batch_ctrl_num = @batch_code
                        AND RTRIM(LTRIM(ISNULL(company_code, ''))) = RTRIM(LTRIM(ISNULL(@company_code, '')))
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @date_applied' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        IF @trx_type = 0
            BEGIN
            UPDATE gltrx
                    SET date_applied = @date_applied
                    WHERE batch_code = @batch_code
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' gltrx 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            END
        IF @trx_type = 2031 
                OR @trx_type = 2032
            BEGIN
            UPDATE arinpchg
                    SET date_applied = @date_applied
                    WHERE batch_code = @batch_code
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' arinpchg 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            UPDATE arinpage
                    SET date_applied = @date_applied
                    FROM arinpchg a, arinpage b
                    WHERE a.trx_ctrl_num = b.trx_ctrl_num
                            AND a.trx_type = b.trx_type
                            AND a.batch_code = @batch_code
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' arinpage 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            END    
        IF @trx_type = 4091 
                OR @trx_type = 4092
            BEGIN
            UPDATE apinpchg
                    SET date_applied = @date_applied
                    WHERE batch_code = @batch_code
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' apinpchg 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            END
        IF @trx_type = 0
            BEGIN    
            UPDATE batchctl
                    SET completed_user = @complete_user,
                        completed_date = @complete_date,
                        completed_time = @complete_time,
                        actual_number = @Transaction_Count,
                        control_number = @Transaction_Count
                    WHERE batch_ctrl_num = @batch_code
                            AND RTRIM(LTRIM(ISNULL(company_code, ''))) = RTRIM(LTRIM(ISNULL(@company_code, '')))
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' batchctl 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            END
        ELSE
            BEGIN    
            UPDATE batchctl
                    SET completed_user = @complete_user,
                        completed_date = @complete_date,
                        completed_time = @complete_time,
                        control_number = actual_number,
                        control_total = ROUND(actual_total, @precision_gl)
                    WHERE batch_ctrl_num = @batch_code
                            AND RTRIM(LTRIM(ISNULL(company_code, ''))) = RTRIM(LTRIM(ISNULL(@company_code, '')))
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' batchctl 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            END
NEXTBATCH:
        IF @trx_type = 0
            BEGIN
            SET ROWCOUNT 1
            SELECT DISTINCT @batch_code = a.batch_code 
                    FROM gltrx a, #imglhdr_vw b 
                    WHERE a.document_1 = b.document_1 
                            AND b.processed_flag = 1
                            AND NOT b.document_1 = ''
                            AND a.batch_code > @batch_code
                    ORDER BY a.batch_code
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' gltrx 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            SET ROWCOUNT 0
            SELECT @Transaction_Count = COUNT(*) 
                    FROM [gltrx]
                    WHERE [batch_code] = @batch_code
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' gltrx 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            END
        IF @trx_type = 2031 
                OR @trx_type = 2032
            BEGIN
            SET ROWCOUNT 1
            SELECT DISTINCT @batch_code = a.batch_code 
                    FROM arinpchg a, #imarhdr_vw b 
                    WHERE a.trx_ctrl_num = b.trx_ctrl_num 
                            AND b.processed_flag = 1
                            AND NOT b.trx_ctrl_num = ''
                            AND a.batch_code > @batch_code
                    ORDER BY a.batch_code
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' arinpchg 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            SET ROWCOUNT 0
            END
        IF @trx_type = 4091 
                OR @trx_type = 4092
            BEGIN
            SET ROWCOUNT 1
            SELECT DISTINCT @batch_code = a.batch_code 
                    FROM apinpchg a, #imaphdr_vw b 
                    WHERE a.trx_ctrl_num = b.trx_ctrl_num 
                            AND b.processed_flag = 1
                            AND NOT b.trx_ctrl_num = ''
                            AND a.batch_code > @batch_code
                    ORDER BY a.batch_code
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' apinpchg 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            SET ROWCOUNT 0
            END
        END
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': Exit.'
    RETURN 0
Error_Return:
    RETURN -1    
GO
GRANT EXECUTE ON  [dbo].[imbatch_sp] TO [public]
GO
