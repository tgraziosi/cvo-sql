SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

    
    CREATE PROC
[dbo].[imapint01_Errors_sp] (@imapint01_Errors_sp_Dummy_1 VARCHAR(128) = '',
                     @imapint01_Errors_sp_Table_Indicator VARCHAR(128) = '',
                     @imapint01_Errors_sp_Dummy_2 VARCHAR(128) = '',
                     @imapint01_Errors_sp_record_id_num INT = -1,
                     @imapint01_Errors_sp_Transaction_Type INT,
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
    

    DECLARE @company_code VARCHAR(8)
    DECLARE @debug_level INT
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
    

    SET @Routine_Name = 'imapint01_Errors_sp'        
    --
    -- Obtain company_code
    --
    SELECT @company_code = LTRIM(RTRIM(ISNULL([company_code], '')))
        FROM [glco]
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @company_code 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END   
    --
    -- Obtain error messages for the specified record, or all records if "-1" is specified..
    --
    -- The JOINs between perror and the staging table use 
    -- perror.trx_ctrl_num = staging.source_trx_ctrl_num for "trial"
    -- and perror.trx_ctrl_num = staging.trx_ctrl_num for "final". 
    -- The second equality test is also used for "trial" if the customer 
    -- elects to import trx_ctrl_num from the staging table. 
    --     
    IF @imapint01_Errors_sp_record_id_num = -1
        BEGIN
        DECLARE @ewcomp_cursor_db_name VARCHAR(128)
        IF NOT EXISTS (SELECT 1 WHERE OBJECT_ID('tempdb..#imapint01_Errors_sp_1') IS NULL) 
            BEGIN
            DROP TABLE [#imapint01_Errors_sp_1]
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DROPTABLE + ' #imapint01_Errors_sp_1 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            END
        CREATE TABLE [#imapint01_Errors_sp_1] 
                ([Text] VARCHAR(250) NULL,
                 [record_id_num] INT NULL,
                 [Import Identifier] INT NULL,
                 [company_code] VARCHAR(8) NULL,
                 [process_ctrl_num] VARCHAR(16) NULL, -- For alternate style import report
                 [batch_code] VARCHAR(16) NULL, -- For alternate style import report
                 [module_id] SMALLINT NULL, -- For alternate style import report
                 [err_code] INT NULL, -- For alternate style import report
                 [info1] VARCHAR(32) NULL, -- For alternate style import report
                 [info2] VARCHAR(32) NULL, -- For alternate style import report
                 [infoint] INT NULL, -- For alternate style import report
                 [infofloat] FLOAT NULL, -- For alternate style import report
                 [flag1] SMALLINT NULL, -- For alternate style import report
                 [trx_ctrl_num] VARCHAR(16) NULL, -- For alternate style import report
                 [sequence_id] INT NULL, -- For alternate style import report
                 [source_ctrl_num] VARCHAR(16) NULL, -- For alternate style import report
                 [extra] INT NULL) -- For alternate style import report
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATETABLE + ' #imapint01_Errors_sp_1 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END   
        DECLARE ewcomp_cursor INSENSITIVE CURSOR FOR
                SELECT [db_name]
                        FROM [CVO_Control]..[ewcomp]
                        ORDER BY [company_code]
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DECLARE + ' ewcomp_cursor 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END   
        OPEN ewcomp_cursor
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_OPEN + ' ewcomp_cursor 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END   
        FETCH NEXT
                FROM ewcomp_cursor
                INTO @ewcomp_cursor_db_name
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_FETCHNEXT + ' ewcomp_cursor 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END   
        WHILE @@FETCH_STATUS = 0
            BEGIN

	    IF(HAS_DBACCESS (@ewcomp_cursor_db_name) = 1)
		BEGIN
            --
            -- The IF EXISTS is used to see if Import Manager has been installed in this database.
            --
            SET @SQL = 'IF EXISTS (SELECT [TABLE_NAME] FROM [' + @ewcomp_cursor_db_name + '].INFORMATION_SCHEMA.TABLES WHERE [TABLE_NAME] = ''imaphdr_vw'')'
                        + ' INSERT INTO [#imapint01_Errors_sp_1]'
                                + ' SELECT CAST(SUBSTRING(''['' + CAST(ISNULL(a.[err_code], 0) AS VARCHAR) + '']'' + SPACE(43), 1, 45) + ISNULL([err_desc], ISNULL(a.[err_code], '''')) AS VARCHAR(250)) AS ''Text'','
                                       + ' c.record_id_num,'
                                       + ' CAST(ISNULL(c.[Import Identifier], 0) AS VARCHAR) AS ''Import Identifier'','
                                       + ' c.[company_code],'
                                       + ' a.[process_ctrl_num],' -- For alternate style import report
                                       + ' a.[batch_code],' -- For alternate style import report
                                       + ' a.[module_id],' -- For alternate style import report
                                       + ' a.[err_code],' -- For alternate style import report
                                       + ' a.[info1],' -- For alternate style import report
                                       + ' a.[info2],' -- For alternate style import report
                                       + ' a.[infoint],' -- For alternate style import report
                                       + ' a.[infofloat],' -- For alternate style import report
                                       + ' a.[flag1],' -- For alternate style import report
                                       + ' a.[trx_ctrl_num],' -- For alternate style import report
                                       + ' a.[sequence_id],' -- For alternate style import report
                                       + ' a.[source_ctrl_num],' -- For alternate style import report
                                       + ' a.[extra]' -- For alternate style import report
                                        + ' FROM [' + @ewcomp_cursor_db_name + ']..[perror] a'
                                        + ' INNER JOIN aredterr b'
                                                + ' ON a.err_code = b.e_code'
                                        + ' INNER JOIN [CVO_Control]..[imaphdr] c'
                                                + ' ON (a.[trx_ctrl_num] = c.[trx_ctrl_num] OR a.[trx_ctrl_num] = c.[source_trx_ctrl_num] OR a.[source_ctrl_num] = c.[source_trx_ctrl_num])'
                                        + ' WHERE a.module_id = 2000'
                                                + ' AND (b.e_active = 1 OR b.e_active = -1)'
                                                + ' AND c.[trx_type] = ' + CAST(@imapint01_Errors_sp_Transaction_Type AS VARCHAR)
                                                + ' AND (c.[User_ID] = ' + CAST(@userid AS VARCHAR) + ' OR ' + CAST(@userid AS VARCHAR) + ' = 0)'
                                + ' UNION'
                                + ' SELECT CAST(SUBSTRING(''['' + CAST(ISNULL(a.[err_code], 0) AS VARCHAR) + '']'' + SPACE(43), 1, 45) + ISNULL([err_desc], ISNULL(a.[err_code], '''')) AS VARCHAR(250)) AS ''Text'','
                                       + ' c.record_id_num,'
                                       + ' CAST(ISNULL(c.[Import Identifier], 0) AS VARCHAR) AS ''Import Identifier'','
                                       + ' c.[company_code],'
                                       + ' a.[process_ctrl_num],'
                                       + ' a.[batch_code],'
                                       + ' a.[module_id],'
                                       + ' a.[err_code],'
                                       + ' a.[info1],'
                                       + ' a.[info2],'
                                       + ' a.[infoint],'
                                       + ' a.[infofloat],'
                                       + ' a.[flag1],'
                                       + ' a.[trx_ctrl_num],'
                                       + ' a.[sequence_id],'
                                       + ' a.[source_ctrl_num],'
                                       + ' a.[extra]'
                                        + ' FROM [' + @ewcomp_cursor_db_name + ']..[perror] a'
                                        + ' INNER JOIN apedterr b'
                                                + ' ON a.err_code = b.err_code'
                                        + ' INNER JOIN [CVO_Control]..[imaphdr] c'
                                                + ' ON (a.[trx_ctrl_num] = c.[trx_ctrl_num] OR a.[trx_ctrl_num] = c.[source_trx_ctrl_num] OR a.[source_ctrl_num] = c.[source_trx_ctrl_num])'
                                        + ' WHERE a.module_id = 4000'
                                                + ' AND c.[trx_type] = ' + CAST(@imapint01_Errors_sp_Transaction_Type AS VARCHAR)
                                                + ' AND (c.[User_ID] = ' + CAST(@userid AS VARCHAR) + ' OR ' + CAST(@userid AS VARCHAR) + ' = 0)'
                                + ' UNION'
                                + ' SELECT CAST(SUBSTRING(''['' + CAST(ISNULL(a.[err_code], 0) AS VARCHAR) + '']'' + SPACE(43), 1, 45) + ISNULL([e_ldesc], ISNULL(a.[err_code], '''')) AS VARCHAR(250)) AS ''Text'','
                                       + ' c.record_id_num,'
                                       + ' CAST(ISNULL(c.[Import Identifier], 0) AS VARCHAR) AS ''Import Identifier'','
                                       + ' c.[company_code],'
                                       + ' a.[process_ctrl_num],'
                                       + ' a.[batch_code],'
                                       + ' a.[module_id],'
                                       + ' a.[err_code],'
                                       + ' a.[info1],'
                                       + ' a.[info2],'
                                       + ' a.[infoint],'
                                       + ' a.[infofloat],'
                                       + ' a.[flag1],'
                                       + ' a.[trx_ctrl_num],'
                                       + ' a.[sequence_id],'
                                       + ' a.[source_ctrl_num],'
                                       + ' a.[extra]'
                                        + ' FROM [' + @ewcomp_cursor_db_name + ']..[perror] a'
                                        + ' INNER JOIN glerrdef b'
                                                + ' ON a.err_code = b.e_code'
                                        + ' INNER JOIN [CVO_Control]..[imaphdr] c'
                                                + ' ON (a.[trx_ctrl_num] = c.[trx_ctrl_num] OR a.[trx_ctrl_num] = c.[source_trx_ctrl_num] OR a.[source_ctrl_num] = c.[source_trx_ctrl_num])'
                                        + ' WHERE a.module_id = 6000'
                                                + ' AND (b.e_active = 1 OR b.e_active = -1)'
                                                + ' AND c.[trx_type] = ' + CAST(@imapint01_Errors_sp_Transaction_Type AS VARCHAR)
                                                + ' AND (c.[User_ID] = ' + CAST(@userid AS VARCHAR) + ' OR ' + CAST(@userid AS VARCHAR) + ' = 0)'
	            EXEC (@SQL)
		END /* End  IF(HAS_DBACCESS (@ewcomp_cursor_db_name) = 1) */

            FETCH NEXT
                    FROM ewcomp_cursor
                    INTO @ewcomp_cursor_db_name
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_FETCHNEXT + ' ewcomp_cursor 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END   
            END
        CLOSE ewcomp_cursor
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CLOSE + ' ewcomp_cursor 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        DEALLOCATE ewcomp_cursor
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DEALLOCATE + ' ewcomp_cursor 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        SELECT *
                FROM [#imapint01_Errors_sp_1]
                ORDER BY [company_code], [record_id_num]                
        DROP TABLE [#imapint01_Errors_sp_1]
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DROPTABLE + ' #imapint01_Errors_sp_1 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        END
    ELSE                    
        BEGIN
        IF UPPER(@imapint01_Errors_sp_Table_Indicator) = 'H'
            BEGIN
            SELECT CAST(SUBSTRING('[' + CAST(ISNULL(a.[err_code], 0) AS VARCHAR) + ']' + SPACE(43), 1, 45) + ISNULL([err_desc], ISNULL(a.[err_code], '')) AS VARCHAR(250)) AS 'Text',
                   c.record_id_num,
                   CAST(ISNULL(c.[Import Identifier], 0) AS VARCHAR) AS 'Import Identifier'
                    FROM perror a 
                    INNER JOIN aredterr b 
                            ON a.err_code = b.e_code
                    INNER JOIN [imaphdr_vw] c 
                            ON (a.[trx_ctrl_num] = c.[trx_ctrl_num] OR a.[trx_ctrl_num] = c.[source_trx_ctrl_num] OR a.[source_ctrl_num] = c.[source_trx_ctrl_num])
                    WHERE a.module_id = 2000
                            AND (b.e_active = 1 OR b.e_active = -1)
                            AND c.record_id_num = @imapint01_Errors_sp_record_id_num
                            AND (a.[sequence_id] = 0 OR a.[sequence_id] IS NULL)
            UNION 
            SELECT CAST(SUBSTRING('[' + CAST(ISNULL(a.[err_code], 0) AS VARCHAR) + ']' + SPACE(43), 1, 45) + ISNULL([err_desc], ISNULL(a.[err_code], '')) + ' ' + (CASE [infoint] WHEN 0 THEN '' ELSE CAST([infoint] AS VARCHAR) END) AS VARCHAR(250)) AS 'Text',
                   c.record_id_num,
                   CAST(ISNULL(c.[Import Identifier], 0) AS VARCHAR) AS 'Import Identifier'
                    FROM perror a
                    INNER JOIN apedterr b 
                            ON a.err_code = b.err_code
                    INNER JOIN [imaphdr_vw] c 
                            ON (a.[trx_ctrl_num] = c.[trx_ctrl_num] OR a.[trx_ctrl_num] = c.[source_trx_ctrl_num] OR a.[source_ctrl_num] = c.[source_trx_ctrl_num])
                    WHERE a.module_id = 4000
                            AND c.record_id_num = @imapint01_Errors_sp_record_id_num
                            AND (a.[sequence_id] = 0 OR a.[sequence_id] IS NULL)
            UNION 
            SELECT CAST(SUBSTRING('[' + CAST(ISNULL(a.[err_code], 0) AS VARCHAR) + ']' + SPACE(43), 1, 45) + ISNULL([e_ldesc], ISNULL(a.[err_code], '')) AS VARCHAR(250)) AS 'Text',
                   c.record_id_num,
                   CAST(ISNULL(c.[Import Identifier], 0) AS VARCHAR) AS 'Import Identifier'
                    FROM perror a
                    INNER JOIN glerrdef b 
                            ON a.err_code = b.e_code
                    INNER JOIN [imaphdr_vw] c 
                            ON (a.[trx_ctrl_num] = c.[trx_ctrl_num] OR a.[trx_ctrl_num] = c.[source_trx_ctrl_num] OR a.[source_ctrl_num] = c.[source_trx_ctrl_num])
                    WHERE a.module_id = 6000
                            AND (b.e_active = 1 OR b.e_active = -1)
                            AND c.record_id_num = @imapint01_Errors_sp_record_id_num
                            AND (a.[sequence_id] = 0 OR a.[sequence_id] IS NULL)
            END                
        IF UPPER(@imapint01_Errors_sp_Table_Indicator) = 'D'
            BEGIN
            SELECT CAST(SUBSTRING('[' + CAST(ISNULL(a.[err_code], 0) AS VARCHAR) + ']' + SPACE(43), 1, 45) + ISNULL([err_desc], ISNULL(a.[err_code], '')) AS VARCHAR(250)) AS 'Text',
                   c.record_id_num,
                   CAST(ISNULL(c.[Import Identifier], 0) AS VARCHAR) AS 'Import Identifier'
                    FROM perror a 
                    INNER JOIN aredterr b 
                            ON a.err_code = b.e_code
                    INNER JOIN [imapdtl_vw] c 
                            ON (a.[trx_ctrl_num] = c.[trx_ctrl_num] OR a.[trx_ctrl_num] = c.[source_trx_ctrl_num] OR a.[source_ctrl_num] = c.[source_trx_ctrl_num])
                    WHERE a.module_id = 2000
                            AND (b.e_active = 1 OR b.e_active = -1)
                            AND c.record_id_num = @imapint01_Errors_sp_record_id_num
                            AND ((a.[sequence_id] = c.[sequence_id]) OR (a.[sequence_id] = -1))
            UNION 
            SELECT CAST(SUBSTRING('[' + CAST(ISNULL(a.[err_code], 0) AS VARCHAR) + ']' + SPACE(43), 1, 45) + ISNULL([err_desc], ISNULL(a.[err_code], '')) AS VARCHAR(250)) AS 'Text',
                   c.record_id_num,
                   CAST(ISNULL(c.[Import Identifier], 0) AS VARCHAR) AS 'Import Identifier'
                    FROM perror a
                    INNER JOIN apedterr b 
                            ON a.err_code = b.err_code
                    INNER JOIN [imapdtl_vw] c 
                            ON (a.[trx_ctrl_num] = c.[trx_ctrl_num] OR a.[trx_ctrl_num] = c.[source_trx_ctrl_num] OR a.[source_ctrl_num] = c.[source_trx_ctrl_num])
                    WHERE a.module_id = 4000
                            AND c.record_id_num = @imapint01_Errors_sp_record_id_num
                            AND ((a.[sequence_id] = c.[sequence_id]) OR (a.[sequence_id] = -1))
            UNION 
            SELECT CAST(SUBSTRING('[' + CAST(ISNULL(a.[err_code], 0) AS VARCHAR) + ']' + SPACE(43), 1, 45) + ISNULL([e_ldesc], ISNULL(a.[err_code], '')) AS VARCHAR(250)) AS 'Text',
                   c.record_id_num,
                   CAST(ISNULL(c.[Import Identifier], 0) AS VARCHAR) AS 'Import Identifier'
                    FROM perror a
                    INNER JOIN glerrdef b 
                            ON a.err_code = b.e_code
                    INNER JOIN [imapdtl_vw] c 
                            ON (a.[trx_ctrl_num] = c.[trx_ctrl_num] OR a.[trx_ctrl_num] = c.[source_trx_ctrl_num] OR a.[source_ctrl_num] = c.[source_trx_ctrl_num])
                    WHERE a.module_id = 6000
                            AND (b.e_active = 1 OR b.e_active = -1)
                            AND c.record_id_num = @imapint01_Errors_sp_record_id_num
                            AND ((a.[sequence_id] = c.[sequence_id]) OR (a.[sequence_id] = -1))
            END                
        END    
    RETURN 0
Error_Return:
    RETURN -1    
GO
GRANT EXECUTE ON  [dbo].[imapint01_Errors_sp] TO [public]
GO
