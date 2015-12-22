SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROCEDURE [dbo].[cc_periods_sp] 

AS

	IF ( ( SELECT MAX(period_end_date) FROM glprd ) >= ( SELECT DATEDIFF(dd, '1/1/1753', CONVERT(datetime, GETDATE())) + 639906))
		SELECT	period_start_date,
					period_end_date
		FROM		glprd
		WHERE		initialized_flag = 1
		AND		period_end_date >= (SELECT DATEDIFF(dd, '1/1/1753', CONVERT(datetime, GETDATE())) + 639906)
		ORDER BY period_end_date ASC
	ELSE
		SELECT	MAX(period_start_date),
					MAX(period_end_date)
		FROM		glprd
		WHERE		initialized_flag = 1
		


GO
GRANT EXECUTE ON  [dbo].[cc_periods_sp] TO [public]
GO
