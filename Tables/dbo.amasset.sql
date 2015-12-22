CREATE TABLE [dbo].[amasset]
(
[timestamp] [timestamp] NOT NULL,
[company_id] [dbo].[smCompanyID] NOT NULL,
[asset_ctrl_num] [dbo].[smControlNumber] NOT NULL,
[activity_state] [dbo].[smSystemState] NOT NULL,
[co_asset_id] [dbo].[smSurrogateKey] NOT NULL,
[co_trx_id] [dbo].[smSurrogateKey] NOT NULL,
[posting_flag] [dbo].[smPostingState] NOT NULL,
[asset_description] [dbo].[smStdDescription] NOT NULL,
[is_new] [dbo].[smLogicalTrue] NOT NULL,
[original_cost] [dbo].[smMoneyZero] NOT NULL,
[acquisition_date] [dbo].[smApplyDate] NOT NULL,
[placed_in_service_date] [dbo].[smApplyDate] NULL,
[original_in_service_date] [dbo].[smApplyDate] NULL,
[disposition_date] [dbo].[smApplyDate] NULL,
[service_units] [dbo].[smServiceUnits] NOT NULL,
[orig_quantity] [dbo].[smQuantity] NOT NULL,
[rem_quantity] [dbo].[smQuantity] NOT NULL,
[category_code] [dbo].[smCategoryCode] NOT NULL,
[status_code] [dbo].[smStatusCode] NOT NULL,
[asset_type_code] [dbo].[smAssetTypeCode] NULL,
[employee_code] [dbo].[smEmployeeCode] NULL,
[location_code] [dbo].[smLocationCode] NULL,
[owner_code] [dbo].[smSegmentCode] NULL,
[business_usage] [dbo].[smPercentage] NOT NULL,
[personal_usage] [dbo].[smPercentZero] NOT NULL,
[investment_usage] [dbo].[smPercentZero] NOT NULL,
[account_reference_code] [dbo].[smAccountReferenceCode] NOT NULL,
[tag] [dbo].[smTag] NOT NULL,
[note_id] [dbo].[smSurrogateKey] NOT NULL,
[user_field_id] [dbo].[smSurrogateKey] NOT NULL,
[is_pledged] [dbo].[smLogicalFalse] NOT NULL,
[lease_type] [dbo].[smLeaseType] NOT NULL,
[is_property] [dbo].[smLogicalFalse] NOT NULL,
[depr_overridden] [dbo].[smLogicalFalse] NOT NULL,
[linked] [dbo].[smLinkType] NOT NULL,
[parent_id] [dbo].[smSurrogateKey] NOT NULL,
[num_children] [dbo].[smCounter] NOT NULL,
[last_modified_date] [dbo].[smApplyDate] NOT NULL,
[modified_by] [dbo].[smUserID] NOT NULL,
[policy_number] [dbo].[smPolicyNumber] NOT NULL,
[depreciated] [dbo].[smLogicalFalse] NOT NULL,
[is_imported] [dbo].[smLogicalFalse] NOT NULL,
[org_id] [dbo].[smOrgId] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE TRIGGER 	[dbo].[amasset_del_trg] 
ON 				[dbo].[amasset] 
FOR 			DELETE 
AS 

DECLARE
 	@rowcount 	smCounter, 
	@num_rows 	smCounter, 
	@rollback 	smLogical, 
	@message 	smErrorLongDesc,
	@param		smErrorParam 

SELECT 	@rowcount = @@rowcount 
SELECT 	@rollback = 0 





 
SELECT 	@num_rows 		= COUNT(co_asset_id) 
FROM 	deleted 
WHERE 	activity_state 	= 100 
OR 		activity_state 	= 101 

IF @num_rows != @rowcount 
BEGIN 



	SELECT	@param 			= MIN(asset_ctrl_num)
	FROM	deleted
	WHERE 	activity_state 	NOT IN (100, 101)
	
	EXEC	 	amGetErrorMessage_sp 20073, ".\\amasset.dtr", 123, @param, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20073 @message 
	SELECT 		@rollback = 1 
END 

 
IF @rollback = 0 
BEGIN 
	DELETE 	amtrxhdr 
	FROM 	deleted d, 
			amtrxhdr f 
	WHERE 	f.co_asset_id = d.co_asset_id 

	IF @@error <> 0 
		SELECT @rollback = 1 
END 

IF @rollback = 0 
BEGIN 
	DELETE 	amastbk 
	FROM 	deleted d, 
			amastbk f 
	WHERE 	f.co_asset_id = d.co_asset_id 

	IF @@error <> 0 
		SELECT @rollback = 1 
END 

IF @rollback = 0 
BEGIN 
	DELETE 	amastcls 
	FROM 	deleted d, 
			amastcls f 
	WHERE 	f.co_asset_id = d.co_asset_id 

	IF @@error <> 0 
		SELECT @rollback = 1 
END 

IF @rollback = 0 
BEGIN 
	DELETE 	amastchg 
	FROM 	deleted d, 
			amastchg f 
	WHERE 	f.co_asset_id = d.co_asset_id 

	IF @@error <> 0 
		SELECT @rollback = 1 
END 

IF @rollback = 0 
BEGIN 
	DELETE 	amitem 
	FROM 	deleted d, 
			amitem f 
	WHERE 	f.co_asset_id	= d.co_asset_id 

	IF @@error <> 0 
		SELECT @rollback = 1 
END 

IF @rollback = 0 
BEGIN 
	DELETE 	amusrfld 
	FROM 	deleted d, 
			amusrfld f 
	WHERE 	f.user_field_id = d.user_field_id 

	IF @@error <> 0 
		SELECT @rollback = 1 
END 

IF @rollback = 0 
BEGIN 
	DELETE 	amastact 
	FROM 	deleted d, 
			amastact f 
	WHERE 	f.co_asset_id 	= d.co_asset_id 

	IF @@error <> 0 
		SELECT @rollback = 1 
END 

IF @rollback = 1 
BEGIN
	ROLLBACK TRANSACTION 
	RETURN
END
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER 	[dbo].[amasset_ins_trg] 
ON 				[dbo].[amasset] 
FOR 			INSERT 
AS 

DECLARE 
	@rowcount 			smCounter, 				
	@rollback 			smLogical, 				
	@message 			smErrorLongDesc,		
	@param1 			smErrorParam, 			
	@param2 			smErrorParam, 			
	@param3 			smErrorParam, 			
 	@ret_status 		smErrorCode, 			
	@asset_ctrl_num		smControlNumber,		
	@activity_state	 	smSystemState,			 
	@acq_date 			smApplyDate,			 
	@disp_date 			smApplyDate,			 
	@placed_date 		smApplyDate, 			
	@bus_use 			smPercentage, 			
	@pers_use 			smPercentage, 			
	@inv_use 			smPercentage, 			
	@category_code 		smCategoryCode,			 
	@user_field_id 		smSurrogateKey,			 
	@co_asset_id 		smSurrogateKey, 		
 	@original_cost 		smMoneyZero, 			
 	@quantity			smQuantity,				
 	@acct_ref_code 		smAccountReferenceCode, 
 	@is_new 			smLogical, 				
 	@company_id 		smCompanyID,			
 	@modify_date		smApplyDate,			
    @location_code		smLocationCode,			
    @employee_code		smEmployeeCode,			
    @asset_type_code	smAssetTypeCode,		
	@status_code		smStatusCode,			
    @changed			smLogical,				
    @dates_valid		smLogical,				
    @is_imported		smLogical,				
	@tag				smTag,					
	@last_modified_date	smApplyDate,			
	@modified_by		smUserID,				
	@add_ids			smLogical,				


   	@i					smSmallCounter,			
	@org_id                    varchar(30)			

SELECT 	@rowcount 	= @@rowcount 
SELECT 	@rollback 	= 0
SELECT	@add_ids	= 0 







 
IF ( SELECT COUNT(i.company_id) 
		FROM 	inserted 	i, 
				amco 		co 
		WHERE 	co.company_id = i.company_id) <> @rowcount 
BEGIN 
	EXEC 		amGetErrorMessage_sp 20508, ".\\amasset.itr", 266, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20508 @message 
	SELECT 		@rollback = 1 
END 



 
IF @rollback = 1 
BEGIN 
	ROLLBACK TRANSACTION 
	RETURN 
END 



 		 

EXEC amGetCompanyID_sp 
			@company_id OUT 

SELECT 	@asset_ctrl_num = MIN(asset_ctrl_num)
FROM 	inserted 
WHERE 	company_id 		= @company_id 

WHILE @asset_ctrl_num IS NOT NULL 
BEGIN 



	 
	SELECT 
			@category_code 		= category_code,
			@acct_ref_code 		= account_reference_code,
			@co_asset_id 		= co_asset_id,
			@user_field_id 		= user_field_id,
			@activity_state 	= activity_state,
			@acq_date 			= acquisition_date,
			@disp_date 			= disposition_date,
			@placed_date 		= placed_in_service_date,
			@bus_use 			= business_usage,
			@pers_use 			= personal_usage,
			@inv_use 	   		= investment_usage,
			@original_cost 		= original_cost,
			@quantity			= orig_quantity,
			@is_new 			= is_new,
			@modified_by		= modified_by,
			@location_code		= location_code,
			@employee_code		= employee_code,
			@asset_type_code 	= asset_type_code,
			@status_code		= status_code,
			@is_imported		= is_imported,
			@tag				= tag,
			@last_modified_date	= last_modified_date,
			@org_id	= org_id
	FROM 	inserted 
	WHERE 	inserted.asset_ctrl_num = @asset_ctrl_num 
	AND 	inserted.company_id 	= @company_id 
	
	





	IF @modified_by > 0 
	BEGIN
		

 
		IF NOT EXISTS (SELECT 	category_code 
						FROM 	amcat  
						WHERE 	category_code = @category_code) 
		BEGIN 

			EXEC	 	amGetErrorMessage_sp 20510, ".\\amasset.itr", 341, @category_code, @asset_ctrl_num, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	20510 @message 
			SELECT 		@rollback = 1 			  
		END 

		


 
		IF 	( LTRIM(@status_code) IS NOT NULL AND LTRIM(@status_code) != " " )
		BEGIN
			IF NOT EXISTS (SELECT 	status_code 
							FROM 	amstatus  
							WHERE 	status_code = @status_code) 
			BEGIN 
				EXEC 		amGetErrorMessage_sp 20502, ".\\amasset.itr", 356, @status_code, @asset_ctrl_num, @error_message = @message OUT 
				IF @message IS NOT NULL RAISERROR 	20502 @message 
				SELECT 		@rollback = 1 
			END 
		END

		

 
		IF @asset_type_code IS NOT NULL
		BEGIN
			IF NOT EXISTS (SELECT 	asset_type_code 
							FROM 	amasttyp  
							WHERE 	asset_type_code = @asset_type_code) 
			BEGIN 
				EXEC	 	amGetErrorMessage_sp 20512, ".\\amasset.itr", 371, @asset_type_code, @asset_ctrl_num, @error_message = @message OUT 
				IF @message IS NOT NULL RAISERROR 	20512 @message 
				SELECT 		@rollback = 1 
			END 
		END

		

 
		IF @employee_code IS NOT NULL
		BEGIN
			IF NOT EXISTS (SELECT 	employee_code 
							FROM 	amemp  
							WHERE 	employee_code = @employee_code) 
			BEGIN 
				EXEC 		amGetErrorMessage_sp 20506, ".\\amasset.itr", 386, @employee_code, @asset_ctrl_num, @error_message = @message OUT 
				IF @message IS NOT NULL RAISERROR 	20506 @message 
				SELECT 		@rollback = 1 
			END 
		END

		

 
		IF @location_code IS NOT NULL
		BEGIN
			IF NOT EXISTS (SELECT 	location_code 
							FROM 	amloc  
							WHERE 	location_code = @location_code) 
			BEGIN 
				EXEC	 	amGetErrorMessage_sp 20504, ".\\amasset.itr", 401, @location_code, @asset_ctrl_num, @error_message = @message OUT 
				IF @message IS NOT NULL RAISERROR 	20504 @message 
				SELECT 		@rollback = 1
			END 
		END 

		


 
	    IF ( LTRIM(@acct_ref_code) IS NOT NULL AND LTRIM(@acct_ref_code) != " " )
		BEGIN
			IF NOT EXISTS (SELECT 	reference_code 
							FROM 	glref  
							WHERE 	reference_code 	= @acct_ref_code
							AND		status_flag		= 0) 
			BEGIN 
				EXEC	 	amGetErrorMessage_sp 20500, ".\\amasset.itr", 418, @acct_ref_code, @asset_ctrl_num, @error_message = @message OUT 
				IF @message IS NOT NULL RAISERROR 	20500 @message 
				SELECT 		@rollback = 1 
			END 
		END

		


		IF 	@activity_state != 100
		BEGIN 
			EXEC	 	amGetErrorMessage_sp 20070, ".\\amasset.itr", 429, @asset_ctrl_num, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	20070 @message 
			SELECT 		@rollback = 1 
		END 
		
		

 
		IF NOT EXISTS (SELECT 	org_id 
						FROM 	amOrganization_vw  
						WHERE 	org_id = @org_id) 
		BEGIN 

			EXEC	 	amGetErrorMessage_sp 20514, ".\\amasset.itr", 442, @org_id, @asset_ctrl_num, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	20514 @message 
			SELECT 		@rollback = 1 			  
		END 

		



		EXEC @ret_status = amValidateAssetDates_sp
								0,						



								@asset_ctrl_num,
								@acq_date,
								@placed_date,
								@dates_valid OUTPUT
		
		IF 	@ret_status 	<> 0 
		OR	@dates_valid 	= 0
			SELECT @rollback = 1

		

 
		IF (ABS(100.00 - ( @bus_use + @pers_use + @inv_use)) > 0.00001)  
		BEGIN 
			SELECT @param1 = RTRIM(CONVERT(char(255),  @bus_use))
			SELECT @param2 = RTRIM(CONVERT(char(255),  @pers_use))
			SELECT @param3 = RTRIM(CONVERT(char(255),  @inv_use))

			EXEC	 	amGetErrorMessage_sp 20072, ".\\amasset.itr", 474, @param1, @param2, @param3, @asset_ctrl_num, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	20072 @message 
			SELECT 		@rollback = 1 
		END 
		
		





		
		IF @rollback = 1 
		BEGIN 
	


			ROLLBACK TRANSACTION 
			RETURN 
		END 
	END

	IF @co_asset_id = 0 
	BEGIN 
		SELECT	@add_ids	= 1
		 
		EXEC @ret_status = amNextKey_sp 
							5, 
							@co_asset_id OUT 
		IF @ret_status <> 0 
		BEGIN 
			SELECT @rollback = 1 
			ROLLBACK TRANSACTION 
			RETURN 
		END 
	END 

	IF @user_field_id = 0 
	BEGIN
		SELECT	@add_ids	= 1
		EXEC @ret_status = amNextKey_sp 
							9, 
							@user_field_id OUT 
		IF @ret_status <> 0 
		BEGIN 
			SELECT @rollback = 1 
			ROLLBACK TRANSACTION 
			RETURN 
		END 

	END

	IF @add_ids = 1
	BEGIN
		

 
		UPDATE 	amasset 
		SET 	co_asset_id 	= @co_asset_id,
				user_field_id	= @user_field_id,
				modified_by		= ABS(@modified_by) 
		WHERE 	company_id 		= @company_id 
		AND 	asset_ctrl_num 	= @asset_ctrl_num 
		
		SELECT @ret_status = @@error
		IF @ret_status <> 0 
		BEGIN 
			SELECT @rollback = 1 
			ROLLBACK TRANSACTION 
			RETURN 
		END 
			
	END 

	






	IF @modified_by > 0
	BEGIN
		 
	



		
		EXEC 	@ret_status = amCreateAssetBooks_sp 
									@company_id,
									@co_asset_id, 
									@category_code, 
									@acq_date, 
									@placed_date,
									@original_cost,
									@modified_by,
									@org_id
		IF @ret_status <> 0 
		BEGIN 
			SELECT @rollback = 1 
			ROLLBACK TRANSACTION 
			RETURN 
		END 

		




 
	   	SELECT	@modify_date 	= GETDATE(),
	   			@modified_by	= ABS(@modified_by) 

		EXEC @ret_status = amLogAssetChanges_sp 
								@co_asset_id,
								@modify_date,		
								@modified_by,	
								NULL, 		@category_code,
								NULL, 		@location_code,
								NULL,		@employee_code,
								NULL, 		@asset_type_code,
								NULL, 		@status_code,
								NULL, 		@activity_state,
								NULL, 		@bus_use,
								NULL, 		@pers_use,
							   	NULL, 		@inv_use,
								NULL,		@quantity,
								@changed OUTPUT 
		
		IF @ret_status <> 0 
		BEGIN 
	


			ROLLBACK TRANSACTION 
			RETURN 
		END 
	END

	
	
	INSERT INTO	amastact
	(
		co_asset_id,
	    account_type_id,
	    account_code,
		up_to_date,
		last_modified_date
	)
	SELECT	
		@co_asset_id,
		account_type,					
		"",
		0,				
	   	GETDATE()
	FROM amacctyp
		
		
	



	 
	SELECT 	@asset_ctrl_num = MIN(asset_ctrl_num)
	FROM 	inserted 
	WHERE 	asset_ctrl_num 	> @asset_ctrl_num 
	AND 	company_id 		= @company_id 

END 




GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER 	[dbo].[amasset_upd_trg] 
ON 				[dbo].[amasset] 
FOR UPDATE 
AS 

DECLARE 
	@rowcount 			smCounter, 
 	@rollback 			smCounter, 
 	@message 			smErrorLongDesc,
 	@param1 	 	 	smErrorParam, 			
 	@param2 	 	 	smErrorParam, 			
 	@param3 	 	 	smErrorParam, 		 	
	@ret_status 		smErrorCode, 			
 	@asset_ctrl_num 	smControlNumber,		
 	@acct_ref_code 		smAccountReferenceCode, 
 	@company_id 		smCompanyID, 			
	@co_asset_id 		smSurrogateKey, 		
	@user_id 			smUserID ,				
	@modify_date 		smApplyDate, 			
 	@changed 			smLogical, 				
	@is_valid			smLogical,				
	@is_imported		smLogical,				
	@new_cat_code 		smCategoryCode, 	 	
	@old_cat_code 		smCategoryCode, 	 	
	@new_is_new 		smLogical, 		 	 	
	@old_is_new 		smLogical, 		 		
	@new_emp_code 		smEmployeeCode, 	 	
	@old_emp_code 		smEmployeeCode, 	 	
	@new_loc_code 		smLocationCode, 	 	
	@old_loc_code 		smLocationCode, 		
	@new_type_code 		smAssetTypeCode, 		
	@old_type_code 		smAssetTypeCode, 		
	@new_status_code 	smStatusCode, 			
	@old_status_code 	smStatusCode, 			
	@new_state 			smSystemState, 			
	@old_state 			smSystemState, 			
	@new_bus_use 		smPercentage, 			
	@new_pers_use 		smPercentage, 			
	@new_inv_use 		smPercentage, 			
	@old_bus_use 		smPercentage, 			
	@old_pers_use 		smPercentage, 			
	@old_inv_use 		smPercentage, 			
	@new_cost 			smMoneyZero, 			
	@old_cost 			smMoneyZero, 			
	@old_quantity		smQuantity,				
	@new_quantity		smQuantity,				
	@acquisition_date	smISODate,				
	@new_acq_date 		smApplyDate, 			
	@old_acq_date 		smApplyDate,		 	
	@new_disp_date 		smApplyDate, 			
	@old_disp_date 		smApplyDate, 			
	@new_placed_date 	smApplyDate, 			
	@old_placed_date 	smApplyDate, 			
	@new_post_code 		smPostingCode, 	 	 	
	@old_post_code 		smPostingCode 	 		

SELECT 	@rowcount = @@rowcount, 
 		@rollback = 0 





 
IF UPDATE(company_id)
BEGIN 
	IF (SELECT COUNT(i.company_id) 
			FROM 	inserted 	i, 
					amco 		co	 
			WHERE	co.company_id = i.company_id) <> @rowcount 
	BEGIN 
		EXEC 		amGetErrorMessage_sp 20509, ".\\amasset.utr", 316, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20509 @message 
		SELECT 		@rollback = 1 
	END 
END 

IF @rollback = 1 
BEGIN



	ROLLBACK TRANSACTION 
	RETURN
END

 

EXEC amGetCompanyID_sp 
		@company_id OUT 

 
SELECT 	@co_asset_id 	= MIN(co_asset_id)
FROM 	inserted 

WHILE @co_asset_id IS NOT NULL 
BEGIN 



 
	 
	SELECT 	@asset_ctrl_num 	= asset_ctrl_num,
			@new_is_new 		= is_new,
			@new_cost 			= original_cost,
			@new_acq_date 		= acquisition_date,
			@new_placed_date 	= placed_in_service_date,
			@new_disp_date 		= disposition_date,
			@new_cat_code 		= category_code,
			@new_status_code 	= status_code,
			@new_type_code 		= asset_type_code,
			@new_emp_code 		= employee_code,
			@new_loc_code 		= location_code,
			@new_bus_use 		= business_usage,
			@new_pers_use 		= personal_usage,
			@new_inv_use 		= investment_usage,
			@new_state 			= activity_state,
			@new_quantity		= orig_quantity,
			@acct_ref_code 		= account_reference_code,
			@user_id 			= modified_by,
			@is_imported		= is_imported 
	FROM	inserted 
	WHERE	co_asset_id 		= @co_asset_id 
	
	 
	SELECT 
			@old_is_new 		= is_new,
			@old_cost 			= original_cost,
			@old_acq_date 		= acquisition_date,
			@old_placed_date 	= placed_in_service_date,
			@old_disp_date 		= disposition_date,
			@old_cat_code 		= category_code,
			@old_status_code 	= status_code,
			@old_type_code 		= asset_type_code,
			@old_emp_code 		= employee_code,
			@old_loc_code 		= location_code,
			@old_bus_use 		= business_usage,
			@old_pers_use 		= personal_usage,
			@old_inv_use 		= investment_usage,
			@old_state 			= activity_state, 
			@old_quantity		= orig_quantity
	FROM	deleted 
	WHERE	co_asset_id 		= @co_asset_id 
	
		
	 
	IF 	UPDATE(category_code)
	AND	@new_cat_code <> @old_cat_code
	BEGIN
		IF NOT EXISTS (SELECT 	category_code 
						FROM 	amcat 
						WHERE 	category_code = @new_cat_code) 
		BEGIN 

			EXEC	 	amGetErrorMessage_sp 20511, ".\\amasset.utr", 409, @new_cat_code, @asset_ctrl_num, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	20511 @message 
			SELECT 		@rollback = 1 			 
		END
	END

	 
	IF 	UPDATE(status_code)
	AND	( LTRIM(@new_status_code) IS NOT NULL AND LTRIM(@new_status_code) != " " )
	AND	@new_status_code <> @old_status_code
	BEGIN
		IF NOT EXISTS (SELECT 	status_code 
						FROM 	amstatus 
						WHERE 	status_code = @new_status_code) 
		BEGIN 
			EXEC 		amGetErrorMessage_sp 20503, ".\\amasset.utr", 426, @new_status_code, @asset_ctrl_num, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	20503 @message 
			SELECT 		@rollback = 1 
		END 
	END
	 
	IF 	UPDATE(asset_type_code)
	AND	@new_type_code IS NOT NULL
	AND	@new_type_code <> @old_type_code
	BEGIN
		IF NOT EXISTS (SELECT 	asset_type_code 
						FROM 	amasttyp 
						WHERE 	asset_type_code = @new_type_code) 
		BEGIN 
			EXEC	 	amGetErrorMessage_sp 20513, ".\\amasset.utr", 442, @new_type_code, @asset_ctrl_num, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	20513 @message 
			SELECT 		@rollback = 1 
		END 
	END

	 
	IF 	UPDATE(employee_code)
	AND	@new_emp_code 	IS NOT NULL
	AND	@new_emp_code	<> @old_emp_code
	BEGIN
		IF NOT EXISTS (SELECT 	employee_code 
						FROM 	amemp 
						WHERE 	employee_code = @new_emp_code) 
		BEGIN 
			EXEC 		amGetErrorMessage_sp 20507, ".\\amasset.utr", 459, @new_emp_code, @asset_ctrl_num, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	20507 @message 
			SELECT 		@rollback = 1 
		END 
	END

	 
	IF 	UPDATE(location_code)
	AND	@new_loc_code 	IS NOT NULL
	AND	@new_loc_code	<> @old_loc_code
	BEGIN
		IF NOT EXISTS (SELECT 	location_code 
						FROM 	amloc 
						WHERE 	location_code = @new_loc_code) 
		BEGIN 
			EXEC	 	amGetErrorMessage_sp 20505, ".\\amasset.utr", 476, @new_loc_code, @asset_ctrl_num, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	20505 @message 
			SELECT 		@rollback = 1
		END 
	END 

	 
	IF 	UPDATE(account_reference_code)
 AND ( LTRIM(@acct_ref_code) IS NOT NULL AND LTRIM(@acct_ref_code) != " " )
	BEGIN
		IF NOT EXISTS (SELECT 	reference_code 
						FROM 	glref 
						WHERE 	reference_code 	= @acct_ref_code
						AND		status_flag		= 0) 
		BEGIN 
			EXEC	 	amGetErrorMessage_sp 20501, ".\\amasset.utr", 493, @acct_ref_code, @asset_ctrl_num, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	20501 @message 
			SELECT 		@rollback = 1 
		END 
	END

	IF 	@new_state = 1 
	BEGIN
		
		IF EXISTS (SELECT 	*
					FROM 	amastbk		ab,
						 	amasset		a,
						 	amvalues	v 
					WHERE	a.co_asset_id 		= @co_asset_id
					AND		a.co_asset_id 		= ab.co_asset_id
					AND		ab.co_asset_book_id = v.co_asset_book_id
					AND		v.trx_type 			= 50
					AND		v.posting_flag 		= 100 )
		BEGIN
			EXEC 		amGetErrorMessage_sp 20079, ".\\amasset.utr", 514, @asset_ctrl_num, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	20079 @message 
			ROLLBACK 	TRANSACTION
			RETURN 
		END

		IF 	@old_state = 1 
		AND	@old_disp_date <> @new_disp_date
		BEGIN
			
			UPDATE 	amacthst
			SET		apply_date 			= @new_disp_date
			FROM	amacthst 	ah,
					amastbk		ab
			WHERE	ab.co_asset_id 		= @co_asset_id
			AND		ab.co_asset_book_id = ah.co_asset_book_id
			AND		trx_type			= 30
		END
	END

	
	IF UPDATE (acquisition_date) 
	OR UPDATE (placed_in_service_date)
	BEGIN
		EXEC @ret_status = amValidateAssetDates_sp
								@co_asset_id,
								@asset_ctrl_num,
								@new_acq_date,
								@new_placed_date,
								@is_valid OUTPUT
		
		IF 	@ret_status <> 0 
		OR	@is_valid 	= 0
			SELECT @rollback = 1
	END
	
	 
	IF (ABS((@new_bus_use + @new_pers_use + @new_inv_use - 100.00)-(0.0)) > 0.0000001)  
	BEGIN 
		SELECT 		@param1 = RTRIM(CONVERT(char(255), @new_bus_use))
		SELECT 		@param2 = RTRIM(CONVERT(char(255), @new_pers_use))
		SELECT 		@param3 = RTRIM(CONVERT(char(255), @new_inv_use))
		EXEC	 	amGetErrorMessage_sp 20072, ".\\amasset.utr", 559, @param1, @param2, @param3, @asset_ctrl_num, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20072 @message 
		SELECT 		@rollback = 1 
	END 
	
	
	IF 	@old_cat_code IS NOT NULL
	AND	@old_cat_code <> @new_cat_code
	AND	@new_state NOT IN (100, 101)
	BEGIN



		
		SELECT	@acquisition_date = CONVERT(char(8), @new_acq_date, 112)
		
		EXEC @ret_status = amCheckNewCategory_sp
								@asset_ctrl_num,	
								@co_asset_id,
								@acquisition_date,
								@new_cat_code,
								@is_valid OUTPUT
	
		IF 	@ret_status <> 0 
		OR	@is_valid 	= 0
			SELECT @rollback = 1

	END

	 

	IF @rollback = 1 
	BEGIN 



		ROLLBACK TRANSACTION 
		RETURN 
	END 


	 
 	SELECT @modify_date = GETDATE() 

	EXEC @ret_status = amLogAssetChanges_sp 
							@co_asset_id,
							@modify_date,
							@user_id,
							@old_cat_code, 		@new_cat_code,
							@old_loc_code, 		@new_loc_code,
							@old_emp_code,		@new_emp_code,
							@old_type_code, 	@new_type_code,
							@old_status_code, 	@new_status_code,
							@old_state, 		@new_state,
							@old_bus_use, 		@new_bus_use,
							@old_pers_use, 		@new_pers_use,
							@old_inv_use, 		@new_inv_use,
							@old_quantity,		@new_quantity,
							@changed OUTPUT 
 
		
	IF @ret_status <> 0 
	BEGIN 



		ROLLBACK TRANSACTION 
		RETURN 
	END 

	 
	IF 	(	@new_state 		= 100
		AND @old_cat_code 	IS NOT NULL
		AND	@old_cat_code <> @new_cat_code)
	OR 	(	@old_acq_date IS NOT NULL
		AND @new_acq_date <> @old_acq_date)
	BEGIN






		 
		EXEC 	@ret_status = amChangeAssetBooks_sp 
								@co_asset_id, 
								@new_cat_code, 
								@old_acq_date,
								@new_acq_date, 
								@new_placed_date,
								@new_cost,
								@user_id,
								@new_state
		IF @ret_status <> 0 
		BEGIN 



			ROLLBACK TRANSACTION 
			RETURN 
		END 
		
		IF @old_acq_date <> @new_acq_date
		BEGIN
			
			UPDATE	amacthst
			SET		effective_date			= @new_acq_date
			FROM	inserted i,
					amastbk	ab,
					amacthst ah
			WHERE	i.co_asset_id			= ab.co_asset_id
			AND		ab.co_asset_book_id	 	= ah.co_asset_book_id
			AND		ah.effective_date	 	= @old_acq_date
			AND		ah.trx_type				!= 30
				
			SELECT @ret_status	= @@error
			IF	@ret_status <> 0
			BEGIN 
				ROLLBACK TRANSACTION 
				RETURN 
			END 

		END
	
		EXEC	 	amGetErrorMessage_sp 
						26004, ".\\amasset.utr", 714, 
						@asset_ctrl_num,
						@error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	26004 @message 
		

	END 

	IF 	@new_state 		!= 100
	AND	@old_cat_code <> @new_cat_code
	BEGIN 
		
		EXEC 	@ret_status = amChangeCategory_sp 
 						@co_asset_id,
								@new_acq_date,
								@new_cat_code,
								@user_id 							
		IF @ret_status <> 0 
		BEGIN 
			ROLLBACK TRANSACTION 
			RETURN 
		END 
		
		EXEC	 	amGetErrorMessage_sp 
						26004, ".\\amasset.utr", 741, 
						@asset_ctrl_num,
						@error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	26004 @message 
		

	END 
		
	
	IF 	@new_state = 100
	AND @old_is_new <> @new_is_new 
	BEGIN 
		
		EXEC 	@ret_status = amChangeAssetSource_sp 
 						@co_asset_id,	
								@old_is_new,		
								@new_is_new 	
							
		IF @ret_status <> 0 
		BEGIN 
			ROLLBACK TRANSACTION 
			RETURN 
		END 
	END 

	IF (ABS((@old_cost - @new_cost)-(0.0)) > 0.0000001) 
	BEGIN 




		UPDATE 	amastbk 
		SET 	orig_amount_capitalised = @new_cost 
		WHERE 	co_asset_id 			= @co_asset_id 
	
		IF @@error <> 0 
		BEGIN 



			ROLLBACK TRANSACTION 
			RETURN 
		END 
	END 

	
	IF @old_cat_code <> @new_cat_code
	BEGIN
		SELECT 	@old_post_code	= posting_code
		FROM	amcat 
		WHERE	category_code	= @old_cat_code
		
		SELECT 	@new_post_code	= posting_code
		FROM	amcat 
		WHERE	category_code	= @new_cat_code
		
		IF @old_post_code <> @new_post_code
		BEGIN
			UPDATE 	amastact
			SET		up_to_date				= 0,
					last_modified_date		= GETDATE()
			FROM	amastact aa
			WHERE	aa.co_asset_id			= @co_asset_id

			SELECT @ret_status = @@error
			IF @ret_status <> 0
			BEGIN
				ROLLBACK TRANSACTION
				RETURN
			END
		END
	END
	
	IF (@old_type_code IS NOT NULL AND @new_type_code IS NULL)
	OR (@old_type_code IS NULL AND @new_type_code IS NOT NULL)
	OR (@old_type_code IS NOT NULL AND @new_type_code IS NOT NULL AND @old_type_code <> @new_type_code)
	BEGIN
		UPDATE 	amastact
		SET		up_to_date				= 0,
				last_modified_date		= GETDATE()
		FROM	amastact aa
		WHERE	aa.co_asset_id			= @co_asset_id
		AND		aa.account_type_id 		IN (0, 1, 5)

		SELECT @ret_status = @@error
		IF @ret_status <> 0
		BEGIN
			ROLLBACK TRANSACTION
			RETURN
		END

	END
		
	 
	SELECT 	@co_asset_id 	= MIN(co_asset_id)
	FROM 	inserted 
	WHERE 	co_asset_id 	> @co_asset_id 
END 





GO
CREATE UNIQUE CLUSTERED INDEX [amasset_ind_0] ON [dbo].[amasset] ([asset_ctrl_num], [company_id]) WITH (FILLFACTOR=70) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [amasset_ind_10] ON [dbo].[amasset] ([asset_type_code], [co_asset_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [amasset_ind_3] ON [dbo].[amasset] ([category_code], [co_asset_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [amasset_ind_1] ON [dbo].[amasset] ([co_asset_id], [activity_state], [acquisition_date]) WITH (FILLFACTOR=80) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [amasset_ind_5] ON [dbo].[amasset] ([company_id], [asset_ctrl_num]) WITH (FILLFACTOR=70) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [amasset_ind_8] ON [dbo].[amasset] ([employee_code]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [amasset_ind_7] ON [dbo].[amasset] ([location_code]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [amasset_ind_2] ON [dbo].[amasset] ([parent_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [amasset_ind_4] ON [dbo].[amasset] ([placed_in_service_date]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [amasset_ind_6] ON [dbo].[amasset] ([status_code]) WITH (FILLFACTOR=80) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[smSystemState_rl]', N'[dbo].[amasset].[activity_state]'
GO
EXEC sp_bindefault N'[dbo].[smSystemState_df]', N'[dbo].[amasset].[activity_state]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amasset].[co_asset_id]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amasset].[co_trx_id]'
GO
EXEC sp_bindefault N'[dbo].[smPostingState_df]', N'[dbo].[amasset].[posting_flag]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amasset].[asset_description]'
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[amasset].[is_new]'
GO
EXEC sp_bindefault N'[dbo].[smTrue_df]', N'[dbo].[amasset].[is_new]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amasset].[original_cost]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amasset].[service_units]'
GO
EXEC sp_bindefault N'[dbo].[smQuantity_df]', N'[dbo].[amasset].[orig_quantity]'
GO
EXEC sp_bindefault N'[dbo].[smQuantity_df]', N'[dbo].[amasset].[rem_quantity]'
GO
EXEC sp_bindefault N'[dbo].[smPercentage_df]', N'[dbo].[amasset].[business_usage]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amasset].[personal_usage]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amasset].[investment_usage]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amasset].[account_reference_code]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amasset].[tag]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amasset].[note_id]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amasset].[user_field_id]'
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[amasset].[is_pledged]'
GO
EXEC sp_bindefault N'[dbo].[smFalse_df]', N'[dbo].[amasset].[is_pledged]'
GO
EXEC sp_bindrule N'[dbo].[smLeaseType_rl]', N'[dbo].[amasset].[lease_type]'
GO
EXEC sp_bindefault N'[dbo].[smLeaseType_df]', N'[dbo].[amasset].[lease_type]'
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[amasset].[is_property]'
GO
EXEC sp_bindefault N'[dbo].[smFalse_df]', N'[dbo].[amasset].[is_property]'
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[amasset].[depr_overridden]'
GO
EXEC sp_bindefault N'[dbo].[smFalse_df]', N'[dbo].[amasset].[depr_overridden]'
GO
EXEC sp_bindrule N'[dbo].[smLinkType_rl]', N'[dbo].[amasset].[linked]'
GO
EXEC sp_bindefault N'[dbo].[smLinkType_df]', N'[dbo].[amasset].[linked]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amasset].[parent_id]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amasset].[num_children]'
GO
EXEC sp_bindefault N'[dbo].[smTodaysDate_df]', N'[dbo].[amasset].[last_modified_date]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amasset].[modified_by]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amasset].[policy_number]'
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[amasset].[depreciated]'
GO
EXEC sp_bindefault N'[dbo].[smFalse_df]', N'[dbo].[amasset].[depreciated]'
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[amasset].[is_imported]'
GO
EXEC sp_bindefault N'[dbo].[smFalse_df]', N'[dbo].[amasset].[is_imported]'
GO
GRANT REFERENCES ON  [dbo].[amasset] TO [public]
GO
GRANT SELECT ON  [dbo].[amasset] TO [public]
GO
GRANT INSERT ON  [dbo].[amasset] TO [public]
GO
GRANT DELETE ON  [dbo].[amasset] TO [public]
GO
GRANT UPDATE ON  [dbo].[amasset] TO [public]
GO
