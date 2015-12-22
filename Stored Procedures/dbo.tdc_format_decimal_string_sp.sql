SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_format_decimal_string_sp]
	@decimal_spaces	int,
	@value_str	varchar(255) OUTPUT
AS
	DECLARE
		@decimal_index	int

	SELECT @decimal_index = CHARINDEX('.', @value_str)
	
	IF @decimal_index = 0
		SELECT @value_str = @value_str + '.'
	
	SELECT @value_str = @value_str + '0000'

	SELECT @value_str = SUBSTRING(@value_str, 1, (CHARINDEX('.', @value_str)+(@decimal_spaces))
		)

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_format_decimal_string_sp] TO [public]
GO
