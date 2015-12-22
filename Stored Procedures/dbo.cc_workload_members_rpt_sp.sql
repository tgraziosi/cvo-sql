SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROC	[dbo].[cc_workload_members_rpt_sp]	@all_workload_flag	smallint	= 1,
																				@workload_code_from	varchar(8)	= '',
																				@workload_code_end	varchar(8)	= '',
																				@user_name	varchar(30) = '',
																				@company_db	varchar(30) = ''
 	

AS
	SET NOCOUNT ON
	IF EXISTS (SELECT name FROM sysobjects WHERE name = 'sm_login_sp' ) EXEC sm_login_sp @user_name, @company_db
	
	IF @all_workload_flag <> 1
		BEGIN
			CREATE TABLE #wklds ( workload_code varchar(8), workload_desc varchar(65) )
			
			INSERT #wklds
			SELECT workload_code, workload_desc from ccwrkhdr 
			WHERE workload_code BETWEEN @workload_code_from AND @workload_code_end
	
			SELECT 	h.workload_code, 
						workload_desc, 
						m.customer_code, 
						customer_name, 
						company_name,
						'all_flag' = @all_workload_flag,
						'from_code' = @workload_code_from,
						'thru_code' = @workload_code_end
			FROM #wklds h, ccwrkmem m, arcust c, arco
			WHERE h.workload_code = m.workload_code
			AND m.customer_code = c.customer_code
		END
	ELSE
		SELECT 	h.workload_code, 
					workload_desc, 
					m.customer_code, 
					customer_name, 
					company_name,
					'all_flag' = @all_workload_flag,
					'from_code' = @workload_code_from,
					'thru_code' = @workload_code_end
		FROM ccwrkhdr h, ccwrkmem m, arcust c, arco
		WHERE h.workload_code = m.workload_code
		AND m.customer_code = c.customer_code

	IF EXISTS (SELECT name FROM sysobjects WHERE name = 'sm_logoff_sp' ) EXEC sm_logoff_sp 
GO
GRANT EXECUTE ON  [dbo].[cc_workload_members_rpt_sp] TO [public]
GO
