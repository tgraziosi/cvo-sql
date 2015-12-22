SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amusrhdrExists_sp] 
( 
	@company_id			smCompanyID,
	@user_field_id 		smUserFieldID,
	@user_field_subid	int, 
	@valid int output 
) as 


if exists (select 1 
	from amusrhdr 
	where user_field_id 	= @user_field_id
	AND	 user_field_subid	= @user_field_subid
	AND	 company_id		= @company_id
	)
 select @valid = 1 
else 
 select @valid = 0 
return @@error 
GO
GRANT EXECUTE ON  [dbo].[amusrhdrExists_sp] TO [public]
GO
