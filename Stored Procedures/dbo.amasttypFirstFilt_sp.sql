SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amasttypFirstFilt_sp]
(
	@rowsrequested smallint = 1,
	@asset_type_code_filter 	smAssetTypeCode
) as


create table #temp 
(
	timestamp 				varbinary(8) null,
	asset_type_code 		char(8) null,
	asset_type_description 	varchar(40) null,
	asset_gl_override 		varchar(32) null,
	accum_depr_gl_override 	varchar(32) null,
	depr_exp_gl_override 	varchar(32) null,
	last_modified_date 		datetime null,
	modified_by 			int null
)
declare @rowsfound smallint
declare @MSKasset_type_code smAssetTypeCode

select @rowsfound = 0

select 	@MSKasset_type_code 	= min(asset_type_code) 
from 	amasttyp 
where 	asset_type_code 		like RTRIM(@asset_type_code_filter)

if @MSKasset_type_code is null
begin
 drop table #temp
 return
end

insert 	into #temp 
select 	 
	timestamp,
	asset_type_code,
	asset_type_description,
	asset_gl_override,
	accum_depr_gl_override,
	depr_exp_gl_override,
	last_modified_date,
	modified_by
from 	amasttyp 
where	asset_type_code = @MSKasset_type_code

select @rowsfound = @@rowcount

select 	@MSKasset_type_code 	= min(asset_type_code) 
from 	amasttyp 
where	asset_type_code 		> @MSKasset_type_code
and 	asset_type_code 		like RTRIM(@asset_type_code_filter)

while @MSKasset_type_code is not null and @rowsfound < @rowsrequested
begin

	insert 	into #temp 
	select 	
		timestamp,
		asset_type_code,
		asset_type_description,
		asset_gl_override,
		accum_depr_gl_override,
		depr_exp_gl_override,
		last_modified_date,
		modified_by
	from 	amasttyp 
	where	asset_type_code = @MSKasset_type_code

	select @rowsfound = @rowsfound + @@rowcount

	
	select 	@MSKasset_type_code 	= min(asset_type_code) 
	from 	amasttyp 
	where	asset_type_code 		> @MSKasset_type_code
 	and 	asset_type_code 		like RTRIM(@asset_type_code_filter)
end

select
	timestamp,
	asset_type_code,
	asset_type_description,
	asset_gl_override,
	accum_depr_gl_override,
	depr_exp_gl_override,
	last_modified_date = convert(char(8),last_modified_date,112),
	modified_by
from #temp 
order by asset_type_code
drop table #temp

return @@error
GO
GRANT EXECUTE ON  [dbo].[amasttypFirstFilt_sp] TO [public]
GO
