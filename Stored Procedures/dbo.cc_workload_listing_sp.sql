SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROC	[dbo].[cc_workload_listing_sp]	@all_workload_flag	smallint	= 1,
				@workload_code_from	varchar(8)	= '',
				@workload_code_end	varchar(8)	= ''

AS

SET QUOTED_IDENTIFIER OFF

	IF @all_workload_flag <> 1
		BEGIN
			CREATE TABLE #wklds ( workload_code varchar(8) )
			
			INSERT #wklds
			SELECT workload_code from ccwrkhdr 
			WHERE workload_code BETWEEN @workload_code_from AND @workload_code_end
	
			SELECT 	h.workload_code, 
						workload_desc, 
						update_date, 
						workload_clause, 
						sequence_id, 
						company_name,
						'all_flag' = @all_workload_flag,
						'from_code' = @workload_code_from,
						'thru_code' = @workload_code_end
			FROM #wklds t, ccwrkhdr h, ccwrkdet d, arco
			WHERE h.workload_code = d.workload_code
			AND h.workload_code = t.workload_code
			END
	ELSE
		SELECT 	h.workload_code, 
					workload_desc, 
					update_date, 
					workload_clause, 
					sequence_id, 
					company_name,
					'all_flag' = @all_workload_flag,
					'from_code' = @workload_code_from,
					'thru_code' = @workload_code_end
		FROM ccwrkhdr h, ccwrkdet d, arco
		WHERE h.workload_code = d.workload_code
GO
GRANT EXECUTE ON  [dbo].[cc_workload_listing_sp] TO [public]
GO
