SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO































CREATE PROCEDURE [dbo].[icv_trustmarque] @transtype CHAR(3),
				 @ccnumber varCHAR(20),
				 @ccexpmo CHAR(2),
				 @ccexpyr CHAR(4),
				 @ordtotal Decimal(20,8),
				 @response VARCHAR(60) OUTPUT,
				 @order_no int = 0,
 				 @ext int = 0,
				 @prompt1 CHAR(30) = '',
				 @trx_ctrl_num VARCHAR(16) = '',
				 @ar_customer_code VARCHAR(8) = '',
				 @nat_cur_code varchar(8) = '',
				 @IAS_TrxType smallint,
				 @csc varchar(5) = ''
AS
BEGIN
	DECLARE @buf			CHAR(255)
	DECLARE @filename		CHAR(255)
	DECLARE	@LogActivity		CHAR(3)
	DECLARE @AddressVerification	CHAR(1)
	DECLARE	@IgnoreAddressFailure	INT
	DECLARE @LevelIICompliance	INT
	DECLARE	@IPAddress		VARCHAR(255)
	DECLARE @Port			VARCHAR(255)
	DECLARE @DemoMode		CHAR(1)
	DECLARE @MerchantID		VARCHAR(255)
	DECLARE @UserName		VARCHAR(255)
	DECLARE @UserPassword		VARCHAR(255)
	DECLARE @Timeout 		VARCHAR(255)
	DECLARE @status			CHAR(1)
	DECLARE @tmif 			INT
	DECLARE @ord_total_str 		VARCHAR(20)
	DECLARE @AcctType		CHAR(2)
	DECLARE @zipcode		CHAR(30)
	DECLARE @address		CHAR(30)
	DECLARE @ix			INT
	DECLARE	@trx_type		CHAR
	DECLARE @result 		INT
	DECLARE @ret 			INT
	DECLARE	@AVSAddr		CHAR(1)
	DECLARE @AVSZip			CHAR(1)
	DECLARE @RespMsg		VARCHAR(255)
	DECLARE @AuthCode		VARCHAR(255)
	DECLARE @Comment1		VARCHAR(255)
	DECLARE @Comment2		VARCHAR(255)
	DECLARE @payment_code		CHAR(8)
	--DECLARE @nat_cur_code		CHAR(8)
	DECLARE @CurrencyID		CHAR(3)
	DECLARE @debug_level		INT
	DECLARE @pttid			CHAR(20)
	DECLARE @orig_no		INT
	DECLARE @orig_ext		INT

	DECLARE @CVNmsg			INT	


	
	
	DECLARE @customer_code		VARCHAR(8)
	DECLARE @ship_to_code		VARCHAR(8)
	DECLARE @name_to_use		INT
	DECLARE @attention_name		VARCHAR(40)
	DECLARE @contact_name		VARCHAR(40)
	DECLARE @customer_name		VARCHAR(40)
	DECLARE @fullname		VARCHAR(40)
	DECLARE @firstname		VARCHAR(40)
	DECLARE @lastname		VARCHAR(40)
	DECLARE @address1		VARCHAR(40)
	DECLARE @address2		VARCHAR(40)
	DECLARE @address3		VARCHAR(40)
	DECLARE @city			VARCHAR(40)
	DECLARE @state			VARCHAR(40)
	DECLARE @state_code		VARCHAR(30)
	DECLARE @country		VARCHAR(40)
	DECLARE @country_code		VARCHAR(2)
	DECLARE	@phone			VARCHAR(30)
	DECLARE	@attention_phone	VARCHAR(30)
	DECLARE	@contact_phone		VARCHAR(30)
	DECLARE	@customer_phone		VARCHAR(30)
	DECLARE @rowcount		INT
	DECLARE @i			INT
	DECLARE @i1			INT
	DECLARE @istest			Varchar(1)  --SCR 30221

	DECLARE @ecomm_dflt_cust char(1) 		-- mls 10/27/03 SCR 31953 
	DECLARE @orders_phone 	 varchar(20)		-- mls 10/27/03 SCR 31953 

	DECLARE @RespCode varchar(30)		-- mls 11/21/03 SCR 32136

        DECLARE @auth_ord_amt decimal(20,8),	-- mls 11/25/03 SCR 32136
          @auth_resp_flag char(1), @auth_approval_code varchar(6), @auth_reference_no varchar(12), @auth_trans_type varchar(4),
          @auth_seq int,
          @order_no_str varchar(255)
	
	DECLARE @reference varchar(16)
	DECLARE @cca_trx_ctrl_num varchar(16)
	DECLARE @org_amount float
	DECLARE	@sys_date	int
	DECLARE @IAS_Account_Exists varchar(300)
	DECLARE @companycode varchar(8)
	DECLARE @is_order smallint
	DECLARE @cash_trx_ctrl_num varchar(16)
	DECLARE @inv_trx_ctrl_num  varchar(16)
	DECLARE @exist_orders_table int  
        DECLARE @order_artrx varchar(16) 
        
	select @exist_orders_table = 0
	SELECT @exist_orders_table = ISNULL( (SELECT 1 FROM sysobjects WHERE name = 'orders') , 0 )
	
        select @ecomm_dflt_cust = 'N'

	SET NOCOUNT ON
	IF( @order_no=0)
	BEGIN
	SELECT @is_order =0
	END
	ELSE
	BEGIN
		SELECT @is_order =1
	END

	SELECT 	@IAS_Account_Exists = ''
	SELECT @companycode = company_code from glco
	
	



	IF(@transtype in ('C0','CO','C1', 'C2','C4','C5','C6'))
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

		





		IF(@transtype in ('C0','CO') 
		     AND (SELECT authorize_onsave from arco) = 1 AND @is_order = 0
			AND ((SELECT source_trx_type 
			FROM arinppyt WHERE trx_ctrl_num = @trx_ctrl_num) = 2031 
			OR   (SELECT source_trx_type 
			FROM arinppyt WHERE trx_ctrl_num = @trx_ctrl_num) = 2021))
		BEGIN
	
	           IF((SELECT source_trx_type 
			FROM arinppyt WHERE trx_ctrl_num = @trx_ctrl_num) = 2031 )
		   BEGIN
		   
		      SELECT  @inv_trx_ctrl_num = source_trx_ctrl_num 
			FROM arinppyt WHERE trx_ctrl_num = @trx_ctrl_num
		       
		   
		   END
		   ELSE
		   BEGIN
	          
	              SELECT @inv_trx_ctrl_num = trx.trx_ctrl_num
			 FROM artrx trx (nolock)
			 INNER join arinppdt pdt  (nolock)
			 on trx.doc_ctrl_num = pdt.apply_to_num
			WHERE pdt.trx_ctrl_num = @trx_ctrl_num
			
		   END

		END
	END

	IF (@transtype = 'C3')	
	BEGIN
		IF @is_order = 1
          	BEGIN
       		     IF @exist_orders_table = 1
		     BEGIN          	
          	
			SELECT	@orig_no = ISNULL(orig_no,0),
				@orig_ext = ISNULL(orig_ext,0)
			  FROM	orders (nolock)
			 WHERE	order_no = @order_no
			   AND	ext = @ext

			SELECT @IAS_Account_Exists= ccnumber from CVO_Control..ccacryptaccts (nolock)
			WHERE  	( order_no = @orig_no
				  AND order_ext = @orig_ext
				  AND company_code = @companycode  )
		     END
		END
	END


	




	IF(@transtype = 'C7' AND @is_order = 0)
	BEGIN
	
	        





                
                SELECT @cash_trx_ctrl_num = trx.trx_ctrl_num
                       FROM artrx trx (nolock)
		          INNER JOIN arinppyt pyt (nolock)
		    	    ON trx.doc_ctrl_num = pyt.doc_ctrl_num
			    WHERE pyt.trx_ctrl_num = @trx_ctrl_num 
			    	AND trx.prompt4_inp = pyt.prompt4_inp
		                AND trx.deposit_num <> ''
                                AND pyt.trx_type = 2121

		SELECT @IAS_Account_Exists = ccnumber from CVO_Control..ccacryptaccts (nolock)
		WHERE 	trx_ctrl_num = @cash_trx_ctrl_num
			AND trx_type = 2111
			AND company_code = @companycode  
			
                
		-- SELECT 'source_trx_type '+ STR(source_trx_type,10,0) FROM artrx WHERE trx_ctrl_num = @cash_trx_ctrl_num
			
		IF (len(@cash_trx_ctrl_num)>0 AND 
		    (SELECT authorize_onsave from arco) = 1 AND 
		    (SELECT source_trx_type FROM artrx WHERE trx_ctrl_num = @cash_trx_ctrl_num) = 2031)
		BEGIN
		  
		  -- SELECT 'rowcount > 0 cash_trx_ctrl_num '+ @cash_trx_ctrl_num
		  SELECT @cash_trx_ctrl_num =  trx.trx_ctrl_num
			 FROM artrx trx (nolock)
			INNER join arinppdt pdt (nolock)
			on trx.doc_ctrl_num = pdt.apply_to_num
			WHERE pdt.trx_ctrl_num = @trx_ctrl_num
			AND pdt.trx_type = 2121
			AND trx.trx_type = 2031
			
		   if @@rowcount = 0 
                   BEGIN 
                       
                      -- SELECT 'rowcount 0 cash_trx_ctrl_num'+ @cash_trx_ctrl_num
 
		      SELECT @cash_trx_ctrl_num = trx.source_trx_ctrl_num
			 FROM artrx trx (nolock) INNER join arinppyt pyt (nolock)
			      on trx.doc_ctrl_num = pyt.doc_ctrl_num
			      WHERE pyt.trx_ctrl_num = @trx_ctrl_num
			      AND trx.prompt4_inp = pyt.prompt4_inp
			      AND pyt.trx_type = 2121
			      AND trx.source_trx_type = 2031
                   END

                      IF (@exist_orders_table = 1 and @cash_trx_ctrl_num <> '' )
                      BEGIN
                           select @order_artrx = order_ctrl_num from artrx (nolock) where trx_type = 2031 
                                  and trx_ctrl_num = @cash_trx_ctrl_num
                           if len(@order_artrx) > 0 
                           BEGIN
                              
                              -- select 'order_artrx ' + @order_artrx 
                              select @order_no = CAST( substring(@order_artrx,1,charindex('-',@order_artrx )-1) AS INT )
                              select @ext = CAST (substring(@order_artrx,charindex('-',@order_artrx )+ 1 ,len(@order_artrx) ) AS INT )
                              select @is_order = 1
 		              SELECT @IAS_Account_Exists = ccnumber from CVO_Control..ccacryptaccts 
			       WHERE  order_no = @order_no 
				  AND order_ext = @ext 
				  AND company_code = @companycode 
                                
                              if (@IAS_Account_Exists <> '')
                              BEGIN 
                                  SELECT  @orig_no = @order_no , @orig_ext = @ext 
                                  -- SELECT 'IAS_Account_Exists'
                              END  
                           END                                          
                      END
			
		END 

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


	SELECT @tmif = 0, @filename = 'C:\tmif.log'

        select @LogActivity = case when isnull((select UPPER(configuration_text_value)
	  FROM icv_config (nolock)
	 WHERE UPPER(configuration_item_name) = 'LOG ACTIVITY'),'NO') = 'YES' then 'YES' else 'NO' end

	SELECT @debug_level = isnull((select configuration_int_value
	  FROM icv_config (nolock)
	 WHERE UPPER(configuration_item_name) = 'DEBUG LEVEL'),0)

	SELECT @DemoMode = SUBSTRING(isnull((select UPPER(configuration_text_value)
	  FROM icv_config (nolock)
	 WHERE UPPER(configuration_item_name) = 'DEMO MODE'),'NO'),1,1)

	SELECT @AddressVerification = case when isnull((select UPPER(configuration_text_value)
	  FROM icv_config (nolock)
	 WHERE UPPER(configuration_item_name) = 'ADDRESS VERIFICATION'),'NO') != 'YES' then '0' else '1' end

	SELECT @IgnoreAddressFailure = case when isnull((select UPPER(configuration_text_value)
	  FROM icv_config (nolock)
	 WHERE UPPER(configuration_item_name) = 'IGNORE ADDRESS VERIFICATION FAILURE'),'NO') = 'YES' then 1 else 0 end

   --SCR 30221
	SELECT @istest = isnull((select configuration_text_value
	FROM   icv_config (nolock)
	WHERE  UPPER(configuration_item_name) = 'ISTEST'),'0')
   --SCR 30221 END

	SELECT @LevelIICompliance = case when isnull((select UPPER(configuration_text_value)
	  FROM icv_config (nolock)
	 WHERE UPPER(configuration_item_name) = 'LEVEL II COMPLIANCE'),'NO') = 'YES' then 1 else 0 end

	


	SELECT @IPAddress = UPPER(configuration_text_value)
	  FROM icv_config (nolock)
	 WHERE UPPER(configuration_item_name) = 'GATEWAY IP ADDRESS'

	IF @@rowcount <> 1
	BEGIN
		SELECT @response = 'Error: Gateway IP Address not defined'
		SELECT @ret = -1010
     		GOTO ICVRETURN
	END

	SELECT @Port = UPPER(configuration_text_value)
	  FROM icv_config (nolock)
	 WHERE UPPER(configuration_item_name) = 'GATEWAY PORT'

	IF @@rowcount <> 1
	BEGIN
		SELECT @response = 'Error: Gateway Port not defined'
		SELECT @ret = -1010
     		GOTO ICVRETURN
	END

	SELECT @MerchantID = UPPER(configuration_text_value)
	  FROM icv_config (nolock)
	 WHERE UPPER(configuration_item_name) = 'MERCHANTID'

	IF @@rowcount <> 1
	BEGIN
		SELECT @response = 'Error: MerchantID not defined'
		SELECT @ret = -1010
     		GOTO ICVRETURN
	END

	SELECT @UserName = UPPER(configuration_text_value)
	  FROM icv_config (nolock)
	 WHERE UPPER(configuration_item_name) = 'USERNAME'

	IF @@rowcount <> 1
	BEGIN
		SELECT @response = 'Error: UserName not defined'
		SELECT @ret = -1010
     		GOTO ICVRETURN
	END

	SELECT @UserPassword = UPPER(configuration_text_value)
	  FROM icv_config (nolock)
	 WHERE UPPER(configuration_item_name) = 'USERPASSWORD'

	IF @@rowcount <> 1
	BEGIN
		SELECT @response = 'Error: UserPassword not defined'
		SELECT @ret = -1010
     		GOTO ICVRETURN
	END

	SELECT @Timeout = (SELECT value_str FROM config (nolock) WHERE UPPER(flag) = 'ICV_TIMEOUT')
	IF @Timeout IS NULL
	BEGIN
     		SELECT @response = 'Error: No Timeout Found'
		SELECT @ret = -1040
	     	GOTO ICVRETURN
	END
	-- Start Rev 1.1 - This part of the code was added to obtain the correct trx_ctrl_num from Cash Recipet Adjustment
	--	     from artrx	
	IF @transtype='C7'
	BEGIN

		SELECT @transtype='C3'

		SELECT @reference=@trx_ctrl_num
		
		SELECT @trx_ctrl_num=trx_ctrl_num
		FROM artrx (nolock)
		WHERE doc_ctrl_num=@trx_ctrl_num
		AND trx_type=2111
		AND customer_code=@ar_customer_code
		
		
		--SELECT 'C7 reference'+ @reference
                --SELECT 'C7 to C3 trx_ctrl_num ' + @trx_ctrl_num
              
	END
	--End Rev 1.1	



	








	SELECT @name_to_use = isnull((select UPPER(configuration_int_value)
	  FROM icv_config (nolock)
	 WHERE UPPER(configuration_item_name) = 'NAME TO USE'),0)

	IF @name_to_use NOT IN (1,2,3)
  	  SELECT @name_to_use = 1				
	
	SELECT @buf = 'Entering icv_trustmarque ' + RTRIM(LTRIM(@transtype)) + ', ' + dbo.CCAMask_fn(RTRIM(LTRIM(@ccnumber))) + ', ' + RTRIM(LTRIM(@ccexpmo)) + ', ' + RTRIM(LTRIM(@ccexpyr)) + ', ' + RTRIM(LTRIM(CONVERT(CHAR, @ordtotal))) + ', ' + RTRIM(LTRIM(CONVERT(CHAR, @order_no))) + ', ' + RTRIM(LTRIM(CONVERT(CHAR, @ext)))
	EXEC icv_Log_sp @buf, @LogActivity
	SELECT @buf = 'Address verification: ' + RTRIM(LTRIM(@AddressVerification))
	EXEC icv_Log_sp @buf, @LogActivity
	SELECT @buf = 'Ignore Address Verification Failure: ' + RTRIM(LTRIM(CONVERT(CHAR, @IgnoreAddressFailure)))
	EXEC icv_Log_sp @buf, @LogActivity
	SELECT @buf = 'Level II Compliance: ' + RTRIM(LTRIM(CONVERT(CHAR, @LevelIICompliance)))
	EXEC icv_Log_sp @buf, @LogActivity
	SELECT @buf = 'Gateway: ' + RTRIM(LTRIM(@IPAddress)) + ' ' + RTRIM(LTRIM(@Port)) + ', ' + RTRIM(LTRIM(@MerchantID)) + ', ' + RTRIM(LTRIM(@UserName)) + ', ' + RTRIM(LTRIM(@UserPassword))
	EXEC icv_Log_sp @buf, @LogActivity


	


       SELECT @status = ''
        IF @exist_orders_table = 1
	BEGIN
	     SELECT @status = status 
	       FROM orders (nolock)
	       WHERE order_no = @order_no AND ext = @ext
	     --SELECT 'Status = '+ isnull(@status, ' ')	       
        END 

        select @auth_resp_flag = response_flag,
          @auth_approval_code = approval_code,
          @auth_reference_no = reference_no,
          @auth_trans_type = trans_type,
          @auth_seq = sequence,
          @auth_ord_amt = ord_amt
        from icv_ord_payment_dtl (nolock)
        where order_no = @order_no and ext = @ext and auth_sequence = 0

       --select 'from orders auth_sequence 0 @auth_resp_flag = '+ ISNULL(@auth_resp_flag,' ') 
       --select 'from orders approval_code = '+ ISNULL(@auth_reference_no, ' ')         

        if @@rowcount = 0
          select @auth_resp_flag = '', @auth_ord_amt = 0, @auth_approval_code = '', @auth_seq = 1

        if @order_no > 0
  	  SELECT @order_no_str = RTRIM(LTRIM(CONVERT(CHAR, @order_no))) + '.' + RTRIM(LTRIM(CONVERT(CHAR, @ext))) +
            case when @auth_seq > 1 then '-' + Convert(CHAR, @auth_seq) else '' end



	IF (isnull(@status,'') = 'V')
	BEGIN
		IF @auth_resp_flag in ('S','C','V','D')						-- mls 1/22/04 SCR 32358 - added D to list
		BEGIN
		  SELECT @buf = 'Void to Trustmarque and Immediate return from icv_trustmarque because order ' + RTRIM(LTRIM(CONVERT(CHAR,@order_no))) + ',' + RTRIM(LTRIM(CONVERT(CHAR,@ext))) + ' has a status of ' + @status + ''
		  EXEC icv_Log_sp @buf, @LogActivity
		  SELECT @ret = -1310
		  SELECT @response = '"NORDER IS VOID"'
		  GOTO ICVRETURN
		end

		IF @auth_resp_flag = ''
		BEGIN
		  SELECT @buf = 'Transaction was never Authorized'
		  EXEC icv_Log_sp @buf, @LogActivity
		  SELECT @response = '"NTransaction was never Authorized"'
		  SELECT @ret = -1300
		  GOTO ICVRETURN
		end

		select @transtype = 'C2'
                select @ordtotal = @auth_ord_amt
	END
	

	


	
	IF @transtype = 'C6'
		SELECT @trx_type = 'A'
	
	IF @transtype = 'C4'
		SELECT @trx_type = 'B'
	  
	IF @transtype in ( 'CO', 'C0')
		SELECT @trx_type = 'D'			-- Deposit
		
	IF @transtype = 'C1' 
		SELECT @trx_type = 'S'			-- Simultaneous Book and Deposit
	
	IF @transtype = 'C3'
		SELECT @trx_type = 'C'

	
	IF @transtype = 'C2'
		Select @trx_type = 'V'


	IF @trx_type <> ''
	BEGIN
		IF @auth_resp_flag = @trx_type and DATALENGTH(RTRIM(LTRIM(@auth_approval_code))) > 0 AND @auth_ord_amt = @ordtotal
		BEGIN
			SELECT @buf = 'Transaction has already been performed for this order'
			EXEC icv_Log_sp @buf, @LogActivity
			SELECT @response = '"Y' + isnull(@auth_approval_code,'999998') + '"'
			SELECT @ret = -1300
			GOTO ICVRETURN
		END

		--
		-- Special case for C4 Trustmarque transaction, if this is a book then check to see if an Authorize has 
		-- already been done.
		--
                if @transtype = 'C4' -- if booking, check for previous authorization
                begin
		  IF @auth_resp_flag = 'A' and DATALENGTH(RTRIM(LTRIM(@auth_approval_code))) > 0 AND @auth_ord_amt = @ordtotal
                  BEGIN
			SELECT @buf = 'Transaction has already been performed for this order'
			EXEC icv_Log_sp @buf, @LogActivity
			SELECT @response = '"Y999998"'
			SELECT @ret = -1300
			GOTO ICVRETURN
		  END
 		END

		if @auth_resp_flag in ('D','S','C') and DATALENGTH(RTRIM(LTRIM(@auth_approval_code))) > 0
		BEGIN
			SELECT @buf = 'Transaction has already been performed for this order for a different amount.'
			EXEC icv_Log_sp @buf, @LogActivity
			SELECT @response = '"NTransaction Already Performed"'
			SELECT @ret = -1300
			GOTO ICVRETURN
		END

		-- call icv_trustmarque to void the original authorizaton and reapply

                if @auth_resp_flag in ('B','A','V') and @trx_type in ('B','A') and DATALENGTH(RTRIM(LTRIM(@auth_approval_code))) > 0
                begin

		  -- void original authorization
                  exec @ret = icv_trustmarque 'C2',@ccnumber,@ccexpmo,@ccexpyr,@auth_ord_amt, @response OUTPUT, @order_no, @ext, @prompt1, @trx_ctrl_num, @ar_customer_code, @nat_cur_code, 0 

                  if substring(@response,2,1) = 'N' 
                    GOTO ICVRETURN

                  select @auth_seq = isnull((select max(auth_sequence) from icv_ord_payment_dtl where order_no = @order_no and ext = @ext),1) + 1

                  if @order_no > 0
   	            SELECT @order_no_str = RTRIM(LTRIM(CONVERT(CHAR, @order_no))) + '.' + RTRIM(LTRIM(CONVERT(CHAR, @ext))) +
                      + '-' + Convert(CHAR, @auth_seq) 
                  
                end
           
	END
        Else
        begin
		  SELECT @buf = 'Invalid transaction type (' + rtrim(@transtype) + ')'
		  EXEC icv_Log_sp @buf, @LogActivity
		  SELECT @ret = -1311
		  SELECT @response = '"N' + 'Invalid transaction type (' + rtrim(@transtype) + ')"'
		  GOTO ICVRETURN
	end

	



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

	
  	EXEC @result = sp_OACreate 'tmif.TrustMarque.1',@tmif OUT
	IF @result <> 0 
	BEGIN
     		select @response = 'Error: OLE Error on sp_OACreate'
		SELECT @ret = -1000
     		GOTO ICVRETURN
	END 



	




	SELECT @customer_code = ''
	IF @order_no > 0
	BEGIN
	      IF @exist_orders_table = 1
	      BEGIN            
		SELECT @customer_code = cust_code, @ship_to_code = ship_to,
                  @orders_phone = phone					-- mls 10/27/03 SCR 31953
		  FROM orders (nolock)
		 WHERE order_no = @order_no  AND ext = @ext

		if exists (select 1 from config (nolock) where flag = 'ECOMM_DFLT_CUST' and value_str = LTRIM(RTRIM(@customer_code)))
                  select @ecomm_dflt_cust = 'Y'
              END 

	END
	ELSE
	BEGIN
		SELECT @customer_code = @ar_customer_code, @ship_to_code = ''		-- SCR 27204
	END

	IF DATALENGTH(ISNULL(RTRIM(LTRIM(@customer_code)),0)) = 0
	BEGIN
		SELECT @buf = 'Cannot locate customer_code ' + RTRIM(LTRIM(CONVERT(CHAR,@order_no))) + ',' + RTRIM(LTRIM(CONVERT(CHAR,@ext))) + ' - ' + RTRIM(LTRIM(@trx_ctrl_num))
		EXEC icv_Log_sp @buf, @LogActivity
		SELECT @ret = -1320
		SELECT @response = '"NNOCUST"'
		GOTO ICVRETURN
	END

	


	IF DATALENGTH(ISNULL(RTRIM(LTRIM(@ship_to_code)),0)) > 0
	BEGIN
		SELECT  @attention_name = attention_name,
			@attention_phone = attention_phone,
			@contact_name = contact_name,
			@contact_phone = contact_phone,
			@customer_name = ship_to_name,
			@address1 = addr1,
			@address2 = addr2, 
			@address3 = addr3,
			@city = city,
			@state = state,
			@country = country,
			@zipcode = postal_code,
			@customer_phone = phone_1
		  FROM  arshipto (nolock)
		 WHERE	customer_code = @customer_code
		   AND	ship_to_code = @ship_to_code
		SELECT @rowcount = @@rowcount
	END
	ELSE
	BEGIN
		SELECT  @attention_name = attention_name,
			@attention_phone = attention_phone,
			@contact_name = contact_name,
			@contact_phone = contact_phone,
			@customer_name = customer_name,
			@address1 = addr1,
			@address2 = addr2,
			@address3 = addr3,
			@city = city,
			@state = state,
			@country = country,
			@zipcode = postal_code,
			@customer_phone = phone_1
		  FROM  arcust (nolock)
		 WHERE	customer_code = @customer_code
		SELECT @rowcount = @@rowcount
	END

	IF @rowcount = 0
	BEGIN
		SELECT @buf = 'Cannot get customer information for ' + RTRIM(LTRIM(@customer_code)) + ' ' + RTRIM(LTRIM(@ship_to_code))
		EXEC icv_Log_sp @buf, @LogActivity
		SELECT @ret = -1320
		SELECT @response = '"NINVCUST"'
		GOTO ICVRETURN
	END

	





	SELECT @fullname = '', @phone = ''
	IF @name_to_use = 1
	BEGIN
		SELECT @fullname = @customer_name, @phone = @customer_phone
	END

	IF @name_to_use = 2
	BEGIN
		SELECT @fullname = @attention_name, @phone = @attention_phone
	END

	IF @name_to_use = 3
	BEGIN
		SELECT @fullname = @contact_name, @phone = @contact_phone
	END

	if @ecomm_dflt_cust = 'Y'							-- mls 10/27/03 SCR 31953
        begin
          select @phone = @orders_phone
        end
        else
        begin
	  IF DATALENGTH(ISNULL(RTRIM(LTRIM(@phone)),0)) = 0 BEGIN SELECT @phone = @customer_phone END
	  IF DATALENGTH(ISNULL(RTRIM(LTRIM(@phone)),0)) = 0 BEGIN SELECT @phone = @attention_phone END
	  IF DATALENGTH(ISNULL(RTRIM(LTRIM(@phone)),0)) = 0 BEGIN SELECT @phone = @contact_phone END
        end

	SELECT @firstname = '', @lastname = ''

	SELECT @i1 = CHARINDEX(' ', @fullname)
	SELECT @i = @i1
	IF @i1 = 0 SELECT @i1 = DATALENGTH(@fullname)
	SELECT @firstname = RTRIM(LTRIM(SUBSTRING(@fullname, 1, @i1)))
	SELECT @i1 = CHARINDEX(' ', LTRIM(SUBSTRING(@fullname, @i+1, DATALENGTH(@fullname))))
	IF @i1 = 0 SELECT @i1 = DATALENGTH(@fullname)
	SELECT @lastname = RTRIM(LTRIM(SUBSTRING(LTRIM(SUBSTRING(@fullname, @i+1, DATALENGTH(@fullname))), 1, @i1)))

	IF DATALENGTH(ISNULL(RTRIM(LTRIM(@firstname)),0)) = 0 OR DATALENGTH(ISNULL(RTRIM(LTRIM(@lastname)),0)) = 0 
	BEGIN
		SELECT @buf = 'Cannot parse customer name ' + RTRIM(LTRIM(@customer_code)) + ' - ' + RTRIM(LTRIM(@fullname))
		EXEC icv_Log_sp @buf, @LogActivity
		SELECT @ret = -1320
		SELECT @response = '"NINVCUST"'
		GOTO ICVRETURN
	END

	IF UPPER(@state) IN ('AA','AB','AE','AK','AL','AP','AR','AS','AZ','BC','CA','CO','CT','DC','DE','FL','FM','GA','GU','HI','IA','ID','IL','IN','KS','KY','LA','MA','MB','MD','ME','MH','MI','MN','MO','MP','MS','MT','NA','NB','NC','ND','NE','NF','NH','NJ','NM','NN','NS','NT','NV','NY','OH','OK','ON','OR','PA','PE','PQ','PR','PW','RI','SC','SD','SK','TN','TX','UT','VA','VI','VT','WA','WI','WV','WY','YT')
	BEGIN
		SELECT @state_code = UPPER(@state)
	END
	ELSE
	BEGIN
		SELECT @state_code = 'NA'
	END

	IF LOWER(@country) IN ('us','usa','united states') OR DATALENGTH(ISNULL(RTRIM(LTRIM(@country)),0)) = 0
	BEGIN
		SELECT @country_code = 'us'
	END
	ELSE
	BEGIN
		IF LOWER(@country) IN ('ad','ae','af','ag','ai','al','am','an','ao','aq','ar','as','at','au','aw','az','ba','bb','bd','be','bf','bg','bh','bi','bj','bm','bn','bo','br','bs','bt','bv','bw','by','bz','ca','cc','cf','cg','ch','ci','ck','cl','cm','cn','co','cr','cs','cu','cv','cx','cy','cz','de','dj','dk','dm','do','dz','ec','ee','eg','eh','er','es','et','fi','fj','fk','fm','fo','fr','ga','gb','gd','ge','gf','gh','gi','gl','gm','gn','gp','gq','gr','gt','gu','gw','gy','hk','hn','hr','ht','hu','id','ie','il','in','iq','ir','is','it','jm','jo','jp','ke','kg','kh','ki','km','kn','kp','kr','kw','ky','kz','la','lb','lc','li','lk','lr','ls','lt','lu','lv','ly','ma','mc','md','mg','mh','mk','ml','mm','mn','mo','mp','mq','mr','ms','mt','mu','mv','mw','mx','my','mz','na','nc','ne','nf','ng','ni','nl','no','np','nr','nt','nu','nz','om','ot','pa','pe','pf','pg','ph','pk','pl','pm','pn','pr','pt','pw','py','qa','re','ro','ru','rw','sa','sb','sc','sd','se','sg','sh','si','sk','sl','sm','sn','so','sr','st','su','sv','sy','sz','tc','td','tg','th','tj','tk','tm','tn','to','tp','tr','tt','tv','tw','tz','ua','ug','uk','um','us','uy','uz','va','vc','ve','vg','vi','vn','vu','wf','ws','ye','yt','yu','za','zm','zr','zw')
		BEGIN
			SELECT @country_code = LOWER(@country)
		END
		ELSE
		BEGIN
			SELECT @country_code = 'ot'
		END
	END

	--SCR 30221
	EXEC @result = sp_OASetProperty @tmif, 'IsTest', @istest
	IF @result <> 0 
	BEGIN
		EXEC icv_Convert_HRESULT_sp @result, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		EXEC icv_Get_OA_Message_sp @tmif, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		SELECT @response = 'Error: OLE Error on sp_OASetProperty for IsTest'
		SELECT @ret = -1090
     		GOTO ICVRETURN
	END
	--SCR 30221 END

	EXEC @result = sp_OASetProperty @tmif, 'FirstName', @firstname
	IF @result <> 0 
	BEGIN
		EXEC icv_Convert_HRESULT_sp @result, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		EXEC icv_Get_OA_Message_sp @tmif, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		SELECT @response = 'Error: OLE Error on sp_OASetProperty for FirstName'
		SELECT @ret = -1090
     		GOTO ICVRETURN
	END

	EXEC @result = sp_OASetProperty @tmif, 'LastName', @lastname
	IF @result <> 0 
	BEGIN
		EXEC icv_Convert_HRESULT_sp @result, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		EXEC icv_Get_OA_Message_sp @tmif, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		SELECT @response = 'Error: OLE Error on sp_OASetProperty for LastName'
		SELECT @ret = -1090
     		GOTO ICVRETURN
	END
	
	EXEC @result = sp_OASetProperty @tmif, 'Address1', @address1
	IF @result <> 0 
	BEGIN
		EXEC icv_Convert_HRESULT_sp @result, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		EXEC icv_Get_OA_Message_sp @tmif, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		SELECT @response = 'Error: OLE Error on sp_OASetProperty for Address1'
		SELECT @ret = -1090
     		GOTO ICVRETURN
	END

	EXEC @result = sp_OASetProperty @tmif, 'Address2', @address2
	IF @result <> 0 
	BEGIN
		EXEC icv_Convert_HRESULT_sp @result, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		EXEC icv_Get_OA_Message_sp @tmif, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		SELECT @response = 'Error: OLE Error on sp_OASetProperty for Address2'
		SELECT @ret = -1090
     		GOTO ICVRETURN
	END

	EXEC @result = sp_OASetProperty @tmif, 'Address3', @address3
	IF @result <> 0 
	BEGIN
		EXEC icv_Convert_HRESULT_sp @result, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		EXEC icv_Get_OA_Message_sp @tmif, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		SELECT @response = 'Error: OLE Error on sp_OASetProperty for Address3'
		SELECT @ret = -1090
     		GOTO ICVRETURN
	END

	EXEC @result = sp_OASetProperty @tmif, 'City', @city
	IF @result <> 0 
	BEGIN
		EXEC icv_Convert_HRESULT_sp @result, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		EXEC icv_Get_OA_Message_sp @tmif, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		SELECT @response = 'Error: OLE Error on sp_OASetProperty for Remote Address'
		SELECT @ret = -1090
     		GOTO ICVRETURN
	END

	EXEC @result = sp_OASetProperty @tmif, 'StateCode', @state_code
	IF @result <> 0 
	BEGIN
		EXEC icv_Convert_HRESULT_sp @result, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		EXEC icv_Get_OA_Message_sp @tmif, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		SELECT @response = 'Error: OLE Error on sp_OASetProperty for StateCode'
		SELECT @ret = -1090
     		GOTO ICVRETURN
	END

	EXEC @result = sp_OASetProperty @tmif, 'CountryCode', @country_code
	IF @result <> 0 
	BEGIN
		EXEC icv_Convert_HRESULT_sp @result, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		EXEC icv_Get_OA_Message_sp @tmif, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		SELECT @response = 'Error: OLE Error on sp_OASetProperty for CountryCode'
		SELECT @ret = -1090
     		GOTO ICVRETURN
	END

	EXEC @result = sp_OASetProperty @tmif, 'ZipCode', @zipcode
	IF @result <> 0 
	BEGIN
		EXEC icv_Convert_HRESULT_sp @result, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		EXEC icv_Get_OA_Message_sp @tmif, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		SELECT @response = 'Error: OLE Error on sp_OASetProperty for ZipCode'
		SELECT @ret = -1090
     		GOTO ICVRETURN
	END

	EXEC @result = sp_OASetProperty @tmif, 'PhoneNumber', @phone
	IF @result <> 0 
	BEGIN
		EXEC icv_Convert_HRESULT_sp @result, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		EXEC icv_Get_OA_Message_sp @tmif, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		SELECT @response = 'Error: OLE Error on sp_OASetProperty for PhoneNumber'
		SELECT @ret = -1090
     		GOTO ICVRETURN
	END

	EXEC @result = sp_OASetProperty @tmif, 'ShipToFirstName', @firstname
	IF @result <> 0 
	BEGIN
		EXEC icv_Convert_HRESULT_sp @result, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		EXEC icv_Get_OA_Message_sp @tmif, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		SELECT @response = 'Error: OLE Error on sp_OASetProperty for ShipToFirstName'
		SELECT @ret = -1090
     		GOTO ICVRETURN
	END

	EXEC @result = sp_OASetProperty @tmif, 'ShipToLastName', @lastname
	IF @result <> 0 
	BEGIN
		EXEC icv_Convert_HRESULT_sp @result, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		EXEC icv_Get_OA_Message_sp @tmif, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		SELECT @response = 'Error: OLE Error on sp_OASetProperty for ShipToLastName'
		SELECT @ret = -1090
     		GOTO ICVRETURN
	END

	EXEC @result = sp_OASetProperty @tmif, 'ShipToAddress1', @address1
	IF @result <> 0 
	BEGIN
		EXEC icv_Convert_HRESULT_sp @result, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		EXEC icv_Get_OA_Message_sp @tmif, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		SELECT @response = 'Error: OLE Error on sp_OASetProperty for ShipToAddress1'
		SELECT @ret = -1090
     		GOTO ICVRETURN
	END

	EXEC @result = sp_OASetProperty @tmif, 'ShipToAddress2', @address2
	IF @result <> 0 
	BEGIN
		EXEC icv_Convert_HRESULT_sp @result, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		EXEC icv_Get_OA_Message_sp @tmif, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		SELECT @response = 'Error: OLE Error on sp_OASetProperty for ShipToAddress2'
		SELECT @ret = -1090
     		GOTO ICVRETURN
	END

	EXEC @result = sp_OASetProperty @tmif, 'ShipToAddress3', @address3
	IF @result <> 0 
	BEGIN
		EXEC icv_Convert_HRESULT_sp @result, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		EXEC icv_Get_OA_Message_sp @tmif, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		SELECT @response = 'Error: OLE Error on sp_OASetProperty for ShipToAddress3'
		SELECT @ret = -1090
     		GOTO ICVRETURN
	END

	EXEC @result = sp_OASetProperty @tmif, 'ShipToCity', @city
	IF @result <> 0 
	BEGIN
		EXEC icv_Convert_HRESULT_sp @result, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		EXEC icv_Get_OA_Message_sp @tmif, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		SELECT @response = 'Error: OLE Error on sp_OASetProperty for ShipToCity'
		SELECT @ret = -1090
     		GOTO ICVRETURN
	END

	EXEC @result = sp_OASetProperty @tmif, 'ShipToStateCode', @state_code
	IF @result <> 0 
	BEGIN
		EXEC icv_Convert_HRESULT_sp @result, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		EXEC icv_Get_OA_Message_sp @tmif, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		SELECT @response = 'Error: OLE Error on sp_OASetProperty for ShipToStateCode'
		SELECT @ret = -1090
     		GOTO ICVRETURN
	END

	EXEC @result = sp_OASetProperty @tmif, 'ShipToCountryCode', @country_code
	IF @result <> 0 
	BEGIN
		EXEC icv_Convert_HRESULT_sp @result, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		EXEC icv_Get_OA_Message_sp @tmif, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		SELECT @response = 'Error: OLE Error on sp_OASetProperty for ShipToCountryCode'
		SELECT @ret = -1090
     		GOTO ICVRETURN
	END

	EXEC @result = sp_OASetProperty @tmif, 'ShipToZipCode', @zipcode
	IF @result <> 0 
	BEGIN
		EXEC icv_Convert_HRESULT_sp @result, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		EXEC icv_Get_OA_Message_sp @tmif, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		SELECT @response = 'Error: OLE Error on sp_OASetProperty for ShipToZipCode'
		SELECT @ret = -1090
     		GOTO ICVRETURN
	END

	EXEC @result = sp_OASetProperty @tmif, 'ShipToPhoneNumber', @phone
	IF @result <> 0 
	BEGIN
		EXEC icv_Convert_HRESULT_sp @result, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		EXEC icv_Get_OA_Message_sp @tmif, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		SELECT @response = 'Error: OLE Error on sp_OASetProperty for ShipToPhoneNumber'
		SELECT @ret = -1090
     		GOTO ICVRETURN
	END

	SELECT @nat_cur_code = ''
	IF @exist_orders_table = 1
	BEGIN          
	
	   SELECT @nat_cur_code = curr_key
	      FROM orders (nolock)
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

	IF @AddressVerification = '1'
	BEGIN

		SELECT @ix = CHARINDEX('/',@prompt1)				
		IF @ix <= 1 OR @ix >= DATALENGTH(RTRIM(LTRIM(@prompt1)))
		BEGIN
			SELECT @buf = 'Invalid prompt1 when AVS_MODE is on: ' + @prompt1
			EXEC icv_Log_sp @buf, @LogActivity
			SELECT @buf = 'AVS_MODE will be turned off for this transaction'
			EXEC icv_Log_sp @buf, @LogActivity
			SELECT @AddressVerification = '0'
		END
		ELSE
		BEGIN
			SELECT @zipcode = SUBSTRING( @prompt1, 1, @ix-1 ),
			       @address = SUBSTRING( @prompt1, @ix+1, DATALENGTH(@prompt1) )
			SELECT @buf = 'Zip: ' + @zipcode + ' Address: ' + @address
			EXEC icv_Log_sp @buf, @LogActivity
		END
	END


	Select @ord_total_str = RTRIM(LTRIM(STR(@ordtotal,18,2))),
		@ret = 0


        



	EXEC @result = sp_OASetProperty @tmif, 'RemoteAddr', @IPAddress
	IF @result <> 0 
	BEGIN
		EXEC icv_Convert_HRESULT_sp @result, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		EXEC icv_Get_OA_Message_sp @tmif, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		SELECT @response = 'Error: OLE Error on sp_OASetProperty for Remote Address'
		SELECT @ret = -1090
     		GOTO ICVRETURN
	END

        


	EXEC @result = sp_OASetProperty @tmif, 'CurrencyID', @CurrencyID
	IF @result <> 0 
	BEGIN
		EXEC icv_Convert_HRESULT_sp @result, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		EXEC icv_Get_OA_Message_sp @tmif, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		SELECT @response = 'Error: OLE Error on sp_OASetProperty for CurrencyID'
		SELECT @ret = -1090
     		GOTO ICVRETURN
	END
 
                                                                                                                                                                                                                                                               
	
	EXEC @result = sp_OASetProperty @tmif, 'IPAddress', @IPAddress
	IF @result <> 0 
	BEGIN
		EXEC icv_Convert_HRESULT_sp @result, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		EXEC icv_Get_OA_Message_sp @tmif, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		SELECT @response = 'Error: OLE Error on sp_OASetProperty for IPAddress'
		SELECT @ret = -1090
     		GOTO ICVRETURN
	END

	EXEC @result = sp_OASetProperty @tmif, 'Port', @Port
	IF @result <> 0 
	BEGIN
		EXEC icv_Convert_HRESULT_sp @result, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		EXEC icv_Get_OA_Message_sp @tmif, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		SELECT @response = 'Error: OLE Error on sp_OASetProperty for Port'
		SELECT @ret = -1090
     		GOTO ICVRETURN
	END

	EXEC @result = sp_OASetProperty @tmif, 'DemoMode', @DemoMode
	IF @result <> 0 
	BEGIN
		EXEC icv_Convert_HRESULT_sp @result, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		EXEC icv_Get_OA_Message_sp @tmif, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		SELECT @response = 'Error: OLE Error on sp_OASetProperty for DemoMode'
		SELECT @ret = -1090
     		GOTO ICVRETURN
	END


	EXEC @result = sp_OASetProperty @tmif, 'MerchantID', @MerchantID
	IF @result <> 0 
	BEGIN
		EXEC icv_Convert_HRESULT_sp @result, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		EXEC icv_Get_OA_Message_sp @tmif, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		SELECT @response = 'Error: OLE Error on sp_OASetProperty for MerchantID'
		SELECT @ret = -1090
     		GOTO ICVRETURN
	END

	EXEC @result = sp_OASetProperty @tmif, 'UserName', @UserName
	IF @result <> 0 
	BEGIN
		EXEC icv_Convert_HRESULT_sp @result, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		EXEC icv_Get_OA_Message_sp @tmif, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		SELECT @response = 'Error: OLE Error on sp_OASetProperty for UserName'
		SELECT @ret = -1090
     		GOTO ICVRETURN
	END

	EXEC @result = sp_OASetProperty @tmif, 'UserPassword', @UserPassword
	IF @result <> 0 
	BEGIN
		EXEC icv_Convert_HRESULT_sp @result, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		EXEC icv_Get_OA_Message_sp @tmif, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		SELECT @response = 'Error: OLE Error on sp_OASetProperty for UserPassword'
		SELECT @ret = -1090
     		GOTO ICVRETURN
	END

	EXEC @result = sp_OASetProperty @tmif, 'Timeout', @Timeout
	IF @result <> 0 
	BEGIN
		EXEC icv_Convert_HRESULT_sp @result, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		EXEC icv_Get_OA_Message_sp @tmif, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		SELECT @response = 'Error: OLE Error on sp_OASetProperty for Timeout'
		SELECT @ret = -1090
     		GOTO ICVRETURN
	END

	EXEC @result = sp_OASetProperty @tmif, 'AVSOption', @AddressVerification
	IF @result <> 0 
	BEGIN
		EXEC icv_Convert_HRESULT_sp @result, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		EXEC icv_Get_OA_Message_sp @tmif, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		SELECT @response = 'Error: OLE Error on sp_OASetProperty for AVSOption'
		SELECT @ret = -1090
     		GOTO ICVRETURN
	END


	if @csc <> ''
	begin
		EXEC @result = sp_OASetProperty @tmif, 'CVN', @csc
		IF @result <> 0 
		BEGIN
			EXEC icv_Convert_HRESULT_sp @result, @response OUT
			EXEC icv_Log_sp @response, @LogActivity
			EXEC icv_Get_OA_Message_sp @tmif, @response OUT
			EXEC icv_Log_sp @response, @LogActivity
			SELECT @response = 'Error: OLE Error on sp_OASetProperty for CVN'
			SELECT @ret = -1090
	     		GOTO ICVRETURN
		END
	end


	IF @order_no > 0
	BEGIN
		SELECT @buf = @order_no_str
                if exists (select 1 from config where flag = 'ECOMM_DFLT_CUST')
                begin
  		  IF EXISTS (SELECT 1 FROM ecomm_order_xref WHERE order_no = @order_no)			
		  BEGIN
			SELECT @buf = RTRIM(LTRIM(sf_order_no)) + '.' + RTRIM(LTRIM(CONVERT(CHAR, @ext))) +
                      + '-' + Convert(CHAR, @auth_seq) 
			  FROM ecomm_order_xref
			 WHERE order_no = @order_no
		  END
		end
	END
	ELSE
	BEGIN
		IF ( @transtype <> 'C3' )
			SELECT @buf= @trx_ctrl_num
		ELSE
			SELECT @buf= @cash_trx_ctrl_num
		
	
		IF (  @transtype IN ('CO','C0') AND LEN(@inv_trx_ctrl_num )<> 0 AND @is_order =0)
			SELECT @buf= @inv_trx_ctrl_num
	END
	IF len(isnull(@cca_trx_ctrl_num,''))<=0 	
		SELECT @cca_trx_ctrl_num=@buf
	EXEC @result = sp_OASetProperty @tmif, 'OrderNumber', @buf
	IF @result <> 0 
	BEGIN
		EXEC icv_Convert_HRESULT_sp @result, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		EXEC icv_Get_OA_Message_sp @tmif, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		SELECT @response = 'Error: OLE Error on sp_OASetProperty for OrderNumber'
		SELECT @ret = -1100
     		GOTO ICVRETURN
	END

	EXEC @result = sp_OASetProperty @tmif, 'AcctName', @prompt1
	IF @result <> 0 
	BEGIN
		EXEC icv_Convert_HRESULT_sp @result, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		EXEC icv_Get_OA_Message_sp @tmif, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
     		SELECT @response = 'Error: OLE Error on sp_OASetProperty for AcctName'
		SELECT @ret = -1100
     		GOTO ICVRETURN
	END

	EXEC @result = sp_OASetProperty @tmif, 'AcctNumber', @ccnumber
	IF @result <> 0 
	BEGIN
		EXEC icv_Convert_HRESULT_sp @result, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		EXEC icv_Get_OA_Message_sp @tmif, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
     		SELECT @response = 'Error: OLE Error on sp_OASetProperty for AcctNumber'
		SELECT @ret = -1100
     		GOTO ICVRETURN
	END

	




	IF ISNULL(DATALENGTH(RTRIM(LTRIM(@ccexpmo))),0) = 1
	BEGIN
		SELECT @ccexpmo = '0' + RTRIM(LTRIM(@ccexpmo))
	END
	IF ISNULL(DATALENGTH(RTRIM(LTRIM(@ccexpyr))),0) = 2
	BEGIN
		SELECT @ccexpyr = '20' + RTRIM(LTRIM(@ccexpyr))
	END

	SELECT @buf = @ccexpmo + @ccexpyr
	EXEC @result = sp_OASetProperty @tmif, 'ExpDate', @buf
	IF @result <> 0 
	BEGIN
		EXEC icv_Convert_HRESULT_sp @result, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		EXEC icv_Get_OA_Message_sp @tmif, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		SELECT @response = 'Error: OLE Error on sp_OASetProperty for ExpDate'
		SELECT @ret = -1110
     		GOTO ICVRETURN	END

	EXEC @result = sp_OASetProperty @tmif, 'Amount', @ord_total_str
	IF @result <> 0 
	BEGIN
		EXEC icv_Convert_HRESULT_sp @result, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		EXEC icv_Get_OA_Message_sp @tmif, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		SELECT @response = 'Error: OLE Error on sp_OASetProperty for Amount'
		SELECT @ret = -1130
     		GOTO ICVRETURN
	END

	


	SELECT @AcctType = 'CC'

	EXEC @result = sp_OASetProperty @tmif, 'AcctType', @AcctType
	IF @result <> 0 
	BEGIN
		EXEC icv_Convert_HRESULT_sp @result, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		EXEC icv_Get_OA_Message_sp @tmif, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		SELECT @response = 'Error: OLE Error on sp_OASetProperty for AcctType'
		SELECT @ret = -1130
     		GOTO ICVRETURN
	END

	


	IF @AddressVerification = '1'
	BEGIN
		EXEC @result = sp_OASetProperty @tmif, 'ZipCode', @zipcode
		IF @result <> 0 
		BEGIN
			EXEC icv_Convert_HRESULT_sp @result, @response OUT
			EXEC icv_Log_sp @response, @LogActivity
			EXEC icv_Get_OA_Message_sp @tmif, @response OUT
			EXEC icv_Log_sp @response, @LogActivity
			SELECT @response = 'Error: OLE Error on sp_OASetProperty for ZipCode'
			SELECT @ret = -1131
     			GOTO ICVRETURN
		END

		EXEC @result = sp_OASetProperty @tmif, 'Address1', @address
		IF @result <> 0 
		BEGIN
			EXEC icv_Convert_HRESULT_sp @result, @response OUT
			EXEC icv_Log_sp @response, @LogActivity
			EXEC icv_Get_OA_Message_sp @tmif, @response OUT
			EXEC icv_Log_sp @response, @LogActivity
			SELECT @response = 'Error: OLE Error on sp_OASetProperty for Address1'
			SELECT @ret = -1132
     			GOTO ICVRETURN
		END
	END

	


	IF @transtype = 'CO' OR
	   @transtype = 'C0' OR
	   @transtype = 'C5' OR
	   @transtype = 'C2'
	BEGIN

	






		SELECT  @AuthCode=SUBSTRING(prompt4_inp,0, CASE (CHARINDEX(':', prompt4_inp)) WHEN 0 THEN 7 ELSE CHARINDEX(':', prompt4_inp) END) ,
			@pttid=SUBSTRING(prompt4_inp,CHARINDEX(':', prompt4_inp)+1, LEN(prompt4_inp)-CHARINDEX(':', prompt4_inp))
		  FROM	arinppyt (nolock)
		 WHERE trx_ctrl_num= @trx_ctrl_num
		
		
		IF LEN(ISNULL(@AuthCode,''))= 0  OR
		  LEN(ISNULL(@pttid,''))= 0  
		BEGIN
			SELECT  @AuthCode=SUBSTRING(prompt4_inp,0, CASE (CHARINDEX(':', prompt4_inp)) WHEN 0 THEN 7 ELSE CHARINDEX(':', prompt4_inp) END) ,
			@pttid=SUBSTRING(prompt4_inp,CHARINDEX(':', prompt4_inp)+1, LEN(prompt4_inp)-CHARINDEX(':', prompt4_inp))
		 	FROM	arinptmp (nolock)
			WHERE trx_ctrl_num= @trx_ctrl_num

		END
		IF LEN(ISNULL(@AuthCode,''))= 0  OR
		  		LEN(ISNULL(@pttid,''))= 0  
			BEGIN
				SELECT  @AuthCode=SUBSTRING(prompt4_inp,0, CASE (CHARINDEX(':', prompt4_inp)) WHEN 0 THEN 7 ELSE CHARINDEX(':', prompt4_inp) END) ,
				@pttid=SUBSTRING(prompt4_inp,CHARINDEX(':', prompt4_inp)+1, LEN(prompt4_inp)-CHARINDEX(':', prompt4_inp))
			 	FROM	artrx (nolock)
				WHERE trx_ctrl_num= @trx_ctrl_num
	
			END
	
		IF LEN(ISNULL(@AuthCode,''))= 0  OR
		  LEN(ISNULL(@pttid,''))= 0  
			BEGIN
				SELECT  @AuthCode = ISNULL(approval_code, ''),
					@pttid = ISNULL(reference_no, ''),
					@org_amount=ord_amt
				  FROM	icv_ord_payment_dtl (nolock)
				 WHERE	order_no = @order_no
				   AND	ext = @ext
				   AND	auth_sequence = 0
			END
		SELECT @buf = '1. AuthCode: ' + ISNULL(@AuthCode, 'NULL') + ', PTTID: ' + ISNULL(@pttid, 'NULL')
		EXEC icv_Log_sp @buf, @LogActivity

		EXEC @result = sp_OASetProperty @tmif, 'AuthCode', @AuthCode
		IF @result <> 0 
		BEGIN
			EXEC icv_Convert_HRESULT_sp @result, @response OUT
			EXEC icv_Log_sp @response, @LogActivity
			EXEC icv_Get_OA_Message_sp @tmif, @response OUT
			EXEC icv_Log_sp @response, @LogActivity
			SELECT @response = 'Error: OLE Error on sp_OASetProperty for AuthCode'
			SELECT @ret = -1131
     			GOTO ICVRETURN
		END

		EXEC @result = sp_OASetProperty @tmif, 'PTTID', @pttid
		IF @result <> 0 
		BEGIN
			EXEC icv_Convert_HRESULT_sp @result, @response OUT
			EXEC icv_Log_sp @response, @LogActivity
			EXEC icv_Get_OA_Message_sp @tmif, @response OUT
			EXEC icv_Log_sp @response, @LogActivity
			SELECT @response = 'Error: OLE Error on sp_OASetProperty for PTTID'
			SELECT @ret = -1131
     			GOTO ICVRETURN
		END
	END

	



	IF  @transtype = 'C3'
	BEGIN	
		











               --SELECT 'CYANEZ CODE from the arinppyt'
                IF @order_no > 0
	        BEGIN
                   --SELECT 'THE TRANSACTION C3 IS FROM AR  '
                   --SELECT 'GET THE APROVAL CODE IS FROM ADM FOR REFUND'
                   SELECT @AuthCode = '' , @pttid = '' ,@trx_ctrl_num = '', @cash_trx_ctrl_num = ''  
		     IF @exist_orders_table = 1
		     BEGIN          
		          
                          --SELECT ' order_no = ' + STR(@order_no,10,0)
                          --SELECT ' ext      = ' + STR(@ext,10,0)    

				SELECT	@orig_no = ISNULL(orig_no,0),
					@orig_ext = ISNULL(orig_ext,0)
				  FROM	orders (nolock)
				 WHERE	order_no = @order_no
				   AND	ext = @ext

		               IF @orig_no = 0
                                  SELECT @orig_no = @order_no , @orig_ext = @ext


				SELECT  @AuthCode = ISNULL(approval_code, ''),
					@pttid = ISNULL(reference_no, '')
				  FROM	icv_ord_payment_dtl (nolock)
				 WHERE	order_no = @orig_no
				   AND	ext = @orig_ext
				   AND	auth_sequence = 0
				SELECT @reference = RTRIM(LTRIM(CONVERT(CHAR, @orig_no))) + '.' + RTRIM(LTRIM(CONVERT(CHAR, @ext)))
				SELECT @cca_trx_ctrl_num= RTRIM(LTRIM(CONVERT(CHAR, @orig_no))) + '.' + RTRIM(LTRIM(CONVERT(CHAR, @orig_ext)))
		     END 
		            
                            -- SELECT '@AuthCode = '+ ISNULL(@AuthCode,' ')
                            -- SELECT ' @pttid = ' + ISNULL (@pttid, ' ')
                            -- SELECT ' @reference = ' +  ISNULL (@reference, ' ')
                            -- SELECT ' @cca_trx_ctrl_num = ' +  ISNULL (@cca_trx_ctrl_num, ' ') 
	


                END 
                ELSE
                BEGIN
		--Rev 1.0	Cyanez This code was modified to 
		--fill @AuthCode and @pttid with AR information
			SELECT  @AuthCode=SUBSTRING(prompt4_inp,0, CASE (CHARINDEX(':', prompt4_inp)) WHEN 0 THEN 7 ELSE CHARINDEX(':', prompt4_inp) END) ,
				@pttid=SUBSTRING(prompt4_inp,CHARINDEX(':', prompt4_inp)+1, LEN(prompt4_inp)-CHARINDEX(':', prompt4_inp))
			  FROM	arinppyt 
			 WHERE trx_ctrl_num= @trx_ctrl_num
		
          
		
			IF LEN(ISNULL(@AuthCode,''))= 0  OR
			  LEN(ISNULL(@pttid,''))= 0  
			BEGIN
				SELECT  @AuthCode=SUBSTRING(prompt4_inp,0, CASE (CHARINDEX(':', prompt4_inp)) WHEN 0 THEN 7 ELSE CHARINDEX(':', prompt4_inp) END) ,
				@pttid=SUBSTRING(prompt4_inp,CHARINDEX(':', prompt4_inp)+1, LEN(prompt4_inp)-CHARINDEX(':', prompt4_inp))
			 	FROM	arinptmp 
				WHERE trx_ctrl_num= @trx_ctrl_num
	
			END
			IF LEN(ISNULL(@AuthCode,''))= 0  OR
		  		LEN(ISNULL(@pttid,''))= 0  
			BEGIN
				SELECT  @AuthCode=SUBSTRING(prompt4_inp,0, CASE (CHARINDEX(':', prompt4_inp)) WHEN 0 THEN 7 ELSE CHARINDEX(':', prompt4_inp) END) ,
				@pttid=SUBSTRING(prompt4_inp,CHARINDEX(':', prompt4_inp)+1, LEN(prompt4_inp)-CHARINDEX(':', prompt4_inp))
			 	FROM	artrx 
				WHERE trx_ctrl_num= @cash_trx_ctrl_num
	
                	END
	        END --ELSE

		SELECT @buf = '2. AuthCode: ' + ISNULL(@AuthCode, 'NULL') + ', PTTID: ' + ISNULL(@pttid, 'NULL')
		EXEC icv_Log_sp @buf, @LogActivity

		EXEC @result = sp_OASetProperty @tmif, 'AuthCode', @AuthCode
		IF @result <> 0 
		BEGIN
			EXEC icv_Convert_HRESULT_sp @result, @response OUT
			EXEC icv_Log_sp @response, @LogActivity
			EXEC icv_Get_OA_Message_sp @tmif, @response OUT
			EXEC icv_Log_sp @response, @LogActivity
			SELECT @response = 'Error: OLE Error on sp_OASetProperty for AuthCode'
			SELECT @ret = -1131
     			GOTO ICVRETURN
		END 

		EXEC @result = sp_OASetProperty @tmif, 'PTTID', @pttid
		IF @result <> 0 
		BEGIN
			EXEC icv_Convert_HRESULT_sp @result, @response OUT
			EXEC icv_Log_sp @response, @LogActivity
			EXEC icv_Get_OA_Message_sp @tmif, @response OUT
			EXEC icv_Log_sp @response, @LogActivity
			SELECT @response = 'Error: OLE Error on sp_OASetProperty for PTTID'
			SELECT @ret = -1131
     			GOTO ICVRETURN
		END
		--  	SELECT @buf = RTRIM(LTRIM(CONVERT(CHAR, @orig_no))) + '.' + RTRIM(LTRIM(CONVERT(CHAR, @orig_ext)))
		--  Rev 1.0 Cyanez  This code was modified to fill OrderNumber with AR informarion 
		IF @orig_no>0 
			SELECT @buf = RTRIM(LTRIM(CONVERT(CHAR, @orig_no))) + '.' + RTRIM(LTRIM(CONVERT(CHAR, @orig_ext)))
		ELSE
		BEGIN
			IF ( @transtype <> 'C3' )
				SELECT @buf= @trx_ctrl_num
			ELSE
				SELECT @buf= @cash_trx_ctrl_num
		
			IF (  @transtype IN ('CO','C0') AND LEN(@inv_trx_ctrl_num )<> 0 AND @is_order =0)
				SELECT @buf= @inv_trx_ctrl_num
		END
				

		EXEC @result = sp_OASetProperty @tmif, 'OrderNumber', @buf
		IF @result <> 0 
		BEGIN
			EXEC icv_Convert_HRESULT_sp @result, @response OUT
			EXEC icv_Log_sp @response, @LogActivity
			EXEC icv_Get_OA_Message_sp @tmif, @response OUT
			EXEC icv_Log_sp @response, @LogActivity
			SELECT @response = 'Error: OLE Error on sp_OASetProperty for OrderNumber'
			SELECT @ret = -1100
	     		GOTO ICVRETURN
		END
	END


	
	IF @transtype = 'C6'
	BEGIN
		EXEC @result = sp_OASetProperty @tmif, 'RequestType', 'A'
		IF @result <> 0 
		BEGIN
			EXEC icv_Convert_HRESULT_sp @result, @response OUT
			EXEC icv_Log_sp @response, @LogActivity
			EXEC icv_Get_OA_Message_sp @tmif, @response OUT
			EXEC icv_Log_sp @response, @LogActivity
			SELECT @response = 'Error: OLE Error on sp_OASetProperty for RequestType'
			SELECT @ret = -1130
	     		GOTO ICVRETURN
		END
	END

	
	IF @transtype = 'C4'
	BEGIN
		EXEC @result = sp_OASetProperty @tmif, 'RequestType', 'A'
		IF @result <> 0 
		BEGIN
			EXEC icv_Convert_HRESULT_sp @result, @response OUT
			EXEC icv_Log_sp @response, @LogActivity
			EXEC icv_Get_OA_Message_sp @tmif, @response OUT
			EXEC icv_Log_sp @response, @LogActivity
			SELECT @response = 'Error: OLE Error on sp_OASetProperty for RequestType'
			SELECT @ret = -1130
	     		GOTO ICVRETURN
		END
	END 

	
	IF @transtype = 'CO' OR @transtype = 'C0'
	BEGIN	
		EXEC @result = sp_OASetProperty @tmif, 'RequestType', 'D'
		IF @result <> 0 
		BEGIN
			EXEC icv_Convert_HRESULT_sp @result, @response OUT
			EXEC icv_Log_sp @response, @LogActivity
			EXEC icv_Get_OA_Message_sp @tmif, @response OUT
			EXEC icv_Log_sp @response, @LogActivity
			SELECT @response = 'Error: OLE Error on sp_OASetProperty for RequestType'
			SELECT @ret = -1130
	     		GOTO ICVRETURN
		END
	END 

	
	IF @transtype = 'C1'
	BEGIN
		EXEC @result = sp_OASetProperty @tmif, 'RequestType', 'S'
		IF @result <> 0 
		BEGIN
			EXEC icv_Convert_HRESULT_sp @result, @response OUT
			EXEC icv_Log_sp @response, @LogActivity
			EXEC icv_Get_OA_Message_sp @tmif, @response OUT
			EXEC icv_Log_sp @response, @LogActivity
			SELECT @response = 'Error: OLE Error on sp_OASetProperty for RequestType'
			SELECT @ret = -1130
	     		GOTO ICVRETURN
		END
	END

	
	IF @transtype = 'C3'
	BEGIN
		EXEC @result = sp_OASetProperty @tmif, 'RequestType', 'R'
		IF @result <> 0 
		BEGIN
			EXEC icv_Convert_HRESULT_sp @result, @response OUT
			EXEC icv_Log_sp @response, @LogActivity
			EXEC icv_Get_OA_Message_sp @tmif, @response OUT
			EXEC icv_Log_sp @response, @LogActivity
			SELECT @response = 'Error: OLE Error on sp_OASetProperty for RequestType'
			SELECT @ret = -1130
	     		GOTO ICVRETURN
		END
	END 

	
	IF @transtype = 'C2'
	BEGIN
		EXEC @result = sp_OASetProperty @tmif, 'RequestType', 'C'
		IF @result <> 0 
		BEGIN
			EXEC icv_Convert_HRESULT_sp @result, @response OUT
			EXEC icv_Log_sp @response, @LogActivity
			EXEC icv_Get_OA_Message_sp @tmif, @response OUT
			EXEC icv_Log_sp @response, @LogActivity
			SELECT @response = 'Error: OLE Error on sp_OASetProperty for RequestType'
			SELECT @ret = -1130
	     		GOTO ICVRETURN
		END
	END 

	
	IF @transtype = 'C5'
	BEGIN
		EXEC @result = sp_OASetProperty @tmif, 'RequestType', 'D'
		IF @result <> 0 
		BEGIN
			EXEC icv_Convert_HRESULT_sp @result, @response OUT
			EXEC icv_Log_sp @response, @LogActivity
			EXEC icv_Get_OA_Message_sp @tmif, @response OUT
			EXEC icv_Log_sp @response, @LogActivity
			SELECT @response = 'Error: OLE Error on sp_OASetProperty for RequestType'
			SELECT @ret = -1130
	     		GOTO ICVRETURN
		END
	END 

	if @csc <> ''
	begin
		EXEC @result = sp_OAMethod  @tmif, 'SubmitCVN'
			EXEC icv_Get_OA_Message_sp @tmif, @response OUT
			EXEC icv_Log_sp @response, @LogActivity
	end
	else
	begin
		EXEC @result = sp_OAMethod  @tmif, 'Submit'
			EXEC icv_Get_OA_Message_sp @tmif, @response OUT
			EXEC icv_Log_sp @response, @LogActivity	
	end

	IF @result <> 0 
	BEGIN
		EXEC icv_Convert_HRESULT_sp @result, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		EXEC icv_Get_OA_Message_sp @tmif, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		SELECT @response = 'Error: OLE Error on sp_OAMethod for Submit'
		SELECT @ret = -1130
     		GOTO ICVRETURN
	END

	


	IF @debug_level > 5
	BEGIN
		SELECT @buf = 'Dumping buffers to ' + RTRIM(LTRIM(@filename))
		EXEC icv_Log_sp @buf, @LogActivity

		EXEC @result = sp_OAMethod  @tmif, 'dumpBuffers', NULL, @filename
		IF @result <> 0 
		BEGIN
			EXEC icv_Convert_HRESULT_sp @result, @response OUT
			EXEC icv_Log_sp @response, @LogActivity
			EXEC icv_Get_OA_Message_sp @tmif, @response OUT
			EXEC icv_Log_sp @response, @LogActivity
			SELECT @response = 'Error: OLE Error on sp_OAMethod for dumpBuffers ' + RTRIM(LTRIM(@filename))
			SELECT @ret = -1130
	     		GOTO ICVRETURN
		END
	END

	


	EXEC @result = sp_OAGetProperty @tmif, 'AVSAddr', @AVSAddr OUT
	IF @result <> 0 
	BEGIN
		EXEC icv_Convert_HRESULT_sp @result, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		EXEC icv_Get_OA_Message_sp @tmif, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		SELECT @response = 'Error: OLE Error on sp_OAGetProperty for AVSAddr'
		SELECT @ret = -1130
     		GOTO ICVRETURN
	END

	EXEC @result = sp_OAGetProperty @tmif, 'AVSZip', @AVSZip OUT
	IF @result <> 0 
	BEGIN
		EXEC icv_Convert_HRESULT_sp @result, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		EXEC icv_Get_OA_Message_sp @tmif, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		SELECT @response = 'Error: OLE Error on sp_OAGetProperty for AVSZip'
		SELECT @ret = -1130
     		GOTO ICVRETURN
	END

	IF (@AVSAddr = 'Y') OR (@AVSZip = 'Y')
	BEGIN
		IF @IgnoreAddressFailure = 1
		BEGIN
			SELECT @result = 0
			EXEC icv_Log_sp 'AVS failure ignored', @LogActivity
		END
		ELSE
		BEGIN
			SELECT @response = '"NNAVS failed"'
			SELECT @ret = -1021
			GOTO ICVRETURN
		END
	END

	EXEC @result = sp_OAGetProperty @tmif, 'RespMsg', @RespMsg OUT
	IF @result <> 0 
	BEGIN
		EXEC icv_Convert_HRESULT_sp @result, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		EXEC icv_Get_OA_Message_sp @tmif, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		SELECT @response = 'Error: OLE Error on sp_OAGetProperty RespMsg'
		SELECT @ret = -1190
     		GOTO ICVRETURN
	END

	EXEC @result = sp_OAGetProperty @tmif, 'AuthCode', @AuthCode OUT
	IF @result <> 0 
	BEGIN
		EXEC icv_Convert_HRESULT_sp @result, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		EXEC icv_Get_OA_Message_sp @tmif, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		SELECT @response = 'Error: OLE Error on sp_OAGetProperty AuthCode'
		SELECT @ret = -1190
     		GOTO ICVRETURN
	END

	EXEC @result = sp_OAGetProperty @tmif, 'Comment1', @Comment1 OUT
	IF @result <> 0 
	BEGIN
		EXEC icv_Convert_HRESULT_sp @result, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		EXEC icv_Get_OA_Message_sp @tmif, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		SELECT @response = 'Error: OLE Error on sp_OAGetProperty Comment1'
		SELECT @ret = -1190
     		GOTO ICVRETURN
	END

	EXEC @result = sp_OAGetProperty @tmif, 'Comment2', @Comment2 OUT
	IF @result <> 0 
	BEGIN
		EXEC icv_Convert_HRESULT_sp @result, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		EXEC icv_Get_OA_Message_sp @tmif, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		SELECT @response = 'Error: OLE Error on sp_OAGetProperty Comment2'
		SELECT @ret = -1190
     		GOTO ICVRETURN
	END

	



	EXEC @result = sp_OAGetProperty @tmif, 'PTTID', @pttid OUT
	IF @result <> 0 
	BEGIN
		EXEC icv_Convert_HRESULT_sp @result, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		EXEC icv_Get_OA_Message_sp @tmif, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		SELECT @response = 'Error: OLE Error on sp_OAGetProperty PTTID'
		SELECT @ret = -1190
     		GOTO ICVRETURN
	END
	
--	EXEC @result = sp_OAGetProperty @tmif, 'Result', @RespCode OUT					-- mls 11/25/03 SCR 32136 start
	EXEC @result = sp_OAGetProperty @tmif, 'MessageCode', @RespCode OUT
	IF @result <> 0 
	BEGIN
		EXEC icv_Convert_HRESULT_sp @result, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		EXEC icv_Get_OA_Message_sp @tmif, @response OUT
		EXEC icv_Log_sp @response, @LogActivity
		SELECT @response = 'Error: OLE Error on sp_OAGetProperty RespCode'
		SELECT @ret = -1190
     		GOTO ICVRETURN
	END												-- mls 11/25/03 SCR 32136 end


	if (@csc <> '' AND ISNULL(@pttid,'') <> '' AND ISNULL(@AuthCode,'') <> '')
	begin

		EXEC @result = sp_OAGetProperty @tmif, 'CVNMSG', @CVNmsg OUT
		IF @result <> 0 
		BEGIN
			EXEC icv_Convert_HRESULT_sp @result, @response OUT
			EXEC icv_Log_sp @response, @LogActivity
			EXEC icv_Get_OA_Message_sp @tmif, @response OUT
			EXEC icv_Log_sp @response, @LogActivity
			SELECT @response = 'Error: OLE Error on sp_OAGetProperty CVNMessageCode'
			SELECT @ret = -1190
	     		GOTO ICVRETURN
		END


		IF @CVNmsg > 1
		begin
			







			EXEC @result = sp_OASetProperty @tmif, 'VersionUsed', '1'
			IF @result <> 0 
			BEGIN
				EXEC icv_Convert_HRESULT_sp @result, @response OUT
				EXEC icv_Log_sp @response, @LogActivity
				EXEC icv_Get_OA_Message_sp @tmif, @response OUT
				EXEC icv_Log_sp @response, @LogActivity
				SELECT @response = 'Error: OLE Error on sp_OASetProperty for VersionUsed'
				SELECT @ret = -1090
		     		GOTO ICVRETURN
			END

			EXEC @result = sp_OASetProperty @tmif, 'TransactionType', 'PT'
			IF @result <> 0 
			BEGIN
				EXEC icv_Convert_HRESULT_sp @result, @response OUT
				EXEC icv_Log_sp @response, @LogActivity
				EXEC icv_Get_OA_Message_sp @tmif, @response OUT
				EXEC icv_Log_sp @response, @LogActivity
				SELECT @response = 'Error: OLE Error on sp_OASetProperty for TransactionType'
				SELECT @ret = -1090
		     		GOTO ICVRETURN
			END

			EXEC @result = sp_OASetProperty @tmif, 'RequestType', 'C'
			IF @result <> 0 
			BEGIN
				EXEC icv_Convert_HRESULT_sp @result, @response OUT
				EXEC icv_Log_sp @response, @LogActivity
				EXEC icv_Get_OA_Message_sp @tmif, @response OUT
				EXEC icv_Log_sp @response, @LogActivity
				SELECT @response = 'Error: OLE Error on sp_OASetProperty for TransactionType'
				SELECT @ret = -1090
		     		GOTO ICVRETURN
			END

			EXEC @result = sp_OASetProperty @tmif, 'PTTID', @pttid
			IF @result <> 0 
			BEGIN
				EXEC icv_Convert_HRESULT_sp @result, @response OUT
				EXEC icv_Log_sp @response, @LogActivity
				EXEC icv_Get_OA_Message_sp @tmif, @response OUT
				EXEC icv_Log_sp @response, @LogActivity
				SELECT @response = 'Error: OLE Error on sp_OASetProperty for AuthCode'
				SELECT @ret = -1090
		     		GOTO ICVRETURN
			END

			EXEC @result = sp_OAMethod  @tmif, 'Submit'
				EXEC icv_Get_OA_Message_sp @tmif, @response OUT
				EXEC icv_Log_sp @response, @LogActivity
			IF @result <> 0 
			BEGIN
				EXEC icv_Convert_HRESULT_sp @result, @response OUT
				EXEC icv_Log_sp @response, @LogActivity
				EXEC icv_Get_OA_Message_sp @tmif, @response OUT
				EXEC icv_Log_sp @response, @LogActivity
				SELECT @response = 'Error: OLE Error on sp_OAMethod for Submit'
				SELECT @ret = -1130
		     		GOTO ICVRETURN
			END
			ELSE
			BEGIN
			   SET @AuthCode = '' 
			   set @RespCode = 2626			
			   SELECT @buf  = 'CVNMessage: ' + ISNULL( CAST(@CVNmsg as varchar(50)), 'NULL') + ''
			   EXEC icv_Log_sp @buf, @LogActivity
			END

		end 
	end



	SELECT @buf = '3. AuthCode: ' + ISNULL(@AuthCode, 'NULL') + ', PTTID: ' + ISNULL(@pttid, 'NULL')
	EXEC icv_Log_sp @buf, @LogActivity
	

	SELECT @buf = 'AuthCode: ' + RTRIM(LTRIM(@AuthCode)) + ', RespCode: ' + @RespCode + ', RespMsg: ' + RTRIM(LTRIM(@RespMsg))	-- mls 11/25/03 SCR 32136
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

	




	IF ISNULL(DATALENGTH(RTRIM(LTRIM(@AuthCode))),0) > 0 AND
	   @order_no > 0 AND (@transtype = 'C6' OR @transtype = 'C4' OR @transtype = 'C1') 
	BEGIN
		IF EXISTS (SELECT 1 FROM icv_ord_payment_dtl WHERE order_no = @order_no and ext = @ext AND auth_sequence = 0)
		BEGIN
			UPDATE icv_ord_payment_dtl
			   SET approval_code = @AuthCode, 
			       reference_no = @pttid,
                               response_flag = @trx_type,
                               ord_amt = @ord_total_str,
			       trans_type = @transtype,
                               sequence = @auth_seq
			 WHERE order_no = @order_no
			   AND ext = @ext
			   AND auth_sequence = 0

			EXEC icv_Log_sp 'Update pttid for order', @LogActivity
		END
		ELSE
		BEGIN
			INSERT INTO icv_ord_payment_dtl (order_no, ext, sequence, auth_sequence, response_flag, rej_reason, approval_code, reference_no, avs_result, proc_date, ord_amt, trans_type) VALUES
							(@order_no, @ext, 1, 0, @trx_type, '', @AuthCode, @pttid, '', GETDATE(), @ord_total_str, @transtype )
			EXEC icv_Log_sp 'Inserted pttid for order', @LogActivity
		END
	END

   
	-- DECLARE @payment_code varchar(8)
	
	
	IF @trx_type='B'  SELECT @trx_type='A'
	IF @trx_type='V'  SELECT @trx_type='C'
	IF @transtype='C3' SELECT @trx_type='R'
	IF len(@ar_customer_code)<=0 SELECT @ar_customer_code= @customer_code 
	IF @CurrencyID = '840' SELECT @nat_cur_code='USD' 

	SELECT @payment_code=payment_code FROM icv_cctype WHERE creditcard_prefix=substring(@ccnumber,1,1)
	EXEC icv_log_events_sp  @cca_trx_ctrl_num,
			        @ar_customer_code,
				@payment_code,
				@ccnumber,
				@trx_type,
				@org_amount,
				@ord_total_str,
				@nat_cur_code,
				@AuthCode,
				@pttid,
				1,
				@RespCode,
				@order_no,
				@reference,
				1

	






	-- Rev 1.0 Cyanez  This code was modfied to obatin error information on AR forms
	IF ISNULL(DATALENGTH(RTRIM(LTRIM(@AuthCode))),0) > 0
		IF @RespCode=2228 AND @transtype IN ('C3', 'C2', 'C0', 'CO') 	
			SELECT @response = CHAR(34) + 'N' + RTRIM(LTRIM(@RespMsg)) + CHAR(34), @ret = @RespCode
		ELSE
			SELECT @response = CHAR(34) + 'Y' + convert(char(6),RTRIM(LTRIM(@AuthCode))) + 
			  case when @order_no > 0 then isnull(@pttid,'        ') + ' ' else ':'+@pttid end + char(34)
	ELSE
	 IF  @transtype IN ('C1' ,'C6')	
			SELECT @response = CHAR(34) + 'N' + RTRIM(LTRIM(@RespMsg)) + CHAR(34), @ret = @RespCode
	   ELSE
		SELECT @response = CHAR(34) + 'N' + RTRIM(LTRIM(@RespMsg)) + CHAR(34), @ret = -1



ICVRETURN:
	IF @tmif > 0
	BEGIN
		EXEC @result = sp_OADestroy @tmif
		IF @result <> 0 
		BEGIN
			EXEC icv_Convert_HRESULT_sp @result, @response OUT
			EXEC icv_Log_sp @response, @LogActivity
			EXEC icv_Get_OA_Message_sp @tmif, @response OUT
			EXEC icv_Log_sp @response, @LogActivity
	     		select @response = 'Error: OLE Error on sp_OADestroy'
			SELECT @ret = -1200
	     		GOTO ICVRETURN
		END
	END
	RETURN @ret
END
GO
GRANT EXECUTE ON  [dbo].[icv_trustmarque] TO [public]
GO
