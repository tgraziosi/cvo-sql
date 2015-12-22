SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[tdc_encrypt]
@stringIn VARCHAR(255),
@strReturn VARCHAR(1000) OUTPUT
WITH ENCRYPTION AS 

DECLARE @string VARCHAR(255)
DECLARE @I	INT
DECLARE @Char	CHAR(1)
DECLARE @Asc	INT
DECLARE @Buffer VARCHAR(500)
DECLARE @segment VARCHAR(255)
DECLARE @strlen VARCHAR(255)

--*****************************************************************************************
--Encrypt the string
--*****************************************************************************************
SELECT @string = @StringIn

--Get the length of the string
SELECT @strlen = CAST((LEN(@string+'z')-1) AS VARCHAR(255))
IF (LEN(@strlen+'z') = 2) SELECT @strlen = '00' + @strlen
IF (LEN(@strlen+'z') = 3) SELECT @strlen = '0' + @strlen

--Make sure the length of the string is divisible by 3
IF ((LEN(@string)%3) <> 0 ) SELECT @string = @string + ' '
IF ((LEN(@string)%3) <> 0 ) SELECT @string = @string + ' ' 

--SELECT @string = REVERSE(@strlen + @string)
SELECT @string =  @strlen + @string 
 
--Convert characters to ASCII, and append a '0'
SELECT @buffer = ''
SELECT @I = 0
WHILE @I < (LEN(@string+'z')-1)
BEGIN
	SELECT @char = SUBSTRING(@string, @I+1, 1)
 
	SELECT @segment = CAST(ASCII(@char) AS VARCHAR(5))
	IF LEN(@segment+'z') = 3 SELECT @segment = '0' + @segment
	IF LEN(@segment+'z') = 2 SELECT @SEGMENT = '00' + @segment
	SELECT @buffer = @buffer + @segment + '0' 
	SELECT @I = @I + 1
 
END
SELECT @string = LTRIM(@buffer)

--Reverse characters in groups of 2
SELECT @buffer = ''
SELECT @I = 0
WHILE @I < LEN(@string)-1
BEGIN

	SELECT @segment = SUBSTRING(@string, @I+1, 2)
	SELECT @segment = REVERSE(@segment)
	SELECT @buffer = @buffer + @segment
	SELECT @I = @I + 2
END
SELECT @string = LTRIM(@buffer)

 

SELECT @strReturn = @string

GO
GRANT EXECUTE ON  [dbo].[tdc_encrypt] TO [public]
GO
