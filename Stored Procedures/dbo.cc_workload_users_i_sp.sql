SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROCEDURE [dbo].[cc_workload_users_i_sp] 
	@workload_code varchar(8),
	@user_id	int
AS

	IF ( SELECT COUNT(*) FROM ccwrkusr WHERE [user_id] = @user_id AND workload_code = @workload_code) = 0
		INSERT ccwrkusr VALUES (@workload_code, @user_id)
GO
GRANT EXECUTE ON  [dbo].[cc_workload_users_i_sp] TO [public]
GO
