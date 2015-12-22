SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amassetLastRow_sp] 
as 


declare @MSKasset_ctrl_num 	smControlNumber, 
		@MSKcompany_id 		smCompanyID 

select @MSKcompany_id = max(company_id) 
from 	amasset_org_vw 

select 	@MSKasset_ctrl_num = max(asset_ctrl_num) 
from 	amasset_org_vw 
where  	company_id = @MSKcompany_id 

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
	,org_id
from 	amasset_org_vw 
where 	company_id 		= @MSKcompany_id 
and 	asset_ctrl_num 	= @MSKasset_ctrl_num 

return @@error 
GO
GRANT EXECUTE ON  [dbo].[amassetLastRow_sp] TO [public]
GO
