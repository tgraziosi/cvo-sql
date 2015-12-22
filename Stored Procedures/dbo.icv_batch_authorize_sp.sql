SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/                                                






















    CREATE PROCEDURE [dbo].[icv_batch_authorize_sp]	@preview 		smallint = 1, 
						@include_cr     	smallint =1,
						@include_invoices	smallint =1,
						@include_onhold		smallint =1,
						@cust_from		varchar(20)='',
						@cust_to		varchar(20)='',
						@doc_from		varchar(20)='',
						@doc_to			varchar(20)='',
						@batch_from		varchar(20)='',
						@batch_to		varchar(20)=''
		
    AS
	DECLARE @result 			INTEGER
	DECLARE @trx_type			CHAR(2)
	DECLARE @batch_size_limit		INT
	DECLARE @maybe_more			INT
	DECLARE @spid				INT
	DECLARE @Error_Code 			int
	DECLARE @Error_Msg			varchar(255)
	DECLARE @appid				int
	DECLARE @HRESULT 			int
	DECLARE @max_users			INT
	DECLARE @ICV_filename			CHAR(20)
	DECLARE	@processor			INT
	DECLARE	@processor_name			CHAR(255)
	DECLARE @ICV_Config_Table_Exists 	char(5)
	DECLARE @ICV_Log_Exists 		char(5)
	DECLARE @ICV_Request_Timeout 		int
	DECLARE @ICV_String_Table_Exists 	char(5)
	DECLARE @Log_Activity 			char(10)
	DECLARE @Return 			int
	DECLARE @Return_Additional_Information 	varchar(255)
	DECLARE @Text_HRESULT 			char(10)
	DECLARE @Text_String 			varchar(255)
	DECLARE @Year 				char(4)
	DECLARE @Month 				char(2)
	DECLARE @trx_ctrl_num 			varchar(16)
	DECLARE @prompt1 			varchar(30)
	DECLARE @prompt2 			varchar(30)
	DECLARE @prompt3 			varchar(30)
	DECLARE @amt_payment 			float
	DECLARE @buf 				varchar(255)
	DECLARE @rowcount 			int
	DECLARE @delete_rowcount		int
	DECLARE @user_id			int
	DECLARE @user_name			varchar(30)
	DECLARE @company_name			varchar(30)		
	DECLARE	@dateValid			INT
	DECLARE @SQL 				NVARCHAR(2000)
	DECLARE @isnull				SMALLINT
	DECLARE @isnullbatch				SMALLINT

	SET NOCOUNT ON

	SELECT @isnullbatch=0,@isnull=0,@Return_Additional_Information = '', @appid = 28000, @user_id = 0, @user_name = '', @company_name = '', @HRESULT = 0, @Error_Code = 0, @maybe_more = 0, @spid = @@spid

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

	


	IF EXISTS (SELECT 1 FROM arco WHERE ISNULL(authorize_onsave,0)=0) 	
	BEGIN
		SELECT @trx_type= 'C1'
	END
	ELSE
	BEGIN
		SELECT @trx_type= 'CO'
	END

	IF (LEN(@cust_from)<=0 OR @cust_from ='<first>' ) 
		SELECT @cust_from=MIN(customer_code) from arcust
	IF (LEN(@cust_to)<=0 OR @cust_to ='<last>' )
		SELECT @cust_to=MAX(customer_code) from arcust


	IF (LEN(@doc_from)<=0 OR @doc_from ='<first>') 
		SELECT @doc_from=MIN(doc_ctrl_num),@isnull=1 from arinptmp
	IF (LEN(@doc_to)<=0 OR @doc_to ='<last>' )
		SELECT @doc_to=MAX(doc_ctrl_num),@isnull=1 from arinptmp

	IF (LEN(@batch_from)<=0 OR @batch_from ='<first>') 
		SELECT @batch_from=MIN(batch_code),@isnullbatch=1 from arinpchg
	IF (LEN(@batch_to)<=0 OR @batch_to ='<last>' )
		SELECT @batch_to=MAX(batch_code),@isnullbatch=1 from arinpchg


	


	SET ROWCOUNT @batch_size_limit

	


	IF (@include_invoices =1) 
	BEGIN
		 INSERT icv_temp (spid, trx_ctrl_num, prompt1_inp, prompt2_inp, prompt3_inp, amt_payment, trx_code, new_ctrl_num) 
		   SELECT @spid, a.trx_ctrl_num, a.prompt1_inp, a.prompt2_inp, a.prompt3_inp, a.amt_payment,  @trx_type , ''
		   FROM arinptmp AS a, icv_cctype AS b, arinpchg AS c 
			WHERE a.payment_code = b.payment_code 
			 AND ISNULL(DATALENGTH(RTRIM(LTRIM(a.prompt4_inp))),0) = 0 
		   	 AND a.trx_ctrl_num = c.trx_ctrl_num 
			  AND c.hold_flag IN (0,@include_onhold) 
			  AND c.customer_code BETWEEN @cust_from AND @cust_to
			  AND a.doc_ctrl_num  BETWEEN @doc_from AND @doc_to
			  AND c.batch_code  BETWEEN @batch_from AND @batch_to
		 
	END

	IF (@isnull=1 ) 
		SELECT @doc_from=MIN(doc_ctrl_num) from arinppyt
	IF (@isnull=1 )
		SELECT @doc_to=MAX(doc_ctrl_num) from arinppyt

	IF (@isnullbatch=1 ) 
		SELECT @batch_from=MIN(batch_code) from arinppyt
	IF (@isnullbatch=1 )
		SELECT @batch_to=MAX(batch_code) from arinppyt

	
	
	



	IF (@include_cr =1) 
	BEGIN
		 	INSERT icv_temp (spid, trx_ctrl_num, prompt1_inp, prompt2_inp, prompt3_inp, amt_payment, trx_code, new_ctrl_num)	 
			SELECT @spid, a.trx_ctrl_num, a.prompt1_inp, a.prompt2_inp, a.prompt3_inp, a.amt_payment, @trx_type , ''
		 	     FROM arinppyt AS a, icv_cctype AS b 
			     WHERE a.payment_code = b.payment_code 
		 	     AND ISNULL(DATALENGTH(RTRIM(LTRIM(a.prompt4_inp))),0) = 0 
			     AND a.hold_flag IN (0,@include_onhold ) 
			     AND a.customer_code BETWEEN @cust_from AND @cust_to
			     AND a.doc_ctrl_num  BETWEEN @doc_from AND @doc_to
			     AND a.batch_code  BETWEEN @batch_from AND @batch_to
	END

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
			    ISNULL(@amt_payment,0.0) <= 0.0 OR
			    @dateValid = 0)
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


	IF @preview <> 1
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
			EXEC @result = icv_trustmarque_batch_sp
			IF @result <> 0
			BEGIN
				SELECT @Return_Additional_Information = 'Error returned from batch processing: ' + RTRIM(LTRIM(CONVERT(CHAR, @result)))
				SELECT @Error_Code = -1009
				GOTO IAS_Return
			END
		END

		
		IF @processor = 2
		BEGIN
			EXEC @result = icv_verisign_batch
			IF @result <> 0
			BEGIN
				SELECT @Return_Additional_Information = 'Error returned from batch processing: ' + RTRIM(LTRIM(CONVERT(CHAR, @result)))
				SELECT @Error_Code = -1009
				GOTO IAS_Return
			END
		END
	END


	SELECT @Error_Code = 0
	GOTO IAS_Return

IAS_Return:


	UPDATE #cca_errors
	SET message = substring(m.message_explanation,1,254)
	FROM #cca_errors e 
		INNER JOIN icv_messages m
		ON e.error_code = m.response_code
		AND m.provider = @processor

	SELECT DISTINCT
		'ERRCODE' = 0,
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
		'ERRCODE' = 0,
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

GO
GRANT EXECUTE ON  [dbo].[icv_batch_authorize_sp] TO [public]
GO
