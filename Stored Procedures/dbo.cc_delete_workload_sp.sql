SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_delete_workload_sp]
	@workload_code varchar(8)
AS

DELETE FROM ccwrkhdr WHERE workload_code = @workload_code
DELETE FROM ccwrkdet WHERE workload_code = @workload_code
DELETE FROM ccwrkusr WHERE workload_code = @workload_code
DELETE FROM ccwrkmem WHERE workload_code = @workload_code

 
GO
GRANT EXECUTE ON  [dbo].[cc_delete_workload_sp] TO [public]
GO
