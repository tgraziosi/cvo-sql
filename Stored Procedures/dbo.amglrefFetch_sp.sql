SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amglrefFetch_sp]
(
	@rowsrequested smallint = 1,
	@reference_code 	varchar(32)
)
AS

CREATE TABLE #temp 
(
	timestamp 		varbinary(8) 	null,
	reference_code 	varchar(32) 	null,
	description 	varchar(40) 	null,
	reference_type 	varchar(8) 		null,
	status_flag 	smallint 		null
)

DECLARE @rowsfound 			smallint
DECLARE @MSKreference_code 	varchar(32 )

SELECT @rowsfound = 0
SELECT @MSKreference_code = @reference_code

IF EXISTS (SELECT 	reference_code 
			FROM 	glref 
			WHERE	reference_code 	= @MSKreference_code
			AND		status_flag		= 0)
BEGIN
	WHILE @MSKreference_code IS NOT NULL AND @rowsfound < @rowsrequested
	BEGIN

		INSERT INTO #temp 
		SELECT 
				timestamp,
				reference_code,
				description,
				reference_type,
				status_flag
		FROM 	glref 
		WHERE	reference_code = @MSKreference_code

		SELECT @rowsfound = @rowsfound + @@rowcount
		

		SELECT 	@MSKreference_code = MIN(reference_code) 
		FROM 	glref 
		WHERE	reference_code 		> @MSKreference_code
	END
END
SELECT
	timestamp,
	reference_code,
	description,
	reference_type,
	status_flag
FROM #temp 
ORDER BY reference_code

DROP TABLE #temp

RETURN @@error
GO
GRANT EXECUTE ON  [dbo].[amglrefFetch_sp] TO [public]
GO
