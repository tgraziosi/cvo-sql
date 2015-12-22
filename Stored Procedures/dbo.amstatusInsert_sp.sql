SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amstatusInsert_sp] 
( 
	@status_code 	smStatusCode, 
	@status_description 	smStdDescription, 
	@activity_state 	smUserState 
) as 

declare @error int 

insert into amstatus 
( 
	status_code,
	status_description,
	activity_state 
)
values 
( 
	@status_code,
	@status_description,
	@activity_state 
)
return @@error 
GO
GRANT EXECUTE ON  [dbo].[amstatusInsert_sp] TO [public]
GO
