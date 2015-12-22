SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AP\PROCS\eft_ctx1.SPv - e7.2.2 : 1.2
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                




CREATE PROC [dbo].[eft_ctx1_sp]

@sequence					smallint ,
@transaction_code			char(2)	,
@vendor_aba_number			char(16),
@check_digit				char(1)	,
@vendor_bank_acct_num		char(20),
@payment_amount				char(10) ,
@vendor_code				char (15),
@addenda_numbers			char(4),
@vendor_name				char(40),
@addenda_record_indicator	char(1),
@bank_aba_number			char(16)	,
@ctx_sequence			 char(7)	 ,
@file_fmt_code				varchar(8), 
@individual_name			char(22)



AS DECLARE 
@addenda_type_code 				 	char(2),
@record_type_code					char(1),
@receiving_dfi_identification		char(9),
@dfi_account_number					char(17),
@identification_number				char(15),
@receiving_name_ctx						char(16),
@receiving_name_ccd						char(22),
@reserved 							char(2),
@discretionary_data					char(2),
@routing_number						char(8),
@rec_length							int,
@cr_flag							smallint






		
		
	 SELECT 
	 @record_type_code		='6',
	 @addenda_type_code			= '00' ,
	 @receiving_dfi_identification = substring(@vendor_aba_number,1,9),
	 @dfi_account_number	= substring(@vendor_bank_acct_num,1,17),
	 @identification_number = @vendor_code + '   ' ,		 
	 @reserved 			= ' ' ,
	 @discretionary_data	= ' ' ,
	 @routing_number	 = substring (@bank_aba_number,1,8),
	 @cr_flag = 1,
	 @rec_length = 94
	 
	 
	IF @file_fmt_code = 'CTX' 
	

	BEGIN 
	
	SELECT @receiving_name_ctx		 = (substring(@vendor_name,1,16)) 	 	 

	INSERT eft_temp

	( sequence ,	
	 record_type_code ,
	 addenda_count,
 eft_data,
 cr_flag,
	 rec_length
	)

	VALUES

	( @sequence,
	 @record_type_code ,
	 0,
	 @record_type_code +
	 @transaction_code +
	 @receiving_dfi_identification +
 
	 @dfi_account_number			 +	
	 @payment_amount +
	 @identification_number	 +	
	 @addenda_numbers				 +
	 @receiving_name_ctx				 +
	 @reserved						 +
	 @discretionary_data +
	 @addenda_record_indicator		 +
	 @routing_number 				 +
	 @ctx_sequence,					 
	 @cr_flag,
	 @rec_length
	)

	 END	


	IF @file_fmt_code = 'PPD' 
	
 
	BEGIN 	 	 

	INSERT eft_temp

	( sequence ,	
	 record_type_code ,
	 addenda_count,
 	 eft_data,
 	 cr_flag,
	 rec_length )

	VALUES

	( @sequence,
	 @record_type_code ,
	 0,
	 @record_type_code +
	 @transaction_code +
	 @receiving_dfi_identification +
	 @dfi_account_number			 +	
	 @payment_amount +
	 @identification_number	 +	
	
	
	
	 @individual_name +	 
	 @discretionary_data +
	 @addenda_record_indicator		 +
	 @routing_number 				 +
	 @ctx_sequence,
	 @cr_flag,
	 @rec_length					 
	 
	 )

	 END	

	IF @file_fmt_code = 'CCD' 
	
 
	BEGIN 	 	 

 SELECT @receiving_name_ccd		 = (substring(@vendor_name,1,22)) 

	INSERT eft_temp

	( sequence ,	
	 record_type_code ,
	 addenda_count,
 eft_data,
 cr_flag,
	 rec_length
	)

	VALUES

	( @sequence,
	 @record_type_code ,
	 0,
	 @record_type_code +
	 @transaction_code +
	 @receiving_dfi_identification +
 	
	 @dfi_account_number			 +	
	 @payment_amount +
	 @identification_number	 +	
	
	 @receiving_name_ccd				 +
	
	 @discretionary_data +
	 @addenda_record_indicator		 +
	 @routing_number 				 +
	 @ctx_sequence,					 
	 @cr_flag,
	 @rec_length
	)

	 END	
	 
GO
GRANT EXECUTE ON  [dbo].[eft_ctx1_sp] TO [public]
GO
