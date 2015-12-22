SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amastprfFirst_sp] 
( 
	@rowsrequested smallint = 1 
) 
as 

create table #temp 
( 
	timestamp 			varbinary(8) null,
	co_asset_book_id 	int null,
	fiscal_period_end 	datetime null,
	current_cost 		float null,
	accum_depr 			float null,
	effective_date 	datetime null 
)
declare @rowsfound smallint 
declare @MSKfiscal_period_end smApplyDate 
declare @MSKco_asset_book_id smSurrogateKey 

select @rowsfound = 0 
select @MSKco_asset_book_id = min(co_asset_book_id) 
from amastprf 

if @MSKco_asset_book_id is null 
begin 
 drop table #temp 
 return 
end 

select 	@MSKfiscal_period_end = min(fiscal_period_end) 
from 	amastprf 
where co_asset_book_id = @MSKco_asset_book_id 

if @MSKfiscal_period_end is null 
begin 
 drop table #temp 
 return 
end 

insert 	into #temp 
select 
		timestamp,
		co_asset_book_id,
		fiscal_period_end, 
		current_cost,
		accum_depr,
		effective_date
from 	amastprf 
where 	co_asset_book_id = @MSKco_asset_book_id 
and 	fiscal_period_end = @MSKfiscal_period_end 

select @rowsfound = @@rowcount 

select @MSKfiscal_period_end = min(fiscal_period_end) 
from amastprf 
where 
	co_asset_book_id = @MSKco_asset_book_id and 
	fiscal_period_end > @MSKfiscal_period_end 

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
	from 	amastprf 
	where 	co_asset_book_id = @MSKco_asset_book_id 
	and 	fiscal_period_end = @MSKfiscal_period_end 

	select @rowsfound = @rowsfound + @@rowcount 
	
	 
	select @MSKfiscal_period_end = min(fiscal_period_end) 
	from amastprf 
	where 
	co_asset_book_id = @MSKco_asset_book_id and 
	fiscal_period_end > @MSKfiscal_period_end 
end 

select @MSKco_asset_book_id = min(co_asset_book_id) 
from amastprf 
where 	co_asset_book_id > @MSKco_asset_book_id 

while @MSKco_asset_book_id is not null and @rowsfound < @rowsrequested 
begin 
	select @MSKfiscal_period_end = min(fiscal_period_end) 
	from amastprf 
	where 
	co_asset_book_id = @MSKco_asset_book_id 

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
		co_asset_book_id = @MSKco_asset_book_id and 
		fiscal_period_end = @MSKfiscal_period_end 

		select @rowsfound = @rowsfound + @@rowcount 

		 

		select @MSKfiscal_period_end = min(fiscal_period_end) 
		from amastprf 
		where 
		co_asset_book_id = @MSKco_asset_book_id and 
		fiscal_period_end > @MSKfiscal_period_end 
	end 
	 
	select @MSKco_asset_book_id = min(co_asset_book_id) 
	from amastprf 
	where 
	co_asset_book_id > @MSKco_asset_book_id 
end 

select 
	timestamp,
	co_asset_book_id,
	fiscal_period_end = convert(char(8), fiscal_period_end,112), 
	current_cost,
	accum_depr,
	effective_date = convert(char(8), effective_date,112)
from #temp order by co_asset_book_id, fiscal_period_end 
drop table #temp 

return @@error 
GO
GRANT EXECUTE ON  [dbo].[amastprfFirst_sp] TO [public]
GO
