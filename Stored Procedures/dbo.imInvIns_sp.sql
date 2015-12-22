SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


    CREATE PROCEDURE 
[dbo].[imInvIns_sp] (@p_batchno INT = 0,
             @p_start_rec INT = 0,
             @p_end_rec INT = 0,
             @p_Dummy INT = 0,
             @debug_level INT = 0,
             @userid INT = 0)
    AS
    
    DECLARE @max_line_no INT
    DECLARE @uom CHAR(2)
    DECLARE @w_ins_count            int
    DECLARE @w_ins_loc_count        int
    DECLARE @w_temp                 int
    DECLARE @err_code               int
    DECLARE @w_cc VARCHAR(8)
    DECLARE @w_dmsg VARCHAR(255)
    DECLARE @w_emsg VARCHAR(255)
    DECLARE @cursrec_count        int
    DECLARE @cursrec_upd        int
    DECLARE @RECTYPE_INVMST         int
    DECLARE @RECTYPE_INVMST_BASE    int
    DECLARE @RECTYPE_INVMST_PURC    int
    DECLARE @RECTYPE_INVMST_COST    int
    DECLARE @RECTYPE_INVMST_PRIC    int
    DECLARE @RECTYPE_INVMST_ACCT    int
    DECLARE @stck_curs_Cursor_Allocated VARCHAR(3)
    DECLARE @stck_curs_Cursor_Opened VARCHAR(3)
    DECLARE @lbstck_curs_Cursor_Allocated VARCHAR(3)
    DECLARE @lbstck_curs_Cursor_Opened VARCHAR(3)
    DECLARE @RECTYPE_INVLOC         int
    DECLARE @RECTYPE_INVLOC_BASE    int
    DECLARE @RECTYPE_INVLOC_COST    int
    DECLARE @RECTYPE_INVLOC_STCK    int
    DECLARE @RECTYPE_INVBOM         int
    DECLARE @RECTYPE_INVLSB         int
    DECLARE @p_part_no VARCHAR(30)
    DECLARE @p_location VARCHAR(10)
    DECLARE @p_avg_cost DECIMAL(20, 8)
    DECLARE @p_who_entered VARCHAR(255)
    DECLARE @p_code VARCHAR(8)
    DECLARE @p_issue_date   datetime
    DECLARE @p_date_expires datetime
    DECLARE @p_note VARCHAR(80)
    DECLARE @p_qty DECIMAL(20, 8)
    DECLARE @p_inventory    char(1)
    DECLARE @p_bin_no VARCHAR(12)
    DECLARE @p_lot_ser VARCHAR(25)
    DECLARE @p_direction    int
    DECLARE @p_lb_tracking  char(1)
    DECLARE @p_direct_dolrs DECIMAL(20, 8)
    DECLARE @p_ovhd_dolrs DECIMAL(20, 8)
    DECLARE @p_util_dolrs DECIMAL(20, 8)
    DECLARE @p_labor DECIMAL(20, 8)
    DECLARE @p_status CHAR(1)
    DECLARE @p_issue_no INT
    DECLARE @p_record_id_num INT

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
    

    DELETE imlog WHERE UPPER(module) = 'INVENTORY' AND ([User_ID] = @userid OR @userid = 0)
    INSERT INTO imlog VALUES (getdate(), 'INVENTORY', 1, '', '', '', 'Inventory -- Begin (Copy) -- 7.3', @userid)
    
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
    

    --
    DECLARE @eBackOffice_Version VARCHAR(100)
    SET @eBackOffice_Version = '7.3'
    SELECT @eBackOffice_Version = RTRIM(LTRIM(ISNULL(UPPER([Text Value]), '')))
            FROM [CVO_Control]..[im_config] 
            WHERE RTRIM(LTRIM(ISNULL(UPPER([Item Name]), ''))) = 'EBACKOFFICE VERSION'
    IF @@ROWCOUNT = 0
            OR @eBackOffice_Version IS NULL
            OR (NOT @eBackOffice_Version = '7' AND NOT @eBackOffice_Version = '7.1' AND NOT @eBackOffice_Version = '7.2')
        SET @eBackOffice_Version = '7.3'
    IF @eBackOffice_Version = '7'
        BEGIN
        EXEC imInvIns_e7_sp @p_debug_level = @debug_level
        RETURN 0
        END
    --
    SET @Routine_Name = 'imInvIns_sp'
    SET @stck_curs_Cursor_Allocated = 'NO'
    SET @stck_curs_Cursor_Opened = 'NO'
    SET @lbstck_curs_Cursor_Allocated = 'NO'
    SET @lbstck_curs_Cursor_Opened = 'NO'
    SET @RECTYPE_INVMST_BASE    = 0x00000001
    SET @RECTYPE_INVMST_PURC    = 0x00000002
    SET @RECTYPE_INVMST_COST    = 0x00000004
    SET @RECTYPE_INVMST_PRIC    = 0x00000008
    SET @RECTYPE_INVMST_ACCT    = 0x00000010
    SET @RECTYPE_INVMST         = 0x0000001F
    SET @RECTYPE_INVLOC_BASE    = 0x00000100
    SET @RECTYPE_INVLOC_COST    = 0x00000200
    SET @RECTYPE_INVLOC_STCK    = 0x00000400
    SET @RECTYPE_INVLOC         = @RECTYPE_INVLOC_BASE + @RECTYPE_INVLOC_COST + @RECTYPE_INVLOC_STCK
    SET @RECTYPE_INVBOM         = 0x00001000
    SET @RECTYPE_INVLSB         = 0x00010000
    SELECT @w_cc = company_code FROM glco
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' glco 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    CREATE TABLE #tupd_stats (company_code VARCHAR(8),
                              section VARCHAR(30),
                              viewName VARCHAR(32),
                              viewDesc VARCHAR(40) null,
                              totRecs     int,
                              err_code    int,
                              updates     int null)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATETABLE + ' #tupd_stats 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    CREATE TABLE #temp_inv_list_ins (part_no VARCHAR(30) NOT NULL, 
                                     entered_who VARCHAR(20),
                                     void char(1), 
                                     location VARCHAR(20) NOT NULL, 
                                     std_cost DECIMAL(20, 8) NOT NULL, 
                                     std_direct_dolrs DECIMAL(20, 8), 
                                     std_ovhd_dolrs DECIMAL(20, 8), 
                                     std_util_dolrs DECIMAL(20, 8))
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATETABLE + ' #temp_inv_list_ins 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    CREATE TABLE #temp_inv_master_ins (part_no VARCHAR(30) NOT NULL, 
                                       description VARCHAR(255),
                                       price_a DECIMAL(20, 8) NOT NULL,
                                       status char(1) NOT NULL, 
                                       weight_ea DECIMAL(20, 8) NOT NULL, 
                                       entered_who VARCHAR(20), 
                                       taxable int, note VARCHAR(255), 
                                       void char(1))
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATETABLE + ' #temp_inv_master_ins 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    create table #t1 (record_id_num int)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATETABLE + ' #t1 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    create nonclustered index t1_key on #t1(record_id_num)
    IF @debug_level > 0
        BEGIN
        SELECT @p_batchno as Batch, @p_start_rec as Start_Record, @p_end_rec as End_Record
        END
    --
    -- Create table #t1 which will contain a list of record_id_num values of records to 
    -- be processed.  Note that due to the use of this table, this is one of the few places 
    -- that [User_ID] needs to be checked.
    --    
    IF @p_batchno > 0
        BEGIN
        INSERT INTO #t1
                SELECT record_id_num
                        FROM iminvmast_vw
                        WHERE company_code = @w_cc
                                AND process_status = 0
                                AND record_status_1 = 0
                                AND record_status_2 = 0
                                AND batch_no = @p_batchno
                                AND ([User_ID] = @userid OR @userid = 0)
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #t1 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        END
    ELSE
        BEGIN
        IF @p_end_rec > 0
            BEGIN
            INSERT INTO #t1
                    SELECT record_id_num
                            FROM iminvmast_vw
                            WHERE company_code = @w_cc
                                    AND process_status = 0
                                    AND record_status_1 = 0
                                    AND record_status_2 = 0
                                    AND record_id_num >= @p_start_rec
                                    AND record_id_num <= @p_end_rec
                                    AND ([User_ID] = @userid OR @userid = 0)
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #t1 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            END
        ELSE
            BEGIN
            INSERT INTO #t1
                    SELECT record_id_num
                            FROM iminvmast_vw
                            WHERE company_code = @w_cc
                                    AND process_status = 0
                                    AND record_status_1 = 0
                                    AND record_status_2 = 0
                                    AND record_id_num >= @p_start_rec
                                    AND ([User_ID] = @userid OR @userid = 0)
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #t1 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            END    
        END
    IF @debug_level > 0
        BEGIN
        SELECT @w_cc as company_code, @p_batchno as Batch, @p_start_rec as Start_Record, @p_end_rec as End_Record
        SELECT * FROM #t1
        END
    --
    -- The workbench won't call this stored procedure if there are no records available
    -- for copying, but this code will log a message if the workbench should be changed in the 
    -- future 
    --
    IF @Row_Count = 0
        BEGIN
        INSERT INTO imlog VALUES (getdate(), 'INVENTORY', 1, '', '', '', 'Inventory -- No records available for copying.', @userid)
        INSERT INTO imlog VALUES (getdate(), 'INVENTORY', 1, '', '', '', 'Inventory --     Records should have process_status = 0, record_status_1 = 0, and record_status_2 = 0.', @userid)
        INSERT INTO imlog VALUES (getdate(), 'INVENTORY', 1, '', '', '', 'Inventory --     This condition usually occurs when the validation has not been run', @userid)
        INSERT INTO imlog VALUES (getdate(), 'INVENTORY', 1, '', '', '', 'Inventory --     or the validation has flagged all records in error.', @userid)
        GOTO Exit_Return
        END    
    --
    SET @ROLLBACK_On_Error = 'YES' BEGIN TRANSACTION    
    --    
    -- Inventory master records
    --
    SELECT @w_ins_count = COUNT(*)
            FROM iminvmast_mstr_vw, #t1
            WHERE iminvmast_mstr_vw.record_id_num = #t1.record_id_num
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' iminvmast_mstr_vw 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    IF @debug_level > 0
        BEGIN
        SELECT 'Inserting ' + CAST(@w_ins_count AS VARCHAR) + ' inventory master records'
        END
    IF @w_ins_count > 0
        BEGIN
        SELECT @w_emsg = 'Inventory -- Error: Failed migration on inv_master'
        INSERT INTO #tupd_stats (company_code,section, viewName, viewDesc, totRecs, err_code)
                SELECT @w_cc,imwbtables_vw.section, imwbtables_vw.Name1,imwbtables_vw.description,@w_ins_count, 1
                FROM imwbtables_vw WHERE imwbtables_vw.Name1 = 'iminvmast_mstr_vw'
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #tupd_stats 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        INSERT INTO inv_master (part_no,         description,          uom, 
                                category,        type_code,            status,      
                                comm_type,       cycle_type,           inv_cost_method, 
                                freight_class,   lb_tracking,          cubic_feet,
                                weight_ea,       labor,                note, 
                                entered_who,     entered_date,         taxable, 
                                rpt_uom,         account,              sku_no,
                                warranty_length, call_limit,           yield_pct,                    
                                tolerance_cd,    pur_prod_flag,        sales_order_hold_flag, 
                                abc_code,        abc_code_frozen_flag, tax_code, 
                                allow_fractions, serial_flag,          upc_code,
                                cfg_flag,        qc_flag,              vendor,
                                buyer,           web_saleable_flag,    reg_prod,
                                [country_code],  [cmdty_code],         [height],
                                [width],         [length],             [min_profit_perc])
                SELECT imvw.part_no,               imvw.description,         imvw.uom,
                       imvw.category,              imvw.type_code,           imvw.status,
                       imvw.comm_type,             imvw.cycle_type,          imvw.inv_cost_method,
                       imvw.freight_class,         imvw.lb_tracking,         imvw.cubic_feet,
                       imvw.weight_ea,             imvw.labor,               imvw.note,
                       SYSTEM_USER,                GETDATE(),                taxable,
                       imvw.uom,                   account,                  imvw.[sku_code],
                       0,                          0,                        100,                
                       NULL,                       'N',                      0,                  
                       ISNULL(imvw.[abc_code], ''), ISNULL(imvw.[abc_code_frozen_flag], 0), imvw.tax_code,
                       imvw.allow_fractions,       imvw.serial_flag,         imvw.upc_code,
                       imvw.cfg_flag,              imvw.qc_flag,             imvw.vendor,
                       imvw.buyer,                 'N',                      'N',
                       imvw.[country_code],        imvw.[cmdty_code],        ISNULL(imvw.[height], 0),
                       ISNULL(imvw.[width], 0),    ISNULL(imvw.[length], 0), imvw.[min_profit_perc]
                        FROM dbo.iminvmast_mstr_vw imvw, #t1
                        WHERE imvw.record_id_num = #t1.record_id_num
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' inv_master 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        IF NOT @Row_Count = @w_ins_count
            BEGIN
            ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO'
            INSERT INTO [imlog]
                    ([now], [module], [text]) 
                    VALUES (GETDATE(), 'INVENTORY', @w_emsg + ', ' + CAST(@w_ins_count AS VARCHAR)) 
            GOTO Error_Return
            END      
        INSERT INTO part_price (part_no,    curr_key,           price_a,
                                price_b,    price_c,            price_d,  
                                price_e,    price_f,            qty_a,   
                                qty_b,      qty_c,              qty_d,
                                qty_e,      qty_f,              promo_type,  
                                promo_rate, promo_date_expires, promo_date_entered, 
                                promo_start_date)
                SELECT imvw.part_no,    imvw.curr_key,           imvw.price_a,
                       imvw.price_b,    imvw.price_c,            imvw.price_d,
                       imvw.price_e,    imvw.price_f,            imvw.qty_a,
                       imvw.qty_b,      imvw.qty_c,              imvw.qty_d,
                       imvw.qty_e,      imvw.qty_f,              imvw.promo_type,
                       imvw.promo_rate, imvw.promo_date_expires, imvw.promo_date_entered,
                       NULL
                        FROM dbo.iminvmast_mstr_vw imvw, #t1
                        WHERE imvw.record_id_num = #t1.record_id_num
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' part_price 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        IF NOT @Row_Count = @w_ins_count
            BEGIN
            ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO'
            INSERT INTO [imlog]
                    ([now], [module], [text], [User_ID]) 
                    VALUES (GETDATE(), 'INVENTORY', @w_emsg + CAST(@w_ins_count AS VARCHAR), @userid) 
            GOTO Error_Return
            END      
        UPDATE dbo.iminvmast_mstr_vw
                SET process_status = -1
                FROM iminvmast_mstr_vw, #t1
                WHERE iminvmast_mstr_vw.record_id_num = #t1.record_id_num
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_mstr_vw 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        UPDATE #tupd_stats
                SET updates = @w_temp
                WHERE err_code = 1
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #tupd_stats 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        END
    --    
    -- Inventory pricing
    --    
    SELECT @w_emsg = 'Inventory -- Error: Failed migration on inv_master (pricing updates)'
    SELECT @w_ins_loc_count = count(*)
            FROM iminvmast_pric_vw, #t1
            WHERE iminvmast_pric_vw.record_id_num = #t1.record_id_num
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' iminvmast_pric_vw 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    IF @debug_level > 0
        BEGIN
        SELECT 'Updating pricing info for ' + RTRIM(LTRIM(STR(@w_ins_loc_count))) + ' inventory master records'
        END
    IF @w_ins_loc_count > 0
        BEGIN
        INSERT INTO #tupd_stats (company_code,section, viewName, viewDesc, totRecs, err_code)
                SELECT @w_cc, section, Name1, description, @w_ins_loc_count, 2
                        FROM imwbtables_vw 
                        WHERE Name1 = 'iminvmast_pric_vw'
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #tupd_stats 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        CREATE TABLE #pp (part_no   VARCHAR(30)   NOT NULL,
                          curr_key VARCHAR(8)    DEFAULT '' NOT NULL,
                          price_a     DECIMAL(20, 8) DEFAULT 0 NOT NULL,
                          price_b     DECIMAL(20, 8) DEFAULT 0 NOT NULL,
                          price_c     DECIMAL(20, 8) DEFAULT 0 NOT NULL,
                          price_d     DECIMAL(20, 8) DEFAULT 0 NULL,
                          price_e     DECIMAL(20, 8) DEFAULT 0 NULL,
                          price_f     DECIMAL(20, 8) DEFAULT 0 NULL,
                          qty_a       DECIMAL(20, 8) DEFAULT 0 NULL,
                          qty_b       DECIMAL(20, 8) DEFAULT 0 NULL,
                          qty_c       DECIMAL(20, 8) DEFAULT 0 NULL,
                          qty_d       DECIMAL(20, 8) DEFAULT 0 NULL,
                          qty_e       DECIMAL(20, 8) DEFAULT 0 NULL,
                          qty_f       DECIMAL(20, 8) DEFAULT 0 NULL,
                          promo_type           char(1)       DEFAULT 'N' NULL,
                          promo_rate  DECIMAL(20, 8) DEFAULT 0 NULL,
                          promo_date_expires   datetime      NULL,
                          promo_date_entered   datetime      NULL,
                          flg int)
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATETABLE + ' #pp 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        INSERT INTO #pp
                SELECT p.part_no,
                       p.curr_key,
                       p.price_a,
                       p.price_b,
                       p.price_c,
                       p.price_d,
                       p.price_e,
                       p.price_f,
                       p.qty_a,
                       p.qty_b,
                       p.qty_c,
                       p.qty_d,
                       p.qty_e,
                       p.qty_f,
                       p.promo_type,
                       p.promo_rate,
                       p.promo_date_expires,
                       p.promo_date_entered,
                       0
                        FROM dbo.iminvmast_pric_vw p, #t1
                        WHERE p.record_id_num = #t1.record_id_num
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #pp 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        UPDATE #pp
                SET flg = 1
                FROM #pp , part_price p
                WHERE #pp.part_no = p.part_no
                        AND #pp.curr_key = p.curr_key
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #pp 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        INSERT INTO part_price
                (part_no,
                 curr_key,
                 price_a,
                 price_b,
                 price_c,
                 price_d,
                 price_e,
                 price_f,
                 qty_a,
                 qty_b,
                 qty_c,
                 qty_d,
                 qty_e,
                 qty_f,
                 promo_type,
                 promo_rate,
                 promo_date_expires,
                 promo_date_entered,
                 promo_date_start)                -- Matthew Sparks 2001/7/2 SCR 1053
                SELECT part_no,
                       curr_key,
                       price_a,
                       price_b,
                       price_c,
                       price_d,
                       price_e,
                       price_f,
                       qty_a,
                       qty_b,
                       qty_c,
                       qty_d,
                       qty_e,
                       qty_f,
                       promo_type,
                       promo_rate,
                       promo_date_expires,
                       promo_date_entered,
                       NULL                           -- Matthew Sparks 2001/7/2 SCR 1053 
                        FROM #pp
                        WHERE flg = 0
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' part_price 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        DROP TABLE #pp
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DROPTABLE + ' #pp 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        UPDATE part_price
                SET price_a = iminvmast_pric_vw.price_a,
                    price_b = iminvmast_pric_vw.price_b,
                    price_c = iminvmast_pric_vw.price_c,
                    price_d = iminvmast_pric_vw.price_d,
                    price_e = iminvmast_pric_vw.price_e,
                    price_f = iminvmast_pric_vw.price_f,
                    qty_a = iminvmast_pric_vw.qty_a,
                    qty_b = iminvmast_pric_vw.qty_b,
                    qty_c = iminvmast_pric_vw.qty_c,
                    qty_d = iminvmast_pric_vw.qty_d,
                    qty_e = iminvmast_pric_vw.qty_e,
                    qty_f = iminvmast_pric_vw.qty_f
                FROM iminvmast_pric_vw, #t1
                WHERE part_price.part_no = iminvmast_pric_vw.part_no
                        AND part_price.curr_key = iminvmast_pric_vw.curr_key
                        AND iminvmast_pric_vw.record_id_num = #t1.record_id_num
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' part_price 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        IF NOT @Row_Count = @w_ins_loc_count
            BEGIN
            ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO'
            INSERT INTO [imlog]
                    ([now], [module], [text], [User_ID]) 
                    VALUES (GETDATE(), 'INVENTORY', @w_emsg + CAST(@w_ins_count AS VARCHAR), @userid) 
            GOTO Error_Return
            END      
        UPDATE iminvmast_pric_vw
                SET process_status = -1
                FROM iminvmast_pric_vw, #t1
                WHERE iminvmast_pric_vw.record_id_num = #t1.record_id_num
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_proc_vw 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        UPDATE #tupd_stats
                SET updates = @w_temp
                WHERE err_code  = 2
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #tupd_stats 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        END
    --    
    -- Inventory Locations (inv_list)
    --    
    SELECT @w_emsg = 'Inventory -- Error: Failed migration on inv_list'
    SELECT @w_ins_loc_count = count(*)
            FROM iminvmast_loc_vw, #t1
            WHERE iminvmast_loc_vw.record_id_num = #t1.record_id_num
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' iminvmast_loc_vw 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    IF @debug_level > 0
        BEGIN
        SELECT 'Inserting ' + RTRIM(LTRIM(STR(@w_ins_loc_count))) + ' inventory location records'
        END
    IF @w_ins_loc_count > 0
        BEGIN
        INSERT INTO #tupd_stats (company_code,section, viewName, viewDesc, totRecs, err_code)
                SELECT @w_cc, section, Name1, description, @w_ins_loc_count, 3
                FROM imwbtables_vw 
                WHERE Name1 = 'iminvmast_loc_vw'
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #tupd_stats 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        INSERT INTO inv_list (part_no,          location,             lead_time,
                              note,             eoq,                  hold_qty,
                              in_stock,         issued_mtd,           issued_ytd,
                              max_stock,        min_stock,            min_order,
                              qty_year_end,     qty_month_end,        qty_physical,
                              labor,            std_cost,             std_direct_dolrs,
                              std_ovhd_dolrs,   std_util_dolrs,       avg_cost,
                              avg_direct_dolrs, avg_ovhd_dolrs,       avg_util_dolrs,
                              entered_who,      entered_date,         setup_labor,
                              cycle_date,       status,               acct_code,
                              bin_no,           dock_to_stock,        order_multiple,
                              abc_code,         abc_code_frozen_flag, po_uom,
                              so_uom)
                SELECT part_no,              location,           lead_time,
                       loc_note,             eoq,                hold_qty,
                       0,                    issued_mtd,         issued_ytd,
                       max_stock,            min_stock,          min_order,
                       qty_year_end,         qty_month_end,      qty_physical,
                       loc_labor,            loc_std_cost,       loc_std_direct_dolrs,
                       loc_std_ovhd_dolrs,   loc_std_util_dolrs, loc_avg_cost,
                       loc_avg_direct_dolrs, loc_avg_ovhd_dolrs, loc_avg_util_dolrs,
                       SYSTEM_USER,          GETDATE(),          0,
                       cycle_date,           status,             acct_code,
                       bin_no,               0,                  0,
                       ISNULL([abc_code], ''),  ISNULL([abc_code_frozen_flag], 0), ISNULL([po_uom], ''),
                       ISNULL([so_uom], '')
                        FROM iminvmast_loc_vw, #t1
                        WHERE iminvmast_loc_vw.record_id_num = #t1.record_id_num
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' inv_list 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        IF NOT @Row_Count = @w_ins_loc_count
            BEGIN
            ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO'
            INSERT INTO [imlog]
                    ([now], [module], [text], [User_ID]) 
                    VALUES (GETDATE(), 'INVENTORY', @w_emsg + CAST(@w_ins_loc_count AS VARCHAR), @userid) 
            GOTO Error_Return
            END      
        --
        -- process_status set to -1 so that the following section to import stock
        -- balances will still be executed.
        --    
        UPDATE dbo.iminvmast_loc_vw
                SET process_status = -1
                FROM iminvmast_loc_vw, #t1
                WHERE iminvmast_loc_vw.record_id_num = #t1.record_id_num
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_loc_vw 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        UPDATE #tupd_stats
                SET updates = @w_temp
                WHERE err_code  = 3
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #tupd_stats 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        END
    --    
    -- Inventory stock balances (lb_tracking = 'N')
    --    
    SELECT @w_emsg = 'Inventory -- Error: Failed migration on stock balances not lb_tracked (issues)'
    declare stck_curs insensitive cursor for
            SELECT l.part_no,
                   l.location,
                   l.loc_avg_cost,
                   SYSTEM_USER,
                   l.code,
                   getdate() as issue_date,
                   'Import Manager Inventory Adjustment',
                   l.in_stock,
                   'N' as inventory,
                   'N/A' as bin_no,
                   'N/A' as lot_ser,
                   1  as direction,
                   im.lb_tracking,
                   l.loc_avg_direct_dolrs,
                   l.loc_avg_ovhd_dolrs,
                   l.loc_avg_util_dolrs,
                   l.loc_labor,
                   'T' as status,
                   l.record_id_num
                    FROM iminvmast_vw l, inv_list il, inv_master im, #t1
                    WHERE l.record_id_num = #t1.record_id_num
                            AND (l.record_type & @RECTYPE_INVLOC_STCK) > 0
                            AND l.part_no = il.part_no
                            AND l.location = il.location
                            AND l.part_no = im.part_no
                            AND im.lb_tracking = 'N'
                            AND l.in_stock > 0
            for read only
    SET @stck_curs_Cursor_Allocated = 'YES'
    SELECT @cursrec_upd = 0,
           @cursrec_count = 0
    open stck_curs
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_OPEN + ' stck_curs 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    SET @stck_curs_Cursor_Opened = 'YES'
    fetch next 
            FROM stck_curs
            INTO @p_part_no,
                 @p_location,
                 @p_avg_cost,
                 @p_who_entered,
                 @p_code,
                 @p_issue_date,
                 @p_note,
                 @p_qty,
                 @p_inventory,
                 @p_bin_no,
                 @p_lot_ser,
                 @p_direction,
                 @p_lb_tracking,
                 @p_direct_dolrs,
                 @p_ovhd_dolrs,
                 @p_util_dolrs,
                 @p_labor,
                 @p_status,
                 @p_record_id_num
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_FETCHNEXT + ' stck_curs 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    while @@fetch_status <> -1
        BEGIN
        SELECT @p_issue_no = last_no + 1
                FROM next_iss_no
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' next_iss_no 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        UPDATE  next_iss_no
            SET last_no = @p_issue_no
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' next_iss_no 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        SELECT     @cursrec_count = @cursrec_count + 1
        INSERT issues 
                (issue_no,
                 part_no,
                 location_from,
                 avg_cost,
                 who_entered,
                 code,
                 issue_date,
                 note,
                 qty,
                 inventory,
                 direction,
                 lb_tracking,
                 direct_dolrs,
                 ovhd_dolrs,
                 util_dolrs,
                 labor,
                 status)
                VALUES (@p_issue_no,
                        @p_part_no,
                        @p_location,
                        @p_avg_cost,
                        @p_who_entered,
                        @p_code,
                        @p_issue_date,
                        @p_note,
                        @p_qty,
                        @p_inventory,
                        @p_direction,
                        @p_lb_tracking,
                        @p_direct_dolrs,
                        @p_ovhd_dolrs,
                        @p_util_dolrs,
                        @p_labor,
                        @p_status)
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' issues 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        IF @Row_Count < 1
            BEGIN
            ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO'
            INSERT INTO [imlog]
                    ([now], [module], [text], [User_ID]) 
                    VALUES (GETDATE(), 'INVENTORY', @w_emsg, @userid) 
            GOTO Error_Return
            END      
        SELECT @cursrec_upd = @cursrec_upd + 1
        UPDATE iminvmast_vw
                SET process_status = -1
                WHERE record_id_num = @p_record_id_num
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_vw 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        FETCH NEXT
                FROM stck_curs
                INTO @p_part_no,
                     @p_location,
                     @p_avg_cost,
                     @p_who_entered,
                     @p_code,
                     @p_issue_date,
                     @p_note,
                     @p_qty,
                     @p_inventory,
                     @p_bin_no,
                     @p_lot_ser,
                     @p_direction,
                     @p_lb_tracking,
                     @p_direct_dolrs,
                     @p_ovhd_dolrs,
                     @p_util_dolrs,
                     @p_labor,
                     @p_status,
                     @p_record_id_num
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_FETCHNEXT + ' stck_curs 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        END
    CLOSE stck_curs
    SET @stck_curs_Cursor_Opened = 'NO'
    DEALLOCATE stck_curs
    SET @stck_curs_Cursor_Allocated = 'NO'
    IF @cursrec_count > 0
        BEGIN
        INSERT INTO #tupd_stats (company_code,section, viewName, viewDesc, totRecs, err_code,updates)
                SELECT @w_cc, section, Name1, description, @cursrec_count, 4, @cursrec_upd
                FROM imwbtables_vw 
                WHERE Name1 = 'iminvmast_loc_vw'
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #tupd_stats 4' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        END
    --    
    UPDATE iminvmast_vw
            SET process_status = 1
            WHERE company_code = @w_cc
                    AND process_status = -1
                    AND ([User_ID] = @userid OR @userid = 0)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_vw 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --    
    -- Bills of Material (what_part)
    --    
    SELECT @w_emsg = 'Inventory -- Error: Failed migration on what_part'
    SELECT @w_ins_loc_count = count(*)
            FROM iminvmast_bom_vw, #t1
            WHERE iminvmast_bom_vw.record_id_num = #t1.record_id_num
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' iminvmast_bom_vw 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    IF @debug_level > 0
        BEGIN
        SELECT 'Inserting ' + RTRIM(LTRIM(STR(@w_ins_loc_count))) + ' BOM records'
        END
    IF @w_ins_loc_count > 0
        BEGIN
        INSERT INTO #tupd_stats (company_code,section, viewName, viewDesc, totRecs, err_code)
                SELECT @w_cc, section, Name1, description, @w_ins_loc_count, 5
                FROM imwbtables_vw 
                WHERE Name1 = 'iminvmast_bom_vw'
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #tupd_stats 5' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        INSERT INTO dbo.what_part
                (asm_no,
                 uom,
                 location,
                 part_no,
                 seq_no,
                 qty,
                 lag_qty,
                 pool_qty,
                 plan_pcs,
                 active,
                 constrain,
                 fixed,
                 conv_factor,
                 eff_date,
                 date_entered,
                 who_entered,
                 bench_stock,
                 attrib)
                SELECT part_no,
                       uom,
                       location,
                       bom_part_no,
                       bom_seq_no,
                       bom_qty,
                       bom_lag_qty,
                       bom_pool_qty,
                       bom_plan_pcs,
                       bom_active_flag,
                       bom_constrain,
                       bom_fixed,
                       bom_conv_factor,
                       bom_eff_date,
                       getdate(),
                       SYSTEM_USER,
                       'N',
                       1.0
                        FROM iminvmast_bom_vw, #t1
                        WHERE iminvmast_bom_vw.record_id_num = #t1.record_id_num
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' what_part 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        IF NOT @Row_Count = @w_ins_loc_count
            BEGIN
            ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO'
            INSERT INTO [imlog]
                    ([now], [module], [text], [User_ID]) 
                    VALUES (GETDATE(), 'INVENTORY', @w_emsg + CAST(@w_ins_loc_count AS VARCHAR), @userid) 
            GOTO Error_Return
            END      
        UPDATE dbo.iminvmast_bom_vw
                SET process_status = 1
                FROM iminvmast_bom_vw, #t1
                WHERE iminvmast_bom_vw.record_id_num = #t1.record_id_num
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_bom_vw 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        UPDATE #tupd_stats
                SET updates = @w_temp
                WHERE err_code  = 5
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #tupd_stats 4' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        END
    --    
    -- Inventory stock balances (lb_tracking = 'Y')
    --    
    SELECT @w_emsg = 'Inventory -- Error: Failed migration on stock balances lb_tracked (iminvmast_lbs_vw -- >issues)'
    SELECT @cursrec_upd = 0, @cursrec_count = 0
    DECLARE lbstck_curs INSENSITIVE CURSOR FOR
            SELECT lbs.part_no,
                   lbs.location,
                   lbs.loc_avg_cost,
                   lbs.code,
                   lbs.lbs_date_tran,
                   lbs.lbs_qty,
                   lbs.status,
                   lbs.lbs_bin_no,
                   lbs.lbs_lot_ser,
                   1 as direction,
                   lbs.lb_tracking,
                   lbs.lbs_date_expires,
                   lbs.loc_avg_direct_dolrs,
                   lbs.loc_avg_ovhd_dolrs,
                   lbs.loc_avg_util_dolrs,
                   lbs.loc_labor,
                   lbs.record_id_num,
                   lbs.uom
                    FROM iminvmast_lbs_vw lbs, #t1
                    WHERE lbs.record_id_num = #t1.record_id_num
                            AND lbs.lb_tracking = 'Y'
            FOR READ ONLY
    SET @lbstck_curs_Cursor_Allocated = 'YES'
    OPEN lbstck_curs
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_OPEN + ' lbstck_curs 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    SET @lbstck_curs_Cursor_Opened = 'YES'
    FETCH NEXT 
            FROM lbstck_curs
            INTO @p_part_no,
                 @p_location,
                 @p_avg_cost,
                 @p_code,
                 @p_issue_date,
                 @p_qty,
                 @p_inventory,
                 @p_bin_no,
                 @p_lot_ser,
                 @p_direction,
                 @p_lb_tracking,
                 @p_date_expires,
                 @p_direct_dolrs,
                 @p_ovhd_dolrs,
                 @p_util_dolrs,
                 @p_labor,
                 @p_record_id_num,
                 @uom
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_FETCHNEXT + ' lbstck_curs 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    WHILE @@fetch_status <> -1
        BEGIN
        SELECT @p_issue_no = last_no+1
                FROM next_iss_no
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' next_iss_no 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        UPDATE next_iss_no
                SET last_no = @p_issue_no
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' next_iss_no 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        SELECT @cursrec_count = @cursrec_count + 1
        INSERT issues (issue_no,   part_no,     location_from,
                       avg_cost,   who_entered, code,
                       issue_date, qty,         inventory,
                       direction,  lb_tracking, direct_dolrs,
                       ovhd_dolrs, util_dolrs,  labor)
                VALUES (@p_issue_no,   @p_part_no,     @p_location,
                        @p_avg_cost,   SYSTEM_USER,    @p_code,
                        @p_issue_date, @p_qty,         @p_inventory,
                        @p_direction,  @p_lb_tracking, @p_direct_dolrs,
                        @p_ovhd_dolrs, @p_util_dolrs,  @p_labor)
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' issues 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        SELECT @max_line_no = ISNULL(MAX(line_no), 0) + 1
                FROM lot_serial_bin_issue
                WHERE tran_no = @p_issue_no
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' lot_serial_bin_issue 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        --
        -- Some lot/bin/stock notes: The lot_bin_stock table is ONLY updated through INSERTs 
        -- on the lot_bin_tran table, and the lot_bin_tran table is updated by inserting
        -- records into the lot_serial_bin_issue table.  Triggers on these two tables
        -- effect the updating of lot_bin_stock.  The lot_bin_stock table holds the current
        -- lot bin inventory for a part; it shows on the Lot/Bin tab on the Inventory screen
        -- in eBackOffice.
        --
        INSERT INTO lot_serial_bin_issue (line_no,     tran_no,   tran_ext,  
                                          part_no,     location,  bin_no,  
                                          tran_code,   date_tran, date_expires, 
                                          qty,         direction, uom,
                                          conv_factor, who,       cost,
                                          lot_ser,     uom_qty)                                                                                                                                                                                                                                                    
                VALUES (@max_line_no, @p_issue_no,   0,
                        @p_part_no,   @p_location,   @p_bin_no,   
                        'I',          @p_issue_date, @p_date_expires, 
                        @p_qty,       @p_direction , @uom,
                        1.0,          SYSTEM_USER,   @p_avg_cost,  
                        @p_lot_ser,   NULL)                                                                                                                                                                                                                                                   
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' lot_serial_bin_issue 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        SELECT @cursrec_upd = @cursrec_upd + 1
        UPDATE     iminvmast_lbs_vw
                SET process_status = 1
                WHERE record_id_num = @p_record_id_num
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_lbs_vw 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        fetch next 
                FROM lbstck_curs
                INTO @p_part_no,
                     @p_location,
                     @p_avg_cost,
                     @p_code,
                     @p_issue_date,
                     @p_qty,
                     @p_inventory,
                     @p_bin_no,
                     @p_lot_ser,
                     @p_direction,
                     @p_lb_tracking,
                     @p_date_expires,
                     @p_direct_dolrs,
                     @p_ovhd_dolrs,
                     @p_util_dolrs,
                     @p_labor,
                     @p_record_id_num,
                     @uom
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_FETCHNEXT + ' lbstck_curs 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        END
    close lbstck_curs
    SET @lbstck_curs_Cursor_Opened = 'NO'
    deallocate lbstck_curs
    SET @lbstck_curs_Cursor_Allocated = 'NO'
    IF @cursrec_count > 0
        BEGIN
        INSERT INTO #tupd_stats (company_code,section, viewName, viewDesc, totRecs, err_code,updates)
                SELECT @w_cc, section, Name1, description, @cursrec_count, @err_code, @cursrec_upd
                FROM imwbtables_vw 
                WHERE Name1 = 'iminvmast_lbs_vw'
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #tupd_stats 6' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        END
    --    
    IF @ROLLBACK_On_Error = 'YES' BEGIN COMMIT TRANSACTION SET @ROLLBACK_On_Error = 'NO' END
    INSERT INTO imlog 
            SELECT getdate(), 'INVENTORY', 1, '', '', '', 'Inventory ' + RTRIM(LTRIM(ISNULL(ISNULL(viewDesc, ''), ''))) + ', Total Records: ' + CAST(ISNULL(totRecs, 0) AS VARCHAR) + ', Updates: ' + CAST(ISNULL(updates, 0) AS VARCHAR), @userid
            FROM #tupd_stats
Exit_Return:    
    DROP TABLE #tupd_stats        
    DROP TABLE #temp_inv_list_ins
    DROP TABLE #temp_inv_master_ins
    INSERT INTO imlog VALUES (getdate(), 'INVENTORY', 1, '', '', '', 'Inventory -- End', @userid)
    RETURN 0
Error_Return:
    IF @stck_curs_Cursor_Opened = 'YES'
        CLOSE stck_curs
    IF @lbstck_curs_Cursor_Opened = 'YES'
        CLOSE lbstck_curs
    IF @stck_curs_Cursor_Allocated = 'YES'
        DEALLOCATE stck_curs
    IF @lbstck_curs_Cursor_Allocated = 'YES'
        DEALLOCATE lbstck_curs
    INSERT INTO imlog VALUES (getdate(), 'INVENTORY', 1, '', '', '', 'Inventory -- End (ERROR)', @userid)
    RETURN -1    
GO
GRANT EXECUTE ON  [dbo].[imInvIns_sp] TO [public]
GO
