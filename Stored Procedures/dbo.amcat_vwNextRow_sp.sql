SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amcat_vwNextRow_sp] 
( 
	@category_code smCategoryCode 
) as 


declare @MSKcategory_code smCategoryCode 
select @MSKcategory_code = @category_code 
select @MSKcategory_code = min(category_code) from amcat_vw where 
	category_code > @MSKcategory_code 
select 
	timestamp,
	category_code,
	category_description,
	posting_code,
	posting_code_description 
from amcat_vw where 
		category_code = @MSKcategory_code 

return @@error 
GO
GRANT EXECUTE ON  [dbo].[amcat_vwNextRow_sp] TO [public]
GO
