SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AP\PROCS\eft_chvl.SPv - e7.2.2 : 1.2
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                




 
CREATE PROCEDURE [dbo].[eft_chvl_sp]
@cash_account_code char(32)

AS




DECLARE 
	 	@bank_account_num	 varchar(20)	 ,
	 @aba_number			 varchar(16)	 ,
 	@char_parm_1 varchar(12) ,
		@char_parm_2	 varchar(8)	 ,
	 	@result				 smallint ,
		@e_code				 int,
	 @lenght 			 int	 ,
		@check char(10) ,
		@tax_id_num 		 char(10) 
		 
			 

	SELECT @result 	 = 0 ,		 
	 @char_parm_1 = ' ',
 	 @char_parm_2 = ' '
			 			 


		
		 
		SELECT @tax_id_num = tax_id_num
		FROM apco

		IF (@tax_id_num = ' ')
		BEGIN
		SELECT @e_code = 33006
		EXEC @result= eft_erup_sp 
 		 @e_code,
	 		 @char_parm_1,
	 		 @char_parm_2

		END
	 

SELECT @aba_number = aba_number,
 @bank_account_num = bank_account_num	 
	 
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
		



 

IF @bank_account_num = ' '

 BEGIN
	SELECT @e_code = 33000
	EXEC @result = eft_erup_sp 
 	 @e_code,
	 	 @char_parm_1,
	 	 @char_parm_2
	
	 
 END	 






 

IF @aba_number	= ' '

 BEGIN
	SELECT @e_code = 33002
	EXEC @result = eft_erup_sp 
 	 @e_code,
	 	 @char_parm_1,
	 	 @char_parm_2
	
	 
 END	 


 ELSE 

 BEGIN




 
	SELECT @lenght = datalength(ltrim(@aba_number))

	IF (@lenght > 10)

	BEGIN
	SELECT @e_code = 33003
	EXEC @result = eft_erup_sp 
 	 @e_code,
	 	 @char_parm_1,
	 	 @char_parm_2
	 

	END	 
		

	

	 END 


		


GO
GRANT EXECUTE ON  [dbo].[eft_chvl_sp] TO [public]
GO
