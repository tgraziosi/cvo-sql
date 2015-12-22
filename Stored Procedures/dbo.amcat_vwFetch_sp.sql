SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amcat_vwFetch_sp] 
( 
	@rowsrequested smallint = 1,
	@category_code smCategoryCode 
) as 


create table #temp ( 
	timestamp varbinary(8) null,
	category_code char(8) null,
	category_description varchar(40) null,
	posting_code char(8) null,
	posting_code_description varchar(40) null 
)
declare @rowsfound smallint 
select @rowsfound = 0 
declare @MSKcategory_code smCategoryCode 
select @MSKcategory_code = @category_code 
if exists (select * from amcat_vw where 
	category_code = @MSKcategory_code)
begin 
while @MSKcategory_code is not null and @rowsfound < @rowsrequested 
begin 

		insert into #temp 
		select 
			timestamp,
			category_code,
			category_description,
			posting_code,
			posting_code_description 
		from amcat_vw 
		where	category_code = @MSKcategory_code 

		select @rowsfound = @rowsfound + @@rowcount 
	 
	select @MSKcategory_code = min(category_code) from amcat_vw where 
	category_code > @MSKcategory_code 
end 
end 
select 
	timestamp,
	category_code,
	category_description,
	posting_code,
	posting_code_description 
from #temp order by category_code 
drop table #temp 

return @@error 
GO
GRANT EXECUTE ON  [dbo].[amcat_vwFetch_sp] TO [public]
GO
