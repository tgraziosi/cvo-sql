SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


    CREATE PROC 
[dbo].[IMARValidateInvoice_sp] @db_userid char(40), 
                       @db_password char(40), 
                       @invoice_flag smallint, 
                       @debug_level int, 
                       @pcn varchar(16) OUTPUT,
                       @IMARValidateInvoice_sp_company_code VARCHAR(8),
                       @userid INT = 0
    AS      
    DECLARE @spid int
    DECLARE @result numeric(16, 0)
    DECLARE @buf varchar(255)
    DECLARE @im_config_Validate_Errors_Only SMALLINT
    DECLARE @module_id SMALLINT
    DECLARE @process_ctrl_num VARCHAR(16)
    DECLARE @process_description VARCHAR(40)
    
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
    

    SET NOCOUNT ON
    
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
    

    SET @Routine_Name = 'IMARValidateInvoice_sp'
    SET @Error_Table_Name = 'imicmerr_vw'        
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': Entry   ' + RTRIM(LTRIM(ISNULL(@db_userid, ''))) + ',' + RTRIM(LTRIM(CONVERT(CHAR(4),@invoice_flag))) + ',' + RTRIM(LTRIM(CONVERT(CHAR(5),@debug_level)))
    

    
    IF NOT @invoice_flag = 2031
            AND NOT @invoice_flag = 2032
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
    SELECT @spid = @@spid
    SET @module_id = 2100
    IF @invoice_flag = 2031
        SET @process_description = 'Import Manager -- Invoice Validation'
    IF @invoice_flag = 2032
        SET @process_description = 'Import Manager -- Credit Memo Validation'
    IF @userid = 0
        SELECT @userid = USER_ID()
    SET @process_ctrl_num = ''
    SET @im_config_Validate_Errors_Only = 1
    SELECT @im_config_Validate_Errors_Only = ISNULL([INT Value], 1)
            FROM [im_config]
            WHERE LTRIM(RTRIM(UPPER(ISNULL([Item Name], '')))) = 'I/CM VALIDATE ERRORS ONLY'
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' im_config 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
    EXEC @SP_Result = pctrladd_sp @process_ctrl_num OUTPUT,
                                  @process_description, 
                                  @userid,
                                  @module_id, 
                                  @IMARValidateInvoice_sp_company_code,
                                  @invoice_flag
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
    









CREATE TABLE #ewerror
(
    module_id smallint,
	err_code  int,
	info1 char(32),
	info2 char(32),
	infoint int,
	infofloat float,
	flag1 smallint,
	trx_ctrl_num char(16),
	sequence_id int,
	source_ctrl_num char(16),
	extra int
)

    
CREATE TABLE #arvalchg
(
	trx_ctrl_num    varchar(16),
	doc_ctrl_num    varchar(16),
	doc_desc	varchar(40),
	apply_to_num    varchar(16),
	apply_trx_type  smallint,
	order_ctrl_num  varchar(16),
	batch_code      varchar(16),
	trx_type        smallint,
	date_entered    int,
	date_applied    int,
	date_doc        int,
	date_shipped    int,
	date_required   int,
	date_due        int,
	date_aging      int,
	customer_code   varchar(8),
	ship_to_code    varchar(8),
	salesperson_code        varchar(8),
	territory_code  varchar(8),
	comment_code    varchar(8),
	fob_code        varchar(8),
	freight_code    varchar(8),
	terms_code      varchar(8),
	fin_chg_code    varchar(8),
	price_code      varchar(8),
	dest_zone_code  varchar(8),
	posting_code    varchar(8),
	recurring_flag  smallint,
	recurring_code  varchar(8),
	tax_code        varchar(8),
	cust_po_num     varchar(20),
	total_weight    float,
	amt_gross       float,
	amt_freight     float,
	amt_tax float,
	amt_tax_included	float,
	amt_discount    float,
	amt_net float,
	amt_paid        float,
	amt_due float,
	amt_cost        float,
	amt_profit      float,
	next_serial_id  smallint,
	printed_flag    smallint,
	posted_flag     smallint,
	hold_flag       smallint,
	hold_desc	varchar(40),
	user_id smallint,
	customer_addr1	varchar(40),
	customer_addr2	varchar(40),
	customer_addr3	varchar(40),
	customer_addr4	varchar(40),
	customer_addr5	varchar(40),
	customer_addr6	varchar(40),
	ship_to_addr1	varchar(40),
	ship_to_addr2	varchar(40),
	ship_to_addr3	varchar(40),
	ship_to_addr4	varchar(40),
	ship_to_addr5	varchar(40),
	ship_to_addr6	varchar(40),
	attention_name	varchar(40),
	attention_phone	varchar(30),
	amt_rem_rev     float,
	amt_rem_tax     float,
	date_recurring  int,
	location_code   varchar(8),
	process_group_num       varchar(16) NULL,
	source_trx_ctrl_num     varchar(16) NULL,
	source_trx_type smallint NULL,
	amt_discount_taken      float NULL,
	amt_write_off_given     float NULL,
	nat_cur_code    varchar(8),     
	rate_type_home  varchar(8),     
	rate_type_oper  varchar(8),     
	rate_home       float,  
	rate_oper       float,   
	temp_flag	smallint	NULL,
	org_id				varchar(30) NULL,
	interbranch_flag		integer NULL,
	temp_flag2			integer NULL
)




    
CREATE TABLE #arvalcdt
(
	trx_ctrl_num		varchar(16),
	doc_ctrl_num		varchar(16),
	sequence_id	 	int,
	trx_type	 	smallint,
	location_code		varchar(8),
	item_code	 	varchar(30),
	bulk_flag	 	smallint,
	date_entered		int,
	line_desc	 	varchar(60),		
	qty_ordered	 	float,
	qty_shipped	 	float,
	unit_code	 	varchar(8),
	unit_price	 	float,
	unit_cost	 	float,
	extended_price	float,
	weight	 		float,
	serial_id	 	int,
	tax_code	 	varchar(8),
	gl_rev_acct	 	varchar(32),
	disc_prc_flag		smallint,
	discount_amt		float,
	discount_prc		float,
	commission_flag	smallint,
	rma_num		varchar(16),
	return_code	 	varchar(8),
	qty_returned		float,
	qty_prev_returned	float,
	new_gl_rev_acct	varchar(32),		
	iv_post_flag		smallint,	
	oe_orig_flag		smallint,	
	calc_tax		float,
	reference_code	varchar(32) NULL,
	new_reference_code	varchar(32) NULL,
	temp_flag		smallint NULL,
	org_id				varchar(30) NULL,
	temp_flag2			integer NULL
)


    
CREATE TABLE #arvalage
(
	trx_ctrl_num		varchar(16),
	sequence_id		int,	
	doc_ctrl_num		varchar(16),
	apply_to_num		varchar(16),
	apply_trx_type	smallint,
	trx_type		smallint,
	date_applied		int,
	date_due		int,
	date_aging		int,
	customer_code		varchar(8),
	salesperson_code	varchar(8),
	territory_code	varchar(8),
	price_code		varchar(8),
	amt_due		float,
	temp_flag	  	smallint NULL
)


    
CREATE TABLE #arvaltax
(
	trx_ctrl_num		varchar(16),
	trx_type        	smallint,
	sequence_id     	int,
	tax_type_code   	varchar(8),
	amt_taxable     	float,
	amt_gross       	float,
	amt_tax 		float,
	amt_final_tax   	float,
	temp_flag	  	smallint NULL
)


    
CREATE TABLE #arvalrev
(
	trx_ctrl_num	varchar(16),
	sequence_id	int,
	rev_acct_code	varchar(32),
	apply_amt	float,
	trx_type	smallint,
	reference_code	varchar(32) NULL,
	temp_flag 	smallint,
	org_id varchar(30) NULL, 
	interbranch_flag integer NULL
)


    
CREATE TABLE #arvaltmp
(
	trx_ctrl_num		varchar(16),	
	doc_ctrl_num		varchar(16), 
	date_doc		int,
	customer_code		varchar(8),
	payment_code		varchar(8),
	amt_payment		float,
	amt_disc_taken	float,
	cash_acct_code	varchar(32),
	temp_flag	  	smallint NULL
)


    EXEC @SP_Result = ARINSrcInsertValTables_SP @debug_level
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' ARINSrcInsertValTables_SP 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    IF NOT @SP_Result = 0
        BEGIN
        EXEC im_log_sp_error_sp @ILSE_Error_Code = @SP_Result,
                                @ILSE_SP_Name = 'ARINSrcInsertValTables_SP',
                                @ILSE_String = '',
                                @ILSE_Procedure_Name = @Routine_Name,
                                @ILSE_Log_Activity = 'YES',
                                @im_log_sp_error_sp_User_ID = @userid
        GOTO Error_Return
        END
    IF @invoice_flag = 2031
      BEGIN
        EXEC @SP_Result = arinvedt_sp @im_config_Validate_Errors_Only,
                                      @debug_level

		EXEC @SP_Result = imarvalh_sp @invoice_flag, @debug_level 
	
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' arinvedt_sp 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        IF NOT @SP_Result = 0
          BEGIN
            EXEC im_log_sp_error_sp @ILSE_Error_Code = @SP_Result,
                                    @ILSE_SP_Name = 'arinvedt_sp',
                                    @ILSE_String = '',
                                    @ILSE_Procedure_Name = @Routine_Name,
                                    @ILSE_Log_Activity = 'YES',
                                    @im_log_sp_error_sp_User_ID = @userid
            GOTO Error_Return
          END
	  




		IF ( SELECT e_level FROM aredterr WHERE e_code = 20002 ) >= 3 --@error_level.  20002
		BEGIN
		  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "imarvi.sp" + ", line " + STR( 147, 5 ) + " -- MSG: " + "Validate that the Doc Num exists as an unposted invoice"
		  
		  INSERT	#ewerror
		  SELECT 2000,
		  	20002,
			a.doc_ctrl_num,
			"",
			0,
			0.0,
			1,
			a.trx_ctrl_num,
			0,
			ISNULL(a.source_trx_ctrl_num, ""),
			0
		  FROM   #arvalchg a, arinpchg_all b
	  	  WHERE  a.doc_ctrl_num = b.doc_ctrl_num 
			AND a.trx_ctrl_num != b.trx_ctrl_num
			AND ( LTRIM(a.doc_ctrl_num) IS NOT NULL AND LTRIM(a.doc_ctrl_num) != " " )
		END
		
		
		IF ( SELECT e_level FROM aredterr WHERE e_code = 20003 ) >= 3 --@error_level
		BEGIN
		  IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "imarvi.sp" + ", line " + STR( 170, 5 ) + " -- MSG: " + "Validate that the Doc Num exists as a posted invoice"
		  
		  INSERT	#ewerror
		  SELECT 2000,
		  	20003,
			a.doc_ctrl_num,
			"",
			0,
			0.0,
			1,
			a.trx_ctrl_num,
			0,
			ISNULL(a.source_trx_ctrl_num, ""),
			0
		  FROM   #arvalchg a, artrx_all b
		  WHERE  a.doc_ctrl_num = b.doc_ctrl_num
		  AND	a.trx_type = b.trx_type
		END
	  
      END    
    IF @invoice_flag = 2032
      BEGIN
        EXEC @SP_Result = arcmedt_sp @im_config_Validate_Errors_Only,
                                     @debug_level

		EXEC @SP_Result = imarvalh_sp @invoice_flag, @debug_level 

        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' arinvedt_sp 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        IF NOT @SP_Result = 0
          BEGIN
            EXEC im_log_sp_error_sp @ILSE_Error_Code = @SP_Result,
                                    @ILSE_SP_Name = 'arinvedt_sp',
                                    @ILSE_String = '',
                                    @ILSE_Procedure_Name = @Routine_Name,
                                    @ILSE_Log_Activity = 'YES',
                                    @im_log_sp_error_sp_User_ID = @userid
            GOTO Error_Return
          END
        --
        -- Verify that these credit memos are not duplicated.
        --
        INSERT [#ewerror]
                SELECT 2000,           20946,
                       a.doc_ctrl_num, '',
                       0,              0,
                       1,              a.trx_ctrl_num, 
                       0,              ISNULL(a.source_trx_ctrl_num, ''), 
                       0
                        FROM [#arvalchg] a
                        INNER JOIN [arinpchg_all] b 		
                                ON a.[doc_ctrl_num] = b.[doc_ctrl_num] 
                                        AND a.[customer_code] = b.[customer_code] 
                                        AND NOT a.[trx_ctrl_num] = b.[trx_ctrl_num]
                        WHERE NOT DATALENGTH(LTRIM(RTRIM(ISNULL(a.doc_ctrl_num, '')))) = 0
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #ewerror 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        INSERT [#ewerror]
                SELECT 2000,           20947,
                       a.doc_ctrl_num, '',
                       0,              0,
                       1,              a.trx_ctrl_num, 
                       0,              ISNULL(a.source_trx_ctrl_num, ''), 
                       0
                        FROM [#arvalchg] a
                        INNER JOIN [artrx_all] b				
                                ON a.[doc_ctrl_num] = b.[doc_ctrl_num]
                                        AND a.[customer_code] = b.[customer_code] 
                                        AND a.[trx_type] = b.[trx_type]
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #ewerror 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
      END    
    IF @debug_level >= 3
        BEGIN
        SELECT '(3): ' + @Routine_Name + ': #ewerror after validation:'
        SELECT * 
            FROM #ewerror
        END    
    EXEC @SP_Result = ARInsertPERRors_SP @process_ctrl_num,
                                         @process_ctrl_num,
                                         @debug_level
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' ARInsertPERRors_SP 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    IF NOT @SP_Result = 0
            AND NOT @SP_Result = 34562
        BEGIN
        EXEC im_log_sp_error_sp @ILSE_Error_Code = @SP_Result,
                                @ILSE_SP_Name = 'ARInsertPERRors_SP',
                                @ILSE_String = '',
                                @ILSE_Procedure_Name = @Routine_Name,
                                @ILSE_Log_Activity = 'YES',
                                @im_log_sp_error_sp_User_ID = @userid
        GOTO Error_Return
        END
    DROP TABLE #ewerror 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DROPTABLE + ' #ewerror 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    DROP TABLE #arvalchg    
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DROPTABLE + ' #arvalchg 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    DROP TABLE #arvalcdt    
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DROPTABLE + ' #arvalcdt 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    DROP TABLE #arvalage    
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DROPTABLE + ' #arvalage 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    DROP TABLE #arvaltax    
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DROPTABLE + ' #arvaltax 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    DROP TABLE #arvalrev    
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DROPTABLE + ' #arvalrev 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    DROP TABLE #arvaltmp    
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DROPTABLE + ' #arvaltmp 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    EXEC @SP_Result = pctrlupd_sp @process_ctrl_num,
                                  3
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' pctrlupd_sp 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
    IF NOT @SP_Result = 0
            AND NOT @SP_Result = 34562
        BEGIN
        EXEC im_log_sp_error_sp @ILSE_Error_Code = @SP_Result,
                                @ILSE_SP_Name = 'pctrlupd_sp',
                                @ILSE_String = '',
                                @ILSE_Procedure_Name = @Routine_Name,
                                @ILSE_Log_Activity = 'YES',
                                @im_log_sp_error_sp_User_ID = @userid
        GOTO Error_Return
        END
    SET @pcn = @process_ctrl_num
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': Exit.'
    RETURN 0
Error_Return:
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': Exit (ERROR).'
    RETURN -1    
GO
GRANT EXECUTE ON  [dbo].[IMARValidateInvoice_sp] TO [public]
GO
