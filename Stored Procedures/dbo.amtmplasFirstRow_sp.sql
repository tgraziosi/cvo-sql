SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amtmplasFirstRow_sp] 
as 


declare @MSKtemplate_code 	smTemplateCode, 
		@MSKcompany_id 		smCompanyID 

select 	@MSKcompany_id = min(company_id) 
from 	amtmplas 

select 	@MSKtemplate_code = min(template_code) 
from 	amtmplas 
where   company_id = @MSKcompany_id 

select 
	timestamp,
	company_id,
	template_code,
	template_description,
	is_new,
	original_cost,
	acquisition_date 			= convert(char(8), acquisition_date,112), 
	placed_in_service_date 		= convert(char(8), placed_in_service_date,112), 
	original_in_service_date 	= convert(char(8), original_in_service_date,112), 
	orig_quantity,
	category_code,
	status_code,
	asset_type_code,
	employee_code,
	location_code,
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
	linked,
	parent_id,
	policy_number,
	last_modified_date 		= convert(char(8), last_modified_date,112), 
	modified_by,
	org_id
from 	amtmplas 
where 	company_id 		= @MSKcompany_id 
and 	template_code 	= @MSKtemplate_code 

return @@error 
GO
GRANT EXECUTE ON  [dbo].[amtmplasFirstRow_sp] TO [public]
GO
