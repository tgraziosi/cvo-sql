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















CREATE  FUNCTION  [dbo].[CCAEncrypt_fn] ( @acc varchar(300), @key varchar(255))
RETURNS varchar(300)
AS
BEGIN

	EXEC master..xp_EncryptAcct @key, @acc OUTPUT
	RETURN @acc
END


/**/                                              
GO
GRANT EXECUTE ON  [dbo].[CCAEncrypt_fn] TO [public]
GO
