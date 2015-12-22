SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROCEDURE [dbo].[cc_get_workloads_sp] 
	@user_id int
AS

	SELECT h.workload_code, workload_desc 
	FROM ccwrkhdr h, ccwrkusr u
	WHERE user_id = @user_id
	AND h.workload_code = u.workload_code
GO
GRANT EXECUTE ON  [dbo].[cc_get_workloads_sp] TO [public]
GO
