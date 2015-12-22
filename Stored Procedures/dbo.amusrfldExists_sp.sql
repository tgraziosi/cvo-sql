SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amusrfldExists_sp] 
( 
	@user_field_id 		smSurrogateKey, 
	@valid int output 
) as 


if exists (select 1 from amusrfld where 
user_field_id = @user_field_id)
 select @valid = 1 
else 
 select @valid = 0 
return @@error 
GO
GRANT EXECUTE ON  [dbo].[amusrfldExists_sp] TO [public]
GO
