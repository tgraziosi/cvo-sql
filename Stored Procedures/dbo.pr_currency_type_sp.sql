SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[pr_currency_type_sp]
AS

	DECLARE @currency_type  varchar(5), @currency_mask varchar(105)
	
	SELECT @currency_type = text_value FROM pr_config WHERE item_name = 'CURRENCY'

	IF  ( UPPER( @currency_type ) = 'HOME' )
		SELECT @currency_mask = currency_mask 
		FROM glcurr_vw, glco
		WHERE	currency_code = home_currency

	IF  ( UPPER( @currency_type ) = 'OPER' )
		SELECT @currency_mask = currency_mask 
		FROM glcurr_vw, glco
		WHERE	currency_code = oper_currency

	SELECT @currency_type, @currency_mask

GO
GRANT EXECUTE ON  [dbo].[pr_currency_type_sp] TO [public]
GO
