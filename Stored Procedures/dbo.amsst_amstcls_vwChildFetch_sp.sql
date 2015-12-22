SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amsst_amstcls_vwChildFetch_sp]
(
	@rowsrequested smallint = 1,
	@co_asset_id 	smSurrogateKey,
	@company_id 	smCompanyID,
	@classification_id 	smSurrogateKey
) as


create table #temp (
	timestamp varbinary(8) null,
	company_id smallint null,
	classification_id int null,
	co_asset_id int null,
	classification_code char(8) null,
	classification_description varchar(40) null,
	last_modified_date datetime null,
	modified_by int null
)
declare @rowsfound smallint
select @rowsfound = 0
declare @MSKclassification_id smSurrogateKey
select @MSKclassification_id = @classification_id
declare @MSKcompany_id smCompanyID
select @MSKcompany_id = @company_id
declare @MSKco_asset_id smSurrogateKey
select @MSKco_asset_id = @co_asset_id

if exists (select * from amastcls_vw where
	co_asset_id = @MSKco_asset_id and
	company_id = @MSKcompany_id and
	classification_id = @MSKclassification_id)
begin
while @MSKclassification_id is not null and @rowsfound < @rowsrequested
	begin

		insert into #temp 
		select 
			timestamp,
			company_id,
			classification_id,
			co_asset_id,
			classification_code,
			classification_description,
			last_modified_date,
			modified_by
		from 	amastcls_vw 
		where	co_asset_id = @MSKco_asset_id 
		and		company_id = @MSKcompany_id 
		and		classification_id = @MSKclassification_id

		select @rowsfound = @rowsfound + @@rowcount
		
		
		select @MSKclassification_id = min(classification_id) from amastcls_vw where
		co_asset_id = @MSKco_asset_id and
		company_id = @MSKcompany_id and
		classification_id > @MSKclassification_id
	end
end
select
	timestamp,
	company_id,
	classification_id,
	co_asset_id,
	classification_code,
	classification_description,
	last_modified_date = convert(char(8),last_modified_date,112),
	modified_by
from #temp order by co_asset_id, company_id, classification_id
drop table #temp

return @@error
GO
GRANT EXECUTE ON  [dbo].[amsst_amstcls_vwChildFetch_sp] TO [public]
GO
