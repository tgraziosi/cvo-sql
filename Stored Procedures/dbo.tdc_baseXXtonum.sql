SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*                        					  */
/* SP for converting a baseXX number to base 10		          */
/*								  */
/* 04/24/1999	Initial		CAC				  */
/*								  */

CREATE PROCEDURE [dbo].[tdc_baseXXtonum](@seqalpha varchar(16), @retval decimal(20, 0) OUTPUT)
AS

	/* Declare local variables */
	DECLARE @err 		int
	DECLARE @bc_value	decimal(20, 4)
	DECLARE @power_XX	decimal(20, 4)
	DECLARE @counter	int
	DECLARE @j		int
	DECLARE @c		char
	DECLARE @baseXX 	decimal(20, 0)
	DECLARE @tstring	varchar(16)


	SELECT @err = 0
	SELECT @bc_value = 0.0
	SELECT @power_XX = 1
	SELECT @tstring = LTRIM(RTRIM(@seqalpha))

	/*
         * Fetch base arithmetic value for serialization from tdc_config configuration
	 * table.
	 */
	SELECT @baseXX = convert(decimal(20, 0), value_str)
	  FROM tdc_config
	 WHERE [function] = 'tdc_sn_base'


	/*
	 * Determine the length of the character S/N string.
	 */
	IF (@tstring <> '')
		SELECT @counter = DATALENGTH(@tstring)
	ELSE
		SELECT @counter = 0

	/* Main Loop */
	WHILE (@counter >= 1) BEGIN
		select @c = SUBSTRING(@tstring, @counter, 1)

		IF (@c <= '9')
			SELECT @j = ASCII(@c) - 48 
		ELSE
		  BEGIN
			SELECT @j = ASCII(@c) - 55
		  END

		SELECT @bc_value = (@bc_value + (@j * @power_XX))

		SELECT @power_XX = @power_XX * @baseXX

		SELECT @counter = @counter - 1
	END

	SELECT @retval = @bc_value

RETURN @err
GO
GRANT EXECUTE ON  [dbo].[tdc_baseXXtonum] TO [public]
GO
