SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_workload_params_sp] 

AS

	SET NOCOUNT ON

	CREATE TABLE #wrkparams
	(
		min_workload_code	varchar(8) NULL,
		max_workload_code	varchar(8) NULL		
	)
	
	INSERT #wrkparams (min_workload_code)
		SELECT 	MIN(workload_code)
		FROM	ccwrkhdr 
		WHERE	workload_code <> ''
		AND	workload_code IS NOT NULL


	UPDATE 	#wrkparams
	SET 	max_workload_code = (SELECT MAX(workload_code)
				 FROM	ccwrkhdr 
				 WHERE	workload_code <> ''
				 AND	workload_code IS NOT NULL
				)


	SELECT	min_workload_code,
		max_workload_code		
	FROM	#wrkparams

	SET NOCOUNT OFF
GO
GRANT EXECUTE ON  [dbo].[cc_workload_params_sp] TO [public]
GO
