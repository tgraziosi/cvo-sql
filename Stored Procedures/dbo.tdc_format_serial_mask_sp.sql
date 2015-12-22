SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[tdc_format_serial_mask_sp]
		@Part		VARCHAR(30),
		@SerialRaw	VARCHAR(40),
		@MaskedSerial	VARCHAR(40) OUTPUT,
		@ErrMsg		VARCHAR(255) OUTPUT, 
		@mask_code	VARCHAR(40) = '' 
AS 

DECLARE @Mask		VARCHAR(50)
DECLARE @I		INT
DECLARE @M		INT
DECLARE @digit		INT
DECLARE @strlen		INT
DECLARE @NoMatch	INT
DECLARE @SERIAL_NO_MATCH VARCHAR(255)
DECLARE @MaskChar 	VARCHAR(1)
DECLARE @MaskASC 	INT
DECLARE @RawChar 	VARCHAR(1)
DECLARE @RawASC 	INT
DECLARE @str		VARCHAR(40)

SELECT @SERIAL_NO_MATCH = 'Serial number does not match the mask code'

IF @mask_code = ''
	SELECT @Mask = mask_data 
	  FROM tdc_inv_master m (NOLOCK), tdc_serial_no_mask k (NOLOCK)
	 WHERE part_no = @Part
	   AND m.mask_code = k.mask_code 
ELSE
	SELECT @Mask = mask_data 
	  FROM tdc_serial_no_mask (NOLOCK)
	 WHERE mask_code = @mask_code

SELECT @NoMatch = 0
SELECT @MaskedSerial = ''
SELECT @I = 1, @M = 1, @digit = 1

DECLARE @required varchar(40)

-- SELECT @required = REPLACE (@Mask , '!' , '')
-- IF ((LEN(@SerialRaw)) < (LEN(@required)))
-- BEGIN
-- 	SELECT @ErrMsg = @SERIAL_NO_MATCH
-- 	RETURN -1
-- END

-- @I is index of mask data.
-- @M is index of serial number

WHILE (@I <= DATALENGTH( @Mask ) AND @NoMatch = 0)
BEGIN

	SELECT @MaskChar = SUBSTRING(@Mask, @I, 1) 
	SELECT @MaskASC  = ASCII(SUBSTRING(@Mask, @I, 1)) 
	SELECT @RawChar  = SUBSTRING(@SerialRaw, @M, 1) 
	SELECT @RawASC   = ASCII(SUBSTRING(@SerialRaw, @M, 1)) 

	IF @MaskChar = ''
		SELECT @MaskASC = 32

	ELSE IF @MaskChar = '&'
	BEGIN
 
		IF NOT ((@RawASC >= 65 And @RawASC <= 90) Or (@RawASC >= 97 And @RawASC <= 122) Or (@RawASC >= 48 AND @RawASC <= 57))
		BEGIN 
                	SELECT @NoMatch = 1
                END
 
		SELECT @MaskedSerial = @MaskedSerial + @RawChar
	END

	ELSE IF @MaskChar = '@'
	BEGIN

		IF NOT ((@RawASC >= 65 And @RawASC <= 90) Or (@RawASC >= 97 And @RawASC <= 122))
		BEGIN 
                	SELECT @NoMatch = 1
                END

		SELECT @MaskedSerial = @MaskedSerial + @RawChar
	END

	ELSE IF @MaskChar = '#'-- [0...9]
	BEGIN
		IF NOT ((@RawASC >= 48 And @RawASC <= 57))
		BEGIN 
                	SELECT @NoMatch = 1
                END

		SELECT @MaskedSerial = @MaskedSerial + @RawChar
	END

	ELSE IF @MaskChar = '?'	-- Optional, can be ignored only if it is at the end of the string, and
                          	-- there is no other special mask characters(@, #) after it
	BEGIN
		IF (@RawASC = 33 Or @RawASC = 35 Or @RawASC = 64 Or @RawASC = 126 Or @RawASC = 63)
		BEGIN 
                	SELECT @NoMatch = 1
                END
		SELECT @MaskedSerial = @MaskedSerial + @RawChar
	END

	ELSE IF @MaskChar = '!' -- Optional, can be ignored only if it is at the end of the string, and
                           	-- there is no other special mask characters(@, #) after it
	BEGIN
		IF (@RawASC = 33 Or @RawASC = 35 Or @RawASC = 64 Or @RawASC = 126 Or @RawASC = 63)
		BEGIN 
                	SELECT @NoMatch = 1
                END

		SELECT @MaskedSerial = @MaskedSerial + @RawChar
	END

	ELSE IF @MaskChar = '<'
	BEGIN
		SELECT @I = @I + 1
		SELECT @MaskChar = SUBSTRING(@Mask, @I, 1) 

		IF (@MaskChar = 'Y')
		BEGIN
			SELECT @str = SUBSTRING(@Mask, @I, 3)
			IF @str <> 'YY>'
			BEGIN
				SELECT @str = SUBSTRING(@Mask, @I, 5)

				IF @str <> 'YYYY>'
					SELECT @NoMatch = 1
				ELSE
				BEGIN
					SELECT @str = SUBSTRING(@SerialRaw, @M, 4)
					IF(ISNUMERIC(@str) = 0)
						SELECT @NoMatch = 1
					ELSE
					BEGIN
						SELECT @M = @M + 3
						SELECT @I = @I + 4
					END
				END
			END
			ELSE
			BEGIN
				SELECT @str = SUBSTRING(@SerialRaw, @M, 2)

				IF(ISNUMERIC(@str) = 0)
					SELECT @NoMatch = 1
				ELSE
				BEGIN
					SELECT @M = @M + 1
					SELECT @I = @I + 2
					SELECT @MaskedSerial = @MaskedSerial + @str
				END
			END
		END
		ELSE IF ((@MaskChar = 'M') OR (@MaskChar = 'D'))
		BEGIN
			IF SUBSTRING(@Mask, @I+1, 1) != '>'
				SELECT @NoMatch = 1

			SELECT @str = SUBSTRING(@SerialRaw, @M, 2)

			IF(ISNUMERIC(@str) = 0)
				SELECT @NoMatch = 1
			ELSE
			BEGIN
				SELECT @M = @M + 1
				SELECT @I = @I + 1
				SELECT @MaskedSerial = @MaskedSerial + @str
			END
		END
		ELSE IF (@MaskChar = 'J')
		BEGIN
			IF SUBSTRING(@Mask, @I+1, 1) != '>'
				SELECT @NoMatch = 1

			SELECT @str = SUBSTRING(@SerialRaw, @M, 7)

			IF(ISNUMERIC(@str) = 0)
				SELECT @NoMatch = 1
			ELSE
			BEGIN
				SELECT @M = @M + 6
				SELECT @I = @I + 1
				SELECT @MaskedSerial = @MaskedSerial + @str
			END
		END
		ELSE IF ((@MaskChar = 'L') OR (@MaskChar = 'P'))
		BEGIN
			SELECT @str = SUBSTRING(@Mask, @I+1, 1)

			IF SUBSTRING(@Mask, @I+2, 1) != '>'
			BEGIN
				SELECT @str = SUBSTRING(@Mask, @I+1, 2)
				SELECT @digit = 2
			END

			-- max lengh is 40. two digits.
			IF SUBSTRING(@Mask, @I + @digit + 1, 1) != '>'
				SELECT @NoMatch = 1			

			IF(ISNUMERIC(@str) = 1)			
			BEGIN		
				SELECT @strlen = @str	
				SELECT @str = SUBSTRING(@SerialRaw, @M, @strlen)

				IF(LEN(@str) < @strlen)
					SELECT @NoMatch = 1
				ELSE
				BEGIN
					SELECT @M = @M + @strlen - 1
					SELECT @I = @I + @digit + 1
					SELECT @MaskedSerial = @MaskedSerial + @str
				END
			END
			ELSE
				SELECT @NoMatch = 1
						
		END
	END
	
	ELSE IF @MaskChar != '~'
	BEGIN
		IF @MaskChar != @RawChar
			SELECT @NoMatch = 1
		ELSE
			SELECT @MaskedSerial = @MaskedSerial + @MaskChar
	END

	--Increment position
  	SELECT @I = @I + 1
	SELECT @M = @M + 1
END

IF SUBSTRING(@SerialRaw, @M, 1) > ''
	SELECT @NoMatch = 1

--If no match found
IF (@NoMatch = 1)
BEGIN
	SELECT @ErrMsg = @SERIAL_NO_MATCH
	RETURN -1
END

RETURN 1
GO
GRANT EXECUTE ON  [dbo].[tdc_format_serial_mask_sp] TO [public]
GO
