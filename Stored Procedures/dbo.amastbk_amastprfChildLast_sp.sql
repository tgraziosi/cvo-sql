SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amastbk_amastprfChildLast_sp] 
( 
	@rowsrequested smallint = 1,
  
	@co_asset_book_id smSurrogateKey 
) as 

create table #temp ( 
	timestamp varbinary(8) null,
	co_asset_book_id int null,
	fiscal_period_end datetime null,
	current_cost float null,
	accum_depr float null,
	effective_date datetime null 
)
declare @rowsfound smallint 
select @rowsfound = 0 
declare @MSKfiscal_period_end smApplyDate 

select @MSKfiscal_period_end = max(fiscal_period_end) from amastprf where 
co_asset_book_id = @co_asset_book_id 
if @MSKfiscal_period_end is null 
begin 
 drop table #temp 
 return 
end 

insert into #temp 
select 
		timestamp,
		co_asset_book_id,
		fiscal_period_end, 
		current_cost,
		accum_depr,		 
		effective_date
from amastprf 
where 
	co_asset_book_id = @co_asset_book_id and 
	fiscal_period_end = @MSKfiscal_period_end 

select @rowsfound = @@rowcount 

select @MSKfiscal_period_end = max(fiscal_period_end) from amastprf where 
	co_asset_book_id = @co_asset_book_id and 
	fiscal_period_end < @MSKfiscal_period_end 
while @MSKfiscal_period_end is not null and @rowsfound < @rowsrequested 
begin 

	insert into #temp 
	select 
		timestamp,
		co_asset_book_id,
		fiscal_period_end, 
		current_cost,
		accum_depr,		 
		effective_date
	from amastprf 
	where 
	co_asset_book_id = @co_asset_book_id and 
	fiscal_period_end = @MSKfiscal_period_end 

	select @rowsfound = @rowsfound + @@rowcount 
	 
	select @MSKfiscal_period_end = max(fiscal_period_end) from amastprf where 
	co_asset_book_id = @co_asset_book_id and 
	fiscal_period_end < @MSKfiscal_period_end 
end 
select 
	timestamp,
	co_asset_book_id,
	fiscal_period_end = convert(char(8), fiscal_period_end,112), 
	current_cost,
	-accum_depr,		 
	effective_date = convert(char(8), effective_date,112)
from #temp order by fiscal_period_end 
drop table #temp 

return @@error 
GO
GRANT EXECUTE ON  [dbo].[amastbk_amastprfChildLast_sp] TO [public]
GO
