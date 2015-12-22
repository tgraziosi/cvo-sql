SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amcatbkFirst_sp] 
( 
	@rowsrequested smallint = 1 
) as 


create table #temp ( 
	timestamp varbinary(8) null,
	category_code char(8) null,
	book_code char(8) null,
	effective_date datetime null,
	depr_rule_code char(8) null,
	depr_rule_description char(40) null,
	limit_rule_code char(8) null 
)
declare @rowsfound smallint 
select @rowsfound = 0 
declare @MSKeffective_date smApplyDate 
declare @MSKbook_code smBookCode 
declare @MSKcategory_code smCategoryCode 

select @MSKcategory_code = min(category_code) from amcatbk 
if @MSKcategory_code is null 
begin 
 drop table #temp 
 return 
end 

select @MSKbook_code = min(book_code) from amcatbk where 
 category_code = @MSKcategory_code 
if @MSKbook_code is null 
begin 
 drop table #temp 
 return 
end 

select @MSKeffective_date = min(effective_date) from amcatbk where 
 category_code = @MSKcategory_code 
 and book_code = @MSKbook_code 
if @MSKeffective_date is null 
begin 
 drop table #temp 
 return 
end 

insert into #temp 
	select 
		cb.timestamp,
		cb.category_code,
		cb.book_code,
		cb.effective_date,
		cb.depr_rule_code,
		dr.rule_description,
		cb.limit_rule_code
	from 	amcatbk cb, 
			amdprrul dr
	where	cb.category_code 	= @MSKcategory_code 
	AND 	cb.book_code 		= @MSKbook_code 
	AND		cb.effective_date 	= @MSKeffective_date 
 AND		cb.depr_rule_code 	= dr.depr_rule_code

select @rowsfound = @@rowcount 

select @MSKeffective_date = min(effective_date) from amcatbk where 
	category_code = @MSKcategory_code and 
	book_code = @MSKbook_code and 
	effective_date > @MSKeffective_date 
while @MSKeffective_date is not null and @rowsfound < @rowsrequested 
begin 

		insert into #temp 
			select 
				cb.timestamp,
				cb.category_code,
				cb.book_code,
				cb.effective_date,
				cb.depr_rule_code,
				dr.rule_description,
				cb.limit_rule_code
			from 	amcatbk cb, 
					amdprrul dr
			where	cb.category_code 	= @MSKcategory_code 
			AND 	cb.book_code 		= @MSKbook_code 
			AND		cb.effective_date 	= @MSKeffective_date 
		 AND		cb.depr_rule_code 	= dr.depr_rule_code

		select @rowsfound = @rowsfound + @@rowcount 
	 
	select @MSKeffective_date = min(effective_date) from amcatbk where 
	category_code = @MSKcategory_code and 
	book_code = @MSKbook_code and 
	effective_date > @MSKeffective_date 
end 
select @MSKbook_code = min(book_code) from amcatbk where 
	category_code = @MSKcategory_code and 
	book_code > @MSKbook_code 
while @MSKbook_code is not null and @rowsfound < @rowsrequested 
begin 
	select @MSKeffective_date = min(effective_date) from amcatbk where 
	category_code = @MSKcategory_code and 
	book_code = @MSKbook_code 
	while @MSKeffective_date is not null and @rowsfound < @rowsrequested 
	begin 

		insert into #temp 
			select 
				cb.timestamp,
				cb.category_code,
				cb.book_code,
				cb.effective_date,
				cb.depr_rule_code,
				dr.rule_description,
				cb.limit_rule_code
			from 	amcatbk cb, 
					amdprrul dr
			where	cb.category_code 	= @MSKcategory_code 
			AND 	cb.book_code 		= @MSKbook_code 
			AND		cb.effective_date 	= @MSKeffective_date 
		 AND		cb.depr_rule_code 	= dr.depr_rule_code

			select @rowsfound = @rowsfound + @@rowcount 

		 

		select @MSKeffective_date = min(effective_date) from amcatbk where 
		category_code = @MSKcategory_code and 
		book_code = @MSKbook_code and 
		effective_date > @MSKeffective_date 
	end 
	 
	select @MSKbook_code = min(book_code) from amcatbk where 
	category_code = @MSKcategory_code and 
	book_code > @MSKbook_code 
end 
select @MSKcategory_code = min(category_code) from amcatbk where 
	category_code > @MSKcategory_code 
while @MSKcategory_code is not null and @rowsfound < @rowsrequested 
begin 
	select @MSKbook_code = min(book_code) from amcatbk where 
	category_code = @MSKcategory_code 
	while @MSKbook_code is not null and @rowsfound < @rowsrequested 
	begin 
		select @MSKeffective_date = min(effective_date) from amcatbk where 
		category_code = @MSKcategory_code and 
		book_code = @MSKbook_code 
		while @MSKeffective_date is not null and @rowsfound < @rowsrequested 
		begin 

		insert into #temp 
			select 
				cb.timestamp,
				cb.category_code,
				cb.book_code,
				cb.effective_date,
				cb.depr_rule_code,
				dr.rule_description,
				cb.limit_rule_code
				from 	amcatbk cb, 
						amdprrul dr
				where	cb.category_code 	= @MSKcategory_code 
				AND 	cb.book_code 		= @MSKbook_code 
				AND		cb.effective_date 	= @MSKeffective_date 
			 AND		cb.depr_rule_code 	= dr.depr_rule_code

				select @rowsfound = @rowsfound + @@rowcount 

			 

			select @MSKeffective_date = min(effective_date) from amcatbk where 
			category_code = @MSKcategory_code and 
			book_code = @MSKbook_code and 
			effective_date > @MSKeffective_date 
		end 

		 

		select @MSKbook_code = min(book_code) from amcatbk where 
		category_code = @MSKcategory_code and 
		book_code > @MSKbook_code 
	end 
	 
	select @MSKcategory_code = min(category_code) from amcatbk where 
	category_code > @MSKcategory_code 
end 
select 
	timestamp,
	category_code,
	book_code,
	effective_date = convert(char(8), effective_date,112), 
	depr_rule_code,
	depr_rule_description,
	limit_rule_code 
from #temp order by category_code, book_code, effective_date 
drop table #temp 

return @@error 
GO
GRANT EXECUTE ON  [dbo].[amcatbkFirst_sp] TO [public]
GO
