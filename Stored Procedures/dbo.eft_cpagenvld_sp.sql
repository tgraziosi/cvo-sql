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




















CREATE PROCEDURE [dbo].[eft_cpagenvld_sp]
@cash_account_code 				char(32),
@company_entry_description 		varchar(10),		
@effective_date					int,
@debug 							smallint

AS DECLARE 
@bank_account_num	 varchar(20)	 ,
@aba_number			 varchar(16)	 ,
@char_parm_1 varchar(12) ,
@char_parm_2	 varchar(8)	 ,
@result				 smallint ,
@e_code				 int,
@lenght 			 int	 ,
@check char(10) ,
@tax_id_num 		 char(10) ,
@year						smallint,
@month						smallint,
@day						smallint,
@datediff			smallint,
@date				datetime
		 
			 




	
SELECT @result 	 = 0,		 
 @char_parm_1 = ' ',
 	 @char_parm_2 = ' '








SELECT @aba_number = aba_number,
       @bank_account_num = bank_account_num	 
FROM apcash 
WHERE cash_acct_code = @cash_account_code





 
IF @bank_account_num = ' '
BEGIN
	SELECT @e_code = 33000

	EXEC @result= eft_erup_sp 
		 @e_code,
		 @char_parm_1,
		 @char_parm_2
END





 

IF @aba_number	= ' '
BEGIN
	SELECT @e_code = 33002

	EXEC @result= eft_erup_sp 
		 @e_code,
		 @char_parm_1,
		 @char_parm_2
END
















	



	EXEC appdtjul_sp 
	@year 	OUTPUT, 
	@month OUTPUT , 
	@day 	OUTPUT,
 	@effective_date

	SELECT @date = convert(datetime, convert(char,@month) + '/' + convert(char,@day) + '/' + convert(char,@year) )
	


	SELECT @datediff = datediff(dd,getdate(),@date)

	IF (@datediff > 173 or @datediff < -30)			
	BEGIN
	SELECT @e_code = 33011
	EXEC @result= eft_erup_sp 
	 @e_code,
	 @char_parm_1,
	 @char_parm_2
	END

GO
GRANT EXECUTE ON  [dbo].[eft_cpagenvld_sp] TO [public]
GO
