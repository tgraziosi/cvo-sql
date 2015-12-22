SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/                                                



























































































































































































































































CREATE PROC [dbo].[gl_ivcvtqty_sp]
	@item_code varchar(30),
	@from_uom varchar(10),
	@to_uom varchar(10),
	@qty float,
	@converted_qty float OUTPUT
AS
BEGIN

DECLARE
	@conv_factor float

	SELECT @conv_factor = 1.0





	IF EXISTS( SELECT name FROM sysobjects WHERE name = 'uom_table')
	BEGIN
		IF @from_uom <> @to_uom
		BEGIN
			

			SELECT @conv_factor = conv_factor
			FROM uom_table
			WHERE item = @item_code AND std_uom = @from_uom AND alt_uom = @to_uom

			

			IF ( @@rowcount = 0 )
			BEGIN
				SELECT @conv_factor = conv_factor
				FROM uom_table
				WHERE item = 'STD' AND std_uom = @from_uom AND alt_uom = @to_uom

				IF ( @@rowcount = 0 ) RETURN 8114
			END
		END
	END




	SELECT @converted_qty = @qty * @conv_factor
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[gl_ivcvtqty_sp] TO [public]
GO
