SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- RETURNS: position to split string 
-- v1.0 CT 07/03/2014	Checks if position passed in is ok to split string, ensures string isn't split on a quote

-- SELECT dbo.f_string_split_position ('CH215BRO5418', 5)

CREATE FUNCTION [dbo].[f_string_split_position]	(@string	VARCHAR(2000), 
											 @pos		SMALLINT) 
RETURNS SMALLINT
AS
BEGIN
	DECLARE @char CHAR(1)

	IF LEN(@string) < @pos
	BEGIN
		RETURN LEN(@string)
	END

	WHILE 1=1 
	BEGIN
		
		SET @char = SUBSTRING(@string,@pos,1)
		
		-- If the character isn't a quote then exit
		IF @char <> ''''
			BREAK

		-- If character is a quote then move back one character
		SET @pos = @pos - 1

		IF @pos = 0
			BREAK

	END

	RETURN @pos


END
GO
GRANT REFERENCES ON  [dbo].[f_string_split_position] TO [public]
GO
GRANT EXECUTE ON  [dbo].[f_string_split_position] TO [public]
GO
