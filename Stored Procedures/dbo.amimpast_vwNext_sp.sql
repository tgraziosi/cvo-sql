SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amimpast_vwNext_sp] 
( 
	@rowsrequested smallint = 1,
	@company_id smCompanyID, 
	@asset_ctrl_num smControlNumber 
) as 


create table #temp 
( 
	timestamp 					varbinary(8) 	null,
	company_id 					smallint 		null,
	asset_ctrl_num 				char(16) 		null,
	activity_state 				tinyint 		null,
	co_asset_id 				int 			null,
	co_trx_id 					int 			null,
	posting_flag 				tinyint 		null,
	asset_description 			varchar(40) 	null,
	is_new 						tinyint 		null,
	original_cost 				float 			null,
	acquisition_date 			datetime 		null,
	placed_in_service_date 		datetime 		null,
	original_in_service_date 	datetime 		null,
	disposition_date 			datetime 		null,
	service_units 				int				null,
	orig_quantity 				int 			null,
	rem_quantity 				int 			null,
	category_code 				char(8) 		null,
	status_code 				char(8) 		null,
	asset_type_code 			varchar(8) 		null,
	employee_code 				varchar(9) 		null,
	location_code 				varchar(8) 		null,
	owner_code 					varchar(8) 		null,
	business_usage 				float 			null,
	personal_usage 				float 			null,
	investment_usage 			float 			null,
	account_reference_code 		varchar(32) 	null,
	tag 						char(32)		null,
	note_id 					int 			null,
	user_field_id 				int 			null,
	is_pledged 					tinyint 		null,
	lease_type 					tinyint 		null,
	is_property 				tinyint 		null,
	depr_overridden 			tinyint 		null,
	linked 						tinyint 		null,
	parent_id 					int 			null,
	num_children 				int 			null,
	last_modified_date 			datetime 		null,
	modified_by 				int 			null,
	policy_number 				varchar(40) 	null,
	depreciated 				tinyint 		null,
	is_imported 				tinyint 		null 
)

declare @rowsfound 			smallint, 
		@MSKasset_ctrl_num 	smControlNumber, 
		@MSKcompany_id 		smCompanyID 

select @MSKasset_ctrl_num = @asset_ctrl_num 
select @rowsfound = 0 
select @MSKcompany_id = @company_id 

select 	@MSKasset_ctrl_num = min(asset_ctrl_num) 
from 	amimpast_vw 
where 	company_id 		= @MSKcompany_id 
and 	asset_ctrl_num 	> @MSKasset_ctrl_num 

while @MSKasset_ctrl_num is not null and @rowsfound < @rowsrequested 
begin 

	insert 	into #temp 
	select 	 
		timestamp,
		company_id,
		asset_ctrl_num,
		activity_state,
		co_asset_id,
		co_trx_id,
		posting_flag,
		asset_description,
		is_new,
		original_cost,
		acquisition_date, 
		placed_in_service_date, 
		original_in_service_date, 
		disposition_date, 
		service_units,
		orig_quantity,
		rem_quantity,
		category_code,
		status_code,
		asset_type_code,
		employee_code,
		location_code,
		owner_code,
		business_usage,
		personal_usage,
		investment_usage,
		account_reference_code,
		tag,
		note_id,
		user_field_id,
		is_pledged,
		lease_type,
		is_property,
		depr_overridden,
		linked,
		parent_id,
		num_children,
		last_modified_date, 
		modified_by,
		policy_number,
		depreciated, 
		is_imported 
	from 	amimpast_vw 
	where 	company_id 		= @MSKcompany_id 
	and 	asset_ctrl_num 	= @MSKasset_ctrl_num 

	select @rowsfound = @rowsfound + @@rowcount 

	 
	select 	@MSKasset_ctrl_num = min(asset_ctrl_num) 
	from 	amimpast_vw 
	where 	company_id 		= @MSKcompany_id 
	and 	asset_ctrl_num 	> @MSKasset_ctrl_num 
end 
select 
	timestamp,
	company_id,
	asset_ctrl_num,
	activity_state,
	co_asset_id,
	co_trx_id,
	posting_flag,
	asset_description,
	is_new,
	original_cost,
	acquisition_date 			= convert(char(8), acquisition_date,112), 
	placed_in_service_date 		= convert(char(8), placed_in_service_date,112), 
	original_in_service_date 	= convert(char(8), original_in_service_date,112), 
	disposition_date 			= convert(char(8), disposition_date,112), 
	service_units,
	orig_quantity,
	rem_quantity,
	category_code,
	status_code,
	asset_type_code,
	employee_code,
	location_code,
	owner_code,
	business_usage,
	personal_usage,
	investment_usage,
	account_reference_code,
	tag,
	note_id,
	user_field_id,
	is_pledged,
	lease_type,
	is_property,
	depr_overridden,
	linked,
	parent_id,
	num_children,
	last_modified_date 			= convert(char(8), last_modified_date,112), 
	modified_by,
	policy_number,
	depreciated,
	is_imported 
from #temp 
order by company_id, asset_ctrl_num 

drop table #temp 

return @@error 
GO
GRANT EXECUTE ON  [dbo].[amimpast_vwNext_sp] TO [public]
GO
