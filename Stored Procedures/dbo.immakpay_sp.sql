SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


    CREATE PROC 
[dbo].[immakpay_sp] @company_code VARCHAR(8),
            @debug_level smallint = 0,
            @immakpay_sp_Process_User_ID INT = 0,
            @immakpay_sp_Import_Identifier INT,
            @immakpay_sp_trial_flag INT,
            @userid INT = 0,
            @immakpay_sp_User_Name VARCHAR(30) = ''
    AS  
    DECLARE @buf        char(255),
            @bufl        int,
            @process_description     varchar(40), 
            @process_parent_app     smallint, 
            @process_ctrl_num    char(16),
            @result        int,
            @rowcount    int,
            @masked        char(16),
            @errcode    int,
            @date_processed datetime,
            @next_dcn    char(16),
            @date_entered    int,
            @precision_gl    smallint,
            @next_vendor    char(12),
            @trx_ctrl_num   varchar(16),
            @doc_ctrl_num    char(16),
            @trx_desc    char(40),
            @cash_acct_code    char(32),
            @date_applied    int,
            @date_doc    int,
            @vendor_code    char(12),
            @pay_to_code    char(8),
            @payment_code    char(8),
            @payment_type    smallint,
            @approval_code    char(8),
            @approval_flag    int,
            @amt_on_account    float,
            @amt_payment    float,
            @amt_discount    float,
            @nat_cur_code    char(8),
            @rate_type_home    char(8),
            @rate_type_oper    char(8),
            @rate_home    float,
            @rate_oper    float,
            @next_cash_disb_num    int,
            @cash_disb_num_mask    char(16),
            @cash_disb_start_col    smallint,
            @cash_disb_length    smallint,
            @next_vendatn        char(24),
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
    DECLARE @updateflag smallint
    
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
    

    SET @Routine_Name = 'immakpay_sp' 
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': Entry.'    
    
    --
    -- Standard_Process_1
    --
    -- Update and retrieve the current timestamp value from the control database.  
    -- Perform the update to insure that the timestamp value is unique.  An IF EXISTS
    -- with an INSERT is used here rather than having the table initially populated
    -- with a DAT file to avoid problems with the record possibly being deleted
    -- after the initial DBUPDATE.
    --
    IF EXISTS(SELECT 1 FROM [CVO_Control]..[im_DBTS])
        UPDATE [CVO_Control]..[im_DBTS]
                SET [Blank] = ''
    ELSE
        INSERT INTO [CVO_Control]..[im_DBTS]
                VALUES (NULL, '')
    SELECT @Import_Identifier = CAST([DBTS] AS INT)
        FROM [CVO_Control]..[im_DBTS]
    --
    -- Verify that @debug_level is within range.
    --
    IF @debug_level < 0
            OR @debug_level > 10
        BEGIN
        EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = 'Invalid @debug_level -- part 1',
                                                     @IGES_String = @External_String_1 OUT 
        EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = 'Invalid @debug_level -- part 2',
                                                     @IGES_String = @External_String_2 OUT 
        INSERT INTO [imlog] ([now], [text])
                VALUES (GETDATE(), @External_String_1 + '''' + @Routine_Name + '''' + @External_String_2)
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' @debug_level check' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END  
        SET @debug_level = 3      
        END   
    --
    -- Setting to 0 if NULL will prevent other "equal to 0" tests from thinking that @userid
    -- was set to non-zero.
    --
    IF @userid IS NULL
        SET @userid = 0
    --

    
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

    SELECT @im_config_batch_description = RTRIM(LTRIM(ISNULL(UPPER(ISNULL([Text Value], 'Import Manager Batch')), '')))
            FROM [CVO_Control]..[im_config]
            WHERE RTRIM(LTRIM(ISNULL(UPPER([Item Name]), ''))) = 'BATCH DESCRIPTION'
                    AND [INT Value] = @immakpay_sp_Process_User_ID
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' im_config 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Make sure that all the header rows that have details in error are marked in error.
    --
    UPDATE #imappyt_vw
            SET processed_flag = b.processed_flag
            FROM [#imappyt_vw] a, [#imappdt_vw] b
            WHERE NOT b.processed_flag = 0
                    AND a.doc_ctrl_num = b.doc_ctrl_num
                    AND (NOT a.[processed_flag] = 1 OR a.[processed_flag] IS NULL)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imappyt_vw 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Get rounding precision
    --
    SELECT @precision_gl = curr_precision
            FROM glco, glcurr_vw
            WHERE glco.home_currency = glcurr_vw.currency_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' glco 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    IF DATALENGTH(LTRIM(RTRIM(ISNULL(@precision_gl, '')))) = 0
        SELECT @precision_gl = 2
    --
    -- Get multicurrency info
    --
    SELECT @home_currency = home_currency,
           @oper_currency = oper_currency
            FROM glco    
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' glco 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    SET @Process_User_ID = @immakpay_sp_Process_User_ID
    SELECT @date_processed = GETDATE()
    SET @External_String = @Routine_Name + ' 1' 
    EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = @External_String,
                                                 @IGES_String = @External_String OUT
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' im_get_external_string_sp 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    SELECT @process_description = @External_String,
           @process_parent_app = 4000, 
           @process_ctrl_num = ''
    EXEC @SP_Result = pctrladd_sp @process_ctrl_num OUTPUT,
                                  @process_description, 
                                  @Process_User_ID,
                                  @process_parent_app, 
                                  @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' pctrladd_sp 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
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
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' appdate_sp 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
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
    --
    -- Build the copy of the detail input table.  This is done outside of the transaction 
    -- for performance reasons.  The join with the header prevents detail records with a 
    -- header error from being inserted into #apinppdt.
    --
    INSERT INTO [#apinppdt] 
		(	doc_ctrl_num,		trx_ctrl_num,		trx_type,
			sequence_id,    	apply_to_num,		apply_trx_type,       	
			amt_applied,          	amt_disc_taken,  	line_desc,
			void_flag,		payment_hold_flag,	vendor_code,
			vo_amt_applied,		vo_amt_disc_taken,	gain_home,
			gain_oper,		nat_cur_code,		trx_state,
			mark_flag,		vo_rate_oper,		vo_rate_home,
			org_id	)
            SELECT d.[doc_ctrl_num],  '',                 4111,
                   d.[sequence_id],  d.[apply_to_num],   4091,
                   d.[amt_applied],  d.[amt_disc_taken], d.[line_desc],
                   0,                0,                  d.[vendor_code],
                   d.[amt_applied],  d.[amt_disc_taken], 0.0,
                   0.0,              '',                 0,
                   0,                0.0,                0.0,
		   d.org_id
                   FROM [#imappdt_vw] d
                   INNER JOIN [#imappyt_vw] h
		                   ON h.[doc_ctrl_num] = d.[doc_ctrl_num]
                   WHERE (d.[processed_flag] = 0 OR d.[processed_flag] IS NULL)
                           AND (h.[processed_flag] = 0 OR h.[processed_flag] IS NULL)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #apinppdt 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- In e7 the transaction tables were broken apart into their various types.
    -- Assume that the payments are being applied to vouchers only.
    --
    UPDATE #apinppdt
            SET #apinppdt.apply_trx_type = 4091
            FROM #apinppdt #apinppdt, apvohdr b
            WHERE #apinppdt.apply_to_num = b.trx_ctrl_num
                    AND #apinppdt.vendor_code = b.vendor_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #apinppdt 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #apinppdt
            SET nat_cur_code = b.currency_code, 
                vo_rate_oper = b.rate_oper, 
                vo_rate_home = b.rate_home
            FROM #apinppdt #apinppdt, apvohdr b
            WHERE #apinppdt.apply_to_num = b.trx_ctrl_num
                    AND #apinppdt.vendor_code = b.vendor_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #apinppdt 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #apinppdt
            SET gain_home = ROUND(#apinppdt.amt_applied * ( SIGN(1 + SIGN(b.rate_home))*(b.rate_home) + (SIGN(ABS(SIGN(ROUND(b.rate_home,6))))/(b.rate_home + SIGN(1 - ABS(SIGN(ROUND(b.rate_home,6)))))) * SIGN(SIGN(b.rate_home) - 1) ), @precision_gl) - ROUND(#apinppdt.vo_amt_applied * ( SIGN(1 + SIGN(#apinppdt.vo_rate_home))*(#apinppdt.vo_rate_home) + (SIGN(ABS(SIGN(ROUND(#apinppdt.vo_rate_home,6))))/(#apinppdt.vo_rate_home + SIGN(1 - ABS(SIGN(ROUND(#apinppdt.vo_rate_home,6)))))) * SIGN(SIGN(#apinppdt.vo_rate_home) - 1) ), @precision_gl), 
                gain_oper = ROUND(#apinppdt.amt_applied * ( SIGN(1 + SIGN(b.rate_oper))*(b.rate_oper) + (SIGN(ABS(SIGN(ROUND(b.rate_oper,6))))/(b.rate_oper + SIGN(1 - ABS(SIGN(ROUND(b.rate_oper,6)))))) * SIGN(SIGN(b.rate_oper) - 1) ), @precision_gl) - ROUND(#apinppdt.vo_amt_applied * ( SIGN(1 + SIGN(#apinppdt.vo_rate_oper))*(#apinppdt.vo_rate_oper) + (SIGN(ABS(SIGN(ROUND(#apinppdt.vo_rate_oper,6))))/(#apinppdt.vo_rate_oper + SIGN(1 - ABS(SIGN(ROUND(#apinppdt.vo_rate_oper,6)))))) * SIGN(SIGN(#apinppdt.vo_rate_oper) - 1) ), @precision_gl)
            FROM #apinppdt #apinppdt, #imappyt_vw b
            WHERE #apinppdt.doc_ctrl_num = b.doc_ctrl_num
                    AND #apinppdt.vendor_code = b.vendor_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #apinppdt 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    IF (@debug_level >= 3)  
        BEGIN
        SELECT '(3): ' + @Routine_Name + ': #apinppdt'
        SELECT * FROM #apinppdt
        END
    CREATE TABLE #trxnums (doc_ctrl_num VARCHAR(16),
                           trx_ctrl_num VARCHAR(16),
                           vendor_code VARCHAR(12),
                           date_applied INT,
                           nat_cur_code VARCHAR(8),
                           rate_type_home VARCHAR(8),
                           rate_type_oper VARCHAR(8),
                           rate_home FLOAT,
                           rate_oper FLOAT,
			   org_id    VARCHAR(30) NULL)    
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATETABLE + ' #trxnums 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    CREATE UNIQUE CLUSTERED INDEX #trxnums_ind0 ON #trxnums (vendor_code, doc_ctrl_num)
	    INSERT #trxnums    
			(doc_ctrl_num,	 trx_ctrl_num,	vendor_code,
                         date_applied,	 nat_cur_code,	rate_type_home,
                         rate_type_oper, rate_home,	rate_oper,
			 org_id) 
            SELECT 	doc_ctrl_num, 	trx_ctrl_num, 	vendor_code, 
			datediff(dd, @January_First_Nineteen_Eighty, CONVERT(datetime,date_applied))+722815, nat_cur_code, rate_type_home, 
			rate_type_oper, rate_home, rate_oper, 
			org_id
                    FROM #imappyt_vw
                    WHERE processed_flag = 0    
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #trxnums 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    DECLARE trxnum_cursor CURSOR FOR
            SELECT     doc_ctrl_num, trx_ctrl_num, vendor_code, date_applied, nat_cur_code, rate_type_home, rate_type_oper, rate_home, rate_oper
            FROM     #trxnums
    OPEN trxnum_cursor
    FETCH NEXT 
            FROM trxnum_cursor
            INTO @doc_ctrl_num, @trx_ctrl_num, @vendor_code, @date_applied, @nat_cur_code, @rate_type_home, @rate_type_oper, @rate_home, @rate_oper
    WHILE (@@FETCH_STATUS <> -1)
        BEGIN
        IF @@FETCH_STATUS <> -2
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
                                            @ILSE_String = '',
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
                                            @ILSE_String = '',
                                            @ILSE_Procedure_Name = @Routine_Name,
                                            @ILSE_Log_Activity = 'YES',
                                            @im_log_sp_error_sp_User_ID = @userid
                    GOTO Error_Return
                    END    
                SELECT @updateflag = 1
            END
            IF DATALENGTH(LTRIM(RTRIM(ISNULL(@trx_ctrl_num, '')))) = 0
                BEGIN
                EXEC @SP_Result = apnewnum_sp 4111, 
                                              @company_code, 
                                              @trx_ctrl_num OUTPUT
                SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' apnewnum_sp 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
                IF NOT @SP_Result = 0
                    BEGIN
                    EXEC im_log_sp_error_sp @ILSE_Error_Code = @SP_Result,
                                            @ILSE_SP_Name = 'apnewnum_sp',
                                            @ILSE_String = '',
                                            @ILSE_Procedure_Name = @Routine_Name,
                                            @ILSE_Log_Activity = 'YES',
                                            @im_log_sp_error_sp_User_ID = @userid
                    GOTO Error_Return
                    END    
                SELECT @updateflag = 1
                END
            IF @updateflag = 1
                BEGIN
                UPDATE #trxnums
                        SET trx_ctrl_num = @trx_ctrl_num,
                            rate_home = @rate_home,
                            rate_oper = @rate_oper
                        WHERE CURRENT OF trxnum_cursor
                SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #trxnums 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
                END
            FETCH NEXT 
                   FROM trxnum_cursor
                   INTO @doc_ctrl_num, 
                        @trx_ctrl_num, 
                        @vendor_code, 
                        @date_applied, 
                        @nat_cur_code, 
                        @rate_type_home, 
                        @rate_type_oper, 
                        @rate_home, 
                        @rate_oper
        END
    END
    CLOSE trxnum_cursor
    DEALLOCATE trxnum_cursor
    BEGIN TRANSACTION 
    INSERT INTO #apinppyt 
            (trx_ctrl_num,    trx_type,       doc_ctrl_num,      trx_desc, 
             batch_code,      cash_acct_code, date_entered,      date_applied, 
             date_doc,        vendor_code,    pay_to_code,       approval_code, 
             payment_code,    payment_type,   amt_payment,       amt_on_acct, 
             posted_flag,     printed_flag,   hold_flag,         approval_flag, 
             gen_id,          user_id,        void_type,         amt_disc_taken, 
             print_batch_num, company_code,   process_group_num, nat_cur_code, 
             rate_type_home,  rate_type_oper, rate_home,         rate_oper,
	     org_id)
            SELECT a.trx_ctrl_num,   4111,             a.doc_ctrl_num,    trx_desc, 
                   '',               cash_acct_code,   @date_entered,     a.date_applied, 
                   datediff(dd, @January_First_Nineteen_Eighty, CONVERT(datetime,date_doc)) + 722815, a.vendor_code, ISNULL(pay_to_code, ''), approval_code,
                   payment_code,     payment_type,     amt_payment,       amt_on_account, 
                   0,                2,                0,                 approval_flag, 
                   0,                @Process_User_ID, 0,                 amt_discount, 
                   0,                @company_code,    @process_ctrl_num, a.nat_cur_code, 
                   a.rate_type_home, a.rate_type_oper, a.rate_home,       a.rate_oper,
		   a.org_id
            FROM #imappyt_vw, #trxnums a
            WHERE (processed_flag = 0 OR processed_flag IS NULL)
                    AND #imappyt_vw.vendor_code = a.vendor_code
                    AND #imappyt_vw.doc_ctrl_num = a.doc_ctrl_num
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #apinppyt 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #apinppdt 
            SET #apinppdt.trx_ctrl_num = b.trx_ctrl_num
            FROM #apinppdt #apinppdt, #apinppyt b
            WHERE #apinppdt.doc_ctrl_num = b.doc_ctrl_num
                    AND #apinppdt.vendor_code = b.vendor_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #apinppdt 4' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    COMMIT TRANSACTION 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_COMMIT + ' 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    DROP TABLE #trxnums
    




    SET @next_vendatn = ''
    WHILE 42 = 42
        BEGIN
        


        IF @debug_level >= 3
            BEGIN
            SELECT '(3): ' + @Routine_Name + ': #totals pseudo cursor: @next_vendatn = ' + RTRIM(ISNULL(@next_vendatn, ''))
            END
        SET ROWCOUNT 1
        SELECT @next_vendatn = RTRIM(vendor_code) + RTRIM(apply_to_num),
               @amt_applied = amt_applied,
               @amt_disc_taken = amt_disc_taken,
               @amt_net = amt_net,
               @vendor_code = vendor_code,
               @doc_ctrl_num = ''
                FROM #totals
                WHERE RTRIM(vendor_code) + RTRIM(apply_to_num) > ISNULL(RTRIM(@next_vendatn),'')
                ORDER BY RTRIM(vendor_code) + RTRIM(apply_to_num)
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' #totals 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        SET ROWCOUNT 0
        IF @Row_Count = 0
            BREAK
        



        IF ROUND(@amt_applied + @amt_disc_taken, @precision_gl) > ROUND(@amt_net, @precision_gl)
            BEGIN
            


            SELECT @amt_overcharge = ROUND(@amt_applied + @amt_disc_taken, @precision_gl) - ROUND(@amt_net, @precision_gl)
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @amt_overcharge 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            IF (@debug_level >= 3) 
                BEGIN
                SELECT @buf = '(3): ' + @Routine_Name + ': Vendor/ApplyTo ' + rtrim(ltrim(@next_vendatn)) + ' overpayed by ' + RTRIM(LTRIM(CONVERT(CHAR,@amt_overcharge)))
                SELECT @buf
                END
            



            IF @debug_level >= 3
                BEGIN
                SELECT '(3): ' + @Routine_Name + ': Payments pseudo cursor:'
                SELECT a.date_applied, 
                       b.amt_applied,
                       a.doc_ctrl_num,
                       a.vendor_code,
                       b.sequence_id
                        FROM #apinppyt a, #apinppdt b
                        WHERE a.doc_ctrl_num = b.doc_ctrl_num 
                                AND a.vendor_code = b.vendor_code 
                                AND b.vendor_code + b.apply_to_num = RTRIM(@next_vendatn)
                        ORDER BY a.date_applied DESC, 
                                 a.doc_ctrl_num DESC, 
                                 b.sequence_id DESC
            END
            DECLARE payCursor CURSOR FOR 
                    SELECT a.date_applied, 
                           b.amt_applied,
                           a.doc_ctrl_num,
                           a.vendor_code,
                           b.sequence_id
                    FROM #apinppyt a, #apinppdt b
                    WHERE a.doc_ctrl_num = b.doc_ctrl_num 
                            AND a.vendor_code = b.vendor_code 
                            AND b.vendor_code + b.apply_to_num = rtrim(@next_vendatn)
                    ORDER BY a.date_applied DESC, 
                             a.doc_ctrl_num DESC, 
                             b.sequence_id DESC
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DECLARE + ' payCursor 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            OPEN payCursor
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_OPEN + ' payCursor 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            FETCH NEXT 
                    FROM payCursor 
                    INTO @next_date_applied, 
                         @amt_applied,
                         @doc_ctrl_num, 
                         @vendor_code, 
                         @sequence_id
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_FETCHNEXT + ' payCursor 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            WHILE (@@FETCH_STATUS <> -1)
                BEGIN
                IF @@FETCH_STATUS <> -2
                    BEGIN
                    IF @debug_level >= 3
                        BEGIN
                        SELECT '(3): ' + @Routine_Name + ': next_date_applied = ' + @next_date_applied
                        SELECT 'amt_applied' = @amt_applied,
                               'doc_ctrl_num' = @doc_ctrl_num,
                               'vendor_code' = @vendor_code,
                               'sequence_id' = @sequence_id
                        END
                    


                
                    IF @amt_applied < @amt_overcharge
                        BEGIN
                        IF @debug_level >= 3 
                            BEGIN
                            SELECT '(3): ' + @Routine_Name + ':  ' + RTRIM(LTRIM(CONVERT(CHAR,@amt_applied))) + ' moved to on-account for vendor ' + RTRIM(@vendor_code) + ', document ' + RTRIM(@doc_ctrl_num)
                            END
                        UPDATE #apinppyt
                                SET amt_on_acct = amt_on_acct + @amt_applied
                                WHERE vendor_code = @vendor_code 
                                        AND doc_ctrl_num = @doc_ctrl_num
                        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #apinppyt 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
                        UPDATE #apinppdt
                                SET amt_applied = 0,
                                    vo_amt_applied = 0
                                WHERE vendor_code = @vendor_code
                                        AND doc_ctrl_num = @doc_ctrl_num
                                        AND sequence_id = @sequence_id
                        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #apinppdt 5' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
                        SELECT @amt_overcharge = @amt_overcharge - @amt_applied
                        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @amt_overcharge 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
                        END
                    ELSE
                        BEGIN
                        



                        IF @debug_level >= 3 
                            BEGIN
                            SELECT '(3): ' + @Routine_Name + ': ' + RTRIM(LTRIM(CONVERT(CHAR,@amt_overcharge))) + ' of ' + RTRIM(LTRIM(CONVERT(CHAR,@amt_applied))) + ' moved to on-account for vendor ' + RTRIM(@vendor_code) + ', document ' + RTRIM(@doc_ctrl_num)
                            END
                        UPDATE #apinppyt
                                SET amt_on_acct = amt_on_acct + @amt_overcharge
                                WHERE vendor_code = @vendor_code 
                                        AND doc_ctrl_num = @doc_ctrl_num
                        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #apinppyt 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
                        UPDATE #apinppdt
                                SET amt_applied = amt_applied - @amt_overcharge,
                                    vo_amt_applied = amt_applied - @amt_overcharge
                                WHERE vendor_code = @vendor_code
                                        AND doc_ctrl_num = @doc_ctrl_num
                                        AND sequence_id = @sequence_id
                        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #apinppdt 6' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
                        SELECT @amt_overcharge = 0
                        END
                    IF @amt_overcharge <=0
                        BREAK
                    END
                FETCH NEXT 
                        FROM payCursor 
                        INTO @next_date_applied, 
                             @amt_applied, 
                             @doc_ctrl_num, 
                             @vendor_code, 
                             @sequence_id
                SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_FETCHNEXT + ' payCursor 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
                END
            DEALLOCATE payCursor
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DEALLOCATE + ' payCursor 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            END
        END
    


    IF @debug_level >= 3
        BEGIN
        SELECT '(3): ' + @Routine_Name + ': Any records that appear after this line will be deleted because the entire payment was put on account:'
        SELECT b.* 
                FROM #apinppyt a, #apinppdt b 
                WHERE a.trx_ctrl_num = b.trx_ctrl_num
                        AND a.amt_payment = a.amt_on_acct
        END
    DELETE #apinppdt
            FROM #apinppyt #apinppyt, #apinppdt b
            WHERE #apinppyt.trx_ctrl_num = b.trx_ctrl_num
                    AND #apinppyt.amt_payment = #apinppyt.amt_on_acct
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DELETE + ' #apinppdt 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    






    IF @debug_level >= 3
        BEGIN
        SELECT '(3): ' + @Routine_Name + ': Copy records to the im# tables.'
        END
    INSERT INTO [CVO_Control]..im#imappyt 
            ([Import Identifier], [Import Company], [Import Date],
             company_code,        trx_ctrl_num,     doc_ctrl_num,
             trx_desc,            cash_acct_code,   date_applied,
             date_doc,            vendor_code,      pay_to_code,
             payment_code,        payment_type,     approval_code,
             approval_flag,       amt_on_account,   amt_payment,
             amt_discount,        nat_cur_code,     rate_type_home,
             rate_type_oper,      rate_home,        rate_oper,
             processed_flag,      date_processed,   [batch_no],
             [record_id_num],     [User_ID], 	    [org_id])
            SELECT @immakpay_sp_Import_Identifier, @company_code,  GETDATE(),
                   company_code,                   trx_ctrl_num,   doc_ctrl_num,
                   trx_desc,                       cash_acct_code, date_applied,
                   date_doc,                       vendor_code,    pay_to_code,
                   payment_code,                   payment_type,   approval_code,
                   approval_flag,                  amt_on_account, amt_payment,
                   amt_discount,                   nat_cur_code,   rate_type_home,
                   rate_type_oper,                 rate_home,      rate_oper,
                   processed_flag,                 date_processed, [batch_no],
                   [record_id_num],                [User_ID],	   [org_id]
                    FROM #imappyt_vw
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' [CVO_Control]..im#imappyt 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    INSERT INTO [CVO_Control]..im#imappdt 
            ([Import Identifier], [Import Company], [Import Date],
             company_code,        trx_ctrl_num,     doc_ctrl_num,
             sequence_id,         apply_to_num,     vendor_code,
             amt_applied,         amt_disc_taken,   line_desc,
             processed_flag,      [batch_no],       [record_id_num],
             [User_ID],		  [org_id])
            SELECT @immakpay_sp_Import_Identifier, @company_code,  GETDATE(),
                   company_code,                   trx_ctrl_num,   doc_ctrl_num,
                   sequence_id,                    apply_to_num,   vendor_code,
                   amt_applied,                    amt_disc_taken, line_desc,
                   processed_flag,                 [batch_no],     [record_id_num],
                   [User_ID],			   [org_id]		   
                    FROM #imappdt_vw
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' [CVO_Control]..im#imappdt 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    


    IF @immakpay_sp_trial_flag = 0
        BEGIN
        EXEC @errcode = appysav_sp @Process_User_ID, 
                                   NULL, 
                                   @debug_level
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' appysav_sp' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        IF NOT @errcode = 0
            BEGIN
            EXEC im_log_sp_error_sp @ILSE_Error_Code = @errcode,
                                    @ILSE_SP_Name = 'appysav_sp',
                                    @ILSE_String = '',
                                    @ILSE_Procedure_Name = @Routine_Name,
                                    @ILSE_Log_Activity = 'YES',
                                    @im_log_sp_error_sp_User_ID = @userid
            GOTO Error_Return
            END    
        


        UPDATE [imappyt_vw]
                SET [trx_ctrl_num] = b.[trx_ctrl_num],
                    [date_processed] = @date_processed,
                    [processed_flag] = 1
                FROM [imappyt_vw] a 
                INNER JOIN [apinppyt] b
                        ON a.[doc_ctrl_num] = b.[doc_ctrl_num]
                                AND a.[vendor_code] = b.[vendor_code]
                WHERE RTRIM(LTRIM(ISNULL(a.[company_code], ''))) = @company_code                
                        AND (NOT a.[processed_flag] = 1 OR a.[processed_flag] IS NULL)
                        AND (a.[User_ID] = @userid OR @userid = 0)
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imappyt_vw 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        UPDATE [imappdt_vw]
                SET [trx_ctrl_num] = b.[trx_ctrl_num], 
                    [processed_flag] = b.[processed_flag]
                FROM [imappdt_vw] a 
                INNER JOIN [imappyt_vw] b
                        ON a.[doc_ctrl_num] = b.[doc_ctrl_num]
                                AND a.[vendor_code] = b.[vendor_code]
                WHERE RTRIM(LTRIM(ISNULL(a.company_code, ''))) = @company_code                
                        AND (a.[User_ID] = @userid OR @userid = 0)
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imappdt_vw 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        


        IF EXISTS (SELECT 1 FROM apco WHERE batch_proc_flag = 1)
            BEGIN
            IF @debug_level >= 3
                SELECT '(3): ' + @Routine_Name + ': Updating batch descriptions and closing batches' 
            SELECT @complete_date = datediff(dd, @January_First_Nineteen_Eighty, CONVERT(datetime, GETDATE())) + 722815
            SELECT @complete_time = datepart(hh, GETDATE()) * 3600 + datepart(mi, GETDATE()) * 60 + datepart(ss, GETDATE())
            IF DATALENGTH(LTRIM(RTRIM(ISNULL(@immakpay_sp_User_Name, '')))) = 0
                SET @complete_user = SUSER_SNAME()
            ELSE    
                SET @complete_user = @immakpay_sp_User_Name
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @complete_date 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            SELECT @next_batch_code = ''
            WHILE (42 = 42)
                BEGIN
                SET ROWCOUNT 1
                SELECT DISTINCT @next_batch_code = a.batch_ctrl_num
                        FROM batchctl a, [CVO_Control]..imappyt b, apinppyt c
                        WHERE a.batch_ctrl_num = c.batch_code
                                AND b.doc_ctrl_num = c.doc_ctrl_num
                                AND b.vendor_code = c.vendor_code
                                AND RTRIM(LTRIM(ISNULL(b.company_code, ''))) = @company_code
                                AND b.processed_flag = 1                
                                AND c.batch_code > @next_batch_code
                        ORDER BY a.batch_ctrl_num
                SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @next_batch_code 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
                SET ROWCOUNT 0
                IF @Row_Count = 0
                    BEGIN
                    BREAK                
                    END
                SELECT @batch_count = COUNT(*),
                       @batch_total = SUM(amt_payment)
                        FROM apinppyt
                        WHERE batch_code = @next_batch_code
                SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' apinppyt 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
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
                    SELECT '(3): ' + @Routine_Name + ': batchctl WHERE batch_ctrl_num = ' + ISNULL(@next_batch_code, '') + ' AND TRIM(company_code) = ' + @company_code
                    SELECT * 
                            FROM [batchctl] 
                            WHERE batch_ctrl_num = @next_batch_code 
                                    AND RTRIM(LTRIM(ISNULL(company_code, ''))) = @company_code
                    END
                END
            IF @debug_level >= 3        
                SELECT '(3): ' + @Routine_Name + ': Done updating batch descriptions and closing batches' 
            END
        END    
    


    EXEC @SP_Result = pctrlupd_sp @process_ctrl_num ,3
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
GRANT EXECUTE ON  [dbo].[immakpay_sp] TO [public]
GO
