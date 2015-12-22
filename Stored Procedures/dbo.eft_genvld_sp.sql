SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AP\PROCS\eft_genvld.SPv - e7.2.2 : 1.2
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                





CREATE PROCEDURE [dbo].[eft_genvld_sp]
@cash_account_code 				char(32),
@file_fmt_code					varchar(8),
@company_entry_description 		char(10),
@effective_date					int,
@debug 							smallint


AS DECLARE 
@bank_account_num	varchar(20),
@char_parm_1 varchar(12),
@char_parm_2	 varchar(8),
@result				smallint,
@e_code				int		 

			 


SELECT @result 	 = 0,
 @char_parm_1 = ' ',
 @char_parm_2 = ' '

			 			 


SELECT @bank_account_num = bank_account_num	 
FROM apcash 
WHERE cash_acct_code = @cash_account_code
	 

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
		 

		EXEC @result = eft_ctxgenvld_sp
		@cash_account_code, 				
		@debug 						 	
	END 		

	IF (@file_fmt_code = 'CPA005CR')	
	BEGIN
		 

		EXEC @result = eft_cpagenvld_sp
		@cash_account_code, 				
		@company_entry_description,
		@effective_date,
		@debug 						 	
	END 		

	IF (@file_fmt_code = 'EXPRESS')	
	BEGIN
		 

		EXEC @result = eft_expgenvld_sp
		@cash_account_code, 				
		@company_entry_description,
		@effective_date,
		@debug 						 	
	END 		

END


GO
GRANT EXECUTE ON  [dbo].[eft_genvld_sp] TO [public]
GO
