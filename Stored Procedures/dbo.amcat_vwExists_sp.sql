SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amcat_vwExists_sp] 
( 
	@category_code smCategoryCode, 
	@valid int output 
) as 


if exists (select 1 from amcat where 
	category_code = @category_code 
)
 select @valid = 1 
else 
 select @valid = 0 
return @@error 
GO
GRANT EXECUTE ON  [dbo].[amcat_vwExists_sp] TO [public]
GO
