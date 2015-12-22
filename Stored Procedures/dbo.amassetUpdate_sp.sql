SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amassetUpdate_sp] 
( 
	@timestamp                      timestamp,
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
	,@org_id			smOrgId
) 
AS 

DECLARE @rowcount 	int, 
		@error 		int, 
		@ts 		timestamp, 
		@message 	varchar(255)









SELECT dummy_select = 1

SELECT @acquisition_date = RTRIM(@acquisition_date) IF @acquisition_date = "" SELECT @acquisition_date = NULL
SELECT @placed_in_service_date = RTRIM(@placed_in_service_date) IF @placed_in_service_date = "" SELECT @placed_in_service_date = NULL
SELECT @original_in_service_date = RTRIM(@original_in_service_date) IF @original_in_service_date = "" SELECT @original_in_service_date = NULL
SELECT @disposition_date = RTRIM(@disposition_date) IF @disposition_date = "" SELECT @disposition_date = NULL
SELECT @last_modified_date = RTRIM(@last_modified_date) IF @last_modified_date = "" SELECT @last_modified_date = NULL








IF @status_code IS NULL
	SELECT @status_code = ""

UPDATE amasset 
SET 
	activity_state                  =       @activity_state,
	co_asset_id                     =       @co_asset_id,
	co_trx_id                       =       @co_trx_id,
	posting_flag                    =       @posting_flag,
	asset_description               =       @asset_description,
	is_new                          =       @is_new,
	original_cost                   =       @original_cost,
	acquisition_date                =       @acquisition_date,
	placed_in_service_date          =       @placed_in_service_date,
	original_in_service_date        =       @original_in_service_date,
	disposition_date                =       @disposition_date,
	service_units                   =       @service_units,
	orig_quantity                   =       @orig_quantity,
	rem_quantity                    =       @rem_quantity,
	category_code                   =       @category_code,
	status_code                     =       @status_code,
	asset_type_code                 =       @asset_type_code,
	employee_code                   =       @employee_code,
	location_code                   =       @location_code,
	owner_code                      =       @owner_code,
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
	depr_overridden                 =       @depr_overridden,
	linked                          =       @linked,
	parent_id                       =       @parent_id,
	num_children                    =       @num_children,
	last_modified_date              =       @last_modified_date,
	modified_by                     =       @modified_by,
	policy_number                   =       @policy_number,
	depreciated                     =       @depreciated,
	is_imported						= 		@is_imported 
	,org_id				=	@org_id
WHERE 	company_id                  =       @company_id 
AND 	asset_ctrl_num              =       @asset_ctrl_num 
AND 	timestamp                   =       @timestamp 

SELECT @error = @@error, @rowcount = @@rowcount 
IF @error <> 0   
	RETURN @error 

IF @rowcount = 0  
BEGIN 
	 
	SELECT 	@ts = timestamp 
	FROM 	amasset 
	WHERE 	company_id 		= @company_id 
	AND 	asset_ctrl_num 	= @asset_ctrl_num 

	SELECT @error = @@error, @rowcount = @@rowcount 
	IF @error <> 0   
		RETURN @error 
	IF @rowcount = 0  
	BEGIN 
		EXEC 		amGetErrorMessage_sp 20004, "amasetup.cpp", 217, amasset, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20004 @message 
		RETURN 		20004 
	END 
	IF @ts <> @timestamp 
	BEGIN 
		EXEC 		amGetErrorMessage_sp 20003, "amasetup.cpp", 223, amasset, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20003 @message 
		RETURN 		20003 
	END 
END 

RETURN @@error 
GO
GRANT EXECUTE ON  [dbo].[amassetUpdate_sp] TO [public]
GO
