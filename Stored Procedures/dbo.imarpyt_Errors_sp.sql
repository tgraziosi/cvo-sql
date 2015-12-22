SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

    
    CREATE PROC
[dbo].[imarpyt_Errors_sp] (@imarpyt_Errors_sp_Dummy_1 VARCHAR(128) = '',
                   @imarpyt_Errors_sp_Table_Indicator VARCHAR(128) = '',
                   @imarpyt_Errors_sp_Dummy_2 VARCHAR(128) = '',
                   @imarpyt_Errors_sp_record_id_num INT = -1,
                   @imarpyt_Errors_sp_Dummy_3 INT = 0,
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
    

    SET @Routine_Name = 'imarpyt_Errors_sp'        
    --
    -- Obtain company_code
    --
    SELECT @company_code = LTRIM(RTRIM(ISNULL([company_code], '')))
        FROM [glco]
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @company_code 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END   
    --
    -- Obtain error messages for the specified record, or all records in all companies
    -- if record_id_num is -1.
    --     
    IF @imarpyt_Errors_sp_record_id_num = -1
        BEGIN
        SELECT CAST(SUBSTRING('[' + CAST(ISNULL([e_code], 0) AS VARCHAR) + ']' + SPACE(43), 1, 45) + ISNULL([e_ldesc], ISNULL(e_code, '')) AS VARCHAR(250)) AS 'Text',
               [CVO_Control]..[imarpyt].record_id_num,
               CAST(ISNULL([CVO_Control]..[imarpyt].[Import Identifier], 0) AS VARCHAR) AS 'Import Identifier',
               [CVO_Control]..[imarpyt].[company_code],
               [CVO_Control]..[imcsherr].[doc_ctrl_num], -- For alternate style import report
               [CVO_Control]..[imcsherr].[sequence_id], -- For alternate style import report
               [CVO_Control]..[imcsherr].[customer_code], -- For alternate style import report
               [CVO_Control]..[imcsherr].[e_value], -- For alternate style import report
               [CVO_Control]..[imcsherr].[e_code], -- For alternate style import report
               [CVO_Control]..[imcsherr].[e_ldesc] -- For alternate style import report
                FROM [CVO_Control]..[imcsherr]
                INNER JOIN [CVO_Control]..[imarpyt] 
                        ON [CVO_Control]..[imcsherr].[company_code] = [CVO_Control]..[imarpyt].[company_code]
                                AND [CVO_Control]..[imcsherr].[doc_ctrl_num] = [CVO_Control]..[imarpyt].[doc_ctrl_num]
                                AND [CVO_Control]..[imcsherr].[customer_code] = [CVO_Control]..[imarpyt].[customer_code]
                WHERE ([CVO_Control]..[imarpyt].[User_ID] = @userid OR @userid = 0)        
                ORDER BY [CVO_Control]..[imarpyt].[company_code], [record_id_num]                
        END
    ELSE
        BEGIN  
        IF UPPER(@imarpyt_Errors_sp_Table_Indicator) = 'H'
            BEGIN          
            SELECT CAST(SUBSTRING('[' + CAST(ISNULL([e_code], 0) AS VARCHAR) + ']' + SPACE(43), 1, 45) + ISNULL([e_ldesc], ISNULL(e_code, '')) AS VARCHAR(250)) AS 'Text',
                   [imarpyt_vw].record_id_num,
                   CAST(ISNULL([imarpyt_vw].[Import Identifier], 0) AS VARCHAR) AS 'Import Identifier'
                    FROM imcsherr_vw
                    INNER JOIN [imarpyt_vw] 
                            ON [imcsherr_vw].[company_code] = [imarpyt_vw].[company_code]
                                    AND [imcsherr_vw].[doc_ctrl_num] = [imarpyt_vw].[doc_ctrl_num]
                                    AND [imcsherr_vw].[customer_code] = [imarpyt_vw].[customer_code]
                    WHERE LTRIM(RTRIM([imarpyt_vw].[company_code])) = @company_code 
                            AND [imarpyt_vw].[record_id_num] = @imarpyt_Errors_sp_record_id_num
                            AND ([imcsherr_vw].[sequence_id] = 0 OR [imcsherr_vw].[sequence_id] IS NULL)
            END
        IF UPPER(@imarpyt_Errors_sp_Table_Indicator) = 'D'
            BEGIN          
            SELECT CAST(SUBSTRING('[' + CAST(ISNULL([e_code], 0) AS VARCHAR) + ']' + SPACE(43), 1, 45) + ISNULL([e_ldesc], ISNULL(e_code, '')) AS VARCHAR(250)) AS 'Text',
                   [imarpdt_vw].record_id_num,
                   CAST(ISNULL([imarpdt_vw].[Import Identifier], 0) AS VARCHAR) AS 'Import Identifier'
                    FROM [imcsherr_vw]
                    INNER JOIN [imarpdt_vw] 
                            ON [imcsherr_vw].[company_code] = [imarpdt_vw].[company_code]
                                    AND [imcsherr_vw].[doc_ctrl_num] = [imarpdt_vw].[doc_ctrl_num]
                                    AND [imcsherr_vw].[customer_code] = [imarpdt_vw].[customer_code]
                    WHERE LTRIM(RTRIM([imarpdt_vw].[company_code])) = @company_code 
                            AND [imarpdt_vw].[record_id_num] = @imarpyt_Errors_sp_record_id_num
                            AND (([imcsherr_vw].[sequence_id] = [imarpdt_vw].[sequence_id]) OR ([imcsherr_vw].[sequence_id] = -1))
            END                
        END                
    RETURN 0
Error_Return:
    RETURN -1    
GO
GRANT EXECUTE ON  [dbo].[imarpyt_Errors_sp] TO [public]
GO
