SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_parse_string_sp]
			@input 	varchar (255) ,
			@output	varchar (255) OUTPUT
AS 

DECLARE @index int


SET @index = 0
SELECT @index = CHARINDEX(CHAR(9), @input, 0)
WHILE (@index > 0)
BEGIN
	SELECT @input = STUFF (@input, CHARINDEX(CHAR(9),  @input, 0) , 1, ' ') -- Replace all the TABs with single spaces

	SET @index = 0
	SELECT @index = CHARINDEX(CHAR(9), @input, 0)
END

SET @index = 0
SELECT @index = CHARINDEX(CHAR(10), @input, 0)
WHILE (@index > 0)
BEGIN
	SELECT @input = STUFF (@input, CHARINDEX(CHAR(10), @input, 0) , 1, ' ' ) -- Replace all the Line Feeds with blanks

	SET @index = 0
	SELECT @index = CHARINDEX(CHAR(10), @input, 0)
END

SET @index = 0
SELECT @index = CHARINDEX(CHAR(13), @input, 0)
WHILE (@index > 0)
BEGIN
	SELECT @input = STUFF (@input, CHARINDEX(CHAR(13), @input, 0) , 2, ' ') -- Replace all the Carrage Returns with single spaces

	SET @index = 0
	SELECT @index = CHARINDEX(CHAR(13), @input, 0)
END


SET @input  = REPLACE (@input, '   ', ' ')
SET @output = REPLACE (@input, '  ', ' ')

RETURN
GO
GRANT EXECUTE ON  [dbo].[tdc_parse_string_sp] TO [public]
GO
