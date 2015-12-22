SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


    CREATE PROCEDURE 
[dbo].[imPurVal_sp] (@p_batchno          int = 0,
             @p_start_rec        int = 0,
             @p_end_rec         int = 0,
             @p_record_type        int = 0x00000FFF,
             @debug_level         int = 0,
             @userid INT = 0,
             @default_part_no    VARCHAR(30) = 'UPGRADE') 
    AS
    DECLARE @Automatically_Assign_Order_Numbers VARCHAR(100)
    DECLARE @w_cc            varchar(8)
    DECLARE @w_dmsg            varchar(255)
    DECLARE @w_highest_po_no    int
    DECLARE @prev_po_key        INT
    DECLARE @po_key            INT
    DECLARE @record_id_num        INT
    DECLARE @cntr            INT
    DECLARE @ext            CHAR(2)
    DECLARE @record_type        INT
    DECLARE @result            INT
    DECLARE @home_currency        VARCHAR(8)
    DECLARE @oper_currency        VARCHAR(8)
    DECLARE @part_no_cursor_Cursor_Allocated VARCHAR(3)
    DECLARE @part_no_cursor_Cursor_Opened VARCHAR(3)
    DECLARE @ADMorg	VARCHAR(30)
    DECLARE @ERR_PUR_R_POPART    int
    DECLARE @ERR_PUR_R_CONFIRM    int
    DECLARE @ERR_PUR_R_POLINEERR    int
    DECLARE @ERR_PUR_R_ALL        int
    DECLARE @RECTYPE_PUR_HDR    int
    DECLARE @RECTYPE_PUR_LINE    int
    DECLARE @RECTYPE_PUR_REL    int
    DECLARE @ERR_PUR_PONO        int
    DECLARE @ERR_PUR_STATUS        int
    DECLARE @ERR_PUR_PRINTFLAG    int
    DECLARE @ERR_PUR_VENDORCODE    int
    DECLARE @ERR_PUR_SHIP_TO_NO    int
    DECLARE @ERR_PUR_SHIP_NAME    int
    DECLARE @ERR_PUR_SHIP_VIA    int
    DECLARE @ERR_PUR_FOB        int
    DECLARE @ERR_PUR_TAXCODE    int
    DECLARE @ERR_PUR_LOC        int
    DECLARE @ERR_PUR_BUYER        int
    DECLARE @ERR_PUR_TERMS        int
    DECLARE @ERR_PUR_POSTN_CODE    int
    DECLARE @ERR_PUR_HOLDCODE    int
    DECLARE @ERR_PUR_CURR        int
    DECLARE @ERR_PUR_NOLIN        int
    DECLARE @ERR_PUR_INVLD_LIN    int
    DECLARE @ERR_PUR_DUP        int
    DECLARE @ERR_PUR_HDR_1        int
    DECLARE @ERR_PUR_MC        int
    DECLARE @ERR_PUR_HDR_2        int
    DECLARE @ERR_PUR_L_LINENO    int
    DECLARE @ERR_PUR_L_ORDNO    int
    DECLARE @ERR_PUR_L_PARTNO    int
    DECLARE @ERR_PUR_L_PARTNO_OPPOSITE INT
    DECLARE @ERR_PUR_L_LOCATION    int
    DECLARE @ERR_PUR_L_LOCATION_OPPOSITE INT
    DECLARE @ERR_PUR_L_PROJCODE    int
    DECLARE @ERR_PUR_L_PARTTYPE    int
    DECLARE @ERR_PUR_L_ACCTCODE    int
    DECLARE @ERR_PUR_L_ACCT_ORG    int				--eleal 7/5/05
    DECLARE @ERR_PUR_L_REFCODE    int
    DECLARE @ERR_PUR_L_UNITMEASURE    int
    DECLARE @ERR_PUR_L_PARTDUP    int
    DECLARE @ERR_PUR_L_RECLOC    int				-- mls 1/11/05
    DECLARE @ERR_PUR_L_SHIPTO    int				-- mls 1/11/05
    DECLARE @ERR_PUR_LINE_1        int
    DECLARE @ERR_PUR_LINE_2        int

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
    INSERT INTO imlog VALUES (getdate(), 'PO', 1, '', '', '', 'Purchase Order -- Begin (Validation) -- 7.3', @userid) 
    
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
        EXEC imPurVal_e7_sp @p_batchno = @p_batchno,
                            @p_start_rec = @p_start_rec,
                            @p_end_rec = @p_end_rec,
                            @p_record_type = @p_record_type,
                            @p_debug_level = @debug_level,
                            @default_part_no = @default_part_no
        RETURN 0
        END
    --
    SET @Routine_Name = 'imPurVal_sp'
    SET @part_no_cursor_Cursor_Allocated = 'NO'
    SET @part_no_cursor_Cursor_Opened = 'NO'
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
    SELECT @w_cc = company_code, 
           @home_currency = home_currency, 
           @oper_currency = oper_currency
            FROM [glco]    
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' glco 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    IF @debug_level > 0
        begin
        SET NOCOUNT OFF
        SELECT @p_batchno as Batch, @p_start_rec as Start_Record, @p_end_rec as End_Record
        SELECT @w_dmsg = 'Company=' + @w_cc
        print @w_dmsg
        END
    create table #t99 (record_id_num int constraint t1_pur_key unique nonclustered (record_id_num))
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATETABLE + ' #t99' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- If the Release record types are being validated then also validate the line
    -- records that they are generated from
    --
    SELECT @record_type = @p_record_type
    IF @p_record_type & 0x00000100 > 0
        BEGIN
        SELECT @record_type = @p_record_type | 0x00000010
        END
    --
    -- Create table #t99 which will contain a list of record_id_num values of records to 
    -- be processed.  Note that due to the use of this table, this is one of the few places 
    -- that [User_ID] needs to be checked.
    --     
    IF @p_batchno > 0
        BEGIN
        INSERT INTO #t99
                SELECT record_id_num
                        FROM impur_vw
                        WHERE company_code = @w_cc
                                AND process_status = 0
                                AND batch_no = @p_batchno
                                AND ([User_ID] = @userid OR @userid = 0)
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #t99 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        END
    ELSE
        BEGIN
        IF @p_end_rec > 0
            BEGIN
            INSERT INTO #t99
                    SELECT record_id_num
                            FROM impur_vw
                            WHERE company_code = @w_cc
                                    AND process_status = 0
                                    AND record_id_num >= @p_start_rec
                                    AND record_id_num <= @p_end_rec
                                    AND ([User_ID] = @userid OR @userid = 0)
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #t99 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            END
        ELSE
            BEGIN
            INSERT INTO #t99
                    SELECT record_id_num
                            FROM impur_vw
                            WHERE company_code = @w_cc
                                    AND process_status = 0
                                    AND record_id_num >= @p_start_rec
                                    AND ([User_ID] = @userid OR @userid = 0)
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #t99 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            END
        END
    IF @debug_level > 0
        begin
        SELECT @w_cc as company_code, @p_batchno as Batch, @p_start_rec as Start_Record, @p_end_rec as End_Record
        SELECT * FROM #t99
        end
    set @RECTYPE_PUR_HDR =             0x00000001
    set @RECTYPE_PUR_LINE =            0x00000010
    set @RECTYPE_PUR_REL =             0x00000100
    --
    -- Header and Line record_status_1 bits.
    --
    set @ERR_PUR_PONO =                0x00000001
    set @ERR_PUR_STATUS =              0x00000002
    set @ERR_PUR_PRINTFLAG =           0x00000004
    set @ERR_PUR_VENDORCODE =          0x00000008
    set @ERR_PUR_SHIP_TO_NO =          0x00000010
    set @ERR_PUR_SHIP_NAME =           0x00000020 -- *** not set in initial bit combination
    set @ERR_PUR_SHIP_VIA =            0x00000040
    set @ERR_PUR_FOB =                 0x00000080
    set @ERR_PUR_TAXCODE =             0x00000100
    set @ERR_PUR_LOC =                 0x00000200
    set @ERR_PUR_BUYER =               0x00000400
    set @ERR_PUR_TERMS =               0x00000800
    set @ERR_PUR_POSTN_CODE =          0x00001000
    set @ERR_PUR_HOLDCODE =            0x00002000
    set @ERR_PUR_CURR =                0x00004000
    set @ERR_PUR_NOLIN =               0x00008000
    set @ERR_PUR_L_LINENO =            0x00010000
    set @ERR_PUR_R_CONFIRM =           0x00020000 -- *** not used
                                    -- 0x00040000
    set @ERR_PUR_INVLD_LIN =           0x00080000 -- *** not set in initial bit combination
    set @ERR_PUR_L_ORDNO =             0x00100000
    set @ERR_PUR_L_PARTNO =            0x00200000
    set @ERR_PUR_L_LOCATION =          0x00400000
    set @ERR_PUR_L_RECLOC =	       0x00800000 -- mls 1/11/05
    set @ERR_PUR_L_UNITMEASURE =       0x01000000
    set @ERR_PUR_L_PARTTYPE =          0x02000000
    set @ERR_PUR_L_ACCTCODE =          0x04000000
    set @ERR_PUR_L_ACCT_ORG =	       0x08000000 -- eleal 7/5/05
    set @ERR_PUR_DUP =                 0x08000000
    set @ERR_PUR_L_PROJCODE =          0x10000000 -- *** not set in initial bit combination
    set @ERR_PUR_L_REFCODE =           0x20000000 -- *** not set in initial bit combination
    set @ERR_PUR_L_SHIPTO =	       0x00000001 -- mls 1/11/05
    --
    SET @ERR_PUR_L_PARTNO_OPPOSITE =   0xFFDFFFFF
    SET @ERR_PUR_L_LOCATION_OPPOSITE = 0xFFBFFFFF
    --
    -- Header record_status_1 bit combinations.
    --
    set @ERR_PUR_HDR_1 = @ERR_PUR_PONO + @ERR_PUR_STATUS + @ERR_PUR_PRINTFLAG + @ERR_PUR_VENDORCODE
        + @ERR_PUR_SHIP_TO_NO + @ERR_PUR_SHIP_VIA
        + @ERR_PUR_FOB + @ERR_PUR_TAXCODE + @ERR_PUR_BUYER + @ERR_PUR_TERMS
        + @ERR_PUR_HOLDCODE + @ERR_PUR_CURR + @ERR_PUR_NOLIN
        + @ERR_PUR_LOC + @ERR_PUR_POSTN_CODE  + @ERR_PUR_DUP
    --
    -- Header and Line record_status_2 bits.
    --
    set @ERR_PUR_MC =                  0x00000002 -- *** not set in initial bit combination
    set @ERR_PUR_L_PARTDUP =           0x00000008 -- *** not set in initial bit combination
    --
    -- Header record_status_2 bit combinations.
    --
    set @ERR_PUR_HDR_2 =               0x00000000
    --
    -- Line record_status_1 bit combinations.
    --
    set @ERR_PUR_LINE_1 = @ERR_PUR_L_ORDNO + @ERR_PUR_L_PARTNO + @ERR_PUR_L_LOCATION
        + @ERR_PUR_L_UNITMEASURE + @ERR_PUR_L_PARTTYPE
        + @ERR_PUR_L_ACCTCODE + @ERR_PUR_L_LINENO
        + @ERR_PUR_TAXCODE + @ERR_PUR_STATUS
	+ @ERR_PUR_L_RECLOC				-- mls 1/11/05
	+ @ERR_PUR_L_ACCT_ORG				-- eleal 7/5/05

    set @ERR_PUR_LINE_2 = @ERR_PUR_L_SHIPTO		-- mls 1/11/05
    --
    -- Releases record_status_1 bits.
    --
    set @ERR_PUR_R_POPART = 0x00010000
    set @ERR_PUR_R_POLINEERR = 0x00040000
    --
    -- Releases record_status_1 bit combinations.
    --
    select @ERR_PUR_R_ALL = @ERR_PUR_R_POPART + @ERR_PUR_R_POLINEERR
    --
    -- set error bits on
    --
    UPDATE impur_vw
            SET record_status_1 = 0,
                record_status_2 = 0
            FROM impur_vw, #t99
            WHERE impur_vw.record_id_num = #t99.record_id_num
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_vw 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE impur_hdr_vw
            SET record_status_1 = record_status_1 | @ERR_PUR_HDR_1,
                record_status_2 = record_status_2 | @ERR_PUR_HDR_2,
		date_of_order = isnull(date_of_order,getdate())		-- mls 1/11/05
            FROM impur_hdr_vw, #t99
            WHERE impur_hdr_vw.record_id_num = #t99.record_id_num
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_hdr_vw 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE impur_line_vw
            SET record_status_1 = record_status_1 | @ERR_PUR_LINE_1,
		record_status_2 = record_status_2 | @ERR_PUR_LINE_2	-- mls 1/11/05
            FROM impur_line_vw, #t99
            WHERE impur_line_vw.record_id_num = #t99.record_id_num
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_line_vw 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE impur_rel_vw
            SET record_status_2 = record_status_2 | @ERR_PUR_R_ALL
            FROM impur_rel_vw, #t99
            WHERE impur_rel_vw.record_id_num = #t99.record_id_num
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_rel_vw 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Validate order header
    --
    -- If Import Manager will automatically assign order numbers, then assume that
    -- all existing values are valid since they will be overwritten.
    -- 
    IF @Automatically_Assign_Order_Numbers = 'YES'
        BEGIN
        UPDATE [impur_hdr_vw]
                SET [record_status_1] = [record_status_1] ^ @ERR_PUR_PONO
                FROM [impur_hdr_vw]
                INNER JOIN [#t99]
                        ON [impur_hdr_vw].[record_id_num] = [#t99].[record_id_num]
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_hdr_vw 2A' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        END
    ELSE    
        BEGIN
        SELECT @w_highest_po_no = [last_no]
                FROM [next_po_no]
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' next_po_no 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        UPDATE [impur_hdr_vw]
                SET [record_status_1] = [record_status_1] ^ @ERR_PUR_PONO
                FROM [impur_hdr_vw]
                INNER JOIN [#t99]
                        ON [impur_hdr_vw].[record_id_num] = [#t99].[record_id_num]
                WHERE [po_key] between 0 and @w_highest_po_no
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_hdr_vw 2B' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        END
    --    
    UPDATE impur_hdr_vw
            SET record_status_1 = record_status_1 ^ @ERR_PUR_STATUS
            FROM impur_hdr_vw, #t99
            WHERE impur_hdr_vw.record_id_num = #t99.record_id_num
                    AND     impur_hdr_vw.status in ('O', 'C', 'H')
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_hdr_vw 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE impur_hdr_vw
            SET record_status_1 = record_status_1 ^ @ERR_PUR_PRINTFLAG
            FROM impur_hdr_vw,    #t99 
            WHERE impur_hdr_vw.record_id_num = #t99.record_id_num
                    AND     impur_hdr_vw.printed in ('H', 'N', 'P', 'Y')
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_hdr_vw 4' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE h
            SET record_status_1 = record_status_1 ^ @ERR_PUR_VENDORCODE,
              vendor_no = v.vendor_code,						-- mls 1/11/05
              tax_code = case when isnull(h.tax_code,'') = '' then v.tax_code else h.tax_code end,
              terms = case when isnull(h.terms,'') = '' then v.terms_code else h.terms end,
              ship_via = case when isnull(h.ship_via,'') = '' then v.freight_code else h.ship_via end,
              fob = case when isnull(h.fob,'') = '' then v.fob_code else h.fob end,

              posting_code = case when isnull(h.posting_code,'') = '' then v.posting_code else h.posting_code end,
              rate_type_home = case when isnull(h.rate_type_home,'') = '' then v.rate_type_home else h.rate_type_home end,
              rate_type_oper = case when isnull(h.rate_type_oper,'') = '' then v.rate_type_oper else h.rate_type_oper end,
              curr_key = case when isnull(h.curr_key,'') = '' then v.nat_cur_code else h.curr_key end
              
            FROM impur_hdr_vw h, apvend v, #t99
            WHERE h.record_id_num = #t99.record_id_num
                    AND     h.vendor_no = v.vendor_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_hdr_vw 5' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Assign default values.
    --


































































    --
    -- Update multi currency information
    --
    CREATE TABLE #rates (from_currency varchar(8), 
                         to_currency varchar(8), 
                         rate_type varchar(8), 
                         date_applied int, 
                         rate float)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATETABLE + ' #rates 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

    create index r1 on #rates (from_currency,to_currency, rate_type, date_applied)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATETABLE + ' #rates 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

    INSERT INTO #rates
            SELECT hdr.curr_key, @home_currency, hdr.rate_type_home, DATEDIFF(DD, "1/1/80", date_of_order)+722815, 0.0
            FROM impur_hdr_vw hdr, #t99
            WHERE hdr.record_id_num = #t99.record_id_num
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #rates 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

    INSERT INTO #rates
            SELECT hdr.curr_key, @oper_currency, hdr.rate_type_oper, DATEDIFF(DD, '1/1/80', date_of_order)+722815, 0.0
            FROM impur_hdr_vw hdr, #t99
            WHERE hdr.record_id_num = #t99.record_id_num
            and not exists (select 1 from #rates r where r.from_currency = hdr.curr_key and
              r.to_currency = @oper_currency and r.rate_type = hdr.rate_type_oper and
              r.date_applied = DATEDIFF(DD, '1/1/80', date_of_order)+722815)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #rates 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

    EXEC [CVO_Control]..[mcrates_sp]
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' [CVO_Control]..mcrates_sp 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    IF (@debug_level >= 3)  
        BEGIN
        SELECT "hdr.rate_type_home #rates table"
        SELECT * FROM #rates
        END
    UPDATE hdr
            SET curr_factor = #rates.rate
            FROM impur_hdr_vw hdr, #t99, #rates
            WHERE hdr.record_id_num = #t99.record_id_num
                    AND hdr.curr_key = #rates.from_currency
                    and #rates.to_currency = @home_currency
                    AND hdr.rate_type_home = #rates.rate_type
                    AND DATEDIFF(DD, "1/1/80", date_of_order)+722815 = #rates.date_applied
                    AND #rates.rate <> 0.0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_hdr_vw 14' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
















    UPDATE hdr
            SET oper_factor = #rates.rate
            FROM impur_hdr_vw hdr, #t99, #rates
            WHERE hdr.record_id_num = #t99.record_id_num
                    AND hdr.curr_key = #rates.from_currency
                    and #rates.to_currency = @oper_currency
                    AND hdr.rate_type_oper = #rates.rate_type
                    AND DATEDIFF(DD, "1/1/80", date_of_order)+722815 = #rates.date_applied
                    AND #rates.rate <> 0.0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_hdr_vw 15' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

    UPDATE line
            SET curr_factor = hdr.curr_factor,
              oper_factor = hdr.oper_factor,
              curr_cost = isnull(curr_cost,0),
              unit_cost = isnull(round(case when hdr.curr_factor < 0 then line.curr_cost / abs(hdr.curr_factor) else line.curr_cost * abs(hdr.curr_factor) end,8),0),
              oper_cost = isnull(round(case when hdr.oper_factor < 0 then line.curr_cost / abs(hdr.oper_factor) else line.curr_cost * abs(hdr.oper_factor) end,8),0)
            FROM impur_hdr_vw hdr, impur_line_vw line, #t99
            WHERE line.record_id_num = #t99.record_id_num
                    AND hdr.po_key = line.po_key

    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_line_vw 7' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
















































































  DROP TABLE #rates
    UPDATE impur_hdr_vw
            SET record_status_1 = record_status_1 ^ @ERR_PUR_SHIP_TO_NO,
	      ship_to_no = locations.location
            FROM impur_hdr_vw,
                locations,     #t99
            WHERE impur_hdr_vw.record_id_num = #t99.record_id_num
                    AND     impur_hdr_vw.ship_to_no = locations.location
                    AND     impur_hdr_vw.location <> 'DROP'
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_hdr_vw 16' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- If the ship to is valid, then overwrite the address
    -- with the location address information
    --
    UPDATE hdr
            SET ship_name = loc.name,
                ship_address1 = loc.addr1,
                ship_address2 = loc.addr2,
                ship_address3 = loc.addr3,
                ship_address4 = loc.addr4,
                ship_address5 = loc.addr5
            FROM impur_hdr_vw hdr,     #t99,
                locations loc
            WHERE hdr.record_id_num = #t99.record_id_num
                    AND hdr.ship_to_no = loc.location
                    AND hdr.ship_to_no <> 'DROP'
                    AND (hdr.record_status_1 & @ERR_PUR_SHIP_TO_NO) = 0        
                    AND isnull(hdr.ship_name,'') = ''
                    AND isnull(hdr.ship_address1,'') = ''
                    AND isnull(hdr.ship_address1,'') = ''
                    AND isnull(hdr.ship_address3,'') = ''
                    AND isnull(hdr.ship_address4,'') = ''
                    AND isnull(hdr.ship_address5,'') = ''
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_hdr_vw 17' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- the only other valid possibility is for this to be a
    -- drop shipment; in that case overwrite the address info.
    -- with the info. from the vendor.
    --
    UPDATE hdr
            SET record_status_1 = hdr.record_status_1 ^ @ERR_PUR_SHIP_TO_NO
            FROM impur_hdr_vw hdr,     #t99,
                apvend apv
            WHERE hdr.record_id_num = #t99.record_id_num
                    AND UPPER(hdr.ship_to_no) = 'DROP'
                    AND (hdr.record_status_1 & @ERR_PUR_VENDORCODE) = 0
                    AND (hdr.record_status_1 & @ERR_PUR_SHIP_TO_NO) > 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_hdr_vw 18' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE hdr
            SET record_status_1 = record_status_1 ^ @ERR_PUR_SHIP_VIA,
	      ship_via = arshipv.ship_via_code
            FROM impur_hdr_vw hdr,     #t99,
                arshipv
            WHERE hdr.record_id_num = #t99.record_id_num
                    AND hdr.ship_via = arshipv.ship_via_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_hdr_vw 19' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE impur_hdr_vw
            SET record_status_1 = record_status_1 ^ @ERR_PUR_FOB,
             fob = apfob.fob_code
            FROM impur_hdr_vw,     #t99,
                apfob
            WHERE impur_hdr_vw.record_id_num = #t99.record_id_num
                    AND impur_hdr_vw.fob = apfob.fob_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_hdr_vw 20' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE impur_hdr_vw
            SET record_status_1 = record_status_1 ^ @ERR_PUR_TAXCODE,
              tax_code = aptax.tax_code
            FROM impur_hdr_vw,     #t99,
                aptax
            WHERE impur_hdr_vw.record_id_num = #t99.record_id_num
                    AND impur_hdr_vw.tax_code = aptax.tax_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_hdr_vw 21' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE impur_hdr_vw
            SET record_status_1 = record_status_1 ^ @ERR_PUR_LOC,
              location = locations.location
            FROM impur_hdr_vw,     #t99,
                locations
            WHERE impur_hdr_vw.record_id_num = #t99.record_id_num
                    AND impur_hdr_vw.location = locations.location
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_hdr_vw 22' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE impur_hdr_vw
            SET record_status_1 = record_status_1 ^ @ERR_PUR_BUYER,
              buyer = buyers.kys
            FROM impur_hdr_vw,     #t99,
                buyers
            WHERE impur_hdr_vw.record_id_num = #t99.record_id_num
                    AND impur_hdr_vw.buyer = buyers.kys
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_hdr_vw 23' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE impur_hdr_vw
            SET record_status_1 = record_status_1 ^ @ERR_PUR_BUYER
            FROM impur_hdr_vw,     #t99
            WHERE impur_hdr_vw.record_id_num = #t99.record_id_num
                    AND (record_status_1 & @ERR_PUR_BUYER) > 0
                    AND (buyer <= ' ' or buyer is null)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_hdr_vw 24' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE impur_hdr_vw
            SET record_status_1 = record_status_1 ^ @ERR_PUR_TERMS,
              terms = apterms.terms_code
            FROM impur_hdr_vw,     #t99,
                apterms
            WHERE impur_hdr_vw.record_id_num = #t99.record_id_num
                    AND impur_hdr_vw.terms = apterms.terms_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_hdr_vw 25' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE impur_hdr_vw
            SET record_status_1 = record_status_1 ^ @ERR_PUR_POSTN_CODE,
              posting_code = apaccts.posting_code
            FROM impur_hdr_vw,     #t99,
                apaccts
            WHERE impur_hdr_vw.record_id_num = #t99.record_id_num
                    AND impur_hdr_vw.posting_code = apaccts.posting_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_hdr_vw 26' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- turn the HOLDCODE error off where the status does not
    -- indicate a hold in effect.
    --
    UPDATE impur_hdr_vw
            SET record_status_1 = record_status_1 ^ @ERR_PUR_HOLDCODE
            FROM impur_hdr_vw,     #t99
            WHERE impur_hdr_vw.record_id_num = #t99.record_id_num
                    AND impur_hdr_vw.status <> 'H'
                    AND (record_status_1 & @ERR_PUR_STATUS) = 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_hdr_vw 27' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE impur_hdr_vw
            SET record_status_1 = record_status_1 ^ @ERR_PUR_HOLDCODE,
              hold_reason = adm_pohold.hold_code
            FROM impur_hdr_vw,     #t99,
                adm_pohold
            WHERE impur_hdr_vw.record_id_num = #t99.record_id_num
                    AND (record_status_1 & @ERR_PUR_HOLDCODE) > 0
                    AND impur_hdr_vw.hold_reason = adm_pohold.hold_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_hdr_vw 28' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE impur_hdr_vw
            SET record_status_1 = record_status_1 ^ @ERR_PUR_CURR,
              curr_key = currency_code
            FROM impur_hdr_vw,     #t99,
                glcurr_vw
            WHERE impur_hdr_vw.record_id_num = #t99.record_id_num
                    AND impur_hdr_vw.curr_key = glcurr_vw.currency_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_hdr_vw 29' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE impur_hdr_vw
            SET record_status_1 = record_status_1 ^ @ERR_PUR_DUP
            FROM (SELECT COUNT(*) AS _count,
                         po_key
                          FROM impur_hdr_vw
                          WHERE company_code = @w_cc
                                  AND process_status = 0
                          GROUP BY po_key
                          HAVING COUNT(*) = 1) AS singles, #t99
            WHERE impur_hdr_vw.record_id_num = #t99.record_id_num
                    AND impur_hdr_vw.po_key = singles.po_key
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_hdr_vw 30' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    IF NOT @Automatically_Assign_Order_Numbers = 'YES'
        BEGIN
        UPDATE [impur_hdr_vw]
                SET [record_status_1] = [record_status_1] | @ERR_PUR_DUP
                FROM [impur_hdr_vw]
                INNER JOIN [#t99]
                        ON [impur_hdr_vw].[record_id_num] = [#t99].[record_id_num]
                INNER JOIN [purchase]
                        ON [impur_hdr_vw].[po_key] = [purchase].[po_key]
                WHERE ([record_status_1] & @ERR_PUR_DUP) = 0        
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_hdr_vw 31' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        END
    UPDATE impur_hdr_vw
            SET impur_hdr_vw.record_status_1 = impur_hdr_vw.record_status_1 ^ @ERR_PUR_NOLIN
            FROM impur_hdr_vw,     #t99,
                impur_line_vw
            WHERE impur_hdr_vw.record_id_num = #t99.record_id_num
                    AND impur_hdr_vw.po_key = impur_line_vw.po_key
                    AND impur_line_vw.company_code = @w_cc
                    AND impur_line_vw.process_status = 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_hdr_vw 32' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE impur_hdr_vw
            SET impur_hdr_vw.record_status_1 = impur_hdr_vw.record_status_1 ^ @ERR_PUR_SHIP_NAME
            FROM impur_hdr_vw,     #t99
            WHERE impur_hdr_vw.record_status_1 = #t99.record_id_num
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_hdr_vw 33' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE impur_hdr_vw
            SET impur_hdr_vw.record_status_2 = impur_hdr_vw.record_status_2 | @ERR_PUR_MC
            FROM impur_hdr_vw, #t99
            WHERE impur_hdr_vw.record_id_num = #t99.record_id_num
                    AND (impur_hdr_vw.curr_factor IS NULL OR impur_hdr_vw.oper_factor IS NULL)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_hdr_vw 34' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE impur_line_vw
            SET impur_line_vw.record_status_2 = impur_line_vw.record_status_2 | @ERR_PUR_MC
            FROM impur_line_vw, #t99
            WHERE impur_line_vw.record_id_num = #t99.record_id_num
                    AND (impur_line_vw.curr_factor IS NULL OR impur_line_vw.oper_factor IS NULL)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_hdr_vw 35' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- line validations
    --
    UPDATE impur_line_vw
            SET record_status_1 = record_status_1 ^ @ERR_PUR_STATUS
            FROM impur_line_vw,     #t99
            WHERE impur_line_vw.record_id_num = #t99.record_id_num
                    AND (impur_line_vw.record_status_1 & @ERR_PUR_STATUS) > 0
                    AND impur_line_vw.status in ( 'O','C','H' )
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_line_vw 8' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- if the tax code is blank, the as the eDist client does
    -- assume that the tax code for the line, will be the same
    -- as the tax code for the header
    --
    UPDATE impur_line_vw
            SET impur_line_vw.tax_code = impur_hdr_vw.tax_code
            FROM impur_line_vw,     #t99,
                impur_hdr_vw
            WHERE impur_line_vw.record_id_num = #t99.record_id_num
                AND impur_line_vw.po_key = impur_hdr_vw.po_key
                AND (impur_hdr_vw.record_status_1 & @ERR_PUR_DUP) = 0
                AND (impur_line_vw.tax_code = '' OR impur_line_vw.tax_code IS NULL)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_line_vw 9' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE impur_line_vw
            SET record_status_1 = record_status_1 ^  @ERR_PUR_TAXCODE,
		tax_code = aptax.tax_code
            FROM impur_line_vw,     #t99, 
                aptax
            WHERE impur_line_vw.record_id_num = #t99.record_id_num
                    AND (impur_line_vw.record_status_1 & @ERR_PUR_TAXCODE) > 0
                    AND impur_line_vw.tax_code = aptax.tax_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_line_vw 10' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    SELECT @prev_po_key = -1
    DECLARE part_no_cursor INSENSITIVE CURSOR FOR 
            SELECT im.po_key, im.record_id_num
                    FROM impur_line_vw im, #t99
                    WHERE ISNULL(DATALENGTH(RTRIM(LTRIM(part_no))),0) = 0
                            AND im.record_id_num = #t99.record_id_num
                    ORDER BY po_key
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DECLARE + ' part_no_cursor 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    SET @part_no_cursor_Cursor_Allocated = 'YES'
    OPEN part_no_cursor
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_OPEN + ' part_no_cursor 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    SET @part_no_cursor_Cursor_Opened = 'YES'
    FETCH NEXT 
            FROM part_no_cursor 
            INTO @po_key, @record_id_num
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_FETCHNEXT + ' part_no_cursor 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    WHILE (@@FETCH_STATUS <> -1)
        BEGIN
        IF @@FETCH_STATUS <> -2
            BEGIN
            IF @po_key <> @prev_po_key
                BEGIN
                SELECT @prev_po_key = @po_key, @cntr = 0
                END
            IF @cntr < 10
                SELECT @ext = '0' + CONVERT(CHAR,@cntr)
            ELSE
                SELECT @ext = CONVERT(CHAR,@cntr)
            UPDATE impur_line_vw
                    SET part_no = RTRIM(LTRIM(@default_part_no)) + @ext,
		      type = 'M'
                    WHERE record_id_num = @record_id_num
            SELECT @cntr = @cntr + 1
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_line_vw 11' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            END
        FETCH NEXT 
                FROM part_no_cursor 
                INTO @po_key, @record_id_num
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_FETCHNEXT + ' part_no_cursor 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        END
    CLOSE part_no_cursor
    SET @part_no_cursor_Cursor_Opened = 'NO'
    DEALLOCATE part_no_cursor
    SET @part_no_cursor_Cursor_Allocated = 'NO'
    --
    -- Since the @ERR_PUR_L_PARTNO bit was set earlier, remove it here for all valid
    -- part numbers.  For those with type 'M', there will not be a record in inv_master
    -- so it will appear that the part is invalid.  In the case of type 'M', remove the 
    -- bit so the part is marked as valid.
    --
    UPDATE impur_line_vw
            SET record_status_1 = record_status_1 ^ @ERR_PUR_L_PARTNO,
              part_no = inv_master.part_no,
              type = 'P'
            FROM impur_line_vw, #t99, inv_master
            WHERE impur_line_vw.record_id_num = #t99.record_id_num
                    AND impur_line_vw.part_no = inv_master.part_no
                    AND inv_master.obsolete = 0
                    AND inv_master.void = 'N'
		    and upper(impur_line_vw.type) = 'P'		-- mls 1/11/05
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_line_vw 12' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE impur_line_vw
            SET record_status_1 = record_status_1 ^  @ERR_PUR_L_PARTNO,	-- mls 1/11/05
              type = 'M'
            FROM impur_line_vw
                    INNER JOIN #t99 ON impur_line_vw.record_id_num = #t99.record_id_num
            WHERE UPPER(impur_line_vw.type) = 'M'
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_line_vw 13' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Since the @ERR_PUR_L_LOCATION bit was set earlier, remove it here for all valid
    -- locations.  For those where the part is type 'M', there will not be a record in 
    -- inv_master so it will appear that the location is invalid.  In the case of type 'M', 
    -- remove the bit so the location is marked as valid.
    --
    UPDATE lin
            SET record_status_1 = lin.record_status_1 ^ @ERR_PUR_L_LOCATION,
                location = il.location,
                description = im.description,
                lb_tracking = im.lb_tracking,
                conv_factor = im.conv_factor,
                weight_ea = im.weight_ea
            FROM impur_line_vw lin, #t99, inv_list il, inv_master im
            WHERE lin.record_id_num = #t99.record_id_num
                    AND lin.part_no = il.part_no
                    AND lin.location = il.location
                    AND lin.part_no = im.part_no
                    AND (lin.record_status_1 & @ERR_PUR_L_PARTNO) = 0
		    and upper(lin.type) = 'P'		-- mls 1/11/05
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_line_vw 14' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

    -- mls 1/11/05 - changed to validate location for misc items
    UPDATE lin
            SET record_status_1 = lin.record_status_1 ^ @ERR_PUR_L_LOCATION,
                location = l.location,
                description = isnull(lin.description,lin.part_no),
                lb_tracking = 'N',
                conv_factor = 1,
                weight_ea = isnull(lin.weight_ea,0)
            FROM impur_line_vw lin, #t99, locations l
            WHERE lin.record_id_num = #t99.record_id_num
                    AND lin.location = l.location
		    and upper(lin.type) = 'M'		-- mls 1/11/05

    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_line_vw 15' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- If no unit of measure is supplied then, get the default
    -- unit of measure off of the item master (inv_master)
    --
    UPDATE lin
            SET uom = im.uom
            FROM impur_line_vw lin,     #t99,
                inv_master im
            WHERE lin.record_id_num = #t99.record_id_num
                    AND lin.part_no = im.part_no
                    AND (lin.uom = '' OR lin.uom IS NULL)
		    and upper(lin.type) = 'P'				-- mls 1/11/05

    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_line_vw 16' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE impur_line_vw
            SET record_status_1 = record_status_1 ^ @ERR_PUR_L_UNITMEASURE,
              uom = inv_master.uom
            FROM impur_line_vw,     #t99,
                inv_master
            WHERE impur_line_vw.record_id_num = #t99.record_id_num
                    AND impur_line_vw.part_no = inv_master.part_no
                    AND impur_line_vw.uom = inv_master.uom
                    AND (impur_line_vw.record_status_1 & @ERR_PUR_L_PARTNO) = 0
		    AND upper(impur_line_vw.type) = 'P'				-- mls 1/11/05 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_line_vw 17' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE impur_line_vw
            SET record_status_1 = record_status_1 ^ @ERR_PUR_L_UNITMEASURE,
              uom = uom_table.alt_uom
            FROM impur_line_vw,     #t99,
                inv_master,
                uom_table
            WHERE impur_line_vw.record_id_num = #t99.record_id_num
                    AND (impur_line_vw.record_status_1 & @ERR_PUR_L_UNITMEASURE) > 0
                    AND impur_line_vw.part_no = inv_master.part_no
                    AND (impur_line_vw.part_no = uom_table.item OR uom_table.item = 'STD')
                    AND inv_master.uom = uom_table.std_uom
                    AND impur_line_vw.uom = uom_table.alt_uom
		    AND upper(impur_line_vw.type) = 'P'				-- mls 1/11/05 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_line_vw 18' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- The @ERR_PUR_L_UNITMEASURE bit needs to be removed here for all records
    -- where the part is type 'M', since there will not be a record in inv_master 
    -- to validate against so it will appear that the UOM is invalid.
    --
    -- mls 1/11/05 - validate misc parts uom
    UPDATE impur_line_vw
            SET record_status_1 = record_status_1 ^ @ERR_PUR_L_UNITMEASURE,
              uom = uom_list.uom
            FROM impur_line_vw,     #t99,
                uom_list
            WHERE impur_line_vw.record_id_num = #t99.record_id_num
                    AND (impur_line_vw.record_status_1 & @ERR_PUR_L_UNITMEASURE) > 0
		    AND upper(impur_line_vw.type) = 'M'				-- mls 1/11/05 
                    AND (uom_list.void = 'N')
                    AND impur_line_vw.uom = uom_list.uom
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_line_vw 19' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

    UPDATE [impur_line_vw]
            SET [record_status_1] = [record_status_1] ^ @ERR_PUR_L_PARTTYPE,
              type = upper(impur_line_vw.type)	
            FROM [impur_line_vw]
            INNER JOIN [#t99]
                    ON [impur_line_vw].[record_id_num] = [#t99].[record_id_num]
            WHERE upper([impur_line_vw].[type]) IN ('P', 'M')
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_line_vw 20' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Check to see if the po_key = a valid po_key on a header record, if so
    -- then check to see if the only error on that header is a @ERR_PUR_INVALID_LIN
    -- error, then it can be assumed that the ERR_PUR_L_ORD_NO error can be turned off
    --
    UPDATE impur_line_vw
            SET record_status_1 = impur_line_vw.record_status_1 ^ @ERR_PUR_L_ORDNO
            FROM impur_line_vw, #t99, impur_hdr_vw
            WHERE impur_line_vw.record_id_num = #t99.record_id_num
                    AND impur_line_vw.po_key = impur_hdr_vw.po_key
                    AND impur_hdr_vw.company_code = @w_cc
                    AND impur_hdr_vw.process_status = 0
                    AND impur_hdr_vw.record_status_2 = 0
                    AND (impur_hdr_vw.record_status_1 = 0 OR impur_hdr_vw.record_status_1 = @ERR_PUR_INVLD_LIN)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_line_vw 21' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Update and check the account_no
    -- for parts of type P then the account_no will come from
    -- from the posting code on the header.
    --
    UPDATE impur_line_vw
            SET account_no = in_account.inv_acct_code,
                record_status_1 = impur_line_vw.record_status_1 ^ @ERR_PUR_L_ACCTCODE
            FROM impur_line_vw,     #t99,
                in_account,
                inv_list
            WHERE impur_line_vw.record_id_num = #t99.record_id_num
                    AND impur_line_vw.part_no = inv_list.part_no
                    AND impur_line_vw.location = inv_list.location
                    AND impur_line_vw.type = 'P'
                    AND inv_list.acct_code = in_account.acct_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_line_vw 22A' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE impur_line_vw
            SET record_status_1 = impur_line_vw.record_status_1 ^ @ERR_PUR_L_ACCTCODE,
              account_no = glchart.account_code
            FROM impur_line_vw,     #t99,
                glchart
            WHERE impur_line_vw.record_id_num = #t99.record_id_num
                    AND impur_line_vw.type = 'M'
                    AND impur_line_vw.account_no = glchart.account_code
                    AND glchart.inactive_flag = 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_line_vw 22B' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

    --
    --	The account_no must be from the configured Distribution Organization
    --  eleal 7/11/05
    --
    SELECT @ADMorg = value_str FROM config WHERE flag = 'INV_ORG_ID'
    UPDATE impur_line_vw
            SET record_status_1 = record_status_1 ^ @ERR_PUR_L_ACCT_ORG
            FROM impur_line_vw,     #t99
            WHERE impur_line_vw.record_id_num = #t99.record_id_num
                    AND dbo.IBOrgbyAcct_fn(impur_line_vw.account_no) = @ADMorg
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_line_vw 23A' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

    --
    --  Turn off organization account errors where the account code is invalid, because they will be meaningless.
    --  eleal 7/11/05
    --
    UPDATE impur_line_vw
            SET record_status_1 = record_status_1 ^ @ERR_PUR_L_ACCT_ORG
            FROM impur_line_vw,     #t99
            WHERE impur_line_vw.record_id_num = #t99.record_id_num
                    AND (impur_line_vw.record_status_1 & @ERR_PUR_L_ACCTCODE) > 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_line_vw 23B' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

    --
    -- Turn off errors where the part_no is invalid, because they will be meaningless.
    --
    UPDATE impur_line_vw
            SET record_status_1 = record_status_1 ^ @ERR_PUR_L_ACCTCODE
            FROM impur_line_vw,     #t99
            WHERE impur_line_vw.record_id_num = #t99.record_id_num
                    AND (impur_line_vw.record_status_1 & @ERR_PUR_L_PARTNO) > 0
                    AND (impur_line_vw.record_status_1 & @ERR_PUR_L_ACCTCODE) > 0
                    AND impur_line_vw.type = 'P'
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_line_vw 24' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    













    UPDATE impur_line_vw
            SET record_status_1 = record_status_1 ^ @ERR_PUR_L_LINENO
            FROM (SELECT COUNT(*) AS _count,
                         po_key,
                         line
                          FROM impur_line_vw
                          WHERE impur_line_vw.company_code = @w_cc
                                  AND impur_line_vw.process_status = 0
                                  AND impur_line_vw.line > 0
                          GROUP BY po_key,line
                          HAVING COUNT(*) = 1) AS v2, #t99
            WHERE impur_line_vw.record_id_num = #t99.record_id_num
                    AND impur_line_vw.po_key = v2.po_key
                    AND impur_line_vw.line = v2.line
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_line_vw 26' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

    -- mls 1/11/05 - changed to validate location receiving location
    UPDATE lin
            SET receiving_loc = location
            FROM impur_line_vw lin, #t99
            WHERE lin.record_id_num = #t99.record_id_num
		    and isnull(lin.receiving_loc,'') = ''
                    AND (lin.record_status_1 & @ERR_PUR_L_LOCATION) = 0

    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_line_vw 27' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

    UPDATE lin
            SET record_status_1 = lin.record_status_1 ^ @ERR_PUR_L_RECLOC,
              receiving_loc = l.location
            FROM impur_line_vw lin, #t99, locations l
            WHERE lin.record_id_num = #t99.record_id_num
		    and isnull(lin.receiving_loc,'') != ''
                    AND isnull(lin.receiving_loc,'') = l.location

    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_line_vw 28' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

    -- mls 1/11/05 - changed to validate ship to location
    UPDATE lin
            SET shipto_code = h.ship_to_no,
		shipto_name = h.ship_name,
		addr1 = h.ship_address1,		
		addr2 = h.ship_address2,		
		addr3 = h.ship_address3,		
		addr4 = h.ship_address4,		
		addr5 = h.ship_address5
            FROM impur_line_vw lin, #t99, impur_hdr_vw h
            WHERE lin.record_id_num = #t99.record_id_num
		    and h.po_key = lin.po_key and h.company_code = lin.company_code
		    and isnull(lin.shipto_code,'') = ''
                    AND (h.record_status_1 & @ERR_PUR_SHIP_TO_NO) = 0

    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_line_vw 29' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

    UPDATE lin
            SET record_status_2 = lin.record_status_2 ^ @ERR_PUR_L_SHIPTO,
              shipto_code = l.location
            FROM impur_line_vw lin, #t99, locations l
            WHERE lin.record_id_num = #t99.record_id_num
		    and isnull(lin.shipto_code,'') != ''
                    AND isnull(lin.shipto_code,'') = l.location

    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_line_vw 30' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

    --
    -- Recreate the releases records from the line records.  
    -- *** Note that the record_id_num values stored in #t99 for the releases records 
    -- *** are no longer valid after the INSERT and therefore no processing can be done 
    -- *** with the inserted records via the #t99 table.
    --
    DELETE impur_rel_vw
            FROM impur_rel_vw rel, impur_line_vw line, #t99
            WHERE line.record_id_num = #t99.record_id_num
                    AND line.company_code = rel.company_code
                    AND line.line = rel.line
                    AND line.po_key = rel.po_key
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DELETE + ' impur_rel_vw 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    INSERT INTO impur_rel_vw (po_key, type, part_no, lb_tracking, location, rel_date, prev_qty, qty_ordered, qty_received, conv_factor, status, line, batch_no, dirty_flag, record_status_1, record_status_2, process_status, company_code, record_type)
            SELECT line.po_key, type, line.part_no, lb_tracking, location, rel_date, prev_qty, qty_ordered, qty_received, conv_factor, status, line, batch_no, 1, 0, 0, 0, company_code, 256
            FROM impur_line_vw line, #t99
            WHERE #t99.record_id_num = line.record_id_num
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' impur_rel_vw 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    --
    -- End of line validations
    --
    -- Purchase order release validations.
    --
    UPDATE rel
            SET record_status_2 = rel.record_status_2 ^ @ERR_PUR_R_POPART
            FROM impur_rel_vw rel, #t99, impur_line_vw lin
            WHERE rel.record_id_num = #t99.record_id_num
                    AND rel.po_key = lin.po_key
                    AND rel.part_no = lin.part_no
                    AND rel.line = lin.line
                    AND lin.company_code = @w_cc
                    AND lin.process_status = 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_rel_vw 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- End of purchase order release validations.
    --
    -- Determine the po_key values for line records in error.
    --
    SELECT impur_line_vw.po_key
            INTO #polins
            FROM impur_line_vw, #t99
            WHERE impur_line_vw.record_id_num = #t99.record_id_num
                    AND (impur_line_vw.record_status_1 > 0 OR impur_line_vw.record_status_2 > 0)
                    AND impur_line_vw.process_status = 0
            GROUP BY po_key
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' impur_line_vw 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Set the error bit on for all headers that have lines that are in error.
    --
    UPDATE impur_hdr_vw
            SET record_status_1 = impur_hdr_vw.record_status_1 | @ERR_PUR_INVLD_LIN
            FROM #polins, #t99, impur_hdr_vw
            WHERE impur_hdr_vw.record_id_num = #t99.record_id_num
                    AND (impur_hdr_vw.record_status_1 & @ERR_PUR_INVLD_LIN) = 0
                    AND impur_hdr_vw.po_key = #polins.po_key
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' impur_hdr_vw 36' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    INSERT INTO imlog VALUES (getdate(), 'PO', 1, '', '', '', 'Purchase Order -- End', @userid)
    RETURN 0
Error_Return:
    IF @part_no_cursor_Cursor_Opened = 'YES'
        CLOSE part_no_cursor
    IF @part_no_cursor_Cursor_Allocated = 'YES'
        DEALLOCATE part_no_cursor
    INSERT INTO imlog VALUES (getdate(), 'PO', 1, '', '', '', 'Purchase Order -- End (ERROR)', @userid)
    RETURN -1    


GO
GRANT EXECUTE ON  [dbo].[imPurVal_sp] TO [public]
GO
