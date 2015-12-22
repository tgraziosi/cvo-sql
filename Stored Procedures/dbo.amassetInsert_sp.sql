SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amassetInsert_sp] 
( 
	@company_id                     smCompanyID, 
	@asset_ctrl_num                 smControlNumber, 
	@activity_state                 smSystemState, 
	@co_asset_id                    smSurrogateKey, 
	@co_trx_id                      smSurrogateKey, 
	@posting_flag                   smPostingState, 
	@asset_description              smStdDescription, 
	@is_new                         smLogicalTrue, 
	@original_cost                  smMoneyZero, 
	@acquisition_date               varchar(30), 
	@placed_in_service_date         varchar(30), 
	@original_in_service_date       varchar(30), 
	@disposition_date               varchar(30), 
	@service_units                  smServiceUnits, 
	@orig_quantity                  smQuantity, 
	@rem_quantity                   smQuantity, 
	@category_code                  smCategoryCode, 
	@status_code                    smStatusCode, 
	@asset_type_code                smAssetTypeCode, 
	@employee_code                  smEmployeeCode, 
	@location_code                  smLocationCode, 
	@owner_code                     smSegmentCode, 
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
	@depr_overridden                smLogicalFalse, 
	@linked                         smLinkType, 
	@parent_id                      smSurrogateKey, 
	@num_children                   smCounter, 
	@last_modified_date             varchar(30), 
	@modified_by                    smUserID, 
	@policy_number                  smPolicyNumber, 
	@depreciated                    smLogicalFalse,
	@is_imported					smLogicalFalse 
	, @org_id			smOrgId
) as 

declare @error int 

 

SELECT @acquisition_date = RTRIM(@acquisition_date) IF @acquisition_date = "" SELECT @acquisition_date = NULL
SELECT @placed_in_service_date = RTRIM(@placed_in_service_date) IF @placed_in_service_date = "" SELECT @placed_in_service_date = NULL
SELECT @original_in_service_date = RTRIM(@original_in_service_date) IF @original_in_service_date = "" SELECT @original_in_service_date = NULL
SELECT @disposition_date = RTRIM(@disposition_date) IF @disposition_date = "" SELECT @disposition_date = NULL
SELECT @last_modified_date = RTRIM(@last_modified_date) IF @last_modified_date = "" SELECT @last_modified_date = NULL








IF @status_code IS NULL	
	SELECT	@status_code = ""

 

insert into amasset 
( 
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
	,org_id
)
values 
( 
	@company_id,
	@asset_ctrl_num,
	@activity_state,
	@co_asset_id,
	@co_trx_id,
	@posting_flag,
	@asset_description,
	@is_new,
	@original_cost,
	@acquisition_date,
	@placed_in_service_date,
	@original_in_service_date,
	@disposition_date,
	@service_units,
	@orig_quantity,
	@rem_quantity,
	@category_code,
	@status_code,
	@asset_type_code,
	@employee_code,
	@location_code,
	@owner_code,
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
	@depr_overridden,
	@linked,
	@parent_id,
	@num_children,
	@last_modified_date,
	@modified_by,
	@policy_number,
	@depreciated,
	@is_imported 
	,@org_id
)
return @@error 
GO
GRANT EXECUTE ON  [dbo].[amassetInsert_sp] TO [public]
GO
