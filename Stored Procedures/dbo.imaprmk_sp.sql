SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


    CREATE PROCEDURE 
[dbo].[imaprmk_sp] @trx_type smallint,
           @trx_num char(32),
           @system_date int,
           @debug_level SMALLINT = 0,
           @userid INT = 0
    AS
    
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
    

    SET @Routine_Name = 'imaprmk_sp'        
    DECLARE @po_type smallint,    
            @voucher_type     smallint,    
            @payment_type     smallint,    
            @sequence_flag     smallint,    
            @det_aprv_flag    smallint,    
            @add_appr_code     varchar(16),
            @trx_amt     float,        
            @appr_code     varchar(16),    
            @apply_date     int,        
            @acct_code     varchar(32),    
            @branch_code     varchar(16),    
            @vendor_code     varchar(12),    
            @sqid         int,        
            @last_sqid     smallint,
            @line_amt     float,        
            @approve     smallint,    
            @date_doc     int,        
            @proc_flag    smallint,
            @nat_cur_code varchar(8), 
            @rate_type_home varchar(8),
            @rate_type_oper varchar(8), 
            @rate_home float,
            @rate_oper float,    
            @approval_by_home smallint,
            @approve_amt float
    





    DECLARE @approved_flag int
    DECLARE @date_approved int
    


    SELECT @voucher_type = 4091, 
           @payment_type = 4111, 
           @det_aprv_flag = 0
    



    IF @trx_type = @payment_type
        BEGIN
        RETURN
        END
    ELSE IF @trx_type = @voucher_type
        BEGIN
        



        SELECT @det_aprv_flag = aprv_voucher_det_flag,
               @proc_flag = aprv_voucher_flag,
               @approval_by_home = aprv_hm_flag
                FROM apco
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' apco 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        SELECT @trx_amt = amt_net,
               @appr_code = approval_code,
               @vendor_code = vendor_code,
               @branch_code = branch_code,
               @apply_date = date_applied,
               @date_doc = date_doc,
               @nat_cur_code = nat_cur_code,
               @rate_type_home = rate_type_home,
               @rate_type_oper = rate_type_oper,
               @rate_home = rate_home,
               @rate_oper = rate_oper,
               @approved_flag = ABS(approval_flag - 1)
                FROM #apinpchg
                WHERE trx_type = @trx_type
                        AND trx_ctrl_num = @trx_num
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' #apinpchg 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        END
    ELSE
        RETURN 0
    --
    -- If we are importing approved transactions then we must set the approved date 
    -- to the passed-in system_date
    --
    IF @approved_flag = 1
        SELECT @date_approved = @system_date
    ELSE
        SELECT @date_approved = 0
    --
    IF @approval_by_home = 1
       SELECT @approve_amt = @trx_amt * ( SIGN(1 + SIGN(@rate_home))*(@rate_home) + (SIGN(ABS(SIGN(ROUND(@rate_home,6))))/(@rate_home + SIGN(1 - ABS(SIGN(ROUND(@rate_home,6)))))) * SIGN(SIGN(@rate_home) - 1) )
    ELSE 
       SELECT @approve_amt = @trx_amt * ( SIGN(1 + SIGN(@rate_oper))*(@rate_oper) + (SIGN(ABS(SIGN(ROUND(@rate_oper,6))))/(@rate_oper + SIGN(1 - ABS(SIGN(ROUND(@rate_oper,6)))))) * SIGN(SIGN(@rate_oper) - 1) )
    



    -- *** investigate later: this next line is just asking for trouble 
    IF @appr_code != SPACE(8) 
            AND @proc_flag = 1
        BEGIN
        INSERT apaprtrx (user_id,         trx_ctrl_num,   trx_type,
                         amount,          approved_flag,  disappr_flag,
                         display_flag,    disable_flag,   date_approved,
                         date_doc,        date_assigned,  appr_user_id,
                         disappr_user_id, approval_code,  sequence_flag,
                         appr_seq_id,     appr_complete,  vendor_code,
                         comment,         changed_flag,   origin_flag,
                         nat_cur_code,    rate_type_home, rate_type_oper,
                         rate_home,       rate_oper)
                SELECT user_id,       @trx_num,        @trx_type,
                       @trx_amt,      @approved_flag,  0,
                       1,             0,               @date_approved,
                       @date_doc,     @system_date,    0,
                       0,             @appr_code,      0,
                       sequence_id,   0,               @vendor_code,
                       '',            0,               1,
                       @nat_cur_code, @rate_type_home, @rate_type_oper,
                       @rate_home,    @rate_oper
                        FROM apaprdet
                        WHERE approval_code = @appr_code
                                AND ((@approve_amt) BETWEEN ((amt_min) - 0.0000001) AND ((amt_max) + 0.0000001)) 
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' apaprtrx 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        


        SELECT @sequence_flag = 0
        SELECT @sequence_flag = sequence_flag
                FROM apapr
                WHERE approval_code = @appr_code
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' apapr 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        



        IF @sequence_flag = 1
            BEGIN
            


            UPDATE apaprtrx
                SET sequence_flag = 1
                WHERE trx_ctrl_num = @trx_num
                        AND trx_type = @trx_type
                        AND approval_code = @appr_code
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' apaprtrx 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            


            UPDATE apaprtrx
                SET display_flag = 0
                WHERE trx_ctrl_num = @trx_num
                        AND trx_type = @trx_type
                        AND approval_code = @appr_code
                        AND appr_seq_id > (SELECT MIN(appr_seq_id) FROM apaprtrx WHERE trx_ctrl_num = @trx_num AND trx_type = @trx_type AND approval_code = @appr_code)
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' apaprtrx 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            END
        END
    



    SET ROWCOUNT  1
    SELECT @add_appr_code = NULL
    




    IF @trx_type = @voucher_type
        BEGIN
        SELECT @add_appr_code = approval_code
                FROM apaprdfh
                WHERE ((branch_code = @branch_code AND vendor_code = @vendor_code) OR (branch_code = '' AND vendor_code = @vendor_code) OR (branch_code = @branch_code AND vendor_code = ''))
                        AND vouch_flag = 1
                        AND ((amt_min) <= (@approve_amt) + 0.0000001)
                ORDER BY sequence_id
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' apaprdfh 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        END        
    SET ROWCOUNT  0
    



    IF @add_appr_code IS NOT NULL 
            AND @add_appr_code != @appr_code
            AND @proc_flag = 1
        BEGIN
        INSERT apaprtrx (user_id,            trx_ctrl_num,    trx_type,
                         amount,                approved_flag,    disappr_flag,
                         display_flag,        disable_flag,    date_approved,
                         date_doc,            date_assigned,    appr_user_id,
                         disappr_user_id,    approval_code,    sequence_flag,
                         appr_seq_id,        appr_complete,    vendor_code,
                         comment,            changed_flag,    origin_flag,
                         nat_cur_code,        rate_type_home,    rate_type_oper,
                         rate_home,             rate_oper )
                SELECT user_id,            @trx_num,        @trx_type,    
                       @trx_amt,            @approved_flag,                0,
                       1,                  0,                @date_approved,
                       @date_doc,            @system_date,    0,
                       0,                    @add_appr_code,    0,    
                       sequence_id,        0,                @vendor_code,    
                       '',                0,                2,
                       @nat_cur_code,        @rate_type_home,@rate_type_oper,
                       @rate_home,            @rate_oper
                        FROM apaprdet
                        WHERE approval_code = @add_appr_code
                                AND ((@approve_amt) BETWEEN ((amt_min) - 0.0000001) AND ((amt_max) + 0.0000001))
                                AND user_id NOT IN (SELECT user_id FROM apaprtrx WHERE trx_ctrl_num = @trx_num)
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' apaprtrx 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        



        SELECT @sequence_flag = sequence_flag
                FROM apapr
                WHERE approval_code = @add_appr_code
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' apapr 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        IF @sequence_flag = 1
            BEGIN
            


            UPDATE apaprtrx
                    SET sequence_flag = 1
                    WHERE trx_ctrl_num = @trx_num
                            AND trx_type = @trx_type
                            AND approval_code = @add_appr_code
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' apaprtrx 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            


            UPDATE apaprtrx
                    SET display_flag = 0
                    WHERE trx_ctrl_num = @trx_num
                            AND trx_type = @trx_type
                            AND approval_code = @add_appr_code
                            AND appr_seq_id > (SELECT MIN(appr_seq_id) FROM apaprtrx WHERE trx_ctrl_num = @trx_num AND trx_type = @trx_type AND approval_code = @add_appr_code)
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' apaprtrx 4' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            END
        END
    IF @trx_type = @voucher_type 
            AND @det_aprv_flag = 1
        BEGIN
        


        SELECT @sqid = 1, 
               @last_sqid = 0
        SELECT @last_sqid = MAX(sequence_id)
                FROM #apinpcdt
                WHERE trx_type = @trx_type
                        AND trx_ctrl_num = @trx_num
        WHILE (@sqid <= @last_sqid)
            BEGIN
            SELECT @acct_code = NULL
            SELECT @acct_code = gl_exp_acct,
                   @line_amt = ((qty_received * unit_price) - amt_discount + amt_freight + amt_misc + amt_tax)
                    FROM #apinpcdt
                    WHERE trx_type = @trx_type
                            AND trx_ctrl_num = @trx_num
                            AND sequence_id = @sqid
                    


            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' #apinpcdt 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            


            SELECT @sqid = @sqid + 1
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @sqid 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            


            IF (@acct_code IS NULL)
                CONTINUE
            SET ROWCOUNT  1
            SELECT @add_appr_code = NULL
            



            SELECT @add_appr_code = approval_code
                    FROM apaprdfd
                    WHERE @acct_code LIKE substring(exp_acct_code,1,datalength(@acct_code))
                              AND ((amt_min) <= (@line_amt) + 0.0000001)
                    ORDER BY sequence_id
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' apaprdfd 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            SET ROWCOUNT  0
            


            IF @add_appr_code IS NULL
                CONTINUE
            


            UPDATE #apinpcdt
                    SET approval_code = @add_appr_code
                    WHERE trx_type = @trx_type
                            AND trx_ctrl_num = @trx_num
                            AND sequence_id = ( @sqid - 1 )
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #apinpcdt 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            



            IF NOT EXISTS( SELECT approval_code FROM apaprtrx WHERE trx_ctrl_num = @trx_num AND trx_type = @trx_type AND approval_code = @add_appr_code)
                BEGIN
                INSERT apaprtrx (user_id,            trx_ctrl_num,    trx_type,
                                 amount,                approved_flag,    disappr_flag,
                                 display_flag,        disable_flag,    date_approved,
                                 date_doc,            date_assigned,    appr_user_id,
                                 disappr_user_id,    approval_code,    sequence_flag,
                                 appr_seq_id,        appr_complete,    vendor_code,
                                 comment,            changed_flag,    origin_flag,
                                 nat_cur_code,        rate_type_home,    rate_type_oper,
                                 rate_home,             rate_oper )
                        SELECT user_id,            @trx_num,        @trx_type,    
                               @trx_amt,            @approved_flag,                 0,     
                               1,                  0,                @date_approved,         
                               @date_doc,            @system_date,    0,            
                               0,                    @add_appr_code,    0,            
                               sequence_id,        0,                @vendor_code,        
                               '',                0,                3,
                               @nat_cur_code,        @rate_type_home,@rate_type_oper,
                               @rate_home,            @rate_oper
                                FROM apaprdet
                                WHERE  approval_code = @add_appr_code
                                AND ((@approve_amt) BETWEEN ((amt_min) - 0.0000001) AND ((amt_max) + 0.0000001))
                                AND user_id NOT IN (SELECT user_id FROM apaprtrx WHERE trx_ctrl_num = @trx_num)                    
                SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' apaprtrx 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
                



                SELECT @sequence_flag = sequence_flag
                        FROM apapr
                        WHERE approval_code = @add_appr_code
                IF @sequence_flag > 0 
                    BEGIN
                    


                    UPDATE apaprtrx
                        SET sequence_flag = 1
                        WHERE trx_ctrl_num = @trx_num
                                AND trx_type = @trx_type
                                AND approval_code = @add_appr_code
                    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' apaprtrx 5' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
                    


                    UPDATE apaprtrx
                            SET display_flag = 0,
                                sequence_flag = @sequence_flag
                            WHERE trx_ctrl_num = @trx_num
                                    AND trx_type = @trx_type
                                    AND approval_code = @add_appr_code
                                    AND appr_seq_id > (SELECT MIN(appr_seq_id) FROM apaprtrx WHERE trx_ctrl_num = @trx_num AND trx_type = @trx_type AND approval_code = @add_appr_code)
                    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' apaprtrx 6' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
                    END
                END
            END
        END
    




    IF NOT EXISTS(SELECT trx_ctrl_num FROM apaprtrx WHERE trx_ctrl_num = @trx_num AND trx_type = @trx_type AND approved_flag = 0)
        SELECT @approve = 0
    ELSE
        SELECT @approve = 1
    IF @trx_type = @voucher_type
        BEGIN
        UPDATE #apinpchg
                SET approval_flag = @approve
                WHERE trx_ctrl_num = @trx_num
                        AND trx_type = @trx_type
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #apinpchg 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        END                    
    RETURN 0
Error_Return:
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': Exit (ERROR).'
    RETURN -1    
GO
GRANT EXECUTE ON  [dbo].[imaprmk_sp] TO [public]
GO
