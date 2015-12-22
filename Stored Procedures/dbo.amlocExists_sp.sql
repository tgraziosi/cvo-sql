SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amlocExists_sp] 
( 
	@location_code 	smLocationCode, 
	@valid int output 
) as 


if exists (select 1 from amloc where 
	location_code 	= @location_code 
)
 select @valid = 1 
else 
 select @valid = 0 
return @@error 
GO
GRANT EXECUTE ON  [dbo].[amlocExists_sp] TO [public]
GO
