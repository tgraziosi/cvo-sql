SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amReplicateAsset_sp] 
(
	@company_id			smCompanyID,				
	@co_asset_id		smSurrogateKey, 			
	@num_times   	 	smCounter,        			
	@user_id			smUserID,					
	@asset_ctrl_num		smControlNumber	OUTPUT,		
	@last_apply_date	smISODate		= NULL,		



	@debug_level		smDebugLevel 	= 0 		
)
AS 

DECLARE 
	@result					smErrorCode, 
	@message		        smErrorLongDesc,
	@new_asset_ctrl_num		smControlNumber,
	@count					smCounter,
	@new_co_asset_id		smSurrogateKey,
	@old_user_field_id		smSurrogateKey,
	@new_user_field_id		smSurrogateKey,
	@apply_date				smApplyDate				
	

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "amrepast.cpp" + ", line " + STR( 75, 5 ) + " -- ENTRY: "




SELECT dummy_select = 1




IF @last_apply_date IS NOT NULL
	SELECT 	@apply_date = CONVERT(datetime, @last_apply_date)
ELSE
	SELECT 	@apply_date			= MAX(apply_date)
	FROM	amastbk ab,
			amacthst ah
	WHERE	ab.co_asset_book_id = ah.co_asset_book_id
	AND		ab.co_asset_id		= @co_asset_id





SELECT	@old_user_field_id 	= user_field_id
FROM	amasset	
WHERE	co_asset_id 		= @co_asset_id

SELECT	@count = 0
WHILE	@count < @num_times
BEGIN

	


	EXEC @result = amNextControlNumber_sp
					@company_id, 
				    1,					
				    @new_asset_ctrl_num    OUTPUT, 	
					@debug_level

	IF @result <> 0
		RETURN @result 

	


	IF @count = 0
		SELECT	@asset_ctrl_num = @new_asset_ctrl_num
		
	


	INSERT INTO amasset 
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
		is_imported,
		org_id 
	)
	SELECT 
		company_id,
		@new_asset_ctrl_num,
		100,			
		0,					
		0,					
		0,				
		asset_description,
		1,				
		original_cost,
		acquisition_date,
		placed_in_service_date,
		original_in_service_date,
		NULL,				
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
		0,					
		0,					
		is_pledged,
		lease_type,
		is_property,
		depr_overridden,
		linked,
		parent_id,
		0,					
		GETDATE(),
		-@user_id,
		policy_number,
		0,				
		0,				 
		org_id	

	FROM	amasset
	WHERE	co_asset_id = @co_asset_id


	SELECT	@result = @@error
	IF	@result <> 0
		RETURN @result
	
	


	SELECT	@new_co_asset_id 	= co_asset_id,
			@new_user_field_id	= user_field_id
	FROM	amasset
	WHERE	company_id			= @company_id
	AND		asset_ctrl_num		= @new_asset_ctrl_num

	




	INSERT INTO amusrfld 
	(
		user_field_id, 
		user_code_1,
		user_code_2,
		user_code_3,
		user_code_4,
		user_code_5,
		user_date_1,
		user_date_2,
		user_date_3,
		user_date_4,
		user_date_5,
		user_amount_1,
		user_amount_2,
		user_amount_3,
		user_amount_4,
		user_amount_5
	)
	SELECT
		@new_user_field_id,
		user_code_1,
		user_code_2,
		user_code_3,
		user_code_4,
		user_code_5,
		user_date_1,
		user_date_2,
		user_date_3,
		user_date_4,
		user_date_5,
		user_amount_1,
		user_amount_2,
		user_amount_3,
		user_amount_4,
		user_amount_5
	FROM	amusrfld 
	WHERE 	user_field_id		= @old_user_field_id
	  
	SELECT	@result = @@error
	IF	@result <> 0
		RETURN @result
	
	




	INSERT INTO amitem
	(
		co_asset_id,
		sequence_id,
		posting_flag,
		co_trx_id,
		manufacturer,
		model_num,
		serial_num,
		item_code,
		item_description,
		po_ctrl_num,
		contract_number,
		vendor_code,
		vendor_description,
		invoice_num,
		invoice_date, 
		original_cost,
		manufacturer_warranty,
		vendor_warranty,
		item_tag,
		item_quantity,
		item_disposition_date,
		last_modified_date,
		modified_by 
	)
	SELECT
		@new_co_asset_id,
		sequence_id,
		posting_flag,
		0,
		manufacturer,
		model_num,
		serial_num,
		item_code,
		item_description,
		po_ctrl_num,
		contract_number,
		vendor_code,
		vendor_description,
		invoice_num,
		invoice_date, 
		original_cost,
		manufacturer_warranty,
		vendor_warranty,
		item_tag,
		item_quantity,
		item_disposition_date,
		GETDATE(),
		@user_id 
	FROM	amitem
	WHERE	co_asset_id = @co_asset_id

	SELECT	@result = @@error
	IF	@result <> 0
		RETURN @result

	


	INSERT INTO amastcls
	(
		company_id,
		classification_id,
		co_asset_id,
		classification_code,
		last_modified_date,
		modified_by
	)
	SELECT
		company_id,
		classification_id,
		@new_co_asset_id,
		classification_code,
		GETDATE(),
		@user_id
	FROM	amastcls
	WHERE	co_asset_id = @co_asset_id

	SELECT	@result = @@error
	IF	@result <> 0
		RETURN @result
	
	


	EXEC @result = amReplicateBooks_sp
					@company_id,
				    @co_asset_id, 		
				    @new_co_asset_id,
					@user_id,
					@apply_date,
					@debug_level
					
	IF	@result <> 0
		RETURN @result
	
	


	SELECT	@count = @count + 1
END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "amrepast.cpp" + ", line " + STR( 389, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amReplicateAsset_sp] TO [public]
GO
