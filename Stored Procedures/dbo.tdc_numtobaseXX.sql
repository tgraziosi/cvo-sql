SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*                        					  */
/* SP for converting a base 10 number to a baseXX number, where   */
/* baseXX is defined in the tdc_config configuration table.	  */
/*								  */
/* 04/25/1999	Initial		CAC				  */
/*								  */

CREATE PROCEDURE [dbo].[tdc_numtobaseXX](@invalue decimal(20, 0), @stringXX varchar(16) OUTPUT)
WITH ENCRYPTION AS

	/* Declare local variables */
	DECLARE @err int
	DECLARE @baseXX_squared	decimal(28, 4)
	DECLARE @remainder	int
	DECLARE @dremainder	decimal(28, 4)
	DECLARE @format		varchar(36)
	DECLARE @counter	int
	DECLARE @buff		varchar(16)
	DECLARE @value 		decimal(28, 4)
	DECLARE @baseXX		decimal(28, 0)
	DECLARE @baseFactor	decimal(28, 4)
	DECLARE @tchar		char
	DECLARE	@nonzeroFlag	int

	SELECT @err = 0
	SELECT @counter = 1
	SELECT @nonzeroFlag = 0

	/*
         * Fetch base arithmetic value for serialization from tdc_config configuration
	 * table.
	 */
	SELECT @baseXX = convert(decimal(20, 0), value_str)
	  FROM tdc_config
	 WHERE [function] = 'tdc_sn_base'

	SELECT @format = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'
	SELECT @baseFactor = POWER(@baseXX, 15)

	SELECT @value = convert(decimal(20, 4), @invalue)
	WHILE (@counter <= 16) BEGIN
		SELECT @dremainder = @value / @baseFactor
		SELECT @remainder = FLOOR(@dremainder)
		SELECT @tchar = SUBSTRING(@format, @remainder+1, 1)
		
		/* Don't display preceding zero's */
		IF (@tchar <> '0')
		  BEGIN
			SELECT @nonzeroFlag = 1
			IF (@counter = 1)
				SELECT @buff = @tchar
			ELSE
				SELECT @buff = @buff + @tchar
		  END
		ELSE
		  BEGIN
			IF (@nonzeroFlag = 1)
			  BEGIN
				IF (@counter = 1)
					SELECT @buff = @tchar
				ELSE
					SELECT @buff = @buff + @tchar
			  END
		  END
		
		SELECT @value = @value - (@remainder * @baseFactor)
		SELECT @baseFactor = @baseFactor / @baseXX
		SELECT @counter = @counter + 1
	END

	SELECT @stringXX = @buff

RETURN @err
GO
GRANT EXECUTE ON  [dbo].[tdc_numtobaseXX] TO [public]
GO
