SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO









       
Create Procedure [dbo].[icv_fs_trans]
	@transtype CHAR(3), 
	@ccnumber varCHAR(20), 
	@ccexpmo CHAR(2), 
	@ccexpyr CHAR(4), 
	@ordtotal Decimal(20,8),
	@response VARCHAR(60) OUTPUT,
	@order_no int = 0,
	@ext int = 0,
	@prompt1 CHAR(30) = '',
	@trx_ctrl_num VARCHAR(16) = '',
	@customer_code VARCHAR(8)='',
	@nat_cur_code varchar(8) = '',
	@IAS_TrxType smallint,
	@csc	varchar(5) = ''
As

--	Developer:	Ricardo Maduro
--	Date:		05/05/1999
--	Description:	ICVerify Integration - this procedure will perform the task of interfacing with ICVerify. It will write .req
--                      files to a specified directory for a single ICVerify authorization transaction, and will GOTO ICVRETURN the result
--                      of the transaction. 			
			













BEGIN
	DECLARE @buf			CHAR(255)
	DECLARE	@LogActivity		CHAR(3)
	DECLARE	@processor		INT
	DECLARE	@processor_name		CHAR(255)
	DECLARE @ret 			INT



	SELECT @buf = UPPER(configuration_text_value)
	  FROM icv_config
	 WHERE UPPER(configuration_item_name) = 'LOG ACTIVITY'

	IF @@rowcount <> 1
		SELECT @buf = 'NO'

	IF @buf = 'YES'
	BEGIN
		SELECT @LogActivity = 'YES'
	END
	ELSE
	BEGIN
		SELECT @LogActivity = 'NO'
	END

	SELECT 	@processor_name = configuration_text_value, 
		@processor = configuration_int_value
	  FROM icv_config
	 WHERE UPPER(configuration_item_name) = 'PROCESSOR INTERFACE'


	SELECT @buf = 'Entering icv_fs_trans;  Processor: '  + RTRIM(LTRIM(@processor_name)) + ' (' + RTRIM(LTRIM(CONVERT(CHAR, @processor))) + ')'
	EXEC icv_Log_sp @buf, @LogActivity

	


	IF @processor = 0
	BEGIN
	  
		GOTO ICVRETURN
	END
	
	


	IF @processor = 1
	BEGIN
		if @nat_cur_code <> 'USD'
		begin
		  SELECT @buf = 'Currency of transaction: ' + @nat_cur_code
		  EXEC icv_Log_sp @buf, @LogActivity
		end
		EXEC @ret = icv_trustmarque @transtype, @ccnumber, @ccexpmo, @ccexpyr, @ordtotal, @response OUTPUT, @order_no, @ext, 	@prompt1, @trx_ctrl_num, @customer_code, @nat_cur_code, @IAS_TrxType, @csc
		GOTO ICVRETURN
	END

	

	IF @processor = 2
	BEGIN

        select @buf = 'Going to icv_verisign ' 
	EXEC icv_Log_sp @buf, 'YES'

		EXEC @ret = icv_verisign @transtype, @ccnumber, @ccexpmo, @ccexpyr, @ordtotal, @response OUTPUT, @order_no, @ext, 	@prompt1, @trx_ctrl_num, @customer_code, @nat_cur_code, @IAS_TrxType, @csc
	
	select @buf = 'Back from icv_versign ' + @response
	EXEC icv_Log_sp @buf, 'YES'	
		
		GOTO ICVRETURN
	END


ICVRETURN:
	EXEC icv_Log_sp @response, @LogActivity
	RETURN @ret
	
END
GO
GRANT EXECUTE ON  [dbo].[icv_fs_trans] TO [public]
GO
