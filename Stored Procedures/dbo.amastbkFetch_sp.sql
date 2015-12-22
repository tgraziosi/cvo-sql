SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amastbkFetch_sp] 
( 
	@rowsrequested smallint = 1,
	@co_asset_book_id smSurrogateKey 
) as 


create table #temp ( 
	timestamp varbinary(8) null,
	co_asset_id int null,
	book_code char(8) null,
	co_asset_book_id int null,
	orig_salvage_value float null,
	orig_amount_expensed float null,
	orig_amount_capitalised float null,
	placed_in_service_date datetime null,
	last_posted_activity_date datetime null,
	next_entered_activity_date datetime null,
	last_posted_depr_date datetime null,
	prev_posted_depr_date datetime null,
	first_depr_date datetime null,
	last_modified_date datetime null,
	proceeds float null,
	gain_loss float null,
	last_depr_co_trx_id int null,
	process_id int null 
)
declare @rowsfound smallint 
select @rowsfound = 0 
declare @MSKco_asset_book_id smSurrogateKey 
select @MSKco_asset_book_id = @co_asset_book_id 
if exists (select * from amastbk where 
	co_asset_book_id = @MSKco_asset_book_id)
begin 
while @MSKco_asset_book_id is not null and @rowsfound < @rowsrequested 
begin 

	insert into #temp 
	select 
		timestamp,
		co_asset_id,
		book_code,
		co_asset_book_id,
		orig_salvage_value,
		orig_amount_expensed,
		orig_amount_capitalised,
		placed_in_service_date, 
		last_posted_activity_date, 
		next_entered_activity_date, 
		last_posted_depr_date, 
		prev_posted_depr_date, 
		first_depr_date, 
		last_modified_date, 
		proceeds,
		gain_loss,
		last_depr_co_trx_id,
		process_id 
	from amastbk 
	where 
	co_asset_book_id = @MSKco_asset_book_id 

	select @rowsfound = @rowsfound + @@rowcount 
	
	 
	select @MSKco_asset_book_id = min(co_asset_book_id) from amastbk where 
	co_asset_book_id > @MSKco_asset_book_id 
end 
end 
select 
	timestamp,
	co_asset_id,
	book_code,
	co_asset_book_id,
	orig_salvage_value,
	orig_amount_expensed,
	orig_amount_capitalised,
	placed_in_service_date = convert(char(8), placed_in_service_date,112), 
	last_posted_activity_date = convert(char(8), last_posted_activity_date,112), 
	next_entered_activity_date = convert(char(8), next_entered_activity_date,112), 
	last_posted_depr_date = convert(char(8), last_posted_depr_date,112), 
	prev_posted_depr_date = convert(char(8), prev_posted_depr_date,112), 
	first_depr_date = convert(char(8), first_depr_date,112), 
	last_modified_date = convert(char(8), last_modified_date,112), 
	proceeds,
	gain_loss,
	last_depr_co_trx_id,
	process_id 
from #temp order by co_asset_book_id 
drop table #temp 

return @@error 
GO
GRANT EXECUTE ON  [dbo].[amastbkFetch_sp] TO [public]
GO
