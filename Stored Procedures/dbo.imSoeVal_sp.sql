SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


    create procedure 
[dbo].[imSoeVal_sp] (@p_batchno INT = 0,
             @p_start_rec INT = 0,
             @p_end_rec INT = 0,
             @p_record_type INT = 0x000000FF,
             @debug_level INT = 0,
             @userid INT = 0)
    AS
    SET NOCOUNT ON
    DECLARE @Automatically_Assign_Order_Numbers VARCHAR(100)
    DECLARE @w_cc VARCHAR(8)
    DECLARE @w_dmsg CHAR(255)
    DECLARE @RECTYPE_OE_HDR INT
    DECLARE @RECTYPE_OE_LINE INT
    DECLARE @RECTYPE_OE_HIST INT
    
    DECLARE @ERR_OE_HDR INT
    DECLARE @ERR_OE_CUSTCODE INT
    DECLARE @ERR_OE_SHIPTO INT
    DECLARE @ERR_OE_TERMS INT
    DECLARE @ERR_OE_ROUTING INT
    DECLARE @ERR_OE_SHIPTOREG INT
    DECLARE @ERR_OE_SALES INT
    DECLARE @ERR_OE_TAXCODE INT
    DECLARE @ERR_OE_FWDR INT
    DECLARE @ERR_OE_FRTTO INT
    DECLARE @ERR_OE_LOC INT
    DECLARE @ERR_OE_CURR INT
    DECLARE @ERR_OE_BILLTO INT
    DECLARE @ERR_OE_POSTN_CODE INT
    DECLARE @ERR_OE_ZONE_CODE INT
    DECLARE @ERR_OE_RATE_TYPE INT
    DECLARE @ERR_OE_HOLD_REASON INT
    DECLARE @ERR_OE_PRINTCODE INT
    -- defined selection
    DECLARE @ERR_OE_STATUS INT
    DECLARE @ERR_OE_TYPE INT
    DECLARE @ERR_OE_BOFLG INT
    DECLARE @ERR_OE_ORDNO INT
    DECLARE @ERR_OE_INVLD_LIN INT
    DECLARE @ERR_OE_TOTALS INT
    DECLARE @ERR_OE_DUP INT
    DECLARE @ERR_IE_MC INT
    DECLARE @ERR_OE_NOLIN INT
    
    
    DECLARE @ERR_OE_LINE INT
    DECLARE @ERR_OE_L_ORDNO INT
    DECLARE @ERR_OE_L_PARTNO INT
    DECLARE @ERR_OE_L_LOCATION INT
    DECLARE @ERR_OE_L_UOM INT
    DECLARE @ERR_OE_L_TAXCODE INT
    DECLARE @ERR_OE_L_GLREF INT
    DECLARE @ERR_OE_L_DUP INT
    DECLARE @ERR_OE_L_PRICTYP INT
    DECLARE @ERR_OE_LBT_FLAG INT
    DECLARE @ERR_OE_L_LOCMISMATCH INT
    DECLARE @ERR_OE_L_DESCBLANK INT
    DECLARE @ERR_OE_L_PARTTYPE INT
    
    DECLARE @ERR_OE_LINE2 INT
    DECLARE @ERR_OE_L_ORDQTY INT
    DECLARE @precision_gl INT
    DECLARE @currency        VARCHAR(10)
    DECLARE @rate_type        VARCHAR(8)
    DECLARE @p_highest_pos_order_num INT
    DECLARE @ERR_OE_TRANSMIX INT
    DECLARE @ERR_OE_SHIP INT
    DECLARE @ERR_OE_SHIP2 INT
    
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
    INSERT INTO imlog VALUES (getdate(), 'SO', 1, '', '', '', 'Sales Order -- Begin (Validation) -- 7.3', @userid) 
    
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
        EXEC imSoeVal_e7_sp @p_batchno = @p_batchno,
                            @p_start_rec = @p_start_rec,
                            @p_end_rec = @p_end_rec,
                            @p_record_type = @p_record_type,
                            @p_debug_level = @debug_level
        RETURN 0
        END
    --
    SET @Routine_Name = 'imSoeVal_sp'
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
                OR (@Automatically_Assign_Order_Numbers <> 'NO' AND @Automatically_Assign_Order_Numbers <> 'YES' AND @Automatically_Assign_Order_Numbers <> 'TRUE' AND @Automatically_Assign_Order_Numbers <> 'FALSE')
            SET @Automatically_Assign_Order_Numbers = 'NO'
        IF @Automatically_Assign_Order_Numbers = 'TRUE'
            SET @Automatically_Assign_Order_Numbers = 'YES'
        END    
    --
    SELECT @w_cc = company_code from glco
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' glco 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    if @debug_level > 0
        begin
        SELECT @p_batchno as Batch, @p_start_rec as Start_Record, @p_end_rec as End_Record
        end
    --
    -- Create table #t1 which will contain a list of record_id_num values of records to 
    -- be processed.  Note that due to the use of this table, this is one of the few places 
    -- that [User_ID] needs to be checked.
    --    
    create table #t1 (record_id_num INT constraint imsoe_t1_key unique nonclustered (record_id_num))
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATETABLE + ' #t1 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    IF @p_batchno > 0
        BEGIN
        INSERT INTO #t1
                SELECT record_id_num
                FROM imsoe_vw
                WHERE company_code = @w_cc
                        AND process_status = 0
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
                            AND record_id_num >= @p_start_rec
                            AND ([User_ID] = @userid OR @userid = 0)
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #t1 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            END   
        END
    SELECT @RECTYPE_OE_HDR         = 0x00000001
    SELECT @RECTYPE_OE_LINE        = 0x00000002
    SELECT @RECTYPE_OE_HIST        = 0x00000010
    --
    -- record_status_1    
   

    SELECT @ERR_OE_CUSTCODE        = 0x00000001
    SELECT @ERR_OE_SHIPTO          = 0x00000002
    SELECT @ERR_OE_TERMS           = 0x00000004
    SELECT @ERR_OE_ROUTING         = 0x00000008
    SELECT @ERR_OE_SHIPTOREG       = 0x00000010
    SELECT @ERR_OE_SALES           = 0x00000020
    SELECT @ERR_OE_TAXCODE         = 0x00000040
    SELECT @ERR_OE_FWDR            = 0x00000080
    SELECT @ERR_OE_FRTTO           = 0x00000100
    SELECT @ERR_OE_LOC             = 0x00000200
    SELECT @ERR_OE_CURR            = 0x00000400
    SELECT @ERR_OE_BILLTO          = 0x00000800
    SELECT @ERR_OE_POSTN_CODE      = 0x00001000
    SELECT @ERR_OE_ZONE_CODE       = 0x00002000
    

    --
    -- record_status_2
    --
    SELECT @ERR_OE_RATE_TYPE       = 0x00000001
    SELECT @ERR_IE_MC              = 0x00000002
    SELECT @ERR_OE_L_ORDQTY        = 0x00000004
                                -- = 0x00000008
    SELECT @ERR_OE_HOLD_REASON     = 0x00000010
    SELECT @ERR_OE_PRINTCODE       = 0x00000020
    SELECT @ERR_OE_L_LOCMISMATCH   = 0x00000040
    SELECT @ERR_OE_L_DESCBLANK     = 0x00000080
    SELECT @ERR_OE_L_PARTTYPE      = 0x00000100
    	  			-- = 0x00000200
	                        -- = 0x00000400
                                -- = 0x00000800
                                -- = 0x00001000
                                -- = 0x00002000
    SELECT @ERR_OE_STATUS          = 0x00004000
    SELECT @ERR_OE_TYPE            = 0x00008000
    SELECT @ERR_OE_BOFLG           = 0x00010000
    SELECT @ERR_OE_TOTALS          = 0x00020000
    SELECT @ERR_OE_ORDNO           = 0x00040000
    SELECT @ERR_OE_INVLD_LIN       = 0x00080000
    SELECT @ERR_OE_L_ORDNO         = 0x00100000
    SELECT @ERR_OE_L_PARTNO        = 0x00200000
    SELECT @ERR_OE_L_LOCATION      = 0x00400000
    SELECT @ERR_OE_L_UOM           = 0x00800000
    SELECT @ERR_OE_L_TAXCODE       = 0x01000000
    SELECT @ERR_OE_L_GLREF         = 0x02000000
    SELECT @ERR_OE_L_DUP           = 0x04000000
    SELECT @ERR_OE_DUP             = 0x08000000
    SELECT @ERR_OE_NOLIN           = 0x10000000
    SELECT @ERR_OE_L_PRICTYP       = 0x20000000
    SELECT @ERR_OE_LBT_FLAG        = 0x40000000

    
    SET @ERR_OE_HDR = @ERR_OE_CUSTCODE + @ERR_OE_SHIPTO + @ERR_OE_TERMS + @ERR_OE_ROUTING
                    + @ERR_OE_SHIPTOREG + @ERR_OE_SALES + @ERR_OE_TAXCODE + @ERR_OE_FWDR             + @ERR_OE_FRTTO
                    + @ERR_OE_LOC + @ERR_OE_CURR + @ERR_OE_BILLTO + @ERR_OE_POSTN_CODE
                    + @ERR_OE_ZONE_CODE + @ERR_OE_STATUS + @ERR_OE_TYPE + @ERR_OE_BOFLG
                    + @ERR_OE_ORDNO + @ERR_OE_DUP + @ERR_OE_NOLIN 
    SET @ERR_OE_LINE = @ERR_OE_L_ORDNO + @ERR_OE_L_PARTNO + @ERR_OE_L_LOCATION
                     + @ERR_OE_L_TAXCODE + @ERR_OE_L_UOM + @ERR_OE_L_GLREF + @ERR_OE_L_DUP
                     + @ERR_OE_L_PRICTYP + @ERR_OE_STATUS
    SET @ERR_OE_LINE2 = @ERR_OE_L_ORDQTY + @ERR_OE_L_DESCBLANK + @ERR_OE_L_PARTTYPE  +@ERR_OE_LBT_FLAG
    SET @ERR_OE_TRANSMIX = 0x00000008
    SET @ERR_OE_SHIP = @ERR_OE_CUSTCODE + @ERR_OE_SHIPTO + @ERR_OE_SHIPTOREG + @ERR_OE_SALES
                     + @ERR_OE_LOC + @ERR_OE_L_ORDNO + @ERR_OE_L_PRICTYP + @ERR_OE_L_PARTNO
                     + @ERR_OE_L_LOCATION
    SET @ERR_OE_SHIP2 = @ERR_OE_TRANSMIX
    --
    -- Fill in some defaults
    --
    UPDATE vw
            SET rate_type_home = arco.rate_type_home,
                rate_type_oper = arco.rate_type_oper
            FROM imsoe_hdr_vw vw 
            INNER JOIN glco
                    ON vw.company_code = glco.company_code 
            INNER JOIN arco
                    ON arco.company_id = glco.company_id
            INNER JOIN #t1
                    ON #t1.record_id_num = vw.record_id_num
            WHERE vw.process_status = 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_hdr_vw 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE vw
            SET curr_key = arco.def_curr_code
            FROM imsoe_hdr_vw vw
            INNER JOIN glco
                    ON vw.company_code = glco.company_code
            INNER JOIN arco
                    ON arco.company_id = glco.company_id
            INNER JOIN #t1
                    ON #t1.record_id_num = vw.record_id_num
            WHERE (vw.curr_key <= '' OR vw.curr_key IS NULL)
                    AND vw.process_status = 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_hdr_vw 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- SET validation bits
    --
    UPDATE imsoe_hdr_vw
            SET record_status_1 = @ERR_OE_HDR
            FROM imsoe_hdr_vw,     #t1
            WHERE imsoe_hdr_vw.record_id_num = #t1.record_id_num
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_hdr_vw 4' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    -- validation bits record_status_2
    UPDATE imsoe_hdr_vw
            SET record_status_2 = @ERR_OE_HOLD_REASON + @ERR_OE_PRINTCODE + @ERR_IE_MC
            FROM imsoe_hdr_vw,     #t1
            WHERE imsoe_hdr_vw.record_id_num = #t1.record_id_num
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_hdr_vw 5' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    -- SET ERR_OE_TOTALS ON --
    UPDATE imsoe_hdr_vw
            SET record_status_1 = record_status_1 | @ERR_OE_TOTALS
            FROM imsoe_hdr_vw,     #t1
            WHERE imsoe_hdr_vw.record_id_num = #t1.record_id_num
                    AND status = 'T'
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_hdr_vw 6' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    -- SET OE_LINE ERRORS ON --
    UPDATE imsoe_line_vw
            SET record_status_1 = @ERR_OE_LINE,
                record_status_2 = @ERR_OE_LINE2
            FROM imsoe_line_vw,     #t1
            WHERE imsoe_line_vw.record_id_num = #t1.record_id_num
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_line_vw 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    -- SET OE_SHIP ERRORS ON --
    UPDATE imsoe_shipr_vw
            SET record_status_1 = @ERR_OE_SHIP,
                record_status_2 = @ERR_OE_SHIP2
            FROM imsoe_shipr_vw,     #t1
            WHERE imsoe_shipr_vw.record_id_num = #t1.record_id_num
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_shipr_vw 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    -- ERR_OE_CUSTCODE --
    UPDATE imsoe_hdr_vw
            SET record_status_1 = record_status_1 ^ @ERR_OE_CUSTCODE
            FROM imsoe_hdr_vw,     arcust,     #t1
            WHERE imsoe_hdr_vw.record_id_num = #t1.record_id_num
                    AND imsoe_hdr_vw.cust_code = arcust.customer_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_hdr_vw 7' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    -- ERR_OE_SHIPTO --
    UPDATE im
            SET ship_to_name = ars.ship_to_name,
                ship_to_add_1 = ars.addr1,
                ship_to_add_2 = ars.addr2,
                ship_to_add_3 = ars.addr3,
                ship_to_add_4 = ars.addr4,
                ship_to_add_5 = ars.addr5,
                ship_to_state = substring(ars.state,1,2),
                ship_to_zip = SUBSTRING(ars.postal_code,1,10),
                ship_to_country = ars.country,
                ship_to_region = ars.territory_code,
                record_status_1 = record_status_1 ^ @ERR_OE_SHIPTO
            FROM imsoe_hdr_vw im, arshipto ars, #t1
            WHERE im.record_id_num = #t1.record_id_num
                    AND im.cust_code = ars.customer_code
                    AND im.ship_to = ars.ship_to_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_hdr_vw 8' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE im
            SET ship_to = '',
                ship_to_name = ar.customer_name,
                ship_to_add_1 = ar.addr1,
                ship_to_add_2 = ar.addr2,
                ship_to_add_3 = ar.addr3,
                ship_to_add_4 = ar.addr4,
                ship_to_add_5 = ar.addr5,
                ship_to_state = substring(ar.state,1,2),
                ship_to_zip = SUBSTRING(ar.postal_code,1,10),
                ship_to_country = ar.country,
                ship_to_region = ar.territory_code,
                record_status_1 = im.record_status_1 ^ @ERR_OE_SHIPTO
            FROM imsoe_hdr_vw im, arcust ar, #t1
            WHERE im.record_id_num = #t1.record_id_num
                    AND (im.record_status_1 & @ERR_OE_SHIPTO ) > 0
                    AND (im.ship_to = '' or im.ship_to is NULL)
                    AND im.ship_to_name = ''
                    AND im.ship_to_add_1 = ''
                    AND im.ship_to_add_2 = ''
                    AND im.ship_to_add_3 = ''
                    AND im.ship_to_add_4 = ''
                    AND im.ship_to_add_5 = ''
                    AND im.ship_to_city = ''
                    AND im.ship_to_state = ''
                    AND im.ship_to_zip = ''
                    AND im.ship_to_country = ''
                    AND im.ship_to_region = ''
                    AND im.cust_code = ar.customer_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_hdr_vw 9' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE imsoe_hdr_vw
            SET record_status_1 = record_status_1 ^ @ERR_OE_SHIPTO
            FROM imsoe_hdr_vw,     #t1
            WHERE imsoe_hdr_vw.record_id_num = #t1.record_id_num
                    AND (record_status_1 & @ERR_OE_SHIPTO) > 0
                    AND (ship_to <= ' ' or ship_to IS NULL)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_hdr_vw 10' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    -- ERR_OE_TERMS --
    UPDATE imsoe_hdr_vw
    SET record_status_1 = record_status_1 ^ @ERR_OE_TERMS
    FROM imsoe_hdr_vw,
        arterms,     #t1
    WHERE imsoe_hdr_vw.record_id_num = #t1.record_id_num
    AND imsoe_hdr_vw.terms = arterms.terms_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_hdr_vw 11' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

-- ERR_OE_ROUTING --

UPDATE imsoe_hdr_vw
SET record_status_1 = record_status_1 ^ @ERR_OE_ROUTING
FROM imsoe_hdr_vw,
    arshipv,     #t1
WHERE imsoe_hdr_vw.record_id_num = #t1.record_id_num
AND imsoe_hdr_vw.routing = arshipv.ship_via_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_hdr_vw 12' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

-- ERR_OE_SALES --

UPDATE imsoe_hdr_vw
SET record_status_1 = record_status_1 ^ @ERR_OE_SALES
FROM imsoe_hdr_vw,
    arsalesp,     #t1
WHERE imsoe_hdr_vw.record_id_num = #t1.record_id_num
AND imsoe_hdr_vw.salesperson = arsalesp.salesperson_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_hdr_vw 13' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

UPDATE im
SET im.record_status_1 = im.record_status_1 ^ @ERR_OE_SALES,
    im.salesperson = arcust.salesperson_code
FROM imsoe_hdr_vw im,
    arcust,     #t1
WHERE im.record_id_num = #t1.record_id_num
AND (record_status_1 & @ERR_OE_SALES) > 0
AND (    im.salesperson <= ' '
    or    im.salesperson IS NULL
    )
AND im.cust_code = arcust.customer_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_hdr_vw 14' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

-- ERR_OE_TAXCODE --
-- if the tax code of blank, AND the customer is valid
-- then UPDATE it with the code off of the vendor

UPDATE imsoe_hdr_vw
SET imsoe_hdr_vw.record_status_1 = imsoe_hdr_vw.record_status_1 ^ @ERR_OE_TAXCODE,
    imsoe_hdr_vw.tax_id = arcust.tax_code
FROM imsoe_hdr_vw,
    arcust,     #t1
WHERE imsoe_hdr_vw.record_id_num = #t1.record_id_num
AND imsoe_hdr_vw.cust_code = arcust.customer_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_hdr_vw 15' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

UPDATE imsoe_hdr_vw
SET record_status_1 = record_status_1 ^ @ERR_OE_TAXCODE
FROM imsoe_hdr_vw,
    artax,     #t1
WHERE imsoe_hdr_vw.record_id_num = #t1.record_id_num
AND imsoe_hdr_vw.tax_id = artax.tax_code
AND (imsoe_hdr_vw.record_status_1 & @ERR_OE_TAXCODE) > 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_hdr_vw 16' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

-- ERR_OE_FWDR --

UPDATE imsoe_hdr_vw
SET record_status_1 = record_status_1 ^ @ERR_OE_FWDR
FROM imsoe_hdr_vw,
    arfwdr,     #t1
WHERE imsoe_hdr_vw.record_id_num = #t1.record_id_num
AND imsoe_hdr_vw.forwarder_key = arfwdr.kys
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_hdr_vw 17' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

UPDATE imsoe_hdr_vw
SET record_status_1 = record_status_1 ^ @ERR_OE_FWDR
FROM imsoe_hdr_vw,     #t1
WHERE imsoe_hdr_vw.record_id_num = #t1.record_id_num
AND (record_status_1 & @ERR_OE_FWDR ) > 0
AND (    forwarder_key <= ' '
    or     forwarder_key IS NULL )
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_hdr_vw 18' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

-- ERR_OE_FRTTO --

UPDATE imsoe_hdr_vw
SET record_status_1 = record_status_1 ^ @ERR_OE_FRTTO
FROM imsoe_hdr_vw,
    arfrt_to,     #t1 
WHERE imsoe_hdr_vw.record_id_num = #t1.record_id_num
AND imsoe_hdr_vw.freight_to = arfrt_to.kys
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_hdr_vw 19' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
UPDATE imsoe_hdr_vw
SET record_status_1 = record_status_1 ^ @ERR_OE_FRTTO
FROM imsoe_hdr_vw,     #t1
WHERE imsoe_hdr_vw.record_id_num = #t1.record_id_num
AND (record_status_1 & @ERR_OE_FRTTO) > 0
AND (    freight_to < = ' '
    or     freight_to IS NULL)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_hdr_vw 20' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

-- ERR_OE_SHIPTOREG --

UPDATE imsoe_hdr_vw
SET record_status_1 = record_status_1 ^ @ERR_OE_SHIPTOREG
FROM imsoe_hdr_vw,
    arterr,     #t1
WHERE imsoe_hdr_vw.record_id_num = #t1.record_id_num
AND imsoe_hdr_vw.ship_to_region = arterr.territory_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_hdr_vw 21' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

UPDATE imsoe_hdr_vw
SET record_status_1 = record_status_1 ^ @ERR_OE_SHIPTOREG
FROM imsoe_hdr_vw,     #t1
WHERE imsoe_hdr_vw.record_id_num = #t1.record_id_num
AND (record_status_1 & @ERR_OE_SHIPTOREG) > 0
AND ship_to_region < = ' '
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_hdr_vw 22' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

-- ERR_OE_LOC --

UPDATE imsoe_hdr_vw
SET record_status_1 = record_status_1 ^ @ERR_OE_LOC
FROM imsoe_hdr_vw,
    locations,     #t1
WHERE imsoe_hdr_vw.record_id_num = #t1.record_id_num
AND imsoe_hdr_vw.location = locations.location
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_hdr_vw 23' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

-- ERR_OE_CURR --

UPDATE imsoe_hdr_vw
SET record_status_1 = record_status_1 ^ @ERR_OE_CURR
FROM imsoe_hdr_vw,
    glcurr_vw,     #t1
WHERE imsoe_hdr_vw.record_id_num = #t1.record_id_num
AND imsoe_hdr_vw.curr_key = glcurr_vw.currency_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_hdr_vw 24' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

-- ERR_OE_BILLTO --

UPDATE imsoe_hdr_vw
SET bill_to_key = cust_code
FROM imsoe_hdr_vw,    #t1
WHERE imsoe_hdr_vw.record_id_num = #t1.record_id_num
AND (    bill_to_key <= ' '
    or     bill_to_key IS NULL)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_hdr_vw 25' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

UPDATE imsoe_hdr_vw
SET record_status_1 = record_status_1 ^ @ERR_OE_BILLTO
FROM imsoe_hdr_vw,     #t1
WHERE imsoe_hdr_vw.record_id_num = #t1.record_id_num
AND cust_code = bill_to_key
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_hdr_vw 26' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

-- ERR_OE_POSTN_CODE --

UPDATE imsoe_hdr_vw
SET record_status_1 = record_status_1 ^ @ERR_OE_POSTN_CODE
FROM imsoe_hdr_vw
    ,araccts
    ,#t1
WHERE imsoe_hdr_vw.record_id_num = #t1.record_id_num
AND imsoe_hdr_vw.posting_code = araccts.posting_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_hdr_vw 27' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

-- ERR_OE_ZONE_CODE --

UPDATE imsoe_hdr_vw
SET record_status_1 = record_status_1 ^ @ERR_OE_ZONE_CODE
FROM imsoe_hdr_vw,
    arzone,     #t1
WHERE imsoe_hdr_vw.record_id_num = #t1.record_id_num
AND imsoe_hdr_vw.dest_zone_code = arzone.zone_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_hdr_vw 28' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

UPDATE imsoe_hdr_vw
SET record_status_1 = record_status_1 ^ @ERR_OE_ZONE_CODE
FROM imsoe_hdr_vw,     #t1
WHERE imsoe_hdr_vw.record_id_num = #t1.record_id_num
AND (record_status_1 & @ERR_OE_ZONE_CODE) > 0
AND (    dest_zone_code <= ' '
    or     dest_zone_code IS NULL)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_hdr_vw 29' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

-- ERR_OE_STATUS --

UPDATE imsoe_hdr_vw
SET record_status_1 = record_status_1 ^ @ERR_OE_STATUS
FROM imsoe_hdr_vw,     #t1
WHERE imsoe_hdr_vw.record_id_num = #t1.record_id_num
AND status in ('N')  ---,'T') only new orders for the moment
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_hdr_vw 30' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

-- if the status is 'T' then have to check the totals

-- ERR_OE_TYPE --

UPDATE imsoe_hdr_vw
SET record_status_1 = record_status_1 ^ @ERR_OE_TYPE
FROM imsoe_hdr_vw,     #t1 
WHERE imsoe_hdr_vw.record_id_num = #t1.record_id_num
AND type = 'I'
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_hdr_vw 31' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

-- ERR_OE_BOFLG --

UPDATE imsoe_hdr_vw
SET record_status_1 = record_status_1 ^ @ERR_OE_BOFLG
FROM imsoe_hdr_vw,     #t1
WHERE imsoe_hdr_vw.record_id_num = #t1.record_id_num
AND back_ord_flag >= '0' AND back_ord_flag <= '2'
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_hdr_vw 32' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END




-- ERR_OE_HOLD_REASON --

UPDATE vw
SET vw.record_status_2 = vw.record_status_2 ^ @ERR_OE_HOLD_REASON
FROM imsoe_hdr_vw vw,
    adm_oehold ao,     #t1
WHERE vw.record_id_num = #t1.record_id_num
AND vw.hold_reason = ao.hold_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_hdr_vw 33' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END


UPDATE imsoe_hdr_vw
SET record_status_2 = record_status_2 ^ @ERR_OE_HOLD_REASON
FROM imsoe_hdr_vw,     #t1
WHERE imsoe_hdr_vw.record_id_num = #t1.record_id_num
AND (    hold_reason <= ' '
    or     hold_reason IS NULL )
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_hdr_vw 34' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

-- ERR_OE_PRINTCODE --

UPDATE imsoe_hdr_vw
SET record_status_2 = record_status_2 ^ @ERR_OE_PRINTCODE
FROM imsoe_hdr_vw,     #t1
WHERE imsoe_hdr_vw.record_id_num = #t1.record_id_num
AND (    printed = 'N'
    or     printed = 'S'
    or     printed = 'T' )
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_hdr_vw 35' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

-- ERR_OE_ORDNO --
    IF @Automatically_Assign_Order_Numbers = 'YES'
        BEGIN
        UPDATE [imsoe_hdr_vw]
                SET [record_status_1] = [record_status_1] ^ @ERR_OE_ORDNO
                FROM [imsoe_hdr_vw]
                INNER JOIN [#t1]
                        ON [imsoe_hdr_vw].[record_id_num] = [#t1].[record_id_num]
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_hdr_vw 36A' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        END
    ELSE    
        BEGIN
        SELECT @p_highest_pos_order_num = [last_no]
                FROM [next_order_num]
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' next_order_num 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        UPDATE [imsoe_hdr_vw]
                SET [record_status_1] = [record_status_1] ^ @ERR_OE_ORDNO
                FROM [imsoe_hdr_vw]
                INNER JOIN [#t1]
                        ON [imsoe_hdr_vw].[record_id_num] = [#t1].[record_id_num]
                WHERE [imsoe_hdr_vw].[order_no] >= 0
                        AND [imsoe_hdr_vw].[order_no] <= @p_highest_pos_order_num
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_hdr_vw 36B' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        UPDATE [imsoe_hdr_vw]
                SET [record_status_1] = [record_status_1] & @ERR_OE_ORDNO
                FROM [imsoe_hdr_vw]
                INNER JOIN [orders]
                        ON [imsoe_hdr_vw].[order_no] = [orders].[order_no]
                INNER JOIN [#t1]
                        ON [imsoe_hdr_vw].[record_id_num] = [#t1].[record_id_num]
                WHERE ([imsoe_hdr_vw].[record_status_1] & @ERR_OE_ORDNO) = 0     -- error has been turned off
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_hdr_vw 37' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        END

-- ERR_OE_DUP --

-- check to see if this hdr record is a duplicate in the staging table
    UPDATE imsoe_hdr_vw
            SET record_status_1 = record_status_1 ^ @ERR_OE_DUP
            FROM (SELECT COUNT(*) AS _count,
                         order_no
                          FROM imsoe_hdr_vw
                          WHERE company_code = @w_cc
                                  AND process_status = 0
                          GROUP BY order_no
                          HAVING COUNT(*) = 1) AS singles, #t1
            WHERE imsoe_hdr_vw.record_id_num = #t1.record_id_num
                    AND imsoe_hdr_vw.order_no = singles.order_no
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_hdr_vw 38' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Check to see if this record already exists in the production tables
    --
    IF NOT @Automatically_Assign_Order_Numbers = 'YES'
        BEGIN
        UPDATE imsoe_hdr_vw
                SET record_status_1 = record_status_1 | @ERR_OE_DUP
                FROM imsoe_hdr_vw,
                     orders, #t1
                WHERE imsoe_hdr_vw.record_id_num = #t1.record_id_num
                        AND imsoe_hdr_vw.order_no = orders.order_no
                        AND (imsoe_hdr_vw.record_status_1 & @ERR_OE_DUP) = 0    -- bit is currently turned off FROM above query
            -- can be zero , this will signal an order number to be applied
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_hdr_vw 39' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        END

-- ERR_OE_NOLIN
-- now check that header lines must have at least one order line assocated with then

UPDATE hdr
SET hdr.record_status_1  = hdr.record_status_1 ^ @ERR_OE_NOLIN
FROM imsoe_hdr_vw hdr,
        imsoe_line_vw lin,         #t1
WHERE hdr.record_id_num = #t1.record_id_num
AND hdr.order_no = lin.order_no
AND lin.company_code = @w_cc
AND lin.process_status = 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_hdr_vw 40' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END


----------- order line validations ------------

-- ERR_OE_LINE --
UPDATE imsoe_line_vw
SET record_status_1 = record_status_1 | @ERR_OE_LINE
FROM imsoe_line_vw,     #t1
WHERE imsoe_line_vw.record_id_num = #t1.record_id_num
AND (record_type & @RECTYPE_OE_LINE) > 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_line_vw 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

-- turn the ERR_OE_BOFLG bit on for all records that are
-- only lin recs
UPDATE imsoe_vw
SET record_status_1 = record_status_1 | @ERR_OE_BOFLG
FROM imsoe_vw,     #t1
WHERE imsoe_vw.record_id_num = #t1.record_id_num
AND record_type = @RECTYPE_OE_LINE
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_vw 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

-- ERR_OE_L_PARTNO --

    UPDATE imsoe_line_vw
            SET [record_status_1] = imsoe_line_vw.[record_status_1] ^ @ERR_OE_L_PARTNO
            FROM [imsoe_line_vw]
            LEFT OUTER JOIN [inv_master]
                    ON inv_master.[part_no] = imsoe_line_vw.[part_no]
            INNER JOIN [#t1]
                    ON #t1.[record_id_num] = imsoe_line_vw.[record_id_num]
            WHERE (NOT imsoe_line_vw.[part_type] = 'M' AND NOT inv_master.[part_no] IS NULL)
                    OR imsoe_line_vw.[part_type] = 'M'                
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_line_vw 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

-- ERR_OE_L_PARTTYPE --

UPDATE imsoe_line_vw
SET record_status_2 = record_status_2 ^ @ERR_OE_L_PARTTYPE
FROM imsoe_line_vw,    #t1
WHERE imsoe_line_vw.record_id_num = #t1.record_id_num
AND (    part_type = 'M'
    or     part_type = 'P' )
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_line_vw 4' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

-- ERR_OE_L_LOCATION --

    UPDATE imsoe_line_vw
            SET [record_status_1] = imsoe_line_vw.[record_status_1] ^ @ERR_OE_L_LOCATION
            FROM imsoe_line_vw
            LEFT OUTER JOIN [inv_list]
                    ON inv_list.[part_no] = imsoe_line_vw.[part_no]
                            AND inv_list.[location] = imsoe_line_vw.[line_location]
            INNER JOIN [#t1]
                    ON #t1.[record_id_num] = imsoe_line_vw.[record_id_num]
            WHERE (NOT imsoe_line_vw.[part_type] = 'M' AND NOT inv_list.[part_no] IS NULL)
                    OR imsoe_line_vw.[part_type] = 'M'                
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_line_vw 5' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

-- ERR_OE_L_DESCBLANK --

UPDATE vw
SET vw.description = im.description
FROM imsoe_line_vw vw,
    inv_master im,     #t1
WHERE vw.record_id_num = #t1.record_id_num
AND vw.part_no = im.part_no
AND (     vw.description <= ' '
    or     vw.description IS NULL )
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_line_vw 6' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

UPDATE vw
SET vw.description = hdr.description
FROM imsoe_line_vw vw,
    iminvmast_mstr_vw hdr,     #t1
WHERE vw.record_id_num = #t1.record_id_num
AND (    vw.description <= ' '
    or    vw.description IS NULL )
AND vw.part_no = hdr.part_no
AND hdr.company_code = @w_cc
AND hdr.process_status = 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_line_vw 7' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

UPDATE imsoe_line_vw
SET record_status_2 = record_status_2 ^ @ERR_OE_L_DESCBLANK
FROM imsoe_line_vw,     #t1
WHERE imsoe_line_vw.record_id_num = #t1.record_id_num
AND description is not null
AND description > ''
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_line_vw 8' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

-- ERR_OE_L_UOM --

UPDATE imsoe_line_vw
SET record_status_1 = imsoe_line_vw.record_status_1 ^ @ERR_OE_L_UOM
FROM imsoe_line_vw,
    uom_list,     #t1
WHERE imsoe_line_vw.record_id_num = #t1.record_id_num
AND imsoe_line_vw.uom = uom_list.uom
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_line_vw 9' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

-- ERR_OE_L_TAXCODE --

UPDATE imsoe_line_vw
SET imsoe_line_vw.record_status_1 = imsoe_line_vw.record_status_1 ^ @ERR_OE_L_TAXCODE,
    imsoe_line_vw.tax_code = arcust.tax_code
FROM imsoe_line_vw,
    imsoe_hdr_vw,
    arcust,     #t1
WHERE imsoe_line_vw.record_id_num = #t1.record_id_num
AND imsoe_line_vw.order_no = imsoe_hdr_vw.order_no
AND imsoe_hdr_vw.company_code = @w_cc
AND imsoe_hdr_vw.process_status = 0
AND imsoe_hdr_vw.cust_code = arcust.customer_code
AND (    imsoe_line_vw.tax_code IS NULL
    or     imsoe_line_vw.tax_code <= ' ')
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_line_vw 10' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END


UPDATE imsoe_line_vw
SET record_status_1 = imsoe_line_vw.record_status_1 ^ @ERR_OE_L_TAXCODE
FROM imsoe_line_vw,
    artax,     #t1
WHERE imsoe_line_vw.record_id_num = #t1.record_id_num
AND imsoe_line_vw.tax_code = artax.tax_code
AND (imsoe_line_vw.record_status_1 & @ERR_OE_L_TAXCODE ) > 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_line_vw 11' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

-- ERR_OE_L_GLREF --

UPDATE imsoe_line_vw
SET imsoe_line_vw.gl_rec_acct = in_account.sales_acct_code,
    imsoe_line_vw.record_status_1 = imsoe_line_vw.record_status_1 ^ @ERR_OE_L_GLREF
FROM imsoe_line_vw,
    in_account,
    inv_list,     #t1
WHERE imsoe_line_vw.record_id_num = #t1.record_id_num
AND (imsoe_line_vw.record_status_1 & @ERR_OE_L_LOCATION) = 0
AND imsoe_line_vw.part_type = 'P'
AND imsoe_line_vw.part_no = inv_list.part_no
AND imsoe_line_vw.line_location = inv_list.location
AND inv_list.acct_code = in_account.acct_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_line_vw 12' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

UPDATE imsoe_line_vw
SET record_status_1 = imsoe_line_vw.record_status_1 ^ @ERR_OE_L_GLREF
FROM imsoe_line_vw,
        in_account,     #t1
WHERE imsoe_line_vw.record_id_num = #t1.record_id_num
AND imsoe_line_vw.gl_rec_acct = in_account.sales_acct_code
AND imsoe_line_vw.part_type = 'M'
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_line_vw 13' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

-- ERR_OE_L_PRICETYP --

UPDATE imsoe_line_vw
SET record_status_1 = record_status_1 ^ @ERR_OE_L_PRICTYP
FROM imsoe_line_vw,     #t1
WHERE imsoe_line_vw.record_id_num = #t1.record_id_num
AND price_type in ('1','2','3','4','5','P','Q','Y')
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_line_vw 14' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

-- ERR_OE_L_ORDQTY --

UPDATE imsoe_line_vw
SET record_status_2 = record_status_2 ^ @ERR_OE_L_ORDQTY
FROM imsoe_line_vw,     #t1
WHERE imsoe_line_vw.record_id_num = #t1.record_id_num
AND ordered > 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_line_vw 15' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

-- ERR_OE_BOFLG --

UPDATE imsoe_line_vw
SET record_status_1 = record_status_1 ^ @ERR_OE_BOFLG
FROM imsoe_line_vw,     #t1
WHERE imsoe_line_vw.record_id_num = #t1.record_id_num
AND record_type = @RECTYPE_OE_LINE
AND back_ord_flag >= '0' AND back_ord_flag <= '2'
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_line_vw 16' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

-- ERR_OE_STATUS for soelines

UPDATE imsoe_line_vw
SET record_status_1 = record_status_1 ^ @ERR_OE_STATUS
FROM imsoe_line_vw,     #t1
WHERE imsoe_line_vw.record_id_num = #t1.record_id_num
AND line_status in ('N')  ---,'T') only new orders for the moment
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_line_vw 17' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

-- ERR_OE_LBT_FLAG --

UPDATE imsoe_line_vw
SET [record_status_2] = imsoe_line_vw.[record_status_2] ^ @ERR_OE_LBT_FLAG
FROM [imsoe_line_vw]
	LEFT OUTER JOIN [inv_master]
             ON inv_master.[part_no] = imsoe_line_vw.[part_no]
	     AND inv_master.lb_tracking = imsoe_line_vw.lb_tracking
        INNER JOIN [#t1]
             ON #t1.[record_id_num] = imsoe_line_vw.[record_id_num]
WHERE (inv_master.[part_no] IS NOT NULL)               
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_line_vw 18' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END


-- ERR_OE_L_DUP --

-- here is a tricky bit of sql for you, it checks for duplicates order_no,line_no in the
-- staging table and sets the bit off where there is only one record in the group
UPDATE imsoe_line_vw
SET record_status_1 = record_status_1 ^ @ERR_OE_L_DUP
FROM (     SELECT count(*) as _count,
                order_no,
                line_no
        FROM imsoe_line_vw
        WHERE company_code = @w_cc
        group by     order_no,
                line_no
        having         count(*) = 1
        ) as v2,     #t1
WHERE imsoe_line_vw.record_id_num = #t1.record_id_num
AND imsoe_line_vw.order_no = v2.order_no
AND imsoe_line_vw.line_no = v2.line_no
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_line_vw 18' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

-- now check the see that if any of the lines that were not duplicated
-- belong to orders that are already in the
-- production tables. This scheme will not allow appending to an existing order!
UPDATE imsoe_line_vw
SET record_status_1 = record_status_1 | @ERR_OE_L_DUP -- turn the bit on
FROM imsoe_line_vw,
    orders,     #t1
WHERE imsoe_line_vw.record_id_num = #t1.record_id_num
AND (imsoe_line_vw.record_status_1 & @ERR_OE_L_DUP) = 0 -- bit is not set
AND imsoe_line_vw.order_no = orders.order_no
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_line_vw 19' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

-- now check turn the line error off for all rows that

UPDATE lin
SET lin.record_status_1 = lin.record_status_1 ^ @ERR_OE_L_ORDNO
FROM imsoe_line_vw lin,
    imsoe_hdr_vw  hdr,     #t1
WHERE lin.record_id_num = #t1.record_id_num
AND lin.order_no = hdr.order_no
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_line_vw 20' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

-- this is a little different, in this case I turn the bit on in the hdr, if an error exists in any
-- of the line records for a given header
UPDATE imsoe_hdr_vw
SET record_status_1 = record_status_1 | @ERR_OE_INVLD_LIN
FROM (    SELECT lin.order_no
        FROM imsoe_line_vw lin
        WHERE lin.company_code = @w_cc
        AND lin.record_status_1 <> 0
        AND lin.process_status = 0
        group by     lin.order_no) as t1,     #t1
WHERE imsoe_hdr_vw.record_id_num = #t1.record_id_num
AND imsoe_hdr_vw.order_no = t1.order_no
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_hdr_vw 41' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

------- imsoe_shipr_vw validation [start]

-- ERR_OE_TRANSMIX --

UPDATE imsoe_shipr_vw
SET record_status_2 = record_status_2 ^ @ERR_OE_TRANSMIX
FROM imsoe_shipr_vw,    #t1
WHERE imsoe_shipr_vw.record_id_num = #t1.record_id_num
AND imsoe_shipr_vw.record_type = @RECTYPE_OE_HIST
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_shipr_vw 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

-- ERR_OE_CUSTCODE --

UPDATE imsoe_shipr_vw
SET record_status_1 = record_status_1 ^ @ERR_OE_CUSTCODE
FROM imsoe_shipr_vw
    ,arcust 
    ,#t1
WHERE imsoe_shipr_vw.record_id_num = #t1.record_id_num
AND imsoe_shipr_vw.cust_code = arcust.customer_code
AND (imsoe_shipr_vw.record_status_2 & @ERR_OE_TRANSMIX) = 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_shipr_vw 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

-- ERR_OE_SHIPTO --

UPDATE imsoe_shipr_vw
SET record_status_1 = record_status_1 ^ @ERR_OE_SHIPTO
FROM imsoe_shipr_vw,
    arshipto,     #t1
WHERE imsoe_shipr_vw.record_id_num = #t1.record_id_num
AND (     imsoe_shipr_vw.ship_to = arshipto.ship_to_code
    or    imsoe_shipr_vw.ship_to <= ' '
    or     imsoe_shipr_vw.ship_to IS NULL)
AND (imsoe_shipr_vw.record_status_2 & @ERR_OE_TRANSMIX) = 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_shipr_vw 4' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

-- ERR_OE_SHIPTOREG --

UPDATE imsoe_shipr_vw
SET record_status_1 = record_status_1 ^ @ERR_OE_SHIPTOREG
FROM imsoe_shipr_vw,
    arterr,    #t1
WHERE imsoe_shipr_vw.record_id_num = #t1.record_id_num
AND (    imsoe_shipr_vw.ship_to_region = arterr.territory_code
    or    imsoe_shipr_vw.ship_to_region <= ' '
    or     imsoe_shipr_vw.ship_to_region IS NULL)
AND (imsoe_shipr_vw.record_status_2 & @ERR_OE_TRANSMIX) = 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_shipr_vw 5' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

-- ERR_OE_SALES --

UPDATE imsoe_shipr_vw
SET record_status_1 = record_status_1 ^ @ERR_OE_SALES
FROM imsoe_shipr_vw,
    arsalesp,     #t1
WHERE imsoe_shipr_vw.record_id_num  = #t1.record_id_num
AND (    imsoe_shipr_vw.salesperson = arsalesp.salesperson_code
    or    imsoe_shipr_vw.salesperson <= ' '
    or    imsoe_shipr_vw.salesperson IS NULL)
AND (imsoe_shipr_vw.record_status_2 & @ERR_OE_TRANSMIX) = 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_shipr_vw 6' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

-- ERR_OE_LOC --

UPDATE imsoe_shipr_vw
SET record_status_1 = record_status_1 ^ @ERR_OE_LOC
FROM imsoe_shipr_vw,
    locations,     #t1
WHERE imsoe_shipr_vw.record_id_num = #t1.record_id_num
AND imsoe_shipr_vw.location = locations.location
AND (imsoe_shipr_vw.record_status_2 & @ERR_OE_TRANSMIX) = 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_shipr_vw 7' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

-- ERR_OE_ORD_NO --

UPDATE imsoe_shipr_vw
SET record_status_1 = record_status_1 ^ @ERR_OE_ORDNO
FROM imsoe_shipr_vw,
    orders,     #t1
WHERE imsoe_shipr_vw.record_id_num = #t1.record_id_num
AND imsoe_shipr_vw.order_no = orders.order_no
AND imsoe_shipr_vw.order_ext = orders.ext
AND (imsoe_shipr_vw.record_status_2 & @ERR_OE_TRANSMIX) = 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_shipr_vw 8' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

UPDATE imsoe_shipr_vw
SET imsoe_shipr_vw.record_status_1 = imsoe_shipr_vw.record_status_1 ^ @ERR_OE_ORDNO
FROM imsoe_shipr_vw,
    imsoe_hdr_vw,     #t1
WHERE imsoe_shipr_vw.record_id_num = #t1.record_id_num
AND imsoe_shipr_vw.order_no = imsoe_hdr_vw.order_no
--AND imsoe_shipr_vw.order_ext = imsoe_hdr_vw.ext  ---eye
AND imsoe_hdr_vw.company_code = @w_cc
AND imsoe_hdr_vw.record_status_1 = 0
AND imsoe_hdr_vw.record_status_2 = 0
AND imsoe_hdr_vw.process_status = 0
AND imsoe_shipr_vw.process_status = 0
AND (imsoe_shipr_vw.record_status_2 & @ERR_OE_TRANSMIX) = 0
AND (imsoe_shipr_vw.record_status_1 & @ERR_OE_ORDNO) > 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_shipr_vw 9' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

-- ERR_OE_L_PRICETYP --

UPDATE imsoe_shipr_vw
SET record_status_1 = record_status_1 ^ @ERR_OE_L_PRICTYP
FROM imsoe_shipr_vw,         #t1
WHERE imsoe_shipr_vw.record_id_num = #t1.record_id_num
AND price_type in ('1','2','3','4','5','P','Q','Y')
AND (imsoe_shipr_vw.record_status_2 & @ERR_OE_TRANSMIX) = 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_shipr_vw 10' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

-- ERR_OE_L_PART_NO --
        -- check production
UPDATE imsoe_shipr_vw
SET record_status_1 = imsoe_shipr_vw.record_status_1 ^ @ERR_OE_L_PARTNO
FROM imsoe_shipr_vw,
        inv_master,         #t1
WHERE imsoe_shipr_vw.record_id_num = #t1.record_id_num
AND imsoe_shipr_vw.part_no = inv_master.part_no
AND (imsoe_shipr_vw.record_status_2 & @ERR_OE_TRANSMIX) = 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_shipr_vw 11' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

        -- check staging table
UPDATE imsoe_shipr_vw
SET record_status_1 = imsoe_shipr_vw.record_status_1 ^ @ERR_OE_L_PARTNO
FROM imsoe_shipr_vw,
        iminvmast_mstr_vw,         #t1
WHERE imsoe_shipr_vw.record_id_num = #t1.record_id_num
AND imsoe_shipr_vw.part_no = iminvmast_mstr_vw.part_no
AND iminvmast_mstr_vw.process_status = 0
AND iminvmast_mstr_vw.record_status_1 = 0
AND iminvmast_mstr_vw.record_status_2 = 0
AND (imsoe_shipr_vw.record_status_2 & @ERR_OE_TRANSMIX) = 0
AND (imsoe_shipr_vw.record_status_1 & @ERR_OE_L_PARTNO) > 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_shipr_vw 12' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END



-- ERR_OE_L_LOCATION --
        -- check production
UPDATE imsoe_shipr_vw
SET record_status_1 = imsoe_shipr_vw.record_status_1 ^ @ERR_OE_L_LOCATION
FROM imsoe_shipr_vw,
        inv_list,         #t1
WHERE imsoe_shipr_vw.record_id_num = #t1.record_id_num
AND imsoe_shipr_vw.part_no = inv_list.part_no
AND imsoe_shipr_vw.location = inv_list.location
AND (imsoe_shipr_vw.record_status_2 & @ERR_OE_TRANSMIX) = 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_shipr_vw 13' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END


UPDATE imsoe_shipr_vw
SET record_status_1 = imsoe_shipr_vw.record_status_1 ^ @ERR_OE_L_LOCATION
FROM imsoe_shipr_vw,
        iminvmast_loc_vw,         #t1
WHERE imsoe_shipr_vw.record_id_num = #t1.record_id_num
AND imsoe_shipr_vw.part_no = iminvmast_loc_vw.part_no
AND imsoe_shipr_vw.location = iminvmast_loc_vw.location
AND iminvmast_loc_vw.record_status_1 = 0
AND iminvmast_loc_vw.process_status = 0
AND (imsoe_shipr_vw.record_status_1 & @ERR_OE_L_LOCATION) > 0
AND (imsoe_shipr_vw.record_status_2 & @ERR_OE_TRANSMIX) = 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_shipr_vw 14' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END


--------imsoe_shipr_vw validation [end]





CREATE TABLE #rates (from_currency varchar(8), 
                     to_currency varchar(8), 
                     rate_type varchar(8), 
                     date_applied INT, 
                     rate float)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATETABLE + ' #rates 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

SELECT @precision_gl = 2
SELECT @precision_gl = curr_precision, 
       @currency = glco.home_currency,
       @rate_type = glco.rate_type_home
  FROM glco, glcurr_vw
 WHERE glco.home_currency = glcurr_vw.currency_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' glco 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

-- From Currency is imsoe_hdr_vw.curr_key, to_currency is glco.home_currency AND glco.oper_currency, rate_type comes
-- FROM imsoe_hdr_vw.rate_type_home AND rate_type_oper, date_applied is imsoe_hdr_vw.req_ship_date, rate is returned

INSERT INTO #rates
  SELECT distinct hdr.curr_key, @currency, @rate_type, DATEDIFF(DD, '1/1/80', CONVERT(DATETIME,hdr.req_ship_date))+722815, 0.0
         FROM imsoe_hdr_vw hdr, #t1 #t1
    WHERE hdr.record_id_num = #t1.record_id_num
      AND (hdr.record_status_2 & @ERR_IE_MC) > 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #rates 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

EXEC [CVO_Control]..mcrates_sp
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' [CVO_Control]..mcrates_sp 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

IF (@debug_level >= 3)  
BEGIN
    SELECT '#rates after home conversion'
    SELECT * FROM #rates
END

UPDATE imsoe_hdr_vw
   SET record_status_2 = record_status_2 ^ @ERR_IE_MC,
       curr_factor = rate
  FROM imsoe_hdr_vw hdr, #t1 #t1, #rates #rates
 WHERE hdr.record_id_num = #t1.record_id_num
   AND (hdr.record_status_2 & @ERR_IE_MC) > 0
   AND hdr.curr_key = #rates.from_currency
   AND DATEDIFF(DD,'1/1/80',CONVERT(DATETIME,hdr.req_ship_date))+722815 = #rates.date_applied
   AND #rates.rate <> 0.0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_hdr_vw 42' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END


DELETE #rates

SELECT @currency = glco.oper_currency,
       @rate_type = glco.rate_type_oper
  FROM glco
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' glco 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

-- From Currency is imsoe_hdr_vw.curr_key, to_currency is glco.home_currency and glco.oper_currency, rate_type comes
-- from imsoe_hdr_vw.rate_type_home and rate_type_oper, date_applied is imsoe_hdr_vw.req_ship_date, rate is returned

INSERT INTO #rates
  SELECT distinct hdr.curr_key, @currency, @rate_type, DATEDIFF(DD, '1/1/80', CONVERT(DATETIME,hdr.req_ship_date))+722815, 0.0
         FROM imsoe_hdr_vw hdr, #t1 #t1
    WHERE hdr.record_id_num = #t1.record_id_num
      AND (hdr.record_status_2 & @ERR_IE_MC) > 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #rates 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

EXEC [CVO_Control]..mcrates_sp
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' [CVO_Control]..mcrates_sp 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

IF (@debug_level >= 3)  
BEGIN
    SELECT '#rates after oper conversion'
    SELECT * FROM #rates
END

UPDATE imsoe_hdr_vw
   SET record_status_2 = record_status_2 ^ @ERR_IE_MC,
       curr_factor = rate
  FROM imsoe_hdr_vw hdr, #t1 #t1, #rates #rates
 WHERE hdr.record_id_num = #t1.record_id_num
   AND (hdr.record_status_2 & @ERR_IE_MC) > 0
   AND hdr.curr_key = #rates.from_currency
   AND DATEDIFF(DD,'1/1/80',CONVERT(DATETIME,hdr.req_ship_date))+722815 = #rates.date_applied
   AND #rates.rate <> 0.0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imsoe_hdr_vw 43' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    DROP TABLE #rates
    INSERT INTO imlog VALUES (getdate(), 'SO', 1, '', '', '', 'Sales Order -- End', @userid)
    RETURN 0
Error_Return:
    INSERT INTO imlog VALUES (getdate(), 'SO', 1, '', '', '', 'Sales Order -- End (ERROR)', @userid)
    RETURN -1    
GO
GRANT EXECUTE ON  [dbo].[imSoeVal_sp] TO [public]
GO
