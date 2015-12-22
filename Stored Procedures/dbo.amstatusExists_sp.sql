SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amstatusExists_sp] 
( 
	@status_code 	smStatusCode, 
	@valid int output 
) as 


if exists (select 1 from amstatus where 
	status_code 	= @status_code 
)
 select @valid = 1 
else 
 select @valid = 0 
return @@error 
GO
GRANT EXECUTE ON  [dbo].[amstatusExists_sp] TO [public]
GO
