SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


    CREATE PROCEDURE 
[dbo].[imPurIns_sp] (@p_batchno INT = 0,
             @p_start_rec INT = 0,
             @p_end_rec INT = 0,
             @p_Dummy INT = 0,
             @debug_level INT = 0,
             @userid INT = 0) 
    AS
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
    

    DELETE imlog WHERE UPPER(module) = 'PO' AND ([User_ID] = @userid OR @userid = 0)
    INSERT INTO imlog VALUES (getdate(), 'PO', 1, '', '', '', 'Purchase Order -- Begin (Copy) -- 7.3', @userid) 
    
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
    declare @po_mask varchar(16), @po_no varchar(16),    	-- mls 1/11/05
      @err_flag int
    --
    select @po_mask = isnull((select value_str from config (nolock) where flag = 'PUR_PO_MASK'),'')
    if @po_mask = ''
      goto Error_Return

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
        EXEC imPurIns_e7_sp @p_batchno = @p_batchno,
                            @p_start_rec = @p_start_rec,
                            @p_end_rec = @p_end_rec,
                            @p_debug_level = @debug_level 
        RETURN 0
        END
    --
    DECLARE @Automatically_Assign_Order_Numbers VARCHAR(100)
    DECLARE @batch_size INT
    DECLARE @cnt INT
    DECLARE @Header_Record_Count INT
    DECLARE @last_no INT
    DECLARE @max_cnt INT
    DECLARE @New_po_key INT
    DECLARE @next_po INT
    DECLARE @w_cc VARCHAR(8)
    DECLARE @w_dmsg VARCHAR(255)
    DECLARE @err_code INT
    DECLARE @w_rec_upd_count INT
    DECLARE @hdr_cursor_Cursor_Allocated VARCHAR(3)
    DECLARE @hdr_cursor_Cursor_Opened VARCHAR(3)
    DECLARE @hdr_cursor_po_key INT
    DECLARE @hdr_cursor_record_id_num INT
    DECLARE @RECTYPE_OE_HDR INT
    DECLARE @RECTYPE_OE_LINE INT
    DECLARE @RECTYPE_OE_REL INT
    DECLARE @w_po_no int
    DECLARE @w_hdr_record_id_num int
    DECLARE @w_lin_record_id_num int
    DECLARE @P002 INT
    DECLARE @w_julian int
    DECLARE @w_date_entered datetime
    DECLARE @w_cust_code varchar(10)
    DECLARE @w_cursrec_count int
    DECLARE @w_cursrec_upd int
    DECLARE @w_cursrec_hdr_count int
    DECLARE @w_cursrec_dtl_count int
    DECLARE @w_cursrec_dtl_upd int
    DECLARE @w_cursrec_rel_count int
    DECLARE @w_cursrec_rel_upd int
    --
    SET @Routine_Name = 'imPurIns_sp'
    SET @hdr_cursor_Cursor_Allocated = 'NO'
    SET @hdr_cursor_Cursor_Opened = 'NO'
    SELECT @w_cc = company_code 
            FROM glco (nolock)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' glco 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    SET @RECTYPE_OE_HDR = 1
    SET @RECTYPE_OE_LINE = 16
    SET @RECTYPE_OE_REL = 256
    SELECT @w_cursrec_count = 0,
           @w_cursrec_upd = 0,
           @w_cursrec_dtl_count = 0,
           @w_cursrec_dtl_upd = 0,
           @w_cursrec_rel_count = 0,
           @w_cursrec_rel_upd = 0
    --
    -- Get batch size
    --
    SET @batch_size = 12
    IF EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'im_config')
        BEGIN
        SELECT @batch_size = ISNULL([INT Value], 12)
                FROM [im_config] 
                WHERE RTRIM(LTRIM(ISNULL(UPPER([Item Name]), ''))) = 'BATCH SIZE (PURCHASE ORDER)'
        IF @@ROWCOUNT = 0
                OR @batch_size < 0
                OR @batch_size > 1000
            SET @batch_size = 12
        END
    --
    -- Get the "automatically assign numbers" configuration entry.
    --
    SET @Automatically_Assign_Order_Numbers = 'NO'
    IF EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'im_config')
        BEGIN
        SELECT @Automatically_Assign_Order_Numbers = RTRIM(LTRIM(ISNULL(UPPER([Text Value]), '')))
                FROM [im_config] 
                WHERE RTRIM(LTRIM(ISNULL(UPPER([Item Name]), ''))) = 'AUTOMATICALLY ASSIGN PURCHASE ORDER NUMBERS'
        IF @@ROWCOUNT = 0
                OR @Automatically_Assign_Order_Numbers IS NULL
                OR (NOT @Automatically_Assign_Order_Numbers = 'NO' AND NOT @Automatically_Assign_Order_Numbers = 'YES' AND NOT @Automatically_Assign_Order_Numbers = 'TRUE' AND NOT @Automatically_Assign_Order_Numbers = 'FALSE')
            SET @Automatically_Assign_Order_Numbers = 'NO'
        IF @Automatically_Assign_Order_Numbers = 'TRUE'
            SET @Automatically_Assign_Order_Numbers = 'YES'
        END    
    --
    -- Tax calculation tables.
    --
    
CREATE TABLE #TxLineInput
(
	control_number		varchar(16),
	reference_number	int,
	tax_code			varchar(8),
	quantity			float,
	extended_price		float,
	discount_amount		float,
	tax_type			smallint,
	currency_code		varchar(8)
)

    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATETABLE + ' TxLineInput' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    
CREATE TABLE #TxInfo
(
	control_number		varchar(16),
	sequence_id		int,
	tax_type_code		varchar(8),
	amt_taxable			float,
	amt_gross			float,
	amt_tax				float,
	amt_final_tax		float,
	currency_code		varchar(8),
	tax_included_flag	smallint

)

    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATETABLE + ' TxInfo' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    
CREATE TABLE #TxLineTax
(
	control_number		varchar(16),
	reference_number	int,
	tax_amount			float,
	tax_included_flag	smallint
)

    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATETABLE + ' TxLineTax' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Note that txdetail.tmp contains four CREATE TABLE instructions and therefore only
    -- the last one will trigger the following CHECK_SQL_STATUS.
    --
    
	CREATE TABLE #txdetail
	(
		control_number	varchar(16),
		reference_number	int,
		tax_type_code		varchar(8),
		amt_taxable		float
	)


	CREATE TABLE #txinfo_id
	(
		id_col			numeric identity,
		control_number	varchar(16),
		sequence_id		int,
		tax_type_code		varchar(8),
		currency_code		varchar(8)
	)


	CREATE TABLE #TXInfo_min_id (control_number varchar(16),min_id_col numeric)


	CREATE TABLE	#TxTLD
	(
		control_number	varchar(16),
		tax_type_code		varchar(8),
		tax_code		varchar(8),
		currency_code		varchar(8),
		tax_included_flag	smallint,
		base_id		int,
		amt_taxable		float,		
		amt_gross		float		
	)

    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATETABLE + ' TxTLD' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    CREATE TABLE #arcrchk (customer_code        varchar(8),
                           check_credit_limit    smallint,
                           credit_limit        float,
                           limit_by_home        smallint)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATETABLE + ' #arcrchk 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    CREATE table #tupd_stats (company_code    varchar(8),
                              section        varchar(30),
                              viewName     varchar(32),
                              viewDesc     varchar(40) null,
                              totRecs     int,
                              err_code     int null,
                              updates     int null,
                              row_id        int identity)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATETABLE + ' #tupd_stats 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    CREATE table #t1 (record_type            int,
                      record_id_num            int,
                      po_key                int)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATETABLE + ' #t1 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    CREATE UNIQUE CLUSTERED INDEX t1_key on #t1 (record_type, record_id_num)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATEINDEX + ' t1_key 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    CREATE NONCLUSTERED INDEX t1_key1 on #t1 (po_key, record_type)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATEINDEX + ' t1_key1 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    CREATE table #t2 
            (batch_no            int,
             po_key                int,
             po_no               varchar(16))		-- mls 1/11/05
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATETABLE + '#t2 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    CREATE NONCLUSTERED INDEX t2_key on #t2 (batch_no, po_key)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATEINDEX + ' t2_key 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    IF @debug_level >= 3
        BEGIN
        SELECT @p_batchno as Batch, 
               @p_start_rec as Start_Record, 
               @p_end_rec as End_Record
        END
    --
    -- Table #t1 will contain a list of record_id_num values that indicate which staging
    -- table records to process.
    --    
    IF @p_batchno > 0
        BEGIN
        INSERT INTO #t1
                SELECT record_type, record_id_num, po_key
                        FROM impur_vw
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
                    SELECT record_type, record_id_num, po_key
                            FROM impur_vw
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
                    SELECT record_type, record_id_num, po_key
                            FROM impur_vw
                            WHERE company_code = @w_cc
                                    AND process_status = 0
                                    AND record_status_1 = 0
                                    AND record_status_2 = 0
                                    AND record_id_num >= @p_start_rec
                                    AND ([User_ID] = @userid OR @userid = 0)
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #t1 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            END
        END
    --    
    IF @debug_level >= 3
        BEGIN
        SELECT @w_cc as company_code, 
               @p_batchno as Batch, 
               @p_start_rec as Start_Record, 
               @p_end_rec as End_Record
        SELECT '(3): ' + @Routine_Name + ': Records from #t1:'
        SELECT * FROM #t1
        END
    --
    -- The workbench won't call this stored procedure if there are no records available
    -- for copying, but this code will log a message if the workbench should be changed in the 
    -- future 
    --
    IF @Row_Count = 0
        BEGIN
        INSERT INTO imlog VALUES (getdate(), 'PO', 1, '', '', '', 'Purchase Order -- No records available for copying.', @userid)
        INSERT INTO imlog VALUES (getdate(), 'PO', 1, '', '', '', 'Purchase Order --     Records should have process_status = 0, record_status_1 = 0, and record_status_2 = 0.', @userid)
        INSERT INTO imlog VALUES (getdate(), 'PO', 1, '', '', '', 'Purchase Order --     This condition usually occurs when the validation has not been run', @userid)
        INSERT INTO imlog VALUES (getdate(), 'PO', 1, '', '', '', 'Purchase Order --     or the validation has flagged all records in error.', @userid)
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
        SELECT @New_po_key = MAX([impur_hdr_vw].[po_key])
                FROM [impur_hdr_vw]                 
                INNER JOIN [#t1]
                        ON [impur_hdr_vw].[record_id_num] = [#t1].[record_id_num]
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' impur_hdr_vw 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        SELECT @Header_Record_Count = COUNT(*)
                FROM [impur_hdr_vw]                 
                INNER JOIN [#t1]
                        ON [impur_hdr_vw].[record_id_num] = [#t1].[record_id_num]
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' #t1 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        SELECT @last_no = ISNULL([last_no], 0)
                FROM [next_po_no]
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' next_po_no 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        IF NOT @New_po_key > (@last_no + @Header_Record_Count + 1)
            SET @New_po_key = @last_no + @Header_Record_Count + 1
        DECLARE [hdr_cursor] CURSOR FOR
                SELECT impur_hdr_vw.po_key, 
                       impur_hdr_vw.record_id_num
                        FROM [impur_hdr_vw]
                        INNER JOIN [#t1]
                                ON [impur_hdr_vw].[record_id_num] = [#t1].[record_id_num]
                        ORDER BY [impur_hdr_vw].[po_key] DESC
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DECLARE + ' hdr_cursor 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        SET @hdr_cursor_Cursor_Allocated = 'YES'
        OPEN [hdr_cursor]
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_OPEN + ' hdr_cursor 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        SET @hdr_cursor_Cursor_Opened = 'YES'
        FETCH NEXT 
                FROM hdr_cursor
                INTO @hdr_cursor_po_key, 
                     @hdr_cursor_record_id_num
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_FETCHNEXT + ' hdr_cursor 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        --
        -- Note that impur_vw is updated rather than impur_hdr_vw so that an update
        -- is made to both header and line tables.
        --
        WHILE NOT @@FETCH_STATUS = -1
            BEGIN
            SET @New_po_key = @New_po_key + 1
            UPDATE [impur_vw]
                    SET [po_key] = @New_po_key
                    FROM [impur_vw]
                    INNER JOIN [#t1]    
                            ON [impur_vw].[record_id_num] = [#t1].[record_id_num]
                    WHERE [impur_vw].[po_key] = @hdr_cursor_po_key
                           AND ([impur_vw].[record_type] = @RECTYPE_OE_HDR OR [impur_vw].[record_type] = @RECTYPE_OE_LINE
 				OR [impur_vw].[record_type] = @RECTYPE_OE_REL)	-- mls 1/11/05
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_vw 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            FETCH NEXT 
                    FROM [hdr_cursor]
                    INTO @hdr_cursor_po_key, 
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
                SELECT impur_hdr_vw.po_key, 
                       impur_hdr_vw.record_id_num
                        FROM [impur_hdr_vw]
                        INNER JOIN [#t1]
                                ON [impur_hdr_vw].[record_id_num] = [#t1].[record_id_num]
                        ORDER BY [impur_hdr_vw].[po_key] DESC
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DECLARE + ' hdr_cursor 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        SET @hdr_cursor_Cursor_Allocated = 'YES'
        OPEN [hdr_cursor]
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_OPEN + ' hdr_cursor 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        SET @hdr_cursor_Cursor_Opened = 'YES'
        FETCH NEXT 
                FROM hdr_cursor
                INTO @hdr_cursor_po_key, 
                     @hdr_cursor_record_id_num
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_FETCHNEXT + ' hdr_cursor 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        WHILE NOT @@FETCH_STATUS = -1
            BEGIN
            --
            -- Note again that impur_vw is updated rather than impur_hdr_vw so that an update
            -- is made to both header and line tables.
            --
            SET @last_no = @last_no + 1
            UPDATE [impur_vw]
                    SET [po_key] = @last_no
                    FROM [impur_vw]
                    INNER JOIN [#t1]    
                            ON [impur_vw].[record_id_num] = [#t1].[record_id_num]
                    WHERE [impur_vw].[po_key] = @hdr_cursor_po_key
                            AND ([impur_vw].[record_type] = @RECTYPE_OE_HDR OR [impur_vw].[record_type] = @RECTYPE_OE_LINE
 				OR [impur_vw].[record_type] = @RECTYPE_OE_REL)	-- mls 1/11/05
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_vw 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            FETCH NEXT 
                    FROM [hdr_cursor]
                    INTO @hdr_cursor_po_key, 
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
        -- Third, update next_po_no.last_no with the value that includes all the staging
        -- table records.
        --
        UPDATE [next_po_no]
                SET [last_no] = @last_no                 
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' next_po_no 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

	update #t1
        set po_key = i.po_key
        from #t1, impur_vw i
        where #t1.record_id_num = i.record_id_num
        END

    --
    -- Table #t2 will contain a list of po_key values and the batch numbers to which they
    -- belong.  This table will be used to divide the processing into "batches" to improve
    -- efficiency.
    --    
    INSERT #t2 (batch_no, po_key, po_no)		-- mls 1/11/05
            SELECT DISTINCT 0, po_key, ''
                    FROM #t1
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #t2 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    SET @cnt = 1
    SET ROWCOUNT @batch_size
    WHILE EXISTS (SELECT 1 from #t2 where batch_no = 0)
        BEGIN
        UPDATE #t2
                SET batch_no = @cnt
                WHERE batch_no = 0
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #t2 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        SET @cnt = @cnt + 1
        END
    SET ROWCOUNT 0
    SELECT @max_cnt = @cnt,
           @cnt = 1
    --

    update #t2
    set po_no = p.po_no
    from #t2, purchase p
    where #t2.po_key = p.po_key

    
        DECLARE [hdr_cursor] CURSOR FOR
                SELECT po_key
                        FROM #t2 where po_no = ''
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DECLARE + ' hdr_cursor 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        SET @hdr_cursor_Cursor_Allocated = 'YES'
        OPEN [hdr_cursor]
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_OPEN + ' hdr_cursor 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        SET @hdr_cursor_Cursor_Opened = 'YES'
        FETCH NEXT 
                FROM hdr_cursor
                INTO @hdr_cursor_po_key
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_FETCHNEXT + ' hdr_cursor 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        --
        WHILE NOT @@FETCH_STATUS = -1
            BEGIN
	    exec fs_fmtctlnm_sp @hdr_cursor_po_key, @po_mask, @po_no OUT, @err_flag OUT

            if @err_flag != 0 or isnull(@po_no,'') = '' 
            begin
              set @Error_Code = @err_flag
              IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = 'Exec' + ' fs_fmtctlnm_sp 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return 
            end

            UPDATE #t2
             set po_no = @po_no
             where po_key = @hdr_cursor_po_key

            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_vw 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            FETCH NEXT 
                    FROM [hdr_cursor]
                    INTO @hdr_cursor_po_key
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_FETCHNEXT + ' hdr_cursor 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            END    
        CLOSE [hdr_cursor]
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CLOSE + ' hdr_cursor 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        SET @hdr_cursor_Cursor_Opened = 'NO'
        DEALLOCATE [hdr_cursor]
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DEALLOCATE + ' hdr_cursor 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        SET @hdr_cursor_Cursor_Allocated = 'NO'

    --
    WHILE @cnt < @max_cnt
        BEGIN
        --
        -- Calculate taxes.
        --
        TRUNCATE TABLE #TxLineInput
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DELETE + ' #TxLineInput 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        TRUNCATE TABLE #TxInfo
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DELETE + ' #TxInfo 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        TRUNCATE TABLE #TxLineTax
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DELETE + ' #TxLineTax 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        INSERT #TxLineInput
                (control_number, reference_number, tax_code,
                 quantity,       extended_price,   discount_amount,
                 tax_type,       currency_code)
                SELECT CONVERT(VARCHAR(10), l.po_key),  l.record_id_num,               l.tax_code, 
                       (l.qty_ordered * l.conv_factor), (l.qty_ordered * l.curr_cost), 0, 
                       0,                               NULL
                        from impur_vw l (nolock), #t1 t (nolock), #t2 t2
                        where t.po_key = t2.po_key 
                                AND t.record_type = @RECTYPE_OE_LINE 
                                AND l.record_id_num = t.record_id_num
                                AND t2.batch_no = @cnt 
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #TxLineInput 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        INSERT #TxLineInput
                (control_number, reference_number, tax_code,
                 quantity,       extended_price,   discount_amount,
                 tax_type,       currency_code)
                SELECT CONVERT(VARCHAR(10), l.po_key),  1000000 + l.line,              l.tax_code, 
                       (l.qty_ordered * l.conv_factor), (l.qty_ordered * l.curr_cost), 0, 
                       0,                               NULL
                        FROM pur_list l (nolock)
                        WHERE l.po_key in (SELECT distinct t2.po_key from #t2 t2 where t2.batch_no = @cnt)
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #TxLineInput 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        UPDATE #TxLineInput
                SET extended_price = round(extended_price, isnull(g.curr_precision, 1.0)),
                    currency_code = p.curr_key
                FROM impur_hdr_vw p (nolock) LEFT OUTER JOIN glcurr_vw g ON (p.curr_key = g.currency_code)
                WHERE p.po_key = convert(int, #TxLineInput.control_number) 
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #TxLineInput 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        UPDATE #TxLineInput
                SET extended_price = round(extended_price, isnull(g.curr_precision, 1.0)),
                    currency_code = p.curr_key
                FROM purchase p (nolock) LEFT OUTER JOIN glcurr_vw g ON (p.curr_key = g.currency_code)
                WHERE p.po_key = convert(int, #TxLineInput.control_number )
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #TxLineInput 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        IF EXISTS (SELECT distinct tax_code from #TxLineInput group by tax_code having tax_code not in (SELECT tax_code from artax (nolock)))
            BEGIN
            EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = 'imPurIns_sp 1', 
                                                         @IGES_String = @External_String OUT 
            ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO'                                             
            INSERT INTO [imlog] ([now], 
                                 [module], 
                                 [text],
                                 [User_ID]) 
                    VALUES (GETDATE(), 
                            'PO',
                            @External_String,
                            @userid) 
            GOTO Error_Return
            END
        IF EXISTS (SELECT distinct currency_code from #TxLineInput group by currency_code having currency_code not in (SELECT currency_code from glcurr_vw (nolock)))
            BEGIN
            EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = 'imPurIns_sp 2', 
                                                         @IGES_String = @External_String OUT 
            ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO'                                             
            INSERT INTO [imlog] ([now], 
                                 [module], 
                                 [text],
                                 [User_ID]) 
                    VALUES (GETDATE(), 
                            'PO',
                            @External_String,
                            @userid) 
            GOTO Error_Return
            END
        EXEC @SP_Result = TXCalculateTax_SP
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' TXCalculateTax_SP 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        IF NOT @SP_Result = 0
            BEGIN
            ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO'                                             
            EXEC im_log_sp_error_sp @ILSE_Error_Code = @SP_Result,
                                    @ILSE_SP_Name = 'TXCalculate_SP',
                                    @ILSE_String = '',
                                    @ILSE_Procedure_Name = @Routine_Name,
                                    @ILSE_Log_Activity = 'YES'
            GOTO Error_Return
            END
        UPDATE impur_hdr_vw
                SET total_tax = ISNULL((SELECT SUM(amt_final_tax) FROM #TxInfo WHERE control_number = CONVERT(VARCHAR(10),po_key) AND tax_included_flag in (0, 1)), 0)
                WHERE po_key IN (SELECT distinct convert(int, control_number) from #TxInfo)
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_hdr_vw 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        UPDATE purchase
                SET total_tax = ISNULL((SELECT SUM(amt_final_tax) FROM #TxInfo WHERE control_number = CONVERT(VARCHAR(10),po_key) AND tax_included_flag in (0, 1)), 0)
                WHERE po_key IN (SELECT distinct convert(int, control_number) from #TxInfo)
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' purchase 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        UPDATE impur_vw
                SET total_tax = t.tax_amount,
                    taxable = 
                            case when t.tax_included_flag = 1 then 
                                0 
                            else 
                                1 
                            end
                FROM impur_vw, #TxLineTax t
                WHERE impur_vw.po_key = convert(int, t.control_number) 
                        AND impur_vw.record_id_num = t.reference_number 
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_vw 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        UPDATE pur_list
                SET total_tax = t.tax_amount,
                    taxable = 
                            case when t.tax_included_flag = 1 then 
                                0 
                            else 
                                1 
                            end
                FROM pur_list, #TxLineTax t
                WHERE pur_list.po_key = convert(int, t.control_number)  
                        AND pur_list.line = t.reference_number - 1000000
                        AND t.reference_number >= 1000000
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' pur_list 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        --
        INSERT INTO purchase 
                (attn,            blanket,       curr_factor,   
                 curr_key,        date_of_order, date_order_due,  
                 discount,        fob,           freight,        
                 location,        oper_factor,   phone, 
                 po_ext,          po_key,        po_no,         
                 po_type,         posting_code,  prepaid_amt,     
                 printed,         prod_no,       rate_type_home, 
                 rate_type_oper,  ship_address1, ship_address2, 
                 ship_address3,   ship_address4, ship_address5, 
                 ship_name,       ship_to_no,    ship_via,        
                 status,          tax_code,      terms,          
                 total_amt_order, total_tax,     vendor_no, 
                 void,            who_entered,   reference_code,
                 buyer,           [user_code],   [expedite_flag],
                 [vend_order_no], [requested_by],                   [approved_by],
                 [user_category], [blanket_flag],                   [date_blnk_from],
                 [date_blnk_to],  [amt_blnk_limit])
               SELECT attn,                        blanket,                          curr_factor,
                       curr_key,                    ISNULL(date_of_order, GETDATE()), date_order_due, 
                       isnull(discount,0),          fob,                              0,
                       location,                    oper_factor,                      phone, 
                       po_ext,                      h.po_key,                         #t2.po_no,	-- mls 1/11/05
                       po_type,                     posting_code,                     0,              
                       printed,                     prod_no,                          rate_type_home,  
                       rate_type_oper,              isnull(ship_address1,''),         isnull(ship_address2,''),
                       isnull(ship_address3,''),    isnull(ship_address4,''),         isnull(ship_address5,''),
                       isnull(ship_name,''),        ship_to_no,                       ship_via, 
                       status,                      tax_code,                         terms,
                       isnull(total_amt_order,0),   isnull(total_tax,0),              vendor_no, 
                       'N',                         SUBSTRING(SYSTEM_USER, 1, 20),    reference_code,
                       buyer,                       ISNULL([user_code], ''),          ISNULL([expedite_flag], 0),
                       [vend_order_no],             [requested_by],                   [approved_by],
                       ISNULL([user_category], ''), ISNULL([blanket_flag], 0),        [date_blnk_from],
                       [date_blnk_to],              [amt_blnk_limit] 
                         FROM impur_vw h, #t1, #t2
                        WHERE h.record_id_num = #t1.record_id_num 
                                AND #t1.po_key = #t2.po_key
                                AND #t1.record_type = @RECTYPE_OE_HDR
                                AND #t2.batch_no = @cnt 
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' purchase 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        SET @w_cursrec_hdr_count = @Row_Count
        UPDATE impur_vw
                SET process_status = 1
                FROM impur_vw, #t1, #t2
                WHERE impur_vw.record_id_num = #t1.record_id_num 
                        AND #t1.po_key = #t2.po_key
                        AND #t1.record_type = @RECTYPE_OE_HDR 
                        AND #t2.batch_no = @cnt
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_vw 4' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        SET @w_cursrec_upd = @Row_Count
        IF @w_cursrec_hdr_count > 0
            BEGIN
            SELECT @next_po = ISNULL((SELECT MAX(po_key) from purchase), 0)
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' MAX(po_key) 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            UPDATE next_po_no
                    SET last_no = @next_po
                    WHERE @next_po != 0
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' next_po_no 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            END
        IF @debug_level >= 3
            BEGIN
            SELECT @w_cursrec_hdr_count 'Number of Records inserted into Purchase'
            END
        --
        -- pur_list rows are also inserted as open (status = 'O') AND will be closed later, if 
        -- necessary, by updating the releases row AND letting the triggers mark the items 
        -- closed.
        --
        INSERT INTO pur_list (account_no,      conv_factor,      curr_cost,
                              description,     ext_cost,         lb_tracking,
                              line,            location,         oper_cost,
                              part_no,         po_key,           po_no,
                              prev_qty,        qty_ordered,      qty_received,
                              rel_date,        status,           tax_code,
                              taxable,         total_tax,        type,
                              unit_cost,       unit_measure,     vend_sku,
                              void,            weight_ea,        who_entered,
                              reference_code,  [tolerance_code], [shipto_code],
                              [receiving_loc], [shipto_name],    [addr1],
                              [addr2],         [addr3],          [addr4],
                              [addr5])
                SELECT account_no,                  conv_factor,      curr_cost, 
                       description,                 0,                lb_tracking,
                       line,                        location,         oper_cost,
                       part_no,                     impur_vw.po_key,  #t2.po_no,		-- mls 1/11/05
                       prev_qty,                    qty_ordered,      qty_received,
                       rel_date,                    'O',              tax_code,
                       taxable,                     total_tax,        type,
                       unit_cost,                   unit_measure,     isnull(vend_sku,''),		-- mls 1/11/05
                       'N',                         weight_ea,        isnull(who_entered,'import mgr'),	-- mls 1/11/05
                       reference_code,              [tolerance_code], ISNULL([shipto_code], ''),
                       ISNULL([receiving_loc], ''), isnull([shipto_name],''),    isnull([addr1],''),
                       isnull([addr2],''),                     isnull([addr3],''),          isnull([addr4],''),
                       isnull([addr5],'')
                        FROM impur_vw, #t1, #t2
                        WHERE impur_vw.record_id_num = #t1.record_id_num 
                                AND #t1.po_key = #t2.po_key
                                AND #t1.record_type = @RECTYPE_OE_LINE 
                                AND #t2.batch_no = @cnt 
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' pur_list 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        SET @w_cursrec_dtl_count = @Row_Count
        IF @w_cursrec_dtl_count > 0
            BEGIN
            SET @w_cursrec_dtl_upd = @w_cursrec_dtl_count
            UPDATE impur_vw
                    SET process_status = 1
                    FROM impur_vw, #t1, #t2
                    WHERE impur_vw.record_id_num = #t1.record_id_num 
                            AND #t1.po_key = #t2.po_key
                            AND #t1.record_type = @RECTYPE_OE_LINE
                            AND #t2.batch_no = @cnt 
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_vw 5' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            END
        IF @debug_level >= 3
            BEGIN
            SELECT @w_cursrec_dtl_count 'Number of Records inserted into Pur_list'
            END
        INSERT INTO releases (po_no,        part_no,      location,
                              part_type,    release_date, quantity,
                              received,     status,       confirm_date,
                              confirmed,    lb_tracking,  conv_factor, 
                              prev_qty,     po_key,       due_date, po_line)
                SELECT #t2.po_no, r.part_no,         r.location,				-- mls 1/11/05 
                       r.type,                                 r.rel_date,        r.qty_ordered,
                       0,                                    'O',             GETDATE(),
                       'N',                                  r.lb_tracking,     r.conv_factor,
                       isnull(r.prev_qty,0),                             r.po_key, r.rel_date,
			r.line
                        FROM impur_vw r, #t1, #t2
                        WHERE r.record_id_num = #t1.record_id_num 
                                AND #t1.po_key = #t2.po_key
                                AND #t1.record_type = @RECTYPE_OE_REL
                                AND #t2.batch_no = @cnt 
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' releases 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        SET @w_cursrec_rel_count = @Row_Count
        IF @debug_level >= 3
            BEGIN
            SELECT @w_cursrec_rel_count 'Number of Records inserted into Releases'
            END
        if @w_cursrec_rel_count > 0
            BEGIN
            SELECT @w_cursrec_rel_upd = @w_cursrec_rel_count
            UPDATE impur_vw
                    SET process_status = 1
                    FROM impur_vw, #t1, #t2
                    WHERE    impur_vw.record_id_num = #t1.record_id_num 
                            AND #t1.po_key = #t2.po_key
                            AND #t1.record_type = @RECTYPE_OE_REL
                            AND #t2.batch_no = @cnt 
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_vw 6' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            END
        --
        -- Update the amount that was received.  This is done with an update rather than during 
        -- the insert since you cannot insert closed items into the releases table.  Update 
        -- the releases entry and let the triggers do the dirty work.
        --
        UPDATE releases 
                SET received = ir.qty_received, 
                    status = case when r.quantity = ir.qty_received then 'C' else r.status end
                FROM releases r, impur_vw ir, #t1, #t2
                WHERE r.po_key = ir.po_key
                        AND r.part_no = ir.part_no
                        AND r.received != ir.qty_received
                        AND ir.record_id_num = #t1.record_id_num
                        AND #t1.po_key = #t2.po_key
                        AND #t1.record_type = @RECTYPE_OE_REL
                        AND #t2.batch_no = @cnt 
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' releases 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        IF @debug_level >= 3
            BEGIN
            SELECT 'id'='ROWS INSERTED', 'purchase'=@w_cursrec_hdr_count, 'pur_list'=@w_cursrec_dtl_count, 'releases'=@w_cursrec_rel_count
            END
        --
        -- Do some processing if project accounting is installed.
        --    
        IF EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'config')
            BEGIN
            IF EXISTS (SELECT 1 FROM config (nolock) WHERE UPPER(flag) = 'PROJECT' AND UPPER(value_str) like 'Y%')
                BEGIN
                DECLARE hdr_cursor CURSOR FOR
                        SELECT impur_vw.po_key, impur_vw.record_id_num
                                FROM impur_vw, #t1, #t2
                                WHERE impur_vw.record_id_num = #t1.record_id_num
                                        AND #t1.po_key = #t2.po_key
                                        AND #t1.record_type = @RECTYPE_OE_HDR
                                        AND #t2.batch_no = @cnt 
                SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DECLARE + ' hdr_cursor 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
                SET @hdr_cursor_Cursor_Allocated = 'YES'
                OPEN hdr_cursor
                SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_OPEN + ' hdr_cursor 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
                SET @hdr_cursor_Cursor_Opened = 'YES'
                FETCH NEXT 
                        FROM hdr_cursor
                        INTO @w_po_no, @w_hdr_record_id_num
                SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_FETCHNEXT + ' hdr_cursor 5' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
                WHILE @@FETCH_STATUS <> -1
                    BEGIN
                    IF @debug_level >= 3
                        BEGIN
                        SELECT 'w_po_no'=@w_po_no, 'w_hdr_record_id_num'=@w_hdr_record_id_num
                        END
                    SELECT @w_cursrec_count = @w_cursrec_count + 1
                    SELECT @po_no = CAST(@w_po_no AS VARCHAR)
                    SELECT @P002 = 0 
                    EXEC dbo.pdgm_purchasing @po_ctrl_num = @po_no, 
                                             @msg = @P002 output 
                    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' pdgm_purchasing 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
                    FETCH NEXT 
                            FROM hdr_cursor
                            INTO @w_po_no, @w_hdr_record_id_num
                    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_FETCHNEXT + ' hdr_cursor 6' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
                    END    
                CLOSE hdr_cursor
                SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CLOSE + ' hdr_cursor 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
                SET @hdr_cursor_Cursor_Opened = 'NO'
                DEALLOCATE hdr_cursor
                SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DEALLOCATE + ' hdr_cursor 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
                SET @hdr_cursor_Cursor_Allocated = 'NO'
                END
            END    
        INSERT INTO #tupd_stats (company_code,section,viewName,viewDesc,totRecs,updates)
                SELECT @w_cc, section, Name1, description, @w_cursrec_count, @w_cursrec_upd
                        FROM imwbtables_vw 
                        WHERE Name1 = 'impur_hdr_vw'
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #tupd_stats 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        INSERT INTO #tupd_stats (company_code,section,viewName,viewDesc,totRecs,updates)
                SELECT @w_cc, section, Name1, description, @w_cursrec_dtl_count, @w_cursrec_dtl_upd
                        FROM imwbtables_vw 
                        WHERE Name1 = 'impur_line_vw'
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #tupd_stats 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        INSERT INTO #tupd_stats (company_code,section,viewName,viewDesc,totRecs,updates)
                SELECT @w_cc, section, Name1, description, @w_cursrec_rel_count, @w_cursrec_rel_upd
                        FROM imwbtables_vw 
                        WHERE Name1 = 'impur_rel_vw'
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #tupd_stats 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        SELECT @cnt = @cnt + 1
        END
    --    
    IF @ROLLBACK_On_Error = 'YES' BEGIN COMMIT TRANSACTION SET @ROLLBACK_On_Error = 'NO' END
    INSERT INTO imlog 
            SELECT getdate(), 'PO', 1, '', '', '', 'Purchase Order ' + RTRIM(LTRIM(ISNULL(ISNULL(viewDesc, ''), ''))) + ', Total Records: ' + CAST(ISNULL(totRecs, 0) AS VARCHAR) + ', Updates: ' + CAST(ISNULL(updates, 0) AS VARCHAR), @userid
            FROM #tupd_stats
Exit_Return:            
    DROP TABLE #tupd_stats
    INSERT INTO imlog VALUES (getdate(), 'PO', 1, '', '', '', 'Purchase Order -- End', @userid)
    RETURN 0
Error_Return:
    IF @hdr_cursor_Cursor_Opened = 'YES'
        CLOSE hdr_cursor
    IF @hdr_cursor_Cursor_Allocated = 'YES'
        DEALLOCATE hdr_cursor
    INSERT INTO imlog VALUES (getdate(), 'PO', 1, '', '', '', 'Purchase Order -- End (ERROR)', @userid)
    RETURN -1    
GO
GRANT EXECUTE ON  [dbo].[imPurIns_sp] TO [public]
GO
