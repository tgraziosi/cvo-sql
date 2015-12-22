SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
-- v1.0 CT 12/02/2014 - Issue #1426 - Returns the date range based on the frquency type

DECLARE @start_date DATETIME , @end_date DATETIME, @date DATETIME
SET @date = GETDATE()
EXEC cvo_get_promo_frequency_dates_sp	@date,
							'W',
							@start_date  OUTPUT,
							@end_date  OUTPUT

SELECT @start_date, @end_date
*/


CREATE PROC [dbo].[cvo_get_promo_frequency_dates_sp]	@date_in DATETIME,
													@type CHAR(1),
													@start_date DATETIME OUTPUT,
													@end_date DATETIME OUTPUT
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @date DATETIME, 
			@year INT

	SET @date = DATEADD(dd, 0, DATEDIFF(dd, 0, @date_in))

	IF @type = 'W'
	BEGIN
		SELECT
			@start_date = DATEADD(dd, -(DATEPART(dw, @date)-1), @date),
			@end_date = DATEADD(dd, 7-(DATEPART(dw, @date)), @date)

		-- Increment end date by 1 day for order selection calc
		SET @end_date = DATEADD(dd, 1, @end_date)		

		RETURN
	END

	IF @type = 'M'
	BEGIN
		SELECT
			@start_date = DATEADD(DAY, 1-DAY(@date), DATEDIFF(DAY, 0, @date)),
			@end_date = DATEADD(DAY, -(DAY(DATEADD(MONTH, 1, @date))), DATEADD(MONTH, 1, @date))

		-- Increment end date by 1 day for order selection calc
		SET @end_date = DATEADD(dd, 1, @end_date)

		RETURN
	END

	IF @type = 'A'
	BEGIN
		SET @year = DATEPART(year, @date)

		SET @start_date = CAST(CAST(@year AS VARCHAR(4)) + '-01-01 00:00:00' AS DATETIME)
		SET @end_date = CAST(CAST(@year AS VARCHAR(4)) + '-12-31 00:00:00' AS DATETIME)

		-- Increment end date by 1 day for order selection calc
		SET @end_date = DATEADD(dd, 1, @end_date)

		RETURN
	END
END
	
GO
GRANT EXECUTE ON  [dbo].[cvo_get_promo_frequency_dates_sp] TO [public]
GO
