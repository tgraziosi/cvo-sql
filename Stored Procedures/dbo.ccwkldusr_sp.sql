SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROC	[dbo].[ccwkldusr_sp]	@all_workload_flag	smallint	= 1,
				@workload_code_from	varchar(8)	= '',
				@workload_code_end	varchar(8)	= ''

AS

SET QUOTED_IDENTIFIER OFF


	IF @all_workload_flag <> 1
		BEGIN
			CREATE TABLE #wklds ( workload_code varchar(8), workload_desc varchar(65) )
			
			INSERT #wklds
			SELECT workload_code, workload_desc from ccwrkhdr 
			WHERE workload_code BETWEEN @workload_code_from AND @workload_code_end
	
			SELECT u.workload_code, workload_desc, 'user_id' = s.user_id, user_name, company_name
	
			FROM #wklds h, ccwrkusr u, CVO_Control..smusers s, arco
			WHERE h.workload_code = u.workload_code
			AND u.user_id = s.user_id
		END
	ELSE
		SELECT u.workload_code, workload_desc, 'user_id' = s.user_id, user_name, company_name

		FROM ccwrkhdr h, ccwrkusr u, CVO_Control..smusers s, arco
		WHERE h.workload_code = u.workload_code
		AND u.user_id = s.user_id


GO
GRANT EXECUTE ON  [dbo].[ccwkldusr_sp] TO [public]
GO
