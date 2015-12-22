SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amtmplasUpdate_sp] 
( 
	@timestamp                      timestamp,
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
) 
as 

declare @rowcount 	int, 
		@error 		int, 
		@ts 		timestamp, 
		@message 	varchar(255)

SELECT @acquisition_date = RTRIM(@acquisition_date) IF @acquisition_date = "" SELECT @acquisition_date = NULL
SELECT @placed_in_service_date = RTRIM(@placed_in_service_date) IF @placed_in_service_date = "" SELECT @placed_in_service_date = NULL
SELECT @original_in_service_date = RTRIM(@original_in_service_date) IF @original_in_service_date = "" SELECT @original_in_service_date = NULL
SELECT @last_modified_date = RTRIM(@last_modified_date) IF @last_modified_date = "" SELECT @last_modified_date = NULL

update amtmplas set 
	template_description               =       @template_description,
	is_new                          =       @is_new,
	original_cost                   =       @original_cost,
	acquisition_date                =       @acquisition_date,
	placed_in_service_date          =       @placed_in_service_date,
	original_in_service_date        =       @original_in_service_date,
	orig_quantity                   =       @orig_quantity,
	category_code                   =       @category_code,
	status_code                     =       @status_code,
	asset_type_code                 =       @asset_type_code,
	employee_code                   =       @employee_code,
	location_code                   =       @location_code,
	business_usage                  =       @business_usage,
	personal_usage                  =       @personal_usage,
	investment_usage                =       @investment_usage,
	account_reference_code          =       @account_reference_code,
	tag                             =       @tag,
	note_id                         =       @note_id,
	user_field_id                   =       @user_field_id,
	is_pledged                      =       @is_pledged,
	lease_type                      =       @lease_type,
	is_property                     =       @is_property,
	linked                          =       @linked,
	parent_id                       =       @parent_id,
	policy_number                   =       @policy_number,
	last_modified_date              =       @last_modified_date,
	modified_by                     =       @modified_by,
	org_id                     =       @org_id  
where 	company_id                  =       @company_id 
and 	template_code              =       @template_code 
and 	timestamp                   =       @timestamp 

select @error = @@error, @rowcount = @@rowcount 
if @error <> 0   
	return @error 

if @rowcount = 0  
begin 
	 
	select 	@ts = timestamp 
	from 	amtmplas 
	where 	company_id 		= @company_id 
	and 	template_code 	= @template_code 

	select @error = @@error, @rowcount = @@rowcount 
	if @error <> 0   
		return @error 
	if @rowcount = 0  
	begin 
		EXEC 		amGetErrorMessage_sp 20004, "amtmasup.cpp", 144, amtmplas, @error_message = @message out 
		IF @message IS NOT NULL RAISERROR 	20004 @message 
		RETURN 		20004 
	end 
	if @ts <> @timestamp 
	begin 
		EXEC 		amGetErrorMessage_sp 20003, "amtmasup.cpp", 150, amtmplas, @error_message = @message out 
		IF @message IS NOT NULL RAISERROR 	20003 @message 
		RETURN 		20003 
	end 
end 
return @@error 
GO
GRANT EXECUTE ON  [dbo].[amtmplasUpdate_sp] TO [public]
GO
