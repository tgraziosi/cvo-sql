SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_generate_epicor_sn]
	@partno varchar(30),
	@qty integer = 1,
	@location varchar(10) = ''
AS

SET NOCOUNT ON
	DECLARE		@mask varchar (100),
			@err as int,
			@msg as varchar(255),
			@language varchar(10),
			@fieldlen int,
			@startfield int,
			@stopfield int,
			@charbuf varchar(50),
			@serial_count integer,
			@count1 INTEGER,
			@count2 INTEGER,
			@count3 INTEGER,
			@divisor1 INTEGER,
			@divisor2 INTEGER,
			@serial VARCHAR(50)

	SELECT @language = ISNULL((SELECT Language FROM tdc_sec (nolock) WHERE userid = (SELECT who FROM #temp_who)), 'us_english')

	SELECT @err = 0

	--Check for temp table
	IF OBJECT_ID('tempdb..#serial_no') IS NULL
	BEGIN
		--ERROR No Temp Table
		SELECT @err = -101
		SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_get_next_serial_sp' AND err_no = @err AND language = @language
		RAISERROR (@msg, 16, 1)
		RETURN @err
	END

	SELECT 	@mask = ISNULL(m.mask_data, ''),
		@serial_count = ISNULL(i.serial_count, 0)
		FROM tdc_inv_master i, tdc_serial_no_mask m
		WHERE 	i.part_no = @partno
		AND	i.mask_code = m.mask_code
	IF ((@mask = '') OR (@mask IS NULL))
	BEGIN
		--ERROR No Mask Defined
		SELECT @err = -102
		SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_get_next_serial_sp' AND err_no = @err AND language = @language
		RAISERROR (@msg, 16, 1)
		RETURN @err
	END

	--Date Fields
	SELECT @mask = REPLACE(@mask, '<YY>', RIGHT(YEAR(GETDATE()), 2)) 	--2-digit year
	SELECT @mask = REPLACE(@mask, '<YYYY>', YEAR(GETDATE()))		--4-digit year
	SELECT @mask = REPLACE(@mask, '<M>', RIGHT('0' + CAST(MONTH(GETDATE())AS VARCHAR(2)), 2)) --Month (this insures that   )
	SELECT @mask = REPLACE(@mask, '<D>', RIGHT('0' + CAST(DAY(GETDATE()) AS VARCHAR(2)), 2))  --Day	  (the value is 2 chars)
	SELECT @mask = REPLACE(@mask, '<J>', 729960 + DATEDIFF(dd, '07-25-99', GETDATE())) --Julian Date 
			--729960 is the julian date for -07-25-99.  We simply add the number of days since then.
	IF (LEN(@mask) > 40)
	BEGIN
		--ERROR Serial Number Too Long
		SELECT @err = -106
		SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_get_next_serial_sp' AND err_no = @err AND language = @language
		RAISERROR (@msg, 16, 1)
		RETURN @err
	END


	--Location Field
	SELECT @startfield = CHARINDEX('<L', @mask, 0) -- This finds the location of any <L flags
	WHILE @startfield <> 0
	BEGIN
		SELECT @stopfield = CHARINDEX('>', @mask, @startfield)  --This finds the matching >
		IF @stopfield = 0
		BEGIN
			--ERROR < without >
			SELECT @err = -103
			SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_get_next_serial_sp' AND err_no = @err AND language = @language
			RAISERROR (@msg, 16, 1)
			RETURN @err
		END
		SELECT @fieldlen = SUBSTRING(@mask, @startfield +2, (@stopfield - @startfield) - 2) 
		--@fieldlen now holds the number of chars of location that we wish to include
		SELECT @charbuf = RIGHT(REPLICATE('0', @fieldlen) + LEFT(@location, @fieldlen), @fieldlen)
		--Get the first @fieldlen number of chars from location, padding with zeroes if necessary
		SELECT @mask = REPLACE(	@mask, 
					SUBSTRING(	@mask, 
							@startfield, 
							@stopfield - @startfield + 1), 
					@charbuf)
		--Replace the <L#> flag with the location string
		SELECT @startfield = CHARINDEX('<L', @mask, @stopfield) 
		--find the next occurence of this flag.
	END

	--Part Number Field
	SELECT @startfield = CHARINDEX('<P', @mask, 0)
	WHILE @startfield <> 0
	BEGIN
		SELECT @stopfield = CHARINDEX('>', @mask, @startfield)  --This finds the matching >
		IF @stopfield = 0
		BEGIN
			--ERROR < without >
			SELECT @err = -103
			SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_get_next_serial_sp' AND err_no = @err AND language = @language
			RAISERROR (@msg, 16, 1)
			RETURN @err
		END
		SELECT @fieldlen = SUBSTRING(@mask, @startfield +2, (@stopfield - @startfield) - 2)
		--@fieldlen now holds the number of chars of partno that we wish to include
		SELECT @charbuf = RIGHT(REPLICATE('0', @fieldlen) + LEFT(@partno, @fieldlen), @fieldlen)
		--Get the first @fieldlen number of chars from partno, padding with zeroes if necessary
		SELECT @mask = REPLACE(	@mask, 
					SUBSTRING(	@mask, 
							@startfield, 
							@stopfield - @startfield + 1), 
					@charbuf )
		--Replace the <P#> flag with the partno string
		SELECT @startfield = CHARINDEX('<P', @mask, @stopfield)
		--find the next occurence of this flag.
	END


	SELECT @count1 = LEN(@mask)
	SELECT @divisor1 = 1
	-- This calculates @divisor1 which is the magnitude of the highest digit of the SN-mask
	WHILE (@count1 > 0)
	BEGIN
		SELECT @charbuf = SUBSTRING(@mask, @count1, 1)
		IF @charbuf = '#'
			SELECT @divisor1 = @divisor1 * 10
		ELSE IF @charbuf = '@'
			SELECT @divisor1 = @divisor1 * 26
		ELSE IF @charbuf = '&'
			SELECT @divisor1 = @divisor1 * 36
		ELSE IF ((@charbuf = '~') 
		     OR (@charbuf = '?') 
		     OR (@charbuf = '!'))
		     BEGIN
			--ERROR INVALID CHARS IN SERIAL MASK
			SELECT @err = -104
			SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_get_next_serial_sp' AND err_no = @err AND language = @language
			RAISERROR (@msg, 16, 1)
			RETURN @err
		     END
		SELECT @count1 = @count1 - 1
	END

	SELECT @count3 = 1

	IF (@serial_count + @qty) > @divisor1
	BEGIN
		--ERROR MAXIMUM SN EXCEEDED
		SELECT @err = -105
		SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_get_next_serial_sp' AND err_no = @err AND language = @language
		RAISERROR (@msg, 16, 1)
		RETURN @err
	END

	WHILE @count3 <= @qty
	BEGIN
		SELECT @divisor2 = @divisor1	--a copy of divisor which will be dissected during this pass
		SELECT @serial = @mask		--@serial is the sn we are generating
		SELECT @count1 = 1		--@count1 points to the current character we are operating on
		SELECT @count2 = @serial_count + @count3 --@count2 is the serial_count of the current sn
		WHILE (@count1 <= LEN(@serial))
		BEGIN
			SELECT @charbuf = SUBSTRING(@mask, @count1, 1)	--Get the current character
			IF @charbuf = '#'
			BEGIN
				SELECT @divisor2 = @divisor2 / 10		--This sets divisor to the magnitude of this digit
				SELECT @serial = STUFF(@serial, @count1, 1, 	--insert into @serial
					CAST(@count2 / @divisor2 AS VARCHAR(1))) --the integral value that goes in this digit
				SELECT @count2 = @count2 % @divisor2		--Set @count2 to be the remainder for the next pass.
			END
			ELSE IF @charbuf = '@'
			BEGIN
				SELECT @divisor2 = @divisor2 / 26		--This sets divisor to the magnitude of this digit
				SELECT @serial = STUFF(@serial, @count1, 1, 	--insert into @serial 
					CHAR((@count2 / @divisor2) + 65))	--We add 65 to get the proper ASCII value, then convert
				SELECT @count2 = @count2 % @divisor2		--Set @count2 to be the remainder for the next pass.
			END
			ELSE IF @charbuf = '&'
			BEGIN
				SELECT @divisor2 = @divisor2 / 36		--This sets divisor to the magnitude of this digit
				IF ((@count2 / @divisor2) < 10)				--This handles digits 0-9
					SELECT @serial = STUFF(@serial, @count1, 1, 		--insert into @serial 
						CAST(@count2 / @divisor2 AS VARCHAR(1))) --the integral value that goes in this digit
				ELSE							--this handles digits A-Z
					SELECT @serial = STUFF(@serial, @count1, 1, 		--insert into @serial 
						CHAR((@count2 / @divisor2) + 55))	--We add 55 to get the proper ASCII value, then convert
				SELECT @count2 = @count2 % @divisor2		--Set @count2 to be the remainder for the next pass.
			END
			SELECT @count1 = @count1 + 1		--Move to the next character in the serial
		END
		--If this would generate a SN that already exists, skip it, and generate one more.
		IF EXISTS(SELECT * FROM lot_bin_stock WHERE part_no = @partno AND lot_ser = @serial)
			SELECT @qty = @qty + 1
		--Otherwise insert it into the temp table
		ELSE INSERT INTO #serial_no (serial) VALUES (@serial)
		SELECT @count3 = @count3 + 1			--Move on to the next Serial
	END
	UPDATE tdc_inv_master SET serial_count = ISNULL(serial_count, 0) + @qty WHERE part_no = @partno
GO
GRANT EXECUTE ON  [dbo].[tdc_generate_epicor_sn] TO [public]
GO
