SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amlocInsert_sp] 
( 
	@location_code 	smLocationCode, 
	@location_description 	smStdDescription 
) as 

declare @error int 

insert into amloc 
( 
	location_code,
	location_description 
)
values 
( 
	@location_code,
	@location_description 
)
return @@error 
GO
GRANT EXECUTE ON  [dbo].[amlocInsert_sp] TO [public]
GO
