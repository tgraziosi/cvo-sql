SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[tdc_calc_text_date_time] (@dt datetime) AS
/*******************************************************************************
 *
 * 980627 REA
 *
 * This proc converts a datetime datatype to 6-character date and time
 * textual representations: YYMMDD and HHMMSS
 *
 */

DECLARE @return_code int,
	@tDate	char(6),
	@tTime	char(6),
	@c8	char(8)

SELECT	@tDate	= convert(char(6),@dt,12),
	@c8	= convert(char(8),@dt, 8),
	@return_code = 0

IF (@tDate = NULL)
	SELECT @tDate = '      '

IF (@c8 = NULL)
	SELECT	@tTime = '      '
ELSE
	SELECT	@tTime = SUBSTRING(@c8,1,2)+SUBSTRING(@c8,4,2)+SUBSTRING(@c8,7,2)

TRUNCATE TABLE #text_date_time
INSERT INTO #text_date_time (date_text, time_text)
	VALUES (@tDate, @tTime)

RETURN @return_code
GO
GRANT EXECUTE ON  [dbo].[tdc_calc_text_date_time] TO [public]
GO
