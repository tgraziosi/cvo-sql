SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amastbk_ammandprChildNext_sp] 
( 
	@rowsrequested smallint = 1,
  
	@co_asset_book_id smSurrogateKey, 
  
	@fiscal_period_end varchar(30)
) as 

SELECT @fiscal_period_end = RTRIM(@fiscal_period_end) IF @fiscal_period_end = "" SELECT @fiscal_period_end = NULL

create table #temp ( 
	timestamp varbinary(8) null,
	co_asset_book_id int null,
	fiscal_period_end datetime null,
	last_modified_date datetime null,
	modified_by int null,
	posting_flag tinyint null,
	depr_expense float null 
)
declare @rowsfound smallint 
select @rowsfound = 0 
declare @MSKfiscal_period_end smApplyDate 
select @MSKfiscal_period_end = @fiscal_period_end 
select @MSKfiscal_period_end = min(fiscal_period_end) from ammandpr where 
	co_asset_book_id = @co_asset_book_id and 
	fiscal_period_end > @MSKfiscal_period_end 
while @MSKfiscal_period_end is not null and @rowsfound < @rowsrequested 
begin 

	insert into #temp 
	select 
		timestamp,
		co_asset_book_id,
		fiscal_period_end, 
		last_modified_date, 
		modified_by,
		posting_flag,
		depr_expense 
	from ammandpr 
	where 
	co_asset_book_id = @co_asset_book_id and 
	fiscal_period_end = @MSKfiscal_period_end 

	select @rowsfound = @rowsfound + @@rowcount 
	 
	select @MSKfiscal_period_end = min(fiscal_period_end) from ammandpr where 
	co_asset_book_id = @co_asset_book_id and 
	fiscal_period_end > @MSKfiscal_period_end 
end 
select 
	timestamp,
	co_asset_book_id,
	fiscal_period_end = convert(char(8), fiscal_period_end,112), 
	last_modified_date = convert(char(8), last_modified_date,112), 
	modified_by,
	posting_flag,
	depr_expense 
from #temp order by fiscal_period_end 
drop table #temp 

return @@error 
GO
GRANT EXECUTE ON  [dbo].[amastbk_ammandprChildNext_sp] TO [public]
GO
