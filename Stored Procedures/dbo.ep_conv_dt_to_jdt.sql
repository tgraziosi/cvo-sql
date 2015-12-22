SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE	[dbo].[ep_conv_dt_to_jdt] @dtDateValue datetime, @lJulianValue int output AS
Begin
	
	DECLARE @status int, @year int, @month int, @day int,
		@time datetime

	--Parse out the @date_value to year, month, day

	SELECT	@year = datepart( yy,  @dtDateValue ),
		@month = datepart( mm,  @dtDateValue ),
		@day = datepart( dd,  @dtDateValue )

	EXEC @status = appjuldt_sp @year, @month, @day, @lJulianValue OUTPUT

  	select julian_date = @lJulianValue

END 


/**/                                              
GO
GRANT EXECUTE ON  [dbo].[ep_conv_dt_to_jdt] TO [public]
GO
