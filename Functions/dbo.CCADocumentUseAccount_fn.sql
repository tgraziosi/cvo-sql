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



















CREATE FUNCTION [dbo].[CCADocumentUseAccount_fn]      ( @order_no int, 
						@order_ext int, 
						@trx_ctrl_num varchar(16),
						@trx_type varchar(16), 
						@encoded_account varchar(255))
RETURNS smallint
BEGIN

	DECLARE @is_order smallint
	DECLARE @company_code varchar(8)
	DECLARE @decoded_account varchar(20)
	DECLARE @decrypted_account varchar(20)

	DECLARE @encrypted_account varchar(255)

		
	SELECT @company_code = company_code from glco
	
	IF( @order_no=0)
	BEGIN
		SELECT @is_order =0
	END
	ELSE
	BEGIN
		SELECT @is_order =1
	END

	SELECT @encrypted_account =''
	SELECT @encrypted_account = ccnumber 
	FROM CVO_Control..ccacryptaccts 
	WHERE  	( trx_ctrl_num = @trx_ctrl_num
		  AND trx_type = @trx_type
			  AND @is_order =0
		  AND company_code = @company_code  
	)
	OR 	( order_no = @order_no
		  AND order_ext = @order_ext
		  AND @is_order =1 
		  AND company_code = @company_code  
		)
	
	IF    (	LEN(@encrypted_account)> 10   )
		BEGIN

				
			SELECT @decoded_account = dbo.CCADecode_fn(@encoded_account)

			SELECT @decrypted_account= dbo.CCADecryptAcct_fn(@encrypted_account)
			
			IF (@decoded_account = @decrypted_account)
				BEGIN
					RETURN 1
				END
			ELSE
				BEGIN	
					RETURN 0
				END
		END
	ELSE
		BEGIN
			RETURN 0
		END 
	RETURN 0

END
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[CCADocumentUseAccount_fn] TO [public]
GO
