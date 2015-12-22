SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


    CREATE PROC 
[dbo].[immakcr_sp] @company_code VARCHAR(8),
           @debug_level smallint = 0,
           @immakcr_sp_Process_User_ID INT = 0,
           @trial_flag INT,
           @immakcr_sp_Import_Identifier INT,
           @userid INT = 0,
           @immakcr_sp_User_Name VARCHAR(30) = ''
    AS  
    DECLARE @updateflag    smallint,
            @buf        char(255),
            @result        int,
            @precision_gl    smallint,
            @date_processed datetime,
            @rowcount    int,
            @masked        char(16),
            @num        int,
            @errcode    int,
            @process_description     varchar(40), 
            @process_ctrl_num    char(16),
            @process_parent_app     smallint, 
            @next_dcn    char(16),
            @date_entered    int,
            @next_customer    char(8),
            @on_acct_flag    smallint,
            @trx_ctrl_num   varchar(16),
            @doc_ctrl_num    char(16),
            @trx_desc    char(40),
            @cash_acct_code    char(32),
            @date_applied    int,
            @date_doc    int,
            @customer_code    char(8),
            @payment_code    char(8),
            @payment_type    smallint,
            @amt_on_account    float,
            @amt_payment    float,
            @amt_discount    float,
            @nat_cur_code    char(8),
            @rate_type_home    char(8),
            @rate_type_oper    char(8),
            @rate_home    float,
            @rate_oper    float,
            @next_custatn        char(24),
            @amt_applied        float,
            @amt_disc_taken        float,
            @amt_net        float,
            @amt_overcharge        float,
            @next_date_applied    int,
            @sequence_id        int,
            @next_batch_code    char(16),
            @complete_date        int,
            @complete_time        int,
            @complete_user        char(30),
            @batch_count        int,
            @batch_total        float,
            @divide_flag_h    smallint,
            @divide_flag_o    smallint,
            @home_currency    varchar(8),
            @oper_currency    varchar(8)
    DECLARE @im_config_batch_description VARCHAR(30)
    DECLARE @stl_ctrl_num VARCHAR(16)        
    DECLARE @Using_Settlements VARCHAR(3)
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
    

    SET @Routine_Name = 'immakcr_sp'   
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': Entry.'     
    
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

    --
    SET @Using_Settlements = 'YES'
    SELECT @Using_Settlements = UPPER([Text Value])
            FROM [CVO_Control]..[im_config] 
            WHERE UPPER([Item Name]) = 'USING SETTLEMENTS'
    IF @@ROWCOUNT = 0
            OR @Using_Settlements IS NULL
            OR (NOT @Using_Settlements = 'NO' AND NOT @Using_Settlements = 'YES' AND NOT @Using_Settlements = 'TRUE' AND NOT @Using_Settlements = 'FALSE')
        SET @Using_Settlements = 'YES'
    IF @Using_Settlements = 'FALSE'
        SET @Using_Settlements = 'NO'
    --
    SELECT @im_config_batch_description = RTRIM(LTRIM(ISNULL(UPPER(ISNULL([Text Value], 'Import Manager Batch')), '')))
            FROM [CVO_Control]..[im_config]
            WHERE RTRIM(LTRIM(ISNULL(UPPER([Item Name]), ''))) = 'BATCH DESCRIPTION'
                    AND [INT Value] = @immakcr_sp_Process_User_ID
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' im_config 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    SELECT @process_description = 'Cash Receipt Import',
           @process_parent_app = 2000, 
           @process_ctrl_num = ''
    --
    -- Make sure that all the header rows that have details in error are marked in error.
    --
    UPDATE [#imarpyt_vw]
            SET [processed_flag] = d.[processed_flag]
            FROM [#imarpyt_vw] h
            INNER JOIN [#imarpdt_vw] d
                    ON d.[doc_ctrl_num] = h.[doc_ctrl_num]
            WHERE NOT d.[processed_flag] = 0
                    AND h.[processed_flag] = 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarpyt_vw 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    SELECT @date_processed = GETDATE()
    --
    -- Get rounding precision
    --
    SELECT @precision_gl = 2
    SELECT @precision_gl = curr_precision
            FROM glco, glcurr_vw
            WHERE glco.home_currency = glcurr_vw.currency_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' glco 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Get multicurrency info
    --
    SELECT @home_currency = home_currency,
           @oper_currency = oper_currency
            FROM glco    
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' glco 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    EXEC @SP_Result = pctrladd_sp @process_ctrl_num OUTPUT,
                                  @process_description, 
                                  @immakcr_sp_Process_User_ID,
                                  @process_parent_app, 
                                  @company_code
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
    SELECT @next_dcn = ''
    EXEC @SP_Result = appdate_sp @date_entered  OUTPUT 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' appdate_sp' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    IF @SP_Result = 0
        BEGIN
        EXEC im_log_sp_error_sp @ILSE_Error_Code = @SP_Result,
                                @ILSE_SP_Name = 'appdate_sp',
                                @ILSE_String = '',
                                @ILSE_Procedure_Name = @Routine_Name,
                                @ILSE_Log_Activity = 'YES',
                                @im_log_sp_error_sp_User_ID = @userid
        GOTO Error_Return
        END    
    


    INSERT INTO #arinppdt
            SELECT trx_ctrl_num,   doc_ctrl_num, sequence_id,
                   2111,           apply_to_num, 2031,
                   customer_code,  0,            amt_applied,
                   amt_disc_taken, 0,            0,
                   0,              line_desc,    '',
                   0,              0,            0,
                   '',             '',           0,
                   0,              0,            0,
                   0,              0,            amt_applied,
                   amt_disc_taken, 0,            '',
                   0,              0,			org_id			
                    FROM #imarpdt_vw
                    WHERE [processed_flag] = 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #arinppdt 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #arinppdt
            SET apply_trx_type = h.trx_type
            FROM #arinppdt td
            INNER JOIN artrx h
                    ON h.doc_ctrl_num = td.apply_to_num
                            AND h.customer_code = td.customer_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #arinppdt 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #arinppdt
            SET date_aging = h.date_aging, 
                amt_tot_chg = h.amt_tot_chg, 
                date_doc = h.date_doc, 
                amt_inv = h.amt_net, 
                inv_cur_code = h.nat_cur_code, 
                inv_rate_oper = h.rate_oper, 
                inv_rate_home = h.rate_home
            FROM #arinppdt td
            INNER JOIN artrx h
                    ON td.apply_to_num = h.doc_ctrl_num
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #arinppdt 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    DELETE #interim_totals_1
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DELETE + ' #interim_totals_1 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    INSERT INTO #interim_totals_1
            SELECT a.customer_code, a.apply_to_num, SUM(a.amt_applied + a.amt_disc_taken), 0
                    FROM arinppdt a, #arinppdt b
                    WHERE a.apply_to_num = b.apply_to_num
                            AND a.customer_code = b.customer_code
                    GROUP BY a.customer_code, a.apply_to_num
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #interim_totals 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #arinppdt
            SET #arinppdt.amt_paid_to_date = b.amt1
            FROM #arinppdt #arinppdt, #interim_totals_1 b
            WHERE #arinppdt.apply_to_num = b.apply_to_num
                    AND #arinppdt.customer_code = b.customer_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #arinppdt 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    DELETE #interim_totals_1
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DELETE + ' #interim_totals 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    INSERT INTO #interim_totals_1
            SELECT a.customer_code, a.apply_to_num, SUM(a.amt_applied + a.amt_disc_taken),0
                    FROM artrxpdt a, #arinppdt b
                    WHERE a.apply_to_num = b.apply_to_num
                            AND a.customer_code = b.customer_code
                    GROUP BY a.customer_code, a.apply_to_num
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #interim_totals 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #arinppdt
            SET #arinppdt.amt_paid_to_date = #arinppdt.amt_paid_to_date + b.amt1
            FROM #arinppdt #arinppdt, #interim_totals_1 b
            WHERE #arinppdt.apply_to_num = b.apply_to_num
                    AND #arinppdt.customer_code = b.customer_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #arinppdt 4' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    DELETE #interim_totals_1
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DELETE + ' #interim_totals 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #arinppdt
            SET #arinppdt.terms_code = b.terms_code
            FROM #arinppdt #arinppdt, arcust b
            WHERE #arinppdt.customer_code = b.customer_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #arinppdt 5' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #arinppdt
            SET #arinppdt.gain_home = ROUND(#arinppdt.amt_applied * ( SIGN(1 + SIGN(b.rate_home))*(b.rate_home) + (SIGN(ABS(SIGN(ROUND(b.rate_home,6))))/(b.rate_home + SIGN(1 - ABS(SIGN(ROUND(b.rate_home,6)))))) * SIGN(SIGN(b.rate_home) - 1) ), @precision_gl) - ROUND(#arinppdt.inv_amt_applied * ( SIGN(1 + SIGN(#arinppdt.inv_rate_home))*(#arinppdt.inv_rate_home) + (SIGN(ABS(SIGN(ROUND(#arinppdt.inv_rate_home,6))))/(#arinppdt.inv_rate_home + SIGN(1 - ABS(SIGN(ROUND(#arinppdt.inv_rate_home,6)))))) * SIGN(SIGN(#arinppdt.inv_rate_home) - 1) ), @precision_gl), #arinppdt.gain_oper = ROUND(#arinppdt.amt_applied * ( SIGN(1 + SIGN(b.rate_oper))*(b.rate_oper) + (SIGN(ABS(SIGN(ROUND(b.rate_oper,6))))/(b.rate_oper + SIGN(1 - ABS(SIGN(ROUND(b.rate_oper,6)))))) * SIGN(SIGN(b.rate_oper) - 1) ), @precision_gl) -  ROUND(#arinppdt.inv_amt_applied * ( SIGN(1 + SIGN(#arinppdt.inv_rate_oper))*(#arinppdt.inv_rate_oper) + (SIGN(ABS(SIGN(ROUND(#arinppdt.inv_rate_oper,6))))/(#arinppdt.inv_rate_oper + SIGN(1 - ABS(SIGN(ROUND(#arinppdt.inv_rate_oper,6)))))) * SIGN(SIGN(#arinppdt.inv_rate_oper) - 1) ), @precision_gl)
            FROM #arinppdt #arinppdt, #imarpyt_vw b
            WHERE #arinppdt.doc_ctrl_num = b.doc_ctrl_num
                    AND #arinppdt.customer_code = b.customer_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #arinppdt 6' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    IF (@debug_level >= 3)  
        BEGIN
        SELECT '(3): ' + @Routine_Name + ': Dump of #arinppdt'
        SELECT * FROM #arinppdt
        END
    CREATE TABLE #trxnums (doc_ctrl_num VARCHAR(16),
                           trx_ctrl_num VARCHAR(16),
                           stl_ctrl_num VARCHAR(16),
                           customer_code VARCHAR(8),
                           date_applied INT,
                           nat_cur_code VARCHAR(8),
                           rate_type_home VARCHAR(8),
                           rate_type_oper VARCHAR(8),
                           rate_home FLOAT,
                           rate_oper FLOAT)    
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATETABLE + ' #trxnums 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    CREATE UNIQUE CLUSTERED INDEX #trxnums_ind0 ON #trxnums (customer_code, doc_ctrl_num)
    INSERT #trxnums    
            SELECT doc_ctrl_num,   trx_ctrl_num,                                                     
                   '',             customer_code,  
                   datediff(dd, @January_First_Nineteen_Eighty, CONVERT(datetime, date_applied)) + 722815, nat_cur_code, 
                   rate_type_home, rate_type_oper,       
                   rate_home,      rate_oper
                    FROM #imarpyt_vw
                    WHERE processed_flag = 0    
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #trxnums 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    DECLARE trxnum_cursor CURSOR FOR
            SELECT doc_ctrl_num, trx_ctrl_num, customer_code, date_applied, nat_cur_code, rate_type_home, rate_type_oper, rate_home, rate_oper
            FROM #trxnums
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DECLARE + ' trxnum_cursor 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    OPEN trxnum_cursor
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_OPEN + ' trxnum_cursor 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    FETCH NEXT FROM trxnum_cursor
            INTO @doc_ctrl_num, @trx_ctrl_num, @customer_code, @date_applied, @nat_cur_code, @rate_type_home, @rate_type_oper, @rate_home, @rate_oper
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_FETCHNEXT + ' trxnum_cursor 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    WHILE NOT @@FETCH_STATUS = -1
        BEGIN
        IF NOT @@FETCH_STATUS = -2
            BEGIN
            SELECT @updateflag = 0
            IF @rate_home = 0
                BEGIN
                EXEC @SP_Result = [CVO_Control]..mccurate_sp @date_applied,
                                                          @nat_cur_code,    
                                                          @home_currency,        
                                                          @rate_type_home,    
                                                          @rate_home OUTPUT,
                                                          0,
                                                          @divide_flag_h OUTPUT
                SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' [CVO_Control]..mccurate_sp 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
                IF NOT @SP_Result = 0
                    BEGIN
                    EXEC im_log_sp_error_sp @ILSE_Error_Code = @SP_Result,
                                            @ILSE_SP_Name = 'mccurate_sp',
                                            @ILSE_String = '1',
                                            @ILSE_Procedure_Name = @Routine_Name,
                                            @ILSE_Log_Activity = 'YES',
                                            @im_log_sp_error_sp_User_ID = @userid
                    GOTO Error_Return
                    END    
                SELECT @updateflag = 1
                END
            IF @rate_oper = 0
                BEGIN
                EXEC @SP_Result = [CVO_Control]..mccurate_sp @date_applied,
                                                          @nat_cur_code,    
                                                          @oper_currency,        
                                                          @rate_type_oper,    
                                                          @rate_oper OUTPUT,
                                                          0,
                                                          @divide_flag_o OUTPUT
                SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' [CVO_Control]..mccurate_sp 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
                IF NOT @SP_Result = 0
                    BEGIN
                    EXEC im_log_sp_error_sp @ILSE_Error_Code = @SP_Result,
                                            @ILSE_SP_Name = 'mccurate_sp',
                                            @ILSE_String = '2',
                                            @ILSE_Procedure_Name = @Routine_Name,
                                            @ILSE_Log_Activity = 'YES',
                                            @im_log_sp_error_sp_User_ID = @userid
                    GOTO Error_Return
                    END    
                SELECT @updateflag = 1
                END
            IF DATALENGTH(LTRIM(RTRIM(ISNULL(@trx_ctrl_num, '')))) = 0
                BEGIN
                EXEC @SP_Result = ARGetNextControl_SP 2010, 
                                                      @masked OUTPUT, 
                                                      @num OUTPUT
                SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' ARGetNextControl_SP 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
                IF NOT @SP_Result = 0
                    BEGIN
                    EXEC im_log_sp_error_sp @ILSE_Error_Code = @SP_Result,
                                            @ILSE_SP_Name = 'ARGetNextControl_SP',
                                            @ILSE_String = '1',
                                            @ILSE_Procedure_Name = @Routine_Name,
                                            @ILSE_Log_Activity = 'YES',
                                            @im_log_sp_error_sp_User_ID = @userid
                    GOTO Error_Return
                    END    
                SELECT @trx_ctrl_num = @masked 
                SET @updateflag = 1
                END
            IF @Using_Settlements = 'YES'
                BEGIN    
                
















                EXEC @SP_Result = ARGetNextControl_SP 2015, 
                                                      @masked OUTPUT, 
                                                      @num OUTPUT
                SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' ARGetNextControl_SP 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
                IF NOT @SP_Result = 0
                        BEGIN
                        EXEC im_log_sp_error_sp @ILSE_Error_Code = @SP_Result,
                                                @ILSE_SP_Name = 'ARGetNextControl_SP',
                                                @ILSE_String = '2',
                                                @ILSE_Procedure_Name = @Routine_Name,
                                                @ILSE_Log_Activity = 'YES',
                                                @im_log_sp_error_sp_User_ID = @userid
                        GOTO Error_Return
                        END    
                SELECT @stl_ctrl_num = @masked 
                --
                -- Note that @updateflag is set unconditionally when using eBackOffice 7.2
                -- (settlements). 
                --
                SET @updateflag = 1    
                --
                END
            IF @updateflag = 1
                BEGIN
                UPDATE #trxnums
                        SET trx_ctrl_num = @trx_ctrl_num,
                            stl_ctrl_num = @stl_ctrl_num,
                            rate_home = @rate_home,
                            rate_oper = @rate_oper
                        WHERE CURRENT OF trxnum_cursor
                SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #trxnums 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
                END
            END
        FETCH NEXT FROM trxnum_cursor
                INTO @doc_ctrl_num, @trx_ctrl_num, @customer_code, @date_applied, @nat_cur_code, @rate_type_home, @rate_type_oper, @rate_home, @rate_oper
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_FETCHNEXT + ' trxnum_cursor 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        END
    CLOSE trxnum_cursor
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CLOSE + ' trxnum_cursor 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    DEALLOCATE trxnum_cursor
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DEALLOCATE + ' trxnum_cursor 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': Copying from #imarpyt_vw to #arinppyt'
    BEGIN TRANSACTION 
    INSERT INTO #arinppyt (trx_ctrl_num,      doc_ctrl_num,        trx_desc,
                           batch_code,        trx_type,            non_ar_flag,
                           non_ar_doc_num,    gl_acct_code,        date_entered,
                           date_applied,      date_doc,            customer_code,
                           payment_code,      payment_type,        amt_payment,
                           amt_on_acct,       prompt1_inp,         prompt2_inp,
                           prompt3_inp,       prompt4_inp,         deposit_num,
                           bal_fwd_flag,      printed_flag,        posted_flag,
                           hold_flag,         wr_off_flag,         on_acct_flag,
                           user_id,           max_wr_off,          days_past_due,
                           void_type,         cash_acct_code,      origin_module_flag,
                           process_group_num, source_trx_ctrl_num, source_trx_type,
                           nat_cur_code,      rate_type_home,      rate_type_oper,
                           rate_home,         rate_oper,           amt_discount,
                           reference_code,	  org_id)				
            SELECT a.trx_ctrl_num,    a.doc_ctrl_num,   trx_desc,
                   '',                2111,             0,
                   '',                '',               @date_entered,
                   a.date_applied,    datediff(dd, @January_First_Nineteen_Eighty, CONVERT(datetime,date_doc)) + 722815, a.customer_code,
                   payment_code,      payment_type,     amt_payment,
                   amt_on_account,    '',               '',
                   '',                '',               '', 
                   0,                 0,                0,
                   0,                 0,                0,
                   @userid,           0.0,              0,
                   0,                 cash_acct_code,   NULL,
                   @process_ctrl_num, '',               NULL,
                   a.nat_cur_code,    a.rate_type_home, a.rate_type_oper,
                   a.rate_home,       a.rate_oper,      amt_discount,
                   '',				  #imarpyt_vw.org_id							
                    FROM #imarpyt_vw, #trxnums a
                    WHERE RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
                            AND processed_flag = 0
                            AND #imarpyt_vw.customer_code = a.customer_code
                            AND #imarpyt_vw.doc_ctrl_num = a.doc_ctrl_num  
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #arinppyt 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #arinppyt
            SET on_acct_flag = 1
            WHERE amt_on_acct > 0.0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #arinppyt 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #arinppdt 
            SET #arinppdt.trx_ctrl_num = b.trx_ctrl_num
            FROM #arinppdt #arinppdt, #arinppyt b
            WHERE #arinppdt.doc_ctrl_num = b.doc_ctrl_num
                    AND #arinppdt.customer_code = b.customer_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #arinppdt 7' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    COMMIT TRANSACTION 
    --
    -- If there is an overpayment of an invoice, start subtracting from the amount applied on details that apply to the
    -- invoice and adding that amount into the header amt_on_acct, working backward from the last applied CR, until
    -- the invoice is no longer overpayed.
    --
    SELECT @next_custatn = ''
    IF @debug_level >= 3
        BEGIN
        SELECT '(3): ' + @Routine_Name + ': Starting #totals pseudo cursor processing.'
        END
    WHILE 42 = 42
        BEGIN
        --
        -- Loop through each of the customer/apply to numbers in the #totals table
        --
        IF @debug_level >= 3
            BEGIN
            SELECT '(3): ' + @Routine_Name + ': #totals pseudo cursor'
            SELECT '#totals cursor: ', 'totals' = '[' + RTRIM(customer_code) + RTRIM(apply_to_num) + ']', 'variable' = '[' + RTRIM(@next_custatn) + ']' FROM #totals ORDER BY customer_code + apply_to_num
            END

        SET ROWCOUNT 1
        SELECT @next_custatn = RTRIM(customer_code) + RTRIM(apply_to_num),
               @amt_applied = amt_applied,
               @amt_disc_taken = amt_disc_taken,
               @amt_net = amt_net,
               @customer_code = customer_code,
               @doc_ctrl_num = ''
                FROM #totals
                WHERE RTRIM(customer_code) + RTRIM(apply_to_num) > ISNULL(RTRIM(@next_custatn),'')
                ORDER BY RTRIM(customer_code) + RTRIM(apply_to_num)
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' #totals 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        SET ROWCOUNT 0
        IF @debug_level >= 3
            BEGIN
            SELECT '(3): ' + @Routine_Name + ': @next_custatn = ' + LTRIM(RTRIM(@next_custatn))
            END
        IF @Row_Count = 0
            BREAK
        IF @debug_level >= 3
            BEGIN
            SELECT '(3): ' + @Routine_Name + ': #totals pseudo cursor @next_custatn = ' + @next_custatn
            END
        --
        -- If we have an overpayment then we need to loop through all of the CRs in the temp tables and move
        -- the amt_applied into the headers amt_on_acct until we no longer have an overpayment.
        --
        IF ROUND(@amt_applied + @amt_disc_taken, @precision_gl) > ROUND(@amt_net, @precision_gl)
            BEGIN
            --
            -- Calculate the amount of overpayment
            --
            SELECT @amt_overcharge = ROUND(@amt_applied + @amt_disc_taken, @precision_gl) - ROUND(@amt_net, @precision_gl)
            IF (@debug_level >= 3) 
                BEGIN
                SELECT '(3): ' + @Routine_Name + ': Customer/Apply-To ' + RTRIM(LTRIM(@next_custatn)) + ' overpaid by ' + RTRIM(LTRIM(CONVERT(CHAR, @amt_overcharge)))
                END
            --
            -- Loop through all of the payments in the temp table until we reduce the overpayment to zero.
            -- The latest payment gets reduced first.
            --
            IF @debug_level >= 3
                BEGIN
                SELECT '(3): ' + @Routine_Name + ': Payments pseudo cursor:'
                SELECT a.date_applied, 
                       b.amt_applied,
                       a.doc_ctrl_num,
                       a.customer_code,
                       b.sequence_id
                        FROM #arinppyt a, #arinppdt b
                        WHERE a.doc_ctrl_num = b.doc_ctrl_num 
                                AND a.customer_code = b.customer_code 
                                AND b.customer_code + b.apply_to_num = rtrim(@next_custatn)
                        ORDER BY a.date_applied DESC, a.doc_ctrl_num DESC, b.sequence_id DESC
                SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' payments pseudo cursor 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
                END
            DECLARE payCursor CURSOR FOR 
                    SELECT a.date_applied, 
                           b.amt_applied,
                           a.doc_ctrl_num,
                           a.customer_code,
                           b.sequence_id
                            FROM #arinppyt a, #arinppdt b
                            WHERE a.doc_ctrl_num = b.doc_ctrl_num 
                                    AND a.customer_code = b.customer_code 
                                    AND b.customer_code + b.apply_to_num = rtrim(@next_custatn)
                            ORDER BY a.date_applied DESC, a.doc_ctrl_num DESC, b.sequence_id DESC
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DECLARE + ' payCursor 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            OPEN payCursor
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_OPEN + ' payCursor 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            FETCH NEXT FROM payCursor 
                    INTO @next_date_applied, @amt_applied, @doc_ctrl_num, @customer_code, @sequence_id
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_FETCHNEXT + ' payCursor 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            WHILE (@@FETCH_STATUS <> -1)
                BEGIN
                IF @@FETCH_STATUS <> -2
                    BEGIN
                    IF @debug_level >= 3
                        BEGIN
                        SELECT '(3): ' + @Routine_Name + ': payCursor:'
                        SELECT '@next_date_applied' = @next_date_applied,
                               '@amt_applied' = @amt_applied,
                               '@doc_ctrl_num' = @doc_ctrl_num,
                               '@customer_code' = @customer_code,
                               '@sequence_id' = @sequence_id
                        END
                    --
                    -- If the amount on this payment cannot erase the entire overpayment 
                    -- then move the entire amt_applied to amt_on_acct.
                    --                
                    IF @amt_applied < @amt_overcharge
                        BEGIN
                        IF @debug_level >= 3 
                            BEGIN
                            SELECT '(3): ' + @Routine_Name + ': Moved to on-account:'
                            SELECT @buf = RTRIM(LTRIM(CONVERT(CHAR,@amt_applied))) + ' moved to on-account for customer ' + RTRIM(@customer_code) + ', document ' + RTRIM(@doc_ctrl_num)
                            SELECT @buf
                            END
                        UPDATE #arinppyt
                                SET amt_on_acct = amt_on_acct + @amt_applied,
                                    on_acct_flag = 1
                                WHERE customer_code = @customer_code 
                                        AND doc_ctrl_num = @doc_ctrl_num
                        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #arinppyt 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
                        UPDATE #arinppdt
                                SET amt_applied = 0,
                                    inv_amt_applied = 0
                                WHERE customer_code = @customer_code
                                        AND doc_ctrl_num = @doc_ctrl_num
                                        AND sequence_id = @sequence_id
                        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #arinppdt 8' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
                        SELECT @amt_overcharge = @amt_overcharge - @amt_applied
                        END
                    ELSE
                        BEGIN
                        --
                        -- If the amount on this payment is more than the amount overpaid then 
                        -- we subtract the amount overpaid from the amount of the payment and
                        -- add it to the amount on account.
                        --
                        IF @debug_level >= 3 
                            BEGIN
                            SELECT '(3): ' + @Routine_Name + ': Amount over-charged:'
                            SELECT @buf = RTRIM(LTRIM(CONVERT(CHAR, @amt_overcharge))) + ' of ' + RTRIM(LTRIM(CONVERT(CHAR,@amt_applied))) + ' moved to on-account for customer ' + RTRIM(@customer_code) + ', document ' + RTRIM(@doc_ctrl_num)
                            SELECT @buf
                            END
                        UPDATE #arinppyt
                                SET amt_on_acct = amt_on_acct + @amt_overcharge,
                                    on_acct_flag = 1
                                WHERE customer_code = @customer_code 
                                        AND doc_ctrl_num = @doc_ctrl_num
                        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #arinppyt 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
                        UPDATE #arinppdt
                                SET amt_applied = amt_applied - @amt_overcharge,
                                    inv_amt_applied = amt_applied - @amt_overcharge
                                WHERE customer_code = @customer_code
                                        AND doc_ctrl_num = @doc_ctrl_num
                                        AND sequence_id = @sequence_id
                        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #arinppdt 9' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
                        SELECT @amt_overcharge = 0
                        END
                    IF @amt_overcharge <= 0
                        BREAK
                    END
                FETCH NEXT FROM payCursor 
                        INTO @next_date_applied, @amt_applied, @doc_ctrl_num, @customer_code, @sequence_id
                SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_FETCHNEXT + ' payCursor 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
                END
            DEALLOCATE payCursor
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DEALLOCATE + ' payCursor 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            END
        END
    --
    -- Delete the details of any transaction that has amt_payment = amt_on_acct.
    -- The check for amt_payment = amt_on_acct is a "tolerance" check rather than an 
    -- equality check courtesy of Mike at National Leasing.
    --
    IF @debug_level >= 3
        BEGIN
        SELECT '(3): ' + @Routine_Name + ': Removing the following details because entire payment was put on account'
        SELECT b.* 
                FROM #arinppyt a, #arinppdt b 
                WHERE a.trx_ctrl_num = b.trx_ctrl_num
                        AND ABS(a.amt_payment - a.amt_on_acct) < 0.01
                        AND a.on_acct_flag = 1
        END
    DELETE FROM #arinppdt
            FROM #arinppyt a, #arinppdt b
            WHERE a.trx_ctrl_num = b.trx_ctrl_num
                    AND ABS(a.amt_payment - a.amt_on_acct) < 0.01
                    AND a.on_acct_flag = 1
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DELETE + ' #arinppdt 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Copy records to the im# tables.
    --
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': Copy records to the im# tables'
    INSERT INTO [CVO_Control]..im#imarpyt 
            ([Import Identifier], [Import Company], [Import Date],
             company_code,        trx_ctrl_num,     doc_ctrl_num,
             trx_desc,            cash_acct_code,   date_applied,
             date_doc,            customer_code,    payment_code,
             payment_type,        amt_on_account,   amt_payment,
             amt_discount,        nat_cur_code,     rate_type_home,
             rate_type_oper,      rate_home,        rate_oper,
             processed_flag,      date_processed,   [batch_no],
             [record_id_num], [User_ID],			org_id)			
            SELECT @immakcr_sp_Import_Identifier, @company_code,  GETDATE(),                 
                   company_code,                  trx_ctrl_num,   doc_ctrl_num,
                   trx_desc,                      cash_acct_code, date_applied,
                   date_doc,                      customer_code,  payment_code,
                   payment_type,                  amt_on_account, amt_payment,
                   amt_discount,                  nat_cur_code,   rate_type_home,
                   rate_type_oper,                rate_home,      rate_oper,
                   processed_flag,                date_processed, [batch_no],
                   [record_id_num],               [User_ID],	  org_id			
                    FROM #imarpyt_vw
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' [CVO_Control]..im#imarpyt 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    INSERT INTO [CVO_Control]..im#imarpdt 
            ([Import Identifier], [Import Company], [Import Date],
             company_code,        trx_ctrl_num,     doc_ctrl_num,
             sequence_id,         apply_to_num,     customer_code,
             amt_applied,         amt_disc_taken,   line_desc,
             processed_flag,      [batch_no],       [record_id_num],
             [User_ID],				org_id)			
            SELECT @immakcr_sp_Import_Identifier, @company_code,      GETDATE(),      
                   company_code,                  trx_ctrl_num,       doc_ctrl_num,
                   sequence_id,                   apply_to_num,       customer_code,
                   amt_applied,                   amt_disc_taken,     line_desc,
                   processed_flag,                [batch_no],         [record_id_num],
                   [User_ID],					  org_id			
                    FROM #imarpdt_vw
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' [CVO_Control]..im#imarpdt 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Let the standard stored procedure write it to the input tables.
    --
    IF @trial_flag = 0
        BEGIN
        EXEC @errcode = arpysav_sp @company_code, 
                                   @immakcr_sp_Process_User_ID, 
                                   @debug_level
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' arpysav_sp' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        IF NOT @errcode = 0
            BEGIN
            EXEC im_log_sp_error_sp @ILSE_Error_Code = @errcode,
                                    @ILSE_SP_Name = 'arpysav_sp',
                                    @ILSE_String = '',
                                    @ILSE_Procedure_Name = @Routine_Name,
                                    @ILSE_Log_Activity = 'YES',
                                    @im_log_sp_error_sp_User_ID = @userid
            GOTO Error_Return
            END
        --
        -- The proper way to set arinppdt.writeoff_code would have been to add a writeoff_code
        -- column to #arinppdt, set that value from arcustok_vw, and to fix arpysav_sp to copy
        -- that value to arinppdt.
        --    
        UPDATE [arinppdt]
                SET [writeoff_code] = b.[writeoff_code]
                FROM [arinppdt] a
                INNER JOIN [arcustok_vw] b
                        ON b.[customer_code] = a.[customer_code]
                INNER JOIN [#trxnums] c
                        ON c.[trx_ctrl_num] = a.[trx_ctrl_num]      
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' [arinppdt] 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        --
        -- The following section of code was added in version 7.2 to process the new
        -- "settlements".  Some of these SQL statements are done inside an EXEC because
        -- an error is generated if the named tables etc. do not exist even though
        -- the processing is conditional based on @Using_Settlements.  
        --    
        IF @Using_Settlements = 'YES'
            BEGIN
            --
            -- batch_code must be blank for settlements to post in non-batch mode.
            --
            IF EXISTS (SELECT 1 FROM arco WHERE batch_proc_flag = 1)
                BEGIN
                EXEC ('UPDATE arinppyt
                               SET [settlement_ctrl_num] = [stl_ctrl_num]
                               FROM [arinppyt] h
                               INNER JOIN [#trxnums] t
                                       ON t.[trx_ctrl_num] = h.[trx_ctrl_num]')
                SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' arinppyt 1A' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
                END
            ELSE    
                BEGIN
                EXEC ('UPDATE arinppyt
                               SET [settlement_ctrl_num] = [stl_ctrl_num],
                                   [batch_code] = ''''
                               FROM [arinppyt] h
                               INNER JOIN [#trxnums] t
                                       ON t.[trx_ctrl_num] = h.[trx_ctrl_num]')
                SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' arinppyt 1B' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
                END
            --
            EXEC ('INSERT INTO arinpstlhdr (timestamp,          settlement_ctrl_num, description, 
                                            hold_flag,          posted_flag,         date_entered, 
                                            date_applied,       user_id,             process_group_num, 
                                            doc_count_expected, doc_count_entered,   doc_sum_expected, 
                                            doc_sum_entered,    cr_total_home,       cr_total_oper, 
                                            oa_cr_total_home,   oa_cr_total_oper,    cm_total_home, 
                                            cm_total_oper,      inv_total_home,      inv_total_oper, 
                                            disc_total_home,    disc_total_oper,     wroff_total_home, 
                                            wroff_total_oper,   onacct_total_home,   onacct_total_oper, 
                                            gain_total_home,    gain_total_oper,     loss_total_home, 
                                            loss_total_oper,    customer_code,       nat_cur_code,
                                            batch_code,         rate_type_home,      rate_home, 
                                            rate_type_oper,     rate_oper,           inv_amt_nat, 
                                            amt_doc_nat,        amt_dist_nat,        amt_on_acct,  
                                            settle_flag,		org_id)			
                           SELECT NULL,                                    t.stl_ctrl_num,                          ''IMPORTED-'' + LTRIM(RTRIM(t.trx_ctrl_num)), 
                                  0,                                       0,                                       DATEDIFF(dd, ''' + @January_First_Nineteen_Eighty + ''', CONVERT(datetime, GETDATE())) + 722815, 
                                  t.date_applied,                          h.user_id,                               '''', 
                                  1,                                       1,                                       h.amt_payment, 
                                  h.amt_payment,                           h.amt_payment * h.rate_home,             h.amt_payment * h.rate_oper, 
                                  0,                                       0,                                       0, 
                                  0,                                       0,                                       0, 
                                  ISNULL(h.amt_discount, 0) * h.rate_home, ISNULL(h.amt_discount, 0) * h.rate_oper, 0, 
                                  0,                                       h.amt_on_acct * h.rate_home,             h.amt_on_acct * h.rate_oper, 
                                  0,                                       0,                                       0, 
                                  0,                                       h.[customer_code],                       t.nat_cur_code,
                                  '''',                                    t.rate_type_home,                        t.rate_home,
                                  t.rate_type_oper,                        t.rate_oper,                             0,
                                  0,                                       0,                                       0,
                                  0,										h.org_id			
                                   FROM [#trxnums] t
                                   INNER JOIN [arinppyt] h
                                           ON h.[trx_ctrl_num] = t.[trx_ctrl_num]')
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' arinpstlhdr 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            CREATE TABLE #stl_totals (trx_ctrl_num VARCHAR(16),
                                      stl_ctrl_num VARCHAR(16),
                                      inv_total FLOAT,
                                      wroff_total FLOAT,
                                      gain_total_home FLOAT,
                                      gain_total_oper FLOAT,
                                      rate_home FLOAT,
                                      rate_oper FLOAT,
                                      inv_amt_nat FLOAT,
                                      amt_doc_nat FLOAT,
                                      amt_dist_nat FLOAT,
                                      amt_on_acct FLOAT)
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATETABLE + ' #stl_totals 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            INSERT INTO [#stl_totals]
                    SELECT d.trx_ctrl_num,        '',                                     SUM(ISNULL(d.amt_applied, 0)), 
                           SUM(ISNULL(d.amt_max_wr_off, 0)), SUM(ISNULL(d.gain_home, 0)), SUM(ISNULL(d.gain_oper, 0)), 
                           0,                     0,                                      SUM(ISNULL(d.amt_applied, 0)),
                           0,                     0,                                      0
                            FROM arinppdt d
                            INNER JOIN #trxnums t
                                    ON t.trx_ctrl_num = d.trx_ctrl_num
                            GROUP BY d.trx_ctrl_num
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #stl_totals 1A' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            UPDATE [#stl_totals]
                    SET rate_home = h.rate_home,
                        rate_oper = h.rate_oper,
                        stl_ctrl_num = h.settlement_ctrl_num,
                        inv_amt_nat = t.inv_amt_nat
                    FROM #stl_totals t
                    INNER JOIN arinppyt h
                            ON h.trx_ctrl_num = t.trx_ctrl_num
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #stl_totals 1A' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            EXEC ('UPDATE arinpstlhdr
                           SET inv_total_home = t.inv_total * t.rate_home,
                               inv_total_oper = t.inv_total * t.rate_oper,
                               wroff_total_home = t.wroff_total * t.rate_home,
                               wroff_total_oper = t.wroff_total * t.rate_oper,
                               gain_total_home = t.gain_total_home,
                               gain_total_oper = t.gain_total_oper,
                               inv_amt_nat = t.inv_amt_nat
                           FROM arinpstlhdr
                           INNER JOIN #stl_totals t
                                   ON t.stl_ctrl_num = arinpstlhdr.settlement_ctrl_num')
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' arinpstlhdr 1A' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            DELETE FROM [#stl_totals]
            INSERT INTO [#stl_totals]
                    SELECT h.trx_ctrl_num,                '',                            0, 
                           0,                             0,                             0, 
                           0,                             0,                             0,
                           SUM(ISNULL(h.amt_payment, 0)), SUM(ISNULL(h.amt_payment, 0)), SUM(ISNULL(h.amt_on_acct, 0)) 
                            FROM arinppyt h
                            INNER JOIN #trxnums t
                                    ON t.trx_ctrl_num = h.trx_ctrl_num
                            GROUP BY h.trx_ctrl_num
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #stl_totals 1B' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            UPDATE [#stl_totals]
                    SET stl_ctrl_num = h.settlement_ctrl_num
                    FROM #stl_totals
                    INNER JOIN arinppyt h
                            ON h.trx_ctrl_num = #stl_totals.trx_ctrl_num
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #stl_totals 1B' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            EXEC ('UPDATE arinpstlhdr
                           SET amt_doc_nat = t.amt_doc_nat,
                               amt_dist_nat = t.amt_dist_nat,
                               amt_on_acct = t.amt_on_acct
                           FROM arinpstlhdr
                           INNER JOIN #stl_totals t
                                   ON t.stl_ctrl_num = arinpstlhdr.settlement_ctrl_num')
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' arinpstlhdr 1B' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            DROP TABLE [#stl_totals]
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DROPTABLE + ' #stl_totals 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            END
        --
        -- Set processed_flag to 1 for valid records.
        --
        UPDATE [imarpyt_vw]
                SET [trx_ctrl_num] = b.[trx_ctrl_num],
                    [date_processed] = @date_processed,
                    [processed_flag] = 1
                FROM [imarpyt_vw] a, [arinppyt] b
                WHERE RTRIM(LTRIM(ISNULL(a.[company_code], ''))) = @company_code
                        AND a.[doc_ctrl_num] = b.[doc_ctrl_num]
                        AND a.[customer_code] = b.[customer_code]
                        AND (a.[processed_flag] = 0 OR a.[processed_flag] IS NULL)
                        AND (a.[User_ID] = @userid OR @userid = 0)
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imarpyt_vw 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        UPDATE [imarpdt_vw]
                SET [trx_ctrl_num] = b.trx_ctrl_num,
                    [processed_flag] = b.processed_flag
                FROM [imarpdt_vw] a, [CVO_Control]..[imarpyt] b
                WHERE RTRIM(LTRIM(ISNULL(a.[company_code], ''))) = @company_code
                        AND a.[doc_ctrl_num] = b.[doc_ctrl_num]
                        AND a.[customer_code] = b.[customer_code]
                        AND (a.[User_ID] = @userid OR @userid = 0)
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imarpdt_vw 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        --
        -- Update the batch_description and close the batches.
        --
        IF EXISTS (SELECT 1 FROM arco WHERE batch_proc_flag = 1)
            BEGIN
            IF @debug_level >= 3
                SELECT '(3): ' + @Routine_Name + ': Updating batch descriptions and closing batches' 
            SELECT @complete_date = datediff(dd, @January_First_Nineteen_Eighty, CONVERT(datetime, GETDATE())) + 722815
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @complete_date' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            SELECT @complete_time = datepart(hh, GETDATE()) * 3600 + datepart(mi, GETDATE()) * 60 + datepart(ss, GETDATE())
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @complete_time' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            IF DATALENGTH(LTRIM(RTRIM(ISNULL(@immakcr_sp_User_Name, '')))) = 0
                SET @complete_user = SUSER_SNAME()
            ELSE    
                SET @complete_user = @immakcr_sp_User_Name
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @complete_user' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            SELECT @next_batch_code = ''
            WHILE (42 = 42)
                BEGIN
                SET ROWCOUNT 1
                SELECT DISTINCT @next_batch_code = a.batch_ctrl_num
                        FROM batchctl a, [CVO_Control]..imarpyt b, arinppyt c
                        WHERE a.batch_ctrl_num = c.batch_code
                                AND b.doc_ctrl_num = c.doc_ctrl_num
                                AND b.customer_code = c.customer_code
                                AND RTRIM(LTRIM(ISNULL(b.company_code, ''))) = @company_code
                                AND b.processed_flag = 1                
                                AND c.batch_code > @next_batch_code
                        ORDER BY a.batch_ctrl_num
                SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' batchctl 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
                SET ROWCOUNT 0
                IF @Row_Count = 0
                    BREAK                
                SELECT @batch_count = COUNT(*),
                       @batch_total = SUM(amt_payment)
                        FROM    arinppyt
                        WHERE    batch_code = @next_batch_code
                SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' arinppyt 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
                UPDATE batchctl
                        SET batch_description = @im_config_batch_description,
                            completed_user = @complete_user,
                            completed_date = @complete_date,
                            completed_time = @complete_time,
                            control_number = @batch_count,
                            control_total = @batch_total,
                            actual_number = @batch_count,
                            actual_total = @batch_total
                        WHERE batch_ctrl_num = @next_batch_code
                                AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
                SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' batchctl 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
                IF @debug_level >= 3
                    BEGIN
                    SELECT '(3): ' + @Routine_Name + ': batchctl WHERE batch_ctrl_num = ' + ISNULL(@next_batch_code, 'NULL') + ' AND company_code = ' + @company_code
                    SELECT * 
                            FROM batchctl 
                            WHERE batch_ctrl_num = @next_batch_code 
                                    AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
                    END
                END
            IF @debug_level >= 3
                SELECT '(3): ' + @Routine_Name + ': Done updating batch descriptions and closing batches' 
            END
        END
    DROP TABLE #trxnums    
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DROPTABLE + ' #trxnums 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Let the pcontrol table know that we are done.
    --
    EXEC @SP_Result = pctrlupd_sp @process_ctrl_num ,3
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' pctrlupd_sp' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    IF NOT @SP_Result = 0
        BEGIN
        EXEC im_log_sp_error_sp @ILSE_Error_Code = @SP_Result,
                                @ILSE_SP_Name = 'pctrlupd_sp',
                                @ILSE_String = '',
                                @ILSE_Procedure_Name = @Routine_Name,
                                @ILSE_Log_Activity = 'YES',
                                @im_log_sp_error_sp_User_ID = @userid
        GOTO Error_Return
        END   
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': Exit.' 
    RETURN 0
Error_Return:
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': Exit (ERROR).'
    RETURN -1    
GO
GRANT EXECUTE ON  [dbo].[immakcr_sp] TO [public]
GO
