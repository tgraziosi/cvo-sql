SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
Copyright (c) 2012 Epicor Software (UK) Ltd
Name:			f_is_carton_autopack
Project ID:		Issue 690
Type:			Function
Description:	Returns if this is an autopack carton
Returns;		0 = not autopack carton
				1 = autopack carton
Developer:		Chris Tyler

History
-------
v1.0	26/07/12	CT	Original version

-- SELECT dbo.f_is_carton_autopack (123456) 

*/

CREATE FUNCTION [dbo].[f_is_carton_autopack] (@carton_no INT)
RETURNS SMALLINT
AS
BEGIN

	IF EXISTS(SELECT 1 FROM dbo.CVO_autopack_carton (NOLOCK) WHERE carton_no = @carton_no)
	BEGIN
		RETURN 1
	END
	
	RETURN 0

END

GO
GRANT REFERENCES ON  [dbo].[f_is_carton_autopack] TO [public]
GO
GRANT EXECUTE ON  [dbo].[f_is_carton_autopack] TO [public]
GO
