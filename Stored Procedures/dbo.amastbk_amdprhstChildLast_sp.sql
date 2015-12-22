SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amastbk_amdprhstChildLast_sp] 
( 
	@rowsrequested smallint = 1,
  
	@co_asset_book_id smSurrogateKey 
) as 

create table #temp ( 
	timestamp varbinary(8) null,
	co_asset_book_id int null,
	effective_date datetime null,
	last_modified_date datetime null,
	modified_by int null,
	posting_flag tinyint null,
	depr_rule_code char(8) null,
	limit_rule_code char(8) null,
	salvage_value float null,
	catch_up_diff tinyint null,
	end_life_date datetime null,
	switch_to_sl_date datetime null 
)
declare @rowsfound smallint 
select @rowsfound = 0 
declare @MSKeffective_date smApplyDate 

select @MSKeffective_date = max(effective_date) from amdprhst where 
co_asset_book_id = @co_asset_book_id 
if @MSKeffective_date is null 
begin 
 drop table #temp 
 return 
end 

insert into #temp 
select 
		timestamp,
		co_asset_book_id,
		effective_date, 
		last_modified_date, 
		modified_by,
		posting_flag,
		depr_rule_code,
		limit_rule_code,
		salvage_value,
		catch_up_diff,
		end_life_date, 
		switch_to_sl_date
from amdprhst 
where 
	co_asset_book_id = @co_asset_book_id and 
	effective_date = @MSKeffective_date 

select @rowsfound = @@rowcount 

select @MSKeffective_date = max(effective_date) from amdprhst where 
	co_asset_book_id = @co_asset_book_id and 
	effective_date < @MSKeffective_date 
while @MSKeffective_date is not null and @rowsfound < @rowsrequested 
begin 

	insert into #temp 
	select 
		timestamp,
		co_asset_book_id,
		effective_date, 
		last_modified_date, 
		modified_by,
		posting_flag,
		depr_rule_code,
		limit_rule_code,
		salvage_value,
		catch_up_diff,
		end_life_date, 
		switch_to_sl_date
	from amdprhst 
	where 
	co_asset_book_id = @co_asset_book_id and 
	effective_date = @MSKeffective_date 

	select @rowsfound = @rowsfound + @@rowcount 
	 
	select @MSKeffective_date = max(effective_date) from amdprhst where 
	co_asset_book_id = @co_asset_book_id and 
	effective_date < @MSKeffective_date 
end 
select 
	timestamp,
	co_asset_book_id,
	effective_date = convert(char(8), effective_date,112), 
	last_modified_date = convert(char(8), last_modified_date,112), 
	modified_by,
	posting_flag,
	depr_rule_code,
	limit_rule_code,
	salvage_value,
	catch_up_diff,
	end_life_date = convert(char(8), end_life_date,112), 
	switch_to_sl_date = convert(char(8), switch_to_sl_date,112)
from #temp order by effective_date 
drop table #temp 

return @@error 
GO
GRANT EXECUTE ON  [dbo].[amastbk_amdprhstChildLast_sp] TO [public]
GO
