SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

 
    CREATE PROC 
[dbo].[imarint01a_sp] @company_code VARCHAR(8), 
              @validation_flag SMALLINT, 
              @db_userid CHAR(40), 
              @db_password CHAR(40), 
              @invoice_flag SMALLINT, 
              @debug_level SMALLINT, 
              @module_id SMALLINT, 
              @process_ctrl_num VARCHAR(16) OUTPUT, 
              @userid INT = 0
    AS      
    DECLARE @result int,
            @process_description VARCHAR(40), 
            @process_parent_app SMALLINT, 
            @process_parent_company VARCHAR(8) ,
            @buf VARCHAR(255),
            @spid SMALLINT,
			@Bypass_All_Tax_Calculations NVARCHAR(1000),		
			@Bypass_Tax_Calculation_Code NVARCHAR(1000)			

    
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
    

    SET @Routine_Name = 'imarint01a_sp'
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
    SELECT @spid = @@spid
    --
    -- Validate transactions
    --
    IF (@validation_flag = 1)
        BEGIN
        IF (@debug_level >= 3)
            SELECT '(3): ' + @Routine_Name + ': Before IMARValidateInvoice_sp'
        EXEC @SP_Result = IMARValidateInvoice_sp @db_userid, 
                                                 @db_password, 
                                                 @invoice_flag, 
                                                 @debug_level, 
                                                 @process_ctrl_num OUTPUT,
                                                 @company_code
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' IMARValidateInvoice_sp' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        IF NOT @SP_Result = 0
                AND NOT @SP_Result = 34562
            BEGIN
            EXEC im_log_sp_error_sp @ILSE_Error_Code = @SP_Result,
                                    @ILSE_SP_Name = 'IMARValidateInvoice_sp',
                                    @ILSE_String = '',
                                    @ILSE_Procedure_Name = @Routine_Name,
                                    @ILSE_Log_Activity = 'YES',
                                    @im_log_sp_error_sp_User_ID = @userid
            GOTO Error_Return
            END    
        --
        -- Update the errors that were found earlier, before the process_ctrl_num was known
        --
        UPDATE perror
                SET process_ctrl_num = @process_ctrl_num
                WHERE process_ctrl_num = 'imarint01temp'
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' perror 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
        --
        -- Verify that all headers have details.
        --
        INSERT INTO perror
                (process_ctrl_num, batch_code,  module_id,
                 err_code,         info1,       info2,
                 infoint,          infofloat,   flag1,
                 trx_ctrl_num,     sequence_id, source_ctrl_num,
                 extra) 
                SELECT @process_ctrl_num,       '',             @module_id,
                       20930, h.doc_ctrl_num, h.order_ctrl_num,
                       0,                       0,              0,
                       h.trx_ctrl_num,          0,              '',
                       0
                        FROM [#arinpchg] h
                        LEFT OUTER JOIN [#arinpcdt] d
                                ON h.[trx_ctrl_num] = d.[trx_ctrl_num]
                        GROUP BY h.[trx_ctrl_num], h.[doc_ctrl_num], h.[order_ctrl_num]
                        HAVING COUNT(d.[trx_ctrl_num]) = 0
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' perror 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
        --
        -- Verify that all details have headers.  Note that since #arinpcdt records are
        -- only created when there is a corresponding record in #imarhdr_vw, the check here
        -- must use the staging tables rather than the temporary input tables.
        --
        INSERT INTO perror (process_ctrl_num, batch_code, module_id, err_code, info1, info2, infoint, infofloat, flag1, trx_ctrl_num, sequence_id, source_ctrl_num, extra ) 
                SELECT @process_ctrl_num, '', @module_id, 20944, '', a.order_ctrl_num, 0, 0.0, 0, a.source_ctrl_num, a.sequence_id, '', 0
                        FROM [#imardtl_vw] a
                        LEFT OUTER JOIN [#imarhdr_vw] b
                                ON [a].[source_ctrl_num] = [b].[source_ctrl_num]
                        WHERE [b].[company_code] IS NULL
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' perror 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
        --
        IF (@debug_level >= 3)
            BEGIN
            SELECT '(3): ' + @Routine_Name + ': Begin prepayment validation phase.  Dump of #arinptmp:'
            SELECT * FROM #arinptmp
            END
        --
        -- Validate amt_payment.
        --
        IF (@debug_level >= 3)
            BEGIN
            SELECT '(3): ' + @Routine_Name + ': Validate amt_payment'
            END
        INSERT INTO perror (process_ctrl_num, batch_code, module_id, 
                            err_code, info1, info2, 
                            infoint, infofloat, flag1, 
                            trx_ctrl_num, sequence_id, source_ctrl_num, 
                            extra) 
                SELECT @process_ctrl_num, '', @module_id, 
                       20932, a.doc_ctrl_num, a.order_ctrl_num, 
                       0, 0.0, 0, 
                       a.trx_ctrl_num, 0, '', 
                       0
                        FROM #arinpchg a, #arinptmp b
                        WHERE a.trx_ctrl_num = b.trx_ctrl_num
                                AND b.amt_payment <= 0
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' perror 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        --
        -- Validate amt_disc_taken.
        --
        IF (@debug_level >= 3)
            SELECT '(3): ' + @Routine_Name + ': Validate prepay_discount'
        INSERT INTO perror (process_ctrl_num, batch_code, module_id, 
                            err_code, info1, info2, 
                            infoint, infofloat, flag1, 
                            trx_ctrl_num, sequence_id, source_ctrl_num, 
                            extra) 
                SELECT @process_ctrl_num, '', @module_id, 
                       20931, a.doc_ctrl_num, a.order_ctrl_num, 
                       0, 0.0, 0, 
                       a.trx_ctrl_num, 0, '', 
                       0
                        FROM #arinpchg a, #arinptmp b
                        WHERE a.trx_ctrl_num = b.trx_ctrl_num
                                AND b.amt_disc_taken < 0
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' perror 4' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        --
        -- Validate that qty_returned is greater than 0 for credit memos.
        --
        IF (@debug_level >= 3)
            SELECT '(3): ' + @Routine_Name + ': Validate that qty_returned is greater than 0 for credit memos'
        INSERT INTO perror (process_ctrl_num, batch_code,  module_id, 
                            err_code,         info1,       info2, 
                            infoint,          infofloat,   flag1, 
                            trx_ctrl_num,     sequence_id, source_ctrl_num, 
                            extra) 
                SELECT @process_ctrl_num,          '',               @module_id, 
                       20943, a.[doc_ctrl_num], a.[order_ctrl_num], 
                       0,                          0.0,              0, 
                       a.[trx_ctrl_num],           b.[sequence_id],  a.[source_trx_ctrl_num], 
                       0
                        FROM [#arinpchg] a 
                        INNER JOIN [#arinpcdt] b
                                ON a.[trx_ctrl_num] = b.[trx_ctrl_num]
                        WHERE a.[trx_type] = 2032
                                AND b.[qty_returned] = 0
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' perror 5' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        --
        -- Validate recurring_code.
        --
        IF (@debug_level >= 3)
            SELECT '(3): ' + @Routine_Name + ': Validate recurring_code'
        INSERT INTO perror (process_ctrl_num, batch_code,  module_id, 
                            err_code,         info1,       info2, 
                            infoint,          infofloat,   flag1, 
                            trx_ctrl_num,     sequence_id, source_ctrl_num, 
                            extra) 
                SELECT @process_ctrl_num,               '',               @module_id, 
                       20949, a.[doc_ctrl_num], a.[order_ctrl_num], 
                       0,                               0.0,              0, 
                       a.[trx_ctrl_num],                b.[sequence_id],  a.[source_trx_ctrl_num], 
                       0
                        FROM [#arinpchg] a 
                        INNER JOIN [#arinpcdt] b
                                ON a.[trx_ctrl_num] = b.[trx_ctrl_num]
                        WHERE a.[recurring_code] IN (1, 2, 3, 4)
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' perror 6' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        --
        -- Validate doc_ctrl_num against arcpcust_vw
        --
        IF (@debug_level >= 3)
            SELECT '(3): ' + @Routine_Name + ': Validate doc_ctrl_num against arcpcust_vw'
        INSERT INTO perror (process_ctrl_num, batch_code, module_id, 
                            err_code, info1, info2, 
                            infoint, infofloat, flag1, 
                            trx_ctrl_num, sequence_id, source_ctrl_num, 
                            extra) 
                SELECT @process_ctrl_num, '', @module_id, 
                       20933, a.doc_ctrl_num, a.order_ctrl_num, 
                       0, 0.0, 0, 
                       a.trx_ctrl_num, 0, '', 
                       0
                        FROM #arinpchg a, #arinptmp b, arcpcust_vw c
                        WHERE a.trx_ctrl_num = b.trx_ctrl_num
                                AND b.doc_ctrl_num = c.doc_ctrl_num 
                                AND b.customer_code = c.customer_code
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' perror 7' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        --
        -- Validate doc_ctrl_num against arinppyt
        --
        IF (@debug_level >= 3)
            SELECT '(3): ' + @Routine_Name + ': Validate doc_ctrl_num against arinppyt'
        INSERT INTO perror (process_ctrl_num, batch_code,  module_id, 
                            err_code,         info1,       info2, 
                            infoint,          infofloat,   flag1, 
                            trx_ctrl_num,     sequence_id, source_ctrl_num, 
                            extra)
                SELECT @process_ctrl_num,      '',             @module_id, 
                       20933, a.doc_ctrl_num, a.order_ctrl_num, 
                       0,                      0.0,            0, 
                       a.trx_ctrl_num,         0,              '', 
                       0
                        FROM #arinpchg a, #arinptmp b, arinppyt c
                        WHERE a.trx_ctrl_num = b.trx_ctrl_num
                                AND b.doc_ctrl_num = c.doc_ctrl_num 
                                AND b.customer_code = c.customer_code
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' perror 8' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        --
        -- Validate doc_ctrl_num against arinptmp
        --
        IF (@debug_level >= 3)
            SELECT '(3): ' + @Routine_Name + ': Validate doc_ctrl_num against arinptmp'
        INSERT INTO perror (process_ctrl_num, batch_code,  module_id, 
                            err_code,         info1,       info2, 
                            infoint,          infofloat,   flag1, 
                            trx_ctrl_num,     sequence_id, source_ctrl_num, 
                            extra) 
                SELECT @process_ctrl_num,      '',             @module_id, 
                       20933, a.doc_ctrl_num, a.order_ctrl_num, 
                       0,                      0.0,            0, 
                       a.trx_ctrl_num,         0,              '', 
                       0
                        FROM #arinpchg a, #arinptmp b, arinptmp c
                        WHERE a.trx_ctrl_num = b.trx_ctrl_num
                                AND b.doc_ctrl_num = c.doc_ctrl_num 
                                AND b.customer_code = c.customer_code
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' perror 9' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        --
        -- Validate doc_ctrl_num against #arinptmp
        --
        IF (@debug_level >= 3)
            SELECT '(3): ' + @Routine_Name + ': Validate doc_ctrl_num against #arinptmp'
        INSERT INTO perror (process_ctrl_num, batch_code,  module_id, 
                            err_code,         info1,       info2, 
                            infoint,          infofloat,   flag1, 
                            trx_ctrl_num,     sequence_id, source_ctrl_num, 
                            extra)
                SELECT @process_ctrl_num,      '',             @module_id, 
                       20933, a.doc_ctrl_num, a.order_ctrl_num, 
                       0,                      0.0,             0, 
                       a.trx_ctrl_num,         0,              '', 
                       0
                        FROM #arinpchg a
                        WHERE a.trx_ctrl_num IN (SELECT b.trx_ctrl_num FROM #arinptmp b WHERE b.doc_ctrl_num IN (SELECT c.doc_ctrl_num FROM #arinptmp c GROUP BY c.doc_ctrl_num, c.customer_code HAVING COUNT(*) > 1 AND c.customer_code = b.customer_code))
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' perror 10' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        --
        -- Validate cash_acct_code.  If valid, assume that payment_code is valid because 
        -- cash_acct_code was defaulted from payment_code upstream.
        --
        IF (@debug_level >= 3)
            SELECT '(3): ' + @Routine_Name + ': Validate cash_acct_code'
        INSERT INTO perror (process_ctrl_num, batch_code,  module_id, 
                            err_code,         info1,       info2, 
                            infoint,          infofloat,   flag1, 
                            trx_ctrl_num,     sequence_id, source_ctrl_num, 
                            extra)
                SELECT @process_ctrl_num,       '',             @module_id, 
                       20934, a.doc_ctrl_num, a.order_ctrl_num, 
                       0,                       0.0,            0, 
                       a.trx_ctrl_num,          0,              '', 
                       0
                        FROM #arinpchg a, #arinptmp b
                        WHERE a.trx_ctrl_num = b.trx_ctrl_num
                                AND b.cash_acct_code = ''
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' perror 11' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        IF @invoice_flag = 2032
            BEGIN
            --
            -- Validate writeoff_code.
            --
            IF (@debug_level >= 3)
                SELECT '(3): ' + @Routine_Name + ': Validate writeoff_code'
            INSERT INTO perror (process_ctrl_num, batch_code,  module_id, 
                                err_code,         info1,       info2, 
                                infoint,          infofloat,   flag1, 
                                trx_ctrl_num,     sequence_id, source_ctrl_num, 
                                extra)
                    SELECT @process_ctrl_num,              '',             @module_id, 
                           20948, doc_ctrl_num,   order_ctrl_num, 
                           0,                              0.0,            0, 
                           trx_ctrl_num,                   0,              '', 
                           0
                            FROM #arinpchg
                            WHERE [writeoff_code] NOT IN (SELECT DISTINCT [writeoff_code] FROM [arwrofac])
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' perror 12' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            END
        --
        -- Make sure that there are no duplicate records in the staging tables.
        -- Note that source_ctrl_num cannot be used for a duplicates test because
        -- this value is not part of the actual transaction.  Also note that this test
        -- only examines invoices that are printed; it is not possible to detect
        -- duplicate invoices when they are unprinted since there is no doc_ctrl_num
        -- value.
        --
        INSERT INTO perror ([process_ctrl_num], [batch_code],  [module_id], 
                            [err_code],         [info1],       [info2],
                            [infoint],          [infofloat],   [flag1],
                            [trx_ctrl_num],     [sequence_id], [source_ctrl_num],
                            [extra]) 
                SELECT @process_ctrl_num,              '',                            @module_id, 
                       20941, ISNULL(b.[customer_code], ''), '',
                       0,                              0,                              0,
                       '',                             0,                              ISNULL(a.[source_trx_ctrl_num], ''),
                       0
                        FROM [#arinpchg] a INNER JOIN [arinpchg_all] b			
                                ON a.[trx_type] = b.[trx_type]
                                        AND a.[doc_ctrl_num] = b.[doc_ctrl_num]
                                        AND a.[customer_code] = b.[customer_code]
                                        AND a.[amt_gross] = b.[amt_gross]
                                        AND a.[printed_flag] = 1
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' perror 13' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        INSERT INTO perror ([process_ctrl_num], [batch_code],  [module_id], 
                            [err_code],         [info1],       [info2],
                            [infoint],          [infofloat],   [flag1],
                            [trx_ctrl_num],     [sequence_id], [source_ctrl_num],
                            [extra]) 
                SELECT @process_ctrl_num,              '',                @module_id, 
                       20941, ISNULL(b.[customer_code], ''), '',
                       0,                              0,                              0,
                       ISNULL(b.trx_ctrl_num, ''),     0,                              ISNULL(a.[source_trx_ctrl_num], ''),
                       0
                        FROM [#arinpchg] a INNER JOIN [artrx_all] b 			
                                ON a.[trx_type] = b.[trx_type]
                                        AND a.[doc_ctrl_num] = b.[doc_ctrl_num]
                                        AND a.[customer_code] = b.[customer_code]
                                        AND a.[amt_gross] = b.[amt_gross]
                                        AND a.[printed_flag] = 1
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' perror 14' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

	



		-- 
        -- Get the "Bypass Tax Calculations" config table entry.
        --
        SET @Bypass_All_Tax_Calculations = 'NO'
        IF EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'im_config')
        BEGIN
          SELECT @Bypass_All_Tax_Calculations = UPPER([Text Value])
          FROM   [im_config] 
          WHERE  UPPER([Item Name]) = 'BYPASS ALL TAX CALCULATIONS'

		IF @Bypass_All_Tax_Calculations = 'TRUE'
            SET @Bypass_All_Tax_Calculations = 'YES'
        END
        IF @debug_level >= 3
          SELECT '(3): ' + @Routine_Name + ': Bypass All Tax Calculations = ''' + @Bypass_All_Tax_Calculations + ''''
		--
    	-- "Bypass All Tax Calculations" overrides "Bypass Tax Calculation Code".
    	--    
    	IF @Bypass_All_Tax_Calculations = 'YES'
		BEGIN
		  --
          -- Verify that all the detail records have a relation one-to-one between tax_code and tax_type_code.
          --
          INSERT INTO perror
                (process_ctrl_num, batch_code,  module_id,
                 err_code,         info1,       info2,
                 infoint,          infofloat,   flag1,
                 trx_ctrl_num,     sequence_id, source_ctrl_num,
                 extra) 
				 SELECT @process_ctrl_num,		'',				@module_id, 
						20954, '',		d.tax_code, 
						0,						0.0,			0, 
						d.trx_ctrl_num,		d.sequence_id, '', 
						0
                 FROM   [#arinpcdt] d
                     INNER JOIN artaxdet t ON d.tax_code = t.tax_code
                 GROUP  BY d.[trx_ctrl_num], d.[tax_code], d.[sequence_id]
                 HAVING COUNT(d.[trx_ctrl_num]) > 1
          SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' perror 15' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
		
		END
		ELSE
        BEGIN
		  -- 
          -- Get the "Bypass Tax Calculation Code" config table entry.
          --
          SET @Bypass_Tax_Calculation_Code = ''
          IF EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'im_config')
          BEGIN
            SELECT @Bypass_Tax_Calculation_Code = [Text Value]
            FROM   [im_config] 
            WHERE  UPPER([Item Name]) = 'BYPASS TAX CALCULATION CODE'
            IF @@ROWCOUNT = 0 OR @Bypass_Tax_Calculation_Code IS NULL
              SET @Bypass_Tax_Calculation_Code = ''
          END
		  IF @debug_level >= 3
          SELECT '(3): ' + @Routine_Name + ': Bypass Tax Calculation Code = ''' + @Bypass_Tax_Calculation_Code + ''''

		  --
          -- Verify that the "Tax Code" bypassed has only one tax_type_code.
          --
          INSERT INTO perror
                (process_ctrl_num, batch_code,  module_id,
                 err_code,         info1,       info2,
                 infoint,          infofloat,   flag1,
                 trx_ctrl_num,     sequence_id, source_ctrl_num,
                 extra) 
				 SELECT @process_ctrl_num,		'',				@module_id, 
						20955, '',		d.tax_code, 
						0,						0.0,			0, 
						d.trx_ctrl_num,		d.sequence_id, '', 
						0
                 FROM   [#arinpcdt] d
                     INNER JOIN artaxdet t ON d.tax_code = t.tax_code
				 WHERE  d.tax_code = @Bypass_Tax_Calculation_Code
                 GROUP  BY d.[trx_ctrl_num], d.[tax_code], d.[sequence_id]
                 HAVING COUNT(d.[trx_ctrl_num]) > 1
          SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' perror 15' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
		END

	
	


		INSERT INTO perror
                (process_ctrl_num, batch_code,  module_id,
                 err_code,         info1,       info2,
                 infoint,          infofloat,   flag1,
                 trx_ctrl_num,     sequence_id, source_ctrl_num,
                 extra) 
				 SELECT @process_ctrl_num,			 '',			@module_id, 
						20956, '',			a.apply_to_num, 
						0,							 0.0,			0, 
						a.trx_ctrl_num, 			 0, 			'', 
						0
                 FROM   #arinpchg a
                     INNER JOIN artrx b ON a.apply_to_num = b.doc_ctrl_num AND a.org_id <> b.org_id
				 WHERE b.trx_type = 2031
          SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' perror 16' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
	
        --
        -- Mark all the temporary input table records as valid and then mark those in error
        -- appropriately.  process_group_num is set to that code called by imarinsav_sp
        -- can set #arinpchg.batch_code appropriately. 
        --
        UPDATE #arinpchg
                SET trx_state = 2,
                    [process_group_num] = @process_ctrl_num
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #arinpchg 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        UPDATE #arinpchg
                SET trx_state = 3
                FROM #arinpchg a, perror b
                WHERE (a.trx_ctrl_num = b.trx_ctrl_num OR a.source_trx_ctrl_num = b.trx_ctrl_num)
                        AND b.process_ctrl_num = @process_ctrl_num
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #arinpchg 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        UPDATE #arinpcdt
                SET trx_state = 2
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #arinpcdt 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        UPDATE #arinpcdt
                SET trx_state = 3
                FROM #arinpcdt a, perror b
                WHERE a.trx_ctrl_num = b.trx_ctrl_num
                        AND (a.sequence_id = b.sequence_id OR b.sequence_id = 0)
                        AND b.process_ctrl_num = @process_ctrl_num
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #arinpcdt 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        --
        IF (@debug_level >= 3)
            BEGIN
            SELECT '(3): ' + @Routine_Name + ': End of validation phase.'
            SELECT '(3): ' + @Routine_Name + ': Dump of pcontrol:'
            SELECT * 
                    FROM [CVO_Control]..pcontrol 
                    WHERE [process_ctrl_num] = @process_ctrl_num
            SELECT '(3): ' + @Routine_Name + ': Dump of perror:'
            SELECT * 
                    FROM perror 
                    WHERE [process_ctrl_num] = @process_ctrl_num
            END
        END
    ELSE
        BEGIN
        --
        -- If the transactions are not being validated, we need to fill in all the stuff that 
        -- the validation would have filled in so that the code downstream thinks we really 
        -- did do the validation.  We need to get a process entry and then update the permanent
        -- tables with the stuff from the temporary tables.
        --
        SELECT @process_description = 'Invoice Posting in AR',
              @process_parent_app = 2100, 
              @process_ctrl_num = '',
              @Process_User_ID = @userid
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @process_description' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        EXEC @SP_Result = pctrladd_sp @process_ctrl_num OUTPUT,
                                      @process_description, 
                                      @Process_User_ID,
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
        --
        -- Mark the temporary input table records as valid.
        --
        UPDATE #arinpchg
                SET [trx_state] = 2, 
                    [process_group_num] = @process_ctrl_num
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #arinpchg 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        UPDATE #arinpcdt
                SET trx_state = 2
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #arinpcdt 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        --
        -- Update the process table.
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
        --
        -- Verify that all headers have details.
        --
        INSERT INTO perror (process_ctrl_num, batch_code, module_id, err_code, info1, info2, infoint, infofloat, flag1, trx_ctrl_num, sequence_id, source_ctrl_num, extra ) 
                SELECT @process_ctrl_num, '', @module_id, 20930, a.doc_ctrl_num, a.order_ctrl_num, 0, 0.0, 0, a.trx_ctrl_num, 0, '', 0
                        FROM #arinpchg a LEFT OUTER JOIN #arinpcdt b ON (a.trx_ctrl_num = b.trx_ctrl_num)
                        GROUP BY a.trx_ctrl_num, a.doc_ctrl_num, a.order_ctrl_num
                        HAVING COUNT(b.trx_ctrl_num) = 0
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' perror 15' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        --
        -- Update the errors that were found earlier, before the process_ctrl_num was known
        --
        UPDATE perror
                SET process_ctrl_num = @process_ctrl_num
                WHERE process_ctrl_num = 'imarint01temp'
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' perror 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        --
        -- Update the trx_state column in the temp tables so that the save routines will behave
        -- as they did in 4.1
        --
        UPDATE #arinpchg
                SET trx_state = 3
                FROM #arinpchg a, perror b
                WHERE (a.trx_ctrl_num = b.trx_ctrl_num OR a.source_trx_ctrl_num = b.trx_ctrl_num)
                        AND b.process_ctrl_num = @process_ctrl_num
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #arinpchg 4' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        UPDATE #arinpcdt
                SET trx_state = 3
                FROM #arinpcdt a, perror b
                WHERE a.trx_ctrl_num = b.trx_ctrl_num
                        AND (a.sequence_id = b.sequence_id OR b.sequence_id = 0)
                        AND b.process_ctrl_num = @process_ctrl_num
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #arinpcdt 4' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        --
        IF (@debug_level >= 3)
            BEGIN
            SELECT '(3): ' + @Routine_Name + ': End simulated validation phase'
            SELECT '(3): ' + @Routine_Name + ': Dump of pcontrol:'
            SELECT * 
                    FROM [CVO_Control]..[pcontrol] 
                    WHERE [process_ctrl_num] = @process_ctrl_num
            SELECT '(3): ' + @Routine_Name + ': Dump of perror:'
            SELECT * 
                    FROM [perror] 
                    WHERE [process_ctrl_num] = @process_ctrl_num
            END
        END
    --
    -- Put process_ctrl_num in the staging header table so the following UPDATEs
    -- can do a proper JOIN.
    --    
    UPDATE #imarhdr_vw
            SET process_ctrl_num = @process_ctrl_num
            FROM #imarhdr_vw a, #arinpchg b
            WHERE a.source_ctrl_num = b.source_trx_ctrl_num
                    AND a.customer_code = b.customer_code
                    AND (NOT a.[processed_flag] = 1 OR a.[processed_flag] IS NULL)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarhdr_vw 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Eliminate errors that have no meaning in an import environment.
    -- Update #arinpchg setting trx_state = 2 when the error code is 20030
    -- and there are no other errors.
    --
    CREATE TABLE [#arinpchg_perror] ([trx_ctrl_num] VARCHAR(16) NULL,
                                     [trx_state] INT NULL)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATETABLE + ' #arinpchg_perror 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    INSERT INTO [#arinpchg_perror] ([trx_ctrl_num], [trx_state])
            SELECT h.[trx_ctrl_num], COUNT(h.[trx_state])
                    FROM [#arinpchg] h
                    INNER JOIN [perror] p
                            ON p.[trx_ctrl_num] = h.[trx_ctrl_num]
                    WHERE NOT p.[err_code] = 20030
                    GROUP BY h.[trx_ctrl_num]
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #arinpchg_perror 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE [#arinpcdt] 
            SET trx_state = 2
            FROM [#arinpcdt] d
            INNER JOIN [#arinpchg] h
                    ON d.[trx_ctrl_num] = h.[trx_ctrl_num]
            INNER JOIN [perror] p
                    ON p.[trx_ctrl_num] = h.[trx_ctrl_num]
            LEFT OUTER JOIN [#arinpchg_perror] ap
                    ON ap.[trx_ctrl_num] = h.[trx_ctrl_num]
            WHERE ap.[trx_state] IS NULL
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #arinpcdt 5' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE [#arinpchg] 
            SET trx_state = 2
            FROM [#arinpchg] h
            INNER JOIN [perror] p
                    ON p.[trx_ctrl_num] = h.[trx_ctrl_num]
            LEFT OUTER JOIN [#arinpchg_perror] ap
                    ON ap.[trx_ctrl_num] = h.[trx_ctrl_num]
            WHERE ap.[trx_state] IS NULL
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #arinpchg 5' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    DROP TABLE [#arinpchg_perror]
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DROPTABLE + ' #arinpchg_perror 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    DELETE [perror]
            WHERE [err_code] = 20030
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DELETE + ' perror 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    -- 
    -- Now flag all of the staging header table records that have errors.  The update
    -- done linking staging.source_ctrl_num = perror.trx_ctrl_num is done for "trial"
    --                                                                                
    UPDATE [#imarhdr_vw]                                                                 
            SET [processed_flag] = 2
            FROM [#imarhdr_vw] a
            INNER JOIN [perror] b                                        
                    ON a.[process_ctrl_num] = b.[process_ctrl_num]                           
                            AND a.[trx_ctrl_num] = b.[trx_ctrl_num]
            WHERE (NOT a.[processed_flag] = 1 OR a.[processed_flag] IS NULL)
                    AND NOT DATALENGTH(LTRIM(RTRIM(ISNULL(b.[trx_ctrl_num], '')))) = 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarhdr_vw 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE [#imarhdr_vw]                                                                 
            SET [processed_flag] = 2
            FROM [#imarhdr_vw] a
            INNER JOIN [perror] b                                        
                    ON a.[process_ctrl_num] = b.[process_ctrl_num]                           
                            AND a.[source_ctrl_num] = b.[source_ctrl_num]                       
            WHERE (NOT a.[processed_flag] = 1 OR a.[processed_flag] IS NULL)
                    AND DATALENGTH(LTRIM(RTRIM(ISNULL(b.[trx_ctrl_num], '')))) = 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarhdr_vw 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE [#imarhdr_vw]                                                                 
            SET [processed_flag] = 2
            FROM [#imarhdr_vw] a
            INNER JOIN [perror] b                                        
                    ON a.[process_ctrl_num] = b.[process_ctrl_num]                           
                            AND a.[source_ctrl_num] = b.[trx_ctrl_num]                       
            WHERE (NOT a.[processed_flag] = 1 OR a.[processed_flag] IS NULL)
                    AND NOT DATALENGTH(LTRIM(RTRIM(ISNULL(b.[trx_ctrl_num], '')))) = 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarhdr_vw 4' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- The edit in ARINValidateHeader3_SP does not create a proper record in perror
    -- for code 20091.  This is a detail record error, but perror.sequence_id is set to 0
    -- and perror.source_ctrl_num is not set.  There may be other error codes with this 
    -- problem so they are listed in the im_config table.  Set perror.sequence_id to -1.
    --
    -- 2002/10/29 Removed until a better fix can be implemenmted, either in the form
    -- of correcting the eBackOffice procedure ARINValidateHeader3_SP (and/or whatever 
    -- else follows it and uses the #account table), or coming up with some code here
    -- that effectively re-validates #arinpcdt.gl_rev_acct and sets perror.sequence_id
    -- to a proper value.  Even though the sequence_id column is zero and the error applies 
    -- to a detail record, having the sequence_id column set to zero at least allows the 
    -- error message to appear in the header grid (as opposed to not at all).
    







    --
    -- Make sure the source_ctrl_num from the staging table exists in the perror table.
    -- The update can be done using trx_ctrl_num to do the JOIN because the temporary
    -- version of the staging table will always have this column populated. 
    --
    UPDATE [perror]
            SET [source_ctrl_num] = b.[source_ctrl_num]
            FROM [perror] a
            INNER JOIN [#imarhdr_vw] b
                    ON a.[trx_ctrl_num] = b.[trx_ctrl_num]
            WHERE DATALENGTH(LTRIM(RTRIM(ISNULL(a.[source_ctrl_num], '')))) = 0
                    AND (a.[sequence_id] = 0)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' perror 4' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE [perror]
            SET [source_ctrl_num] = b.[source_ctrl_num]
            FROM [perror] a
            INNER JOIN [#imardtl_vw] b
                    ON a.[trx_ctrl_num] = b.[trx_ctrl_num]
            WHERE DATALENGTH(LTRIM(RTRIM(ISNULL(a.[source_ctrl_num], '')))) = 0
                    AND ((a.[sequence_id] = b.[sequence_id]) OR (a.[sequence_id] = -1))
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' perror 5' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Update the detail table setting processed_flag = 2 for records in error.  
    -- The update to set process_ctrl_num is present so that a join may be done
    -- with perror and only get perror records for the current import.  The update
    -- done linking staging.source_ctrl_num = perror.trx_ctrl_num is done for "trial"
    -- mode conditions.
    --
    UPDATE [#imardtl_vw]
            SET [process_ctrl_num] = @process_ctrl_num
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imardtl_vw 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE [#imardtl_vw]                                                                 
            SET [processed_flag] = 2
            FROM [#imardtl_vw] a
            INNER JOIN [perror] b                                        
                    ON a.[process_ctrl_num] = b.[process_ctrl_num]                           
                            AND a.[trx_ctrl_num] = b.[trx_ctrl_num]                       
            WHERE (a.[processed_flag] = 0 OR a.[processed_flag] IS NULL)
                    AND ((a.[sequence_id] = b.[sequence_id]) OR (b.[sequence_id] = -1))
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imardtl_vw 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE [#imardtl_vw]                                                                 
            SET [processed_flag] = 2
            FROM [#imardtl_vw] a
            INNER JOIN [perror] b                                        
                    ON a.[process_ctrl_num] = b.[process_ctrl_num]                           
                            AND a.[source_ctrl_num] = b.[source_ctrl_num]                       
            WHERE (a.[processed_flag] = 0 OR a.[processed_flag] IS NULL)
                    AND ((a.[sequence_id] = b.[sequence_id]) OR (b.[sequence_id] = -1))
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imardtl_vw 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE [#imardtl_vw]                                                                 
            SET [processed_flag] = 2
            FROM [#imardtl_vw] a
            INNER JOIN [perror] b                                        
                    ON a.[process_ctrl_num] = b.[process_ctrl_num]                           
                            AND a.[source_ctrl_num] = b.[trx_ctrl_num]                       
            WHERE (a.[processed_flag] = 0 OR a.[processed_flag] IS NULL)
                    AND ((a.[sequence_id] = b.[sequence_id]) OR (b.[sequence_id] = -1))
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imardtl_vw 4' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Update the header staging table setting processed_flag = 2 for all detail
    -- records where the processed_flag = 2.
    --
    UPDATE [#imarhdr_vw]
            SET [processed_flag] = 2
            FROM [#imarhdr_vw] h
            INNER JOIN [#imardtl_vw] d
                    ON h.[source_ctrl_num] = d.[source_ctrl_num]
            WHERE d.[processed_flag] = 2        
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imarhdr_vw 5' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Eliminate all the invalid records from the temporary input tables since the save 
    -- routine copies all of the records in those tables to the permanent input tables.
    --
    DELETE [#arinptmp]
            FROM [#arinptmp] t
            INNER JOIN [#arinpchg] h
                    ON t.[trx_ctrl_num] = h.[trx_ctrl_num] 
            WHERE NOT h.[trx_state] = 2
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DELETE + ' #arinptmp 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    DELETE [#arinptax]
            FROM [#arinptax] t
            INNER JOIN [#arinpchg] h
                    ON t.[trx_ctrl_num] = h.[trx_ctrl_num] 
            WHERE NOT h.[trx_state] = 2
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DELETE + ' #arinptax 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    DELETE [#arinpage]
            FROM [#arinpage] a
            INNER JOIN [#arinpchg] h
                    ON a.[trx_ctrl_num] = h.[trx_ctrl_num] 
            WHERE NOT h.[trx_state] = 2
    DELETE #arinpchg 
            WHERE trx_state <> 2
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DELETE + ' #arinpchg 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    DELETE #arinpcdt 
            WHERE trx_state <> 2
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DELETE + ' #arinpcdt 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': Exit'

    RETURN 0
Error_Return:
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': Exit (ERROR).'
    RETURN -1    
GO
GRANT EXECUTE ON  [dbo].[imarint01a_sp] TO [public]
GO
