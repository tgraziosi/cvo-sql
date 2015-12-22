SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2009 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2009 Epicor Software Corporation, 2006    
                  All Rights Reserved                    
*/                                                













CREATE PROC [dbo].[eft_cpa_sp]
@eft_batch_num 					int,
@cash_acct_code		       		char(32),
@company_name_apco 		 		char(30),
@payment_code	          		varchar(8),
@company_entry_description 		char(10),
@effective_date					int,
@total_float					float   OUTPUT,		
@company_identification			char(10),
@transaction_code		 		char(3),
@debug 							smallint,
@rb_processing_centre			char(5)

		
   
AS  DECLARE 
@payment_num 			 char(16),
@vendor_code			 char(12),
@pay_to_code			 char(8),
@header_flag             int,
@payment_amount          float ,
@payment_char15          char(15) ,
@payment_char10			 char(10),
@vendor_name			 char(30),
@vendor_account_num		 char(12),
@vendor_aba_number 		 char(9),
@result					 smallint ,
@sequence				 smallint ,
@total_credit            char(14),
@last_payment_num        char(16),
@client_num				 char(10),
@segment				 smallint,
@processing_centre		 char(5),
@file_creation_num		 char(4),
@client_name			 char(30),
@description			 char(15),		
@date_doc			 	 int,
@curr_code				 char(3)  
		
		


		
		SELECT
		@header_flag  = 0	 ,
		@last_payment_num = ' ',
		@sequence = 0	,
		@total_float = 0  ,
		@payment_char15 = ' ',
		@segment = 1


		SELECT
		@client_num = substring(ltrim(@company_identification), 1,10),
		@file_creation_num = substring(convert(char(5),10000+@eft_batch_num),2,4),
		@processing_centre = substring(ltrim(@rb_processing_centre),1,5),
		@client_name = ltrim(@company_name_apco)
	 	  


OPEN SYMMETRIC KEY EnterpriseFSDSKey
DECRYPTION BY CERTIFICATE CERTENTERPRISEFSDS;
 	  
WHILE 1=1
BEGIN
SET ROWCOUNT 1

SELECT @payment_num = payment_num,
       @vendor_code = vendor_code,
       @pay_to_code = pay_to_code,
      -- @vendor_account_num 	= substring(ltrim(dest_account_num),1,12),
	   @vendor_account_num 	= substring(convert(varchar(max),decryptByKey(bank_account_encrypted)),1,12),	
	   @vendor_aba_number 	= substring(ltrim(dest_aba_num),1,9),
	   @description = substring(ltrim(description),1,15),
	   @curr_code = substring(nat_cur_code, 1,3)			
FROM   eft_aptr
WHERE  cash_acct_code =  @cash_acct_code
AND    payment_code   =  @payment_code
AND    payment_num    >  @last_payment_num
AND    eft_batch_num  =	 @eft_batch_num
ORDER BY  cash_acct_code, payment_num

IF @@rowcount = 0 
BREAK 


SELECT @date_doc = date_doc
FROM   apinppyt a, eft_aptr b
WHERE  a.trx_ctrl_num   =  b.payment_num
AND    b.cash_acct_code =  @cash_acct_code
AND    b.payment_code   =  @payment_code
AND    b.payment_num	=  @payment_num
AND    b.eft_batch_num  =  @eft_batch_num


SET ROWCOUNT 0


	  
		IF @header_flag = 0
		BEGIN
			


			 
				SELECT @sequence =  @sequence + 1
			 
			    EXEC @result = eft_cpahdr_sp	
		  	    @sequence,
		  	    @client_num,
		  	    @file_creation_num,
				@effective_date,
				@processing_centre,
				@debug,
				@curr_code		

				



				SELECT @sequence =  @sequence + 6

			IF (@debug > 0)
			BEGIN
			SELECT " *** eft_cpah_sp - Create the CPA File Header Record"
			END
		END

		SELECT @header_flag = 1
		SELECT @sequence =  @sequence + 1

		



 		SELECT @vendor_name = substring(ltrim(address_name),1,30)
		FROM   apmaster
		WHERE  vendor_code = @vendor_code
		AND	   pay_to_code = @pay_to_code

		



 		SELECT @payment_amount = sum(amt_paid)
 		FROM   eft_aptr
 		WHERE  payment_num = @payment_num
		GROUP  BY payment_num 		
 	    		
 		SELECT @total_float = @total_float + @payment_amount

		


		 	 EXEC @result = eft_flcv_sp	
	  	     @payment_amount,
	  	     @payment_char15 OUTPUT

		SELECT @payment_char10 = substring(@payment_char15,6,10)
 	 			

		EXEC @result = eft_CPADtl_sp
		@sequence			     		,
		@client_name		            ,
		@vendor_aba_number 				,
		@vendor_account_num			    ,
		@payment_char10           		,
		@vendor_code				    ,
		@vendor_name					,
		@payment_num                    , 
		@description					,
		@segment						,
		@client_num 	  				,
		@file_creation_num				,
		@date_doc						,
		@transaction_code				,	
		@debug
		
		IF (@debug > 0)
		BEGIN
		SELECT " *** eft_cpa_sp - Call the EFT_CPADtl_sp "
		SELECT @sequence 
		END

		SELECT @last_payment_num = @payment_num
		SELECT @segment = @segment + 1
		

		



		IF @segment = 7
		BEGIN
        SELECT @segment = 1
		END
		 
END	  
		




	IF @segment > 1
	BEGIN
		WHILE @segment < 7
		BEGIN
			SELECT @sequence = @sequence + 1

			EXEC @result = eft_cpad2_sp
			@sequence,
			@segment,
			@debug
			
			IF (@debug > 0)
			BEGIN
			SELECT " *** eft_cpad2_sp - Call the eft_cpad2_sp "
			SELECT @sequence 
			END

			SELECT @segment = @segment + 1
		END
	END

		    


			 	 EXEC
				 @result = eft_flcv_sp	
		  	     @total_float,
		  	     @payment_char15 OUTPUT

			SELECT @total_credit = substring(@payment_char15,2,15)

		  	
		    


			
			SELECT @sequence =  @sequence + 1
			 
			EXEC @result = eft_cpaf_sp	
			@sequence,
			@client_num,
			@file_creation_num,
			@total_credit				
			
			IF (@debug > 0)
			BEGIN
			SELECT " *** eft_cpa_sp - Create the CPA File Footer Record"
			END

CLOSE MASTER KEY
CLOSE SYMMETRIC KEY EnterpriseFSDSKey


GO
GRANT EXECUTE ON  [dbo].[eft_cpa_sp] TO [public]
GO
