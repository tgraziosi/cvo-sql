SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_workload_zoom_sp]
	@workload_code varchar(8) = '',
	@direction tinyint = 0

AS
SET rowcount 50

BEGIN
	IF @direction = 0
		SELECT workload_code 'Workload Code',workload_desc 'Workload Description'
		FROM ccwrkhdr
		WHERE workload_code >= @workload_code

		AND	workload_code IN ( SELECT workload_code FROM ccwrkdet )
		ORDER BY workload_code
	IF @direction = 1
		SELECT workload_code 'Workload Code',workload_desc 'Workload Description'
		FROM ccwrkhdr
		WHERE workload_code <= @workload_code

		AND	workload_code IN ( SELECT workload_code FROM ccwrkdet )
		ORDER BY workload_code DESC
	IF @direction = 2
		SELECT workload_code 'Workload Code',workload_desc 'Workload Description'
		FROM ccwrkhdr
		WHERE workload_code >= @workload_code

		AND	workload_code IN ( SELECT workload_code FROM ccwrkdet )
		ORDER BY workload_code ASC
END


SET rowcount 0

GO
GRANT EXECUTE ON  [dbo].[cc_workload_zoom_sp] TO [public]
GO
