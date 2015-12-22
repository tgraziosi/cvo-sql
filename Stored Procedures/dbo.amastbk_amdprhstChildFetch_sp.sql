SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amastbk_amdprhstChildFetch_sp]
(
	@rowsrequested smallint = 1,
	@co_asset_book_id				smSurrogateKey,
	@effective_date					varchar(30)
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
declare @MSKco_asset_book_id smSurrogateKey
select @MSKco_asset_book_id = @co_asset_book_id
declare @MSKeffective_date	 smApplyDate
select @MSKeffective_date = @effective_date

if exists (select * from amdprhst where
	 co_asset_book_id = @MSKco_asset_book_id and
	 effective_date= @MSKeffective_date)
begin
	while @MSKeffective_date is not null and @rowsfound < @rowsrequested
	begin

		insert into #temp select 
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
		from amdprhst where
		co_asset_book_id = @MSKco_asset_book_id and
		effective_date = @MSKeffective_date

		select @rowsfound = @rowsfound + @@rowcount

		
		select @MSKeffective_date = min(effective_date) from amdprhst where
		co_asset_book_id= @MSKco_asset_book_id and
		 effective_date> @MSKeffective_date
	end
end
select
	timestamp,
	co_asset_book_id,
	effective_date = convert(char(8),effective_date,112),
	last_modified_date = convert(char(8),last_modified_date,112),
	modified_by,
	posting_flag,
	depr_rule_code,
	limit_rule_code,
	salvage_value,
	catch_up_diff,
	end_life_date = convert(char(8),end_life_date,112),
	switch_to_sl_date = convert(char(8),switch_to_sl_date,112)
from #temp order by	co_asset_book_id, effective_date
drop table #temp

return @@error
GO
GRANT EXECUTE ON  [dbo].[amastbk_amdprhstChildFetch_sp] TO [public]
GO
