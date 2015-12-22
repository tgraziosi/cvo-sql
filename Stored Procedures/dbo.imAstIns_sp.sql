SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[imAstIns_sp] 
( 
	@company_id					smallint,				
	@asset_ctrl_num				char(16),					
	@asset_description			varchar(40) 	= "",	
	@is_new						int				= 0,	
	@original_cost				float 			= 0.00,	
	@acquisition_date			char(8),				
	@placed_in_service_date		char(8)			= NULL,	
	@original_in_service_date	char(8)			= NULL,	
	@disposition_date			char(8) 		= NULL,	
	@orig_quantity				int 			= 1,	
	@category_code				char(8) 		= NULL,	
	@status_code				char(8) 		= NULL,	
	@asset_type_code			char(8) 		= NULL,	
	@employee_code				char(9) 		= NULL,	
	@location_code				char(8) 		= NULL,	
	@business_usage				float 			= 100,	
	@personal_usage				float 			= 0,	
	@investment_usage			float 			= 0,	
	@account_reference_code		varchar(32) 	= "",	
	@tag						varchar(32)		= "",	
	@is_pledged					int 			= 0,	


	@lease_type					int 			= 1,	
	@is_property				int 			= 0,	


	@last_modified_date			char(8) 		= NULL,	
	@modified_by				int 			= 1,	
	@policy_number				varchar(40) 	= "",	
	@stop_on_error				tinyint			= 0,	
	@debug_level				smallint		= 0		
	,@org_id				varchar(30) = ""

)
AS 

DECLARE
	@result			int,			
	@message		varchar(255),	
	@is_valid		tinyint
	,@org_flag		int

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "imastins.cpp" + ", line " + STR( 95, 5 ) + " -- ENTRY: "







	IF (@employee_code = "''")
		SELECT @employee_code = " "
	IF (@account_reference_code = "''")
		SELECT @account_reference_code = " "
	IF (@location_code = "''")
		SELECT @location_code = " "
	IF (@asset_type_code = "''")
		SELECT @asset_type_code = " "








IF @last_modified_date IS NULL
	SELECT	@last_modified_date = CONVERT(char(8), GETDATE(), 112)

EXEC @result = imAstVal_sp
					@action 					= 0,
					@company_id					= @company_id,
					@asset_ctrl_num				= @asset_ctrl_num,
					@asset_description			= @asset_description,
					@is_new						= @is_new,
					@original_cost				= @original_cost,
					@acquisition_date			= @acquisition_date,
					@placed_in_service_date		= @placed_in_service_date,
					@original_in_service_date	= @original_in_service_date,
					@disposition_date			= @disposition_date,
					@orig_quantity				= @orig_quantity,
					@category_code				= @category_code,
					@status_code				= @status_code,
					@asset_type_code			= @asset_type_code,
					@employee_code				= @employee_code,
					@location_code				= @location_code,
					@business_usage				= @business_usage,
					@personal_usage				= @personal_usage,
					@investment_usage			= @investment_usage,
					@account_reference_code		= @account_reference_code,
					@tag						= @tag,
					@is_pledged					= @is_pledged,
					@lease_type					= @lease_type,
					@is_property				= @is_property,
					@last_modified_date			= @last_modified_date,
					@modified_by				= @modified_by,
					@policy_number				= @policy_number,
					@stop_on_error				= @stop_on_error,
					@is_valid					= @is_valid			OUTPUT
					,@org_id				= @org_id

IF @result <> 0
	RETURN @result

IF @is_valid = 1
BEGIN

	



	SELECT @org_flag = ib_flag FROM glco
	IF @org_flag = 0 AND @org_id IS NULL
	BEGIN
		SELECT @org_id = org_id 
		from amOrganization_vw
		where outline_num = '1'
	END

	IF @status_code IS NULL
		SELECT	@status_code = ""
		
	EXEC @result = amassetInsert_sp
					@company_id					= @company_id, 
					@asset_ctrl_num				= @asset_ctrl_num, 
					@activity_state 			= 100, 		
					@co_asset_id 				= 0, 			 
					@co_trx_id					= 0,  			
					@posting_flag				= 0, 			
					@asset_description			= @asset_description, 
					@is_new						= @is_new, 
					@original_cost				= @original_cost, 
					@acquisition_date			= @acquisition_date, 
					@placed_in_service_date		= @placed_in_service_date, 
					@original_in_service_date	= @original_in_service_date, 
					@disposition_date			= @disposition_date, 
					@service_units				= 0, 			
					@orig_quantity				= @orig_quantity, 
					@rem_quantity				= @orig_quantity, 
					@category_code				= @category_code, 
					@status_code				= @status_code, 
					@asset_type_code			= @asset_type_code, 
					@employee_code				= @employee_code, 
					@location_code				= @location_code, 
					@owner_code					= NULL, 		
					@business_usage				= @business_usage, 
					@personal_usage				= @personal_usage, 
					@investment_usage			= @investment_usage, 
					@account_reference_code		= @account_reference_code, 
					@tag						= @tag, 
					@note_id					= 0, 			
					@user_field_id				= 0, 			
					@is_pledged					= @is_pledged, 
					@lease_type					= @lease_type, 
					@is_property				= @is_property, 
					@depr_overridden			= 0,
					@linked						= 0, 			
					@parent_id					= 0, 
					@num_children				= 0, 
					@last_modified_date			= @last_modified_date, 
					@modified_by				= @modified_by, 
					@policy_number				= @policy_number, 
					@depreciated				= 0,			 
					@is_imported				= 1
					,@org_id				= @org_id

		SELECT @result = @@error
		IF @result <> 0
			RETURN @result

		


		IF @debug_level < 100
			EXEC 		amGetErrorMessage_sp 
						20404, "imastins.cpp", 228, 
						@asset_ctrl_num, 
						@error_message = @message OUT 
		
END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "imastins.cpp" + ", line " + STR( 234, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[imAstIns_sp] TO [public]
GO
