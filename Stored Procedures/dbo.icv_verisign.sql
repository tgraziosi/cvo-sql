SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO





















                                                


 
CREATE PROCEDURE [dbo].[icv_verisign] @transtype CHAR(3),
				 @ccnumber varCHAR(20),
				 @ccexpmo varchar(2),
				 @ccexpyr varchar(4),
				 @ordtotal Decimal(20,8),
				 @Response VARCHAR(255) OUTPUT,
				 @order_no int = 0,
 				 @ext int = 0,
				 @prompt1 varchar(30) = '',
				 @trx_ctrl_num VARCHAR(16) = '',
				 @ar_customer_code VARCHAR(8) = '',
				 @nat_cur_code varchar(8) = '',
				 @IAS_TrxType smallint,
				 @csc varchar(5) = ''
				WITH RECOMPILE 
AS
BEGIN
    DECLARE @request        VARCHAR(1023)           --Added 8/10/01 for VeriSign
    DECLARE @Partner        VARCHAR(255)		 --Added 8/10/01 for VeriSign
	DECLARE @buf			CHAR(255)
	DECLARE @filename		CHAR(255)
	DECLARE	@LogActivity		CHAR(3)
	DECLARE @AddressVerification	VARCHAR(3)  --added 2/5/03 FF
	DECLARE	@IgnoreAddressFailure	INT		--added 2/5/03 FF
        DECLARE @IgnoreAddressFailureSTR   Varchar(3)	--added 2/5/03 FF
	DECLARE @LevelIICompliance	INT
	DECLARE	@IPAddress		CHAR(30)
	DECLARE @HostAdd                VARCHAR(255)       --Added 8/10/01 for VeriSign
	DECLARE @Port			CHAR(6)
	DECLARE @DemoMode		CHAR(1)
	DECLARE @MerchantID		VARCHAR(255)
	DECLARE @UserName		VARCHAR(255)
	DECLARE @UserPassword		VARCHAR(255)
	DECLARE @Timeout 		VARCHAR(255)
	DECLARE @status			CHAR(1)
	DECLARE @vsif 			INT
	DECLARE @ord_total_str 		VARCHAR(20)
	DECLARE @AcctType		CHAR(2)
	DECLARE @zipcode		varchar(30)
	DECLARE @address		varchar(30)
	DECLARE @ix			INT
	DECLARE	@trx_type		CHAR
	DECLARE @result 		INT
	DECLARE @ret 			INT
	DECLARE	@AVSAddr		varCHAR(1)
	DECLARE @AVSZip			varCHAR(1)
	DECLARE @RespMsg		VARCHAR(255)
	DECLARE @AuthCode		VARCHAR(255)
	DECLARE @Comment1		VARCHAR(255)
	DECLARE @Comment2		VARCHAR(255)
	DECLARE @payment_code		CHAR(8)
	--DECLARE @nat_cur_code		CHAR(8)
	DECLARE @CurrencyID		CHAR(3)
	DECLARE @debug_level		INT
	DECLARE @PTTID			varchar(20)
	DECLARE @orig_no		INT
	DECLARE @orig_ext		INT
	DECLARE @submitcommand  varCHAR(1024)			 --Added 8/10/01 for VeriSign -- increased to 1024 6/2/03
	DECLARE @submitcommandmask  varCHAR(1024)		 -- logging masked accounts - CCA - 10/26/05	
	DECLARE @pointer		 int			 --Added 8/10/01 for VeriSign
        DECLARE @begpos 		int  			 --Added 8/10/01 for VeriSign
        DECLARE @vlength	    int				 --Added 8/10/01 for VeriSign
        DECLARE @resultcontext       int		 --Added 8/10/01 for VeriSign
        DECLARE @fullstring      varCHAR(255)		 --Added 8/10/01 for VeriSign
        DECLARE @searchname      varCHAR(255)		 --Added 8/10/01 for VeriSign
        DECLARE @ResultString    varCHAR(255)		 --Added 8/10/01 for VeriSign
	DECLARE @temp		varchar(50)
	DECLARE @temp2		varchar(15)
 	DECLARE @requeststr     varchar(1024)            -- increased size 6/2/03
	DECLARE @requeststrmask     varchar(1024)            -- logging masked accounts - CCA - 10/26/05
	DECLARE @ResultCode varchar(255)			-- mls 11/24/03 SCR 32136
	DECLARE @customer_code varchar(12)  -- FF 6/2/03
	DECLARE @Entered_By	varchar(32) -- FF 6/2/03
	DECLARE @order_no_str  varchar(8)  -- FF 6/2/03
	DECLARE @ext_str       varchar(3)  -- FF 6/2/03
	DECLARE @reference 	varchar(16)
	DECLARE @cca_trx_ctrl_num  varchar(20)
	DECLARE @IAS_Account_Exists varchar(300)
	DECLARE @is_order smallint
	DECLARE @companycode varchar(8)
	DECLARE @cash_trx_ctrl_num varchar(16)
	DECLARE @exist_orders_table int  


	DECLARE @cvv2match	varchar(1)
	DECLARE @res_net	nvarchar(255)

			
	select @exist_orders_table = 0
	SELECT @exist_orders_table = ISNULL( (SELECT 1 FROM sysobjects WHERE name = 'orders') , 0 )


	declare @auth_resp_flag char(1), @auth_approval_code varchar(6), @auth_reference_no varchar(12), @auth_trans_type varchar(4), 	-- mls 1/22/04 SCR 32358
          @auth_seq int, @auth_ord_amt decimal(20,8)											-- mls 1/22/04 SCR 32358


	if convert(int,@ccexpmo) < 10									-- mls 10/13/05
	  select @ccexpmo = '0' + convert(varchar(1),convert(int,@ccexpmo))


	IF( @order_no=0)
	BEGIN
	SELECT @is_order =0
	END
	ELSE
	BEGIN
		SELECT @is_order =1
	END
	SELECT @companycode = company_code from glco
	SELECT 	@IAS_Account_Exists = ''
	IF(@transtype in ('C0','CO','C1','C2','C4','C5','C6'))
	BEGIN
	SELECT @IAS_Account_Exists= ccnumber from CVO_Control..ccacryptaccts 
	WHERE  	(	  trx_ctrl_num = @trx_ctrl_num
						  AND trx_type = @IAS_TrxType
	   					  AND @is_order =0
						  AND company_code = @companycode  
					)
					OR 	( order_no = @order_no
						  AND order_ext = @ext
						  AND @is_order =1 
						  AND company_code = @companycode  
						)
	END

	IF (@transtype = 'C3')	
	BEGIN
		IF @is_order = 1
          	BEGIN
          		IF @exist_orders_table = 1
		        BEGIN
          	
			SELECT	@orig_no = ISNULL(orig_no,0),
				@orig_ext = ISNULL(orig_ext,0)
			  FROM	orders
			 WHERE	order_no = @order_no
			   AND	ext = @ext

			SELECT @IAS_Account_Exists= ccnumber from CVO_Control..ccacryptaccts 
			WHERE  	( order_no = @orig_no
				  AND order_ext = @orig_ext
				  AND company_code = @companycode  )
		        END
		END
	END

	IF(@transtype = 'C7' AND @is_order = 0)
	BEGIN
	
		SELECT @cash_trx_ctrl_num = trx.trx_ctrl_num FROM artrx trx
		INNER JOIN arinppyt pyt
		ON trx.doc_ctrl_num = pyt.doc_ctrl_num
		WHERE pyt.trx_ctrl_num = @trx_ctrl_num AND pyt.trx_type = 2121
	
		SELECT @IAS_Account_Exists = ccnumber from CVO_Control..ccacryptaccts 
		WHERE 	trx_ctrl_num = @cash_trx_ctrl_num
			AND trx_type = 2111
			AND company_code = @companycode  
	END

	IF(@IAS_Account_Exists<>'')
	BEGIN
		SELECT @ccnumber = dbo.CCADecryptAcct_fn(@IAS_Account_Exists)
	END
	ELSE
	BEGIN
		IF(@transtype in ('C1','C6','C4','C0','CO','C3'))
		BEGIN
		RETURN 5005
		END
	END
	


	SELECT @Entered_By = '', @customer_code = ''
	IF @exist_orders_table = 1
	BEGIN
	   SELECT @Entered_By = who_entered, @customer_code = cust_code 
	          from orders where order_no = @order_no and ext = @ext
	END
	SELECT @order_no_str = convert(varchar(8),@order_no)
	SELECT @ext_str = convert(varchar(3), @ext)
	

	SELECT @trx_type = ''
        SELECT @ccexpyr = RTRIM(RIGHT(@ccexpyr,2))
        SELECT @prompt1 = RTRIM(@prompt1)


-- Start Rev 1.1 - This part of the code was added to obtain the correct trx_ctrl_num from Cash Recipet Adjustment
	--	     from artrx	
	IF @transtype='C7'
	BEGIN
		SELECT @transtype='C3'
		SELECT @reference=@trx_ctrl_num
		SELECT @trx_ctrl_num=trx_ctrl_num
		FROM artrx
		WHERE doc_ctrl_num=@trx_ctrl_num
		AND trx_type=2111
		AND customer_code=@ar_customer_code
	END
	--End Rev 1.1	

	SET NOCOUNT ON

	SELECT @vsif = 0, @filename = "C:\tmif.log"


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


	SELECT @debug_level = 0
	SELECT @debug_level = configuration_int_value
	 FROM icv_config
	 WHERE UPPER(configuration_item_name) = 'DEBUG LEVEL'

	SELECT @buf = UPPER(configuration_text_value)
	 FROM icv_config
	 WHERE UPPER(configuration_item_name) = 'DEMO MODE'

	IF @@rowcount <> 1
		SELECT @buf = 'NO'
	SELECT @DemoMode = SUBSTRING(@buf,1,1)


   
	SELECT @Partner = 'No Partner'
	SELECT @Partner  =  configuration_text_value
	 FROM icv_config
	 WHERE UPPER(configuration_item_name) = 'PARTNER'

	IF @@rowcount <> 1
	BEGIN
		SELECT @Response = 'Error: Partner not defined'
		SELECT @ret = -1010
 		GOTO ICVRETURN
	END

	
	SELECT @HostAdd = "" 
	SELECT @HostAdd  = (configuration_text_value)
	 FROM icv_config
	 WHERE UPPER(configuration_item_name) = 'HOST ADDRESS'

	IF @@rowcount <> 1
	BEGIN
		SELECT @Response = 'Error: Host Address not defined'
		SELECT @ret = -1010
 		GOTO ICVRETURN
	END

	
        SELECT @MerchantID = ""
	SELECT @MerchantID =  (configuration_text_value)
	 FROM icv_config
	 WHERE UPPER(configuration_item_name) = 'MERCHANTID'

	IF @@rowcount <> 1
	BEGIN
		SELECT @Response = 'Error: MerchantID not defined'
		SELECT @ret = -1010
 		GOTO ICVRETURN
	END
        SELECT @UserName = ""
	SELECT @UserName =   (configuration_text_value)
	 FROM icv_config
	 WHERE UPPER(configuration_item_name) = 'USERNAME'

	IF @@rowcount <> 1
	BEGIN
		SELECT @Response = 'Error: UserName not defined'
		SELECT @ret = -1010
 		GOTO ICVRETURN
	END
        SELECT @UserPassword = ""
	SELECT @UserPassword = LTRIM(RTRIM((configuration_text_value)))
	 FROM icv_config
	 WHERE UPPER(configuration_item_name) = 'USERPASSWORD'

	IF @@rowcount <> 1
	BEGIN
		SELECT @Response = 'Error: UserPassword not defined'
		SELECT @ret = -1010
 		GOTO ICVRETURN
	END
        SELECT @Port = ""
        SELECT @Port = (configuration_text_value)
	 FROM icv_config
	 WHERE UPPER(configuration_item_name) = 'GATEWAY PORT'

	IF @@rowcount <> 1
	BEGIN
		SELECT @Response = 'Error: Gateway Port not defined'
		SELECT @ret = -1010
 		GOTO ICVRETURN
	END
	SELECT @Timeout = ""
	SELECT @Timeout =  (configuration_text_value)
	 FROM icv_config
	 WHERE UPPER(configuration_item_name) = 'TIMEOUT'

	IF @@rowcount <> 1
	BEGIN
		SELECT @Response = 'Error: Timeout not defined'
		SELECT @ret = -1010
 		GOTO ICVRETURN
	END

	SELECT @AddressVerification = ""
	SELECT @AddressVerification =  (configuration_text_value)
	 FROM icv_config
	 WHERE UPPER(configuration_item_name) = 'ADDRESS VERIFICATION'

	IF @@rowcount <> 1
	BEGIN
		SELECT @Response = 'Error: Address Verification not specified'
		SELECT @ret = -1010
 		GOTO ICVRETURN
	END
	
--added 2/5/03 FF
	SELECT @IgnoreAddressFailure = 0
	SELECT @IgnoreAddressFailureSTR =  (configuration_text_value)
	 FROM icv_config
	 WHERE UPPER(configuration_item_name) like 'IGNORE ADDRESS%'

	
	IF @@rowcount <> 1
	BEGIN
		SELECT @Response = 'Error: Ignore Address Verification Failure not specified'
		SELECT @ret = -1010
 		GOTO ICVRETURN
	END 

	IF LEFT(@IgnoreAddressFailureSTR,1) = 'Y'
          SELECT @IgnoreAddressFailure = 1

	SELECT @buf = 'Debug Level'+ RTRIM(LTRIM(CONVERT(CHAR, @debug_level)))
	EXEC icv_Log_sp @buf, @LogActivity
	
       SELECT @status = ''
       IF @exist_orders_table = 1 
       BEGIN
		SELECT @status = status 
		 FROM orders (nolock)
		 WHERE order_no = @order_no AND ext = @ext
       END

	IF (@status = 'V')
	BEGIN
          select @auth_resp_flag = response_flag,						-- mls 1/22/04 SCR 32358 start
            @auth_approval_code = approval_code,
            @auth_reference_no = reference_no,
            @auth_trans_type = trans_type,
            @auth_seq = sequence,
            @auth_ord_amt = ord_amt
          from icv_ord_payment_dtl (nolock)
          where order_no = @order_no and ext = @ext and auth_sequence = 0

          if @@rowcount = 0
            select @auth_resp_flag = '', @auth_ord_amt = 0, @auth_approval_code = '', @auth_seq = 1
	
          IF @auth_resp_flag in ('S','C','V','D')						-- mls 1/22/04 SCR 32358 - added D to list
          BEGIN
            SELECT @buf = 'Void to Verisign and Immediate return from icv_verisign because order ' + RTRIM(LTRIM(CONVERT(CHAR,@order_no))) + ',' + RTRIM(LTRIM(CONVERT(CHAR,@ext))) + ' has a status of ' + @status + ''
            EXEC icv_Log_sp @buf, @LogActivity
            SELECT @ret = -1310
            SELECT @Response = '"NORDER IS VOID"'
            GOTO ICVRETURN
          end

          IF @auth_resp_flag = ''
          BEGIN
            SELECT @buf = 'Transaction was never Authorized'
            EXEC icv_Log_sp @buf, @LogActivity
            SELECT @Response = '"NTransaction was never Authorized"'
            SELECT @ret = -1300
            GOTO ICVRETURN
          end

          select @transtype = 'C2'
          select @ordtotal = @auth_ord_amt							-- mls 1/22/04 SCR 32358 start
	END
		
	SELECT @trx_type = ''
	-- Authorization transaction
	IF @transtype = 'C6'
		SELECT @trx_type = 'A'
	-- Book transaction
	IF @transtype = 'C4'
		SELECT @trx_type = 'A'
	-- Ship transaction
	IF @transtype in ( 'C0', 'CO')
		SELECT @trx_type = 'D'
	-- Sale transaction
	IF @transtype = 'C1'
		SELECT @trx_type = 'S'
	-- Credit return transaction	
	IF @transtype = 'C3'
		SELECT @trx_type = 'C'
	-- Void transaction									-- mls 1/22/04 SCR 32358
	IF @transtype = 'C2'
		SELECT @trx_type = 'V'

	IF @trx_type <> ''
	BEGIN
		IF EXISTS (SELECT 1 FROM icv_ord_payment_dtl WHERE order_no = @order_no AND ext = @ext 
		AND case when response_flag in ('B','A') then 'A' else response_flag end = @trx_type 	-- mls 12/23/03 SCR 32256
		AND DATALENGTH(RTRIM(LTRIM(approval_code))) > 0)
		BEGIN
		  if not exists (select 1 from icv_ord_payment_dtl where order_no = @order_no and ext = @ext	-- mls 12/23/03 SCR 32256 start
		  and auth_sequence = 0) and @trx_type = 'A'
		  begin
		    INSERT INTO icv_ord_payment_dtl (order_no, ext, sequence, auth_sequence, response_flag, rej_reason, 
		      approval_code, reference_no, avs_result, proc_date, ord_amt, trans_type) 
		    select TOP 1
		      order_no, ext, sequence, 0, @trx_type, rej_reason, approval_code, reference_no, avs_result,
		      getdate(), ord_amt, trans_type
		    from icv_ord_payment_dtl
		    where order_no = @order_no and ext = @ext and trans_type in ('C6','C4')
 		  end												-- mls 12/23/03 SCR 32256 end

		  select @auth_approval_code = approval_code
                  from icv_ord_payment_dtl
                  where order_no = @order_no and ext = @ext and auth_sequence = 0

                  SELECT @buf = 'Transaction has already been performed for this order'
		  EXEC icv_Log_sp @buf, @LogActivity
		  SELECT @Response = '"Y' + isnull(@auth_approval_code,'999998') + '"' 
		  SELECT @ret = -1300
		  GOTO ICVRETURN
		END
	END
	
	IF ISNULL(DATALENGTH(RTRIM(LTRIM(@prompt1))),0) = 0
	BEGIN
		IF @exist_orders_table = 1
		BEGIN
			SELECT @prompt1 = prompt1_inp,
			 @payment_code = payment_code
			 FROM ord_payment (nolock)
			 WHERE order_no = @order_no
			 AND order_ext = @ext
		END
	END

	SELECT @nat_cur_code = ''
	IF @exist_orders_table = 1
	BEGIN
	   SELECT @nat_cur_code = curr_key
	    FROM orders
	    WHERE order_no = @order_no
	    AND ext = @ext
	END
	

	SELECT @CurrencyID = '840'
	IF @nat_cur_code = 'USD' SELECT @CurrencyID = '840'
	IF @nat_cur_code = 'AUD' SELECT @CurrencyID = '36 '
	IF @nat_cur_code = 'ATS' SELECT @CurrencyID = '40 '
	IF @nat_cur_code = 'CAD' SELECT @CurrencyID = '124'
	IF @nat_cur_code = 'DKK' SELECT @CurrencyID = '208'
	IF @nat_cur_code = 'FRF' SELECT @CurrencyID = '250'
	IF @nat_cur_code = 'DEM' SELECT @CurrencyID = '280'
	IF @nat_cur_code = 'HKD' SELECT @CurrencyID = '344'
	IF @nat_cur_code = 'IEP' SELECT @CurrencyID = '372'
	IF @nat_cur_code = 'ITL' SELECT @CurrencyID = '380'
	IF @nat_cur_code = 'JPY' SELECT @CurrencyID = '392'
	IF @nat_cur_code = 'NLG' SELECT @CurrencyID = '528'
	IF @nat_cur_code = 'SGD' SELECT @CurrencyID = '702'
	IF @nat_cur_code = 'ZAR' SELECT @CurrencyID = '710'
	IF @nat_cur_code = 'ESP' SELECT @CurrencyID = '724'
	IF @nat_cur_code = 'SEK' SELECT @CurrencyID = '752'
	IF @nat_cur_code = 'CHF' SELECT @CurrencyID = '756'
	IF @nat_cur_code = 'GBP' SELECT @CurrencyID = '826'
	IF @nat_cur_code = 'EUR' SELECT @CurrencyID = '978'
		
	IF ISNULL(DATALENGTH(RTRIM(LTRIM(@prompt1))),0) = 0
	BEGIN
		SELECT @prompt1 = 'CCAUSER'
	END

	IF LEFT(@AddressVerification,1) = 'Y'
	BEGIN

		SELECT @ix = CHARINDEX('/',@prompt1)				
		IF @ix <= 1 OR @ix >= DATALENGTH(RTRIM(LTRIM(@prompt1)))
		BEGIN
			SELECT @buf = 'Invalid prompt1 when AVS_MODE is on: ' + @prompt1
			EXEC icv_Log_sp @buf, @LogActivity
			SELECT @buf = 'AVS_MODE will be turned off for this transaction'
			EXEC icv_Log_sp @buf, @LogActivity
			SELECT @AddressVerification = 'N'
		END
		ELSE
		BEGIN
			SELECT @zipcode = SUBSTRING( @prompt1, 1, @ix-1 ),
			 @address = RTRIM(SUBSTRING( @prompt1, @ix+1, DATALENGTH(@prompt1) ))
			SELECT @buf = 'Zip: ' + @zipcode + ' Address: ' + @address
			EXEC icv_Log_sp @buf, @LogActivity
		END
	END


	Select @ord_total_str = RTRIM(LTRIM(STR(@ordtotal,18,2))),
		@ret = 0



	-- Instantiate the ole object	















































	-- Convert book to ship OR Return or void.  All require the PNREF to be included

	IF @transtype in ( 'C0', 'C3', 'C2', 'CO')			-- mls 1/22/04 SCR 32358
	BEGIN
		IF @transtype in ('C0' , 'C2', 'CO' )
		BEGIN
			
			






			
			SELECT  @AuthCode=SUBSTRING(prompt4_inp,0, CASE (CHARINDEX(':', prompt4_inp)) WHEN 0 THEN 7 ELSE CHARINDEX(':', prompt4_inp) END) ,
				@PTTID=SUBSTRING(prompt4_inp,CHARINDEX(':', prompt4_inp)+1, LEN(prompt4_inp)-CHARINDEX(':', prompt4_inp))
			  FROM	arinppyt 
			 WHERE trx_ctrl_num= @trx_ctrl_num
			
			
			IF LEN(ISNULL(@AuthCode,''))= 0  OR
		  		LEN(ISNULL(@PTTID,''))= 0  
			BEGIN
				SELECT  @AuthCode=SUBSTRING(prompt4_inp,0, CASE (CHARINDEX(':', prompt4_inp)) WHEN 0 THEN 7 ELSE CHARINDEX(':', prompt4_inp) END) ,
				@PTTID=SUBSTRING(prompt4_inp,CHARINDEX(':', prompt4_inp)+1, LEN(prompt4_inp)-CHARINDEX(':', prompt4_inp))
			 	FROM	arinptmp 
				WHERE trx_ctrl_num= @trx_ctrl_num
				
			END

			IF LEN(ISNULL(@AuthCode,''))= 0  OR
			  		LEN(ISNULL(@PTTID,''))= 0  
				BEGIN
				SELECT  @PTTID = ISNULL(reference_no, '')
				  FROM	icv_ord_payment_dtl
				 WHERE	order_no = @order_no
				   AND	ext = @ext
				   AND	auth_sequence = 0
			END
			
		END

		IF @transtype IN ('C3','C2')
		BEGIN	











			-- Rev 1.0 Cyanez  This was modified to fill @AuthCode and @PTTID with AR Data
			SELECT  @AuthCode=SUBSTRING(prompt4_inp,0, CASE (CHARINDEX(':', prompt4_inp)) WHEN 0 THEN 7 ELSE CHARINDEX(':', prompt4_inp) END) ,
				@PTTID=SUBSTRING(prompt4_inp,CHARINDEX(':', prompt4_inp)+1, LEN(prompt4_inp)-CHARINDEX(':', prompt4_inp))
			  FROM	arinppyt 
			 WHERE trx_ctrl_num= @trx_ctrl_num
			
			
			IF LEN(ISNULL(@AuthCode,''))= 0  OR
		  		LEN(ISNULL(@PTTID,''))= 0  
			BEGIN
				SELECT  @AuthCode=SUBSTRING(prompt4_inp,0, CASE (CHARINDEX(':', prompt4_inp)) WHEN 0 THEN 7 ELSE CHARINDEX(':', prompt4_inp) END) ,
				@PTTID=SUBSTRING(prompt4_inp,CHARINDEX(':', prompt4_inp)+1, LEN(prompt4_inp)-CHARINDEX(':', prompt4_inp))
			 	FROM	arinptmp 
				WHERE trx_ctrl_num= @trx_ctrl_num
				
			END

			IF LEN(ISNULL(@AuthCode,''))= 0  OR
		  		LEN(ISNULL(@PTTID,''))= 0  
			BEGIN
				SELECT  @AuthCode=SUBSTRING(prompt4_inp,0, CASE (CHARINDEX(':', prompt4_inp)) WHEN 0 THEN 7 ELSE CHARINDEX(':', prompt4_inp) END) ,
				@PTTID=SUBSTRING(prompt4_inp,CHARINDEX(':', prompt4_inp)+1, LEN(prompt4_inp)-CHARINDEX(':', prompt4_inp))
			 	FROM	artrx 
				WHERE trx_ctrl_num= @cash_trx_ctrl_num
	
			END
			IF LEN(ISNULL(@AuthCode,''))= 0  OR
		  		LEN(ISNULL(@PTTID,''))= 0  
			BEGIN
				IF @exist_orders_table = 1
		                BEGIN
					SELECT	@orig_no = ISNULL(orig_no,0),
						@orig_ext = ISNULL(orig_ext,0)
					  FROM	orders
					 WHERE	order_no = @order_no
					   AND	ext = @ext
					SELECT  @AuthCode = ISNULL(approval_code, ''),
						@PTTID = ISNULL(reference_no, '')
					  FROM	icv_ord_payment_dtl
					 WHERE	order_no = @orig_no
					   AND	ext = @orig_ext
					   AND	auth_sequence = 0
					SELECT @reference = RTRIM(LTRIM(CONVERT(CHAR, @orig_no))) + '.' + RTRIM(LTRIM(CONVERT(CHAR, @ext)))
			        END 
			END
			-- Rev 1.0 Cyanez  This was modified to fill @AuthCode and @PTTID with AR Data
		END

		SELECT @buf = '1. AuthCode: ' + ISNULL(@AuthCode, 'NULL') + ', PTTID: ' + ISNULL(@PTTID, 'NULL')
		EXEC icv_Log_sp @buf, @LogActivity

	   	SELECT @temp2 = '&'
		SELECT @requeststr = ''
		SELECT @requeststr = @requeststr + 'PARTNER=' + @Partner + @temp2
	  	SELECT @requeststr = @requeststr + 'USER=' + isnull(@UserName,'no user') + @temp2
		SELECT @requeststr = @requeststr + 'VENDOR=' + isnull(@UserName,'no vendor') + @temp2
	        SELECT @requeststr = @requeststr + 'PWD=' + isnull(@UserPassword,'no pwd') + @temp2
		SELECT @requeststr = @requeststr + 'TENDER=C'   + @temp2
		SELECT @requeststr = @requeststr + 'TRXTYPE=' + isnull(@trx_type,'no trxtype') + @temp2
		SELECT @requeststr = @requeststr + 'ACCT=' + isnull(@ccnumber,'no acct') + @temp2
		SELECT @requeststr = @requeststr + 'EXPDATE=' + isnull(@ccexpmo,'no expdate')+isnull(@ccexpyr,'') + @temp2
		SELECT @requeststr = @requeststr + 'AMT=' + isnull(@ord_total_str,'no amt') + @temp2
		IF @AddressVerification = 'Y'
		BEGIN
			SELECT @requeststr = @requeststr + 'ZIP=' + isnull(@zipcode,'') + @temp2
			SELECT @requeststr = @requeststr + 'STREET=' + isnull(@address,'') + @temp2
		END
		SELECT @requeststr = @requeststr + 'COUNTRY=' + isnull(@CurrencyID,'currency id') + @temp2
		IF ISNULL(DATALENGTH(RTRIM(LTRIM(@trx_ctrl_num))),0) > 0
			SELECT @requeststr = @requeststr + 'COMMENT1=' + isnull(@trx_ctrl_num,'trx_ctrl_num') + @temp2
		SELECT @requeststr = @requeststr + 'COMMENT2=' + @customer_code + '/' + @order_no_str + ',' + @ext_str + '/' + @Entered_By + @temp2  -- FF 6/2/03
		
		SELECT @requeststr = @requeststr + 'ORIGID=' + isnull(@PTTID,'pttid')
		-- building the string to be logged
		SELECT @requeststrmask = ''
		SELECT @requeststrmask = @requeststrmask + 'PARTNER=' + @Partner + @temp2
	  	SELECT @requeststrmask = @requeststrmask + 'USER=' + isnull(@UserName,'no user') + @temp2
		SELECT @requeststrmask = @requeststrmask + 'VENDOR=' + isnull(@UserName,'no vendor') + @temp2
	        SELECT @requeststrmask = @requeststrmask + 'PWD=' + isnull(@UserPassword,'no pwd') + @temp2
		SELECT @requeststrmask = @requeststrmask + 'TENDER=C'   + @temp2
		SELECT @requeststrmask = @requeststrmask + 'TRXTYPE=' + isnull(@trx_type,'no trxtype') + @temp2
		SELECT @requeststrmask = @requeststrmask + 'ACCT=' + isnull(dbo.CCAMask_fn(@ccnumber),'no acct') + @temp2
		SELECT @requeststrmask = @requeststrmask + 'EXPDATE=' + isnull(@ccexpmo,'no expdate')+isnull(@ccexpyr,'') + @temp2
		SELECT @requeststrmask = @requeststrmask + 'AMT=' + isnull(@ord_total_str,'no amt') + @temp2
		IF @AddressVerification = 'Y'
		BEGIN
			SELECT @requeststrmask = @requeststrmask + 'ZIP=' + isnull(@zipcode,'') + @temp2
			SELECT @requeststrmask = @requeststrmask + 'STREET=' + isnull(@address,'') + @temp2
		END
		SELECT @requeststrmask = @requeststrmask + 'COUNTRY=' + isnull(@CurrencyID,'currency id') + @temp2
		IF ISNULL(DATALENGTH(RTRIM(LTRIM(@trx_ctrl_num))),0) > 0
			SELECT @requeststrmask = @requeststrmask + 'COMMENT1=' + isnull(@trx_ctrl_num,'trx_ctrl_num') + @temp2
		SELECT @requeststrmask = @requeststrmask + 'COMMENT2=' + @customer_code + '/' + @order_no_str + ',' + @ext_str + '/' + @Entered_By + @temp2  -- FF 6/2/03
		
		SELECT @requeststrmask = @requeststrmask + 'ORIGID=' + isnull(@PTTID,'pttid')
	END

	-- Authorize, Book, Sale

	IF @transtype = 'C6' OR @transtype = 'C1' OR @transtype = 'C4'
	BEGIN

	   	SELECT @temp2 = '&'
		SELECT @requeststr = ''
		SELECT @requeststr = @requeststr + 'PARTNER=' + @Partner + @temp2
	  	SELECT @requeststr = @requeststr + 'USER=' + isnull(@UserName,'no user') + @temp2
		SELECT @requeststr = @requeststr + 'VENDOR=' + isnull(@UserName,'no vendor') + @temp2
	        SELECT @requeststr = @requeststr + 'PWD=' + isnull(@UserPassword,'no pwd') + @temp2
		SELECT @requeststr = @requeststr + 'TENDER=C'   + @temp2
		SELECT @requeststr = @requeststr + 'TRXTYPE=' + isnull(@trx_type,'no trxtype') + @temp2
		SELECT @requeststr = @requeststr + 'ACCT=' + isnull(@ccnumber,'no acct') + @temp2
		SELECT @requeststr = @requeststr + 'EXPDATE=' + isnull(@ccexpmo,'no expdate')+isnull(@ccexpyr,'') + @temp2
		SELECT @requeststr = @requeststr + 'AMT=' + isnull(@ord_total_str,'no amt') + @temp2
		IF LEFT(@AddressVerification ,1)= 'Y'
		BEGIN
			SELECT @requeststr = @requeststr + 'ZIP=' + isnull(@zipcode,'') + @temp2
			SELECT @requeststr = @requeststr + 'STREET=' + isnull(@address,'') + @temp2
		END
		SELECT @requeststr = @requeststr + 'COUNTRY=' + isnull(@CurrencyID,'currency id') + @temp2
		SELECT @requeststr = @requeststr + 'COMMENT1=' + isnull(@trx_ctrl_num,'trx_ctrl_num')+ @temp2   

		if @csc <> ''
		BEGIN
			SELECT @requeststr = @requeststr + 'COMMENT2=' + @customer_code + '/' + @order_no_str + ',' + @ext_str + '/' + @Entered_By + @temp2  -- FF 6/2/03
			SELECT @requeststr = @requeststr + 'CVV2=' + @csc
		END
		else
		BEGIN
			SELECT @requeststr = @requeststr + 'COMMENT2=' + @customer_code + '/' + @order_no_str + ',' + @ext_str + '/' + @Entered_By   -- FF 6/2/03
		END

		
		-- building the string to be logged
		SELECT @requeststrmask = ''
		SELECT @requeststrmask = @requeststrmask + 'PARTNER=' + @Partner + @temp2
	  	SELECT @requeststrmask = @requeststrmask + 'USER=' + isnull(@UserName,'no user') + @temp2
		SELECT @requeststrmask = @requeststrmask + 'VENDOR=' + isnull(@UserName,'no vendor') + @temp2
	        SELECT @requeststrmask = @requeststrmask + 'PWD=' + isnull(@UserPassword,'no pwd') + @temp2
		SELECT @requeststrmask = @requeststrmask + 'TENDER=C'   + @temp2
		SELECT @requeststrmask = @requeststrmask + 'TRXTYPE=' + isnull(@trx_type,'no trxtype') + @temp2
		SELECT @requeststrmask = @requeststrmask + 'ACCT=' + isnull(dbo.CCAMask_fn(@ccnumber),'no acct') + @temp2
		SELECT @requeststrmask = @requeststrmask + 'EXPDATE=' + isnull(@ccexpmo,'no expdate')+isnull(@ccexpyr,'') + @temp2
		SELECT @requeststrmask = @requeststrmask + 'AMT=' + isnull(@ord_total_str,'no amt') + @temp2
		IF LEFT(@AddressVerification ,1)= 'Y'
		BEGIN
			SELECT @requeststrmask = @requeststrmask + 'ZIP=' + isnull(@zipcode,'') + @temp2
			SELECT @requeststrmask = @requeststrmask + 'STREET=' + isnull(@address,'') + @temp2
		END
		SELECT @requeststrmask = @requeststrmask + 'COUNTRY=' + isnull(@CurrencyID,'currency id') + @temp2
		SELECT @requeststrmask = @requeststrmask + 'COMMENT1=' + isnull(@trx_ctrl_num,'trx_ctrl_num')+ @temp2   
		SELECT @requeststrmask = @requeststrmask + 'COMMENT2=' + @customer_code + '/' + @order_no_str + ',' + @ext_str + '/' + @Entered_By  -- FF 6/2/03

		if @csc <> ''
		BEGIN
			SELECT @requeststrmask = @requeststrmask + 'COMMENT2=' + @customer_code + '/' + @order_no_str + ',' + @ext_str + '/' + @Entered_By + @temp2  -- FF 6/2/03
			SELECT @requeststrmask = @requeststrmask + 'CVV2=***'
		END
		ELSE
		BEGIN
			SELECT @requeststrmask = @requeststrmask + 'COMMENT2=' + @customer_code + '/' + @order_no_str + ',' + @ext_str + '/' + @Entered_By   -- FF 6/2/03
		END






	
	END
      
	--Build the submit command

	SELECT @submitcommand = 'SubmitTransaction(' + CAST(@resultcontext as varchar(16)) + ', "' + @requeststr + '",' + CAST(len(@requeststr) as varchar(5)) + ')' 
	SELECT @submitcommandmask = 'SubmitTransaction(' + CAST(@resultcontext as varchar(16)) + ', "' + @requeststrmask + '",' + CAST(len(@requeststrmask) as varchar(5)) + ')' 

	EXEC icv_Log_sp @submitcommandmask, @LogActivity

























	

select @res_net = master.dbo.SubmitTrans(@requeststr,@HostAdd,@Port,@Timeout, 0,0,'','','OFF','','','','')
select @Response = @res_net 


SELECT @fullstring = @Response
 EXEC icv_Log_sp @fullstring, @LogActivity

--RESPMSG
SELECT @searchname = 'RESULT'
SELECT @pointer = charindex(@searchname,@fullstring)
select @ResultCode = -1, @ResultString = ''
IF @pointer > 0  
BEGIN
  SELECT @begpos = @pointer + len(@searchname)+1
    IF charindex("&",@fullstring,@begpos ) <> 0    
     BEGIN   
  	SELECT @vlength = charindex("&",@fullstring,@begpos )-@begpos
        SELECT @ResultString = substring(@fullstring,@begpos,@vlength )
     END
    ELSE 
     BEGIN
        SELECT @vlength = len(@fullstring)+1-@begpos
        SELECT @ResultString = substring(@fullstring,@begpos,@vlength )
        SELECT @ResultCode =  + @ResultString
        GOTO EndParse
     END
END
SELECT @ResultCode =  + @ResultString


	
--PNREF
SELECT @searchname = 'PNREF'
SELECT @pointer = charindex(@searchname,@fullstring), @ResultString = ''
 
IF @pointer > 0  
BEGIN
  SELECT @begpos = @pointer + len(@searchname)+1
    IF charindex("&",@fullstring,@begpos ) <> 0 
     BEGIN   
  	SELECT @vlength = charindex("&",@fullstring,@begpos )-@begpos
        SELECT @ResultString = substring(@fullstring,@begpos,@vlength )
     END
    ELSE 
     BEGIN
        SELECT @vlength = len(@fullstring)+1-@begpos
        SELECT @ResultString = substring(@fullstring,@begpos,@vlength )
        SELECT  @PTTID = @ResultString
        GOTO EndParse
     END
END
SELECT  @PTTID = @ResultString
--RESPMSG
SELECT @searchname = 'RESPMSG'
SELECT @pointer = charindex(@searchname,@fullstring), @ResultString = ''
 
IF @pointer > 0  
BEGIN
  SELECT @begpos = @pointer + len(@searchname)+1
    IF charindex("&",@fullstring,@begpos ) <> 0    
     BEGIN   
  	SELECT @vlength = charindex("&",@fullstring,@begpos )-@begpos
        SELECT @ResultString = substring(@fullstring,@begpos,@vlength )
     END
    ELSE 
     BEGIN
        SELECT @vlength = len(@fullstring)+1-@begpos
        SELECT @ResultString = substring(@fullstring,@begpos,@vlength )
        SELECT @RespMsg =  + @ResultString
        GOTO EndParse
     END
END
SELECT @RespMsg =  + @ResultString

--AUTHCODE
SELECT @searchname = 'AUTHCODE'
SELECT @pointer = charindex(@searchname,@fullstring)
SELECT @AuthCode = '' , @ResultString = ''
IF @pointer > 0  
BEGIN
  SELECT @begpos = @pointer + len(@searchname)+1
  IF charindex("&",@fullstring,@begpos ) <> 0    
     BEGIN   
  	SELECT @vlength = charindex("&",@fullstring,@begpos )-@begpos
        SELECT @ResultString = substring(@fullstring,@begpos,@vlength )
     END
  ELSE 
     BEGIN
        SELECT @vlength = len(@fullstring)+1-@begpos
        SELECT @ResultString = substring(@fullstring,@begpos,@vlength )
        SELECT  @AuthCode =  + @ResultString
        GOTO EndParse
     END
END
SELECT  @AuthCode =  + @ResultString
--AVSADDR
SELECT @searchname = 'AVSADDR'
SELECT @pointer = charindex(@searchname,@fullstring), @ResultString = ''
 
IF @pointer > 0  
BEGIN
  SELECT @begpos = @pointer + len(@searchname)+1
   
  IF charindex("&",@fullstring,@begpos ) <> 0    
     BEGIN   
  	SELECT @vlength = charindex("&",@fullstring,@begpos )-@begpos
        SELECT @ResultString = substring(@fullstring,@begpos,@vlength )
     END
  ELSE 
     BEGIN
        SELECT @vlength = len(@fullstring)+1-@begpos
        SELECT @ResultString = substring(@fullstring,@begpos,@vlength )
        SELECT  @AVSAddr =  + @ResultString
        GOTO EndParse
     END
END
SELECT  @AVSAddr =  + @ResultString
--AVSZIP
SELECT @searchname = 'AVSZIP'
SELECT @pointer = charindex(@searchname,@fullstring), @ResultString = ''
 
IF @pointer > 0  
BEGIN
  SELECT @begpos = @pointer + len(@searchname)+1
  IF charindex("&",@fullstring,@begpos ) <> 0    
     BEGIN   
  	SELECT @vlength = charindex("&",@fullstring,@begpos )-@begpos
        SELECT @ResultString = substring(@fullstring,@begpos,@vlength )
     END
  ELSE 
     BEGIN
        SELECT @vlength = len(@fullstring)+1-@begpos
        SELECT @ResultString = substring(@fullstring,@begpos,@vlength )
        SELECT  @AVSZip =   +  @ResultString
        GOTO EndParse
     END
END
SELECT  @AVSZip =   +  @ResultString


if @csc <> ''
BEGIN
	--CVV2 MATCH
	SELECT @searchname = 'CVV2MATCH'
	SELECT @pointer = charindex(@searchname,@fullstring), @ResultString = ''
	 
	IF @pointer > 0  
	BEGIN
	  SELECT @begpos = @pointer + len(@searchname)+1
	    IF charindex("&",@fullstring,@begpos ) <> 0 
	     BEGIN   
	  	SELECT @vlength = charindex("&",@fullstring,@begpos )-@begpos
	        SELECT @ResultString = substring(@fullstring,@begpos,@vlength )
	     END
	    ELSE 
	     BEGIN
	        SELECT @vlength = len(@fullstring)+1-@begpos
	        SELECT @ResultString = substring(@fullstring,@begpos,@vlength )
	        SELECT  @cvv2match = @ResultString
	        GOTO EndParse
	     END
	END
	SELECT  @cvv2match = @ResultString
END


EndParse:

EXEC icv_Log_sp @RespMsg, @LogActivity

if @ResultCode = 12 and Upper(@RespMsg)  = 'DECLINED'						-- mls 11/24/03 SCR 32136
begin
  select @RespMsg = 'Check Credit Card Information.'
end

IF (@AVSAddr = 'N') OR (@AVSZip = 'N') 
BEGIN
   IF @IgnoreAddressFailure = 1
      BEGIN
         SELECT @result = 0
	 EXEC icv_Log_sp 'AVS failure ignored', @LogActivity
      END
    ELSE
      BEGIN
         SELECT @Response = '"N AVS failed"'
         SELECT @ret = 0
         GOTO ICVRETURN
      END
 END 



if @csc <> '' AND ISNULL(@AuthCode, '') <> ''
BEGIN
	IF  (ISNULL(@PTTID, '') <> '' AND ISNULL(@cvv2match,'N') = 'N')
	BEGIN
	--PARTNER=channelsales&USER=epicore&VENDOR=epicore&PWD=jackson5&TENDER=C&TRXTYPE=V&ORIGID=V18M0ED68B6D		
		SELECT @requeststr = 'PARTNER=' + @Partner + '&USER=' + @UserName + '&VENDOR=' + @UserName + '&PWD=' + @UserPassword  + '&TENDER=C&TRXTYPE=V&ORIGID=' + @PTTID
		SELECT @submitcommand = 'SubmitTransaction(' + CAST(@resultcontext as varchar(16)) + ', "' + @requeststr + '",' + CAST(len(@requeststr) as varchar(5)) + ')'
	
		SELECT @requeststrmask = 'PARTNER=' + @Partner + '&USER=' + @UserName + '&VENDOR=' + @UserName + '&PWD=******&TENDER=C&TRXTYPE=V&ORIGID=' + @PTTID
		SELECT @submitcommandmask = 'SubmitTransaction(' + CAST(@resultcontext as varchar(16)) + ', "' + @requeststrmask + '",' + CAST(len(@requeststrmask) as varchar(5)) + ')'		

		EXEC icv_Log_sp @submitcommandmask, @LogActivity





		select @res_net = master.dbo.SubmitTrans(@requeststr,@HostAdd,@Port,@Timeout, 0,0,'','','OFF','','','','')
		select @Response = @res_net 



























		   SET @AuthCode = '' 
		   SET @ResultCode = 2626
		   set @RespMsg = 'Invalid CVV2'			
		   SELECT @buf  = 'CVNMessage: ' + ISNULL( CAST(@RespMsg as varchar(50)), 'NULL') + ''
		   EXEC icv_Log_sp @buf, @LogActivity		







	END
END

if @AuthCode IS NULL
	SET @AuthCode = ''
	


	SELECT @buf = 'Result: ' + RTRIM(LTRIM(@ResultCode)) + ', AuthCode: ' + RTRIM(LTRIM(@AuthCode)) + ', RespMsg: ' + RTRIM(LTRIM(@RespMsg)) + + ', PTTid: ' + RTRIM(LTRIM(@PTTID))
	EXEC icv_Log_sp @buf, @LogActivity
	IF ISNULL(DATALENGTH(RTRIM(LTRIM(@Comment1))),0) > 0
	BEGIN
		SELECT @buf = 'Comment1: ' + RTRIM(LTRIM(@Comment1))
		EXEC icv_Log_sp @buf, @LogActivity
	END
	IF ISNULL(DATALENGTH(RTRIM(LTRIM(@Comment2))),0) > 0
	BEGIN
		SELECT @buf = 'Comment2: ' + RTRIM(LTRIM(@Comment2))
		EXEC icv_Log_sp @buf, @LogActivity
	END
	

	SELECT @payment_code=payment_code FROM icv_cctype WHERE creditcard_prefix=substring(@ccnumber,1,1)
	SELECT @nat_cur_code= case when @CurrencyID = '840' then 'USD' else @nat_cur_code end
	IF(@transtype ='C3')
		SELECT @cca_trx_ctrl_num= case when len(isnull(@cash_trx_ctrl_num,'')) <=0 then @order_no_str + '-' + @ext_str else @cash_trx_ctrl_num end
	ELSE
		SELECT @cca_trx_ctrl_num= case when len(@trx_ctrl_num) <=0 then @order_no_str + '-' + @ext_str else @trx_ctrl_num end
	EXEC icv_log_events_sp  @cca_trx_ctrl_num,
			        @ar_customer_code,
				@payment_code,
				@ccnumber,
				@trx_type,
				@ord_total_str,
				@ord_total_str,
				@nat_cur_code,
				@AuthCode,
				@PTTID,			
				1,
				@ResultCode,
				@order_no,
				@reference,
				2

	









	
	IF @ResultCode = 0 
--	IF ISNULL(DATALENGTH(RTRIM(LTRIM(@AuthCode))),0) > 0
--		IF (UPPER(@AuthCode) = 'DECLINED') OR (UPPER(@AuthCode) = 'REFERRAL')
--			SELECT @Response = '"N ' + RTRIM(LTRIM(@RespMsg))+'"'    
--		ELSE
			SELECT @Response = '"Y' + RTRIM(LTRIM(@AuthCode))+'"'   + RTRIM(LTRIM(@PTTID))
	ELSE
	  BEGIN
		SELECT @Response = '"N' + RTRIM(LTRIM(@RespMsg))+'"'  
		SELECT @ret= @ResultCode -- Rev 1.0 Cyanez Added to get error information about the transaction
	END

	IF SUBSTRING(@Response,2,1) = 'Y'
	BEGIN
		--Update Tables
	
	       	IF ISNULL(DATALENGTH(RTRIM(LTRIM(@PTTID))),0) > 0 AND @order_no > 0
		BEGIN
			IF EXISTS (SELECT 1 FROM icv_ord_payment_dtl WHERE order_no = @order_no and ext = @ext
			and auth_sequence = 0)		-- mls 10/15/03
			BEGIN
				UPDATE icv_ord_payment_dtl
				 SET approval_code = @AuthCode, 
				 reference_no = @PTTID,
				 trans_type = @transtype
				 WHERE order_no = @order_no
				 AND ext = @ext
				 AND auth_sequence = 0
			END
			ELSE
			BEGIN
				INSERT INTO icv_ord_payment_dtl (order_no, ext, sequence, auth_sequence, response_flag, rej_reason, approval_code, reference_no, avs_result, proc_date, ord_amt, trans_type) VALUES
								(@order_no, @ext, 1, 0, @trx_type, '', SUBSTRING(@AuthCode,1,6), SUBSTRING(@PTTID,1,12), '', GETDATE(), @ord_total_str, @transtype )
			END
		END
	END


ICVRETURN:






















	RETURN @ret
END
GO
GRANT EXECUTE ON  [dbo].[icv_verisign] TO [public]
GO
