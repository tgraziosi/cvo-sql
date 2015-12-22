SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


    CREATE PROC 
[dbo].[imaricust2_sp] @company_code VARCHAR(8),
              @address_type int,
              @trial_flag int,
              @debug_level smallint = 0,
              @imaricust2_sp_Import_Identifier INT,
              @userid INT = 0
    AS  
    DECLARE @added_by_date INT
    DECLARE @buf CHAR(255)
    DECLARE @date_opened INT
    DECLARE @date_processed DATETIME
    DECLARE @errcode INT
    DECLARE @modified_by_date INT
    DECLARE @template_code VARCHAR(8)
    
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
    

    SET @Routine_Name = 'imaricust2_sp'
    SET @Error_Table_Name = 'imcuserr_vw'
    
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
    SET NOCOUNT ON
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
    SELECT @date_processed = getdate()
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @date_processed 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    SELECT @template_code = ISNULL(template_code, 'imarcust')
            FROM arco
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @template_code 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
    --
    -- Validate salesperson_code against arsalesp.salesperson_code.  Where salesperson_code is 
    -- blank, set it to value in artemcus (-32)
    --
    SELECT @errcode = -32
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @errcode 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = @errcode
            FROM #imarcust_vw
            WHERE RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
    UPDATE #imarcust_vw
            SET salesperson_code = b.salesperson_code
            FROM #imarcust_vw a, artemcus b
            WHERE a.salesperson_code = ''
                    AND RTRIM(LTRIM(ISNULL(a.company_code, ''))) = @company_code
                    AND b.template_code = @template_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = 0
            FROM #imarcust_vw
            WHERE DATALENGTH(LTRIM(RTRIM(ISNULL(salesperson_code, '')))) = 0
                    AND processed_flag = @errcode 
                    AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = 0 
            FROM #imarcust_vw a, arsalesp b 
            WHERE a.salesperson_code = b.salesperson_code
                    AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
                    AND processed_flag = @errcode
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 4' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    SET @External_String = @Routine_Name + ' 1' 
    EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = @External_String,
                                                 @IGES_String = @External_String OUT 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' im_get_external_string_sp 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    INSERT INTO imcuserr_vw (company_code, customer_code, ship_to_code , address_type,address_name, short_name, e_value, e_code, e_ldesc, [User_ID]) 
            SELECT RTRIM(LTRIM(ISNULL(company_code, ''))), customer_code, ship_to_code , address_type,address_name, short_name, salesperson_code, processed_flag, @External_String, @userid
                    FROM #imarcust_vw
                    WHERE processed_flag = @errcode
                            AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' imcuserr_vw 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Validate fin_chg_code against arfinchg.fin_chg_code.  Where fin_chg_code is blank, set it to value in artemcus (-33)
    --
    SELECT @errcode = -33
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @errcode 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = @errcode
            FROM #imarcust_vw
            WHERE RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 5' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET fin_chg_code = b.fin_chg_code
            FROM #imarcust_vw a, artemcus b
            WHERE a.fin_chg_code = ''
                    AND RTRIM(LTRIM(ISNULL(a.company_code, ''))) = @company_code
                    AND b.template_code = @template_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 6' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = 0
            FROM #imarcust_vw
            WHERE DATALENGTH(LTRIM(RTRIM(ISNULL(fin_chg_code, '')))) = 0
                    AND processed_flag = @errcode 
                    AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 7' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = 0 
            FROM #imarcust_vw a, arfinchg b 
            WHERE a.fin_chg_code = b.fin_chg_code
                    AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
                    AND processed_flag = @errcode
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 8' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    SET @External_String = @Routine_Name + ' 2' 
    EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = @External_String,
                                                 @IGES_String = @External_String OUT 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' im_get_external_string_sp 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    INSERT INTO imcuserr_vw (company_code, customer_code,ship_to_code , address_type, address_name, short_name, e_value, e_code, e_ldesc, [User_ID]) 
            SELECT RTRIM(LTRIM(ISNULL(company_code, ''))), customer_code, ship_to_code , address_type,address_name, short_name, fin_chg_code, processed_flag, @External_String, @userid
                    FROM #imarcust_vw
                    WHERE processed_flag = @errcode
                            AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' imcuserr_vw 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Validate price_code against arprice.price_code.  Where price_code is blank, set it to value in artemcus (-34)
    --
    SELECT @errcode = -34
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @errcode 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = @errcode
            FROM #imarcust_vw
            WHERE RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 9' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET price_code = b.price_code
            FROM #imarcust_vw a, artemcus b
            WHERE a.price_code = ''
                    AND RTRIM(LTRIM(ISNULL(a.company_code, ''))) = @company_code
                    AND b.template_code = @template_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 10' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = 0
            FROM #imarcust_vw
            WHERE price_code = ''
                    AND processed_flag = @errcode 
                    AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 11' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = 0 
            FROM #imarcust_vw a, arprice b 
            WHERE a.price_code = b.price_code
                    AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
                    AND processed_flag = @errcode
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 12' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    SET @External_String = @Routine_Name + ' 3' 
    EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = @External_String,
                                                 @IGES_String = @External_String OUT 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' im_get_external_string_sp 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    INSERT INTO imcuserr_vw (company_code, customer_code,ship_to_code , address_type, address_name, short_name, e_value, e_code, e_ldesc, [User_ID]) 
            SELECT RTRIM(LTRIM(ISNULL(company_code, ''))), customer_code, ship_to_code , address_type,address_name, short_name, price_code, processed_flag, @External_String, @userid
                    FROM #imarcust_vw
                    WHERE processed_flag = @errcode
                            AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' imcuserr_vw 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Validate payment_code against arpymeth.payment_code.  Where payment_code is blank, set it to value in artemcus (-35)
    --
    SELECT @errcode = -35
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @errcode 4' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = @errcode
            FROM #imarcust_vw
            WHERE RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 13' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET payment_code = b.payment_code
            FROM #imarcust_vw a, artemcus b
            WHERE DATALENGTH(LTRIM(RTRIM(ISNULL(a.payment_code, '')))) = 0
                    AND RTRIM(LTRIM(ISNULL(a.company_code, ''))) = @company_code
                    AND b.template_code = @template_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 14' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = 0
            FROM #imarcust_vw
            WHERE DATALENGTH(LTRIM(RTRIM(ISNULL(payment_code, '')))) = 0
                    AND processed_flag = @errcode 
                    AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 15' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = 0 
            FROM #imarcust_vw a, arpymeth b 
            WHERE a.payment_code = b.payment_code
                    AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
                    AND processed_flag = @errcode
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 16' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    SET @External_String = @Routine_Name + ' 4' 
    EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = @External_String,
                                                 @IGES_String = @External_String OUT 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' im_get_external_string_sp 4' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    INSERT INTO imcuserr_vw (company_code, customer_code,ship_to_code , address_type, address_name, short_name, e_value, e_code, e_ldesc, [User_ID]) 
            SELECT RTRIM(LTRIM(ISNULL(company_code, ''))), customer_code,ship_to_code , address_type,address_name, short_name, payment_code, processed_flag, @External_String, @userid
                    FROM #imarcust_vw
                    WHERE processed_flag = @errcode
                            AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' imcuserr_vw 4' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Validate print_stmt_flag must be 0 or 1.  Where print_stmt_flag is -1, set it to value in artemcus (-40)
    --
    SELECT @errcode = -40
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @errcode 5' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = @errcode
            FROM #imarcust_vw
            WHERE RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
                    AND print_stmt_flag NOT IN (-1,0,1)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 17' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET print_stmt_flag = b.print_stmt_flag
            FROM #imarcust_vw a, artemcus b
            WHERE a.print_stmt_flag = -1
                    AND RTRIM(LTRIM(ISNULL(a.company_code, ''))) = @company_code
                    AND b.template_code = @template_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 18' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    SET @External_String = @Routine_Name + ' 5' 
    EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = @External_String,
                                                 @IGES_String = @External_String OUT 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' im_get_external_string_sp 5' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    INSERT INTO imcuserr_vw (company_code, customer_code,ship_to_code , address_type, address_name, short_name, e_value, e_code, e_ldesc, [User_ID]) 
            SELECT RTRIM(LTRIM(ISNULL(company_code, ''))), customer_code,ship_to_code , address_type, address_name, short_name, CAST(print_stmt_flag AS VARCHAR), processed_flag, @External_String, @userid
                    FROM #imarcust_vw
                    WHERE processed_flag = @errcode
                            AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' imcuserr_vw 5' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Validate stmt_cycle_code against arcycle.stmt_cycle_code.  Where stmt_cycle_code is blank, set it to value in artemcus (-36)
    --
    SELECT @errcode = -36
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @errcode 6' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = @errcode
            FROM #imarcust_vw
            WHERE RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 19' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET stmt_cycle_code = b.stmt_cycle_code
            FROM #imarcust_vw a, artemcus b
            WHERE a.stmt_cycle_code = ''
                    AND RTRIM(LTRIM(ISNULL(a.company_code, ''))) = @company_code
                    AND b.template_code = @template_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 20' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = 0
            FROM #imarcust_vw
            WHERE stmt_cycle_code = ''
                    AND processed_flag = @errcode 
                    AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 21' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = 0 
            FROM #imarcust_vw a, arcycle b 
            WHERE a.stmt_cycle_code = b.cycle_code
                    AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
                    AND processed_flag = @errcode
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 22' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    SET @External_String = @Routine_Name + ' 6' 
    EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = @External_String,
                                                 @IGES_String = @External_String OUT 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' im_get_external_string_sp 6' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    INSERT INTO imcuserr_vw (company_code, customer_code,ship_to_code , address_type, address_name, short_name, e_value, e_code, e_ldesc, [User_ID]) 
            SELECT RTRIM(LTRIM(ISNULL(company_code, ''))), customer_code,ship_to_code , address_type, address_name, short_name, stmt_cycle_code, processed_flag, @External_String, @userid
                    FROM #imarcust_vw
                    WHERE processed_flag = @errcode
                            AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' imcuserr_vw 6' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Validate inv_comment_code against arcommnt.comment_code.  Where inv_comment_code is blank, set it to value in artemcus (-37)
    --
    SELECT @errcode = -37
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @errcode 7' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = @errcode
            FROM #imarcust_vw
            WHERE RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 23' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET inv_comment_code = b.inv_comment_code
            FROM #imarcust_vw a, artemcus b
            WHERE a.inv_comment_code = ''
                    AND RTRIM(LTRIM(ISNULL(a.company_code, ''))) = @company_code
                    AND b.template_code = @template_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 24' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = 0
            FROM #imarcust_vw
            WHERE inv_comment_code = ''
                    AND processed_flag = @errcode 
                    AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 25' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = 0 
            FROM #imarcust_vw a, arcommnt b 
            WHERE a.inv_comment_code = b.comment_code
                    AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
                    AND processed_flag = @errcode
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 26' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    SET @External_String = @Routine_Name + ' 7' 
    EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = @External_String,
                                                 @IGES_String = @External_String OUT 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' im_get_external_string_sp 7' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    INSERT INTO imcuserr_vw (company_code, customer_code,ship_to_code , address_type, address_name, short_name, e_value, e_code, e_ldesc, [User_ID]) 
            SELECT RTRIM(LTRIM(ISNULL(company_code, ''))), customer_code,ship_to_code , address_type, address_name, short_name, inv_comment_code, processed_flag, @External_String, @userid
                    FROM #imarcust_vw
                    WHERE processed_flag = @errcode
                            AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' imcuserr_vw 7' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Validate stmt_comment_code against arcommnt.comment_code.  Where stmt_comment_code is blank, set it to value in artemcus (-38)
    --
    SELECT @errcode = -38
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @errcode 8' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = @errcode
            FROM #imarcust_vw
            WHERE RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 27' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET stmt_comment_code = b.stmt_comment_code
            FROM #imarcust_vw a, artemcus b
            WHERE a.stmt_comment_code = ''
                    AND RTRIM(LTRIM(ISNULL(a.company_code, ''))) = @company_code
                    AND b.template_code = @template_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 28' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = 0
            FROM #imarcust_vw
            WHERE stmt_comment_code = ''
                    AND processed_flag = @errcode 
                    AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 29' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = 0 
            FROM #imarcust_vw a, arcommnt b 
            WHERE a.stmt_comment_code = b.comment_code
                    AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
                    AND processed_flag = @errcode
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 30' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    SET @External_String = @Routine_Name + ' 8' 
    EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = @External_String,
                                                 @IGES_String = @External_String OUT 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' im_get_external_string_sp 8' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    INSERT INTO imcuserr_vw (company_code, customer_code,ship_to_code , address_type, address_name, short_name, e_value, e_code, e_ldesc, [User_ID]) 
            SELECT RTRIM(LTRIM(ISNULL(company_code, ''))), customer_code,ship_to_code , address_type, address_name, short_name, stmt_comment_code, processed_flag, @External_String, @userid
                    FROM #imarcust_vw
                    WHERE processed_flag = @errcode
                        AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' imcuserr_vw 8' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Validate dunn_message_code against ardunn.dunn_message_code.  Where dunn_message_code is blank, set it to value in artemcus (-39)
    --
    SELECT @errcode = -39
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @errcode 9' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = @errcode
            FROM #imarcust_vw
            WHERE RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 31' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET dunn_message_code = b.dunn_message_code
            FROM #imarcust_vw a, artemcus b
            WHERE a.dunn_message_code = ''
                    AND RTRIM(LTRIM(ISNULL(a.company_code, ''))) = @company_code
                    AND b.template_code = @template_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 32' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = 0
            FROM #imarcust_vw
            WHERE dunn_message_code = ''
                    AND processed_flag = @errcode 
                    AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 33' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = 0 
            FROM #imarcust_vw a, ardunn b 
            WHERE a.dunn_message_code = b.dunn_message_code
                    AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
                    AND processed_flag = @errcode
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 34' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    SET @External_String = @Routine_Name + ' 9' 
    EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = @External_String,
                                                 @IGES_String = @External_String OUT 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' im_get_external_string_sp 9' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    INSERT INTO imcuserr_vw (company_code, customer_code,ship_to_code , address_type, address_name, short_name, e_value, e_code, e_ldesc, [User_ID]) 
            SELECT RTRIM(LTRIM(ISNULL(company_code, ''))), customer_code, ship_to_code, address_type, address_name, short_name, dunn_message_code, processed_flag, @External_String, @userid
                    FROM #imarcust_vw
                    WHERE processed_flag = @errcode
                            AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' imcuserr_vw 9' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Where trade_disc_percent is -1, set it to value in artemcus (-54)
    --
    UPDATE #imarcust_vw
            SET trade_disc_percent = b.trade_disc_percent
            FROM #imarcust_vw a, artemcus b
            WHERE a.trade_disc_percent = -1
                    AND RTRIM(LTRIM(ISNULL(a.company_code, ''))) = @company_code
                    AND b.template_code = @template_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 35' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Validate invoice_copies.  If the value is -1, replace the value in the staging table
    -- with that from the artemcus table.  The final value must be 0 or greater (up to 
    -- approximatetly 32000 because the column is a SMALLINT).
    --
    SET @errcode = -54
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @errcode 10' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET invoice_copies = b.invoice_copies
            FROM #imarcust_vw a, artemcus b
            WHERE ISNULL(a.invoice_copies, -1) = -1
                    AND RTRIM(LTRIM(ISNULL(a.company_code, ''))) = @company_code
                    AND b.template_code = @template_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 36' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = @errcode
            FROM #imarcust_vw
            WHERE RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
                    AND (invoice_copies < 0 OR invoice_copies IS NULL)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 37' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    SET @External_String = @Routine_Name + ' 10' 
    EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = @External_String,
                                                 @IGES_String = @External_String OUT 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' im_get_external_string_sp 10' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    INSERT INTO imcuserr_vw (company_code, customer_code,ship_to_code , address_type, address_name, short_name, e_value, e_code, e_ldesc, [User_ID]) 
            SELECT RTRIM(LTRIM(ISNULL(company_code, ''))), customer_code, ship_to_code, address_type, address_name, short_name, CAST(invoice_copies AS VARCHAR), processed_flag, @External_String, @userid
            FROM #imarcust_vw
            WHERE processed_flag = @errcode
                    AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' imcuserr_vw 10' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Validate iv_substitution must be 0 or 1.  Where iv_substitution is -1, set it to 0
    --
    SELECT @errcode = -41
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @errcode 11' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = @errcode
            FROM #imarcust_vw
            WHERE RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
                    AND iv_substitution NOT IN (-1,0,1)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 38' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
           SET iv_substitution = 0
           WHERE iv_substitution = -1
                   AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 39' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    SET @External_String = @Routine_Name + ' 11' 
    EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = @External_String,
                                                 @IGES_String = @External_String OUT 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' im_get_external_string_sp 11' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    INSERT INTO imcuserr_vw (company_code, customer_code,ship_to_code , address_type, address_name, short_name, e_value, e_code, e_ldesc, [User_ID]) 
            SELECT RTRIM(LTRIM(ISNULL(company_code, ''))), customer_code, ship_to_code, address_type, address_name, short_name, CAST(iv_substitution AS VARCHAR), processed_flag, @External_String, @userid
                    FROM #imarcust_vw
                    WHERE processed_flag = @errcode
                            AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' imcuserr_vw 11' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Validate ship_to_history must be 0 or 1.  Where ship_to_history is -1, set it to 0
    --
    SELECT @errcode = -42
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @errcode 12' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = @errcode
            FROM #imarcust_vw
            WHERE RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
                    AND ship_to_history NOT IN (-1,0,1)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 40' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET ship_to_history = 0
            WHERE ship_to_history = -1
                    AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 41' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    SET @External_String = @Routine_Name + ' 12' 
    EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = @External_String,
                                                 @IGES_String = @External_String OUT 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' im_get_external_string_sp 12' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    INSERT INTO imcuserr_vw (company_code, customer_code,ship_to_code , address_type, address_name, short_name, e_value, e_code, e_ldesc, [User_ID]) 
            SELECT RTRIM(LTRIM(ISNULL(company_code, ''))), customer_code, ship_to_code, address_type,address_name, short_name, CAST(ship_to_history AS VARCHAR), processed_flag, @External_String, @userid
                    FROM #imarcust_vw
                    WHERE processed_flag = @errcode
                            AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' imcuserr_vw 12' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Validate check_credit_limit must be 0 or 1.  Where check_credit_limit is -1, set it to value in artemcus (-43)
    --
    SELECT @errcode = -43
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @errcode 13' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = @errcode
            FROM #imarcust_vw
            WHERE RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
                    AND check_credit_limit NOT IN (-1,0,1)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 42' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET check_credit_limit = b.check_credit_limit
            FROM #imarcust_vw a, artemcus b
            WHERE a.check_credit_limit = -1
                    AND RTRIM(LTRIM(ISNULL(a.company_code, ''))) = @company_code
                    AND b.template_code = @template_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 43' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    SET @External_String = @Routine_Name + ' 13' 
    EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = @External_String,
                                                 @IGES_String = @External_String OUT 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' im_get_external_string_sp 13' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    INSERT INTO imcuserr_vw (company_code, customer_code,ship_to_code , address_type, address_name, short_name, e_value, e_code, e_ldesc, [User_ID]) 
            SELECT RTRIM(LTRIM(ISNULL(company_code, ''))), customer_code, ship_to_code, address_type, address_name, short_name, CAST(check_credit_limit AS VARCHAR), processed_flag, @External_String, @userid
                    FROM #imarcust_vw
                    WHERE processed_flag = @errcode
                            AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' imcuserr_vw 13' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- If credit_limit is NULL, set it to value in artemcus
    --
    UPDATE #imarcust_vw
            SET credit_limit = b.credit_limit
            FROM #imarcust_vw a, artemcus b
            WHERE a.credit_limit IS NULL
                    AND RTRIM(LTRIM(ISNULL(a.company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 44' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Validate check_aging_limit must be 0 or 1.  Where check_aging_limit is -1, set it to value in artemcus (-44)
    --
    SELECT @errcode = -44
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @errcode 14' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = @errcode
            FROM #imarcust_vw
            WHERE RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
                    AND check_aging_limit NOT IN (-1,0,1)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 45' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET check_aging_limit = b.check_aging_limit
            FROM #imarcust_vw a, artemcus b
            WHERE a.check_aging_limit = -1
                    AND RTRIM(LTRIM(ISNULL(a.company_code, ''))) = @company_code
                    AND b.template_code = @template_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 46' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    SET @External_String = @Routine_Name + ' 14' 
    EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = @External_String,
                                                 @IGES_String = @External_String OUT 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' im_get_external_string_sp 14' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    INSERT INTO imcuserr_vw (company_code, customer_code,ship_to_code , address_type, address_name, short_name, e_value, e_code, e_ldesc, [User_ID]) 
            SELECT RTRIM(LTRIM(ISNULL(company_code, ''))), customer_code, ship_to_code, address_type,address_name, short_name, CAST(check_aging_limit AS VARCHAR), processed_flag, @External_String, @userid
                    FROM #imarcust_vw
                    WHERE processed_flag = @errcode
                            AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' imcuserr_vw 14' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Validate aging_limit_bracket must be 1,2,3,4,5.  Where aging_limit_bracket is -1, set it to value in artemcus (-45)
    --
    SELECT @errcode = -45
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @errcode 15' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = @errcode
            FROM #imarcust_vw
            WHERE RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
                    AND aging_limit_bracket NOT IN (-1, 1, 2, 3, 4, 5)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 47' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET aging_limit_bracket = b.aging_limit_bracket
            FROM #imarcust_vw a, artemcus b
            WHERE a.aging_limit_bracket = -1
                    AND RTRIM(LTRIM(ISNULL(a.company_code, ''))) = @company_code
                    AND b.template_code = @template_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 48' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    SET @External_String = @Routine_Name + ' 15' 
    EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = @External_String,
                                                 @IGES_String = @External_String OUT 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' im_get_external_string_sp 15' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    INSERT INTO imcuserr_vw (company_code, customer_code,ship_to_code , address_type, address_name, short_name, e_value, e_code, e_ldesc, [User_ID]) 
            SELECT RTRIM(LTRIM(ISNULL(company_code, ''))), customer_code, ship_to_code, address_type, address_name, short_name, CAST(aging_limit_bracket AS VARCHAR), processed_flag, @External_String, @userid
                    FROM #imarcust_vw
                    WHERE processed_flag = @errcode
                            AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' imcuserr_vw 15' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Validate bal_fwd_flag must be 0 or 1.  Where bal_fwd_flag is -1, set it to value in artemcus (-46)
    --
    SELECT @errcode = -46
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @errcode 16' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = @errcode
            FROM #imarcust_vw
            WHERE RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
                    AND bal_fwd_flag NOT IN (-1,0,1)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 49' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET bal_fwd_flag = b.bal_fwd_flag
            FROM #imarcust_vw a, artemcus b
            WHERE a.bal_fwd_flag = -1
                    AND RTRIM(LTRIM(ISNULL(a.company_code, ''))) = @company_code
                    AND b.template_code = @template_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 50' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    SET @External_String = @Routine_Name + ' 16' 
    EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = @External_String,
                                                 @IGES_String = @External_String OUT 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' im_get_external_string_sp 16' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    INSERT INTO imcuserr_vw (company_code, customer_code,ship_to_code , address_type, address_name, short_name, e_value, e_code, e_ldesc, [User_ID]) 
            SELECT RTRIM(LTRIM(ISNULL(company_code, ''))), customer_code, ship_to_code, address_type, address_name, short_name, CAST(bal_fwd_flag AS VARCHAR), processed_flag, @External_String, @userid
                    FROM #imarcust_vw
                    WHERE processed_flag = @errcode
                            AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' imcuserr_vw 16' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Validate ship_complete_flag must be 0 or 1.  Where ship_complete_flag is -1, set it to 0
    --
    SELECT @errcode = -47
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @errcode 17' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = @errcode
            FROM #imarcust_vw
            WHERE RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
                    AND ship_complete_flag NOT IN (-1,0,1)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 51' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
           SET ship_complete_flag = 0
           WHERE ship_complete_flag = -1
                   AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 52' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    SET @External_String = @Routine_Name + ' 17' 
    EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = @External_String,
                                                 @IGES_String = @External_String OUT 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' im_get_external_string_sp 17' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    INSERT INTO imcuserr_vw (company_code, customer_code,ship_to_code , address_type, address_name, short_name, e_value, e_code, e_ldesc, [User_ID]) 
            SELECT RTRIM(LTRIM(ISNULL(company_code, ''))), customer_code, ship_to_code, address_type, address_name, short_name, CAST(ship_complete_flag AS VARCHAR), processed_flag, @External_String, @userid
                    FROM #imarcust_vw
                    WHERE processed_flag = @errcode
                            AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' imcuserr_vw 17' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Validate late_chg_type must be 0 or 1.  Where late_chg_type is -1, set it to value in artemcus (-48)
    --
    SELECT @errcode = -48
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @errcode 18' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = @errcode
            FROM #imarcust_vw
            WHERE RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
                    AND late_chg_type NOT IN (-1,0,1)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 53' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET late_chg_type = b.late_chg_type
            FROM #imarcust_vw a, artemcus b
            WHERE a.late_chg_type = -1
                    AND RTRIM(LTRIM(ISNULL(a.company_code, ''))) = @company_code
                    AND b.template_code = @template_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 54' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    SET @External_String = @Routine_Name + ' 18' 
    EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = @External_String,
                                                 @IGES_String = @External_String OUT 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' im_get_external_string_sp 18' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    INSERT INTO imcuserr_vw (company_code, customer_code,ship_to_code , address_type, address_name, short_name, e_value, e_code, e_ldesc, [User_ID]) 
            SELECT RTRIM(LTRIM(ISNULL(company_code, ''))), customer_code, ship_to_code, address_type, address_name, short_name, CAST(late_chg_type AS VARCHAR), processed_flag, @External_String, @userid
                    FROM #imarcust_vw
                    WHERE processed_flag = @errcode
                            AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' imcuserr_vw 18' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Validate valid_payer_flag must be 0 or 1.  Where valid_payer_flag is -1, set it to 1
    --
    SELECT @errcode = -49
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @errcode 19' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = @errcode
            FROM #imarcust_vw
            WHERE RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
                    AND valid_payer_flag NOT IN (-1,0,1)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 55' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
           SET valid_payer_flag = 1
           WHERE valid_payer_flag = -1
                   AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 56' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    SET @External_String = @Routine_Name + ' 19' 
    EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = @External_String,
                                                 @IGES_String = @External_String OUT 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' im_get_external_string_sp 19' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    INSERT INTO imcuserr_vw (company_code, customer_code,ship_to_code , address_type, address_name, short_name, e_value, e_code, e_ldesc, [User_ID]) 
            SELECT RTRIM(LTRIM(ISNULL(company_code, ''))), customer_code, ship_to_code, address_type, address_name, short_name, CAST(valid_payer_flag AS VARCHAR), processed_flag, @External_String, @userid
                    FROM #imarcust_vw
                    WHERE processed_flag = @errcode
                            AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' imcuserr_vw 19' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Validate valid_soldto_flag must be 0 or 1.  Where valid_soldto_flag is -1, set it to 1
    --
    SELECT @errcode = -50
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @errcode 20' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = @errcode
            FROM #imarcust_vw
            WHERE RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
                    AND valid_soldto_flag NOT IN (-1,0,1)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 57' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
           SET valid_soldto_flag = 1
           WHERE valid_soldto_flag = -1
                   AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 58' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    SET @External_String = @Routine_Name + ' 20' 
    EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = @External_String,
                                                 @IGES_String = @External_String OUT 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' im_get_external_string_sp 20' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    INSERT INTO imcuserr_vw (company_code, customer_code,ship_to_code , address_type, address_name, short_name, e_value, e_code, e_ldesc, [User_ID]) 
            SELECT RTRIM(LTRIM(ISNULL(company_code, ''))), customer_code, ship_to_code, address_type, address_name, short_name, CAST(valid_soldto_flag AS VARCHAR), processed_flag, @External_String, @userid
                    FROM #imarcust_vw
                    WHERE processed_flag = @errcode
                            AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' imcuserr_vw 20' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Validate valid_shipto_flag must be 0 or 1.  Where valid_shipto_flag is -1, set it to 1
    --
    SELECT @errcode = -51
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @errcode 21' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = @errcode
            FROM #imarcust_vw
            WHERE RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
                    AND valid_shipto_flag NOT IN (-1,0,1)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 59' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
           SET valid_shipto_flag = 1
           WHERE valid_shipto_flag = -1
                   AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 60' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    SET @External_String = @Routine_Name + ' 21' 
    EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = @External_String,
                                                 @IGES_String = @External_String OUT 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' im_get_external_string_sp 21' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    INSERT INTO imcuserr_vw (company_code, customer_code,ship_to_code , address_type, address_name, short_name, e_value, e_code, e_ldesc, [User_ID]) 
            SELECT RTRIM(LTRIM(ISNULL(company_code, ''))), customer_code, ship_to_code, address_type, address_name, short_name, CAST(valid_shipto_flag AS VARCHAR), processed_flag, @External_String, @userid
                    FROM #imarcust_vw
                    WHERE processed_flag = @errcode
                            AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' imcuserr_vw 21' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- If payer_soldto_rel_code is blank, set it to value in arco
    --
    UPDATE #imarcust_vw
            SET payer_soldto_rel_code = b.payer_soldto_rel_code
            FROM #imarcust_vw a, arco b
            WHERE a.payer_soldto_rel_code = ''
                    AND RTRIM(LTRIM(ISNULL(a.company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 61' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- If across_na_flag is -1, set it to value in arco
    --
    UPDATE #imarcust_vw
            SET across_na_flag = b.across_na_flag
            FROM #imarcust_vw a, arco b
            WHERE a.across_na_flag = -1
                    AND RTRIM(LTRIM(ISNULL(a.company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 62' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- If added_by_user_name is blank, set it to the value from arco.
    --
    UPDATE #imarcust_vw
            SET added_by_user_name = ISNULL(b.[added_by_user_name], '')
            FROM #imarcust_vw a, arco b
            WHERE DATALENGTH(LTRIM(RTRIM(ISNULL(a.added_by_user_name, '')))) = 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 63' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- If added_by_date is absent, set it to the value from arco.
    --
    UPDATE [#imarcust_vw]
            SET [added_by_date] = SUBSTRING(CONVERT(VARCHAR, CAST(b.[added_by_date] - 693596 AS DATETIME), 120), 1, 10)
            FROM [#imarcust_vw] a, [arco] b
            WHERE DATALENGTH(LTRIM(RTRIM(ISNULL(a.[added_by_date], '')))) = 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 64' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Validate added_by_date.
    --
    SELECT @errcode = -62
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @errcode 22' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = @errcode
            FROM #imarcust_vw
            WHERE NOT ISDATE(added_by_date) = 1
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 65' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    SET @External_String = @Routine_Name + ' 31' 
    EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = @External_String,
                                                 @IGES_String = @External_String OUT 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' im_get_external_string_sp 31' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    INSERT INTO imcuserr_vw (company_code, customer_code,ship_to_code , address_type, address_name, short_name, e_value, e_code, e_ldesc, [User_ID]) 
            SELECT RTRIM(LTRIM(ISNULL(company_code, ''))), customer_code, ship_to_code, address_type, address_name, short_name, CAST(valid_shipto_flag AS VARCHAR), processed_flag, @External_String, @userid
                    FROM #imarcust_vw
                    WHERE processed_flag = @errcode
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' imcuserr_vw 22' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- If modified_by_user_name is blank, set it to the value from arco.
    --
    UPDATE #imarcust_vw
            SET modified_by_user_name = b.modified_by_user_name
            FROM #imarcust_vw a, arco b
            WHERE DATALENGTH(LTRIM(RTRIM(ISNULL(a.modified_by_user_name, '')))) = 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 66' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- If modified_by_date is absent, set it to the value from arco.
    --
    UPDATE #imarcust_vw
            SET modified_by_date = SUBSTRING(CONVERT(VARCHAR, CAST(b.[modified_by_date] - 693596 AS DATETIME), 120), 1, 10)
            FROM #imarcust_vw a, arco b
            WHERE DATALENGTH(LTRIM(RTRIM(ISNULL(a.[modified_by_date], '')))) = 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 67' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Validate modified_by_date.
    --
    SELECT @errcode = -63
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @errcode 23' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = @errcode
            FROM #imarcust_vw
            WHERE NOT ISDATE(added_by_date) = 1
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 68' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    SET @External_String = @Routine_Name + ' 32' 
    EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = @External_String,
                                                 @IGES_String = @External_String OUT 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' im_get_external_string_sp 32' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    INSERT INTO imcuserr_vw (company_code, customer_code,ship_to_code , address_type, address_name, short_name, e_value, e_code, e_ldesc, [User_ID]) 
            SELECT RTRIM(LTRIM(ISNULL(company_code, ''))), customer_code, ship_to_code, address_type, address_name, short_name, CAST(valid_shipto_flag AS VARCHAR), processed_flag, @External_String, @userid
                    FROM #imarcust_vw
                    WHERE processed_flag = @errcode
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' imcuserr_vw 23' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- If date_opened is absent, set it to the system date.
    --
    UPDATE #imarcust_vw
            SET date_opened = SUBSTRING(CONVERT(VARCHAR, GETDATE(), 120), 1, 10)
            FROM #imarcust_vw a, arco b
            WHERE DATALENGTH(LTRIM(RTRIM(ISNULL(a.date_opened, '')))) = 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 69' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Validate date_opened.
    --
    SELECT @errcode = -64
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @errcode 24' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = @errcode
            FROM #imarcust_vw
            WHERE NOT ISDATE(date_opened) = 1
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 70' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    SET @External_String = @Routine_Name + ' 33' 
    EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = @External_String,
                                                 @IGES_String = @External_String OUT 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' im_get_external_string_sp 33' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    INSERT INTO imcuserr_vw (company_code, customer_code, ship_to_code , address_type, address_name, short_name, e_value, e_code, e_ldesc, [User_ID]) 
            SELECT RTRIM(LTRIM(ISNULL(company_code, ''))), customer_code, ship_to_code, address_type, address_name, short_name, CAST(valid_shipto_flag AS VARCHAR), processed_flag, @External_String, @userid
                    FROM #imarcust_vw
                    WHERE processed_flag = @errcode
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' imcuserr_vw 24' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Validate rate_type_home against glrtype_vw.rate_type.  Where rate_type_home is blank, set it to value in artemcus (-55)
    --
    SELECT @errcode = -55
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @errcode 25' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = @errcode
            FROM #imarcust_vw
            WHERE RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 71' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET rate_type_home = b.rate_type_home
            FROM #imarcust_vw a, artemcus b
            WHERE a.rate_type_home = ''
                    AND RTRIM(LTRIM(ISNULL(a.company_code, ''))) = @company_code
                    AND b.template_code = @template_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 72' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = 0
            FROM #imarcust_vw
            WHERE rate_type_home = ''
                    AND processed_flag = @errcode 
                    AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 73' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = 0 
            FROM #imarcust_vw a, glrtype_vw b 
            WHERE a.rate_type_home = b.rate_type
                    AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
                    AND processed_flag = @errcode
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 74' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    SET @External_String = @Routine_Name + ' 22' 
    EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = @External_String,
                                                 @IGES_String = @External_String OUT 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' im_get_external_string_sp 22' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    INSERT INTO imcuserr_vw (company_code, customer_code,ship_to_code , address_type, address_name, short_name, e_value, e_code, e_ldesc, [User_ID]) 
            SELECT RTRIM(LTRIM(ISNULL(company_code, ''))), customer_code, ship_to_code, address_type, address_name, short_name, rate_type_home, processed_flag, @External_String, @userid
                    FROM #imarcust_vw
                    WHERE processed_flag = @errcode
                            AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' imcuserr_vw 25' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Validate rate_type_oper against glrtype_vw.rate_type.  Where rate_type_oper is blank, set it to value in artemcus (-56)
    --
    SELECT @errcode = -56
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @errcode 26' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = @errcode
            FROM #imarcust_vw
            WHERE RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 75' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET rate_type_oper = b.rate_type_oper
            FROM #imarcust_vw a, artemcus b
            WHERE a.rate_type_oper = ''
                    AND RTRIM(LTRIM(ISNULL(a.company_code, ''))) = @company_code
                    AND b.template_code = @template_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 76' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = 0
            FROM #imarcust_vw
            WHERE rate_type_oper = ''
                    AND processed_flag = @errcode 
                    AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 77' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = 0 
            FROM #imarcust_vw a, glrtype_vw b 
            WHERE a.rate_type_oper = b.rate_type
                    AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
                    AND processed_flag = @errcode
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 78' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    SET @External_String = @Routine_Name + ' 23' 
    EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = @External_String,
                                                 @IGES_String = @External_String OUT 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' im_get_external_string_sp 23' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    INSERT INTO imcuserr_vw (company_code, customer_code,ship_to_code , address_type, address_name, short_name, e_value, e_code, e_ldesc, [User_ID]) 
            SELECT RTRIM(LTRIM(ISNULL(company_code, ''))), customer_code, ship_to_code, address_type, address_name, short_name, rate_type_oper, processed_flag, @External_String, @userid
                    FROM #imarcust_vw
                    WHERE processed_flag = @errcode
                            AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' imcuserr_vw 26' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Validate limit_by_home must be 0 or 1.  Where limit_by_home is -1, set it to value in artemcus (-52)
    --
    SELECT @errcode = -52
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @errcode 27' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = @errcode
            FROM #imarcust_vw
            WHERE RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
                    AND limit_by_home NOT IN (-1,0,1)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 79' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET limit_by_home = b.limit_by_home
            FROM #imarcust_vw a, artemcus b
            WHERE a.limit_by_home = -1
                    AND RTRIM(LTRIM(ISNULL(a.company_code, ''))) = @company_code
                    AND b.template_code = @template_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 80' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    SET @External_String = @Routine_Name + ' 24' 
    EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = @External_String,
                                                 @IGES_String = @External_String OUT 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' im_get_external_string_sp 24' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    INSERT INTO imcuserr_vw (company_code, customer_code,ship_to_code , address_type, address_name, short_name, e_value, e_code, e_ldesc, [User_ID]) 
            SELECT RTRIM(LTRIM(ISNULL(company_code, ''))), customer_code, ship_to_code, address_type, address_name, short_name, CAST(limit_by_home AS VARCHAR), processed_flag, @External_String, @userid
                    FROM #imarcust_vw
                    WHERE processed_flag = @errcode
                            AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' imcuserr_vw 27' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Validate nat_cur_code against glcurr_vw.currency_code.  Where nat_cur_code is blank, set it to value in arco (-57)
    --
    SELECT @errcode = -57
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @errcode 28' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = @errcode
            FROM #imarcust_vw
            WHERE RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 81' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET nat_cur_code = b.def_curr_code
            FROM #imarcust_vw a, arco b
            WHERE a.nat_cur_code = ''
                    AND RTRIM(LTRIM(ISNULL(a.company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 82' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = 0
            FROM #imarcust_vw
            WHERE nat_cur_code = ''
                    AND processed_flag = @errcode 
                    AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 83' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = 0 
            FROM #imarcust_vw a, glcurr_vw b 
            WHERE a.nat_cur_code = b.currency_code
                    AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
                    AND processed_flag = @errcode
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 84' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    SET @External_String = @Routine_Name + ' 25' 
    EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = @External_String,
                                                 @IGES_String = @External_String OUT 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' im_get_external_string_sp 25' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    INSERT INTO imcuserr_vw (company_code, customer_code,ship_to_code , address_type, address_name, short_name, e_value, e_code, e_ldesc, [User_ID]) 
            SELECT RTRIM(LTRIM(ISNULL(company_code, ''))), customer_code, ship_to_code, address_type, address_name, short_name, nat_cur_code, processed_flag, @External_String, @userid
                    FROM #imarcust_vw
                    WHERE processed_flag = @errcode
                            AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' imcuserr_vw 28' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Validate one_cur_cust must be 0 or 1.  Where one_cur_cust is -1, set it to value in artemcus (-53)
    --
    SELECT @errcode = -53
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @errcode 29' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = @errcode
            FROM #imarcust_vw
            WHERE RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
                    AND one_cur_cust NOT IN (-1,0,1)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 85' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET one_cur_cust = b.one_cur_cust
            FROM #imarcust_vw a, artemcus b
            WHERE a.one_cur_cust = -1
                    AND RTRIM(LTRIM(ISNULL(a.company_code, ''))) = @company_code
                    AND b.template_code = @template_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 86' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    SET @External_String = @Routine_Name + ' 26' 
    EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = @External_String,
                                                 @IGES_String = @External_String OUT 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' im_get_external_string_sp 26' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    INSERT INTO imcuserr_vw (company_code, customer_code, ship_to_code , address_type,address_name, short_name, e_value, e_code, e_ldesc, [User_ID]) 
            SELECT RTRIM(LTRIM(ISNULL(company_code, ''))), customer_code, ship_to_code, address_type, address_name, short_name, CAST(one_cur_cust AS VARCHAR), processed_flag, @External_String, @userid
                    FROM #imarcust_vw
                    WHERE processed_flag = @errcode
                            AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' imcuserr_vw 29' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Validate remit_code against arremit.kys.  Where remit_code is blank, set it to value in artemcus (-58)
    --
    SELECT @errcode = -58
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @errcode 30' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = @errcode
            FROM #imarcust_vw
            WHERE RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 87' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET remit_code = b.remit_code
            FROM #imarcust_vw a, artemcus b
            WHERE a.remit_code = ''
                    AND RTRIM(LTRIM(ISNULL(a.company_code, ''))) = @company_code
                    AND b.template_code = @template_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 88' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = 0
            FROM #imarcust_vw
            WHERE remit_code = ''
                    AND processed_flag = @errcode 
                    AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 89' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = 0 
            FROM #imarcust_vw a, arremit b 
            WHERE a.remit_code = b.kys
                    AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
                    AND processed_flag = @errcode
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 90' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    SET @External_String = @Routine_Name + ' 27' 
    EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = @External_String,
                                                 @IGES_String = @External_String OUT 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' im_get_external_string_sp 27' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    INSERT INTO imcuserr_vw (company_code, customer_code,ship_to_code , address_type, address_name, short_name, e_value, e_code, e_ldesc, [User_ID]) 
            SELECT RTRIM(LTRIM(ISNULL(company_code, ''))), customer_code, ship_to_code, address_type,address_name, short_name, remit_code, processed_flag, @External_String, @userid
                    FROM #imarcust_vw
                    WHERE processed_flag = @errcode
                            AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' imcuserr_vw 30' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Validate forwarder_code against arfwdr.kys.  Where forwarder_code is blank, set it to value in artemcus (-59)
    --
    SELECT @errcode = -59
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @errcode 31' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = @errcode
            FROM #imarcust_vw
            WHERE RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 91' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET forwarder_code = b.forwarder_code
            FROM #imarcust_vw a, artemcus b
            WHERE a.forwarder_code = ''
                    AND RTRIM(LTRIM(ISNULL(a.company_code, ''))) = @company_code
                    AND b.template_code = @template_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 92' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = 0
            FROM #imarcust_vw
            WHERE forwarder_code = ''
                    AND processed_flag = @errcode 
                    AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 93' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = 0 
            FROM #imarcust_vw a, arfwdr b 
            WHERE a.forwarder_code = b.kys
                    AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
                    AND processed_flag = @errcode
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 94' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    SET @External_String = @Routine_Name + ' 28' 
    EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = @External_String,
                                                 @IGES_String = @External_String OUT 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' im_get_external_string_sp 28' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    INSERT INTO imcuserr_vw (company_code, customer_code,ship_to_code , address_type, address_name, short_name, e_value, e_code, e_ldesc, [User_ID]) 
            SELECT RTRIM(LTRIM(ISNULL(company_code, ''))), customer_code, ship_to_code, address_type,address_name, short_name, forwarder_code, processed_flag, @External_String, @userid
                    FROM #imarcust_vw
                    WHERE processed_flag = @errcode
                            AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' imcuserr_vw 31' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Validate freight_to_code against arfrt_to.kys.  Where freight_to_code is blank, set it to value in artemcus (-60)
    --
    SELECT @errcode = -60
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @errcode 32' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = @errcode
            FROM #imarcust_vw
            WHERE RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 95' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET freight_to_code = b.freight_to_code
            FROM #imarcust_vw a, artemcus b
            WHERE a.freight_to_code = ''
                    AND RTRIM(LTRIM(ISNULL(a.company_code, ''))) = @company_code
                    AND b.template_code = @template_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 96' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = 0
            FROM #imarcust_vw
            WHERE freight_to_code = ''
                    AND processed_flag = @errcode 
                    AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 97' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = 0 
            FROM #imarcust_vw a, arfrt_to b 
            WHERE a.freight_to_code = b.kys
                    AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
                    AND processed_flag = @errcode
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 98' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    SET @External_String = @Routine_Name + ' 29' 
    EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = @External_String,
                                                 @IGES_String = @External_String OUT 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' im_get_external_string_sp 29' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    INSERT INTO imcuserr_vw (company_code, customer_code,ship_to_code , address_type, address_name, short_name, e_value, e_code, e_ldesc, [User_ID]) 
            SELECT RTRIM(LTRIM(ISNULL(company_code, ''))), customer_code, ship_to_code, address_type,address_name, short_name, freight_to_code, processed_flag, @External_String, @userid
                    FROM #imarcust_vw
                    WHERE processed_flag = @errcode
                            AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' imcuserr_vw 32' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Validate ship_via_code against arshipv.ship_via_code.  Where ship_via_code is blank, set it to value in artemcus (-61)
    --
    SELECT @errcode = -61
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @errcode 33' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = @errcode
            FROM #imarcust_vw
            WHERE RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 99' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET ship_via_code = b.ship_via_code
            FROM #imarcust_vw a, artemcus b
            WHERE a.ship_via_code = ''
                    AND RTRIM(LTRIM(ISNULL(a.company_code, ''))) = @company_code
                    AND b.template_code = @template_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 100' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = 0
            FROM #imarcust_vw
            WHERE ship_via_code = ''
                    AND processed_flag = @errcode 
                    AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 101' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = 0 
            FROM #imarcust_vw a, arshipv b 
            WHERE a.ship_via_code = b.ship_via_code
                    AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
                    AND processed_flag = @errcode
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 102' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    SET @External_String = @Routine_Name + ' 30' 
    EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = @External_String,
                                                 @IGES_String = @External_String OUT 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' im_get_external_string_sp 30' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    INSERT INTO imcuserr_vw (company_code, customer_code,ship_to_code , address_type, address_name, short_name, e_value, e_code, e_ldesc, [User_ID]) 
            SELECT RTRIM(LTRIM(ISNULL(company_code, ''))), customer_code, ship_to_code, address_type,address_name, short_name, ship_via_code, processed_flag, @External_String, @userid
                    FROM #imarcust_vw
                    WHERE processed_flag = @errcode
                            AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' imcuserr_vw 33' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

   


    SELECT @errcode = -63
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @errcode 34' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = @errcode
            FROM #imarcust_vw
            WHERE RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 103' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET writeoff_code = b.writeoff_code
            FROM #imarcust_vw a, artemcus b
            WHERE RTRIM(LTRIM(ISNULL(a.writeoff_code, ''))) = ''
                    AND RTRIM(LTRIM(ISNULL(a.company_code, ''))) = @company_code
                    AND b.template_code = @template_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 104' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #imarcust_vw
            SET processed_flag = 0 
            FROM #imarcust_vw a, arwrofac b 
            WHERE a.writeoff_code = b.writeoff_code
                    AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
                    AND processed_flag = @errcode
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 106' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

    SET @External_String = @Routine_Name + ' 34' 
    EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = @External_String,
                                                 @IGES_String = @External_String OUT 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' im_get_external_string_sp 34' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    INSERT INTO imcuserr_vw (company_code, customer_code,ship_to_code , address_type, address_name, short_name, e_value, e_code, e_ldesc, [User_ID]) 
            SELECT RTRIM(LTRIM(ISNULL(company_code, ''))), customer_code, ship_to_code, address_type,address_name, short_name, ship_via_code, processed_flag, @External_String, @userid
                    FROM #imarcust_vw
                    WHERE processed_flag = @errcode
                            AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' imcuserr_vw 34' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END   


    --
    -- Wrap up the import:
    --     * Update the permanent staging table setting processed_flag to 2 for all invalid records.
    --     * For a "Final" import, copy the records from the permanent staging table
    --       that have a matching company code and a processed_flag value of 0.
    --     * Update the permanent staging table setting processed_flag to 1 for all valid records.
    -- 
    -- Set error flags for all invalid records (those that exist in imcuserr_vw).
    -- Note that at this point the temporary version of the staging table is no
    -- longer used since the error information is contained in imcuserr_vw.
    --
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': Setting processed_flag = 2 for invalid records.'
    UPDATE imarcust_vw
            SET [processed_flag] = 2
            FROM [imarcust_vw] a, [imcuserr_vw] b
            WHERE a.[customer_code] = b.[customer_code]
                    AND a.[ship_to_code] =  b.[ship_to_code]
                    AND RTRIM(LTRIM(ISNULL(a.[company_code], ''))) = b.company_code
                    AND RTRIM(LTRIM(ISNULL(b.[company_code], ''))) = @company_code
                    AND (NOT a.[processed_flag] = 1 OR a.[processed_flag] IS NULL)
                    AND a.[address_type] = @address_type
                    AND (a.[User_ID] = @userid OR @userid = 0)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imarcust_vw 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Update the processed_flag for the benefit of the im#imarcust table which in turn
    -- is used by the alternate style Crystal report to indicate valid "yes" or "no". 
    --
    UPDATE [#imarcust_vw]
            SET [processed_flag] = 2
            FROM [#imarcust_vw] a, [imcuserr_vw] b
            WHERE a.[customer_code] = b.[customer_code]
                    AND a.[ship_to_code] =  b.[ship_to_code]
                    AND RTRIM(LTRIM(ISNULL(a.[company_code], ''))) = b.company_code
                    AND RTRIM(LTRIM(ISNULL(b.[company_code], ''))) = @company_code
                    AND (NOT a.[processed_flag] = 1 OR a.[processed_flag] IS NULL)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarcust_vw 103' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Copy records to the im# tables.
    --
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': Copy records to the im# tables'
    INSERT INTO [CVO_Control]..im#imarcust 
            ([Import Identifier], [Import Company],        [Import Date],
             company_code,        customer_code,           ship_to_code,
             address_name,        short_name,              addr1,
             addr2,               addr3,                   addr4,
             addr5,               addr6,                   addr_sort1,
             addr_sort2,          addr_sort3,              address_type,
             status_type,         attention_name,          attention_phone,
             contact_name,        contact_phone,           tlx_twx,
             phone_1,             phone_2,                 tax_code,
             terms_code,          fob_code,                freight_code,
             posting_code,        location_code,           alt_location_code,
             dest_zone_code,      territory_code,          salesperson_code,
             fin_chg_code,        price_code,              payment_code,
             vendor_code,         affiliated_cust_code,    print_stmt_flag,
             stmt_cycle_code,     inv_comment_code,        stmt_comment_code,
             dunn_message_code,   note,                    trade_disc_percent,
             invoice_copies,      iv_substitution,         ship_to_history,
             check_credit_limit,  credit_limit,            check_aging_limit,
             aging_limit_bracket, bal_fwd_flag,            ship_complete_flag,
             resale_num,          db_num,                  db_date,
             db_credit_rating,    late_chg_type,           valid_payer_flag,
             valid_soldto_flag,   valid_shipto_flag,       payer_soldto_rel_code,
             across_na_flag,      date_opened,             added_by_user_name,
             added_by_date,       modified_by_user_name,   modified_by_date,
             rate_type_home,      rate_type_oper,          limit_by_home,
             nat_cur_code,        one_cur_cust,            city,
             state,               postal_code,             country,
             remit_code,          forwarder_code,          freight_to_code,
             route_code,          route_no,                url,
             special_instr,       guid,                    price_level,
             ship_via_code,       processed_flag,          date_processed,
             [batch_no],          [record_id_num],         [User_ID],
             [contact_email],     [attention_email],       [ftp],
             [dunning_group_id],  [consolidated_invoices], [writeoff_code])
            SELECT @imaricust2_sp_Import_Identifier, @company_code,           GETDATE(),
                   company_code,                     customer_code,           ship_to_code,
                   address_name,                     short_name,              addr1,
                   addr2,                            addr3,                   addr4,
                   addr5,                            addr6,                   addr_sort1,
                   addr_sort2,                       addr_sort3,              address_type,
                   status_type,                      attention_name,          attention_phone,
                   contact_name,                     contact_phone,           tlx_twx,
                   phone_1,                          phone_2,                 tax_code,
                   terms_code,                       fob_code,                freight_code,
                   posting_code,                     location_code,           alt_location_code,
                   dest_zone_code,                   territory_code,          salesperson_code,
                   fin_chg_code,                     price_code,              payment_code,
                   vendor_code,                      affiliated_cust_code,    print_stmt_flag,
                   stmt_cycle_code,                  inv_comment_code,        stmt_comment_code,
                   dunn_message_code,                note,                    trade_disc_percent,
                   invoice_copies,                   iv_substitution,         ship_to_history,
                   check_credit_limit,               credit_limit,            check_aging_limit,
                   aging_limit_bracket,              bal_fwd_flag,            ship_complete_flag,
                   resale_num,                       db_num,                  db_date,
                   db_credit_rating,                 late_chg_type,           valid_payer_flag,
                   valid_soldto_flag,                valid_shipto_flag,       payer_soldto_rel_code,
                   across_na_flag,                   @date_opened,            added_by_user_name,
                   @added_by_date,                   modified_by_user_name,   @modified_by_date,
                   rate_type_home,                   rate_type_oper,          limit_by_home,
                   nat_cur_code,                     one_cur_cust,            city,
                   state,                            postal_code,             country,
                   remit_code,                       forwarder_code,          freight_to_code,
                   route_code,                       route_no,                url,
                   special_instr,                    guid,                    price_level,
                   ship_via_code,                    processed_flag,          date_processed,
                   [batch_no],                       [record_id_num],         [User_ID],
                   [contact_email],                  [attention_email],       [ftp],
                   [dunning_group_id],               [consolidated_invoices], [writeoff_code]
                    FROM #imarcust_vw
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' [CVO_Control]..im#imarcust 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- For a "Final" import (@trial_flag = 0), insert records into armaster.
    --
    IF @trial_flag = 0
        BEGIN
        IF @debug_level >= 3
            SELECT '(3): ' + @Routine_Name + ': Final import: Inserting records into [armaster].'
        --
        -- Update armaster.  If we are adding a ship-to then many of the fields are NULL.
        --
        IF (@address_type = 0)
            BEGIN
            INSERT INTO armaster (customer_code,         ship_to_code,            address_name,
                                  short_name,            addr1,                   addr2,
                                  addr3,                 addr4,                   addr5,
                                  addr6,                 addr_sort1,              addr_sort2,
                                  addr_sort3,            address_type,            status_type,
                                  attention_name,        attention_phone,         contact_name,
                                  contact_phone,         tlx_twx,                 phone_1,
                                  phone_2,               tax_code,                terms_code,
                                  fob_code,              freight_code,            posting_code,
                                  location_code,         alt_location_code,       dest_zone_code,
                                  territory_code,        salesperson_code,        fin_chg_code,
                                  price_code,            payment_code,            vendor_code,
                                  affiliated_cust_code,  print_stmt_flag,         stmt_cycle_code,
                                  inv_comment_code,      stmt_comment_code,       dunn_message_code,
                                  note,                  trade_disc_percent,      invoice_copies,
                                  iv_substitution,       ship_to_history,         check_credit_limit,
                                  credit_limit,          check_aging_limit,       aging_limit_bracket,
                                  bal_fwd_flag,          ship_complete_flag,      resale_num,
                                  db_num,                db_date,                 db_credit_rating,
                                  late_chg_type,         valid_payer_flag,        valid_soldto_flag,
                                  valid_shipto_flag,     payer_soldto_rel_code,   across_na_flag,
                                  date_opened,           added_by_user_name,      added_by_date,
                                  modified_by_user_name, modified_by_date,        rate_type_home,
                                  rate_type_oper,        limit_by_home,           nat_cur_code,
                                  one_cur_cust,          city,                    state,
                                  postal_code,           country_code,            remit_code,
                                  forwarder_code,        freight_to_code,         route_code,
                                  route_no,              url,                     special_instr,
                                  guid,                  price_level,             ship_via_code,
                                  [contact_email],       [attention_email],       [ftp],
                                  [dunning_group_id],    [consolidated_invoices], [writeoff_code])
                    SELECT customer_code,         ship_to_code,             address_name,
                           short_name,            addr1,                    addr2,
                           addr3,                 addr4,                    addr5,
                           addr6,                 addr_sort1,               addr_sort2,
                           addr_sort3,            address_type,             status_type,
                           attention_name,        attention_phone,          contact_name,
                           contact_phone,         tlx_twx,                  phone_1,
                           phone_2,               tax_code,                 terms_code,
                           fob_code,              freight_code,             posting_code,
                           location_code,         alt_location_code,        dest_zone_code,
                           territory_code,        salesperson_code,         fin_chg_code,
                           price_code,            payment_code,             vendor_code,
                           affiliated_cust_code,  print_stmt_flag,          stmt_cycle_code,
                           inv_comment_code,      stmt_comment_code,        dunn_message_code,
                           note,                  trade_disc_percent,       invoice_copies,
                           iv_substitution,       ship_to_history,          check_credit_limit,
                           credit_limit,          check_aging_limit,        aging_limit_bracket,
                           bal_fwd_flag,          ship_complete_flag,       resale_num,
                           db_num,                db_date,                  db_credit_rating,
                           late_chg_type,         valid_payer_flag,         valid_soldto_flag,
                           valid_shipto_flag,     payer_soldto_rel_code,    across_na_flag,
                           DATEDIFF(DD, '1/1/1753', @date_opened) + 639906, added_by_user_name, DATEDIFF(DD, '1/1/1753', @added_by_date) + 639906,
                           modified_by_user_name, DATEDIFF(DD, '1/1/1753', @modified_by_date) + 639906, rate_type_home,
                           rate_type_oper,        limit_by_home,            nat_cur_code,
                           one_cur_cust,          city,                     state,
                           postal_code,           country,                  remit_code,
                           forwarder_code,        freight_to_code,          route_code,
                           route_no,              url,                      special_instr,
                           guid,                  price_level,              ship_via_code,
                           [contact_email],       [attention_email],        [ftp],
                           [dunning_group_id],    [consolidated_invoices],  [writeoff_code]
                            FROM [#imarcust_vw]
                            WHERE RTRIM(LTRIM(ISNULL([company_code], ''))) = @company_code
                                    AND ([processed_flag] = 0 OR [processed_flag] IS NULL)
                                    AND [address_type] = @address_type
                                    AND ([User_ID] = @userid OR @userid = 0)
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' armaster 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            END
        ELSE
            BEGIN
            INSERT INTO armaster (customer_code,         ship_to_code,            address_name,
                                  short_name,            addr1,                   addr2,
                                  addr3,                 addr4,                   addr5,
                                  addr6,                 addr_sort1,              addr_sort2,
                                  addr_sort3,            address_type,            status_type,
                                  attention_name,        attention_phone,         contact_name,
                                  contact_phone,         tlx_twx,                 phone_1,
                                  phone_2,               tax_code,                terms_code,
                                  fob_code,              freight_code,            posting_code,
                                  location_code,         alt_location_code,       dest_zone_code,
                                  territory_code,        salesperson_code,        fin_chg_code,
                                  price_code,            payment_code,            vendor_code,
                                  affiliated_cust_code,  print_stmt_flag,         stmt_cycle_code,
                                  inv_comment_code,      stmt_comment_code,       dunn_message_code,
                                  note,                  trade_disc_percent,      invoice_copies,
                                  iv_substitution,       ship_to_history,         check_credit_limit,
                                  credit_limit,          check_aging_limit,       aging_limit_bracket,
                                  bal_fwd_flag,          ship_complete_flag,      resale_num,
                                  db_num,                db_date,                 db_credit_rating,
                                  late_chg_type,         valid_payer_flag,        valid_soldto_flag,
                                  valid_shipto_flag,     payer_soldto_rel_code,   across_na_flag,
                                  date_opened,           added_by_user_name,      added_by_date,
                                  modified_by_user_name, modified_by_date,        rate_type_home,
                                  rate_type_oper,        limit_by_home,           nat_cur_code,
                                  one_cur_cust,          city,                    state,
                                  postal_code,           country_code,            remit_code,
                                  forwarder_code,        freight_to_code,         route_code,
                                  route_no,              url,                     special_instr,
                                  guid,                  price_level,             ship_via_code,
                                  [contact_email],       [attention_email],       [ftp],
                                  [dunning_group_id],    [consolidated_invoices], [writeoff_code])
                    SELECT customer_code,         ship_to_code,            address_name,
                           short_name,            addr1,                   addr2,
                           addr3,                 addr4,                   addr5,
                           addr6,                 addr_sort1,              addr_sort2,
                           addr_sort3,            address_type,            status_type,
                           attention_name,        attention_phone,         contact_name,
                           contact_phone,         tlx_twx,                 phone_1,
                           phone_2,               tax_code,                terms_code,
                           fob_code,              freight_code,            posting_code,
                           location_code,         alt_location_code,       dest_zone_code,
                           territory_code,        salesperson_code,        NULL,
                           NULL,                  NULL,                    NULL,
                           NULL,                  NULL,                    NULL,
                           NULL,                  NULL,                    NULL,
                           note,                  NULL,                    NULL,
                           NULL,                  NULL,                    NULL,
                           NULL,                  NULL,                    NULL,
                           NULL,                  NULL,                    NULL,
                           NULL,                  NULL,                    NULL,
                           NULL,                  NULL,                    NULL,
                           NULL,                  NULL,                    NULL,
                           NULL,                  added_by_user_name, DATEDIFF(DD, '1/1/1753', @added_by_date) + 639906,
                           modified_by_user_name, DATEDIFF(DD, '1/1/1753', @modified_by_date) + 639906, rate_type_home,
                           rate_type_oper,        NULL,                    nat_cur_code,
                           one_cur_cust,          city,                    state,
                           postal_code,           country,                 remit_code,
                           forwarder_code,        freight_to_code,         route_code,
                           route_no,              url,                     special_instr,
                           guid,                  price_level,             ship_via_code,
                           [contact_email],       [attention_email],       [ftp],
                           [dunning_group_id],    [consolidated_invoices], [writeoff_code]
                            FROM [#imarcust_vw]
                            WHERE RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
                                    AND ([processed_flag] = 0 OR [processed_flag] IS NULL)
                                    AND address_type = @address_type
                                    AND ([User_ID] = @userid OR @userid = 0)
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' armaster 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            END                                                    
        --
        -- Finally, update the permanent staging table setting processed_flag to 1 
        -- for all valid records.
        --    
        IF @debug_level >= 3
            SELECT '(3): ' + @Routine_Name + ': Setting processed_flag = 1 for valid records.'
        UPDATE [CVO_Control]..[imarcust]
                SET [date_processed] = @date_processed,
                    [processed_flag] = 1
                WHERE RTRIM(LTRIM(ISNULL([CVO_Control]..imarcust.company_code, ''))) = @company_code
                        AND ([CVO_Control]..[imarcust].[processed_flag] = 0 OR [CVO_Control]..[imarcust].[processed_flag] IS NULL)
                        AND [address_type] = @address_type
                        AND (NOT [processed_flag] = 1 OR [processed_flag] IS NULL)
                        AND ([User_ID] = @userid OR @userid = 0)
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' [CVO_Control]..imarcust 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        END
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': Exit.'
    RETURN 0
Error_Return:
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': Exit (ERROR).'
    RETURN -1    
GO
GRANT EXECUTE ON  [dbo].[imaricust2_sp] TO [public]
GO
