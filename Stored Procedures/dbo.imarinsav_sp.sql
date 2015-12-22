SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

    
    CREATE PROCEDURE 
[dbo].[imarinsav_sp] @proc_user_id SMALLINT, 
             @new_batch_code VARCHAR(16) OUTPUT,
             @debug_level SMALLINT = 0,
             @userid INT = 0,
             @imarinsav_sp_process_group_num VARCHAR(16)
    AS 
    DECLARE @tran_started smallint,
            @batch_module_id smallint,
            @batch_date_applied int,
            @batch_source varchar(16),
            @batch_trx_type smallint,
            @trx_type smallint,
            @home_company varchar(8),
            @result smallint,
            @cus_flag smallint,
            @shp_flag smallint,
            @prc_flag smallint,
            @ter_flag smallint,
            @slp_flag smallint,
            @bat_count int 
    BEGIN
    
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
    

    SET @Routine_Name = 'imarinsav_sp'
    
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
    SELECT @tran_started = 0 
    SELECT @new_batch_code = ' '
    SELECT @home_company = company_code
            FROM glco
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' glco' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    IF EXISTS(SELECT * FROM arco WHERE batch_proc_flag = 1)
        BEGIN 
        INSERT #arinbat (date_applied, process_group_num, trx_type,
                         flag,         batch_ctrl_num)
                SELECT DISTINCT date_applied, @imarinsav_sp_process_group_num, trx_type,
                                0,            ''
                        FROM #arinpchg 
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #arinbat' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
        SELECT @bat_count = COUNT(*)
                FROM #arinbat
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' #arinbat' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
        WHILE @bat_count > 0
            BEGIN
            INSERT INTO #arbatnum (date_applied, process_group_num, trx_type,
                                   flag)
                    SELECT date_applied, process_group_num, trx_type,
                           flag
                            FROM #arinbat
                            WHERE flag = 0 
            EXEC ARCreateBatchBlock_SP @proc_user_id
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' ARCreateBatchBlock_SP' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
            UPDATE #arinbat
                    SET batch_ctrl_num = batnum.batch_ctrl_num, 
                        flag = batnum.flag
                    FROM #arbatnum batnum
                    WHERE batnum.flag = 1
                            AND batnum.date_applied = #arinbat.date_applied 
                            AND batnum.process_group_num = #arinbat.process_group_num
                            AND batnum.trx_type = #arinbat.trx_type 
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #arinbat' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
            DELETE #arbatnum
            SELECT @bat_count = COUNT(*)
                    FROM #arinbat
                    WHERE flag = 0 
            END
        UPDATE #arinpchg
                SET batch_code = batch_ctrl_num
                FROM #arinbat
                WHERE #arinbat.date_applied = #arinpchg.date_applied 
                        AND #arinbat.process_group_num = #arinpchg.process_group_num
                        AND #arinbat.trx_type = #arinpchg.trx_type 
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #arinpchg 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
        INSERT INTO #arbatsum (batch_ctrl_num, actual_number, actual_total)
                SELECT batch_code, COUNT(*), SUM(amt_net)
                        FROM #arinpchg
                        GROUP BY batch_code
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #arbatsum' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
        UPDATE batchctl
                SET actual_number = batsum.actual_number, 
                    actual_total = batsum.actual_total
                FROM #arbatsum batsum
                WHERE batsum.batch_ctrl_num = batchctl.batch_ctrl_num 
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' batchctl' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
        DELETE #arbatsum
        SET ROWCOUNT 1
        SELECT @new_batch_code = batch_ctrl_num 
                FROM #arinbat
        SET ROWCOUNT 0
        END
    ELSE
        BEGIN
        UPDATE #arinpchg
                SET batch_code = ''
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #arinpchg 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
        END
    SET ROWCOUNT 1
    SELECT @trx_type = trx_type
            FROM #arinpchg
    SET ROWCOUNT 0
    IF @@TRANCOUNT = 0
        BEGIN
        BEGIN TRANSACTION 
        SELECT @tran_started = 1
        END
    IF @trx_type = 2031
        BEGIN
        EXEC @result = arinupa_sp 2000 
        IF @result != 0
            BEGIN
            IF @tran_started = 1
                ROLLBACK TRAN
            RETURN @result
            END
        END
    INSERT arinpage (trx_ctrl_num,  sequence_id,      doc_ctrl_num,
                     apply_to_num,  apply_trx_type,   trx_type,
                     date_applied,  date_due,         date_aging,
                     customer_code, salesperson_code, territory_code,
                     price_code,    amt_due)
            SELECT trx_ctrl_num,  sequence_id,      doc_ctrl_num,
                   apply_to_num,  apply_trx_type,   trx_type,
                   date_applied,  date_due,         date_aging,
                   customer_code, salesperson_code, territory_code,
                   price_code,    amt_due  
                    FROM #arinpage  
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' arinpage' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    INSERT arinpcdt (trx_ctrl_num,      doc_ctrl_num,    sequence_id,
                     trx_type,          location_code,   item_code,
                     bulk_flag,         date_entered,    line_desc,
                     qty_ordered,       qty_shipped,     unit_code,
                     unit_price,        unit_cost,       weight,
                     serial_id,         tax_code,        gl_rev_acct,
                     disc_prc_flag,     discount_amt,    commission_flag,
                     rma_num,           return_code,     qty_returned,
                     qty_prev_returned, new_gl_rev_acct, iv_post_flag,
                     oe_orig_flag,      extended_price,  discount_prc,
                     calc_tax,          reference_code,  cust_po,
					 org_id)										
            SELECT trx_ctrl_num,      doc_ctrl_num,    sequence_id,
                   trx_type,          location_code,   item_code,
                   bulk_flag,         date_entered,    line_desc,
                   qty_ordered,       qty_shipped,     unit_code,
                   unit_price,        unit_cost,       weight,
                   serial_id,         tax_code,        gl_rev_acct,
                   disc_prc_flag,     discount_amt,    commission_flag,
                   rma_num,           return_code,     qty_returned,
                   qty_prev_returned, new_gl_rev_acct, iv_post_flag,
                   oe_orig_flag,      extended_price,  discount_prc,
                   calc_tax,          reference_code,  cust_po,
				   org_id										
                    FROM #arinpcdt
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' arinpcdt' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    INSERT arinpchg (trx_ctrl_num,        doc_ctrl_num,     doc_desc,
                     apply_to_num,        apply_trx_type,   order_ctrl_num,
                     batch_code,          trx_type,         date_entered,
                     date_applied,        date_doc,         date_shipped,
                     date_required,       date_due,         date_aging,
                     customer_code,       ship_to_code,     salesperson_code,
                     territory_code,      comment_code,     fob_code,
                     freight_code,        terms_code,       fin_chg_code,
                     price_code,          dest_zone_code,   posting_code,
                     recurring_flag,      recurring_code,   tax_code,
                     cust_po_num,         total_weight,     amt_gross,
                     amt_freight,         amt_tax,          amt_discount,
                     amt_net,             amt_paid,         amt_due,
                     amt_cost,            amt_profit,       next_serial_id,
                     printed_flag,        posted_flag,      hold_flag,
                     hold_desc,           user_id,          customer_addr1,
                     customer_addr2,      customer_addr3,   customer_addr4,
                     customer_addr5,      customer_addr6,   ship_to_addr1,
                     ship_to_addr2,       ship_to_addr3,    ship_to_addr4,
                     ship_to_addr5,       ship_to_addr6,    attention_name,
                     attention_phone,     amt_rem_rev,      amt_rem_tax,
                     date_recurring,      location_code,    process_group_num,
                     source_trx_ctrl_num, source_trx_type,  amt_discount_taken,
                     amt_write_off_given, nat_cur_code,     rate_type_home,
                     rate_type_oper,      rate_home,        rate_oper,
                     edit_list_flag,      amt_tax_included, ddid,
                     writeoff_code,       vat_prc,			org_id)					
            SELECT trx_ctrl_num,        doc_ctrl_num,     doc_desc,
                   apply_to_num,        apply_trx_type,   order_ctrl_num,
                   batch_code,          trx_type,         date_entered,
                   date_applied,        date_doc,         date_shipped,
                   date_required,       date_due,         date_aging,
                   customer_code,       ship_to_code,     salesperson_code,
                   territory_code,      comment_code,     fob_code,
                   freight_code,        terms_code,       fin_chg_code,
                   price_code,          dest_zone_code,   posting_code,
                   recurring_flag,      recurring_code,   tax_code,
                   cust_po_num,         total_weight,     amt_gross,
                   amt_freight,         amt_tax,          amt_discount,
                   amt_net,             amt_paid,         amt_due,
                   amt_cost,            amt_profit,       next_serial_id,
                   printed_flag,        posted_flag,      hold_flag,
                   hold_desc,           user_id,          customer_addr1,
                   customer_addr2,      customer_addr3,   customer_addr4,
                   customer_addr5,      customer_addr6,   ship_to_addr1,
                   ship_to_addr2,       ship_to_addr3,    ship_to_addr4,
                   ship_to_addr5,       ship_to_addr6,    attention_name,
                   attention_phone,     amt_rem_rev,      amt_rem_tax,
                   date_recurring,      location_code,    '',
                   source_trx_ctrl_num, source_trx_type,  amt_discount_taken,
                   amt_write_off_given, nat_cur_code,     rate_type_home,
                   rate_type_oper,      rate_home,        rate_oper,
                   edit_list_flag,      amt_tax_included, ddid,
                   writeoff_code,       vat_prc,		  org_id					
                    FROM #arinpchg
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' arinpchg' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    INSERT arinpcom (trx_ctrl_num,     trx_type,       sequence_id,
                     salesperson_code, amt_commission, percent_flag,
                     exclusive_flag,   split_flag)
            SELECT trx_ctrl_num,     trx_type,       sequence_id,
                   salesperson_code, amt_commission, percent_flag,
                   exclusive_flag,   split_flag
                    FROM #arinpcom 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' arinpcom' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    INSERT arinptax (trx_ctrl_num,  trx_type,    sequence_id,
                     tax_type_code, amt_taxable, amt_gross,
                     amt_tax,       amt_final_tax)
            SELECT trx_ctrl_num,  trx_type,    sequence_id,
                   tax_type_code, amt_taxable, amt_gross,
                   amt_tax,       amt_final_tax 
                    FROM #arinptax
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' arinptax' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    INSERT arinptmp (trx_ctrl_num,   doc_ctrl_num,   date_doc,
                     customer_code,  payment_code,   amt_payment,
                     amt_disc_taken, cash_acct_code, trx_desc,
                     prompt1_inp,    prompt2_inp,    prompt3_inp,
                     prompt4_inp)
            SELECT trx_ctrl_num,   doc_ctrl_num,   date_doc,
                   customer_code,  payment_code,   amt_payment,
                   amt_disc_taken, cash_acct_code, trx_desc,
                   prompt1_inp,    prompt2_inp,    prompt3_inp,
                   prompt4_inp
                    FROM #arinptmp
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' arinptmp' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    EXEC @result = arinusv_sp 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' arinusav_sp' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    DELETE #arinpchg
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DELETE + ' #arinpchg' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    DELETE #arinpcdt   
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DELETE + ' #arinpcdt' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    DELETE #arinpage
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DELETE + ' #arinpage' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    DELETE #arinptax 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DELETE + ' #arinptax' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    DELETE #arinptmp  
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DELETE + ' #arinptmp' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    DELETE #arinbat  
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DELETE + ' #arinbat' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    IF @tran_started = 1
        BEGIN
        COMMIT TRANSACTION
        SELECT @tran_started = 0
        END 
    RETURN 0
Error_Return:
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': Exit (ERROR).'
    RETURN -1
    END    
GO
GRANT EXECUTE ON  [dbo].[imarinsav_sp] TO [public]
GO
