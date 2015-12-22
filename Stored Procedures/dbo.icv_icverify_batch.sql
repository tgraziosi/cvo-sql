SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AR\PROCS\icv_icverify_batch.SPv - e7.2.2 : 1.2
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                


 
CREATE PROCEDURE [dbo].[icv_icverify_batch] AS
BEGIN
	DECLARE @buf				CHAR(255)
	DECLARE	@LogActivity			CHAR(3)
	DECLARE @result 			INTEGER
	DECLARE @icvbatch 			INTEGER
	DECLARE @max_users			INT
	DECLARE @ICV_filename			CHAR(20)
	DECLARE @reqpath 			VARCHAR(255)
	DECLARE @rowcount			INT
	DECLARE @Month 				CHAR(2)
	DECLARE @Year 				CHAR(2)
	DECLARE @xAmt 				CHAR(255)
	DECLARE @xTrxCtrlNum 			CHAR(255)
	DECLARE @xName 				CHAR(255)
	DECLARE @xAccount 			CHAR(255)
	DECLARE @xValid				CHAR(255)
	DECLARE @xMonth 			CHAR(255)
	DECLARE @xAuthorization 		CHAR(255)
	DECLARE @xYear 				CHAR(255)
	DECLARE @xTrxType 			CHAR(255)
	DECLARE @trx_ctrl_num 			VARCHAR(16)
	DECLARE @C_float_amt_payment 		FLOAT 
	DECLARE @C_prompt1_inp 			VARCHAR(255)
	DECLARE @C_prompt2_inp 			VARCHAR(255)
	DECLARE @C_prompt3_inp 			VARCHAR(255)
	DECLARE @trx_code			CHAR(2)
	DECLARE	@batch_counter			INT
	DECLARE @payment_code			CHAR(8)
	DECLARE @customer_code			CHAR(8)
	DECLARE @prompt1 			VARCHAR(30)
	DECLARE @prompt2 			VARCHAR(30)
	DECLARE @prompt3 			VARCHAR(30)
	DECLARE @Return_Additional_Information 	VARCHAR(255)
	DECLARE @Error_Code 			INT
	DECLARE @spid				INT
	DECLARE @iMonth				INT
	DECLARE @iYear				INT
	DECLARE @arinpchg_rowcount		INT
	DECLARE @arinppyt_rowcount		INT
	DECLARE @arinptmp_rowcount		INT
	DECLARE @arinptmp2_rowcount		INT
	DECLARE @trx_type			CHAR(2)
	DECLARE @dateValid			INT


	SET NOCOUNT ON

	SELECT @spid = @@spid, @batch_counter = 0, @Error_Code = 0

	SELECT @buf = UPPER(configuration_text_value)
	 FROM icv_config
	 WHERE UPPER(configuration_item_name) = "LOG ACTIVITY"

	IF @@rowcount <> 1
		SELECT @buf = "NO"

	IF @buf = "YES"
	BEGIN
		SELECT @LogActivity = "YES"
	END
	ELSE
	BEGIN
		SELECT @LogActivity = "NO"
	END

	
	SELECT @max_users = ISNULL(CONVERT(INT,value_str),3) 
	 FROM config 
	 WHERE UPPER(flag) = "ICV_MAX_USERS"
	IF @max_users < 3 OR @max_users > 999 OR @@ROWCOUNT = 0
	BEGIN
		SELECT @max_users = 3
		EXEC icv_Get_External_String_sp 'Max users defaulted to 3', @buf OUT
		EXEC icv_Log_sp @buf, @LogActivity
	END

	SELECT @buf = CONVERT(CHAR(3),@max_users - 1)
	SELECT @ICV_filename = "\ICVER" + REPLICATE("0", 3-DATALENGTH(RTRIM(LTRIM(@buf)))) + RTRIM(LTRIM(@buf)) + ".REQ"
	EXEC icv_Get_External_String_sp 'Filename for batch processing set to ', @buf OUT
	SELECT @buf = RTRIM(LTRIM(@buf)) + ' ' + @ICV_filename
	EXEC icv_Log_sp @buf, @LogActivity

	EXEC @result = sp_OACreate 'cca.batch.1',@icvbatch OUT
	IF @result <> 0 
	BEGIN
		EXEC icv_Get_External_String_sp 'Error creating cca.batch.1', @buf OUT
		SELECT @Return_Additional_Information = @buf
		EXEC icv_Log_sp @buf, @LogActivity
		EXEC icv_Convert_HRESULT_sp @result, @buf OUT
		EXEC icv_Log_sp @buf, @LogActivity
		EXEC icv_Get_OA_Message_sp @icvbatch, @buf OUT
		EXEC icv_Log_sp @buf, @LogActivity
		SELECT @Error_Code = -1999
		GOTO IAS_Return
	END 


	SELECT @reqpath = RTRIM(LTRIM(value_str)) + @ICV_filename
	 FROM config 
	 WHERE UPPER(flag) = 'ICV_REQ_PATH'

	SELECT @rowcount = @@rowcount
	IF @rowcount = 0
	BEGIN
		EXEC icv_Get_External_String_sp 'The config entry ICV_REQ_PATH could not be found', @buf OUT
		SELECT @Return_Additional_Information = @buf
		EXEC icv_Log_sp @buf, @LogActivity
		SELECT @Error_Code = -1999
		GOTO IAS_Return
	END

	SELECT @buf = 'Opening batch: ' + RTRIM(LTRIM(@reqpath))
	EXEC icv_Log_sp @buf, @LogActivity

	EXEC @result = sp_OAMethod @icvbatch, "OpenBatch", NULL, @reqpath
	IF @result <> 0 
	BEGIN
		EXEC icv_Get_External_String_sp 'Error opening batch', @buf OUT
		SELECT @Return_Additional_Information = @buf
		EXEC icv_Log_sp @buf, @LogActivity
		EXEC icv_Convert_HRESULT_sp @result, @buf OUT
		EXEC icv_Log_sp @buf, @LogActivity
		EXEC icv_Get_OA_Message_sp @icvbatch, @buf OUT
		EXEC icv_Log_sp @buf, @LogActivity
		SELECT @Error_Code = -1999
		GOTO IAS_Return
	END 

	DECLARE IC_Verify_Cursor INSENSITIVE CURSOR FOR 
	 SELECT trx_ctrl_num, prompt1_inp, prompt2_inp, prompt3_inp, amt_payment, trx_code FROM icv_temp WHERE spid = @spid

	OPEN IC_Verify_Cursor
	 FETCH NEXT FROM IC_Verify_Cursor INTO @trx_ctrl_num, @C_prompt1_inp, @C_prompt2_inp, @C_prompt3_inp, @C_float_amt_payment, @trx_code

					
	WHILE (@@FETCH_STATUS <> -1)
	BEGIN
		IF @@FETCH_STATUS <> -2
		BEGIN
			EXEC @result = icv_parse_expiration @C_prompt3_inp, @iMonth OUTPUT, @iYear OUTPUT, @dateValid OUTPUT
			IF @dateValid = 0
			BEGIN
				EXEC icv_Get_External_String_sp 'Invalid expiration date: ', @buf OUT
				SELECT @buf = @buf + @C_prompt3_inp
				SELECT @Return_Additional_Information = @buf
				EXEC icv_Log_sp @buf, @LogActivity
				GOTO FETCHNEXT
			END 

			SELECT @Month = CONVERT(CHAR(2), @iMonth)
			SELECT @Year = CONVERT(CHAR(4), @iYear)
			SELECT @xAmt = RTRIM(LTRIM(STR(@C_float_amt_payment,10,2)))

			SELECT @buf = 'AddTransaction: ' + RTRIM(LTRIM(@trx_ctrl_num)) + ', ' + RTRIM(LTRIM(@C_prompt1_inp)) + ', ' + RTRIM(LTRIM(@C_prompt2_inp)) + ', ' + RTRIM(LTRIM(CONVERT(CHAR,@Month))) + '/' + RTRIM(LTRIM(CONVERT(CHAR,@Year))) + ', ' + RTRIM(LTRIM(@xAmt)) + ', ' + RTRIM(LTRIM(@trx_code))
			EXEC icv_Log_sp @buf, @LogActivity

			EXEC @result = sp_OAMethod @icvbatch, "AddTransaction", NULL, @trx_ctrl_num, @C_prompt1_inp, @C_prompt2_inp, @Month, @Year, @xAmt, @trx_code
			IF @result <> 0 
			BEGIN
				EXEC icv_Get_External_String_sp 'Error adding transaction', @buf OUT
				SELECT @Return_Additional_Information = @buf
				EXEC icv_Log_sp @buf, @LogActivity
				EXEC icv_Convert_HRESULT_sp @result, @buf OUT
				EXEC icv_Log_sp @buf, @LogActivity
				EXEC icv_Get_OA_Message_sp @icvbatch, @buf OUT
				EXEC icv_Log_sp @buf, @LogActivity
				GOTO FETCHNEXT
			END 

			SELECT @batch_counter = @batch_counter + 1
		END

FETCHNEXT:
		FETCH NEXT FROM IC_Verify_Cursor INTO @trx_ctrl_num, @C_prompt1_inp, @C_prompt2_inp, @C_prompt3_inp, @C_float_amt_payment, @trx_code
	END

	CLOSE IC_Verify_Cursor
	DEALLOCATE IC_Verify_Cursor

	SELECT @buf = RTRIM(LTRIM(CONVERT(CHAR,@batch_counter))) + " transactions in this batch"
	EXEC icv_Log_sp @buf, @LogActivity

	SELECT @buf = 'Submitting batch, blocked, 15 minute timeout'
	EXEC icv_Log_sp @buf, @LogActivity

	EXEC @result = sp_OAMethod @icvbatch, "SubmitBatch", NULL, 1, 900
	IF @result <> 0 
	BEGIN
		EXEC icv_Get_External_String_sp 'Error submitting batch', @buf OUT
		EXEC icv_Log_sp @buf, @LogActivity
		EXEC icv_Convert_HRESULT_sp @result, @buf OUT
		EXEC icv_Log_sp @buf, @LogActivity
		EXEC icv_Get_OA_Message_sp @icvbatch, @buf OUT
		EXEC icv_Log_sp @buf, @LogActivity
		SELECT @Return_Additional_Information = @buf
		SELECT @Error_Code = -1999
		GOTO IAS_Return
	END 

	WHILE 42 = 42
	BEGIN
		SELECT 	@xTrxCtrlNum = "",@xName = "",@xAccount = "",@xMonth = "",@xYear = "",@xAmt = "",@xTrxType = "",@xAuthorization = "", @xValid = ""
		EXEC @result = sp_OAMethod @icvbatch, "GetTransaction", NULL, @xTrxCtrlNum OUT, @xName OUT, @xAccount OUT, @xMonth OUT, @xYear OUT, @xAmt OUT, @xTrxType OUT, @xAuthorization OUT, @xValid OUT
		IF @result <> 0 
		BEGIN
			EXEC icv_Get_External_String_sp 'Error getting transaction', @buf OUT
			SELECT @Return_Additional_Information = @buf
			EXEC icv_Log_sp @buf, @LogActivity
			EXEC icv_Convert_HRESULT_sp @result, @buf OUT
			EXEC icv_Log_sp @buf, @LogActivity
			EXEC icv_Get_OA_Message_sp @icvbatch, @buf OUT
			EXEC icv_Log_sp @buf, @LogActivity
			SELECT @Error_Code = -1999
			GOTO IAS_Return
		END 
 			
		SELECT @buf = 'GetTransaction returned: ' + RTRIM(LTRIM(@xTrxCtrlNum)) + ', ' + RTRIM(LTRIM(@xName)) + ', ' + RTRIM(LTRIM(@xAccount)) + ', ' + RTRIM(LTRIM(@xMonth)) + '/' + RTRIM(LTRIM(@xYear)) + ', ' + RTRIM(LTRIM(@xAmt)) + ', ' + RTRIM(LTRIM(@xTrxType)) + ', ' + RTRIM(LTRIM(@xAuthorization)) + ', ' + RTRIM(LTRIM(@xValid))
		EXEC icv_Log_sp @buf, @LogActivity

		IF (ISNULL(DATALENGTH(RTRIM(LTRIM(@xTrxCtrlNum))),0) = 0)
		BEGIN
			BREAK
		END

		SELECT @batch_counter = @batch_counter - 1
		IF @batch_counter < 0
		BEGIN
			SELECT @buf = "Batch loop did not terminate properly"
			EXEC icv_Log_sp @buf, @LogActivity
			SELECT @Return_Additional_Information = @buf
			SELECT @Error_Code = -1999
			GOTO IAS_Return
		END

		SELECT @trx_ctrl_num = RTRIM(LTRIM(@xTrxCtrlNum)), @prompt1 = RTRIM(LTRIM(@xName)), @prompt2 = RTRIM(LTRIM(@xAccount)), @prompt3 = RTRIM(LTRIM(@xMonth)) + "/" + RTRIM(LTRIM(@xYear)), @iMonth = CONVERT(INT, RTRIM(LTRIM(@xMonth))), @iYear = CONVERT(INT, RTRIM(LTRIM(@xYear))), @C_float_amt_payment = CONVERT(FLOAT, RTRIM(LTRIM(@xAmt))), @trx_type = RTRIM(LTRIM(@xTrxType))
		EXEC icv_history 1, '', @trx_ctrl_num, @prompt1, @prompt2, @iMonth, @iYear, @C_float_amt_payment, @trx_type, @xAuthorization
		SELECT @buf = RTRIM(LTRIM(@xValid)) + RTRIM(LTRIM(@xAuthorization))
		EXEC icv_history 2, @buf

		IF @xValid = "Y"
		BEGIN
			IF (@xTrxType = "C4")
				SELECT @xAuthorization = "BOOKED"

			UPDATE arinpchg SET hold_flag = 0
			 WHERE trx_ctrl_num = @trx_ctrl_num
			SELECT @arinpchg_rowcount = @@ROWCOUNT
			UPDATE arinppyt SET hold_flag = 0, prompt4_inp = @xAuthorization
			 WHERE trx_ctrl_num = @trx_ctrl_num
			SELECT @arinppyt_rowcount = @@ROWCOUNT
			UPDATE arinptmp SET prompt4_inp = @xAuthorization
			 WHERE trx_ctrl_num = @trx_ctrl_num
			SELECT @arinptmp_rowcount = @@ROWCOUNT
			UPDATE arinptmp SET arinptmp.prompt4_inp = @xAuthorization
			 FROM arinptmp AS a, arinpchg AS b
			 WHERE a.trx_ctrl_num = b.trx_ctrl_num
			 AND b.order_ctrl_num = @trx_ctrl_num
			SELECT @arinptmp2_rowcount = @@ROWCOUNT
			SELECT @buf = "Batch booking succeeded, @trx_ctrl_num: " + @trx_ctrl_num + ", @xAuthorization: " + @xAuthorization
			EXEC icv_Log_sp @buf, @LogActivity

			SELECT @buf = "arinpchg: " + RTRIM(LTRIM(CONVERT(CHAR, @arinpchg_rowcount))) + ", " + "arinppyt: " + RTRIM(LTRIM(CONVERT(CHAR, @arinppyt_rowcount))) + ", " + "arinptmp: " + RTRIM(LTRIM(CONVERT(CHAR, @arinptmp_rowcount))) + ", " + "arinptmp2: " + RTRIM(LTRIM(CONVERT(CHAR, @arinptmp2_rowcount)))
			EXEC icv_Log_sp @buf, @LogActivity

			
			SELECT @payment_code = payment_code, @customer_code = customer_code
			 FROM arinptmp
			 WHERE trx_ctrl_num = @trx_ctrl_num
			SELECT @rowcount = @@rowcount

			IF @rowcount = 0
			BEGIN
				SELECT @buf = "Get CC information from arinppyt"
				EXEC icv_Log_sp @buf, @LogActivity
				SELECT @payment_code = payment_code, @customer_code = customer_code
				 FROM arinppyt
				 WHERE trx_ctrl_num = @trx_ctrl_num
				SELECT @rowcount = @@rowcount
			END

			IF @rowcount = 0
			BEGIN
				SELECT @buf = "Get CC information based on order_ctrl_num"
				EXEC icv_Log_sp @buf, @LogActivity
				SELECT @payment_code = a.payment_code, @customer_code = a.customer_code
				 FROM arinptmp AS a, arinpchg AS b
				 WHERE a.trx_ctrl_num = b.trx_ctrl_num
				 AND b.order_ctrl_num = @trx_ctrl_num
				SELECT @rowcount = @@rowcount
			END

			SELECT @buf = "payment_code: " + RTRIM(LTRIM(@payment_code)) + ", customer_code: " + RTRIM(LTRIM(@customer_code)) + ", trx_ctrl_num: " + RTRIM(LTRIM(@trx_ctrl_num)) + ", rowcount: " + RTRIM(LTRIM(CONVERT(CHAR, @rowcount)))
			EXEC icv_Log_sp @buf, @LogActivity

			IF @rowcount <> 0
			BEGIN
				EXEC icv_savecc @payment_code, @customer_code, @prompt1, @prompt2, @prompt3, ''
			END
		END
		ELSE
		BEGIN
			IF (ISNULL(DATALENGTH(RTRIM(LTRIM(@xAuthorization))),0) = 0)
				SELECT @xAuthorization = "TRANSACTION FAILED"
			UPDATE arinpchg SET hold_flag = 1
			 WHERE trx_ctrl_num = @trx_ctrl_num
			SELECT @arinpchg_rowcount = @@ROWCOUNT
			UPDATE arinppyt SET hold_flag = 1, prompt4_inp = @xAuthorization
			 WHERE trx_ctrl_num = @trx_ctrl_num
			SELECT @arinppyt_rowcount = @@ROWCOUNT
			UPDATE arinptmp SET prompt4_inp = @xAuthorization
			 WHERE trx_ctrl_num = @trx_ctrl_num
			SELECT @arinptmp_rowcount = @@ROWCOUNT
			UPDATE arinptmp SET arinptmp.prompt4_inp = @xAuthorization
			 FROM arinptmp AS a, arinpchg AS b
			 WHERE a.trx_ctrl_num = b.trx_ctrl_num
			 AND b.order_ctrl_num = @trx_ctrl_num
			SELECT @arinptmp2_rowcount = @@ROWCOUNT
			SELECT @buf = "Batch booking failed, @trx_ctrl_num: " + @trx_ctrl_num + ", @xAuthorization: " + @xAuthorization
			EXEC icv_Log_sp @buf, @LogActivity

			SELECT @buf = "arinpchg: " + RTRIM(LTRIM(CONVERT(CHAR, @arinpchg_rowcount))) + ", " + "arinppyt: " + RTRIM(LTRIM(CONVERT(CHAR, @arinppyt_rowcount))) + ", " + "arinptmp: " + RTRIM(LTRIM(CONVERT(CHAR, @arinptmp_rowcount))) + ", " + "arinptmp2: " + RTRIM(LTRIM(CONVERT(CHAR, @arinptmp2_rowcount)))
			EXEC icv_Log_sp @buf, @LogActivity
		END
	END

	IF @icvbatch <> 0
	BEGIN
		IF @Error_Code = 0
		BEGIN
			SELECT @buf = 'Closing batch'
			EXEC icv_Log_sp @buf, @LogActivity 
			EXEC @result = sp_OAMethod @icvbatch, "CloseBatch", NULL
			IF @result <> 0 
			BEGIN
				EXEC icv_Get_External_String_sp 'Error closing batch', @buf OUT
				SELECT @Return_Additional_Information = @buf
				EXEC icv_Log_sp @buf, @LogActivity
				EXEC icv_Convert_HRESULT_sp @result, @buf OUT
				EXEC icv_Log_sp @buf, @LogActivity
				EXEC icv_Get_OA_Message_sp @icvbatch, @buf OUT
				EXEC icv_Log_sp @buf, @LogActivity
				SELECT @Error_Code = -1999
				GOTO IAS_Return
			END 
		END
		EXEC @result = sp_OADestroy @icvbatch
		IF @result <> 0 
		BEGIN
			EXEC icv_Get_External_String_sp 'Error destroying cca.batch.1', @buf OUT
			SELECT @Return_Additional_Information = @buf
			EXEC icv_Log_sp @buf, @LogActivity
			EXEC icv_Convert_HRESULT_sp @result, @buf OUT
			EXEC icv_Log_sp @buf, @LogActivity
			EXEC icv_Get_OA_Message_sp @icvbatch, @buf OUT
			EXEC icv_Log_sp @buf, @LogActivity
			SELECT @Error_Code = -1999
			GOTO IAS_Return
		END 
	END
IAS_Return:
END
GO
GRANT EXECUTE ON  [dbo].[icv_icverify_batch] TO [public]
GO
