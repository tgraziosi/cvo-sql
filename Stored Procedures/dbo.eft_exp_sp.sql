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












CREATE PROC [dbo].[eft_exp_sp]
@eft_batch_num 					int,
@cash_acct_code		       		char(32),
@payment_code	          		varchar(8),
@effective_date					int	,
@total_float					float   OUTPUT,
@debug 							smallint


   
AS  DECLARE 
@payment_num 			 char(16),
@vendor_code			 char(12),
@pay_to_code			 char(8),
@vendor_account_num		 char(17),
@vendor_aba_number 		 char(10),
@vendor_name			 char(35),
@vendor_addr2			 char(35),
@vendor_addr3			 char(35),
@vendor_city_state		 char(20),
@payment_amount          float ,
@result					 smallint ,
@payment_char15_dec3	 char(15),
@year					 smallint,
@month					 smallint,
@day					 smallint,
@value_date				 char(8),
@record_type_code		 char(1),
@header_flag             int,
@last_payment_num        char(16),
@sequence				 smallint ,
@payment_char15          char(15) ,
@reserved_num 			 char(25),
@reserved_blank			 char(255),
@credit_currency_code	 char(3),
@credit_country_code	 char(2),
@vendor_country_code	 char(2),
@charges				 char(3),
@pay_method_code		 char(1),
@template_id			 char(8),
@rec_length				 int,
@cr_flag				 smallint


		




SELECT
@total_float = 0  ,
@header_flag  = 0	 ,
@last_payment_num = ' ',
@sequence = 0	,
@payment_char15 = ' ',
@reserved_num 	= '0000000000000000000000000',
@reserved_blank = ' ',
@credit_currency_code = 'CAD',
@credit_country_code = 'CA',
@vendor_country_code = 'CA',
@charges = 'OUR',
@pay_method_code = '2',
@template_id = ltrim(@payment_code),
@cr_flag = 0,
@rec_length = 255



OPEN SYMMETRIC KEY EnterpriseFSDSKey
DECRYPTION BY CERTIFICATE CERTENTERPRISEFSDS;

WHILE 1=1 
BEGIN
	SET ROWCOUNT 1

	SELECT @payment_num = payment_num,
	       @vendor_code = vendor_code,
	       @pay_to_code = pay_to_code,
	       --@vendor_account_num 	= substring(dest_account_num,1,17),
		   @vendor_account_num 	= substring(convert(varchar(max),decryptByKey(bank_account_encrypted)),1,17),
		   @vendor_aba_number 	= substring(dest_aba_num,1,10)
	FROM   eft_aptr
	WHERE  cash_acct_code =  @cash_acct_code
	AND    payment_code   =  @payment_code
	AND    payment_num    >  @last_payment_num
	AND    eft_batch_num  =	 @eft_batch_num
	ORDER BY  cash_acct_code, payment_num


	IF @@rowcount = 0 
	BREAK 

	SET ROWCOUNT 0
	  
	



	SELECT @vendor_name = substring(ltrim(address_name),1,35),
		   @vendor_addr2 = substring(ltrim(addr2),1,35),
		   @vendor_addr3 = substring(ltrim(addr3),1,35),
		   @vendor_city_state = substring((ltrim(addr4) + ltrim(addr5)),1,20)
	FROM   apmaster
	WHERE  vendor_code = @vendor_code
	AND    pay_to_code = @pay_to_code	

	



	SELECT @payment_amount = sum(amt_paid)
	FROM   eft_aptr
	WHERE  payment_num = @payment_num
	GROUP  BY payment_num 		
	    		
	SELECT @total_float = @total_float + @payment_amount

	


	
	EXEC
	@result = eft_flcv_sp	
  	@payment_amount,
  	@payment_char15 OUTPUT
	
	SELECT @payment_char15_dec3 = substring(@payment_char15,2,14) + "0"

	



	EXEC appdtjul_sp 
	@year 	OUTPUT, 
	@month  OUTPUT , 
	@day  	OUTPUT,
	@effective_date

	SELECT @value_date = convert(char(2),substring(str(100+@day,3),2,2)) +
						 convert(char(2),substring(str(100+@month,3),2,2)) +
						 convert(char(4),@year) 
	 			
	IF @header_flag = 0
	BEGIN
		SELECT @record_type_code = 'A'

		IF (@debug > 0)
		BEGIN
			SELECT " *** eft_exp_sp - EFT Express first row inserted into eft_temp"
		END
	END

	



	SELECT @rec_length = 245

	INSERT eft_temp
  
	( sequence,		
   	record_type_code,
   	addenda_count,
	eft_data,
	cr_flag,
	rec_length  )

	VALUES

	( @sequence,
  	@record_type_code,
  	0,
	@template_id					+	
	@payment_char15_dec3			+	
	substring(@reserved_blank,1,15)	+	
	@value_date						+	
	substring(@reserved_blank,1,15)	+	
	@vendor_aba_number				+	
	@vendor_account_num				+	
	substring(@reserved_blank,1,27)	+	
	@credit_currency_code			+	
	substring(@reserved_blank,1,125)+	
	@credit_country_code,				
	@cr_flag,
	@rec_length )


	IF (@debug > 0)
	BEGIN
		SELECT " *** eft_exp_sp - part 1 into eft_temp "
		SELECT @sequence 
	END


	SELECT @header_flag = 1
	SELECT @record_type_code = 'C'
	SELECT @sequence =  @sequence + 1

	



	SELECT @cr_flag = 1,
		   @rec_length = 131

	INSERT eft_temp
  
	( sequence,		
   	record_type_code,
   	addenda_count,
	eft_data,
	cr_flag,
	rec_length  )

	VALUES

	( @sequence,
  	@record_type_code,
  	0,
	@vendor_name					+	
	@vendor_addr2					+	
	@vendor_addr3					+	
	@vendor_city_state				+	
	@vendor_country_code			+	
	@charges						+	
	@pay_method_code,					
	@cr_flag,
	@rec_length )



	IF (@debug > 0)
	BEGIN
		SELECT " *** eft_exp_sp - part 2 into eft_temp "
		SELECT @sequence 
	END




	


	SELECT @sequence =  @sequence + 1

	



	INSERT eft_temp
  
	( sequence,		
   	record_type_code,
   	addenda_count,
   	eft_data  )

	VALUES

	( @sequence,
  	@record_type_code,
  	0,
	substring(@reserved_blank,1,255))


	IF (@debug > 0)
	BEGIN
		SELECT " *** eft_exp_sp - part 3 into eft_temp "
		SELECT @sequence 
	END


	SELECT @sequence =  @sequence + 1

	



	INSERT eft_temp
  
	( sequence,		
   	record_type_code,
   	addenda_count,
   	eft_data  )

	VALUES

	( @sequence,
  	@record_type_code,
  	0,
	substring(@reserved_blank,1,111))


	IF (@debug > 0)
	BEGIN
		SELECT " *** eft_exp_sp - part 4 into eft_temp "
		SELECT @sequence 
	END




	SELECT @sequence =  @sequence + 1

	SELECT @last_payment_num = @payment_num
		
END	  

CLOSE MASTER KEY
CLOSE SYMMETRIC KEY EnterpriseFSDSKey

GO
GRANT EXECUTE ON  [dbo].[eft_exp_sp] TO [public]
GO
