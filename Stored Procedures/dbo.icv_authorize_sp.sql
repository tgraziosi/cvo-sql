SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 22/12/2016 - Add error capture for missing credit card info
CREATE PROCEDURE [dbo].[icv_authorize_sp]	@IAS_Option int, @IAS_String varchar(255) = '', @IAS_Name varchar(30) = '',  
									@IAS_TrxCtrlNum varchar(16) = '', @IAS_TrxType smallint = 0,@IAS_Account varchar(300) = '',   
									@IAS_Expiration varchar(30) = '', @IAS_Amount float = 0.00, @IAS_Preview smallint = 1, @IAS_CCATrxType CHAR(2) = 'C1', 
									@customer_code VARCHAR(255) = '', @nat_cur_code varchar(8) = '', @csc varchar(5) = ''   
AS  
BEGIN
	DECLARE @result    INTEGER  
	DECLARE @icvbatch    INTEGER  
	DECLARE @reqpath    VARCHAR(255)  
	DECLARE @xTrxCtrlNum    CHAR(255)  
	DECLARE @xAmt     CHAR(255)  
	DECLARE @xName     CHAR(255)  
	DECLARE @xAccount    CHAR(255)  
	DECLARE @xValid    CHAR(255)  
	DECLARE @xMonth    CHAR(255)  
	DECLARE @xAuthorization   CHAR(255)  
	DECLARE @xYear     CHAR(255)  
	DECLARE @xTrxType    CHAR(255)  
	DECLARE @ret    INT  
	DECLARE @response   CHAR(60)  
	DECLARE @iMonth    INT  
	DECLARE @iYear    INT  
	DECLARE @trx_type   CHAR(2)  
	DECLARE @arinpchg_rowcount  INT  
	DECLARE @arinppyt_rowcount  INT  
	DECLARE @arinptmp_rowcount  INT  
	DECLARE @arinptmp2_rowcount  INT  
	DECLARE @batch_size_limit  INT  
	DECLARE @maybe_more   INT  
	DECLARE @spid    INT  

	DECLARE @Authorization_Code   varchar(255)  
	DECLARE @Bailout    int  
	DECLARE @C_amt_payment    varchar(255)   
	DECLARE @C_float_amt_payment   float   
	DECLARE @C_prompt1_inp    varchar(255)  
	DECLARE @C_prompt2_inp    varchar(255)  
	DECLARE @C_prompt3_inp    varchar(255)  
	DECLARE @C_prompt4_inp    varchar(255)  
	DECLARE @C_trx_ctrl_num   varchar(255)   
	DECLARE @Error_Code    int  
	DECLARE @Error_Msg   varchar(255)  
	DECLARE @appid    int  
	DECLARE @Field     varchar(255)  
	DECLARE @Field_Number    int  
	DECLARE @HRESULT    int  
	DECLARE @I     int  
	DECLARE @I1     int  
	DECLARE @ICV_Config_Table_Exists  char(5)  
	DECLARE @ICV_Log_Exists   char(5)  
	DECLARE @ICV_Request_Timeout   int  
	DECLARE @ICV_String_Table_Exists  char(5)  
	DECLARE @Log_Activity    char(10)  
	DECLARE @Month     char(2)  
	DECLARE @Platinum_Date    int  
	DECLARE @Remaining_Length   int  
	DECLARE @Request_String   varchar(255)  
	DECLARE @Return    int  
	DECLARE @Return_Additional_Information  varchar(255)  
	DECLARE @String    varchar(255)  
	DECLARE @String_Remaining   int  
	DECLARE @Successful_Authorization  char(1)  
	DECLARE @Substring_1    varchar(255)  
	DECLARE @Test_Character   char(1)  
	DECLARE @Test_int    int  
	DECLARE @Text_HRESULT    char(10)  
	DECLARE @Text_String    varchar(255)  
	DECLARE @Text_String_2    varchar(255)  
	DECLARE @Text_String_3    varchar(255)  
	DECLARE @Time_Remaining   int  
	DECLARE @Year     char(4)  
	DECLARE @trx_ctrl_num    varchar(16)  
	DECLARE @prompt1    varchar(30)  
	DECLARE @prompt2    varchar(30)  
	DECLARE @prompt3    varchar(30)  
	DECLARE @amt_payment    float  
	DECLARE @buf     varchar(255)  
	DECLARE @rowcount    int  
	DECLARE @delete_rowcount  int  
	DECLARE @user_id   int  
	DECLARE @user_name   varchar(30)  
	DECLARE @company_name   varchar(30)  
	DECLARE @trx_code   char(2)  
	DECLARE @amt     char(255)  
	DECLARE @payment_code   char(8)  
	-- DECLARE @customer_code   char(8)  
	DECLARE @batch_counter   INT  

	DECLARE @max_users   INT  
	DECLARE @ICV_filename   CHAR(20)  

	DECLARE @processor   INT  
	DECLARE @processor_name   CHAR(255)  
	DECLARE @IAS_AccountDecoded  VARCHAR(30)  
   
	-- v1.0 Start
	IF NOT EXISTS(SELECT * FROM CVO_Control..ccacryptaccts WHERE trx_ctrl_num = @IAS_TrxCtrlNum AND trx_type = @IAS_TrxType)
	BEGIN
		RAISERROR 15000 'Credit card data missing, Resave or void and re-enter!'
	END
	-- v1.0 End

	DECLARE @dateValid   INT  
  
	SET NOCOUNT ON  
  
	SELECT @Return_Additional_Information = '', @appid = 28000, @user_id = 0, @user_name = '', @company_name = '', @HRESULT = 0, @Error_Code = 0, @maybe_more = 0, @spid = @@spid, @batch_counter = 0, @icvbatch = 0  
  
	SELECT @Log_Activity = 'NO'  
	SELECT @ICV_Config_Table_Exists = 'NO'  
	IF EXISTS (SELECT name FROM sysobjects WHERE name = 'icv_config')  
	BEGIN  
		SELECT @ICV_Config_Table_Exists = 'YES'  
	END  
  
	SELECT @ICV_Log_Exists = 'NO'  
	IF EXISTS (SELECT name FROM sysobjects WHERE name = 'icv_log')  
	BEGIN  
		SELECT @ICV_Log_Exists = 'YES'  
	END  
  
	SELECT @ICV_String_Table_Exists = 'NO'  
	IF EXISTS (SELECT name FROM sysobjects WHERE name = 'icv_strings')  
	BEGIN  
		SELECT @ICV_String_Table_Exists = 'YES'  
	END  
  
	IF @ICV_Log_Exists = 'YES'  
	BEGIN  
		EXEC icv_Log_sp NULL, 'INIT'  
	END  
  
	IF @IAS_Option <> 1 AND   
		@IAS_Option <> 2 AND   
		@IAS_Option <> 3 AND   
		@IAS_Option <> 4 AND   
		@IAS_Option <> 5 AND   
		@IAS_Option <> -1  
	BEGIN  
		SELECT @Return_Additional_Information = 'Invalid option' + RTRIM(LTRIM(CONVERT(CHAR,@IAS_Option)))  
		SELECT @Error_Code = -1001  
		GOTO IAS_Return  
	END  
  
	IF @ICV_Config_Table_Exists = 'YES'  
	BEGIN  
		SELECT @Log_Activity = 'NO'  
		SELECT @Text_String = UPPER(configuration_text_value)   
		FROM icv_config WHERE UPPER(configuration_item_name) = 'LOG ACTIVITY'  
		IF @@ROWCOUNT = 1  
		BEGIN  
			IF @Text_String = 'YES' OR @Text_String = 'TRUE'  
			BEGIN  
				SELECT @Log_Activity = 'YES'  
			END   
		END  
  
		SELECT @ICV_Request_Timeout = configuration_int_value   
		FROM icv_config   
		WHERE UPPER(configuration_item_name) = 'IC VERIFY REQUEST TIMEOUT'  
  
		IF @ICV_Request_Timeout < 0 OR @@ROWCOUNT = 0  
		BEGIN  
			SELECT @ICV_Request_Timeout = 300  
			EXEC icv_Get_External_String_sp 'IC Verify Request Timeout is either not in the configuration table or is less than 0, therefore it has defaulted to 300', @Text_String OUT  
			EXEC icv_Log_sp @Text_String, @Log_Activity  
		END  
  
		SELECT @batch_size_limit = configuration_int_value,   
			@buf = UPPER(configuration_text_value)  
		FROM icv_config   
		WHERE UPPER(configuration_item_name) = 'BATCH SIZE LIMIT'  
		IF RTRIM(LTRIM(@buf)) <> 'YES' OR ISNULL(DATALENGTH(RTRIM(LTRIM(@buf))),0) = 0 OR @@ROWCOUNT = 0  
		BEGIN  
			SELECT @batch_size_limit = 0  
			EXEC icv_Get_External_String_sp 'Batch size limit is either not in the configuration table or has an invalid value, therefore batch size limiting will be turned off', @Text_String OUT  
			EXEC icv_Log_sp @Text_String, @Log_Activity  
		END  
  
		SELECT @max_users = ISNULL(CONVERT(INT,value_str),3)   
		FROM config   
		WHERE UPPER(flag) = 'ICV_MAX_USERS'  
		IF @max_users < 3 OR @max_users > 999 OR @@ROWCOUNT = 0  
		BEGIN  
			SELECT @max_users = 3  
			EXEC icv_Get_External_String_sp 'Max users defaulted to 3', @Text_String OUT  
			EXEC icv_Log_sp @Text_String, @Log_Activity  
		END  
  
		SELECT @buf = CONVERT(CHAR(3),@max_users - 1)  
		SELECT @ICV_filename = '\ICVER' + REPLICATE('0', 3-DATALENGTH(RTRIM(LTRIM(@buf)))) + RTRIM(LTRIM(@buf)) + '.REQ'  
		EXEC icv_Get_External_String_sp 'Filename for batch processing set to ', @Text_String OUT  
		SELECT @Text_String = @Text_String + @ICV_filename  
		EXEC icv_Log_sp @Text_String, @Log_Activity  
  
		SELECT @processor = configuration_int_value,  
			 @processor_name = configuration_text_value  
		FROM icv_config  
		WHERE UPPER(configuration_item_name) = 'PROCESSOR INTERFACE'  
		IF @@ROWCOUNT <> 1 OR @processor < 0 OR @processor > 2  
		BEGIN  
			SELECT @Return_Additional_Information = 'A processor interface has not been defined in the config table'  
			SELECT @Error_Code = -1009  
			EXEC icv_Log_sp @Return_Additional_Information, @Log_Activity  
			GOTO IAS_Return  
		END  
	END  
	ELSE  
	BEGIN  
		SELECT @Return_Additional_Information = 'Config table does not exist'  
		SELECT @Error_Code = -1009  
		GOTO IAS_Return  
	END  
  
	SELECT @buf = 'Enter icv_authorize_sp ' + RTRIM(LTRIM(CONVERT(CHAR,@IAS_Option))) + ', ' + RTRIM(LTRIM(@IAS_String)) + ', ' + RTRIM(LTRIM(@IAS_Name)) + ', ' + RTRIM(LTRIM(@IAS_TrxCtrlNum)) + ', ' + RTRIM(LTRIM(@IAS_Account)) + ', '  
		+ RTRIM(LTRIM(@IAS_Expiration)) + ', ' + RTRIM(LTRIM(CONVERT(CHAR, @IAS_Amount))) + ', ' + RTRIM(LTRIM(CONVERT(CHAR, @IAS_Preview)))  
	EXEC icv_Log_sp @buf, @Log_Activity  
  
	SELECT @buf = 'TRANCOUNT: ' + RTRIM(LTRIM(STR(@@TRANCOUNT))) + ' SPID: ' + RTRIM(LTRIM(STR(@spid)))  
	EXEC icv_Log_sp @buf, @Log_Activity  
  
	SELECT @buf = 'Processor: ' + RTRIM(LTRIM(@processor_name)) + ' (' + RTRIM(LTRIM(STR(@processor))) + ')'  
	EXEC icv_Log_sp @buf, @Log_Activity  
  
  
	SELECT @user_id = user_id,   
        @user_name = suser_name()  
	FROM ewusers_vw  
	WHERE user_name = suser_name()  
  
	SELECT @company_name = company_name  
	FROM arco  
  
	DELETE icv_temp  
	WHERE spid = @spid  
  
	IF @IAS_Option = 5  
	BEGIN  
		IF (ISNULL(DATALENGTH(RTRIM(LTRIM(@IAS_Name))),0) = 0)  
		BEGIN  
			SELECT @IAS_Name = 'CCA'  
		END  
  
		INSERT icv_temp (spid, trx_ctrl_num, prompt1_inp, prompt2_inp, prompt3_inp, amt_payment, trx_code, new_ctrl_num) VALUES  
              (@spid, @IAS_TrxCtrlNum, @IAS_Name, @IAS_Account, @IAS_Expiration, @IAS_Amount, @IAS_CCATrxType, '')  
  
		EXEC @result = icv_parse_expiration @IAS_Expiration, @iMonth OUTPUT, @iYear OUTPUT, @dateValid OUTPUT  
		IF @dateValid = 0  
		BEGIN  
			EXEC icv_Get_External_String_sp 'Invalid expiration date: ', @Text_String OUT  
			SELECT @Text_String = @Text_String + @IAS_Expiration  
			EXEC icv_Log_sp @Text_String, @Log_Activity  
			SELECT @Return_Additional_Information = @Text_String  
			SELECT @C_prompt4_inp = 'Invalid expiration'  
			SELECT @Error_Code = -1999  
			GOTO IAS_Return  
		END  
    
		SELECT @Month = CONVERT(CHAR(2), @iMonth)  
		SELECT @Year = CONVERT(CHAR(4), @iYear)  
		SELECT @xAmt = CONVERT(CHAR,@IAS_Amount)  
  
		SELECT @Text_String = RTRIM(LTRIM(@IAS_TrxType)) + ', ' + '************' + RIGHT(LTRIM(RTRIM(@IAS_Account)), 4) + ', ' + @Month + ', ' + @Year + ', ' + @xAmt  
		EXEC icv_Log_sp @Text_String, @Log_Activity  
		EXEC @ret = icv_fs_trans @IAS_CCATrxType, @IAS_Account, @Month, @Year, @IAS_Amount, @response OUT, 0, 0, @IAS_Name, @IAS_TrxCtrlNum, @customer_code, @nat_cur_code, @IAS_TrxType, @csc   
		EXEC icv_Log_sp @response, @Log_Activity  
  
		IF @ret <> 0  
		BEGIN  
			EXEC icv_Get_External_String_sp 'Invalid return from icv_fs_trans: ', @Text_String OUT  
			SELECT @Text_String = @Text_String + CONVERT(CHAR,@ret)  
			EXEC icv_Log_sp @Text_String, @Log_Activity  
			SELECT @Return_Additional_Information = @Text_String  
			SELECT @C_prompt4_inp = 'Invalid response'  
		--Rev 1.1 Cyanez SELECT @Error_Code = -1999  
		-- To get error code on AR visual forms  
			SELECT @Error_Code = @ret  
			GOTO IAS_Return  
		END  
  
        SELECT @buf = SUBSTRING(@response, 2, 1)  
		SELECT @I = CHARINDEX( CHAR(34), SUBSTRING( @response, 2, 255 ) )  
		IF @I = 0  
		BEGIN  
			EXEC icv_Get_External_String_sp 'Invalid response: ', @Text_String OUT  
			SELECT @Return_Additional_Information = @Text_String  
			EXEC icv_Log_sp @Text_String, @Log_Activity  
			SELECT @C_prompt4_inp = 'Badly formed response'  
			SELECT @Error_Code = -1999  
			GOTO IAS_Return  
		END  
   
		SELECT @Return_Additional_Information = @buf  
        IF @buf = 'Y'  
		BEGIN  
			SELECT @Authorization_Code = SUBSTRING(@response, 3, @I - 2)  
			IF @IAS_CCATrxType = 'C4'  
				SELECT @Authorization_Code = 'BOOKED'  
		END  
        ELSE  
		BEGIN  
			SELECT @Authorization_Code = SUBSTRING(@response, 4, @I - 3)  
		END  
  
    
		SELECT @C_prompt4_inp = @Authorization_Code   
		--Start Rev 1.1 Cyanez Added To get two codes needed to refund a transaction.  
		IF CHARINDEX(':', @C_prompt4_inp)=0   
			SELECT @C_prompt4_inp=@C_prompt4_inp+':'+ SUBSTRING(@response, LEN(@C_prompt4_inp)+4,LEN (@response)-1)  
		--Ends Rev 1.1 Cyanez  
   
		SELECT @iMonth = CONVERT(INT,@Month), @iYear = CONVERT(INT,@Year)  
		EXEC icv_history 1, '', @IAS_TrxCtrlNum, @IAS_Name, @IAS_Account, @iMonth, @iYear, @IAS_Amount, @IAS_CCATrxType, @Authorization_Code  
		EXEC icv_history 2, @response  
		GOTO IAS_Return  
	END  
  
	SET ROWCOUNT @batch_size_limit  
  
	INSERT icv_temp (spid, trx_ctrl_num, prompt1_inp, prompt2_inp, prompt3_inp, amt_payment, trx_code, new_ctrl_num)  
	SELECT @spid, a.trx_ctrl_num, a.prompt1_inp, a.prompt2_inp, a.prompt3_inp, a.amt_payment, 'C1', ''  
    FROM arinptmp AS a, icv_cctype AS b, arinpchg AS c  
    WHERE a.payment_code = b.payment_code  
    AND ISNULL(DATALENGTH(RTRIM(LTRIM(a.prompt4_inp))),0) = 0  
    AND a.trx_ctrl_num = c.trx_ctrl_num  
    AND c.hold_flag = 0  
	UNION   
	SELECT @spid, a.trx_ctrl_num, a.prompt1_inp, a.prompt2_inp, a.prompt3_inp, a.amt_payment, 'C1', ''  
    FROM arinppyt AS a, icv_cctype AS b  
    WHERE a.payment_code = b.payment_code  
    AND ISNULL(DATALENGTH(RTRIM(LTRIM(a.prompt4_inp))),0) = 0  
    AND a.hold_flag = 0  
  
	SET ROWCOUNT 0  

	DELETE icv_temp   
	FROM icv_temp a, artrx b  
	WHERE a.spid = @spid  
    AND (a.new_ctrl_num = b.doc_ctrl_num  
    AND b.trx_type = 2032)  
  
	SELECT @rowcount = @@rowcount  
	SELECT @Text_String = RTRIM(LTRIM(STR(@rowcount))) + ' payments were skipped because the were related to on-account credit memos.'  
	EXEC icv_Log_sp @Text_String, @Log_Activity  
  
	SELECT @delete_rowcount = 0  
	DECLARE c1 INSENSITIVE CURSOR FOR   
	SELECT trx_ctrl_num, prompt1_inp, prompt2_inp, prompt3_inp, amt_payment FROM icv_temp WHERE spid = @spid  
  
	OPEN c1  
	FETCH NEXT FROM c1 INTO @trx_ctrl_num, @prompt1, @prompt2, @prompt3, @amt_payment  
       
	WHILE (@@FETCH_STATUS <> -1)  
	BEGIN  
		IF @@FETCH_STATUS <> -2  
		BEGIN  
			EXEC @result = icv_parse_expiration @prompt3, @Month OUTPUT, @Year OUTPUT, @dateValid OUTPUT  
  
			IF (ISNULL(DATALENGTH(RTRIM(LTRIM(@prompt1))),0) = 0 OR  
				ISNULL(DATALENGTH(RTRIM(LTRIM(@prompt2))),0) = 0 OR  
				ISNULL(@amt_payment,0.0) <= 0.0 OR @dateValid = 0)  
			BEGIN  
				DELETE icv_temp  
				WHERE CURRENT OF c1  
				SELECT @delete_rowcount = @delete_rowcount + 1  
			END  
		END  
		FETCH NEXT FROM c1 INTO @trx_ctrl_num, @prompt1, @prompt2, @prompt3, @amt_payment  
	END  
  
	CLOSE  c1  
	DEALLOCATE  c1  
   
	SELECT @Text_String = RTRIM(LTRIM(STR(@delete_rowcount))) + ' payments had invalid data'  
	EXEC icv_Log_sp @Text_String, @Log_Activity  
  
	SELECT @rowcount = COUNT(*)  
	FROM icv_temp  
	WHERE spid = @spid  
   
	IF @rowcount = 0  
	BEGIN  
		EXEC icv_Get_External_String_sp 'No payments to process', @Text_String OUT  
		IF @delete_rowcount > 0  
		BEGIN  
			SELECT @Text_String = @Text_String + ', ' + RTRIM(LTRIM(STR(@delete_rowcount))) + ' payments had invalid data'  
		END  
		EXEC icv_Log_sp @Text_String, @Log_Activity  
		SELECT @Return_Additional_Information = @Text_String  
		SELECT @Error_Code = -1005  
		GOTO IAS_Return  
	END  
  
	SELECT @maybe_more = 0  
	IF (@batch_size_limit > 0)  
	BEGIN  
		IF (@rowcount >= @batch_size_limit)  
		BEGIN  
			SELECT @maybe_more = 1  
		END  
	END  
  
	UPDATE icv_temp   
    SET prompt1_inp = 'CCA'   
	WHERE ISNULL(DATALENGTH(RTRIM(LTRIM(prompt1_inp))),0) = 0  
  
	IF @IAS_Preview <> 1  
	BEGIN  
  
		IF @processor = 0  
		BEGIN  
			EXEC @result = icv_icverify_batch  
			IF @result <> 0  
			BEGIN  
				SELECT @Return_Additional_Information = 'Error returned from batch processing: ' + RTRIM(LTRIM(CONVERT(CHAR, @result)))  
				SELECT @Error_Code = -1009  
				GOTO IAS_Return  
			END  
		END  
   
		IF @processor = 1  
		BEGIN  
			EXEC @result = icv_trustmarque_batch  
			IF @result <> 0  
			BEGIN  
				SELECT @Return_Additional_Information = 'Error returned from batch processing: ' + RTRIM(LTRIM(CONVERT(CHAR, @result)))  
				SELECT @Error_Code = -1009  
				GOTO IAS_Return  
			END  
		END  
  
		IF @processor = 2  
		BEGIN  
			EXEC @result = icv_VeriSign_batch  
			IF @result <> 0  
			BEGIN  
				SELECT @Return_Additional_Information = 'Error returned from batch processing: ' + RTRIM(LTRIM(CONVERT(CHAR, @result)))  
				SELECT @Error_Code = -1009  
				GOTO IAS_Return  
			END  
		END  
	END  
  
	IF @IAS_Option = -1  
	BEGIN  
		IF @ICV_Log_Exists = 'YES'  
		BEGIN  
			DELETE FROM icv_log  
			EXEC icv_Get_External_String_sp 'Log Cleared', @Text_String  
			EXEC icv_Log_sp @Text_String, @Log_Activity  
			SELECT @Error_Code = 0   
			GOTO IAS_Return  
		END  
		ELSE  
		BEGIN  
			SELECT @Return_Additional_Information = 'Attemp to clear log that does not exist'  
			SELECT @Error_Code = -1002  
			GOTO IAS_Return  
		END  
	END  
  
	SELECT @Error_Code = 0  
	GOTO IAS_Return  
  
	IAS_Return:  
  
	IF @Error_Code <> 0  
	BEGIN  
		EXEC @Error_Code = aegError_sp @appid, @Error_Code, @Error_Msg OUT  
  
		SELECT 'ERRCODE' = @Error_Code,  
			'HRESULT' = ISNULL(@Text_HRESULT,''), --ff 5/30/03 FOR 7.3 VERSION  
			'ADDITIONALINFO' = @Return_Additional_Information,  
			'CUSTOMER' = '',  
			'PAYMENT-CODE' = '',  
			'DOCNUM' = '',   
			'DOC-DATE' = '',  
			'AMT' = 0.0,  
			'NAME' = '',  
			'ACCOUNT' = '',  
			'EXPIRATION' = '',  
			'AUTHORIZATION' = '',  
			'ERRORMESSAGE'=@Error_Msg,  
			'USER_ID'=@user_id,  
			'USER_NAME'=@user_name,  
			'COMPANY_NAME'=@company_name,  
			'TRX_CTRL_NUM'='',  
			'MAYBE_MORE'=@maybe_more  
		RETURN @Error_Code  
	END  
  
	IF @IAS_Option = 5  
	BEGIN  
		SELECT 'ERRCODE' = 0,  
			'HRESULT' = '',  
			'ADDITIONALINFO' = @Return_Additional_Information,  
			'CUSTOMER' = '',  
			'PAYMENT-CODE' = '',  
			'DOCNUM' = '',   
			'DOC-DATE' = 0,  
			'AMT' = @IAS_Amount,  
			'NAME' = @IAS_Name,  
			'ACCOUNT' = @IAS_Account,  
			'EXPIRATION' = @IAS_Expiration,  
			'AUTHORIZATION' = @C_prompt4_inp,  
			'ERRORMESSAGE'='',  
			'USER_ID'=@user_id,  
			'USER_NAME'=@user_name,  
			'COMPANY_NAME'=@company_name,  
			'TRX_CTRL_NUM'=@IAS_TrxCtrlNum,  
			'MAYBE_MORE'=@maybe_more  
		RETURN @Error_Code  
	END  
  
	SELECT DISTINCT  
		'ERRCODE' = @Error_Code,  
		'HRESULT' = ISNULL(@Text_HRESULT,''),              --FF 5/30/03 for 7.3 version  
		'ADDITIONALINFO' = @Return_Additional_Information,  
		'CUSTOMER' = a.customer_code,   
		'PAYMENT-CODE' = a.payment_code,   
		'DOCNUM' = a.doc_ctrl_num,   
		'DOC-DATE' = CONVERT(CHAR(12), DATEADD(dd,a.date_doc-722815,'1/1/80'), 101),  
		'AMT' = a.amt_payment,  
		'NAME' = a.prompt1_inp,   
		'ACCOUNT' = a.prompt2_inp,   
		'EXPIRATION' = a.prompt3_inp,  
		'AUTHORIZATION' = a.prompt4_inp,  
		'ERRORMESSAGE'='',  
		'USER_ID'=@user_id,  
		'USER_NAME'=@user_name,  
		'COMPANY_NAME'=@company_name,  
		'TRX_CTRL_NUM'=a.trx_ctrl_num,  
		'MAYBE_MORE'=@maybe_more  
	FROM arinptmp AS a, icv_cctype AS b  
	WHERE a.payment_code = b.payment_code  
    AND a.trx_ctrl_num in (SELECT trx_ctrl_num FROM icv_temp WHERE spid = @spid)  
	UNION   
	SELECT   
		'ERRCODE' = @Error_Code,  
		'HRESULT' = ISNULL(@Text_HRESULT,''),               --  ff 5/30/03 for 7.3 version  
		'ADDITIONALINFO' = @Return_Additional_Information,  
		'CUSTOMER' = a.customer_code,   
		'PAYMENT-CODE' = a.payment_code,   
		'DOCNUM' = a.doc_ctrl_num,   
		'DOC-DATE' = CONVERT(CHAR(12), DATEADD(dd,a.date_doc-722815,'1/1/80'), 101),  
		'AMT' = a.amt_payment,  
		'NAME' = a.prompt1_inp,   
		'ACCOUNT' = a.prompt2_inp,   
		'EXPIRATION' = a.prompt3_inp,  
		'AUTHORIZATION' = a.prompt4_inp,  
		'ERRORMESSAGE'='',  
		'USER_ID'=@user_id,  
		'USER_NAME'=@user_name,  
		'COMPANY_NAME'=@company_name,  
		'TRX_CTRL_NUM'=a.trx_ctrl_num,  
		'MAYBE_MORE'=@maybe_more  
	FROM arinppyt AS a, icv_cctype AS b  
	WHERE a.payment_code = b.payment_code  
    AND a.trx_ctrl_num in (SELECT trx_ctrl_num FROM icv_temp WHERE spid = @spid)  
END
GO
GRANT EXECUTE ON  [dbo].[icv_authorize_sp] TO [public]
GO
