SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AP\PROCS\eft_expprovld.SPv - e7.2.2 : 1.2
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                



 
CREATE PROCEDURE [dbo].[eft_expprovld_sp]
@bank_account_num	varchar(20),
@aba_number 	varchar(16),
@account_type 		smallint ,
@char_parm1			varchar(12),
@char_parm2			varchar(8) 
 

AS



DECLARE 

	 @lenght 			 int	 ,
		@check char(10),
		@e_code				 int,
		@result				 smallint
		
		SELECT @result = 0 			

	 



IF @bank_account_num	= ' '

BEGIN

SELECT @e_code = 33000
EXEC @result = eft_erup_sp 
 @e_code,
	 @char_parm1,
	 @char_parm2
 
END		 
 

ELSE



	BEGIN

	SELECT @lenght = datalength(rtrim(@bank_account_num	))

	IF (@lenght > 17)

		BEGIN

		SELECT @e_code = 33001
		EXEC @result= eft_erup_sp 
 		 @e_code,
	 		 @char_parm1,
	 		 @char_parm2
								
	 	END

END			 




 

IF @aba_number	= ' '

 BEGIN
	SELECT @e_code = 33002
	EXEC @result = eft_erup_sp 
 	 @e_code,
	 	 @char_parm1,
	 	 @char_parm2
	
	 
 END	 


 ELSE 

 BEGIN




 
	SELECT @lenght = datalength(ltrim(@aba_number))

	IF (@lenght <> 10)

	BEGIN
	SELECT @e_code = 33014
	EXEC @result = eft_erup_sp 
 	 @e_code,
	 	 @char_parm1,
	 	 @char_parm2
	 

	END	 

 END

	 
GO
GRANT EXECUTE ON  [dbo].[eft_expprovld_sp] TO [public]
GO
