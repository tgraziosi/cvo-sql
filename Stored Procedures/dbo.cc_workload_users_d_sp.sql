SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_workload_users_d_sp] 
	@workload_code varchar(8)
AS
	DELETE ccwrkusr WHERE workload_code = @workload_code
GO
GRANT EXECUTE ON  [dbo].[cc_workload_users_d_sp] TO [public]
GO
