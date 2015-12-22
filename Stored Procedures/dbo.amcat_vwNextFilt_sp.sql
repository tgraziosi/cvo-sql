SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amcat_vwNextFilt_sp] 
( 
	@rowsrequested smallint = 1,
	@category_code smCategoryCode, 
	@category_code_filter smCategoryCode 
) as 


create table #temp 
( 
	timestamp 					varbinary(8) null,
	category_code 				char(8) null,
	category_description 		varchar(40) null,
	posting_code 				char(8) null,
	posting_code_description 	varchar(40) null 
)

declare @rowsfound smallint 
declare @MSKcategory_code smCategoryCode 

select @rowsfound = 0 
select @MSKcategory_code = @category_code 
select	@MSKcategory_code 	= min(category_code) 
from 	amcat_vw 
where 	category_code 		> @MSKcategory_code 
and 	category_code 		like RTRIM(@category_code_filter)

while @MSKcategory_code is not null and @rowsfound < @rowsrequested 
begin 

	insert 	into #temp 
	select 	 
		timestamp,
		category_code,
		category_description,
		posting_code,
		posting_code_description 
	from 	amcat_vw 
	where 	category_code = @MSKcategory_code 

	select @rowsfound = @rowsfound + @@rowcount 

	 
	select 	@MSKcategory_code 	= min(category_code) 
	from 	amcat_vw 
	where 	category_code 		> @MSKcategory_code 
 	and 	category_code 		like RTRIM(@category_code_filter)
end 

select 
	timestamp,
	category_code,
	category_description,
	posting_code,
	posting_code_description 
from #temp 
order by category_code 

drop table #temp 

return @@error 
GO
GRANT EXECUTE ON  [dbo].[amcat_vwNextFilt_sp] TO [public]
GO
