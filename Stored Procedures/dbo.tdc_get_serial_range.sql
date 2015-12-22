SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_get_serial_range]
	@part_no VARCHAR(30),
	@first_serial VARCHAR(40),
	@last_serial VARCHAR(40)
AS



DECLARE @errno INT,
	@language VARCHAR(10),
	@msg VARCHAR(255),
	@mask VARCHAR(100),
	@counter INT,
	@counter2 INT,
	@length INT,
	@tmpch1 CHAR(1),
	@tmpch2 CHAR(1),
	@tmpch3 CHAR(1),
	@baseval1 INT,
	@baseval2 INT,
	@multiplier INT,
	@current_serial VARCHAR(40),
	@currentval INT,
	@divisor INT

	SELECT @language = ISNULL(
		(SELECT Language FROM tdc_sec (nolock) 
		  WHERE userid = ( SELECT who FROM #temp_who)), 'us_english')

	SELECT @errno = 0

--Get the mask for this part.
SELECT @mask = mask_data FROM tdc_serial_no_mask
	WHERE mask_code = (SELECT mask_code 
			FROM tdc_inv_master 
			WHERE part_no = @part_no)

--make sure this mask is valid for range-entry
SELECT @counter =	PATINDEX('%~%',@mask) +
			PATINDEX('%!%',@mask) +
			PATINDEX('%?%',@mask) +
			PATINDEX('%<%>%',@mask) 

IF (@counter > 0)	--Mask contains invalid tags
BEGIN
	SELECT @errno = -1
	SELECT @msg = err_msg 
		FROM tdc_lookup_error 
		WHERE language = @language
		AND module = 'GEN' 
		AND trans = 'tdc_get_serial_range' 
		AND err_no = @errno
	RAISERROR (@msg, 16, 1)
	RETURN @errno
END

SELECT @baseval1 = 0, @baseval2 = 0, @multiplier = 1

--Make sure both serials match the mask, and get their base-values.
SELECT @length = LEN(@mask)
IF (LEN(@first_serial) <> @length) SELECT @errno = -2
IF (LEN(@last_serial) <> @length) SELECT @errno = -3
SELECT @counter = @length
WHILE (@counter > 0)
BEGIN
	IF (@errno <> 0) BREAK

	SELECT @tmpch1 = SUBSTRING(@mask, @counter, 1), 
		@tmpch2 = SUBSTRING(@first_serial, @counter, 1),
		@tmpch3 = SUBSTRING(@last_serial, @counter, 1)

	SELECT @counter = @counter - 1

	IF (@tmpch1 NOT IN ('@', '#', '&'))
	BEGIN
		IF (@tmpch1 <> @tmpch2) SELECT @errno = -2
		ELSE IF (@tmpch1 <> @tmpch3) SELECT @errno = -3
		CONTINUE
	END

--numeric ascii values are 48-57
--upper-cased alpha ascii values are 65-90 
--lower-cased alpha ascii values are 97-122
	IF (@tmpch1 = '#')
	BEGIN
		IF (ASCII(@tmpch2) < 48 OR ASCII(@tmpch2) > 57) SELECT @errno = -2
		ELSE IF (ASCII(@tmpch3) < 48 OR ASCII(@tmpch3) > 57) SELECT @errno = -3
		ELSE 
		BEGIN
			SELECT @baseval1 = @baseval1 + (CAST(@tmpch2 AS INT) * @multiplier),
				@baseval2 = @baseval2 + (CAST(@tmpch3 AS INT) * @multiplier)
	
			SELECT @multiplier = @multiplier * 10
		END
		CONTINUE
	END

	IF (@tmpch1 = '@')
	BEGIN
		IF (ASCII(UPPER(@tmpch2)) < 65 OR ASCII(UPPER(@tmpch2)) > 90) SELECT @errno = -2
		ELSE IF (ASCII(UPPER(@tmpch3)) < 65 OR ASCII(UPPER(@tmpch3)) > 90) SELECT @errno = -3
		ELSE 
		BEGIN
			SELECT @baseval1 = @baseval1 + ((ASCII(UPPER(@tmpch2))-65) * @multiplier),
				@baseval2 = @baseval2 + ((ASCII(UPPER(@tmpch3))-65) * @multiplier)
	
			SELECT @multiplier = @multiplier * 26
		END
		CONTINUE
	END

	IF (@tmpch1 = '&')
	BEGIN
		IF (ASCII(@tmpch2) < 48 OR (ASCII(@tmpch2) > 57 AND ASCII(UPPER(@tmpch2)) < 65) OR ASCII(UPPER(@tmpch2)) > 90) SELECT @errno = -2
		ELSE IF (ASCII(@tmpch3) < 48 OR (ASCII(@tmpch3) > 57 AND ASCII(UPPER(@tmpch3)) < 65) OR ASCII(UPPER(@tmpch3)) > 90) SELECT @errno = -3
		ELSE 
		BEGIN
			SELECT @baseval1 = @baseval1 + (CASE WHEN ASCII(@tmpch2) <= 57 
								THEN CAST(@tmpch2 AS INT) 
								ELSE ASCII(UPPER(@tmpch2))-55 
							END * @multiplier)
							
			SELECT @baseval2 = @baseval2 + (CASE WHEN ASCII(@tmpch3) <= 57 
								THEN CAST(@tmpch3 AS INT) 
								ELSE ASCII(UPPER(@tmpch3))-55
							END * @multiplier)

			SELECT @multiplier = @multiplier * 36
		END
		CONTINUE
	END
END

IF (@baseval1 > @baseval2)
BEGIN
	SELECT @counter = @baseval1
	SELECT @baseval1 = @baseval2
	SELECT @baseval2 = @counter
END

IF (@baseval2 - @baseval1 > 10000) SELECT @errno = -4
--TOO Many Serials in this range!

IF (@errno <> 0) 
BEGIN
	SELECT @msg = err_msg 
		FROM tdc_lookup_error 
		WHERE language = @language
		AND module = 'GEN' 
		AND trans = 'tdc_get_serial_range' 
		AND err_no = @errno
	RAISERROR (@msg, 16, 1)
	RETURN @errno
END


--this is where we actually generate the range of serials from the two basevals
SELECT @counter = @baseval1	--start with the first baseval
WHILE (@counter <= @baseval2)	--iterate through the entire range of basevals
BEGIN
	SELECT @currentval = @counter,  --so we can modify it without messing up the loop
		@current_serial = '', 	--start with an empty SN
		@counter2 = 1,		--start with the first character of the SN
		@divisor = @multiplier
	WHILE (@counter2 <= @length)	--iterate through all the chars of the SN
	BEGIN
		SELECT @tmpch1 = SUBSTRING(@mask, @counter2, 1)	--Get the first character of the Mask

		IF (@tmpch1 = '#')
		BEGIN
			SELECT @divisor = @divisor / 10
			SELECT @current_serial = @current_serial + CAST( @currentval / @divisor AS CHAR(1))
			SELECT @currentval = @currentval % @divisor
		END
		ELSE IF (@tmpch1 = '@')
		BEGIN
			SELECT @divisor = @divisor / 26
			SELECT @current_serial = @current_serial + CHAR( (@currentval / @divisor) + 65 )
			SELECT @currentval = @currentval % @divisor
		END
		ELSE IF (@tmpch1 = '&')
		BEGIN
			SELECT @divisor = @divisor / 36
			IF (@currentval / @divisor < 10)
				SELECT @current_serial = @current_serial + CAST( @currentval / @divisor AS CHAR(1))
			ELSE
				SELECT @current_serial = @current_serial + CHAR( (@currentval / @divisor) + 55 )
			SELECT @currentval = @currentval % @divisor
		END
		ELSE 		--If its not one of #, @ or &, its a constant
			SELECT @current_serial = @current_serial + @tmpch1 --Just concatenate the character

		SELECT @counter2 = @counter2 + 1	--increment the counter for the Loop
	END

	INSERT INTO #sn_temp (serial) VALUES (@current_serial)

	SELECT @counter = @counter + 1		--increment the counter for the Loop
END

GO
GRANT EXECUTE ON  [dbo].[tdc_get_serial_range] TO [public]
GO
