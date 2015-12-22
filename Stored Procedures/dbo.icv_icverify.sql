SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AR\PROCS\icv_icverify.SPv - e7.2.2 : 1.2
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                


 
CREATE PROCEDURE [dbo].[icv_icverify] 	@transtype CHAR(3),
				@ccnumber varCHAR(20),
				@ccexpmo CHAR(2),
				@ccexpyr CHAR(4),
				@ordtotal Decimal(20,8),
				@response VARCHAR(60) OUTPUT,
				@order_no int = 0,
 				@ext int = 0,
				@prompt1 CHAR(30) = "",
				@trx_ctrl_num VARCHAR(16) = ""
AS
BEGIN
	DECLARE @buf			CHAR(255)
	DECLARE	@LogActivity		CHAR(3)
	DECLARE @AddressVerification	INT
	DECLARE	@IgnoreAddressFailure	INT
	DECLARE @LevelIICompliance	INT
	DECLARE @status			CHAR(1)
	DECLARE	@trx_type		CHAR
	DECLARE @zipcode		CHAR(30)
	DECLARE @address		CHAR(30)
	DECLARE @ix			INT
	DECLARE @ord_total_str 		VARCHAR(20)
	DECLARE @result 		INT
	DECLARE @icvpay 		INT
	DECLARE @merch 			VARCHAR(255)
	DECLARE @reqpath 		VARCHAR(255)
	DECLARE @maxusrs 		VARCHAR(255)
	DECLARE @timeout 		VARCHAR(255)
	DECLARE @maxusrsint 		INT
	DECLARE @timeoutint 		INT
	DECLARE @ret 			INT
	DECLARE @payment_code		CHAR(8)


	SET NOCOUNT ON


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

	SELECT @buf = UPPER(configuration_text_value)
	 FROM icv_config
	 WHERE UPPER(configuration_item_name) = "DEMO MODE"

	IF @@rowcount <> 1
		SELECT @buf = "NO"

	IF @buf = "YES"
	BEGIN
		SELECT @response = """Y999999"""
		GOTO ICVRETURN
	END

	SELECT @buf = UPPER(configuration_text_value),
	 @AddressVerification = configuration_int_value
	 FROM icv_config
	 WHERE UPPER(configuration_item_name) = "ADDRESS VERIFICATION"

	IF @@rowcount <> 1
		SELECT @buf = "NO"

	IF @buf <> "YES"
	BEGIN
		SELECT @AddressVerification = 0
	END

	SELECT @buf = UPPER(configuration_text_value)
	 FROM icv_config
	 WHERE UPPER(configuration_item_name) = "IGNORE ADRESS VERIFICATION FAILURE"

	IF @@rowcount <> 1
		SELECT @buf = "NO"

	IF @buf = "YES"
	BEGIN
		SELECT @IgnoreAddressFailure = 1
	END
	ELSE
	BEGIN
		SELECT @IgnoreAddressFailure = 0
	END

	SELECT @buf = UPPER(configuration_text_value)
	 FROM icv_config
	 WHERE UPPER(configuration_item_name) = "LEVEL II COMPLIANCE"

	IF @@rowcount <> 1
		SELECT @buf = "NO"

	IF @buf = "YES"
	BEGIN
		SELECT @LevelIICompliance = 1
	END
	ELSE
	BEGIN
		SELECT @LevelIICompliance = 0
	END


	SELECT @buf = "Entering icv_icverify " + RTRIM(LTRIM(@transtype)) + ", " + RTRIM(LTRIM(@ccnumber)) + ", " + RTRIM(LTRIM(@ccexpmo)) + ", " + RTRIM(LTRIM(@ccexpyr)) + ", " + RTRIM(LTRIM(CONVERT(CHAR, @ordtotal))) + ", " + RTRIM(LTRIM(CONVERT(CHAR, @order_no))) + ", " + RTRIM(LTRIM(CONVERT(CHAR, @ext)))
	EXEC icv_Log_sp @buf, @LogActivity
	SELECT @buf = "Address verification: " + RTRIM(LTRIM(CONVERT(CHAR, @AddressVerification)))
	EXEC icv_Log_sp @buf, @LogActivity
	SELECT @buf = "Ignore Address Verification Failure: " + RTRIM(LTRIM(CONVERT(CHAR, @IgnoreAddressFailure)))
	EXEC icv_Log_sp @buf, @LogActivity
	SELECT @buf = "Level II Compliance: " + RTRIM(LTRIM(CONVERT(CHAR, @LevelIICompliance)))
	EXEC icv_Log_sp @buf, @LogActivity


	
	SELECT @status = status 
	 FROM orders
	 WHERE order_no = @order_no
	 AND ext = @ext
	IF (@status = "V")
	BEGIN
		SELECT @buf = "Immediate return from icv_icverify because order " + RTRIM(LTRIM(CONVERT(CHAR,@order_no))) + "," + RTRIM(LTRIM(CONVERT(CHAR,@ext))) + " has a status of '" + @status + "'"
		EXEC icv_Log_sp @buf, @LogActivity
		SELECT @ret = -1310
		SELECT @response = """NORDER IS VOID"""
		GOTO ICVRETURN
	END
	

	
	SELECT @trx_type = ""
	-- Authorization transaction
	IF @transtype = 'C6'
		SELECT @trx_type = "A"
	-- Book transaction
	IF @transtype = 'C4'
		SELECT @trx_type = "B"
	-- Ship transaction
	IF @transtype = 'CO'
		SELECT @trx_type = "S"
	-- Sale transaction
	IF @transtype = 'C1'
		SELECT @trx_type = "S"
	-- Credit return transaction	
	IF @transtype = 'C3'
		SELECT @trx_type = "C"
	IF @trx_type <> ""
	BEGIN
		IF EXISTS (SELECT 1 
	 FROM icv_ord_payment_dtl 
	 WHERE order_no = @order_no
			 AND ext = @ext
			 AND response_flag = @trx_type
			 AND DATALENGTH(RTRIM(LTRIM(approval_code))) > 0)
		BEGIN
			SELECT @buf = "Transaction has already been performed for this order"
			EXEC icv_Log_sp @buf, @LogActivity
			SELECT @response = """Y999998"""
			SELECT @ret = -1300
			GOTO ICVRETURN
		END
	END

	
	IF @AddressVerification > 0
	BEGIN
		IF ISNULL(DATALENGTH(RTRIM(LTRIM(@prompt1))),0) = 0
		BEGIN
			SELECT @prompt1 = prompt1_inp
			 FROM ord_payment
			 WHERE order_no = @order_no
			 AND order_ext = @ext
		END

		SELECT @ix = CHARINDEX('/',@prompt1)				
		IF @ix <= 1 OR @ix >= DATALENGTH(RTRIM(LTRIM(@prompt1)))
		BEGIN
			SELECT @buf = "Invalid prompt1 when AVS_MODE is on: " + @prompt1
			EXEC icv_Log_sp @buf, @LogActivity
			SELECT @buf = "AVS_MODE will be turned off for this transaction"
			EXEC icv_Log_sp @buf, @LogActivity
			SELECT @AddressVerification = 0
		END
		ELSE
		BEGIN
			SELECT @zipcode = SUBSTRING( @prompt1, 1, @ix-1 ),
			 @address = SUBSTRING( @prompt1, @ix+1, DATALENGTH(@prompt1) )
			SELECT @buf = "Zip: " + @zipcode + " Address: " + @address
			EXEC icv_Log_sp @buf, @LogActivity
		END
	END


	Select @ord_total_str = Convert(varchar(20), @ordtotal),
		@ret = 0

	-- Instantiate the ole object	
 	EXEC @result = sp_OACreate 'icvpayctrl.icvpayctrl.1',@icvpay OUT
	IF @result <> 0 
	BEGIN
 		select @response = 'Error: OLE Error on sp_OACreate'
		SELECT @ret = -1000
 		GOTO ICVRETURN
	END 

	-- Retrieve required data from dbo.config
	BEGIN
 		SELECT @merch = (SELECT value_str FROM config WHERE UPPER(flag) = 'ICV_MERCH_CODE')
		IF @merch IS NULL 
		BEGIN
 			select @response = 'Error: No Merchant Code Found'
			SELECT @ret = -1010
	 		GOTO ICVRETURN
		END
 		SELECT @reqpath = (SELECT value_str FROM config WHERE UPPER(flag) = 'ICV_REQ_PATH')
 		IF @reqpath IS NULL
		BEGIN
 			select @response = 'Error: No ICVerify Directory Path Found'
			SELECT @ret = -1020
 			GOTO ICVRETURN
		END
 
 		SELECT @maxusrs = (SELECT value_str FROM config WHERE UPPER(flag) = 'ICV_MAX_USERS')
		IF @maxusrs IS NULL
		BEGIN
 			select @response = 'Error: No Maximum Users Found'
			SELECT @ret = -1030
 			GOTO ICVRETURN
		END 		
 		SELECT @timeout = (SELECT value_str FROM config WHERE UPPER(flag) = 'ICV_TIMEOUT')
		IF @timeout IS NULL
		BEGIN
 			select @response = 'Error: No Timeout Found'
			SELECT @ret = -1040
	 		GOTO ICVRETURN
		END
	END	
	SELECT @maxusrsint = CONVERT(INT, @maxusrs)
	SELECT @timeoutint = CONVERT(INT, @timeout)
 
 
	-- set OLE object properties to allow for transaction processing:
	EXEC @result = sp_OASetProperty @icvpay, 'Req_Dir', @reqpath
	IF @result <> 0 
	BEGIN
 		select @response = 'Error: OLE Error'
		SELECT @ret = -1050
 		GOTO ICVRETURN
	END

	EXEC @result = sp_OASetProperty @icvpay, 'Max_Users', @maxusrsint
	IF @result <> 0 
	BEGIN
		EXEC icv_Convert_HRESULT_sp @result, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		EXEC icv_Get_OA_Message_sp @icvpay, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
 		select @response = 'Error: OLE Error on sp_OASetProperty for Max_users'
		SELECT @ret = -1060
 		GOTO ICVRETURN
	END

	EXEC @result = sp_OASetProperty @icvpay, 'License_Timeout', @timeoutint
	IF @result <> 0 
	BEGIN
		EXEC icv_Convert_HRESULT_sp @result, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		EXEC icv_Get_OA_Message_sp @icvpay, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
 		select @response = 'Error: OLE Error on sp_OASetProperty for License_timeout'
		SELECT @ret = -1070
 		GOTO ICVRETURN
	END

	EXEC @result = sp_OASetProperty @icvpay, 'Merch_Code', @merch
	IF @result <> 0 
	BEGIN
		EXEC icv_Convert_HRESULT_sp @result, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		EXEC icv_Get_OA_Message_sp @icvpay, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
 		select @response = 'Error: OLE Error on sp_OASetProperty for Merch_code'
		SELECT @ret = -1080
 		GOTO ICVRETURN
	END

	EXEC @result = sp_OASetProperty @icvpay, 'AVS_Mode', @AddressVerification
	IF @result <> 0 
	BEGIN
		EXEC icv_Convert_HRESULT_sp @result, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		EXEC icv_Get_OA_Message_sp @icvpay, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
 		select @response = 'Error: OLE Error on sp_OASetProperty for AVS_mode'
		SELECT @ret = -1090
 		GOTO ICVRETURN
	END

	EXEC @result = sp_OASetProperty @icvpay, 'CC_Number', @ccnumber
	IF @result <> 0 
	BEGIN
		EXEC icv_Convert_HRESULT_sp @result, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		EXEC icv_Get_OA_Message_sp @icvpay, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
 		select @response = 'Error: OLE Error on sp_OASetProperty for CC_number'
		SELECT @ret = -1100
 		GOTO ICVRETURN
	END

	EXEC @result = sp_OASetProperty @icvpay, 'CC_Exp_Month', @ccexpmo
	IF @result <> 0 
	BEGIN
		EXEC icv_Convert_HRESULT_sp @result, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		EXEC icv_Get_OA_Message_sp @icvpay, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
 		select @response = 'Error: OLE Error on sp_OASetProperty for CC_exp_month'
		SELECT @ret = -1110
 		GOTO ICVRETURN	END

	EXEC @result = sp_OASetProperty @icvpay, 'CC_Exp_Year', @ccexpyr 	
	IF @result <> 0 
	BEGIN
		EXEC icv_Convert_HRESULT_sp @result, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		EXEC icv_Get_OA_Message_sp @icvpay, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
 		select @response = 'Error: OLE Error on sp_OASetProperty for CC_exp_year'
		SELECT @ret = -1120
 		GOTO ICVRETURN
	END

	--EXEC @result = sp_OASetProperty @icvpay, 'Order_Total', @ordtotal	
	EXEC @result = sp_OASetProperty @icvpay, 'Order_Total', @ord_total_str
	IF @result <> 0 
	BEGIN
		EXEC icv_Convert_HRESULT_sp @result, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		EXEC icv_Get_OA_Message_sp @icvpay, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
 		select @response = 'Error: OLE Error on sp_OASetProperty for Order_total'
		SELECT @ret = -1130
 		GOTO ICVRETURN
	END

	
	IF @AddressVerification > 0
	BEGIN
		EXEC @result = sp_OASetProperty @icvpay, 'Bill_To_ZIP', @zipcode
		IF @result <> 0 
		BEGIN
			EXEC icv_Convert_HRESULT_sp @result, @response OUT
			EXEC icv_Log_sp @response, @LogActivity
			EXEC icv_Get_OA_Message_sp @icvpay, @response OUT
			EXEC icv_Log_sp @response, @LogActivity
 			select @response = 'Error: OLE Error on sp_OASetProperty for Bill_To_ZIP'
			SELECT @ret = -1131
 			GOTO ICVRETURN
		END

		EXEC @result = sp_OASetProperty @icvpay, 'Bill_To_St', @address
		IF @result <> 0 
		BEGIN
			EXEC icv_Convert_HRESULT_sp @result, @response OUT
			EXEC icv_Log_sp @response, @LogActivity
			EXEC icv_Get_OA_Message_sp @icvpay, @response OUT
			EXEC icv_Log_sp @response, @LogActivity
 			select @response = 'Error: OLE Error on sp_OASetProperty for Bill_To_St'
			SELECT @ret = -1132
 			GOTO ICVRETURN
		END
	END

	-- process pre-authorization transaction
	IF @transtype = 'C6'
	BEGIN
		EXEC @result = sp_OAMethod @icvpay, 'submitauthonlytx'

		
		IF @result = -1021
		BEGIN
			IF @IgnoreAddressFailure = 1
			BEGIN
				SELECT @result = 0
				EXEC icv_Log_sp "AVS failure ignored", @LogActivity
			END
			ELSE
			BEGIN
				SELECT @response = """NNAVS failed"""
				SELECT @ret = -1021
				GOTO ICVRETURN
			END
		END

		IF @result <> 0 
		BEGIN
			EXEC icv_Convert_HRESULT_sp @result, @response OUT
			SELECT @response = @response + " (" + RTRIM(LTRIM(CONVERT(CHAR,@result))) + ")"
			EXEC icv_Log_sp @response, @LogActivity
			EXEC icv_Get_OA_Message_sp @icvpay, @response OUT
			EXEC icv_Log_sp @response, @LogActivity

 			select @response = 'Error: OLE Error on sp_OAMethod for submitauthonlytx'
			SELECT @ret = -1140
	 		GOTO ICVRETURN
		END
	END

	-- process book transaction
	IF @transtype = 'C4'
	BEGIN
		EXEC @result = sp_OAMethod @icvpay, 'submitbooktx'

		
		IF @result = -1021
		BEGIN
			IF @IgnoreAddressFailure = 1
			BEGIN
				SELECT @result = 0
				EXEC icv_Log_sp "AVS failure ignored", @LogActivity
			END
			ELSE
			BEGIN
				SELECT @response = """NNAVS failed"""
				SELECT @ret = -1021
				GOTO ICVRETURN
			END
		END

		IF @result <> 0
		BEGIN
			EXEC icv_Convert_HRESULT_sp @result, @response OUT
			SELECT @response = @response + " (" + RTRIM(LTRIM(CONVERT(CHAR,@result))) + ")"
			EXEC icv_Log_sp @response, @LogActivity
			EXEC icv_Get_OA_Message_sp @icvpay, @response OUT
			EXEC icv_Log_sp @response, @LogActivity
			select @response = 'Error: OLE Error on sp_OAMethod for submitbooktx'
			SELECT @ret = -1150
	 		GOTO ICVRETURN
		END
	END 

	-- process ship transaction
	IF @transtype = 'CO'
	BEGIN
		EXEC @result = sp_OAMethod @icvpay, 'submitshiptx'

		
		IF @result = -1021
		BEGIN
			IF @IgnoreAddressFailure = 1
			BEGIN
				SELECT @result = 0
				EXEC icv_Log_sp "AVS failure ignored", @LogActivity
			END
			ELSE
			BEGIN
				SELECT @response = """NNAVS failed"""
				SELECT @ret = -1021
				GOTO ICVRETURN
			END
		END

		IF @result <> 0 
		BEGIN
			EXEC icv_Convert_HRESULT_sp @result, @response OUT
			SELECT @response = @response + " (" + RTRIM(LTRIM(CONVERT(CHAR,@result))) + ")"
			EXEC icv_Log_sp @response, @LogActivity
			EXEC icv_Get_OA_Message_sp @icvpay, @response OUT
			EXEC icv_Log_sp @response, @LogActivity
 			select @response = 'Error: OLE Error on sp_OAMethod for submitshiptx'
			SELECT @ret = -1160
	 		GOTO ICVRETURN
		END
	END 

	-- process sale transaction
	IF @transtype = 'C1'
	BEGIN
		EXEC @result = sp_OAMethod @icvpay, 'submitsaletx'

		
		IF @result = -1021
		BEGIN
			IF @IgnoreAddressFailure = 1
			BEGIN
				SELECT @result = 0
				EXEC icv_Log_sp "AVS failure ignored", @LogActivity
			END
			ELSE
			BEGIN
				SELECT @response = """NNAVS failed"""
				SELECT @ret = -1021
				GOTO ICVRETURN
			END
		END

		IF @result <> 0 
		BEGIN
			EXEC icv_Convert_HRESULT_sp @result, @response OUT
			SELECT @response = @response + " (" + RTRIM(LTRIM(CONVERT(CHAR,@result))) + ")"
			EXEC icv_Log_sp @response, @LogActivity
			EXEC icv_Get_OA_Message_sp @icvpay, @response OUT
			EXEC icv_Log_sp @response, @LogActivity
 			select @response = 'Error: OLE Error on sp_OAMethod for submitsaletx'
			SELECT @ret = -1170
	 		GOTO ICVRETURN
		END
	END

	-- process credit GOTO ICVRETURN transaction	
	IF @transtype = 'C3'
	BEGIN
		EXEC @result = sp_OAMethod @icvpay, 'submitcreditreturntx'

		
		IF @result = -1021
		BEGIN
			IF @IgnoreAddressFailure = 1
			BEGIN
				SELECT @result = 0
				EXEC icv_Log_sp "AVS failure ignored", @LogActivity
			END
			ELSE
			BEGIN
				SELECT @response = """NNAVS failed"""
				SELECT @ret = -1021
				GOTO ICVRETURN
			END
		END

		IF @result <> 0 
		BEGIN
			EXEC icv_Convert_HRESULT_sp @result, @response OUT
			SELECT @response = @response + " (" + RTRIM(LTRIM(CONVERT(CHAR,@result))) + ")"
			EXEC icv_Log_sp @response, @LogActivity
			EXEC icv_Get_OA_Message_sp @icvpay, @response OUT
			EXEC icv_Log_sp @response, @LogActivity
 			select @response = 'Error: OLE Error on sp_OAMethod for submitcreditreturntx'
			SELECT @ret = -1180
 			GOTO ICVRETURN
		END
	END 

	-- process void GOTO ICVRETURN transaction	
	IF @transtype = 'C2'
	BEGIN
		EXEC @result = sp_OAMethod @icvpay, 'SubmitVoidSaleTx'

		
		IF @result = -1021
		BEGIN
			IF @IgnoreAddressFailure = 1
			BEGIN
				SELECT @result = 0
				EXEC icv_Log_sp "AVS failure ignored", @LogActivity
			END
			ELSE
			BEGIN
				SELECT @response = """NNAVS failed"""
				SELECT @ret = -1021
				GOTO ICVRETURN
			END
		END

		IF @result <> 0 
		BEGIN
			EXEC icv_Convert_HRESULT_sp @result, @response OUT
			SELECT @response = @response + " (" + RTRIM(LTRIM(CONVERT(CHAR,@result))) + ")"
			EXEC icv_Log_sp @response, @LogActivity
			EXEC icv_Get_OA_Message_sp @icvpay, @response OUT
			EXEC icv_Log_sp @response, @LogActivity
 			select @response = 'Error: OLE Error on sp_OAMethod for SubmitVoidSaleTx'
			SELECT @ret = -1180
 			GOTO ICVRETURN
		END
	END 

	-- process force
	IF @transtype = 'C5'
	BEGIN
		EXEC @result = sp_OAMethod @icvpay, 'SubmitForceSaleTx'

		
		IF @result = -1021
		BEGIN
			IF @IgnoreAddressFailure = 1
			BEGIN
				SELECT @result = 0
				EXEC icv_Log_sp "AVS failure ignored", @LogActivity
			END
			ELSE
			BEGIN
				SELECT @response = """NNAVS failed"""
				SELECT @ret = -1021
				GOTO ICVRETURN
			END
		END

		IF @result <> 0 
		BEGIN
			EXEC icv_Convert_HRESULT_sp @result, @response OUT
			SELECT @response = @response + " (" + RTRIM(LTRIM(CONVERT(CHAR,@result))) + ")"
			EXEC icv_Log_sp @response, @LogActivity
			EXEC icv_Get_OA_Message_sp @icvpay, @response OUT
			EXEC icv_Log_sp @response, @LogActivity
 			select @response = 'Error: OLE Error on sp_OAMethod for SubmitForceSaleTx'
			SELECT @ret = -1180
 			GOTO ICVRETURN
		END
	END 


	-- get response from ICVerify
	EXEC @result = sp_OAGetProperty @icvpay, 'ICVAns', @response OUT
	IF @result <> 0 
	BEGIN
		EXEC icv_Convert_HRESULT_sp @result, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		EXEC icv_Get_OA_Message_sp @icvpay, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
 		select @response = 'Error: OLE Error on sp_OAGetProperty 9'
		SELECT @ret = -1190
 		GOTO ICVRETURN
	END

	EXEC @result = sp_OADestroy @icvpay
	IF @result <> 0 
	BEGIN
		EXEC icv_Convert_HRESULT_sp @result, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		EXEC icv_Get_OA_Message_sp @icvpay, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
 		select @response = 'Error: OLE Error on sp_OADestroy'
		SELECT @ret = -1200
 		GOTO ICVRETURN
	END

ICVRETURN:
	RETURN @ret
END
GO
GRANT EXECUTE ON  [dbo].[icv_icverify] TO [public]
GO
