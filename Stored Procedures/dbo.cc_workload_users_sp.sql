SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROCEDURE [dbo].[cc_workload_users_sp] 
	@workload_code varchar(8)
AS
SET QUOTED_IDENTIFIER OFF



	SELECT u.user_id, user_name, 0 FROM CVO_Control..smusers u, ccwrkusr w
		WHERE w.workload_code = @workload_code

		and u.user_id = w.user_id
		
	UNION
	SELECT user_id, user_name, 1 FROM CVO_Control..smusers u
		WHERE user_id not in (SELECT user_id FROM ccwrkusr
					WHERE workload_code = @workload_code)
		AND deleted = 0
		ORDER BY user_name












GO
GRANT EXECUTE ON  [dbo].[cc_workload_users_sp] TO [public]
GO
