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












CREATE PROCEDURE [dbo].[apcashbankencrypt_sp] (@cash_acct_code varchar(32),@bank_name varchar(40),@bank_account_num varchar(20))
	
AS
BEGIN
	SET NOCOUNT ON	
	
	OPEN SYMMETRIC KEY EnterpriseFSDSKey
	DECRYPTION BY CERTIFICATE CERTENTERPRISEFSDS;

	IF @bank_account_num <> ''
		UPDATE  apcash 
		SET		bank_account_encrypted =  EncryptByKey(Key_GUID('EnterpriseFSDSKey'),CAST(@bank_account_num as varbinary)),
				bank_account_num = LEFT( '**********',10 - LEN(RIGHT(@bank_account_num,4))) +  RIGHT(@bank_account_num,4)
		WHERE	cash_acct_code = @cash_acct_code and bank_name = @bank_name
	ELSE
		UPDATE  apcash 
		SET		bank_account_encrypted =  NULL
		WHERE	cash_acct_code = @cash_acct_code and bank_name = @bank_name
	
	CLOSE MASTER KEY
	CLOSE SYMMETRIC KEY EnterpriseFSDSKey
END

GO
GRANT EXECUTE ON  [dbo].[apcashbankencrypt_sp] TO [public]
GO
