SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_serial_count_sp]
	@partno varchar(30),
	@serial_no varchar(50)
AS
SET NOCOUNT ON

	DECLARE		@mask varchar (100),
			@err int,
			@sn_length int,
			@multiplier int,
			@maskpos int,
			@serialpos int,
			@maskchar char,
			@serialchar char,
			@serial_count int

	SELECT @err = 0
	SELECT @mask = 'NOCODE***'
	SELECT @mask = tsnm.mask_data FROM tdc_inv_master tim, tdc_serial_no_mask tsnm
		WHERE	tim.part_no = @partno
		AND	tim.mask_code = tsnm.mask_code

	IF (@mask = 'NOCODE***') RETURN -100 --No Mask Defined

	SELECT 	@serial_count = 0, 
		@multiplier = 1, 
		--@sn_length = LEN(@serial_no), 
		@serialpos = LEN(@serial_no),
		@maskpos = LEN(@mask)
		
	WHILE (@serialpos > 0)
	BEGIN
		IF (@maskpos <=0) RETURN -101 --Serial doesnt match the mask.
		SELECT @maskchar = SUBSTRING(UPPER(@mask), @maskpos, 1)	
		SELECT @serialchar = SUBSTRING(UPPER(@serial_no), @serialpos, 1)	
		IF (@maskchar = '#')
		BEGIN
			IF (ISNUMERIC(@serialchar) = 0)
				RETURN -101 --Serial doesnt match the mask.
			SELECT	@serial_count = @serial_count + (CAST(@serialchar AS INT) * @multiplier),
				@multiplier = 10 * @multiplier,
				@serialpos = @serialpos - 1,
				@maskpos = @maskpos - 1
		END
		ELSE IF (@maskchar = '@')
		BEGIN
			IF ((ASCII(@serialchar) < 65) OR (ASCII(@serialchar) >90))
				RETURN -101 --Serial doesnt match the mask.
			SELECT	@serial_count = @serial_count + ((ASCII(@serialchar) - 65) * @multiplier),
				@multiplier = 26 * @multiplier,
				@serialpos = @serialpos - 1,
				@maskpos = @maskpos - 1
		END
		ELSE IF (@maskchar = '&')
		BEGIN
			IF (ISNUMERIC(@serialchar) = 1)
				SELECT	@serial_count = @serial_count + (CAST(@serialchar AS INT) * @multiplier),
					@multiplier = 36 * @multiplier,
					@serialpos = @serialpos - 1,
					@maskpos = @maskpos - 1
			ELSE IF ((ASCII(@serialchar) >= 65) AND (ASCII(@serialchar) <= 90))
				SELECT	@serial_count = @serial_count + ((ASCII(@serialchar) - 55) * @multiplier),
					@multiplier = 36 * @multiplier,
					@serialpos = @serialpos - 1,
					@maskpos = @maskpos - 1
			ELSE RETURN -101 --Serial doesnt match the mask.
		END
		ELSE IF (@maskchar = @serialchar)
			SELECT	@serialpos = @serialpos - 1,
				@maskpos = @maskpos - 1
		ELSE IF (@maskchar = '>')
		BEGIN
			DECLARE	@taglen int, 
				@tag varchar(30),
				@controlchar char
			SELECT @taglen = CHARINDEX('<', REVERSE(LEFT(@mask, @maskpos)))
			SELECT @tag = SUBSTRING(@mask, @maskpos-@taglen+1, @taglen)
			IF ((@tag = '<D>') OR (@tag = '<M>'))
			BEGIN
				SELECT 	@serialpos = @serialpos - 2,
					@maskpos = @maskpos - @taglen
			END
			ELSE IF (@tag = '<YY>')
			BEGIN
				SELECT 	@serialpos = @serialpos - 2,
					@maskpos = @maskpos - @taglen
			END
			ELSE IF (@tag = '<YYYY>')
			BEGIN
				SELECT 	@serialpos = @serialpos - 4,
					@maskpos = @maskpos - @taglen
			END
			ELSE IF (@tag = '<J>')
			BEGIN
				SELECT 	@serialpos = @serialpos - 7,
					@maskpos = @maskpos - @taglen
			END
			ELSE IF ((LEFT(@tag, 2) = '<L') OR (LEFT(@tag, 2) = '<P'))
			BEGIN
				SELECT 	@serialpos = @serialpos - CAST(SUBSTRING(@tag, 3, @taglen-3) AS INT),
					@maskpos = @maskpos - @taglen
			END 
			ELSE RETURN -102 --MASK CODE CONTAINS INVALID TAGS
		END
		ELSE RETURN -101
	END
	RETURN @serial_count

GO
GRANT EXECUTE ON  [dbo].[tdc_serial_count_sp] TO [public]
GO
