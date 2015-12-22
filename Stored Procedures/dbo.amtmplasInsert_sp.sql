SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amtmplasInsert_sp] 
( 
	@company_id                     smCompanyID, 
	@template_code                 smTemplateCode, 
	@template_description              smStdDescription, 
	@is_new                         smLogicalTrue, 
	@original_cost                  smMoneyZero, 
	@acquisition_date               varchar(30), 
	@placed_in_service_date         varchar(30), 
	@original_in_service_date       varchar(30), 
	@orig_quantity                  smQuantity, 
	@category_code                  smCategoryCode, 
	@status_code                    smStatusCode, 
	@asset_type_code                smAssetTypeCode, 
	@employee_code                  smEmployeeCode, 
	@location_code                  smLocationCode, 
	@business_usage                 smPercentage, 
	@personal_usage                 smPercentage, 
	@investment_usage               smPercentage, 
	@account_reference_code         smAccountReferenceCode, 
	@tag                            smTag, 
	@note_id                        smSurrogateKey, 
	@user_field_id                  smSurrogateKey, 
	@is_pledged                     smLogicalFalse, 
	@lease_type                     smLeaseType, 
	@is_property                    smLogicalFalse, 
	@linked                         smLinkType, 
	@parent_id                      smSurrogateKey, 
	@policy_number                  smPolicyNumber, 
	@last_modified_date             varchar(30), 
	@modified_by                    smUserID,
	@org_id				varchar(30) 
) as 

declare @error int 

 

SELECT @acquisition_date = RTRIM(@acquisition_date) IF @acquisition_date = "" SELECT @acquisition_date = NULL
SELECT @placed_in_service_date = RTRIM(@placed_in_service_date) IF @placed_in_service_date = "" SELECT @placed_in_service_date = NULL
SELECT @original_in_service_date = RTRIM(@original_in_service_date) IF @original_in_service_date = "" SELECT @original_in_service_date = NULL
SELECT @last_modified_date = RTRIM(@last_modified_date) IF @last_modified_date = "" SELECT @last_modified_date = NULL

 

insert into amtmplas 
( 
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
)
values 
( 
	@company_id,
	@template_code,
	@template_description,
	@is_new,
	@original_cost,
	@acquisition_date,
	@placed_in_service_date,
	@original_in_service_date,
	@orig_quantity,
	@category_code,
	@status_code,
	@asset_type_code,
	@employee_code,
	@location_code,
	@business_usage,
	@personal_usage,
	@investment_usage,
	@account_reference_code,
	@tag,
	@note_id,
	@user_field_id,
	@is_pledged,
	@lease_type,
	@is_property,
	@linked,
	@parent_id,
	@policy_number,
	@last_modified_date,
	@modified_by,
	@org_id 
)
return @@error 
GO
GRANT EXECUTE ON  [dbo].[amtmplasInsert_sp] TO [public]
GO
