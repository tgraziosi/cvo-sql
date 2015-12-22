SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AP\PROCS\eft_provld.SPv - e7.2.2 : 1.2
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                




 
CREATE PROCEDURE [dbo].[eft_provld_sp]
@set_posted_flag 	smallint,
@file_fmt_code		varchar(8)


AS






DECLARE 
	 	@vendor_code		 varchar(12)	 ,
		@pay_to_code		 varchar(8)		 ,
	 	@bank_account_num	 varchar(20)	 ,
	 @aba_number			 varchar(16)	 ,
 @last_vendor_code varchar(12) ,
		@last_pay_to_code varchar(8)	 ,
		@char_parm_1 varchar(12) ,
		@char_parm_2	 varchar(8)	 ,
		@account_type		 smallint ,
		@result				 smallint ,
		@e_code				 int		 
			 

	SELECT @last_vendor_code	= ' ',
		 @last_pay_to_code	= ' ',
		 @result 				= 0 		 


 
WHILE 1=1 
BEGIN
SET ROWCOUNT 1

SELECT distinct 
@vendor_code = vendor_code ,
@pay_to_code = pay_to_code
FROM apinppyt
WHERE posted_flag = @set_posted_flag
AND (vendor_code + pay_to_code) > (@last_vendor_code + @last_pay_to_code)
ORDER BY vendor_code , pay_to_code

IF @@rowcount = 0 
BREAK 
SET ROWCOUNT 0

	 
SELECT @char_parm_1 = @vendor_code,
 @char_parm_2 = @pay_to_code
	 

SELECT @bank_account_num = bank_account_num,
 @aba_number = aba_number	 ,
	 @account_type = account_type

FROM eft_apms 
WHERE vendor_code = @vendor_code
AND pay_to_code = @pay_to_code

	 
		IF (@@rowcount = 0)

	 	BEGIN
		SELECT @e_code = 33005
		EXEC @result= eft_erup_sp 
 		 @e_code,
	 		 @char_parm_1,
	 		 @char_parm_2
		END		
	 		
		ELSE
		
		BEGIN
			

			IF (@file_fmt_code IN('CTX','PPD'))	
			BEGIN
				 

				EXEC @result = eft_ctxprovld_sp
				@bank_account_num	,
				@aba_number 	,
				@account_type 	 ,
				@char_parm_1 ,		
			 	@char_parm_2
			END 		

			IF (@file_fmt_code = 'CPA005CR')	
			BEGIN
				 

				EXEC @result = eft_cpaprovld_sp
				@bank_account_num	,
				@aba_number 	,
				@account_type 	 ,
				@char_parm_1 ,		
			 	@char_parm_2
			END 		

			IF (@file_fmt_code = 'EXPRESS')	
			BEGIN
				 

				EXEC @result = eft_expprovld_sp
				@bank_account_num	,
				@aba_number 	,
				@account_type 	 ,
				@char_parm_1 ,		
			 	@char_parm_2
			END 		
		END



 SELECT @last_vendor_code = @vendor_code,
 @last_pay_to_code = @pay_to_code

END 

SET rowcount 0

		UPDATE apinppyt
 		SET hold_flag = 1 ,
 		print_batch_num = 0,
		process_group_num = " ",
 		posted_flag = 0
		FROM apinppyt, eft_errlst
 		WHERE vendor_code = char_parm_1
 		AND pay_to_code = char_parm_2 
 		AND posted_flag = @set_posted_flag


GO
GRANT EXECUTE ON  [dbo].[eft_provld_sp] TO [public]
GO
