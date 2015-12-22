SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


    CREATE PROC 
[dbo].[imapint01a_sp] @validation_flag SMALLINT,
              @company_code VARCHAR(8),
              @invoice_flag SMALLINT,
              @method_flag SMALLINT,
              @close_batch_flag SMALLINT,
              @post_flag SMALLINT,
              @db_userid CHAR(40), 
              @db_password CHAR(40), 
              @debug_level SMALLINT,
              @perf_level SMALLINT,
              @process_ctrl_num VARCHAR(16) OUTPUT,
              @userid INT = 0,
              @imapint01a_sp_Import_Identifier INT,
              @imapint01a_sp_Process_User_ID INT = 0,
              @imapint01a_sp_User_Name VARCHAR(30) = ''
    AS
    DECLARE @im_config_batch_description VARCHAR(30)      
    DECLARE @process_description VARCHAR(40) 
    DECLARE @process_parent_app SMALLINT 
    DECLARE @process_parent_company VARCHAR(8)
    DECLARE @result SMALLINT
    DECLARE @buf            CHAR(255)
    DECLARE @module_id SMALLINT
    DECLARE @apactvnd_flag        int
    DECLARE @apactpto_flag        int
    DECLARE @apactcls_flag        int
    DECLARE @apactbch_flag        int
    DECLARE @spid            int
    DECLARE @ret_status int
    DECLARE @new_bcn VARCHAR(16)
    DECLARE @batch_flag int
    DECLARE @cur_date int
    DECLARE @cur_time int
    DECLARE @batch_type SMALLINT
    DECLARE @date_applied INT,
			@Bypass_All_Tax_Calculations NVARCHAR(1000),		
			@Bypass_Tax_Calculation_Code NVARCHAR(1000)			

    
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
    

    
    DECLARE @trx_type		smallint
    DECLARE @doc_ctrl_num	varchar(16)
    DECLARE @vendor_code	varchar(12)

    SET NOCOUNT ON
    SET @Routine_Name = 'imapint01a_sp'
    SET @Error_Table_Name = 'imvdmerr_vw'
    
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
    SELECT @spid = @@spid,
           @module_id = 4000
    --
    -- Validate parameters.
    --    
    IF NOT @invoice_flag = 4091
            AND NOT @invoice_flag = 4092
        BEGIN
        EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = 'invalid transaction type 1', 
                                                     @IGES_String = @External_String_1 OUT 
        EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = 'invalid transaction type 2', 
                                                     @IGES_String = @External_String_2 OUT 
        EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = 'invalid transaction type 3', 
                                                     @IGES_String = @External_String_3 OUT 
        EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = 'invalid transaction type 4', 
                                                     @IGES_String = @External_String_4 OUT 
        SET @External_String = @External_String_1 + ' ''''' + CAST(@invoice_flag AS VARCHAR) + ''''' ' + @External_String_2 + ' ''''@invoice_flag'''' ' + @External_String_3 + ' ''''' + @Routine_Name + ''''' ' + @External_String_4                                             
        EXEC im_log_sp @IL_Text = @External_String,
                       @IL_Log_Activity = 'YES',
                       @im_log_sp_User_ID = @userid
        GOTO Error_Return
        END
    SELECT @im_config_batch_description = RTRIM(LTRIM(ISNULL(UPPER(ISNULL([Text Value], 'Import Manager Batch')), '')))
            FROM [CVO_Control]..[im_config]
            WHERE RTRIM(LTRIM(ISNULL(UPPER([Item Name]), ''))) = 'BATCH DESCRIPTION'
                    AND [INT Value] = @imapint01a_sp_Process_User_ID
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' im_config 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END          
    



    IF @validation_flag = 1
        BEGIN
        


        IF (@debug_level >= 3)
            BEGIN
            SELECT '(3): ' + @Routine_Name + ': Begin validation phase'
            END
        EXEC @SP_Result = IMAPValidateVoucher_sp @db_userid, 
                                                 @db_password, 
                                                 @invoice_flag, 
                                                 @debug_level, 
                                                 @process_ctrl_num OUTPUT,
                                                 @company_code,
                                                 @userid
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' IMAPValidateVoucher_sp' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        IF NOT @SP_Result = 0
            BEGIN
            EXEC im_log_sp_error_sp @ILSE_Error_Code = @SP_Result,
                                    @ILSE_SP_Name = 'IMAPValidateVoucher_sp',
                                    @ILSE_String = '1',
                                    @ILSE_Procedure_Name = @Routine_Name,
                                    @ILSE_Log_Activity = 'YES',
                                    @im_log_sp_error_sp_User_ID = @userid
            GOTO Error_Return
            END    
        --
        -- Make sure that there are no duplicate records.
        -- 
        -- Records added to the perror table have some special considerations. 
        -- Input tables for vouchers and debit memos, unlike invoices and credit memos, 
        -- don't have a source control number column.  For Import Manager, ticket_num 
        -- is used in place of a source control number column in the input tables and 
        -- it can be placed into the source_trx_ctrl_num column because ticket_num
        -- was populated early in the process by source_trx_ctrl_num from the staging tables..
        --
        -- Note that the AP transaction edit rule might be set to have code 10010 as a warning
        -- (not an error) so that setting is examined here too.
        --
        IF (SELECT [err_type] FROM [apedterr] WHERE [err_code] = 10010) = 0
            BEGIN
            --
            -- Examine unposted table.
            --
            INSERT INTO perror ([process_ctrl_num], [batch_code],  [module_id], 
                                [err_code],         [info1],       [info2],
                                [infoint],          [infofloat],   [flag1],
                                [trx_ctrl_num],     [sequence_id], [source_ctrl_num],
                                [extra]) 
                    SELECT @process_ctrl_num,               '',              @module_id, 
                           90939, b.[vendor_code], '',
                           1,                               0,               0,
                           a.[trx_ctrl_num],                0,               b.ticket_num,
                           0
                            FROM [#apinpchg] a
                            INNER JOIN [apinpchg_all] b
                                    ON a.[trx_type] = b.[trx_type]
                                            AND a.[doc_ctrl_num] = b.[doc_ctrl_num]
                                            AND a.[vendor_code] = b.[vendor_code]
                            WHERE a.[trx_type] IN (4091, 4092)                
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' perror 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            --
            -- Examine posted table.
            --
            INSERT INTO perror ([process_ctrl_num], [batch_code],  [module_id], 
                                [err_code],         [info1],       [info2],
                                [infoint],          [infofloat],   [flag1],
                                [trx_ctrl_num],     [sequence_id], [source_ctrl_num],
                                [extra]) 
                    SELECT @process_ctrl_num,               '',              @module_id, 
                           90944, b.[vendor_code], '',
                           2,                               0,               0,
                           a.[trx_ctrl_num],                0,               b.ticket_num,
                           0
                            FROM [#apinpchg] a
                            INNER JOIN [apvohdr_all] b
                                    ON a.[doc_ctrl_num] = b.[doc_ctrl_num]
                                            AND a.[vendor_code] = b.[vendor_code]
                            WHERE a.[trx_type] = 4091                
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' perror 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            INSERT INTO perror ([process_ctrl_num], [batch_code],  [module_id], 
                                [err_code],         [info1],       [info2],
                                [infoint],          [infofloat],   [flag1],
                                [trx_ctrl_num],     [sequence_id], [source_ctrl_num],
                                [extra]) 
                    SELECT @process_ctrl_num,               '',              @module_id, 
                           90945, b.[vendor_code], '',
                           3,                               0,               0,
                           a.[trx_ctrl_num],                0,               b.ticket_num,
                           0
                            FROM [#apinpchg] a
                            INNER JOIN [apdmhdr] b
                                    ON a.[doc_ctrl_num] = b.[doc_ctrl_num]
                                            AND a.[vendor_code] = b.[vendor_code]
                            WHERE a.[trx_type] = 4092
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' perror 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            
            --Cursor used to validate duplicity in staging tables
	      DECLARE val_staging_tables CURSOR LOCAL READ_ONLY FOR 
	    	SELECT trx_type, doc_ctrl_num, vendor_code
	    	FROM   [#apinpchg]
	    	WHERE  [trx_type] IN (4091, 4092)
	    	GROUP  BY trx_type, doc_ctrl_num, vendor_code
	    	HAVING count(doc_ctrl_num) > 1
	    
	    --Open Cursor
	      OPEN val_staging_tables
	      --Get first
	      FETCH NEXT FROM val_staging_tables INTO @trx_type, @doc_ctrl_num,@vendor_code
	    
	      WHILE @@FETCH_STATUS = 0
	      BEGIN
	    
	        INSERT INTO perror ([process_ctrl_num], [batch_code],  [module_id], 
	                                    [err_code],         [info1],       [info2],
	                                    [infoint],          [infofloat],   [flag1],
	                                    [trx_ctrl_num],     [sequence_id], [source_ctrl_num],
	                                    [extra]) 
	        SELECT @process_ctrl_num,               '',              @module_id, 
	    				90947, [vendor_code], '',
	    				4,                               0,               0,
	    				[trx_ctrl_num],                0,               ticket_num ,0
	        FROM [#apinpchg] 
	        WHERE [trx_type] IN (4091, 4092)
	          AND [doc_ctrl_num] = @doc_ctrl_num
	          AND [vendor_code] = @vendor_code
	    
	        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' perror 4' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
	        
	        FETCH NEXT FROM val_staging_tables INTO @trx_type, @doc_ctrl_num,@vendor_code
	      END
	      
	      CLOSE val_staging_tables

            END
        --
        -- Verify that all headers have details.
        --
        INSERT INTO perror
                (process_ctrl_num, batch_code,  module_id,
                 err_code,         info1,       info2,
                 infoint,          infofloat,   flag1,
                 trx_ctrl_num,     sequence_id, source_ctrl_num,
                 extra) 
                SELECT @process_ctrl_num,       '',             @module_id,
                       90930, a.doc_ctrl_num, a.ticket_num,
                       0,                       0,              0,
                       a.trx_ctrl_num,          0,              '',
                       0
                        FROM #apinpchg a LEFT OUTER JOIN #apinpcdt b ON (a.trx_ctrl_num = b.trx_ctrl_num)
                        GROUP BY a.trx_ctrl_num, a.doc_ctrl_num, a.ticket_num
                        HAVING COUNT(b.trx_ctrl_num) = 0
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' perror 4' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        --
        -- Verify that all details have headers.  Note that since #apinpcdt records are
        -- ony created when there is a corresponding record in #imaphdr_vw, the check here
        -- must use the staging tables rather than the temporary input tables.
        --
        INSERT INTO perror
                (process_ctrl_num, batch_code, module_id,
                 err_code, info1, info2,
                 infoint, infofloat, flag1,
                 trx_ctrl_num, sequence_id, source_ctrl_num,
                 extra) 
                SELECT @process_ctrl_num,       '',            @module_id,
                       90942, '',            '',
                       0,                       0,             0,
                       a.source_trx_ctrl_num,   a.sequence_id, a.source_trx_ctrl_num,
                       0
                        FROM [#imapdtl_vw] a
                        LEFT OUTER JOIN [#imaphdr_vw] b
                                ON [a].[source_trx_ctrl_num] = [b].[source_trx_ctrl_num]
                        WHERE [b].[company_code] IS NULL
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' perror 5' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
	



		-- Get the "Bypass Tax Calculations" config table entry.
        SET @Bypass_All_Tax_Calculations = 'NO'
        IF EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'im_config')
        BEGIN
          SELECT @Bypass_All_Tax_Calculations = UPPER([Text Value])
          FROM   [im_config] 
          WHERE  UPPER([Item Name]) = 'BYPASS ALL TAX CALCULATIONS'

		  IF @Bypass_All_Tax_Calculations = 'TRUE'
            SET @Bypass_All_Tax_Calculations = 'YES'
        END
        IF @debug_level >= 3
          SELECT '(3): ' + @Routine_Name + ': Bypass All Tax Calculations = ''' + @Bypass_All_Tax_Calculations + ''''
    	
		-- "Bypass All Tax Calculations" overrides "Bypass Tax Calculation Code".
    	IF @Bypass_All_Tax_Calculations = 'YES'
		BEGIN

          -- Verify that all the detail records have a relation one-to-one between tax_code and tax_type_code.
          INSERT INTO perror
                (process_ctrl_num, batch_code,  module_id,
                 err_code,         info1,       info2,
                 infoint,          infofloat,   flag1,
                 trx_ctrl_num,     sequence_id, source_ctrl_num,
                 extra) 
				 SELECT @process_ctrl_num,		'',				@module_id, 
						90948, '',		d.tax_code, 
						0,						0.0,			0, 
						d.trx_ctrl_num,		d.sequence_id, '', 
						0
                 FROM   [#apinpcdt] d
                     INNER JOIN aptaxdet t ON d.tax_code = t.tax_code
                 GROUP  BY d.[trx_ctrl_num], d.[tax_code], d.[sequence_id]
                 HAVING COUNT(d.[trx_ctrl_num]) > 1
          SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' perror 6' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
		
		END
		ELSE
        BEGIN

          -- Get the "Bypass Tax Calculation Code" config table entry.
          SET @Bypass_Tax_Calculation_Code = ''
          IF EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'im_config')
          BEGIN
            SELECT @Bypass_Tax_Calculation_Code = [Text Value]
            FROM   [im_config] 
            WHERE  UPPER([Item Name]) = 'BYPASS TAX CALCULATION CODE'
            IF @@ROWCOUNT = 0 OR @Bypass_Tax_Calculation_Code IS NULL
              SET @Bypass_Tax_Calculation_Code = ''
          END
		  IF @debug_level >= 3
          SELECT '(3): ' + @Routine_Name + ': Bypass Tax Calculation Code = ''' + @Bypass_Tax_Calculation_Code + ''''

          -- Verify that the "Tax Code" bypassed has only one tax_type_code.
          INSERT INTO perror
                (process_ctrl_num, batch_code,  module_id,
                 err_code,         info1,       info2,
                 infoint,          infofloat,   flag1,
                 trx_ctrl_num,     sequence_id, source_ctrl_num,
                 extra) 
				 SELECT @process_ctrl_num,		'',				@module_id, 
						90949, '',		d.tax_code, 
						0,						0.0,			0, 
						d.trx_ctrl_num,		d.sequence_id, '', 
						0
                 FROM   [#apinpcdt] d
                     INNER JOIN aptaxdet t ON d.tax_code = t.tax_code
				 WHERE  d.tax_code = @Bypass_Tax_Calculation_Code
                 GROUP  BY d.[trx_ctrl_num], d.[tax_code], d.[sequence_id]
                 HAVING COUNT(d.[trx_ctrl_num]) > 1
          SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' perror 6' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
		END

	
        --
        -- Update the errors that were found earlier, before the process_ctrl_num was known
        -- Make sure we also have a row in #apinpchg for each of these errors
        --
        UPDATE perror
                SET process_ctrl_num = @process_ctrl_num
                WHERE process_ctrl_num = 'imapint01temp'
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' perror 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        --
        -- Set trx_state to 3 (error) for all records in #apinpchg that have
        -- corresponding rows in perror. First set all records to a 2 (valid) and then
        -- set the invalid records to 3.
        --
        -- Due to the fact that perror.trx_ctrl_num will be blank when records are
        -- inserted that result from validations that occur in imapint01_sp
        -- (before trx_ctrl_num is created), two UPDATEs are needed to set trx_state to 3:
        -- if trx_ctrl_num is blank, join on ticket_num and source_ctrl_num, otherwise
        -- join on trx_ctrl_num.  ticket_num and source_ctrl_num cannot be used unconditionally
        -- because perror.source_ctrl_num is set to an empty string in the standard product
        -- validations.
        --
        UPDATE #apinpchg
                SET trx_state = 2
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #apinpchg 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        UPDATE #apinpchg
                SET trx_state = 3
                FROM #apinpchg a, perror b
                WHERE a.ticket_num = b.source_ctrl_num
                        AND b.process_ctrl_num = @process_ctrl_num
                        AND b.trx_ctrl_num = ''
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #apinpchg 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        UPDATE #apinpchg
                SET trx_state = 3
                FROM #apinpchg a, perror b
                WHERE a.trx_ctrl_num = b.trx_ctrl_num
                        AND b.process_ctrl_num = @process_ctrl_num
                        AND NOT b.trx_ctrl_num = ''
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #apinpchg 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        --                
        UPDATE #apinpcdt
                SET trx_state = 2
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #apinpcdt 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        UPDATE #apinpcdt
                SET trx_state = 3
                FROM #apinpcdt a, perror b
                WHERE a.trx_ctrl_num = b.trx_ctrl_num
                        AND (a.sequence_id = b.sequence_id OR b.sequence_id = 0)
                        AND b.process_ctrl_num = @process_ctrl_num        
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #apinpcdt 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        IF (@debug_level >= 3)
            BEGIN
            SELECT '(3): ' + @Routine_Name + ': End validation phase'
            SELECT '(3): ' + @Routine_Name + ': Dump of pcontrol:'
            SELECT * 
                    FROM [CVO_Control]..[pcontrol] 
                    WHERE [process_ctrl_num] = @process_ctrl_num
            SELECT '(3): ' + @Routine_Name + ': Dump of perror:'
            SELECT * 
                    FROM [perror] 
                    WHERE [process_ctrl_num] = @process_ctrl_num
            END
        END
    ELSE
        BEGIN
        


        IF (@debug_level >= 3)
            BEGIN
            SELECT '(3): ' + @Routine_Name + ': Begin pseudo validation phase'
            END
        IF @invoice_flag = 4091
            SET @process_description = 'Import Manager -- Voucher Validation'
        IF @invoice_flag = 4092
            SET @process_description = 'Import Manager -- Debit Memo Validation'
        SET @process_parent_app = 4100 
        SET @process_ctrl_num = ''
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' @process_description 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        EXEC @SP_Result = pctrladd_sp @process_ctrl_num OUTPUT,
                                      @process_description, 
                                      @imapint01a_sp_Process_User_ID,
                                      @process_parent_app, 
                                      @company_code
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' pctrladd_sp' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
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
        


        UPDATE #apinpchg
                SET trx_state = 2
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #apinpchg 4' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        UPDATE #apinpcdt
                SET trx_state = 2
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #apinpcdt 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        


        EXEC @SP_Result = pctrlupd_sp @process_ctrl_num ,3
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' pctrlupd_sp' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
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
        --
        -- Verify that all headers have details.
        --
        INSERT INTO perror (process_ctrl_num, batch_code, module_id, err_code, info1, info2, infoint, infofloat, flag1, trx_ctrl_num, sequence_id, source_ctrl_num, extra) 
                SELECT @process_ctrl_num, '', @module_id, 90930, a.doc_ctrl_num, a.ticket_num, 0, 0.0, 0, a.trx_ctrl_num, 0, '', 0
                        FROM #apinpchg a LEFT OUTER JOIN #apinpcdt b ON (a.trx_ctrl_num = b.trx_ctrl_num)
                        GROUP BY a.trx_ctrl_num, a.doc_ctrl_num, a.ticket_num
                        HAVING COUNT(b.trx_ctrl_num) = 0
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' perror 6' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        --
        -- Verify that all details have headers.  Note that since #apinpcdt records are
        -- ony created when there is a corresponding record in #imaphdr_vw, the check here
        -- must use the staging tables rather than the temporary input tables.
        --
        INSERT INTO perror (process_ctrl_num, batch_code, module_id, err_code, info1, info2, infoint, infofloat, flag1, trx_ctrl_num, sequence_id, source_ctrl_num, extra) 
                SELECT @process_ctrl_num, '', @module_id, 90942, '', '', 0, 0.0, 0, a.source_trx_ctrl_num, a.sequence_id, a.source_trx_ctrl_num, 0
                        FROM [#imapdtl_vw] a
                        LEFT OUTER JOIN [#imaphdr_vw] b
                                ON [a].[source_trx_ctrl_num] = [b].[source_trx_ctrl_num]
                        WHERE [b].[company_code] IS NULL
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' perror 7' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
        --
        -- Update perror.process_ctrl_num and set it to the actual value for process_ctrl_num
        -- rather than the dummy "imapint01temp".
        --
        UPDATE perror
                SET process_ctrl_num = @process_ctrl_num
                WHERE process_ctrl_num = 'imapint01temp'
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' perror 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        --
        -- Update the trx_state column in the temp tables so that the save routines will behave
        -- as they did in 4.1
        --    
        UPDATE #apinpchg
                SET trx_state = 2
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #apinpchg 5' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        UPDATE #apinpchg
                SET trx_state = 3
                FROM #apinpchg a, perror b
                WHERE a.trx_ctrl_num = b.trx_ctrl_num
                        AND b.process_ctrl_num = @process_ctrl_num
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #apinpchg 6' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        UPDATE #apinpcdt
                SET trx_state = 2
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #apinpcdt 4' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        UPDATE #apinpcdt
                SET trx_state = 3
                FROM #apinpcdt a, perror b
                WHERE a.trx_ctrl_num = b.trx_ctrl_num
                        AND (a.sequence_id = b.sequence_id OR b.sequence_id = 0)
                        AND b.process_ctrl_num = @process_ctrl_num        
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #apinpcdt 5' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        IF (@debug_level >= 3)
            BEGIN
            SELECT '(3): ' + @Routine_Name + ': End pseudo validation phase'
            SELECT '(3): ' + @Routine_Name + ': Dump of pcontrol:'
            SELECT * 
                    FROM [CVO_Control]..pcontrol 
                    WHERE [process_ctrl_num] = @process_ctrl_num
            SELECT '(3): ' + @Routine_Name + ': Dump of perror:'
            SELECT * 
                    FROM [perror] 
                    WHERE [process_ctrl_num] = @process_ctrl_num
            END
        END
    



    
    UPDATE #imaphdr_vw
            SET process_ctrl_num = @process_ctrl_num,
                trx_ctrl_num = b.trx_ctrl_num
            FROM #imaphdr_vw a, #apinpchg b
            WHERE a.source_trx_ctrl_num = b.ticket_num
                    AND a.vendor_code = b.vendor_code
                    AND a.processed_flag = 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imaphdr_vw 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    UPDATE #apinpchg
            SET process_group_num = @process_ctrl_num
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #apinpchg 7' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    -- 
    -- Now flag all of the staging header table records that have errors.     
    --                                                                                
    UPDATE [#imaphdr_vw]                                                                 
            SET [processed_flag] = 2
            FROM [#imaphdr_vw] a
            INNER JOIN [perror] b                                        
                    ON a.[process_ctrl_num] = b.[process_ctrl_num]                           
                            AND a.[trx_ctrl_num] = b.[trx_ctrl_num]                       
            WHERE (a.[processed_flag] = 0 OR a.[processed_flag] IS NULL)
                    AND NOT DATALENGTH(LTRIM(RTRIM(ISNULL(b.[trx_ctrl_num], '')))) = 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imaphdr_vw 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE [#imaphdr_vw]                                                                 
            SET [processed_flag] = 2
            FROM [#imaphdr_vw] a
            INNER JOIN [perror] b                                        
                    ON a.[process_ctrl_num] = b.[process_ctrl_num]                           
                            AND a.[source_trx_ctrl_num] = b.[source_ctrl_num]                       
            WHERE (a.[processed_flag] = 0 OR a.[processed_flag] IS NULL)
                    AND DATALENGTH(LTRIM(RTRIM(ISNULL(b.[trx_ctrl_num], '')))) = 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imaphdr_vw 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE [#imaphdr_vw]                                                                 
            SET [processed_flag] = 2
            FROM [#imaphdr_vw] a
            INNER JOIN [perror] b                                        
                    ON a.[process_ctrl_num] = b.[process_ctrl_num]                           
                            AND a.[source_trx_ctrl_num] = b.[trx_ctrl_num]                       
            WHERE (NOT a.[processed_flag] = 1 OR a.[processed_flag] IS NULL)
                    AND DATALENGTH(LTRIM(RTRIM(ISNULL(b.[trx_ctrl_num], '')))) = 0
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imaphdr_vw 4' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Make sure the source_trx_ctrl_num from the staging table exists in the perror table.
    -- The update can be done using trx_ctrl_num to do the JOIN because the temporary
    -- version of the staging table will always have this column populated. 
    --
    UPDATE [perror]
            SET [source_ctrl_num] = b.[source_trx_ctrl_num]
            FROM [perror] a
            INNER JOIN [#imaphdr_vw] b
                    ON a.[trx_ctrl_num] = b.[trx_ctrl_num]
            WHERE DATALENGTH(LTRIM(RTRIM(ISNULL(a.[source_ctrl_num], '')))) = 0
                    AND (a.[sequence_id] = 0)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' perror 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE [perror]
            SET [source_ctrl_num] = b.[source_trx_ctrl_num]
            FROM [perror] a
            INNER JOIN [#imapdtl_vw] b
                    ON a.[trx_ctrl_num] = b.[trx_ctrl_num]
            WHERE DATALENGTH(LTRIM(RTRIM(ISNULL(a.[source_ctrl_num], '')))) = 0
                    AND ((a.[sequence_id] = b.[sequence_id]) OR (a.[sequence_id] = -1))
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' perror 4' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Update the detail table setting processed_flag = 2 for records in error.  
    -- The update to set process_ctrl_num is present so that a join may be done
    -- with perror and only get perror records for the current import.
    --
    UPDATE [#imapdtl_vw]
            SET [process_ctrl_num] = @process_ctrl_num
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imapdtl_vw 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    UPDATE [#imapdtl_vw]                                                                 
            SET [processed_flag] = 2
            FROM [#imapdtl_vw] a
            INNER JOIN [perror] b
                    ON a.[process_ctrl_num] = b.[process_ctrl_num]
                            AND (a.[source_trx_ctrl_num] = b.[trx_ctrl_num] OR a.[source_trx_ctrl_num] = b.[source_ctrl_num])
            WHERE (a.[processed_flag] = 0 OR a.[processed_flag] IS NULL)
                    AND ((a.[sequence_id] = b.[sequence_id]) OR (b.[sequence_id] = -1))
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imapdtl_vw 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Update the header staging table setting processed_flag = 2 for all detail
    -- records where the processed_flag = 2.
    --
    UPDATE [#imaphdr_vw]
            SET [processed_flag] = b.[processed_flag]
            FROM [#imaphdr_vw] a
            INNER JOIN [#imapdtl_vw] b
                    ON a.[source_trx_ctrl_num] = b.[source_trx_ctrl_num]
            WHERE b.[processed_flag] = 2
                    AND (a.[processed_flag] = 0 OR a.[processed_flag] IS NULL)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imaphdr_vw 6' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Copy records to the im# tables.
    --
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': Copy records to the im# tables'
    INSERT INTO [CVO_Control]..im#imaphdr 
            ([Import Identifier], [Import Company],   [Import Date],
             company_code,        process_ctrl_num,   source_trx_ctrl_num,
             trx_ctrl_num,        trx_type,           doc_ctrl_num,
             apply_to_num,        po_ctrl_num,        ticket_num,
             date_applied,        date_aging,         date_due,
             date_doc,            date_received,      date_required,
             date_discount,       posting_code,       vendor_code,
             pay_to_code,         branch_code,        comment_code,
             tax_code,            terms_code,         payment_code,
             hold_flag,           doc_desc,           hold_desc,
             intercompany_flag,   nat_cur_code,       rate_type_home,
             rate_type_oper,      rate_home,          rate_oper,
             pay_to_addr1,        pay_to_addr2,       pay_to_addr3,
             pay_to_addr4,        pay_to_addr5,       pay_to_addr6,
             attention_name,      attention_phone,    approval_code,
             approval_flag,       add_cost_flag,      amt_freight,
             amt_misc,            amt_paid,           amt_restock,
             amt_tax_included,    class_code,         cms_flag,
             date_entered,        date_recurring,     drop_ship_flag,
             fob_code,            frt_calc_tax,       location_code,
             one_check_flag,      recurring_code,     recurring_flag,
             times_accrued,       user_trx_type_code, vend_order_num,
             date_processed,      processed_flag,     [batch_no],
             [record_id_num],     [User_ID],	      [org_id],
		   [tax_freight_no_recoverable] )         
            SELECT @imapint01a_sp_Import_Identifier, @company_code,      GETDATE(),
                   company_code,                     process_ctrl_num,   source_trx_ctrl_num,
                   trx_ctrl_num,                     trx_type,           doc_ctrl_num,
                   apply_to_num,                     po_ctrl_num,        ticket_num,
                   date_applied,                     date_aging,         date_due,
                   date_doc,                         date_received,      date_required,
                   date_discount,                    posting_code,       vendor_code,
                   pay_to_code,                      branch_code,        comment_code,
                   tax_code,                         terms_code,         payment_code,
                   hold_flag,                        doc_desc,           hold_desc,
                   intercompany_flag,                nat_cur_code,       rate_type_home,
                   rate_type_oper,                   rate_home,          rate_oper,
                   pay_to_addr1,                     pay_to_addr2,       pay_to_addr3,
                   pay_to_addr4,                     pay_to_addr5,       pay_to_addr6,
                   attention_name,                   attention_phone,    approval_code,
                   approval_flag,                    add_cost_flag,      amt_freight,
                   amt_misc,                         amt_paid,           amt_restock,
                   amt_tax_included,                 class_code,         cms_flag,
                   date_entered,                     date_recurring,     drop_ship_flag,
                   fob_code,                         frt_calc_tax,       location_code,
                   one_check_flag,                   recurring_code,     recurring_flag,
                   times_accrued,                    user_trx_type_code, vend_order_num,
                   date_processed,                   processed_flag,     [batch_no],
                   [record_id_num],                  [User_ID], 		 [org_id],
		   [tax_freight_no_recoverable] 
                    FROM #imaphdr_vw
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' [CVO_Control]..im#imaphdr 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    -- Update amt_net for the benefit of the report.
    --
    UPDATE [CVO_Control]..[im#imaphdr] 
            SET [amt_net] = b.[amt_net]
            FROM [CVO_Control]..[im#imaphdr] a
            INNER JOIN [#apinpchg] b
                    ON a.[trx_ctrl_num] = b.[trx_ctrl_num]
                            AND a.[trx_type] = b.[trx_type]
            WHERE a.[Import Identifier] = @imapint01a_sp_Import_Identifier
                    AND a.[company_code] = @company_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' [CVO_Control]..im#imaphdr 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    --
    INSERT INTO [CVO_Control]..im#imapdtl 
            ([Import Identifier],     [Import Company],     [Import Date],
             company_code,            process_ctrl_num,     source_trx_ctrl_num,
             trx_ctrl_num,            trx_type,             sequence_id,
             location_code,           item_code,            qty_ordered,
             qty_received,            qty_returned,         tax_code,
             return_code,             code_1099,            po_ctrl_num,
             unit_code,               unit_price,           amt_discount,
             amt_tax,                 gl_exp_acct,          line_desc,
             reference_code,          rec_company_code,     approval_code,
             amt_freight,             amt_misc,             bulk_flag,
             calc_tax,                date_entered,         new_gl_exp_acct,
             new_reference_code,      po_orig_flag,         qty_prev_returned,
             rma_num,                 processed_flag,       [batch_no],
             [record_id_num],         [User_ID],   	    org_id,
             	amt_nonrecoverable_tax,           amt_tax_det)
            SELECT @imapint01a_sp_Import_Identifier, @company_code,    GETDATE(),
                   company_code,                     process_ctrl_num, source_trx_ctrl_num,
                   trx_ctrl_num,                     trx_type,         sequence_id,
                   location_code,                    item_code,        qty_ordered,
                   qty_received,                     qty_returned,     tax_code,
                   return_code,                      code_1099,        po_ctrl_num,
                   unit_code,                        unit_price,       amt_discount,
                   amt_tax,                          gl_exp_acct,      line_desc,
                   reference_code,                   rec_company_code, approval_code,
                   amt_freight,                      amt_misc,         bulk_flag,
                   calc_tax,                         date_entered,     new_gl_exp_acct,
                   new_reference_code,               po_orig_flag,     qty_prev_returned,
                   rma_num,                          processed_flag,   [batch_no],
                   [record_id_num],                  [User_ID],        org_id,
                   amt_nonrecoverable_tax,           amt_tax_det
                    FROM #imapdtl_vw
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' {CVO_Control]..im#imapdtl 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END                                 


    --
    IF @method_flag = 2
        BEGIN    
        





        DELETE #apinptmp
                FROM #apinptmp a, #apinpchg b
                WHERE a.trx_ctrl_num = b.trx_ctrl_num 
                        AND b.trx_state <> 2
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DELETE + ' #apinptmp 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
	DELETE #apinptax
                FROM #apinptax a, #apinpchg b
                WHERE a.trx_ctrl_num = b.trx_ctrl_num 
                        AND b.trx_state <> 2
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DELETE + ' #apinptax 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
	DELETE #apinptaxdtl
                FROM #apinptaxdtl a, #apinpchg b
                WHERE a.trx_ctrl_num = b.trx_ctrl_num 
                        AND b.trx_state <> 2
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DELETE + ' #apinptaxdtl 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        DELETE #apinpage
                FROM #apinpage a, #apinpchg b
                WHERE a.trx_ctrl_num = b.trx_ctrl_num 
                        AND b.trx_state <> 2
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DELETE + ' #apinpage 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        DELETE #apinpchg 
                WHERE trx_state <> 2
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DELETE + ' #apinpchg 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        DELETE #apinpcdt 
                WHERE trx_state <> 2
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DELETE + ' #apinpcdt 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        IF (@debug_level >= 3)  
            BEGIN
            SELECT '(3): ' + @Routine_Name + ': The following #apinpchg and #apinpcdt records will be copied to the unposted tables:'
            SELECT * 
                    FROM #apinpchg
            SELECT * 
                    FROM #apinpcdt
            END
        --
        SELECT @apactvnd_flag = apactvnd_flag,
               @apactpto_flag = apactpto_flag,
               @apactcls_flag = apactcls_flag,
               @apactbch_flag = apactbch_flag
                FROM apco
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' apco 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        UPDATE apco
                SET apactvnd_flag = 0,
                    apactpto_flag = 0,
                    apactcls_flag = 0,
                    apactbch_flag = 0
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' apco 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        



        SELECT @new_bcn = NULL
        SELECT @Row_Count = COUNT(*) 
                FROM #apinpchg
        IF EXISTS (SELECT * FROM apco WHERE batch_proc_flag = 1) 
                AND (@Row_Count > 0)
            BEGIN
            EXEC apbatnum_sp @batch_flag OUTPUT, 
                             @new_bcn OUTPUT
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' apbatnum_sp' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            EXEC @SP_Result = appdate_sp @cur_date OUTPUT
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' appdate_sp' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
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
            IF @invoice_flag = 4091
                SELECT @batch_type = 4010
            ELSE
                IF @invoice_flag = 4092
                    SELECT @batch_type = 4030
            SELECT @cur_time = datepart(hour, GETDATE()) * 3600 + datepart(minute, GETDATE()) * 60 + datepart(second, GETDATE())
            SELECT @date_applied = MIN(date_applied) FROM #apinpchg
            INSERT INTO batchctl (timestamp,      batch_ctrl_num,   batch_description,
                                  start_date,     start_time,       completed_date,
                                  completed_time, control_number,   control_total,
                                  actual_number,  actual_total,     batch_type,
                                  document_name,  hold_flag,        posted_flag,
                                  void_flag,      selected_flag,    number_held,
                                  date_applied,   date_posted,      time_posted,
                                  start_user,     completed_user,   posted_user,
                                  company_code,   selected_user_id, process_group_num,
                                  page_fill_1,    page_fill_2,      page_fill_3,
                                  page_fill_4,    page_fill_5,      page_fill_6,
                                  page_fill_7,    page_fill_8)
                    VALUES (NULL,                     @new_bcn,                 @im_config_batch_description,
                            @cur_date,                @cur_time,                0,
                            0,                        0,                        0,
                            0,                        0,                        @batch_type,
                            'IM Transaction',         0,                        0,
                            0,                        0,                        0,
                            @date_applied,            0,                        0,
                            @imapint01a_sp_User_Name, @imapint01a_sp_User_Name, '',
                            @company_code,            0,                        @process_ctrl_num,
                            NULL,                     NULL,                     NULL,
                            NULL,                     NULL,                     NULL,
                            NULL,                     NULL)
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' batchctl 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            END
        


        IF @debug_level >= 3
            SELECT '(3): ' + @Routine_Name + ': Begin save'
        EXEC @SP_Result = apvosav_sp @imapint01a_sp_Process_User_ID, 
                                     @new_bcn,
                                     @debug_level,
                                     @new_bcn
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' apvosav_sp' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        IF NOT @SP_Result = 0
            BEGIN
            EXEC im_log_sp_error_sp @ILSE_Error_Code = @SP_Result,
                                    @ILSE_SP_Name = 'apvosav_sp',
                                    @ILSE_String = '',
                                    @ILSE_Procedure_Name = @Routine_Name,
                                    @ILSE_Log_Activity = 'YES',
                                    @im_log_sp_error_sp_User_ID = @userid
            GOTO Error_Return
            END
        IF @debug_level > 3
            BEGIN
            SELECT '(3): ' + @Routine_Name + ': End save'
            SELECT '(3): ' + @Routine_Name + ': Dump of #apinpchg, #apinpcdt'
            SELECT * FROM #apinpchg
            SELECT * FROM #apinpcdt
            END
        --
        -- Set processed_flag to 1 for all records that appear in apinpchg.
        -- All records in apinpchg are valid since this is a "final" process.
        -- Also set trx_ctrl_num, process_ctrl_num, and date_processed.
        --    

        UPDATE [#imaphdr_vw]
                SET processed_flag = 1,
                    trx_ctrl_num = b.trx_ctrl_num,
                    process_ctrl_num = process_group_num,
                    date_processed = GETDATE()
                FROM [#imaphdr_vw] a
                INNER JOIN [apinpchg] b
                        ON a.[doc_ctrl_num] = b.[doc_ctrl_num]
                                AND a.[vendor_code] = b.[vendor_code]
                                AND a.[trx_type] = b.[trx_type]
                WHERE (NOT a.processed_flag = 2 OR a.processed_flag IS NULL)
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #imaphdr_vw 4' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

        UPDATE [#imapdtl_vw]
                SET process_ctrl_num = @process_ctrl_num,
                    trx_ctrl_num = b.trx_ctrl_num,
                    processed_flag = 1
                FROM [#imapdtl_vw] a
                INNER JOIN [#imaphdr_vw] b
                        ON a.[source_trx_ctrl_num] = b.[source_trx_ctrl_num]
                                AND RTRIM(LTRIM(ISNULL(a.[company_code], ''))) = RTRIM(LTRIM(ISNULL(b.[company_code], '')))
                                AND b.[process_ctrl_num] = @process_ctrl_num
                                AND a.[trx_type] = b.[trx_type]
                WHERE (NOT a.processed_flag = 2 OR a.processed_flag IS NULL)
                        AND (NOT b.[processed_flag] = 2 OR b.[processed_flag] IS NULL)
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' imapdtl_vw 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END

        --
        UPDATE apco
                SET apactvnd_flag = @apactvnd_flag,
                    apactpto_flag = @apactpto_flag,
                    apactcls_flag = @apactcls_flag,
                    apactbch_flag = @apactbch_flag
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' apco 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        IF (@close_batch_flag = 1)
            BEGIN
            EXEC @SP_Result = imbatch_sp @company_code, 
                                         @invoice_flag,
                                         @debug_level,
                                         @userid,
                                         @imapint01a_sp_User_Name
            SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' imbatch_sp' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
            IF NOT @SP_Result = 0
                BEGIN
                EXEC im_log_sp_error_sp @ILSE_Error_Code = @SP_Result,
                                        @ILSE_SP_Name = 'imbatch_sp',
                                        @ILSE_String = '',
                                        @ILSE_Procedure_Name = @Routine_Name,
                                        @ILSE_Log_Activity = 'YES',
                                        @im_log_sp_error_sp_User_ID = @userid
                GOTO Error_Return
                END
            END    
        END
    --
    -- Copy processed_flag and other items from the temporary staging tables 
    -- to the permanent staging tables.  The following code is the functional
    -- equivalent of the code in imarint01b_sp for Invoices.
    --        
    IF @method_flag = 2
        BEGIN
        UPDATE [CVO_Control]..[imaphdr]
                SET [process_ctrl_num] = @process_ctrl_num,
                    [processed_flag] = b.[processed_flag],
                    [date_processed] = b.[date_processed],
                    [trx_ctrl_num] = b.[trx_ctrl_num]
                FROM [CVO_Control]..[imaphdr] a 
                INNER JOIN [#imaphdr_vw] b    
                        ON a.[source_trx_ctrl_num] = b.[source_trx_ctrl_num]
                                AND RTRIM(LTRIM(ISNULL(a.[company_code], ''))) = RTRIM(LTRIM(ISNULL(b.[company_code], '')))
                                AND a.[trx_type] = b.[trx_type]
                WHERE RTRIM(LTRIM(ISNULL(a.[company_code], ''))) = @company_code
                        AND a.[trx_type] = @invoice_flag
                        AND (NOT a.[processed_flag] = 1 OR a.[processed_flag] IS NULL)
                        AND NOT b.[processed_flag] = 2
                        AND (a.[User_ID] = @userid OR @userid = 0)
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' [CVO_Control]..[imaphdr] 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END   
        UPDATE [CVO_Control]..[imaphdr]
                SET [process_ctrl_num] = @process_ctrl_num,
                    [processed_flag] = b.[processed_flag],
                    [date_processed] = b.[date_processed]
                FROM [CVO_Control]..[imaphdr] a 
                INNER JOIN [#imaphdr_vw] b    
                        ON a.[source_trx_ctrl_num] = b.[source_trx_ctrl_num]
                                AND RTRIM(LTRIM(ISNULL(a.[company_code], ''))) = RTRIM(LTRIM(ISNULL(b.[company_code], '')))
                                AND a.[trx_type] = b.[trx_type]
                WHERE RTRIM(LTRIM(ISNULL(a.[company_code], ''))) = @company_code
                        AND a.[trx_type] = @invoice_flag
                        AND (NOT a.[processed_flag] = 1 OR a.[processed_flag] IS NULL)
                        AND b.[processed_flag] = 2
                        AND (a.[User_ID] = @userid OR @userid = 0)
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' [CVO_Control]..[imaphdr] 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END   
        UPDATE [CVO_Control]..[imapdtl]
                SET [process_ctrl_num] = @process_ctrl_num,
                    [processed_flag] = b.processed_flag,
                    [trx_ctrl_num] = b.[trx_ctrl_num]
                FROM [CVO_Control]..[imapdtl] a 
                INNER JOIN [#imapdtl_vw] b
                        ON a.[source_trx_ctrl_num] = b.[source_trx_ctrl_num]
                                AND RTRIM(LTRIM(ISNULL(a.[company_code], ''))) = RTRIM(LTRIM(ISNULL(b.[company_code], '')))
                                AND a.[trx_type] = b.[trx_type]
                                AND a.[sequence_id] = b.[sequence_id]
                WHERE RTRIM(LTRIM(ISNULL(a.[company_code], ''))) = @company_code
                        AND a.[trx_type] = @invoice_flag
                        AND (NOT a.[processed_flag] = 1 OR a.[processed_flag] IS NULL)
                        AND NOT b.[processed_flag] = 2
                        AND (a.[User_ID] = @userid OR @userid = 0)
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' [CVO_Control]..[imapdtl] 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END   
        UPDATE [CVO_Control]..[imapdtl]
                SET [process_ctrl_num] = @process_ctrl_num,
                    [processed_flag] = b.processed_flag,
                    [trx_ctrl_num] = b.[trx_ctrl_num]
                FROM [CVO_Control]..[imapdtl] a 
                INNER JOIN [#imapdtl_vw] b
                        ON a.[source_trx_ctrl_num] = b.[source_trx_ctrl_num]
                                AND RTRIM(LTRIM(ISNULL(a.[company_code], ''))) = RTRIM(LTRIM(ISNULL(b.[company_code], '')))
                                AND a.[trx_type] = b.[trx_type]
                                AND a.[sequence_id] = b.[sequence_id]
                WHERE RTRIM(LTRIM(ISNULL(a.[company_code], ''))) = @company_code
                        AND a.[trx_type] = @invoice_flag
                        AND (NOT a.[processed_flag] = 1 OR a.[processed_flag] IS NULL)
                        AND b.[processed_flag] = 2
                        AND (a.[User_ID] = @userid OR @userid = 0)
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' [CVO_Control]..[imapdtl] 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END   
        END
    ELSE
        BEGIN
        UPDATE [CVO_Control]..[imaphdr]
                SET [process_ctrl_num] = @process_ctrl_num,
                    [processed_flag] = b.[processed_flag],
                    [date_processed] = b.[date_processed]
                FROM [CVO_Control]..[imaphdr] a 
                INNER JOIN [#imaphdr_vw] b    
                        ON a.[source_trx_ctrl_num] = b.[source_trx_ctrl_num]
                                AND RTRIM(LTRIM(ISNULL(a.[company_code], ''))) = RTRIM(LTRIM(ISNULL(b.[company_code], '')))
                                AND a.[trx_type] = b.[trx_type]
                WHERE RTRIM(LTRIM(ISNULL(a.[company_code], ''))) = @company_code
                        AND a.[trx_type] = @invoice_flag
                        AND (NOT a.[processed_flag] = 1 OR a.[processed_flag] IS NULL)
                        AND (a.[User_ID] = @userid OR @userid = 0)
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' [CVO_Control]..[imaphdr] 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END   
        UPDATE [CVO_Control]..[imapdtl]
                SET [process_ctrl_num] = @process_ctrl_num,
                    [processed_flag] = b.processed_flag
                FROM [CVO_Control]..[imapdtl] a 
                INNER JOIN [#imapdtl_vw] b
                        ON a.[source_trx_ctrl_num] = b.[source_trx_ctrl_num]
                                AND RTRIM(LTRIM(ISNULL(a.[company_code], ''))) = RTRIM(LTRIM(ISNULL(b.[company_code], '')))
                                AND a.[trx_type] = b.[trx_type]
                                AND a.[sequence_id] = b.[sequence_id]
                WHERE RTRIM(LTRIM(ISNULL(a.[company_code], ''))) = @company_code
                        AND b.[trx_type] = @invoice_flag
                        AND (NOT a.[processed_flag] = 1 OR a.[processed_flag] IS NULL)
                        AND (a.[User_ID] = @userid OR @userid = 0)
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' [CVO_Control]..[imapdtl] 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END   
        END    
    --
    -- Populate perror.trx_ctrl_num so the x_Errors_sp routine can retrieve the errors.
    -- A link in that routine needs to be made between perror.trx_ctrl_num and either 
    -- imaphdr.trx_ctrl_num or imaphdr.source_trx_ctrl_num. 
    --    
    UPDATE [perror]
            SET [perror].[trx_ctrl_num] = b.[source_trx_ctrl_num]
            FROM [perror] a
            INNER JOIN [CVO_Control]..[imaphdr] b
                    ON a.[process_ctrl_num] = b.[process_ctrl_num]
                            AND a.[source_ctrl_num] = b.[source_trx_ctrl_num]
            WHERE RTRIM(LTRIM(ISNULL(b.[company_code], ''))) = @company_code
                    AND b.[trx_type] = @invoice_flag
                    AND b.[processed_flag] = 2
                    AND a.[sequence_id] = 0
                    AND DATALENGTH(LTRIM(RTRIM(ISNULL(a.[trx_ctrl_num], '')))) = 0
                    AND (b.[User_ID] = @userid OR @userid = 0)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' perror 5' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    --
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': Exit.'
    RETURN 0
Error_Return:
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': Exit (ERROR).'
    RETURN -1    
GO
GRANT EXECUTE ON  [dbo].[imapint01a_sp] TO [public]
GO
