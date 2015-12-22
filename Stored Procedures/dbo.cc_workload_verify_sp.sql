SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROCEDURE [dbo].[cc_workload_verify_sp]	@workload_code varchar(8),
																				@user_id int
AS

	IF ( SELECT count(*) from ccwrkhdr h, ccwrkusr u
		WHERE h.workload_code = @workload_code
		AND h.workload_code = u.workload_code
		AND user_id = @user_id ) > 0
		
		EXEC cc_select_cust_list @workload_code

	SELECT count(*) from ccwrkhdr h, ccwrkusr u
		WHERE h.workload_code = @workload_code
		AND h.workload_code = u.workload_code
		AND user_id = @user_id

GO
GRANT EXECUTE ON  [dbo].[cc_workload_verify_sp] TO [public]
GO
