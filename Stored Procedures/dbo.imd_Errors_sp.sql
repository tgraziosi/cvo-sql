SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

    
    CREATE PROC
[dbo].[imd_Errors_sp] (@imd_Errors_sp_Table_Name VARCHAR(128),
               @imd_Errors_sp_Dummy_1 VARCHAR(128) = '',
               @imd_Errors_sp_Dummy_2 INT = 0,
               @imd_Errors_sp_record_id_num INT = -1,
               @userid INT = 0)
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
    

    DECLARE @Base_SQL VARCHAR(1000)
    DECLARE @company_code VARCHAR(8)
    DECLARE @debug_level INT
    DECLARE @imd_Errors_sp_cursor_record_id_num INT
    DECLARE @imd_Errors_sp_cursor_record_status_1 INT
    DECLARE @imd_Errors_sp_cursor_record_status_2 INT
    DECLARE @record_status_Bit INT
    DECLARE @SPID INT
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
    

    SET @Routine_Name = 'imd_Errors_sp'        
    --
    -- This stored procedure is being executed in the context of the company database, 
    -- so get company_code from glco.
    --
    SELECT @company_code = LTRIM(RTRIM(ISNULL([company_code], '')))
        FROM [glco]
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @company_code 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END   
    --
    -- Create a temporary table to hold the error bits.  Note that @userid
    -- is not needed in the "ELSE" case since record_id_num is unique throughout the 
    -- staging table.
    --
    IF NOT EXISTS (SELECT 1 WHERE OBJECT_ID('tempdb..#imd_Errors_sp_1') IS NULL) 
        DROP TABLE [#imd_Errors_sp_1] 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DROPTABLE + ' #imd_Errors_sp_1 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END   
    CREATE TABLE [#imd_Errors_sp_1]
            ([record_status_1] INT NULL,
             [record_status_2] INT NULL,
             [record_id_num] INT NULL)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATETABLE + ' #imd_Errors_sp_1 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END   
    IF @imd_Errors_sp_record_id_num = -1
        BEGIN
        SET @SQL = 'INSERT INTO [#imd_Errors_sp_1]'
                        + ' ([record_status_1], [record_status_2], [record_id_num])'
                        + ' SELECT ISNULL([record_status_1], 0), ISNULL([record_status_2], 0), [record_id_num]' 
                                + ' FROM [' + @imd_Errors_sp_Table_Name + ']'
                                + ' WHERE LTRIM(RTRIM(ISNULL([company_code], ''''))) = ''' + @company_code + ''''
                                        + ' AND ([User_ID] = ' + CAST(@userid AS VARCHAR) + ' OR ' + CAST(@userid AS VARCHAR) + ' = 0)'
        END
    ELSE
        BEGIN
        SET @SQL = 'INSERT INTO [#imd_Errors_sp_1]'
                        + ' ([record_status_1], [record_status_2], [record_id_num])'
                        + ' SELECT ISNULL([record_status_1], 0), ISNULL([record_status_2], 0), [record_id_num]' 
                                + ' FROM [' + @imd_Errors_sp_Table_Name + ']'
                                + ' WHERE LTRIM(RTRIM(ISNULL([company_code], ''''))) = ''' + @company_code + ''''
                                        + ' AND [record_id_num] = ' + CAST(@imd_Errors_sp_record_id_num AS VARCHAR)
        END
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SET + ' 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END   
    EXEC (@SQL)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END   
    --
    -- Create a temporary table to hold the text of the errors.
    --
    IF NOT EXISTS (SELECT 1 WHERE OBJECT_ID('tempdb..#Messages') IS NULL) 
        DROP TABLE [#Messages] 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DROPTABLE + ' #Messages 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END   
    CREATE TABLE [#Messages]
            ([Text] VARCHAR(250),
             [record_id_num] INT NULL) 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATETABLE + ' #Messages 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END  
    --
    DECLARE [imd_Errors_sp_cursor] INSENSITIVE CURSOR FOR
            SELECT [record_status_1],
                   [record_status_2],
                   [record_id_num] 
                    FROM [#imd_Errors_sp_1]
            ORDER BY [record_id_num]
    OPEN [imd_Errors_sp_cursor]
    FETCH NEXT
            FROM [imd_Errors_sp_cursor]
            INTO @imd_Errors_sp_cursor_record_status_1,
                 @imd_Errors_sp_cursor_record_status_2,
                 @imd_Errors_sp_cursor_record_id_num
    WHILE @@FETCH_STATUS = 0
        BEGIN
        IF NOT @imd_Errors_sp_cursor_record_status_1 = 0
                OR NOT @imd_Errors_sp_cursor_record_status_2 = 0
            BEGIN
            SET @Base_SQL = 'INSERT INTO [#Messages]'
                                 + ' SELECT SUBSTRING(SUBSTRING(''['' + CAST(ISNULL([error_message], 0) AS VARCHAR) + '']'' + SPACE(43), 1, 45) + ISNULL([text], ISNULL([error_message], '''')), 1, 255), ' + CAST(@imd_Errors_sp_cursor_record_id_num AS VARCHAR)
                                         + ' FROM [CVO_Control]..[imerrxref] a'
                                         + ' INNER JOIN [CVO_Control]..[aeg_error] b'
                                                 + ' ON a.[error_message] = b.[error_code]' 
                                         + ' WHERE a.[imtable] = ''' + @imd_Errors_sp_Table_Name + ''''
                                                 + ' AND a.[error_message] = b.[error_code]'
                                                 + ' AND a.[error_bit] = '
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SET + ' 4' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END   
            --
            -- Put messages into the temporary table.
            --
            IF NOT @imd_Errors_sp_cursor_record_status_1 = 0
                BEGIN
                SET @record_status_Bit = 1
                WHILE @record_status_Bit <= 1073741824                         
                    BEGIN
                    IF (@imd_Errors_sp_cursor_record_status_1 & @record_status_Bit) > 0
                        BEGIN
                        SET @SQL = @Base_SQL + CAST(@record_status_Bit AS VARCHAR) 
                        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SET + ' 5' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END   
                        SET @SQL = @SQL + ' AND a.[status_field] = 0'
                        EXEC (@SQL)
                        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' 4' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END   
                        END
                    IF @record_status_Bit = 1073741824
                        SET @record_status_Bit = 2000000000
                    ELSE
                        SET @record_status_Bit = @record_status_Bit * 2
                    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SET + ' 6' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END   
                    END
                END               
            IF NOT @imd_Errors_sp_cursor_record_status_2 = 0
                BEGIN
                SET @record_status_Bit = 1
                WHILE @record_status_Bit <= 1073741824                         
                    BEGIN
                    IF (@imd_Errors_sp_cursor_record_status_2 & @record_status_Bit) > 0
                        BEGIN
                        SET @SQL = @Base_SQL + CAST(@record_status_Bit AS VARCHAR) 
                        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SET + ' 5' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END   
                        SET @SQL = @SQL + ' AND a.[status_field] = 1'
                        EXEC (@SQL)
                        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' 4' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END   
                        END
                    IF @record_status_Bit = 1073741824
                        SET @record_status_Bit = 2000000000
                    ELSE
                        SET @record_status_Bit = @record_status_Bit * 2
                    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SET + ' 6' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END   
                    END
                END
            END      
        FETCH NEXT
                FROM [imd_Errors_sp_cursor]
                INTO @imd_Errors_sp_cursor_record_status_1,
                     @imd_Errors_sp_cursor_record_status_2,
                     @imd_Errors_sp_cursor_record_id_num
        END            
    CLOSE imd_Errors_sp_cursor
    DEALLOCATE imd_Errors_sp_cursor                          
    --
    -- Return the messages.
    --    
    IF @imd_Errors_sp_record_id_num = -1
        BEGIN
        SELECT CAST([Text] AS VARCHAR(250)) AS 'Text', [record_id_num] 
                FROM [#Messages]
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' #Messages 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END   
        END
    ELSE    
        BEGIN
        SELECT CAST([Text] AS VARCHAR(250)) AS 'Text' 
                FROM [#Messages]
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' #Messages 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END   
        END
    RETURN 0
Error_Return:
    RETURN -1    
GO
GRANT EXECUTE ON  [dbo].[imd_Errors_sp] TO [public]
GO
