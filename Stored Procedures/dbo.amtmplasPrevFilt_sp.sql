SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amtmplasPrevFilt_sp] 
( 
	@rowsrequested                  smallint = 1,
	@company_id                     smCompanyID, 
	@template_code                 smTemplateCode, 
	@company_id_filter              smCompanyID, 
	@template_code_filter          smTemplateCode 
) as 


create table #temp 
( 
	timestamp 					varbinary(8) 	null,
	company_id 					smallint 		null,
	template_code 				char(16) 		null,
	template_description 		varchar(40) 	null,
	is_new 						tinyint 		null,
	original_cost 				float 			null,
	acquisition_date 			datetime 		null,
	placed_in_service_date 		datetime 		null,
	original_in_service_date 	datetime 		null,
	orig_quantity 				int 			null,
	category_code 				char(8) 		null,
	status_code 				char(8) 		null,
	asset_type_code 			varchar(8) 		null,
	employee_code 				varchar(9) 		null,
	location_code 				varchar(8) 		null,
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
	linked 						tinyint 		null,
	parent_id 					int 			null,
	policy_number 				varchar(40) 	null,
	last_modified_date 			datetime 		null,
	modified_by 				int 			null, 
	org_id					varchar(30)		null
)

declare @rowsfound 			smallint, 
		@MSKtemplate_code 	smTemplateCode, 
		@MSKcompany_id 		smCompanyID
		 
select @MSKtemplate_code = @template_code 
select @rowsfound = 0 
select @MSKcompany_id = @company_id 

select 	@MSKtemplate_code 	= max(template_code) 
from 	amtmplas 
where 	company_id 			= @MSKcompany_id 
and 	template_code 		< RTRIM(@MSKtemplate_code)
and 	template_code 		like @template_code_filter 

while @MSKtemplate_code is not null and @rowsfound < @rowsrequested 
begin 

	insert 	into #temp 
	select 	 
			timestamp,
			company_id,
			template_code,
			template_description,
			is_new,
			original_cost,
			acquisition_date, 
			placed_in_service_date, 
			original_in_service_date, 
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
			last_modified_date, 
			modified_by,
			org_id
	from 	amtmplas 
	where 	company_id 		= @MSKcompany_id 
	and 	template_code 	= @MSKtemplate_code 

	select @rowsfound = @rowsfound + @@rowcount 
	
	 
	select	@MSKtemplate_code = max(template_code) 
	from 	amtmplas 
	where 	company_id 		= @MSKcompany_id 
	and 	template_code 	< @MSKtemplate_code 
 	and 	template_code 	like RTRIM(@template_code_filter)
end 
select 
	timestamp,
	company_id,
	template_code,
	template_description,
	is_new,
	original_cost,
	acquisition_date 			= convert(char(8), acquisition_date,112), 
	placed_in_service_date 		= convert(char(8), placed_in_service_date,112), 
	original_in_service_date	= convert(char(8), original_in_service_date,112), 
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
	last_modified_date 			= convert(char(8), last_modified_date,112), 
	modified_by,
	org_id
from #temp 
order by  company_id, template_code 
drop table #temp 

return @@error 
GO
GRANT EXECUTE ON  [dbo].[amtmplasPrevFilt_sp] TO [public]
GO
