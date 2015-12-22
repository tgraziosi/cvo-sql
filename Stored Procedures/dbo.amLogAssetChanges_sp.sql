SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amLogAssetChanges_sp] 
(
 @co_asset_id 	smSurrogateKey, 				
 	@last_modified_date smApplyDate, 					
 	@modified_by 		smUserID 		= 0,			
 	@old_cat_code 		smCategoryCode 	= NULL,			
 	@new_cat_code 		smCategoryCode 	= NULL,			
 	@old_loc_code 		smLocationCode 	= NULL,			
 	@new_loc_code 		smLocationCode 	= NULL,			
 	@old_emp_code 		smEmployeeCode 	= NULL,			
 	@new_emp_code 		smEmployeeCode 	= NULL,			
 	@old_type_code 		smAssetTypeCode = NULL,			
 	@new_type_code 		smAssetTypeCode = NULL,			
 	@old_status_code 	smStatusCode 	= NULL,			
 	@new_status_code 	smStatusCode 	= NULL,			
 	@old_state 			smSystemState 	= NULL,			
 	@new_state 			smSystemState 	= NULL,			
 	@old_bus_use 		smPercentage 	= NULL,			
 	@new_bus_use 		smPercentage 	= NULL,			
 	@old_pers_use 		smPercentage 	= NULL,			
 	@new_pers_use 		smPercentage 	= NULL,			
 	@old_inv_use 		smPercentage 	= NULL,			
 	@new_inv_use 		smPercentage 	= NULL,			
 	@old_quantity		smQuantity		= NULL,			
 	@new_quantity		smQuantity		= NULL,			
 	@changed 			smLogical 		= 0 OUTPUT,	
	@debug_level		smDebugLevel	= 0				
)
AS 

DECLARE 
	@error smErrorCode 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amlogchg.sp" + ", line " + STR( 105, 5 ) + " -- ENTRY: "

IF @old_cat_code <> @new_cat_code 
BEGIN 
	INSERT INTO amastchg 
	(
		co_asset_id,
		field_type,
		apply_date,
		old_value,
		new_value,
		last_modified_date,
		modified_by
	)
	VALUES 
	(
		@co_asset_id,
		5,
		@last_modified_date,
		@old_cat_code,
		@new_cat_code,
		@last_modified_date,
		@modified_by
	)

	SELECT @error = @@error 
	IF @error <> 0 
		RETURN @error 
	SELECT @changed = 1 
END 

IF @old_loc_code <> @new_loc_code 
BEGIN 
	INSERT INTO amastchg 
	(
		co_asset_id,
		field_type,
		apply_date,
		old_value,
		new_value,
		last_modified_date,
		modified_by
	)
	VALUES 
	(
		@co_asset_id,
		1,
		@last_modified_date,
		@old_loc_code,
		@new_loc_code,
		@last_modified_date,
		@modified_by
	)

	SELECT @error = @@error 
	IF @error <> 0 
		RETURN @error 
	SELECT @changed = 1 
END 

IF @old_emp_code <> @new_emp_code 
BEGIN 
	INSERT INTO amastchg 
	(
		co_asset_id,
		field_type,
		apply_date,
		old_value,
		new_value,
		last_modified_date,
		modified_by
	)
	VALUES 
	(
		@co_asset_id,
		2,
		@last_modified_date,
		@old_emp_code,
		@new_emp_code,
		@last_modified_date,
		@modified_by
	)
	
	SELECT @error = @@error 
	IF @error <> 0 
		RETURN @error 
	SELECT @changed = 1 
END 

IF @old_type_code <> @new_type_code 
BEGIN 
	INSERT INTO amastchg 
	(
		co_asset_id,
		field_type,
		apply_date,
		old_value,
		new_value,
		last_modified_date,
		modified_by
	)
	VALUES 
	(
		@co_asset_id,
		3,
		@last_modified_date,
		@old_type_code,
		@new_type_code,
		@last_modified_date,
		@modified_by
	)

	SELECT @error = @@error 
	IF @error <> 0 
		RETURN @error 

	SELECT @changed = 1 
END 

IF @old_status_code <> @new_status_code 
BEGIN 
	INSERT INTO amastchg 
	(
		co_asset_id,
		field_type,
		apply_date,
		old_value,
		new_value,
		last_modified_date,
		modified_by
	)
	VALUES 
	(
		@co_asset_id,
		4,
		@last_modified_date,
		@old_status_code,
		@new_status_code,
		@last_modified_date,
		@modified_by
	)

	SELECT @error = @@error 
	IF @error <> 0 
		RETURN @error 

	SELECT @changed = 1 
END 

IF @old_state <> @new_state 
BEGIN 
	INSERT INTO amastchg 
	(
		co_asset_id,
		field_type,
		apply_date,
		old_value,
		new_value,
		last_modified_date,
		modified_by
	)
	VALUES 
	(
		@co_asset_id,
		6,
		@last_modified_date,
		convert(char(9), @old_state), 
		convert(char(9), @new_state), 
		@last_modified_date,
		@modified_by
	)
	
	SELECT @error = @@error 
	IF @error <> 0 
		RETURN @error 
	SELECT @changed = 1 
END 

IF @old_bus_use <> @new_bus_use 
BEGIN 
	INSERT INTO amastchg 
	(
		co_asset_id,
		field_type,
		apply_date,
		old_value,
		new_value,
		last_modified_date,
		modified_by
	)
	VALUES 
	(
		@co_asset_id,
		51,
		@last_modified_date,
		convert(char(255), @old_bus_use), 	
		convert(char(255), @new_bus_use), 	
		@last_modified_date,
		@modified_by
	)

	SELECT @error = @@error 
	IF @error <> 0 
		RETURN @error 
	SELECT @changed = 1 
END 

IF @old_pers_use <> @new_pers_use 
BEGIN 
	INSERT INTO amastchg 
	(
		co_asset_id,
		field_type,
		apply_date,
		old_value,
		new_value,
		last_modified_date,
		modified_by
	)
	VALUES 
	(
		@co_asset_id,
		52,
		@last_modified_date,
		convert(char(255), @old_pers_use), 
		convert(char(255), @new_pers_use), 
		@last_modified_date,
		@modified_by
	)

	SELECT @error = @@error 
	IF @error <> 0 
		RETURN @error 
	SELECT @changed = 1 
END 

IF @old_inv_use <> @new_inv_use 
BEGIN 
	INSERT INTO amastchg 
	(
		co_asset_id,
		field_type,
		apply_date,
		old_value,
		new_value,
		last_modified_date,
		modified_by
	)
	VALUES 
	(
		@co_asset_id,
		53,
		@last_modified_date,
		convert(char(255), @old_inv_use), 
		convert(char(255), @new_inv_use), 
		@last_modified_date,
		@modified_by
	)

	SELECT @error = @@error 
	IF @error <> 0 
		RETURN @error 
	SELECT @changed = 1 
END 

IF @old_quantity <> @new_quantity
BEGIN 
	INSERT INTO amastchg 
	(
		co_asset_id,
		field_type,
		apply_date,
		old_value,
		new_value,
		last_modified_date,
		modified_by
	)
	VALUES 
	(
		@co_asset_id,
		9,
		@last_modified_date,
		convert(char(9), @old_quantity), 
		convert(char(9), @new_quantity), 
		@last_modified_date,
		@modified_by
	)
	
	SELECT @error = @@error 
	IF @error <> 0 
		RETURN @error 
	SELECT @changed = 1 
END 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amlogchg.sp" + ", line " + STR( 403, 5 ) + " -- EXIT: "

RETURN @@error 
GO
GRANT EXECUTE ON  [dbo].[amLogAssetChanges_sp] TO [public]
GO
