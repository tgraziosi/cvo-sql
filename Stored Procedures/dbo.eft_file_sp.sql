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
























CREATE PROC [dbo].[eft_file_sp]
@eft_batch_num 					int ,
@cash_acct_code		       		char(32) ,
@tax_id_num 			 		char(10) ,
@company_name_apco		 		char(30), 
@payment_code	          		varchar(8),
@bank_account_num				char(20),
@bank_name       		 		char(40),
@bank_aba_number 		 		char(16),
@company_entry_description 		char(10),
@descriptive_date				int,
@effective_date					int	,
@addenda_flag					smallint ,
@total_float					float   OUTPUT ,
@originator_status_code			char(1),
@company_identification			char(10) ,
@company_data					char(20) ,
@file_id						char(1)	 ,
@debug 							smallint,
@file_fmt_code					varchar(8)

	
   
AS  DECLARE 
@payment_num 			 char(16),
@vendor_code			 char(12),
@pay_to_code			 char(8),
@amt_paid                float,
@invoice_num             char(16),
@invoice_date			 int,
@voucher_date_due		 int,
@header_flag             int,
@payment_amount          float ,
@payment_char15          char(15) ,
@payment_char10			 char(10),
@vendor_name			 char(40),
@vendor_account_num		 char(20),
@vendor_bank_name  		 char(40),
@vendor_aba_number 		 char(16),
@vendor_account_type 	 smallint,
@result					 smallint ,
@check_digit 			 char(1),
@sequence				 smallint ,
@transaction_code		 char(2) ,
@sequence_id			 int ,					
@total_credit            char(12),
@entry_hash				 char(10),
@entry_hash_11			 char(11),
@entry_hash_float		 float,
@entry_addenda_count     char(6),
@number					 float,
@company_16				 char(16) ,
@last_payment_num        char(16),
@individual_name		 char(22),
@company_name	 		 char(23)
		
		


		
		SELECT
		@header_flag  = 0	 ,
		@number = 1000000000 ,
		@company_16 = ' ' ,
		@last_payment_num = ' ',
		@sequence = 0	,
		@entry_hash_float = 0,
		@total_float = 0  ,
		@payment_char15 = ' ',
				
		@company_name = ltrim(substring(@company_name_apco, 1,23))


 		

OPEN SYMMETRIC KEY EnterpriseFSDSKey
DECRYPTION BY CERTIFICATE CERTENTERPRISEFSDS;

	 	  
WHILE 1=1 
BEGIN
SET ROWCOUNT 1

SELECT @payment_num = payment_num,
       @vendor_code = vendor_code,
       @pay_to_code = pay_to_code,
       @vendor_account_num 	= convert(varchar(max),decryptByKey(bank_account_encrypted)),
	   @vendor_aba_number 	= dest_aba_num  ,	
	   @vendor_account_type	= dest_account_type

 
FROM   eft_aptr
WHERE  cash_acct_code =  @cash_acct_code
AND    payment_code   =  @payment_code
AND    payment_num    >  @last_payment_num
AND    eft_batch_num  =	 @eft_batch_num
ORDER BY  cash_acct_code, payment_num

IF @@rowcount = 0 
BREAK 
SET ROWCOUNT 0


	  
		IF @header_flag = 0
		
		BEGIN

		


		 
			 SELECT @sequence =  @sequence + 1
		 
		     EXEC @result = eft_fhdr_sp	
	  	     @sequence,
	  	     @bank_aba_number,
	  	     @bank_name      ,
			 @company_identification     ,		-- SCR #334
			 @company_name ,
			 @file_id
			 	 

		IF (@debug > 0)
		BEGIN
		SELECT " *** eft_file_sp - Create the ACH File Header Record"
		END
		  

		


			 SELECT @sequence =  @sequence + 1
		 
			 EXEC @result = eft_chdr_sp	
	  	     @sequence,
			 @file_fmt_code,	
	  	     @company_name	,
			 @bank_aba_number  ,
		     @company_entry_description  ,	
			 @descriptive_date			,		
			 @effective_date,
			 @originator_status_code  ,	
			 @company_identification  ,	
			 @company_data				
			 
		IF (@debug > 0)
		BEGIN
		SELECT " *** eft_file_sp - Create the ACH File Company Record"
		END
	 				

		END

		



 		SELECT @vendor_name = ltrim(address_name) ,
		       @individual_name = addr1
		FROM   apmaster
		WHERE  vendor_code = @vendor_code
        AND    pay_to_code = @pay_to_code

		IF (@vendor_account_type = 0)	
		SELECT @transaction_code = '22'

		IF (@vendor_account_type = 1)	
		SELECT @transaction_code = '32'

 		 





        
	  
		 SELECT @entry_hash_float = @entry_hash_float  +
		        convert(float, substring (@vendor_aba_number,1,8 ) )
		
		IF (@debug > 0)
		BEGIN
		SELECT " *** eft_file_sp - entry_hash_float " 
		SELECT @entry_hash_float  
		END


		



 	   
 		SELECT @payment_amount = sum(amt_paid)
 		FROM   eft_aptr
 		WHERE  payment_num = @payment_num
		GROUP  BY payment_num 		
 	    		
 		SELECT @total_float = @total_float + @payment_amount

		


		 	 EXEC
			 @result = eft_flcv_sp	
	  	     @payment_amount,
	  	     @payment_char15 OUTPUT

		SELECT @payment_char10 = substring(@payment_char15,6,10)

	   	 			
		



		IF @vendor_aba_number IS NOT null
		 
		BEGIN
				
		EXEC @result = eft_chkd_sp
		@vendor_aba_number 	,
		@check_digit    OUTPUT	

		IF (@debug > 0)
		BEGIN
		SELECT " *** eft_file11_sp - Call the eft_chkd_sp"
		SELECT @check_digit
		SELECT @vendor_aba_number
		END
		
		END 

	   

		




		SELECT @header_flag = 1
		SELECT @sequence =  @sequence + 1

	   

		EXEC @result = eft_ctx_sp
		@sequence					  ,
	  	@addenda_flag                   ,
		@transaction_code               ,
		@vendor_aba_number 				,
		@vendor_account_num			    ,
		@payment_char10           		,
		@company_entry_description 		,
		@vendor_code				    ,
		@vendor_name					,
		@bank_aba_number 				,
		@payment_num                    , 
		@check_digit					,
		@file_fmt_code					,
		@individual_name				,
		@debug
		
		IF (@debug > 0)
		BEGIN
		SELECT " *** eft_file_sp - Call the eft_ctx_sp "
		SELECT @addenda_flag 
		END

		SELECT @last_payment_num = @payment_num
		 
END	  

		



	    SELECT @entry_hash_11 =	str (@entry_hash_float + @number * 10,11) 
		SELECT @entry_hash = substring (@entry_hash_11,2,10)
			       

	   	   
	    


		 	 EXEC
			 @result = eft_flcv_sp	
	  	     @total_float,
	  	     @payment_char15 OUTPUT

		SELECT @total_credit = substring(@payment_char15,4,12)

	  	

       	




		
		SELECT @entry_addenda_count =
			       substring (CONVERT (char(7),(count(*) +
			                 1000000)),2,6)  

        FROM eft_temp
		WHERE record_type_code IN ('6','7') 		  


		


		
		SELECT @sequence =  @sequence + 1
		 
		EXEC @result = eft_cctr_sp	
		@sequence					,
		@entry_addenda_count		,
		@company_identification		,			-- SCR#334
		@bank_aba_number			,
		@entry_hash					,
		@total_credit				


		IF (@debug > 0)
		BEGIN
		SELECT " *** eft_file_sp - Create the ACH Company Control Record"
		END


	    


		
		SELECT @sequence =  @sequence + 1
		 
		EXEC @result = eft_fctr_sp	
		@sequence,
		@entry_addenda_count				,
		@entry_hash					,
		@total_credit				
		
		IF (@debug > 0)
		BEGIN
		SELECT " *** eft_file_sp - Create the ACH File Header Record"
		END

		CLOSE MASTER KEY
		CLOSE SYMMETRIC KEY EnterpriseFSDSKey

GO
GRANT EXECUTE ON  [dbo].[eft_file_sp] TO [public]
GO
