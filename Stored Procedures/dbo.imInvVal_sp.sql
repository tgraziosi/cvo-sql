SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


    CREATE procedure 
[dbo].[imInvVal_sp] (@p_batchno int = 0,
             @p_start_rec int = 0,
             @p_end_rec int = 0,
             @p_record_type int = 0x000000FF,
             @debug_level int = 0,
             @userid INT = 0)
    AS
    DECLARE @buf CHAR(255)
    DECLARE @dt datetime
    DECLARE @ERR_ACCOUNT INT
    DECLARE @ERR_ACCT_NOMAST INT
    DECLARE @ERR_ACTIVE_FLAG INT
    DECLARE @ERR_ALLOW_FRACTIONS INT
    DECLARE @ERR_ALT_UOM INT
    DECLARE @ERR_BP_SEQ INT
    DECLARE @ERR_BP_UOM INT
    DECLARE @ERR_BPLOC INT
    DECLARE @ERR_BUYER INT
    DECLARE @ERR_CATEGORY INT
    DECLARE @ERR_CFG_FLAG INT
    DECLARE @ERR_COMMTYPE INT
    DECLARE @ERR_CONSTRAIN INT
    DECLARE @ERR_CURR INT
    DECLARE @ERR_CYCLETYPE INT
    DECLARE @ERR_DUPLICATE INT
    DECLARE @ERR_FIXED INT
    DECLARE @ERR_FREIGHTCLS INT
    DECLARE @ERR_INCOMPTYPES INT
    DECLARE @ERR_INVCOST_METH INT
    DECLARE @ERR_INVLD_BPPART INT
    DECLARE @ERR_INVLDPART INT
    DECLARE @ERR_LBS_CODE INT
    DECLARE @ERR_LBS_LBTRACK INT
    DECLARE @ERR_LBS_MSTRNOLBTRAK INT
    DECLARE @ERR_LBS_NEGQTY INT
    DECLARE @ERR_LBS_NOLOC INT
    DECLARE @ERR_LBS_NULLBINNO INT
    DECLARE @ERR_LBS_NULLLOTSER INT
    DECLARE @ERR_LBS_UOM INT
    DECLARE @ERR_LOC INT
    DECLARE @ERR_LOC_ACCTCODE INT
    DECLARE @ERR_LOC_DUP INT
    DECLARE @ERR_LOC_INVCODE INT
    DECLARE @ERR_LOC_NOMAST INT
    DECLARE @ERR_LOC_NOMAST2 INT
    DECLARE @ERR_NOLOC INT
    DECLARE @ERR_PRIC_NOLOC INT
    DECLARE @ERR_PRIC_UOM INT
    DECLARE @ERR_PUR_NOMAST INT
    DECLARE @ERR_QC_FLAG INT
    DECLARE @ERR_RPT_UOM INT
    DECLARE @ERR_SERIAL_FLAG INT
    DECLARE @ERR_STATUS INT
    DECLARE @ERR_TAXCODE INT
    DECLARE @ERR_TYPE_CODE INT
    DECLARE @ERR_UOM INT
    DECLARE @ERR_VENDOR INT
    DECLARE @errorbits INT
    DECLARE @ERRS_BASIC INT
    DECLARE @ERRS_BUILDPLAN INT
    DECLARE @ERRS_LBS INT
    DECLARE @ERRS_LOC INT
    DECLARE @ERRS_PRIC INT
    DECLARE @ERRS_PURCHASING INT
    DECLARE @RECTYPE_INVBOM INT
    DECLARE @RECTYPE_INVLBS INT
    DECLARE @RECTYPE_INVLOC INT
    DECLARE @RECTYPE_INVLOC_BASE INT
    DECLARE @RECTYPE_INVLOC_COST INT
    DECLARE @RECTYPE_INVLOC_STCK INT
    DECLARE @RECTYPE_INVMST INT
    DECLARE @RECTYPE_INVMST_ACCT INT
    DECLARE @RECTYPE_INVMST_BASE INT
    DECLARE @RECTYPE_INVMST_COST INT
    DECLARE @RECTYPE_INVMST_PRIC INT
    DECLARE @RECTYPE_INVMST_PURC INT
    DECLARE @w_cc varchar(8)
    DECLARE @w_dmsg varchar(255)
        
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
    INSERT INTO imlog VALUES (getdate(), 'INVENTORY', 1, '', '', '', 'Inventory -- Begin (Validate) -- 7.3', @userid)
    
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
        EXEC imInvVal_e7_sp @p_batchno = @p_batchno,
                            @p_start_rec = @p_start_rec,
                            @p_end_rec = @p_end_rec,
                            @p_record_type = @p_record_type,
                            @p_debug_level = @debug_level 
        RETURN 0
        END
    --
    SET @Routine_Name = 'imInvVal_sp'
    select @w_cc = company_code from glco
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' glco 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    IF @debug_level > 0
        begin
        select @p_batchno as Batch, @p_start_rec as Start_Record, @p_end_rec as End_Record
        end
    --
    -- #t1 will contain a list of all the records that are to be processed during this 
    -- validation.  The list consists of the record_id_num values from the staging table.
    -- One of these days it would be nice to change it to work similar to the Financials
    -- imports in that all the candidate records are copied in whole to a temporary version
    -- of the staging table.  It would be better because there would be fewer tables involved
    -- in joins for various UPDATEs, etc., and the overall process would be less complicated. 
    --    
    create table #t1 (record_id_num INT constraint t1_key unique nonclustered (record_id_num))
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATETABLE + ' #t1 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    IF @p_batchno > 0
        BEGIN
        INSERT INTO #t1
                SELECT record_id_num
                FROM iminvmast_vw
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
                    FROM iminvmast_vw
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
                    FROM iminvmast_vw
                    WHERE company_code = @w_cc
                            AND process_status = 0
                            AND record_id_num >= @p_start_rec
                            AND ([User_ID] = @userid OR @userid = 0)
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #t1 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            END     
        END
    IF @debug_level > 0
        begin
        select @w_cc as company_code, @p_batchno as Batch, @p_start_rec as Start_Record, @p_end_rec as End_Record
        select * from #t1
        end
    SET @RECTYPE_INVMST_BASE = 0x00000001
    SET @RECTYPE_INVMST_PURC = 0x00000002
    SET @RECTYPE_INVMST_COST = 0x00000004
    SET @RECTYPE_INVMST_PRIC = 0x00000008
    SET @RECTYPE_INVMST_ACCT = 0x00000010
    SET @RECTYPE_INVMST = 0x0000001F
    SET @RECTYPE_INVLOC_BASE = 0x00000100
    SET @RECTYPE_INVLOC_COST = 0x00000200
    SET @RECTYPE_INVLOC_STCK = 0x00000400
    SET @RECTYPE_INVLOC = @RECTYPE_INVLOC_BASE + @RECTYPE_INVLOC_COST + @RECTYPE_INVLOC_STCK
    SET @RECTYPE_INVBOM = 0x00001000
    SET @RECTYPE_INVLBS = 0x00010000
    --
    -- record_status_1 bits.
    --
    SET @ERR_UOM =             0x00000001
    SET @ERR_CATEGORY =        0x00000002
    SET @ERR_TYPE_CODE =       0x00000004
    SET @ERR_STATUS =          0x00000008
    SET @ERR_COMMTYPE =        0x00000010
    SET @ERR_CYCLETYPE =       0x00000020
    SET @ERR_FREIGHTCLS =      0x00000040
    SET @ERR_NOLOC =           0x00000080
    SET @ERR_INVCOST_METH =    0x00000100
    SET @ERR_INCOMPTYPES =     0x00000200
    SET @ERR_VENDOR =          0x00000400
    SET @ERR_BUYER =           0x00000800
    SET @ERR_ACCOUNT =         0x00001000
    SET @ERR_TAXCODE =         0x00002000
    SET @ERR_ALT_UOM =         0x00004000
    SET @ERR_CURR =            0x00008000 -- Used in both record_status_1 and _2
    SET @ERR_RPT_UOM =         0x00010000
    SET @ERR_QC_FLAG =         0x00020000
    SET @ERR_CFG_FLAG =        0x00040000
    SET @ERR_LOC_NOMAST2 =     0x00080000
    SET @ERR_LOC =             0x00100000
    SET @ERR_LOC_NOMAST =      0x00200000
    SET @ERR_LOC_ACCTCODE =    0x00400000
    SET @ERR_LOC_INVCODE =     0x00800000
    SET @ERR_ACTIVE_FLAG =     0x01000000
    SET @ERR_BPLOC =           0x02000000
    SET @ERR_INVLDPART =       0x04000000
    SET @ERR_CONSTRAIN =       0x08000000
    SET @ERR_FIXED =           0x10000000
    SET @ERR_ALLOW_FRACTIONS = 0x20000000
    --
    -- record_status_1 bit combinations.
    --
    SET @ERRS_BASIC = @ERR_UOM + @ERR_CATEGORY + @ERR_TYPE_CODE + @ERR_STATUS
                      + @ERR_COMMTYPE + @ERR_CYCLETYPE + @ERR_FREIGHTCLS + @ERR_NOLOC
                      + @ERR_INVCOST_METH + @ERR_ACCOUNT + @ERR_TAXCODE + @ERR_CURR
                      + @ERR_ALT_UOM + @ERR_RPT_UOM + @ERR_QC_FLAG + @ERR_CFG_FLAG
                      + @ERR_ALLOW_FRACTIONS
    SET @ERRS_LOC = @ERR_LOC + @ERR_LOC_NOMAST + @ERR_LOC_NOMAST2 + @ERR_LOC_ACCTCODE
    SET @ERRS_BUILDPLAN = @ERR_ACTIVE_FLAG + @ERR_BPLOC + @ERR_INVLDPART + @ERR_CONSTRAIN 
                          + @ERR_FIXED + @ERR_INCOMPTYPES
    --
    -- record_status_2 bits.
    --
    SET @ERR_LBS_NOLOC =        0x00000001
    SET @ERR_LBS_UOM =          0x00000002
    SET @ERR_LBS_CODE =         0x00000004
    SET @ERR_LBS_LBTRACK =      0x00000008
    SET @ERR_PRIC_NOLOC =       0x00000010
    SET @ERR_PRIC_UOM =         0x00000020
    SET @ERR_INVLD_BPPART =     0x00000040
    SET @ERR_BP_UOM =           0x00000080
    SET @ERR_LOC_DUP =          0x00000100
    SET @ERR_LBS_NEGQTY =       0x00000200
    SET @ERR_BP_SEQ =           0x00000400
    SET @ERR_LBS_NULLBINNO =    0x00000800
    SET @ERR_LBS_NULLLOTSER =   0x00001000
    SET @ERR_LBS_MSTRNOLBTRAK = 0x00002000
    SET @ERR_DUPLICATE =        0x00004000
    -- SET @ERR_CURR =          0x00008000 -- Used in both record_status_1 and _2
                             -- 0x00010000
                             -- 0x00020000
    SET @ERR_PUR_NOMAST =       0x00040000
    --
    -- record_status_2 bit combinations.  Not that @ERR_LOC_DUP and 
    -- @ERR_DUPLICATE bits are not initially turned on. 
    --
    SET @ERRS_PURCHASING = @ERR_VENDOR + @ERR_BUYER + @ERR_PUR_NOMAST
    SET @ERRS_LBS = @ERR_LBS_NOLOC + @ERR_LBS_UOM + @ERR_LBS_CODE + @ERR_LBS_LBTRACK 
                    + @ERR_LBS_NEGQTY + @ERR_LBS_NULLBINNO + @ERR_LBS_NULLLOTSER 
                    + @ERR_LBS_MSTRNOLBTRAK
    SET @ERRS_PRIC = @ERR_PRIC_NOLOC + @ERR_CURR
    --
    -- Clear all the error bits.
    --
    UPDATE [iminvmast_vw]
            SET [record_status_1] = 0x00000000,
                [record_status_2] = 0x00000000
            FROM [iminvmast_vw]
            INNER JOIN [#t1]
                    ON #t1.[record_id_num] = iminvmast_vw.[record_id_num]
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_vw 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Turn on the inventory master error bits.
    --
    UPDATE iminvmast_vw
            SET record_status_1 = @ERRS_BASIC
            FROM iminvmast_vw, #t1
            WHERE iminvmast_vw.record_id_num = #t1.record_id_num
                    AND (iminvmast_vw.record_type & @RECTYPE_INVMST_BASE) > 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_vw 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Turn on the location error bits.
    --
    UPDATE iminvmast_vw
            SET record_status_1 = record_status_1 | @ERRS_LOC
            FROM iminvmast_vw, #t1
            WHERE iminvmast_vw.record_id_num = #t1.record_id_num
                    AND (iminvmast_vw.record_type & @RECTYPE_INVLOC_BASE) > 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_vw 5' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Turn on the lot/bin/stock error bits.
    --
    UPDATE iminvmast_lbs_vw
            SET iminvmast_lbs_vw.record_status_2 = @ERRS_LBS
            FROM iminvmast_lbs_vw, #t1
            WHERE iminvmast_lbs_vw.record_id_num = #t1.record_id_num
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_lbs_vw 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Turn on the pricing error bits.
    --
    UPDATE iminvmast_pric_vw
            SET record_status_2 = record_status_2 | @ERRS_PRIC
            FROM iminvmast_pric_vw, #t1
            WHERE iminvmast_pric_vw.record_id_num = #t1.record_id_num
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_pric_vw 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Turn on the buildplan error bits (group 1).
    --
    UPDATE iminvmast_vw
            SET iminvmast_vw.record_status_1 = iminvmast_vw.record_status_1 | @ERRS_BUILDPLAN
            FROM iminvmast_vw, #t1
            WHERE iminvmast_vw.record_id_num = #t1.record_id_num
                    AND (iminvmast_vw.record_type & @RECTYPE_INVBOM) > 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_vw 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Turn on the purchasing error bits.
    --
    UPDATE iminvmast_vw
            SET iminvmast_vw.record_status_1 = iminvmast_vw.record_status_1 | @ERRS_PURCHASING
            FROM iminvmast_vw, #t1
            WHERE iminvmast_vw.record_id_num = #t1.record_id_num
                    AND (iminvmast_vw.record_type & @RECTYPE_INVMST_PURC) > 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_vw 4' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Set the error bits if the @RECTYPE_INV_STCK bit is set.
    --
    UPDATE iminvmast_loc_vw
            SET record_status_1 = record_status_1 | @ERR_LOC_INVCODE
            FROM iminvmast_loc_vw, #t1
            WHERE iminvmast_loc_vw.record_id_num = #t1.record_id_num
                    AND (iminvmast_loc_vw.record_type & @RECTYPE_INVLOC_BASE) > 0
                    AND (iminvmast_loc_vw.record_type & @RECTYPE_INVLOC_STCK) > 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_loc_vw 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Turn on the buildplan error bits (group 2).
    --
    UPDATE iminvmast_vw
            SET record_status_1 = record_status_1 | @ERR_ACTIVE_FLAG
            FROM iminvmast_vw, #t1
            WHERE iminvmast_vw.record_id_num = #t1.record_id_num
                    AND (iminvmast_vw.record_type & @RECTYPE_INVBOM) > 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_vw 6' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Perform validations.  This process will turn off the bits where an error
    -- does not exist.
    --
    -- Inventory master validations.
    --
    UPDATE iminvmast_vw
            SET record_status_2 = @ERRS_LBS
            FROM iminvmast_vw, #t1
            WHERE iminvmast_vw.record_id_num = #t1.record_id_num
                    AND (record_type & @RECTYPE_INVLBS) > 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_vw 7' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    
    UPDATE iminvmast_mstr_vw
            SET record_status_1 = record_status_1 ^ @ERR_UOM
            FROM iminvmast_mstr_vw, uom_list, #t1
            WHERE iminvmast_mstr_vw.record_id_num = #t1.record_id_num
                    AND iminvmast_mstr_vw.uom = uom_list.uom
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_mstr_vw 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    
    UPDATE iminvmast_mstr_vw
            SET record_status_1 = record_status_1 ^ @ERR_ALT_UOM
            FROM iminvmast_mstr_vw, uom_list, #t1
            WHERE iminvmast_mstr_vw.record_id_num = #t1.record_id_num
                    AND iminvmast_mstr_vw.alt_uom = uom_list.uom
                    AND NOT DATALENGTH(LTRIM(RTRIM(ISNULL(iminvmast_mstr_vw.alt_uom, '')))) = 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_mstr_vw 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    
    UPDATE iminvmast_mstr_vw
            SET record_status_1 = record_status_1 ^ @ERR_RPT_UOM
            FROM iminvmast_mstr_vw, uom_list, #t1
            WHERE iminvmast_mstr_vw.record_id_num = #t1.record_id_num
                    AND iminvmast_mstr_vw.rpt_uom = uom_list.uom
                    AND NOT DATALENGTH(LTRIM(RTRIM(ISNULL(iminvmast_mstr_vw.rpt_uom, '')))) = 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_mstr_vw 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    
    UPDATE iminvmast_mstr_vw
            SET record_status_1 = record_status_1 ^ @ERR_QC_FLAG
            FROM iminvmast_mstr_vw INNER JOIN #t1
                    ON iminvmast_mstr_vw.record_id_num = #t1.record_id_num
            WHERE UPPER(iminvmast_mstr_vw.qc_flag) IN ('N', 'Y')
                    AND NOT DATALENGTH(LTRIM(RTRIM(ISNULL(iminvmast_mstr_vw.qc_flag, '')))) = 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_mstr_vw 4' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    
    UPDATE iminvmast_mstr_vw
            SET record_status_1 = record_status_1 ^ @ERR_CFG_FLAG
            FROM iminvmast_mstr_vw INNER JOIN #t1
                    ON iminvmast_mstr_vw.record_id_num = #t1.record_id_num
            WHERE UPPER(iminvmast_mstr_vw.cfg_flag) IN ('N', 'Y')
                    AND NOT DATALENGTH(LTRIM(RTRIM(ISNULL(iminvmast_mstr_vw.cfg_flag, '')))) = 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_mstr_vw 5' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    
    UPDATE iminvmast_mstr_vw
            SET record_status_1 = record_status_1 ^ @ERR_ALLOW_FRACTIONS
            FROM iminvmast_mstr_vw INNER JOIN #t1
                    ON iminvmast_mstr_vw.record_id_num = #t1.record_id_num
            WHERE UPPER(iminvmast_mstr_vw.allow_fractions) IN (0, 1)
                    AND NOT DATALENGTH(LTRIM(RTRIM(ISNULL(iminvmast_mstr_vw.allow_fractions, '')))) = 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_mstr_vw 6' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    
    UPDATE iminvmast_vw
            SET curr_key = home_currency
            FROM iminvmast_vw, glco
            WHERE ((iminvmast_vw.record_type & @RECTYPE_INVMST_BASE) > 0)
                            OR ((iminvmast_vw.record_type & @RECTYPE_INVMST_PRIC) > 0)
                    AND DATALENGTH(LTRIM(RTRIM(ISNULL(curr_key, '')))) = 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_vw 8' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE iminvmast_vw
            SET record_status_1 = record_status_1 ^ @ERR_CURR
            FROM iminvmast_vw
                ,glcurr_vw
                ,#t1
            WHERE iminvmast_vw.record_id_num = #t1.record_id_num
                    AND ((iminvmast_vw.record_type & @RECTYPE_INVMST_BASE) > 0)
                    AND iminvmast_vw.curr_key = glcurr_vw.currency_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_vw 9' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE iminvmast_vw
            SET record_status_2 = record_status_2 ^ @ERR_CURR
            FROM iminvmast_vw, glcurr_vw, #t1
            WHERE iminvmast_vw.record_id_num = #t1.record_id_num
                    AND ((iminvmast_vw.record_type & @RECTYPE_INVMST_PRIC) > 0)
                    AND iminvmast_vw.curr_key = glcurr_vw.currency_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_vw 10' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    
    UPDATE iminvmast_vw
            SET record_status_1 = record_status_1 ^ @ERR_CATEGORY
            FROM iminvmast_vw,
                category, #t1
            WHERE iminvmast_vw.record_id_num = #t1.record_id_num
                    AND (iminvmast_vw.record_type & @RECTYPE_INVMST_BASE) > 0
                    AND iminvmast_vw.category = category.kys
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_vw 11' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    
    UPDATE iminvmast_vw
            SET record_status_1 = record_status_1 ^ @ERR_TYPE_CODE
            FROM iminvmast_vw,
                part_type, #t1
            WHERE iminvmast_vw.record_id_num = #t1.record_id_num
                    AND (iminvmast_vw.record_type & @RECTYPE_INVMST_BASE) > 0
                    AND type_code = part_type.kys
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_vw 12' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    
    UPDATE iminvmast_vw
            SET record_status_1 = record_status_1 ^ @ERR_STATUS
            FROM iminvmast_vw, #t1
            WHERE iminvmast_vw.record_id_num = #t1.record_id_num
                    AND (iminvmast_vw.record_type & @RECTYPE_INVMST_BASE) > 0
                    AND status in ('C','K','H','M','P','Q','R','V')
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_vw 13' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    
    UPDATE iminvmast_vw
            SET record_status_1 = record_status_1 ^ @ERR_COMMTYPE
            FROM iminvmast_vw, comm_type, #t1
            WHERE iminvmast_vw.record_id_num = #t1.record_id_num
                    AND (iminvmast_vw.record_type & @RECTYPE_INVMST_BASE) > 0
                    AND iminvmast_vw.comm_type = comm_type.kys
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_vw 14' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    
    UPDATE iminvmast_vw
            SET record_status_1 = record_status_1 ^ @ERR_CYCLETYPE
            FROM iminvmast_vw, cycle_types, #t1
            WHERE iminvmast_vw.record_id_num = #t1.record_id_num
                    AND (iminvmast_vw.record_type & @RECTYPE_INVMST_BASE) > 0
                    AND iminvmast_vw.cycle_type = cycle_types.kys
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_vw 15' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    
    UPDATE iminvmast_vw
            SET record_status_1 = record_status_1 ^ @ERR_FREIGHTCLS
            FROM iminvmast_vw  ,freight_class  ,#t1
            WHERE iminvmast_vw.record_id_num = #t1.record_id_num
                    AND (iminvmast_vw.record_type & @RECTYPE_INVMST_BASE) > 0
                    AND iminvmast_vw.freight_class = freight_class.freight_class
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_vw 16' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE iminvmast_mstr_vw
            SET record_status_1 = record_status_1 ^ @ERR_FREIGHTCLS
            FROM iminvmast_mstr_vw, #t1
            WHERE iminvmast_mstr_vw.record_id_num = #t1.record_id_num
                    AND (record_status_1 & @ERR_FREIGHTCLS) > 0
                    AND DATALENGTH(LTRIM(RTRIM(ISNULL(freight_class, '')))) = 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_mstr_vw 8' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    
    UPDATE iminvmast_vw
            SET record_status_1 = record_status_1 ^ @ERR_INVCOST_METH
            FROM iminvmast_vw, #t1
            WHERE iminvmast_vw.record_id_num = #t1.record_id_num
                    AND (iminvmast_vw.record_type & @RECTYPE_INVMST_BASE) > 0
                    AND inv_cost_method  in ('S','A','L','F','1','2','3','4','5','6','7','8','9')
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_vw 17' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    -- accounting code                                        */
    UPDATE iminvmast_vw
            SET record_status_1 = record_status_1 ^ @ERR_ACCOUNT
            FROM iminvmast_vw, in_account, #t1
            WHERE iminvmast_vw.record_id_num = #t1.record_id_num
                    AND (iminvmast_vw.record_type & @RECTYPE_INVMST_BASE) > 0 -- RECTYPE_INVMST_ACCT
                    AND iminvmast_vw.account = in_account.acct_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_vw 18' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE iminvmast_vw
            SET record_status_1 = record_status_1 ^ @ERR_TAXCODE
            FROM iminvmast_vw, artax, #t1
            WHERE iminvmast_vw.record_id_num = #t1.record_id_num
                    AND (iminvmast_vw.record_type & @RECTYPE_INVMST_BASE) > 0 -- RECTYPE_INVMST_ACCT
                    AND iminvmast_vw.tax_code = artax.tax_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_vw 19' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE iminvmast_vw
            SET record_status_1 = record_status_1 ^ @ERR_TAXCODE
            FROM iminvmast_vw, #t1
            WHERE iminvmast_vw.record_id_num = #t1.record_id_num
                    AND (record_type & @RECTYPE_INVMST_BASE) > 0
                    AND (record_status_1 & @ERR_TAXCODE) > 0 -- must still be in error state, checks bit is still set
                    AND (tax_code is null or tax_code <= ' ')
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_vw 20' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Check for duplicates in inv_master.  Note that the @ERR_DUPLICATE bit is being turned
    -- on here rather than off.
    --
    UPDATE [iminvmast_vw]
            SET record_status_2 = im1.record_status_2 ^ @ERR_DUPLICATE
            FROM [iminvmast_vw] im1
            INNER JOIN [inv_master]
                    ON inv_master.[part_no] = im1.[part_no]
            INNER JOIN [#t1]
                    ON #t1.[record_id_num] = im1.[record_id_num]
	    WHERE (im1.record_type & @RECTYPE_INVBOM) = 0				-- RDS
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_loc_vw 5' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Purchasing validations.
    --
    UPDATE iminvmast_vw
            SET record_status_1 = record_status_1 ^ @ERR_VENDOR
            FROM iminvmast_vw, apvend, #t1
            WHERE iminvmast_vw.record_id_num = #t1.record_id_num
                    AND (iminvmast_vw.record_type & @RECTYPE_INVMST_PURC) > 0
                    AND (iminvmast_vw.vendor = apvend.vendor_code
                    OR DATALENGTH(LTRIM(RTRIM(ISNULL(iminvmast_vw.vendor, '')))) = 0)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_vw 21' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE iminvmast_vw
            SET record_status_1 = record_status_1 ^ @ERR_BUYER
            FROM iminvmast_vw, buyers, #t1
            WHERE iminvmast_vw.record_id_num = #t1.record_id_num
                    AND (iminvmast_vw.record_type & @RECTYPE_INVMST_PURC) > 0
                    AND (iminvmast_vw.buyer = buyers.kys
                    OR DATALENGTH(LTRIM(RTRIM(ISNULL(iminvmast_vw.buyer, '')))) = 0)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_vw 22' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Location validations.
    --
    UPDATE ilv
            SET ilv.record_status_1 = ilv.record_status_1 ^ @ERR_LOC
            FROM iminvmast_loc_vw ilv, locations, #t1
            WHERE ilv.record_id_num = #t1.record_id_num
                    AND ilv.location = locations.location
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_loc_vw 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- If acct_code in eBackOffice is blank then the value on the header will
    -- be used since this field cannot be blank.
    --
    UPDATE ilv
            SET ilv.record_status_1 = ilv.record_status_1 ^ @ERR_LOC_ACCTCODE
            FROM iminvmast_loc_vw ilv, in_account, #t1
            WHERE ilv.record_id_num = #t1.record_id_num
                    AND ilv.acct_code = in_account.acct_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_loc_vw 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- If the record_type does not have the @RECTYPE_LOC_STCK
    -- bit set, then turn off the error bit.
    -- If the RECTYPE_INVLOC_BASE bit is not also set on this
    -- record then the @ERR_LOC_INVCODE bit will not be set
    -- and XORing it will turn this error bit on.
    --
    UPDATE ilv
            SET ilv.record_status_1 = ilv.record_status_1 ^ @ERR_LOC_INVCODE
            FROM iminvmast_loc_vw ilv, issue_code ic, #t1
            WHERE ilv.record_id_num = #t1.record_id_num
                    AND ilv.code = ic.code
                    AND (ilv.record_type & @RECTYPE_INVLOC_STCK) > 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_loc_vw 4' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Check for duplicates in inv_list.  Note that the @ERR_LOC_DUP bit is being turned
    -- on here rather than off.
    --
    UPDATE im1
            SET im1.record_status_2 = im1.record_status_2 ^ @ERR_LOC_DUP
            FROM iminvmast_loc_vw im1, inv_list, #t1
            WHERE im1.part_no = inv_list.part_no
                    AND im1.location = inv_list.location
                    AND im1.record_id_num = #t1.record_id_num
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_loc_vw 5' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    
    UPDATE im1
            SET record_status_2 = im1.record_status_2 ^ @ERR_LOC_DUP
            FROM (select count(*) as _count, part_no, location FROM iminvmast_loc_vw WHERE company_code = @w_cc AND process_status = 0 AND (record_status_2 & @ERR_LOC_DUP) = 0 group by part_no,location having count(*) > 1 ) as duplicates, iminvmast_loc_vw im1, #t1
            WHERE im1.part_no = duplicates.part_no
                    AND im1.location = duplicates.location
                    AND im1.record_id_num = #t1.record_id_num
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_loc_vw 6' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Ensure that for each part master record there at least one location record.
    -- For the test, mask out all non-location error bits that can exist in compound records.
    -- The Master should have no errors except "no valid location".  The Location should
    -- have no errors except "no valid master".
    --
    select @errorbits = sum(error_bit)
            FROM imerrxref_vw
            WHERE imtable = 'iminvmast_loc_vw'
                    AND status_field = 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' imerrxref_vw 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE im1
            SET record_status_1 = im1.record_status_1 ^ @ERR_NOLOC
            FROM iminvmast_mstr_vw im1, iminvmast_loc_vw im2, #t1
            WHERE im1.record_id_num = #t1.record_id_num
                    AND im1.part_no = im2.part_no
                    AND im2.company_code = @w_cc
                    AND (im1.record_status_1 & @ERRS_BASIC) = @ERR_NOLOC
                    AND (((im2.record_status_1 & @errorbits) = @ERR_LOC_NOMAST) OR ((im2.record_status_1 & @errorbits) = @ERR_LOC_NOMAST2) OR ((im2.record_status_1 & @errorbits) = @ERR_LOC_NOMAST + @ERR_LOC_NOMAST2))
                    AND im2.record_status_2 = 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_loc_vw 7' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Now the opposite test: ensure that for each location record there is a valid part
    -- master record either in the staging table or in the current company database.
    --
    -- Check the staging table for the presence (valid or otherwise) of a part master record
    -- and leave the ERR_LOC_NOMAST bit set if a record is not present.
    --
    UPDATE imiml
            SET record_status_1 = imiml.record_status_1 ^ @ERR_LOC_NOMAST
            FROM iminvmast_loc_vw imiml, iminvmast_vw im, #t1
            WHERE imiml.record_id_num = #t1.record_id_num
                    AND imiml.part_no = im.part_no
                    AND im.company_code = @w_cc
                    AND (im.record_type & @RECTYPE_INVMST_BASE) > 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_loc_vw 8a' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Check the company database, but don't turn the ERR_LOC_NOMAST bit back on
    -- if the record was already determined to be present.
    --
    UPDATE imiml
        SET record_status_1 = imiml.record_status_1 ^ @ERR_LOC_NOMAST
        FROM iminvmast_loc_vw imiml, inv_master im, #t1
        WHERE imiml.record_id_num = #t1.record_id_num
                AND imiml.part_no = im.part_no
                AND (imiml.record_status_1 & @ERR_LOC_NOMAST) > 0 
                AND im.void = 'N'
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_loc_vw 9' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Check the staging table for a valid part master record and leave the ERR_LOC_NOMAST2
    -- bit set if a record is present but invalid.
    --
    UPDATE imiml
            SET [record_status_1] = imiml.[record_status_1] ^ @ERR_LOC_NOMAST2
            FROM [iminvmast_loc_vw] imiml
            INNER JOIN #t1
                    ON imiml.[record_id_num] = #t1.[record_id_num]
            LEFT OUTER JOIN [iminvmast_mstr_vw] imim
                    ON imiml.[part_no] = imim.[part_no]
            WHERE imiml.[company_code] = @w_cc
                    AND ((imim.[record_type] & @RECTYPE_INVMST_BASE) > 0 OR imim.[record_type] IS NULL) 
                    AND (((imim.[record_status_1] & @ERRS_BASIC) = @ERR_NOLOC) OR ((imim.[record_status_1] & @ERRS_BASIC) = 0) OR (imim.[record_status_1] IS NULL))
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_loc_vw 8b' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Pricing records validations.
    --
    UPDATE imp
            SET imp.record_status_2 = imp.record_status_2 ^ @ERR_PRIC_NOLOC
            FROM iminvmast_pric_vw imp, inv_master im, #t1
                    WHERE imp.record_id_num = #t1.record_id_num
                            AND imp.part_no = im.part_no
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_pric_vw 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE imp
            SET imp.record_status_2 = imp.record_status_2 ^ @ERR_PRIC_NOLOC
            FROM iminvmast_pric_vw imp, iminvmast_mstr_vw imm, #t1
            WHERE imp.record_id_num = #t1.record_id_num
                    AND (imp.record_status_2 & @ERR_PRIC_NOLOC) > 0
                    AND (imm.record_status_1 & @ERRS_BASIC) = 0
                    AND imp.part_no = imm.part_no
                    AND imm.company_code = @w_cc
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_pric_vw 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Build plan records validations.
    --
    UPDATE iminvmast_bom_vw
            SET record_status_1 = record_status_1 ^ @ERR_ACTIVE_FLAG
            FROM iminvmast_bom_vw, #t1
            WHERE bom_active_flag in ('A','B','U','F','T','M','V')
                    AND iminvmast_bom_vw.record_id_num = #t1.record_id_num
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_bom_vw 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE iminvmast_bom_vw
            SET record_status_1 = record_status_1 ^ @ERR_BPLOC
            FROM iminvmast_bom_vw, locations, #t1
            WHERE iminvmast_bom_vw.record_id_num = #t1.record_id_num
                    AND (iminvmast_bom_vw.record_status_1 & @ERR_BPLOC) > 0
                    AND (iminvmast_bom_vw.location = locations.location OR iminvmast_bom_vw.location = 'ALL')
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_bom_vw 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE iminvmast_bom_vw
            SET iminvmast_bom_vw.record_status_1 = iminvmast_bom_vw.record_status_1 ^ @ERR_INVLDPART
            FROM iminvmast_bom_vw, inv_master
            WHERE iminvmast_bom_vw.company_code = @w_cc
                    AND (iminvmast_bom_vw.record_status_1 & @ERR_INVLDPART) > 0
                    AND iminvmast_bom_vw.part_no = inv_master.part_no
                    AND iminvmast_bom_vw.process_status = 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_bom_vw 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE iminvmast_bom_vw
            SET iminvmast_bom_vw.record_status_1 = iminvmast_bom_vw.record_status_1 ^ @ERR_INVLDPART
            FROM iminvmast_bom_vw, iminvmast_mstr_vw, #t1
            WHERE iminvmast_bom_vw.record_id_num = #t1.record_id_num
                    AND iminvmast_bom_vw.part_no = iminvmast_mstr_vw.part_no
                    AND (iminvmast_bom_vw.record_status_1 & @ERR_INVLDPART) > 0
                    AND iminvmast_mstr_vw.company_code = @w_cc
                    AND iminvmast_mstr_vw.record_status_1 = 0
                    AND iminvmast_mstr_vw.record_status_2 = 0
                    AND iminvmast_mstr_vw.process_status = 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_bom_vw 4' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE iminvmast_bom_vw
            SET record_status_1 = record_status_1 ^ @ERR_CONSTRAIN
            FROM iminvmast_bom_vw, #t1
            WHERE iminvmast_bom_vw.record_id_num = #t1.record_id_num
                    AND bom_constrain in ('Y','N')
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_bom_vw 5' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE iminvmast_bom_vw
            SET record_status_1 = record_status_1 ^ @ERR_FIXED
            FROM iminvmast_bom_vw, #t1
            WHERE iminvmast_bom_vw.record_id_num = #t1.record_id_num
                    AND bom_fixed in ('Y','N')
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_bom_vw 6' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE iminvmast_bom_vw
            SET record_status_2 = iminvmast_bom_vw.record_status_2 ^ @ERR_INVLD_BPPART
            FROM iminvmast_bom_vw, inv_master, #t1
            WHERE iminvmast_bom_vw.record_id_num = #t1.record_id_num
                    AND (iminvmast_bom_vw.record_status_2 & @ERR_INVLD_BPPART) > 0
                    AND iminvmast_bom_vw.bom_part_no = inv_master.part_no
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_bom_vw 7' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE iminvmast_bom_vw
            SET record_status_2 = iminvmast_bom_vw.record_status_2 ^ @ERR_INVLD_BPPART
            FROM iminvmast_bom_vw, iminvmast_mstr_vw, #t1
            WHERE iminvmast_bom_vw.record_id_num = #t1.record_id_num
                    AND iminvmast_bom_vw.bom_part_no = iminvmast_mstr_vw.part_no
                    AND (iminvmast_bom_vw.record_status_2 & @ERR_INVLD_BPPART) > 0
                    AND iminvmast_mstr_vw.company_code = @w_cc
                    AND iminvmast_mstr_vw.record_status_1 = 0
                    AND iminvmast_mstr_vw.record_status_2 = 0
                    AND iminvmast_mstr_vw.process_status = 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_bom_vw 8' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE iminvmast_bom_vw
            SET record_status_1 = iminvmast_bom_vw.record_status_1 ^ @ERR_INCOMPTYPES
            FROM iminvmast_bom_vw, #t1
            WHERE iminvmast_bom_vw.record_id_num = #t1.record_id_num
                    AND (iminvmast_bom_vw.record_type ^ @RECTYPE_INVBOM) = 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_bom_vw 9' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE iminvmast_bom_vw
            SET record_status_2 = iminvmast_bom_vw.record_status_2 | @ERR_BP_SEQ
            FROM iminvmast_bom_vw, #t1 
            WHERE iminvmast_bom_vw.record_id_num = #t1.record_id_num
                    AND (iminvmast_bom_vw.bom_seq_no is null OR iminvmast_bom_vw.bom_seq_no = '0')
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_bom_vw 10' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE iminvmast_bom_vw
            SET record_status_2 = iminvmast_bom_vw.record_status_2 | @ERR_BP_SEQ
            FROM iminvmast_bom_vw, #t1, (select iminvmast_bom_vw.part_no FROM iminvmast_bom_vw, #t1 WHERE iminvmast_bom_vw.record_id_num = #t1.record_id_num group by part_no, bom_seq_no having count(*) > 1) as dup_seqs
            WHERE iminvmast_bom_vw.part_no = dup_seqs.part_no
                    AND iminvmast_bom_vw.record_id_num = #t1.record_id_num
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_bom_vw 11' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Lot/bin/stock (lbs) records validations.
    --
    UPDATE iminvmast_lbs_vw
            SET lbs_date_tran = getdate(),
                lbs_date_expires = dateadd(yy,1,getdate())
            FROM iminvmast_lbs_vw, #t1
                    WHERE iminvmast_lbs_vw.record_id_num = #t1.record_id_num
                            AND lbs_date_tran is null
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_lbs_vw 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    







    UPDATE im1
            SET status = 'T'
            FROM iminvmast_lbs_vw im1, #t1
            WHERE im1.record_id_num = #t1.record_id_num
                    AND im1.status <> 'S'
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_lbs_vw 4' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    UPDATE im1
            SET record_status_2 = im1.record_status_2 ^ @ERR_LBS_LBTRACK
            FROM iminvmast_lbs_vw im1, #t1
            WHERE im1.record_id_num = #t1.record_id_num
                    AND im1.lb_tracking = 'Y'
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_lbs_vw 5' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE im1
            SET record_status_2 = im1.record_status_2 ^ @ERR_LBS_NOLOC
            FROM iminvmast_lbs_vw im1, iminvmast_loc_vw im2, #t1
            WHERE im1.record_id_num = #t1.record_id_num
                    AND im2.company_code = @w_cc
                    AND im1.part_no = im2.part_no
                    AND im1.location = im2.location
                    AND im2.record_status_1 = 0
                    AND im2.record_status_2 = 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_lbs_vw 6' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE im1
            SET record_status_2 = im1.record_status_2 ^ @ERR_LBS_NOLOC
            FROM iminvmast_lbs_vw im1, inv_list im2, #t1
            WHERE im1.record_id_num = #t1.record_id_num
                    AND (im1.record_status_2 & @ERR_LBS_NOLOC) > 0 -- make sure error bit is still on
                    AND im1.part_no = im2.part_no
                    AND im1.location = im2.location
                    AND im2.void = 'N'
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_lbs_vw 7' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE im
            SET record_status_2 = im.record_status_2 ^ @ERR_LBS_UOM
            FROM iminvmast_lbs_vw im, uom_list u, #t1
            WHERE im.record_id_num = #t1.record_id_num
                    AND (im.record_status_2 & @ERR_LBS_UOM) > 0
                    AND im.uom = u.uom
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_lbs_vw 8' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE im
            SET record_status_2 = im.record_status_2 ^ @ERR_LBS_CODE
            FROM iminvmast_lbs_vw im, issue_code ic, #t1
            WHERE im.record_id_num = #t1.record_id_num
                    AND im.code = ic.code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_lbs_vw 9' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE im
            SET record_status_2 = im.record_status_2 ^ @ERR_LBS_NEGQTY
            FROM iminvmast_lbs_vw im, #t1
            WHERE im.record_id_num = #t1.record_id_num
                    AND im.lbs_qty > 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_lbs_vw 10' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE im
            SET record_status_2 = im.record_status_2 ^ @ERR_LBS_NULLBINNO
            FROM iminvmast_lbs_vw im, #t1
            WHERE im.record_id_num = #t1.record_id_num
                    AND im.lbs_bin_no is not null
                    AND im.lbs_bin_no > ''
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_lbs_vw 11' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE im
            SET record_status_2 = im.record_status_2 ^ @ERR_LBS_NULLLOTSER
            FROM iminvmast_lbs_vw im, #t1
            WHERE im.record_id_num = #t1.record_id_num
                    AND im.lbs_lot_ser is not null
                    AND im.lbs_lot_ser > ''
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_lbs_vw 12' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE il
            SET record_status_2 = il.record_status_2 ^ @ERR_LBS_MSTRNOLBTRAK
            FROM iminvmast_lbs_vw il, iminvmast_mstr_vw im, #t1
            WHERE il.record_id_num = #t1.record_id_num
                    AND il.part_no = im.part_no
                    AND im.company_code = @w_cc
                    AND im.process_status = 0
                    AND im.record_status_1 = 0
                    AND im.record_status_2 = 0
                    AND im.lb_tracking = 'Y'
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_lbs_vw 13' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE il
            SET il.record_status_2 = il.record_status_2 ^ @ERR_LBS_MSTRNOLBTRAK
            FROM iminvmast_lbs_vw il, inv_master im, #t1
            WHERE il.record_id_num = #t1.record_id_num
                    AND (il.record_status_2 & @ERR_LBS_MSTRNOLBTRAK) > 0
                    AND il.part_no = im.part_no
                    AND im.lb_tracking = 'Y'
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' iminvmast_lbs_vw 14' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    INSERT INTO imlog VALUES (getdate(), 'INVENTORY', 1, '', '', '', 'Inventory -- End', @userid)
    RETURN 0
Error_Return:
    RETURN -1    
GO
GRANT EXECUTE ON  [dbo].[imInvVal_sp] TO [public]
GO
