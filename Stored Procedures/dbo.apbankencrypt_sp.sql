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












CREATE PROCEDURE [dbo].[apbankencrypt_sp] (@vendor_code varchar(20),@pay_to_code varchar(10),@bank_account_num varchar (20))
AS
BEGIN
	SET NOCOUNT ON	
	
	OPEN SYMMETRIC KEY EnterpriseFSDSKey
	DECRYPTION BY CERTIFICATE CERTENTERPRISEFSDS;

	UPDATE  eft_apms 
	SET		bank_account_encrypted =  EncryptByKey(Key_GUID('EnterpriseFSDSKey'),CAST(@bank_account_num as varbinary)),
			bank_account_num = LEFT( '**********',10 - LEN(RIGHT(@bank_account_num,4))) +  RIGHT(@bank_account_num,4)
	WHERE	vendor_code = @vendor_code and pay_to_code = @pay_to_code

	
	CLOSE MASTER KEY
	CLOSE SYMMETRIC KEY EnterpriseFSDSKey
END

GO
GRANT EXECUTE ON  [dbo].[apbankencrypt_sp] TO [public]
GO
