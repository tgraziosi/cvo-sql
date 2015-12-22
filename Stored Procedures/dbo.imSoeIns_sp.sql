SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


    create procedure 
[dbo].[imSoeIns_sp] (@p_batchno INT = 0,
             @p_start_rec INT = 0,
             @p_end_rec INT = 0,
             @p_Dummy INT = 0,
             @debug_level INT = 0,
             @userid INT = 0) 
    as
    DECLARE @Automatically_Assign_Order_Numbers VARCHAR(100)
    DECLARE @err_code INT
    DECLARE @Header_Record_Count INT
    DECLARE @hdr_cursor_Cursor_Allocated VARCHAR(3)
    DECLARE @hdr_cursor_Cursor_Opened VARCHAR(3)
    DECLARE @hdr_cursor_order_no INT 
    DECLARE @hdr_cursor_record_id_num INT
    DECLARE @last_no INT
    DECLARE @lin_cursor_Cursor_Allocated VARCHAR(3)
    DECLARE @lin_cursor_Cursor_Opened VARCHAR(3)
    DECLARE @New_order_no INT
    DECLARE @p003 INT
    DECLARE @p005 INT
    DECLARE @RECTYPE_OE_HDR INT
    DECLARE @RECTYPE_OE_LINE INT
    DECLARE @w_cc VARCHAR(8)
    DECLARE @w_dmsg VARCHAR(255)
    DECLARE @w_hdr_order_no INT
    DECLARE @w_hdr_record_id_num INT
    DECLARE @w_i_wrk INT
    DECLARE @w_lin_record_id_num INT
    DECLARE @w_julian INT
    DECLARE @w_date_entered DATETIME
    DECLARE @w_cust_code VARCHAR(10)
    DECLARE @w_lin_upd_count INT
    DECLARE @w_cursrec_count INT
    DECLARE @w_cursrec_upd INT
    DECLARE @w_cursrec_dtl_count INT
    DECLARE @w_cursrec_dtl_upd INT

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
    

    DELETE imlog WHERE UPPER(module) = 'SO' AND ([User_ID] = @userid OR @userid = 0)
    INSERT INTO imlog VALUES (GETDATE(), 'SO', 1, '', '', '', 'Sales Order -- Begin (Copy) -- 7.3 Service Pack 1', @userid) 
    
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
        EXEC imSoeIns_e7_sp @p_batchno = @p_batchno,
                            @p_start_rec = @p_start_rec,
                            @p_end_rec = @p_end_rec,
                            @p_debug_level = @debug_level
        RETURN 0
        END
    --
    CREATE TABLE [#adm_taxinfo]
            (row_id INT IDENTITY,
             control_number VARCHAR(16) NOT NULL,
             reference_number INT NOT NULL,
             trx_type INT NOT NULL DEFAULT(0),
             currency_code    VARCHAR(8),
             curr_precision INT,
             amt_tax FLOAT DEFAULT(0),
             amt_final_tax FLOAT DEFAULT(0),
             tax_code VARCHAR(8),
             freight FLOAT DEFAULT(0),
             qty FLOAT DEFAULT(1),
             unit_price FLOAT DEFAULT(0),
             extended_price FLOAT DEFAULT(0),
             amt_discount FLOAT DEFAULT(0),
             err_no INT DEFAULT(0),
             action_flag INT DEFAULT(0),
             seqid INT,
             calc_tax FLOAT DEFAULT(0),
             vat_prc FLOAT DEFAULT(0))
    CREATE INDEX [adm_ti1]
            ON [#adm_taxinfo] (row_id)
    CREATE INDEX [adm_ti2]
            ON [#adm_taxinfo] (control_number, reference_number)
    CREATE TABLE [#adm_taxtype]
            (row_id INT IDENTITY,
             ttr_row INT,
             tax_type VARCHAR(8),
             ext_amt FLOAT,
             amt_gross FLOAT,
             amt_taxable FLOAT,
             amt_tax FLOAT,
             amt_final_tax FLOAT,
             amt_tax_included FLOAT,
             save_flag INT,
             tax_rate FLOAT,
             prc_flag INT,
             prc_type INT,
             cents_code_flag INT,
             cents_code VARCHAR(8),
             cents_cnt INT,
             tax_based_type INT,
             tax_included_flag INT,
             modify_base_prc FLOAT,
             base_range_flag INT,
             base_range_type INT,
             base_taxed_type INT,
             min_base_amt FLOAT,
             max_base_amt FLOAT,
             tax_range_flag INT,
             tax_range_type INT,
             min_tax_amt FLOAT,
             max_tax_amt FLOAT)
    CREATE INDEX [adm_tt1]
            ON [#adm_taxtype] (row_id)
    CREATE INDEX [adm_tt2]
            ON [#adm_taxtype] (ttr_row)
    CREATE TABLE [#adm_taxtyperec]
            (row_id INT IDENTITY,
             tc_row INT,
             tax_code VARCHAR(8),
             seq_id INT,
             base_id INT,
             cur_amt FLOAT,
             old_tax FLOAT,
             tax_type VARCHAR(8))
    CREATE INDEX [adm_ttr1]
            ON [#adm_taxtyperec] (row_id)
    CREATE INDEX [adm_ttr2]
            ON [#adm_taxtyperec] (tc_row)
    CREATE INDEX [adm_ttr3]
            ON [#adm_taxtyperec] (tax_code, tc_row, seq_id)
    CREATE TABLE [#adm_taxcode]
            (row_id INT IDENTITY,
             ti_row INT,
             control_number VARCHAR(16),
             tax_code VARCHAR(8),
             amt_tax FLOAT,
             tax_included_flag INT,
             tax_type_cnt INT)
    CREATE INDEX [adm_tc1]
            ON [#adm_taxcode] (row_id)
    CREATE INDEX [adm_tc2]
            ON [#adm_taxcode] (control_number, tax_code)
    CREATE TABLE [#cents]
            (row_id INT IDENTITY,
             cents_code VARCHAR(8),
             to_cent FLOAT,
             tax_cents FLOAT)
    CREATE INDEX [c1]
            ON [#cents] (cents_code, row_id)
    --        
    SET @Routine_Name = 'imSoeIns_sp'
    SET @hdr_cursor_Cursor_Allocated = 'NO'
    SET @hdr_cursor_Cursor_Opened = 'NO'
    SET @lin_cursor_Cursor_Allocated = 'NO'
    SET @lin_cursor_Cursor_Opened = 'NO'
    SET @RECTYPE_OE_HDR = 1
    SET @RECTYPE_OE_LINE = 2
    SELECT @w_cc = [company_code] 
            FROM [glco]
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' glco 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Get the "automatically assign numbers" configuration entry.
    --
    SET @Automatically_Assign_Order_Numbers = 'NO'
    IF EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'im_config')
        BEGIN
        SELECT @Automatically_Assign_Order_Numbers = RTRIM(LTRIM(ISNULL(UPPER([Text Value]), '')))
                FROM [im_config] 
                WHERE RTRIM(LTRIM(ISNULL(UPPER([Item Name]), ''))) = 'AUTOMATICALLY ASSIGN SALES ORDER NUMBERS'
        IF @@ROWCOUNT = 0
                OR @Automatically_Assign_Order_Numbers IS NULL
                OR (NOT @Automatically_Assign_Order_Numbers = 'NO' AND NOT @Automatically_Assign_Order_Numbers = 'YES' AND NOT @Automatically_Assign_Order_Numbers = 'TRUE' AND NOT @Automatically_Assign_Order_Numbers = 'FALSE')
            SET @Automatically_Assign_Order_Numbers = 'NO'
        IF @Automatically_Assign_Order_Numbers = 'TRUE'
            SET @Automatically_Assign_Order_Numbers = 'YES'
        END
    CREATE TABLE #t1 (record_id_num int constraint imsoe_t1_key unique nonclustered (record_id_num))
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATETABLE + ' #t1 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    CREATE TABLE #tupd_stats (company_code varchar(8),
                              section    varchar(30),
                              viewName varchar(32),
                              viewDesc varchar(40) null,
                              totRecs int,
                              updates int null)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATETABLE + ' #tupd_stats 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    CREATE TABLE #temp_orders_ins (order_no int NOT NULL, 
                                   ext int NOT NULL, 
                                   status char (1) NOT NULL)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATETABLE + ' #temp_orders_ins 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    CREATE TABLE #temp_orders_del (order_no int NOT NULL, 
                                   ext int NOT NULL, 
                                   status char (1) NOT NULL)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATETABLE + ' #temp_orders_del 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    CREATE TABLE #temp_ord_list_ins (order_no int NOT NULL , 
                                   order_ext int NOT NULL ,
                                   line_no int NOT NULL, 
                                   shipped decimal(20,8) NOT NULL, 
                                   price decimal(20,8) NOT NULL)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATETABLE + ' #temp_ord_list_ins 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    CREATE TABLE #temp_ord_list_del (order_no int NOT NULL ,
                                     order_ext int NOT NULL ,
                                     line_no int NOT NULL,
                                     shipped decimal(20,8) NOT NULL,
                                     price decimal(20,8) NOT NULL)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATETABLE + ' #temp_ord_list_del 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    IF @debug_level > 0
        BEGIN
        SELECT @p_batchno as Batch, @p_start_rec as Start_Record, @p_end_rec as End_Record
        end
    --
    -- Create table #t1 which will contain a list of record_id_num values of records to 
    -- be processed.  Note that due to the use of this table, this is one of the few places 
    -- that [User_ID] needs to be checked.
    --    
    IF @p_batchno > 0
        BEGIN
        INSERT INTO #t1
                SELECT record_id_num
                FROM imsoe_vw
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
                    FROM imsoe_vw
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
                    FROM imsoe_vw
                    WHERE company_code = @w_cc
                            AND process_status = 0
                            AND record_status_1 = 0
                            AND record_status_2 = 0
                            AND record_id_num >= @p_start_rec
                            AND ([User_ID] = @userid OR @userid = 0)
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #t1 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            END
        END
    if @debug_level > 0
        BEGIN
        SELECT @p_batchno as Batch, @p_start_rec as Start_Record, @p_end_rec as End_Record
        SELECT * FROM #t1
        SELECT count(*) as valid_recs,record_type
                FROM imsoe_vw, #t1
                WHERE imsoe_vw.record_id_num = #t1.record_id_num
                GROUP BY record_type
        END
    --
    -- The workbench won't call this stored procedure if there are no records available
    -- for copying, but this code will log a message if the workbench should be changed in the 
    -- future 
    --
    IF @Row_Count = 0
        BEGIN
        INSERT INTO imlog VALUES (GETDATE(), 'SO', 1, '', '', '', 'Sales Order -- No records available for copying.', @userid)
        INSERT INTO imlog VALUES (GETDATE(), 'SO', 1, '', '', '', 'Sales Order --     Records should have process_status = 0, record_status_1 = 0, and record_status_2 = 0.', @userid)
        INSERT INTO imlog VALUES (GETDATE(), 'SO', 1, '', '', '', 'Sales Order --     This condition usually occurs when the validation has not been run', @userid)
        INSERT INTO imlog VALUES (GETDATE(), 'SO', 1, '', '', '', 'Sales Order --     or the validation has flagged all records in error.', @userid)
        GOTO Exit_Return
        END    
    SET @ROLLBACK_On_Error = 'YES' BEGIN TRANSACTION    
    --
    -- Assign order numbers in three steps.
    --
    IF @Automatically_Assign_Order_Numbers = 'YES'
        BEGIN
        --
        -- First, reassign all order numbers so they're in a range that's outside
        -- the range of the final sequence.  This will insure that the second step
        -- won't encounter any values that are already within the final sequence.
        -- Note that the UPDATE statement will update both header and line records at the 
        -- same time.
        --
        SELECT @New_order_no = MAX([imsoe_hdr_vw].[order_no])
                FROM [imsoe_hdr_vw]                 
                INNER JOIN [#t1]
                        ON [imsoe_hdr_vw].[record_id_num] = [#t1].[record_id_num]
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' imsoe_hdr_vw 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        SELECT @Header_Record_Count = COUNT(*)
                FROM [imsoe_hdr_vw]                 
                INNER JOIN [#t1]
                        ON [imsoe_hdr_vw].[record_id_num] = [#t1].[record_id_num]
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' #t1 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        SELECT @last_no = ISNULL([last_no], 0)
                FROM [next_order_num]
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' next_order_num 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        IF NOT @New_order_no > (@last_no + @Header_Record_Count + 1)
            SET @New_order_no = @last_no + @Header_Record_Count + 1
        DECLARE [hdr_cursor] CURSOR FOR
                SELECT imsoe_hdr_vw.order_no, 
                       imsoe_hdr_vw.record_id_num
                        FROM [imsoe_hdr_vw]
                        INNER JOIN [#t1]
                                ON [imsoe_hdr_vw].[record_id_num] = [#t1].[record_id_num]
                        ORDER BY [imsoe_hdr_vw].[order_no] DESC
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DECLARE + ' hdr_cursor 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        SET @hdr_cursor_Cursor_Allocated = 'YES'
        OPEN [hdr_cursor]
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_OPEN + ' hdr_cursor 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        SET @hdr_cursor_Cursor_Opened = 'YES'
        FETCH NEXT 
                FROM hdr_cursor
                INTO @hdr_cursor_order_no, 
                     @hdr_cursor_record_id_num
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_FETCHNEXT + ' hdr_cursor 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        --
        -- Note that imsoe_vw is updated rather than imsoe_hdr_vw so that an update
        -- is made to both header and line tables.
        --
        WHILE NOT @@FETCH_STATUS = -1
            BEGIN
            SET @New_order_no = @New_order_no + 1
            UPDATE [imsoe_vw]
                    SET [order_no] = @New_order_no
                    FROM [imsoe_vw]
                    INNER JOIN [#t1]    
                            ON [imsoe_vw].[record_id_num] = [#t1].[record_id_num]
                    WHERE [imsoe_vw].[order_no] = @hdr_cursor_order_no
                            AND ([imsoe_vw].[record_type] = @RECTYPE_OE_HDR OR [imsoe_vw].[record_type] = @RECTYPE_OE_LINE)
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_vw 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            FETCH NEXT 
                    FROM [hdr_cursor]
                    INTO @hdr_cursor_order_no, 
                         @hdr_cursor_record_id_num
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_FETCHNEXT + ' hdr_cursor 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            END    
        CLOSE [hdr_cursor]
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CLOSE + ' hdr_cursor 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        SET @hdr_cursor_Cursor_Opened = 'NO'
        DEALLOCATE [hdr_cursor]
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DEALLOCATE + ' hdr_cursor 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        SET @hdr_cursor_Cursor_Allocated = 'NO'
        --
        -- Second, reassign all order numbers so they're in the final sequence.
        --
        DECLARE [hdr_cursor] CURSOR FOR
                SELECT imsoe_hdr_vw.order_no, 
                       imsoe_hdr_vw.record_id_num
                        FROM [imsoe_hdr_vw]
                        INNER JOIN [#t1]
                                ON [imsoe_hdr_vw].[record_id_num] = [#t1].[record_id_num]
                        ORDER BY [imsoe_hdr_vw].[order_no] DESC
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DECLARE + ' hdr_cursor 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        SET @hdr_cursor_Cursor_Allocated = 'YES'
        OPEN [hdr_cursor]
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_OPEN + ' hdr_cursor 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        SET @hdr_cursor_Cursor_Opened = 'YES'
        FETCH NEXT 
                FROM hdr_cursor
                INTO @hdr_cursor_order_no, 
                     @hdr_cursor_record_id_num
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_FETCHNEXT + ' hdr_cursor 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        WHILE NOT @@FETCH_STATUS = -1
            BEGIN
            --
            -- Note again that imsoe_vw is updated rather than imsoe_hdr_vw so that an update
            -- is made to both header and line tables.
            --
            SET @last_no = @last_no + 1
            UPDATE [imsoe_vw]
                    SET [order_no] = @last_no
                    FROM [imsoe_vw]
                    INNER JOIN [#t1]    
                            ON [imsoe_vw].[record_id_num] = [#t1].[record_id_num]
                    WHERE [imsoe_vw].[order_no] = @hdr_cursor_order_no
                            AND ([imsoe_vw].[record_type] = @RECTYPE_OE_HDR OR [imsoe_vw].[record_type] = @RECTYPE_OE_LINE)
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_vw 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            FETCH NEXT 
                    FROM [hdr_cursor]
                    INTO @hdr_cursor_order_no, 
                         @hdr_cursor_record_id_num
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_FETCHNEXT + ' hdr_cursor 4' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            END    
        CLOSE [hdr_cursor]
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CLOSE + ' hdr_cursor 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        SET @hdr_cursor_Cursor_Opened = 'NO'
        DEALLOCATE [hdr_cursor]
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DEALLOCATE + ' hdr_cursor 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        SET @hdr_cursor_Cursor_Allocated = 'NO'
        --
        -- Third, update next_order_num.last_no with the value that includes all the staging
        -- table records.
        --
        UPDATE [next_order_num]
                SET [last_no] = @last_no                 
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' next_order_num 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        END
    --
    -- Calculate tax and put the value in the staging table..
    --
    CREATE TABLE #TxLineInput (control_number        varchar(16),
                               reference_number INT,
                               tax_code        varchar(8),
                               quantity        float,
                               extended_price        float,
                               discount_amount        float,
                               tax_type        smallint,
                               currency_code        varchar(8))
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATETABLE + ' #TxLineInput 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    CREATE TABLE #TxInfo (control_number        varchar(16),
                          sequence_id INT,
                          tax_type_code        varchar(8),
                          amt_taxable            float,
                          amt_gross            float,
                          amt_tax                float,
                          amt_final_tax        float,
                          currency_code        varchar(8),
                          tax_included_flag    smallint)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATETABLE + ' #TxInfo 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    CREATE TABLE #TxLineTax (control_number        varchar(16),
                             reference_number INT,
                             tax_amount            float,
                             tax_included_flag    smallint)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATETABLE + ' #TxLineTax 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    CREATE TABLE #txdetail (control_number    varchar(16),
                            reference_number INT,
                            tax_type_code        varchar(8),
                            amt_taxable        float)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATETABLE + ' #txdetail 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    CREATE TABLE #txinfo_id (id_col            numeric identity,
                             control_number        varchar(16),
                             sequence_id INT,
                             tax_type_code        varchar(8),
                             currency_code        varchar(8))
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATETABLE + ' #txinfo_id 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    CREATE TABLE #TXInfo_min_id (control_number varchar(16),min_id_col numeric)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATETABLE + ' #TXInfo_min_id 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    CREATE TABLE #TxTLD (control_number    varchar(16),
                         tax_type_code        varchar(8),
                         tax_code        varchar(8),
                         currency_code        varchar(8),
                         tax_included_flag    smallint,
                         base_id INT,
                         amt_taxable        float,
                         amt_gross        float)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATETABLE + ' #TxTLD 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    CREATE TABLE #arcrchk (customer_code        varchar(8),
                           check_credit_limit    smallint,
                           credit_limit        float,
                           limit_by_home        smallint)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATETABLE + ' #arcrchk 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    INSERT #TxLineInput
            (control_number, reference_number, tax_code,
             quantity,       extended_price,   discount_amount,
             tax_type,       currency_code)
            SELECT CONVERT(VARCHAR(10), h.[order_no]), h.[record_id_num],         h.[tax_id], 
                   (l.[ordered] * l.[conv_factor]),    (l.[ordered] * l.[price]), 0, 
                   0,                                  NULL
                    FROM [imsoe_hdr_vw] h (NOLOCK)
                    INNER JOIN [imsoe_line_vw] l (NOLOCK)
                            ON h.[order_no] = l.[order_no]
                    INNER JOIN [#t1] t (NOLOCK)
                            ON h.[record_id_num] = t.[record_id_num]
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #TxLineInput 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE #TxLineInput
            SET extended_price = round(extended_price, isnull(g.curr_precision, 1.0)),
                currency_code = h.curr_key
            FROM [imsoe_hdr_vw] h (NOLOCK) LEFT OUTER JOIN glcurr_vw g ON (h.curr_key = g.currency_code)
            WHERE h.order_no = convert(int, #TxLineInput.control_number) 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #TxLineInput 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    IF EXISTS (SELECT DISTINCT [tax_code] FROM [#TxLineInput] GROUP BY [tax_code] HAVING [tax_code] NOT IN (SELECT [tax_code] FROM [artax] (NOLOCK)))
        BEGIN
        EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = 'imSoeIns_sp 1', 
                                                     @IGES_String = @External_String OUT 
        INSERT INTO [imlog] ([now], 
                             [module], 
                             [text],
                             [User_ID]) 
                VALUES (GETDATE(), 
                        'SO',
                        @External_String,
                        @userid) 
        GOTO Error_Return
        END
    IF EXISTS (SELECT distinct currency_code from #TxLineInput group by currency_code having currency_code not in (SELECT currency_code from glcurr_vw (NOLOCK)))
        BEGIN
        EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = 'imSoeIns_sp 2', 
                                                     @IGES_String = @External_String OUT 
        INSERT INTO [imlog] ([now], 
                             [module], 
                             [text],
                             [User_ID]) 
                VALUES (GETDATE(), 
                        'SO',
                        @External_String,
                        @userid) 
        GOTO Error_Return
        END
    EXEC @SP_Result = TXCalculateTax_SP
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' TXCalculateTax_SP 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    IF NOT @SP_Result = 0
        BEGIN
        EXEC im_log_sp_error_sp @ILSE_Error_Code = @SP_Result,
                                @ILSE_SP_Name = 'TXCalculate_SP',
                                @ILSE_String = '',
                                @ILSE_Procedure_Name = @Routine_Name,
                                @ILSE_Log_Activity = 'YES'
        GOTO Error_Return
        END
    UPDATE [imsoe_hdr_vw]
            SET [total_tax] = ISNULL((SELECT SUM([amt_final_tax]) FROM #TxInfo WHERE [control_number] = CONVERT(VARCHAR(10), [order_no]) AND [tax_included_flag] IN (0, 1)), 0)
            WHERE [order_no] IN (SELECT DISTINCT CONVERT(INT, [control_number]) FROM #TxInfo)
                    AND ([total_tax] IS NULL OR [total_tax] = 0)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_hdr_vw 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    SET @w_cursrec_upd = 0
    SET @w_cursrec_count = 0
    SET @w_cursrec_dtl_count = 0
    SET @w_cursrec_dtl_upd = 0
    DECLARE hdr_cursor cursor for
            SELECT order_no,
                   cust_code,
                   date_entered,
                   imsoe_hdr_vw.record_id_num
            FROM [imsoe_hdr_vw]
            INNER JOIN [#t1] 
                    ON [imsoe_hdr_vw].[record_id_num] = [#t1].[record_id_num]
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DECLARE + ' hdr_cursor 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    SET @hdr_cursor_Cursor_Allocated = 'YES'
    OPEN hdr_cursor
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_OPEN + ' hdr_cursor 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    SET @hdr_cursor_Cursor_Opened = 'YES'
    FETCH NEXT 
            FROM hdr_cursor
            INTO @w_hdr_order_no,
                 @w_cust_code,
                 @w_date_entered ,
                 @w_hdr_record_id_num
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_FETCHNEXT + ' hdr_cursor 5' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    WHILE @@FETCH_STATUS <> -1
        BEGIN
        SELECT @w_cursrec_count = @w_cursrec_count + 1
        IF @debug_level > 0
            BEGIN
            SELECT 'w_hdr_order_no'=@w_hdr_order_no, 'w_cust_code'=@w_cust_code, 'w_date_entered'=@w_date_entered, 'w_hdr_record_id_num'=@w_hdr_record_id_num
            END
        INSERT INTO orders (attention,          back_ord_flag,     bill_to_key,
                            blanket,            cash_flag,         changed,
                            cr_invoice_no,      curr_factor,       curr_key,
                            curr_type,          cust_code,         date_entered,
                            dest_zone_code,     discount,          ext,
                            f_note,             fob,               forwarder_key,
                            freight,            freight_allow_pct, freight_to,
                            gross_sales,        invoice_no,        load_no,
                            location,           note,              oper_factor,
                            order_no,           orig_ext,          orig_no,
                            phone,              posting_code,      printed,
                            rate_type_home,     rate_type_oper,    remit_key,
                            req_ship_date,      route_code,        route_no,
                            routing,            sales_comm,        salesperson,
                            sch_ship_date,      ship_to,           ship_to_add_1, 
                            ship_to_add_2,      ship_to_add_3,     ship_to_add_4,
                            ship_to_add_5,      ship_to_city,      ship_to_country,
                            ship_to_name,       ship_to_region,    ship_to_state,
                            ship_to_zip,        special_instr,     status,
                            tax_id,             tax_perc,          terms,
                            tot_ord_disc,       tot_ord_freight,   tot_ord_tax, 
                            total_amt_order,    total_discount,    total_invoice,
                            total_tax,          type,              void,
                            who_entered,        [blanket_amt],     [user_priority],
                            [user_category],    [from_date],       [to_date],
                            [consolidate_flag], [proc_inv_no],     [sold_to_addr1],
                            [sold_to_addr2],    [sold_to_addr3],   [sold_to_addr4],
                            [sold_to_addr5],    [sold_to_addr6],   [user_code],
                            [user_def_fld1],    [user_def_fld2],   [user_def_fld3],
                            [user_def_fld4],    [user_def_fld5],   [user_def_fld6],
                            [user_def_fld7],    [user_def_fld8],   [user_def_fld9],
                            [user_def_fld10],   [user_def_fld11],  [user_def_fld12],
                            [multiple_flag],    [cust_po]) 
                SELECT attention,               back_ord_flag,              bill_to_key,
                       blanket,                 'N',                        changed,
                       cr_invoice_no,           ISNULL(curr_factor, 1),     curr_key,
                       curr_type,               cust_code,                  date_entered,
                       dest_zone_code,          ISNULL(discount, 0),        0,
                       f_note,                  fob,                        forwarder_key,
                       ISNULL(freight, 0),      0,                          freight_to,
                       ISNULL(gross_sales, 0),  invoice_no,                 ISNULL(load_no, 0),
                       location,                note,                       ISNULL(oper_factor, 1),
                       order_no,                ISNULL(orig_ext, 0),        ISNULL(orig_no, 0),
                       phone,                   posting_code,               printed,
                       rate_type_home,          rate_type_oper,             remit_key,
                       req_ship_date,           '',                         0,
                       routing,                 0,                          salesperson,
                       sch_ship_date,           ship_to,                    ship_to_add_1,
                       ship_to_add_2,           ship_to_add_3,              ship_to_add_4,
                       ship_to_add_5,           ship_to_city,               ship_to_country,
                       ship_to_name,            ship_to_region,             ship_to_state,
                       ship_to_zip,             special_instr,              status,
                       tax_id,                  tax_perc,                   terms,
                       ISNULL(tot_ord_disc, 0), ISNULL(tot_ord_freight, 0), ISNULL(tot_ord_tax, 0),
                       total_amt_order,         ISNULL(total_discount, 0),  total_invoice,
                       ISNULL(total_tax, 0),    type,                       void,
                       who_entered,             [blanket_amt],              [user_priority],
                       [user_category],         [from_date],                [to_date],
                       [consolidate_flag],      [proc_inv_no],              [sold_to_addr1],
                       [sold_to_addr2],         [sold_to_addr3],            [sold_to_addr4],
                       [sold_to_addr5],         [sold_to_addr6],            ISNULL([user_code], ''),
                       [user_def_fld1],         [user_def_fld2],            [user_def_fld3],
                       [user_def_fld4],         [user_def_fld5],            [user_def_fld6],
                       [user_def_fld7],         [user_def_fld8],            [user_def_fld9],
                       [user_def_fld10],        [user_def_fld11],           [user_def_fld12],
                       'N',                     [cust_po]
                        FROM [imsoe_hdr_vw]
                        WHERE record_id_num = @w_hdr_record_id_num
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' orders 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        SELECT @w_cursrec_upd = @w_cursrec_upd + 1
        DECLARE lin_cursor CURSOR FOR
                SELECT imsoe_line_vw.record_id_num
                        FROM imsoe_line_vw, #t1, imsoe_hdr_vw
                        WHERE imsoe_line_vw.record_id_num = #t1.record_id_num
                                AND imsoe_line_vw.order_no = imsoe_hdr_vw.order_no
                                AND imsoe_hdr_vw.record_id_num = @w_hdr_record_id_num
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DECLARE + ' lin_cursor 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        SET @lin_cursor_Cursor_Allocated = 'YES'
        OPEN lin_cursor
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_OPEN + ' lin_cursor 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        SET @lin_cursor_Cursor_Opened = 'YES'
        FETCH NEXT 
                FROM lin_cursor 
                INTO @w_lin_record_id_num
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_FETCHNEXT + ' lin_cursor 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        WHILE @@fetch_status <> -1
            BEGIN
            IF @debug_level > 0
                BEGIN
                SELECT 'w_lin_record_id_num'=@w_lin_record_id_num
                SELECT order_no, line_no, line_location, part_no FROM imsoe_line_vw WHERE record_id_num = @w_lin_record_id_num
                END
            SELECT @w_cursrec_dtl_count = @w_cursrec_dtl_count + 1
            INSERT INTO ord_list (back_ord_flag,  ----37
                                  conv_factor,  ----23
                                  cost,  ----14
                                  cr_ordered,  ----19
                                  cr_shipped,  ----20
                                  cubic_feet,  ----26
                                  curr_price,  ----43
                                  description,  ----6
                                  direct_dolrs,  ----30
                                  discount,  ----21
                                  display_line,  ----42
                                  gl_rev_acct,  ----38
                                  labor,  ----29
                                  lb_tracking,  ----28
                                  line_no,  ----3
                                  location,  ----4
                                  note,  ----12
                                  oper_price,  ----44
                                  order_ext,  ----2
                                  order_no,  ----1
                                  ordered,  ----8
                                  orig_part_no,  ----36
                                  ovhd_dolrs,  ----31
                                  part_no,  ----5
                                  part_type,  ----35
                                  price,  ----10
                                  price_type,  ----11
                                  printed,  ----27
                                  qc_flag,  ----34
                                  sales_comm,  ----16
                                  shipped,  ----9
                                  status,  ----13
                                  std_cost,  ----25
                                  std_direct_dolrs,  ----45
                                  std_ovhd_dolrs,  ----46
                                  std_util_dolrs,  ----47
                                  tax_code,  ----40
                                  taxable,  ----33
                                  temp_price,  ----17
                                  temp_type,  ----18
                                  time_entered,  ----7
                                  total_tax,  ----39
                                  uom,  ----22
                                  util_dolrs,  ----32
                                  void,  ----24
                                  weight_ea,  ----41
                                  who_entered) 
                    SELECT back_ord_flag,
                           conv_factor,
                           cost,
                           0, -- cr_ordered
                           0, -- cr_shipped
                           1, -- cubic_feet
                           ISNULL(price, 0),
                           description,
                           0, -- direct_dolrs
                           ISNULL(line_discount, 0),
                           ISNULL(line_no, 0),
                           gl_rec_acct,
                           0, -- labor
                           ISNULL(lb_tracking, 'N'),
                           ISNULL(line_no, 0),
                           line_location,
                           line_note,
                           ISNULL(price, 0),
                           0, -- order_ext
                           order_no,
                           ISNULL(ordered, 0),
                           part_no,
                           0, -- ovhd_dolrs
                           part_no,
                           ISNULL(part_type, 'P'),
                           ISNULL(price, 0),
                           ISNULL(price_type, 'Y'),
                           printed,
                           'N', -- qc_flag
                           0, -- sales_comm
                           ISNULL(shipped, 0),
                           ISNULL(line_status, 'N'),
                           0, -- std_cost
                           0, -- std_direct_dolrs
                           0, -- std_ovhd_dolrs
                           0, -- std_util_dolrs
                           tax_code,
                           ISNULL(taxable, 1),
                           ISNULL(price, 0),
                           '1', -- temp_type
                           time_entered,
                           line_total_tax,
                           uom,
                           0, -- util_dolrs
                           'N', -- void
                           ISNULL(weight_ea, 0),
                           who_entered
                            FROM imsoe_line_vw
                            WHERE record_id_num = @w_lin_record_id_num
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' ord_list 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            SET @w_lin_upd_count = @Row_Count
            IF @w_lin_upd_count > 0
                BEGIN
                SELECT @w_cursrec_dtl_upd = @w_cursrec_dtl_upd + 1
                UPDATE imsoe_line_vw
                        SET process_status = 1
                        WHERE record_id_num = @w_lin_record_id_num
                SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_line_vw 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
                end
            IF @debug_level > 0
                BEGIN
                SELECT @w_dmsg = 'record_id_num='
                SELECT @w_dmsg = @w_dmsg + convert(varchar,@w_hdr_record_id_num)
                SELECT @w_dmsg = @w_dmsg + '  reccount='
                SELECT @w_dmsg = @w_dmsg + convert(varchar,@w_lin_upd_count )
                PRINT @w_dmsg
                END
            FETCH NEXT 
                    FROM lin_cursor 
                    INTO @w_lin_record_id_num
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_FETCHNEXT + ' lin_cursor 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            END
        CLOSE lin_cursor
        SET @lin_cursor_Cursor_Opened = 'NO'
        DEALLOCATE lin_cursor
        SET @lin_cursor_Cursor_Allocated = 'NO'
        INSERT INTO mod_orders 
                VALUES (@w_hdr_order_no,0)
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' mod_orders 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        INSERT INTO ord_rep (order_no,
                             order_ext,
                             salesperson,
                             sales_comm,
                             percent_flag,
                             exclusive_flag,
                             split_flag,
                             display_line)
                SELECT imsoe_salcomm_vw.order_no,
                       0,
                       imsoe_salcomm_vw.salesperson,
                       imsoe_salcomm_vw.sales_comm,
                       ISNULL(imsoe_salcomm_vw.percent_flag, 0),
                       ISNULL(imsoe_salcomm_vw.exclusive_flag, 0),
                       ISNULL(imsoe_salcomm_vw.split_flag, 0),
                       ISNULL(imsoe_salcomm_vw.line_no, 0)
                        FROM imsoe_salcomm_vw, #t1, imsoe_hdr_vw
                        WHERE imsoe_salcomm_vw.record_id_num = #t1.record_id_num
                                AND imsoe_salcomm_vw.order_no = imsoe_hdr_vw.order_no
                                AND imsoe_hdr_vw.record_id_num = @w_hdr_record_id_num
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' ord_rep 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        UPDATE imsoe_salcomm_vw
                SET process_status = 1
                FROM imsoe_salcomm_vw, #t1
                WHERE imsoe_salcomm_vw.record_id_num = #t1.record_id_num
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_salcomm_vw 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        SELECT @p003 = 0
        TRUNCATE TABLE [#adm_taxinfo]
        TRUNCATE TABLE [#adm_taxtype]
        TRUNCATE TABLE [#adm_taxtyperec]
        TRUNCATE TABLE [#adm_taxcode]
        TRUNCATE TABLE [#cents]
        EXEC fs_calculate_oetax @ord = @w_hdr_order_no,
                                @ext = 0,
                                @err = @p003 output
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' fs_calculate_oetax 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        EXEC fs_updordtots @ordno = @w_hdr_order_no,
                           @ordext = 0
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' fs_updordtots 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        EXEC imCvtJulFrmDte_sp @w_date_entered, @w_julian OUTPUT
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' imCvtJulFrmDte_sp 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        SELECT @p005 = 0
        EXEC fs_archklmt_sp @customer_code = @w_cust_code,
                            @date_entered = @w_julian,
                            @ordno = @w_hdr_order_no,
                            @ordext = 0,
                            @chk = @p005 output
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' fs_archklmt_sp 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        UPDATE imsoe_hdr_vw
                SET process_status = 1
                WHERE record_id_num = @w_hdr_record_id_num
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_hdr_vw 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        FETCH NEXT 
                FROM hdr_cursor
                INTO @w_hdr_order_no, @w_cust_code, @w_date_entered,    @w_hdr_record_id_num
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_FETCHNEXT + ' hdr_cursor 6' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        END
    CLOSE hdr_cursor
    SET @hdr_cursor_Cursor_Opened = 'NO'
    DEALLOCATE hdr_cursor
    SET @lin_cursor_Cursor_Allocated = 'NO'
    IF @ROLLBACK_On_Error = 'YES' BEGIN COMMIT TRANSACTION SET @ROLLBACK_On_Error = 'NO' END
    INSERT INTO #tupd_stats (company_code,section,viewName,viewDesc,totRecs,updates)
            SELECT @w_cc, section, Name1, description, @w_cursrec_count, @w_cursrec_upd
            FROM imwbtables_vw 
                    WHERE Name1 = 'imsoe_hdr_vw'
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #tupd_stats 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    INSERT INTO #tupd_stats (company_code,section,viewName,viewDesc,totRecs,updates)
            SELECT @w_cc, section, Name1, description, @w_cursrec_dtl_count, @w_cursrec_dtl_upd
            FROM imwbtables_vw 
                    WHERE Name1 = 'imsoe_line_vw'
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #tupd_stats 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --    
    INSERT INTO [imlog] 
            SELECT GETDATE(), 'SO', 1, '', '', '', 'Sales Order ' + RTRIM(LTRIM(ISNULL(ISNULL(viewDesc, ''), ''))) + ', Total Records: ' + CAST(ISNULL(totRecs, 0) AS VARCHAR) + ', Updates: ' + CAST(ISNULL(updates, 0) AS VARCHAR), @userid
            FROM #tupd_stats
Exit_Return:            
    DROP TABLE [#temp_orders_ins] 
    DROP TABLE [#temp_orders_del] 
    DROP TABLE [#temp_ord_list_ins]
    DROP TABLE [#temp_ord_list_del]
    DROP TABLE [#t1]
    DROP TABLE [#adm_taxinfo]
    DROP TABLE [#adm_taxtype]
    DROP TABLE [#adm_taxtyperec]
    DROP TABLE [#adm_taxcode]
    DROP TABLE [#cents]
    INSERT INTO imlog VALUES (GETDATE(), 'SO', 1, '', '', '', 'Sales Order -- End', @userid)
    RETURN 0
Error_Return:
    DROP TABLE [#temp_orders_ins] 
    DROP TABLE [#temp_orders_del] 
    DROP TABLE [#temp_ord_list_ins]
    DROP TABLE [#temp_ord_list_del]
    DROP TABLE [#t1]
    DROP TABLE [#adm_taxinfo]
    DROP TABLE [#adm_taxtype]
    DROP TABLE [#adm_taxtyperec]
    DROP TABLE [#adm_taxcode]
    DROP TABLE [#cents]
    IF @hdr_cursor_Cursor_Opened = 'YES'
        CLOSE hdr_cursor
    IF @hdr_cursor_Cursor_Allocated = 'YES'
        DEALLOCATE hdr_cursor
    IF @lin_cursor_Cursor_Opened = 'YES'
        CLOSE lin_cursor
    IF @lin_cursor_Cursor_Allocated = 'YES'
        DEALLOCATE lin_cursor
    INSERT INTO imlog VALUES (GETDATE(), 'SO', 1, '', '', '', 'Sales Order -- End (ERROR)', @userid)
    RETURN -1
GO
GRANT EXECUTE ON  [dbo].[imSoeIns_sp] TO [public]
GO
