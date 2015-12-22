SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


    CREATE PROCEDURE 
[dbo].[imaptax_sp] @process_ctrl_num varchar(16), 
           @userid INT = 0, 
           @debug_level smallint = 0
    AS
    DECLARE @Bypass_All_Tax_Calculations NVARCHAR(1000)
    DECLARE @Bypass_Tax_Calculation_Code NVARCHAR(1000)
    DECLARE @Bypass_Tax_control_number VARCHAR(16)
    DECLARE @Bypass_Tax_Previous_control_number VARCHAR(16)
    DECLARE @Bypass_Tax_sequence_id INT
    DECLARE @Bypass_Tax_Cursor_Allocated VARCHAR(3)
    DECLARE @Bypass_Tax_Cursor_Opened VARCHAR(3)
    DECLARE @date_entered INT
    DECLARE @curr_precision SMALLINT 
    DECLARE @Zero_Out_Detail_Discount_Amounts NVARCHAR(1000)
    DECLARE @sequence_id 		INTEGER
    DECLARE @detail_sequence_id		INTEGER
    DECLARE @trx_ctrl_num 	VARCHAR(16)
    
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
    

    SET @Routine_Name = 'imaptax_sp'
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': Entry.'        
    
    --
    -- Standard_Process_2
    --
    -- Get and set DATEFORMAT if specified in the config table.
    --
    SET @im_config_DATEFORMAT = 'mdy'
    SELECT @im_config_DATEFORMAT = LOWER(ISNULL([Text Value], 'mdy'))
            FROM [im_config]
            WHERE LTRIM(RTRIM(UPPER(ISNULL([Item Name], '')))) = 'DATEFORMAT'
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' DATEFORMAT' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END        
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': DATEFORMAT = ''' + @im_config_DATEFORMAT + ''''
    IF NOT @im_config_DATEFORMAT = 'mdy'
            AND NOT @im_config_DATEFORMAT = 'ymd'
            AND NOT @im_config_DATEFORMAT = 'dmy'
        BEGIN
        SET @im_config_DATEFORMAT = 'mdy'
        IF @debug_level >= 3
            SELECT '(3): ' + @Routine_Name + ': DATEFORMAT = ''' + @im_config_DATEFORMAT + ''''
        END
    SET @January_First_Nineteen_Eighty = '1/1/80'
    SET DATEFORMAT mdy
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SET + ' DATEFORMAT 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
    IF @im_config_DATEFORMAT = 'dmy'
        BEGIN
        SET @January_First_Nineteen_Eighty = '1/1/80'
        SET DATEFORMAT dmy
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SET + ' DATEFORMAT 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        END
    IF @im_config_DATEFORMAT = 'ymd'
        BEGIN
        SET @January_First_Nineteen_Eighty = '80/1/1'
        SET DATEFORMAT ymd
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SET + ' DATEFORMAT 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
        END
    --

    SELECT @date_entered = datediff(dd, @January_First_Nineteen_Eighty, getdate()) + 722815
    SELECT @curr_precision = curr_precision
           FROM glco, glcurr_vw
           WHERE glco.home_currency = glcurr_vw.currency_code
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' glco 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
    -- 
    -- Get the "Zero Out Detail Discount Amounts" config table entry.
    --
    -- Rema Taouk had a customer who wanted to import a discount amount and put the value
    -- in the header (they called the value "retention").  The staging header table doesn't
    -- have a discount amount column so the approach taken (to avoid adding a column
    -- to the staging table in a service pack) is to sum up the discount amounts from the 
    -- detail records, put the value in the temporary unposted header table, and then
    -- zero out the temporary unposted detail table discount values.
    --
    SET @Zero_Out_Detail_Discount_Amounts = 'NO'
    IF EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'im_config')
        BEGIN
        SELECT @Zero_Out_Detail_Discount_Amounts = UPPER([Text Value])
                FROM [im_config] 
                WHERE UPPER([Item Name]) = 'ZERO OUT DETAIL DISCOUNT AMOUNTS'
        IF @@ROWCOUNT = 0
                OR @Zero_Out_Detail_Discount_Amounts IS NULL
                OR (@Zero_Out_Detail_Discount_Amounts <> 'NO' AND @Zero_Out_Detail_Discount_Amounts <> 'YES' AND @Zero_Out_Detail_Discount_Amounts <> 'TRUE' AND @Zero_Out_Detail_Discount_Amounts <> 'FALSE')
            SET @Zero_Out_Detail_Discount_Amounts = 'NO'
        IF @Zero_Out_Detail_Discount_Amounts = 'FALSE'
            SET @Zero_Out_Detail_Discount_Amounts = 'NO'
        IF @Zero_Out_Detail_Discount_Amounts = 'TRUE'
            SET @Zero_Out_Detail_Discount_Amounts = 'YES'
        END
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': Zero Out Detail Discount Amounts = ''' + @Zero_Out_Detail_Discount_Amounts + ''''
    -- 
    -- Get the "Bypass Tax Calculation Code" config table entry.
    --
    SET @Bypass_Tax_Calculation_Code = ''
    IF EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'im_config')
        BEGIN
        SELECT @Bypass_Tax_Calculation_Code = UPPER([Text Value])
                FROM [im_config] 
                WHERE UPPER([Item Name]) = 'BYPASS TAX CALCULATION CODE'
        IF @@ROWCOUNT = 0
                OR @Bypass_Tax_Calculation_Code IS NULL
            SET @Bypass_Tax_Calculation_Code = ''
        END
    -- 
    -- Get the "Bypass Tax Calculations" config table entry.
    --
    SET @Bypass_All_Tax_Calculations = 'NO'
    IF EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'im_config')
        BEGIN
        SELECT @Bypass_All_Tax_Calculations = UPPER([Text Value])
                FROM [im_config] 
                WHERE UPPER([Item Name]) = 'BYPASS ALL TAX CALCULATIONS'
        IF @@ROWCOUNT = 0
                OR @Bypass_All_Tax_Calculations IS NULL
                OR (@Bypass_All_Tax_Calculations <> 'NO' AND @Bypass_All_Tax_Calculations <> 'YES' AND @Bypass_All_Tax_Calculations <> 'TRUE' AND @Bypass_All_Tax_Calculations <> 'FALSE')
            SET @Bypass_All_Tax_Calculations = 'NO'
        IF @Bypass_All_Tax_Calculations = 'FALSE'
            SET @Bypass_All_Tax_Calculations = 'NO'
        IF @Bypass_All_Tax_Calculations = 'TRUE'
            SET @Bypass_All_Tax_Calculations = 'YES'
        END
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': Bypass All Tax Calculations = ''' + @Bypass_All_Tax_Calculations + ''''
    --
    -- "Bypass All Tax Calculations" overrides "Bypass Tax Calculation Code".
    --    
    IF @Bypass_All_Tax_Calculations = 'YES'
        SET @Bypass_Tax_Calculation_Code = ''    
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': Bypass Tax Calculation Code = ''' + @Bypass_Tax_Calculation_Code + ''''
    --  
    -- Populate #TxLineInput. 
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

    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATETABLE + ' #TxLineInput 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END   
    INSERT INTO #TxLineInput (control_number, reference_number, tax_code,
                              quantity,       extended_price,   discount_amount,
                              tax_type,       currency_code)
            SELECT hdr.trx_ctrl_num, cdt.sequence_id,  cdt.tax_code,
                   cdt.qty_received, cdt.amt_extended, cdt.amt_discount,
                   0,                hdr.nat_cur_code
                    FROM #apinpcdt cdt, #apinpchg hdr
                    WHERE cdt.trx_ctrl_num = hdr.trx_ctrl_num
                    AND cdt.trx_type = 4091
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #TxLineInput 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
    INSERT INTO #TxLineInput (control_number, reference_number, tax_code,
                              quantity,       extended_price,   discount_amount,
                              tax_type,       currency_code)
            SELECT hdr.trx_ctrl_num,    cdt.sequence_id,  cdt.tax_code,
                   cdt.qty_returned,    cdt.amt_extended, cdt.amt_discount,
                   0,                   hdr.nat_cur_code
                    FROM #apinpcdt cdt, #apinpchg hdr
                    WHERE cdt.trx_ctrl_num = hdr.trx_ctrl_num
                            AND cdt.trx_type = 4092
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #TxLineInput 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
    INSERT INTO #TxLineInput (control_number, reference_number, tax_code,
                              quantity,       extended_price,   discount_amount,
                              tax_type,       currency_code)
            SELECT trx_ctrl_num, 0,           tax_code,
                   1,            amt_freight, 0,
                   1,            nat_cur_code
                    FROM #apinpchg hdr
                    WHERE ((amt_freight) > (0.0) + 0.0000001)
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #TxLineInput 3' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
    IF (@debug_level >= 3)
        BEGIN
        SELECT '(3): ' + @Routine_Name + ': #TxLineInput:'
        SELECT * 
                FROM #TxLineInput
        END
    
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

    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATETABLE + ' #TxInfo 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
    
CREATE TABLE #TxLineTax
(
	control_number		varchar(16),
	reference_number	int,
	tax_amount			float,
	tax_included_flag	smallint
)

    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATETABLE + ' #TxLineTax 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
    
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

    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATETABLE + ' #TxTLD 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
    --
    -- Call the tax calculation routine.  Note that it does not return any status. 
    -- If all tax calculations are bypassed, note that the purpose of TXCalculateTax_SP
    -- then becomes simply to populate #TxInfo with items other than tax.
    --
    EXEC TXCalculateTax_SP
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_EXEC + ' TXCalculateTax_sp' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END





	INSERT INTO #apinptaxdtl
	( 	trx_ctrl_num,	sequence_id,	trx_type,
		tax_sequence_id,	detail_sequence_id,	tax_type_code,	
		amt_taxable,	amt_gross,	amt_tax,	amt_final_tax,	
		recoverable_flag,	account_code )
	
	SELECT t.control_number,  0,	b.trx_type,
		t.reference_number, 	t.reference_number,	t.tax_type_code,
		i.extended_price- i.discount_amount, 	 i.extended_price, 	t.amt_taxable, 	t.amt_taxable, 
		ISNULL(recoverable_flag,0), ''                                      
	FROM #txdetail t
		INNER JOIN #TxLineInput i
			ON t.control_number = i.control_number
			AND t.reference_number = i.reference_number
		INNER JOIN #apinpchg b
			ON t.control_number = b.trx_ctrl_num  
		INNER JOIN artxtype ty
			ON ty.tax_type_code = t.tax_type_code
	WHERE ty.cents_code_flag = 0
		AND (ty.base_range_flag= 0 OR ( ty.base_range_flag= 1 AND ty.base_range_type <> 2 ) )
		AND  (ty.tax_range_flag =0  OR ( ty.tax_range_flag= 1 AND ty.tax_range_type <> 1 ))
	ORDER BY t.reference_number, t.tax_type_code


	CREATE CLUSTERED  INDEX apinptaxdtl_ind_0 
	ON  #apinptaxdtl  (trx_ctrl_num, trx_type, detail_sequence_id)



	CREATE CLUSTERED  INDEX apinpcdt_tax_ind_0 
	ON  #apinpcdt  (trx_ctrl_num, trx_type, sequence_id)

	SELECT @sequence_id = 0, @detail_sequence_id=0, @trx_ctrl_num =''
	


	UPDATE #apinptaxdtl
	SET account_code = d.gl_exp_acct,
	    sequence_id = @sequence_id,
	    @sequence_id = CASE WHEN (detail_sequence_id <> @detail_sequence_id   OR t.trx_ctrl_num <> @trx_ctrl_num ) THEN 1 ELSE  @sequence_id +1 END,
	    @detail_sequence_id = detail_sequence_id,
	    @trx_ctrl_num = t.trx_ctrl_num
	FROM #apinptaxdtl t, #apinpcdt d
	WHERE t.trx_ctrl_num =d.trx_ctrl_num
	  AND t.trx_type = d.trx_type
	  AND t.detail_sequence_id  = d.sequence_id
    

    DROP TABLE #txdetail
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DROPTABLE + ' #txdetail 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
    DROP TABLE #txinfo_id
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DROPTABLE + ' #txinfo_id 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
    DROP TABLE #TXInfo_min_id 
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DROPTABLE + ' #TXInfo_min_id 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
    DROP TABLE #TxTLD
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DROPTABLE + ' #TxTLD 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
    DROP TABLE #TxLineInput
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DROPTABLE + ' #TxLineInput 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
    IF (@debug_level >= 3)  
        BEGIN
        SELECT '(3): ' + @Routine_Name + ': After TXCalculateTax_SP: #TxInfo:'
        SELECT * 
                FROM #TxInfo
        SELECT '(3): ' + @Routine_Name + ': After TXCalculateTax_SP: #TxLineTax:'
        SELECT * 
                FROM #TxLineTax
        END
    --
    -- Restore the calc_tax value from the staging table as appropriate.
    --
  



    IF @Bypass_All_Tax_Calculations = 'YES'
        BEGIN
	



























	



                UPDATE [#TxInfo]
				   SET [amt_tax] = a.[SUM of calc_tax],			
                       [amt_final_tax] = a.[SUM of calc_tax]
                FROM   (SELECT d.[trx_ctrl_num], t.[tax_type_code], SUM(d.[calc_tax]) AS 'SUM of calc_tax' 
						FROM [#apinpcdt] d INNER JOIN aptaxdet t ON d.tax_code = t.tax_code
						GROUP BY d.[trx_ctrl_num], t.[tax_type_code]) a
                 INNER JOIN [#TxInfo] b
                    ON a.[trx_ctrl_num] = b.[control_number] AND a.[tax_type_code] = b.[tax_type_code]
                --WHERE  b.[control_number] = @Bypass_Tax_control_number
                --  AND  b.[sequence_id] = @Bypass_Tax_sequence_id
                SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #TxInfo 1B' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END
	














        IF @debug_level >= 3  
            BEGIN
            SELECT '(3): ' + @Routine_Name + ': After unconditionally putting calc_tax value back in #TxInfo:'
            SELECT * 
                    FROM [#TxInfo]
            END
        END
    ELSE
        BEGIN
		



		UPDATE [#TxInfo]
           SET [amt_tax] = a.[SUM of calc_tax],
			   [amt_final_tax] = a.[SUM of calc_tax]
		FROM   (SELECT d.[trx_ctrl_num], t.[tax_type_code], SUM(d.[calc_tax]) AS 'SUM of calc_tax' 
				FROM   [#apinpcdt] d
				 INNER JOIN aptaxdet t ON d.tax_code = t.tax_code
				WHERE d.[tax_code] = @Bypass_Tax_Calculation_Code
				GROUP BY d.[trx_ctrl_num], t.[tax_type_code]) a
		 INNER JOIN [#TxInfo] b
            ON a.[trx_ctrl_num] = b.[control_number] AND a.[tax_type_code] = b.[tax_type_code]
        --WHERE  a.[tax_code] = @Bypass_Tax_Calculation_Code
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #TxInfo 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
        IF (@debug_level >= 3)  
            BEGIN
            SELECT '(3): ' + @Routine_Name + ': After conditionally putting calc_tax value back in #TxInfo:'
            SELECT * 
                    FROM [#TxInfo]
            END
        END
	  
    --
    -- Update temporary unposted tables.
    --
    IF NOT @Bypass_All_Tax_Calculations = 'YES'
        BEGIN
        UPDATE [#apinpcdt]
                SET [calc_tax] = [#TxLineTax].[tax_amount]
                FROM [#TxLineTax]
                INNER JOIN [#apinpcdt]
                        ON [#apinpcdt].[trx_ctrl_num] = [#TxLineTax].[control_number]
                                AND [#apinpcdt].[sequence_id] = [#TxLineTax].[reference_number]
                WHERE NOT [#apinpcdt].[tax_code] = @Bypass_Tax_Calculation_Code
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #apinpcdt 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
        END
    DROP TABLE #TxLineTax
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DROPTABLE + ' #TxLineTax 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
    IF (@debug_level >= 3)  
        BEGIN
        SELECT '(3): ' + @Routine_Name + ': After conditionally updating #apinpcdt.calc_tax:'
        SELECT * 
                FROM [#apinpcdt]
        END      
    INSERT #apinptax (trx_ctrl_num,  trx_type,    sequence_id,
                      tax_type_code, amt_taxable, amt_gross,
                      amt_tax,       amt_final_tax)
            SELECT a.control_number, b.trx_type,     a.sequence_id,                            
                   a.tax_type_code,  a.amt_taxable,  a.amt_gross,
                   a.amt_tax,        a.amt_final_tax
                    FROM #TxInfo a, #apinpchg b
                    WHERE a.control_number = b.trx_ctrl_num
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #apinptax 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
    IF (@debug_level >= 3)  
        BEGIN
        SELECT '(3): ' + @Routine_Name + ': #apinptax:'
        SELECT * FROM #apinptax
        END
	
	SELECT     i.[control_number],
	    ROUND(SUM(ISNULL(i.[amt_final_tax],0)), @curr_precision) [amt_tax],
	    ROUND(SUM(ISNULL(i.[tax_included_flag],0) * ISNULL(i.[amt_final_tax],0) ),@curr_precision) [amt_tax_included]
	  INTO     [#inptax]
	  FROM     [#TxInfo] i
		INNER JOIN [aptxtype] t
			ON i.tax_type_code = t.tax_type_code
	   WHERE ISNULL(t.recoverable_flag,0) =1
	 GROUP BY i.[control_number]
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' #inptax 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
    DROP TABLE #TxInfo
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DROPTABLE + ' #TxInfo 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END    

	


	SELECT trx_ctrl_num, trx_type,detail_sequence_id, SUM (amt_final_tax) amt_final_tax
	INTO #aptaxdet_sum
	FROM #apinptaxdtl
	WHERE recoverable_flag =1
	GROUP BY trx_ctrl_num, trx_type,detail_sequence_id
	
	UPDATE [#apinpcdt]
	SET amt_tax_det = t.amt_final_tax
	FROM [#apinpcdt] d, [#aptaxdet_sum] t
	WHERE t.trx_ctrl_num =d.trx_ctrl_num
		  AND t.trx_type = d.trx_type
		  AND t.detail_sequence_id  = d.sequence_id
	
	
	


	SELECT trx_ctrl_num, trx_type,detail_sequence_id, SUM (amt_final_tax) amt_final_tax
	INTO #apnrectaxdet_sum
	FROM #apinptaxdtl
	WHERE recoverable_flag =0 
	GROUP BY trx_ctrl_num, trx_type,detail_sequence_id
	
	UPDATE [#apinpcdt]
	SET [amt_nonrecoverable_tax] = t.amt_final_tax
	FROM [#apinpcdt] d, [#apnrectaxdet_sum] t
	WHERE t.trx_ctrl_num =d.trx_ctrl_num
		  AND t.trx_type = d.trx_type
		  AND t.detail_sequence_id  = d.sequence_id
	
	DROP TABLE [#aptaxdet_sum]
	DROP TABLE [#apnrectaxdet_sum]
   
    
	CREATE TABLE #cdt
	(
		trx_ctrl_num	varchar(16),		
		sequence_id	int,
		price		float,
		discount	float,
		cost		float,
		weight		float,
                amt_freight FLOAT
	)

    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_CREATETABLE + ' #cdt 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
    INSERT #cdt
            SELECT trx_ctrl_num, 
                   MAX(sequence_id),
                   SUM(amt_extended+amt_nonrecoverable_tax) ,        
                   SUM(amt_discount),
                   SUM(unit_price),
                   SUM(amt_misc),
                   SUM(amt_freight)
                    FROM #apinpcdt
                    GROUP BY trx_ctrl_num
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_INSERT + ' #cdt 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END     
    UPDATE #apinpchg
            SET next_serial_id = cdt.sequence_id,
                amt_discount = cdt.discount,
                amt_gross = ROUND((cdt.price - tax.amt_tax_included), @curr_precision),
                amt_net = ROUND((cdt.price - tax.amt_tax_included + tax.amt_tax - cdt.discount + cdt.amt_freight + cdt.weight), @curr_precision), -- cdt.weight is #apinpcdt.amt_misc
                amt_tax_included = tax.amt_tax_included,
                amt_paid = 0.0,
                amt_due = ROUND((cdt.price - tax.amt_tax_included + tax.amt_tax - cdt.discount + cdt.amt_freight + cdt.weight), @curr_precision), -- cdt.weight is #apinpcdt.amt_misc
                amt_tax = tax.amt_tax
            FROM #cdt cdt, #inptax tax
            WHERE #apinpchg.trx_ctrl_num = cdt.trx_ctrl_num
                    AND #apinpchg.trx_ctrl_num = tax.control_number
                    AND trx_type = 4091
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #apinpchg 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
    UPDATE #apinpchg
            SET next_serial_id = cdt.sequence_id,
                amt_discount = cdt.discount,
                amt_gross = ROUND((cdt.price - tax.amt_tax_included), @curr_precision),
                amt_net = ROUND((cdt.price - tax.amt_tax_included + tax.amt_tax - cdt.discount + cdt.amt_freight + cdt.weight), @curr_precision), -- cdt.weight is #apinpcdt.amt_misc
                amt_tax_included = tax.amt_tax_included,
                amt_paid = 0.0,
                amt_due = ROUND((cdt.price - tax.amt_tax_included + tax.amt_tax - cdt.discount + cdt.amt_freight + cdt.weight), @curr_precision), -- cdt.weight is #apinpcdt.amt_misc
                amt_tax = tax.amt_tax
            FROM #cdt cdt, #inptax tax
            WHERE #apinpchg.trx_ctrl_num = cdt.trx_ctrl_num
                    AND #apinpchg.trx_ctrl_num = tax.control_number
                    AND trx_type = 4092
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #apinpchg 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
    IF @Zero_Out_Detail_Discount_Amounts = 'YES'
        BEGIN
        UPDATE [#apinpcdt]
                SET [amt_discount] = 0
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #apinpcdt 2' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END 
        END
    --
    IF @debug_level >= 3                    
        BEGIN
        SELECT '(3): ' + @Routine_Name + ': #apinpchg (trx_ctrl_num, amt_net, amt_due, amt_tax, amt_gross):'
        SELECT trx_ctrl_num, amt_net, amt_due, amt_tax, amt_gross
                FROM #apinpchg
        SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_SELECT + ' #apinpchg 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
        END
    DROP TABLE #cdt
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DROPTABLE + ' #cdt 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
    DROP TABLE #inptax
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_DROPTABLE + ' #inptax 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
    -- 
    -- Update amt_due in the #apinpage table
    --
    UPDATE #apinpage
            SET amt_due = amt_net
            FROM #apinpchg a, #apinpage  b
            WHERE a.trx_ctrl_num = b.trx_ctrl_num
                    AND a.trx_type = 4091
    SELECT @Error_Code = @@ERROR, @Row_Count = @@ROWCOUNT IF NOT @Error_Code = 0 AND NOT @Error_Code = 8153 BEGIN IF @ROLLBACK_On_Error = 'YES' BEGIN ROLLBACK TRANSACTION SET @ROLLBACK_On_Error = 'NO' END SET @CSS_Intermediate_String = @External_String_UPDATE + ' #apinpage 1' EXEC im_log_sql_error_sp @ILSE_Error_Code = @Error_Code, @ILSE_String = @CSS_Intermediate_String, @ILSE_Procedure_Name = @Routine_Name, @ILSE_Log_Activity = 'YES', @im_log_sql_error_sp_User_ID = @userid IF @debug_level >= 3 BEGIN SELECT '(3): ERROR: ' + @CSS_Intermediate_String END GOTO Error_Return END       
    IF @debug_level >= 3  
        BEGIN
        SELECT '(3): ' + @Routine_Name + ': #apinptax:'
        SELECT * FROM #apinptax
        END
    IF @debug_level >= 3
        BEGIN
        SELECT '(1): ' + @Routine_Name + ': Prior to exit: #apinpchg:'
        SELECT * FROM #apinpchg
        SELECT '(1): ' + @Routine_Name + ': Prior to exit: #apinpcdt:'
        SELECT * FROM #apinpcdt
        END
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': Exit.'
    RETURN 0
Error_Return:
    IF @Bypass_Tax_Cursor_Opened = 'YES'
        CLOSE Bypass_Tax_Cursor
    IF @Bypass_Tax_Cursor_Allocated = 'YES'
        DEALLOCATE Bypass_Tax_Cursor
    IF @debug_level >= 3
        SELECT '(3): ' + @Routine_Name + ': Exit (ERROR).'
    RETURN -1    
GO
GRANT EXECUTE ON  [dbo].[imaptax_sp] TO [public]
GO
