SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


    CREATE PROCEDURE
[dbo].[imincrh_sp] @module_id SMALLINT,
           @val_mode SMALLINT,
           @trx_ctrl_num VARCHAR(16) OUTPUT,
           @doc_ctrl_num VARCHAR(16),
           @doc_desc VARCHAR(40),
           @apply_to_num VARCHAR(16),
           @apply_trx_type SMALLINT,
           @order_ctrl_num VARCHAR(16),
           @batch_code VARCHAR(16),
           @trx_type SMALLINT,
           @date_entered            int,
           @date_applied            int,
           @date_doc            int,
           @date_shipped            int,
           @date_required        int,
           @date_due            int,
           @date_aging            int,
           @customer_code VARCHAR(8),
           @ship_to_code VARCHAR(8),
           @salesperson_code VARCHAR(8),
           @territory_code VARCHAR(8),
           @comment_code VARCHAR(8),
           @fob_code VARCHAR(8),
           @freight_code VARCHAR(8),
           @terms_code VARCHAR(8),
           @fin_chg_code VARCHAR(8),
           @price_code VARCHAR(8),
           @dest_zone_code VARCHAR(8),
           @posting_code VARCHAR(8),
           @recurring_flag SMALLINT,
           @recurring_code VARCHAR(8),
           @tax_code VARCHAR(8),
           @cust_po_num VARCHAR(20),
           @total_weight FLOAT,
           @amt_gross FLOAT,
           @amt_freight FLOAT,
           @amt_tax FLOAT,
           @amt_discount FLOAT,
           @amt_net FLOAT,
           @amt_paid FLOAT,
           @amt_due FLOAT,
           @amt_cost FLOAT,
           @amt_profit FLOAT,
           @next_serial_id SMALLINT,
           @printed_flag SMALLINT,
           @posted_flag SMALLINT,
           @hold_flag SMALLINT,
           @hold_desc VARCHAR(40),
           @user_id SMALLINT,
           @customer_addr1 VARCHAR(40),
           @customer_addr2 VARCHAR(40),
           @customer_addr3 VARCHAR(40),
           @customer_addr4 VARCHAR(40),
           @customer_addr5 VARCHAR(40),
           @customer_addr6 VARCHAR(40),
           @ship_to_addr1 VARCHAR(40),
           @ship_to_addr2 VARCHAR(40),
           @ship_to_addr3 VARCHAR(40),
           @ship_to_addr4 VARCHAR(40),
           @ship_to_addr5 VARCHAR(40),
           @ship_to_addr6 VARCHAR(40),
           @attention_name VARCHAR(40),
           @attention_phone VARCHAR(30),
           @amt_rem_rev FLOAT,
           @amt_rem_tax FLOAT,
           @date_recurring        int,
           @location_code VARCHAR(8),
           @process_group_num VARCHAR(16),
           @amt_discount_taken FLOAT = 0.0,
           @amt_write_off_given FLOAT = 0.0,
           @source_trx_ctrl_num VARCHAR(16) = '',
           @source_trx_type SMALLINT = 0,
           @nat_cur_code VARCHAR(8),            
           @rate_type_home VARCHAR(8),        
           @rate_type_oper VARCHAR(8),
           @amt_tax_included FLOAT,
           @rate_home FLOAT = 0,
           @rate_oper FLOAT = 0,
           @debug_level SMALLINT = 0,
           @userid INT = 0,
           @writeoff_code VARCHAR(8),
           @vat_prc FLOAT,
           @org_id	varchar(30)				
    AS
    DECLARE @result        int,
            @divide_flag_h SMALLINT,
            @divide_flag_o SMALLINT,
            @home_currency VARCHAR(8),
            @oper_currency VARCHAR(8)            
    DECLARE @day INT        
    DECLARE @month INT        
    DECLARE @rate_date INT
    DECLARE @year INT
    
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
    


    SET NOCOUNT ON
    SET @Routine_Name = 'imincrh_sp'
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': Entry.'
    IF (@val_mode NOT IN (1, 2))
        BEGIN
        IF @debug_level >= 3
            SELECT '(3): ' + @Routine_Name + ': Invalid @val_mode.'
        GOTO Error_Return
        END
    SELECT @home_currency = home_currency,
           @oper_currency = oper_currency
            FROM glco    
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' glco 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END     
    SELECT @rate_date = NULL
    IF @trx_type = 2032 
            AND @apply_to_num <> ''
        BEGIN
        SELECT @rate_date = date_applied
                FROM artrx
                WHERE doc_ctrl_num = @apply_to_num
                        AND customer_code = @customer_code
                        AND trx_type = 2031
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' artrx 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END     
        END 
    IF @rate_date IS NULL
        SELECT @rate_date = @date_applied
    


    IF @rate_home = 0
        BEGIN
        EXEC @result = [CVO_Control]..mccurate_sp @date_applied,
                                               @nat_cur_code,    
                                               @home_currency,        
                                               @rate_type_home,    
                                               @rate_home OUTPUT,
                                               0,
                                               @divide_flag_h OUTPUT
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' [CVO_Control]..mccurate_sp 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        IF NOT @result = 0
                OR @rate_home IS NULL
            BEGIN    
            SELECT @rate_home = 0
            EXEC @SP_Result = appdtjul_sp @year OUTPUT, 
                                          @month OUTPUT, 
                                          @day OUTPUT, 
                                          @date_applied
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' appdtjul_sp 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = 'mccurate_sp error part 1', @IGES_String = @External_String_1 OUT
            EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = 'mccurate_sp error part 2', @IGES_String = @External_String_2 OUT
            SET @External_String = @External_String_1 + ' ' + @Routine_Name + @External_String_2 + ' rate_home: ' + @nat_cur_code + '/' + @home_currency + '/' + @rate_type_home + '/' + CAST(@year AS VARCHAR) + '-' + CAST(@month AS VARCHAR) + '-' + CAST(@day AS VARCHAR)
            EXEC im_log_sp @External_String, 
                           'YES',
                           @userid
            END
        END
    IF @rate_oper = 0
        BEGIN
        EXEC @result = [CVO_Control]..mccurate_sp @date_applied,
                                               @nat_cur_code,    
                                               @oper_currency,        
                                               @rate_type_oper,    
                                               @rate_oper OUTPUT,
                                               0,
                                               @divide_flag_o OUTPUT
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' [CVO_Control]..mccurate_sp 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        IF NOT @result = 0
                OR @rate_oper IS NULL
            BEGIN    
            SELECT @rate_oper = 0
            EXEC @SP_Result = appdtjul_sp @year OUTPUT, 
                                          @month OUTPUT, 
                                          @day OUTPUT, 
                                          @date_applied
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' appdtjul_sp 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = 'mccurate_sp error part 1', @IGES_String = @External_String_1 OUT
            EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = 'mccurate_sp error part 2', @IGES_String = @External_String_2 OUT
            SET @External_String = @External_String_1 + ' ' + @Routine_Name + @External_String_2 + ' rate_oper: ' + @nat_cur_code + '/' + @oper_currency + '/' + @rate_type_oper + '/' + CAST(@year AS VARCHAR) + '-' + CAST(@month AS VARCHAR) + '-' + CAST(@day AS VARCHAR)
            EXEC im_log_sp @External_String, 
                           'YES',
                           @userid
            END
        END
    



    IF DATALENGTH(LTRIM(RTRIM(ISNULL(@trx_ctrl_num, '')))) = 0
        BEGIN
        EXEC @SP_Result = arnewnum_sp @trx_type,  
                                      @trx_ctrl_num OUTPUT
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' arnewnum_sp' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        IF NOT @SP_Result = 0
            BEGIN
            EXEC im_log_sp_error_sp @ILSE_Error_Code = @SP_Result,
                                    @ILSE_SP_Name = 'arnewnum_sp',
                                    @ILSE_String = '',
                                    @ILSE_Procedure_Name = @Routine_Name,
                                    @ILSE_Log_Activity = 'YES',
                                    @im_log_sp_error_sp_User_ID = @userid
            GOTO Error_Return
            END    
        END
    


    INSERT #arinpchg (trx_ctrl_num,        doc_ctrl_num,        doc_desc,
                      apply_to_num,        apply_trx_type,      order_ctrl_num,
                      batch_code,          trx_type,            date_entered,
                      date_applied,        date_doc,            date_shipped,
                      date_required,       date_due,            date_aging,
                      customer_code,       ship_to_code,        salesperson_code,
                      territory_code,      comment_code,        fob_code,
                      freight_code,        terms_code,          fin_chg_code,
                      price_code,          dest_zone_code,      posting_code,
                      recurring_flag,      recurring_code,      tax_code,
                      cust_po_num,         total_weight,        amt_gross,
                      amt_freight,         amt_tax,             amt_discount,
                      amt_net,             amt_paid,            amt_due,                
                      amt_cost,            amt_profit,          next_serial_id,
                      printed_flag,        posted_flag,         hold_flag,
                      hold_desc,           user_id,             customer_addr1,
                      customer_addr2,      customer_addr3,      customer_addr4,
                      customer_addr5,      customer_addr6,      ship_to_addr1,
                      ship_to_addr2,       ship_to_addr3,       ship_to_addr4,
                      ship_to_addr5,       ship_to_addr6,       attention_name,
                      attention_phone,     amt_rem_rev,         amt_rem_tax,
                      date_recurring,      location_code,       process_group_num,
                      trx_state,           mark_flag,           amt_discount_taken,
                      amt_write_off_given, source_trx_ctrl_num, source_trx_type,
                      nat_cur_code,        rate_type_home,      rate_type_oper,
                      rate_home,           rate_oper,           edit_list_flag,      
                      amt_tax_included,    writeoff_code,       vat_prc,
					  org_id)     															
            VALUES (@trx_ctrl_num,        @doc_ctrl_num,        @doc_desc,
                    @apply_to_num,        @apply_trx_type,      @order_ctrl_num,
                    @batch_code,          @trx_type,            @date_entered,
                    @date_applied,        @date_doc,            @date_shipped,
                    @date_required,       @date_due,            @date_aging,
                    @customer_code,       @ship_to_code,        @salesperson_code,
                    @territory_code,      @comment_code,        @fob_code,
                    @freight_code,        @terms_code,          @fin_chg_code,
                    @price_code,          @dest_zone_code,      @posting_code,
                    @recurring_flag,      @recurring_code,      @tax_code,
                    @cust_po_num,         @total_weight,        @amt_gross,
                    @amt_freight,         @amt_tax,             @amt_discount,
                    @amt_net,             @amt_paid,            @amt_due,
                    @amt_cost,            @amt_profit,          @next_serial_id,
                    @printed_flag,        @posted_flag,         @hold_flag,
                    @hold_desc,           @user_id,             @customer_addr1,
                    @customer_addr2,      @customer_addr3,      @customer_addr4,
                    @customer_addr5,      @customer_addr6,      @ship_to_addr1,
                    @ship_to_addr2,       @ship_to_addr3,       @ship_to_addr4,
                    @ship_to_addr5,       @ship_to_addr6,       @attention_name,
                    @attention_phone,     @amt_rem_rev,         @amt_rem_tax,
                    @date_recurring,      @location_code,       @process_group_num,
                    0,           0,                    @amt_discount_taken,
                    @amt_write_off_given, @source_trx_ctrl_num, @source_trx_type,
                    @nat_cur_code,        @rate_type_home,      @rate_type_oper,
                    @rate_home,           @rate_oper,           0,
                    @amt_tax_included,    @writeoff_code,       @vat_prc,
					@org_id)     															
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #arinpchg 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END     
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': Exit.'
    RETURN 0
Error_Return:
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': Exit (ERROR).'
    RETURN -1    
GO
GRANT EXECUTE ON  [dbo].[imincrh_sp] TO [public]
GO
