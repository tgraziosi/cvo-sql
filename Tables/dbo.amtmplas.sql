CREATE TABLE [dbo].[amtmplas]
(
[timestamp] [timestamp] NOT NULL,
[company_id] [dbo].[smCompanyID] NOT NULL,
[template_code] [dbo].[smTemplateCode] NOT NULL,
[template_description] [dbo].[smStdDescription] NOT NULL,
[is_new] [dbo].[smLogicalTrue] NOT NULL,
[original_cost] [dbo].[smMoneyZero] NOT NULL,
[acquisition_date] [dbo].[smApplyDate] NULL,
[placed_in_service_date] [dbo].[smApplyDate] NULL,
[original_in_service_date] [dbo].[smApplyDate] NULL,
[orig_quantity] [dbo].[smQuantity] NOT NULL,
[category_code] [dbo].[smCategoryCode] NULL,
[status_code] [dbo].[smStatusCode] NULL,
[asset_type_code] [dbo].[smAssetTypeCode] NULL,
[employee_code] [dbo].[smEmployeeCode] NULL,
[location_code] [dbo].[smLocationCode] NULL,
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
[linked] [dbo].[smLinkType] NOT NULL,
[parent_id] [dbo].[smSurrogateKey] NOT NULL,
[policy_number] [dbo].[smPolicyNumber] NOT NULL,
[last_modified_date] [dbo].[smApplyDate] NOT NULL,
[modified_by] [dbo].[smUserID] NOT NULL,
[org_id] [dbo].[smOrgId] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER 	[dbo].[amtmplas_del_trg] 
ON 				[dbo].[amtmplas] 
FOR DELETE 
AS 

DECLARE 
 	@result				smErrorCode 





DELETE 	amtmplcl
FROM	amtmplcl,
		deleted
WHERE	deleted.template_code = amtmplcl.template_code

SELECT	@result = @@error
IF	@result <> 0
BEGIN
		ROLLBACK TRANSACTION 
		RETURN 
END





GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER 	[dbo].[amtmplas_ins_trg] 
ON 				[dbo].[amtmplas] 
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
	@template_code		smTemplateCode,			
	@bus_use 			smPercentage, 			
	@pers_use 			smPercentage, 			
	@inv_use 			smPercentage, 			
	@category_code 		smCategoryCode,			 
 	@acct_ref_code 		smAccountReferenceCode, 
 	@company_id 		smCompanyID,			
 @location_code		smLocationCode,			
 @employee_code		smEmployeeCode,			
 @asset_type_code	smAssetTypeCode,		
	@status_code		smStatusCode			

SELECT 	@rowcount 	= @@rowcount 
SELECT 	@rollback 	= 0





 
IF ( SELECT COUNT(i.company_id) 
		FROM 	inserted 	i, 
				amco 		co 
		WHERE 	co.company_id = i.company_id) <> @rowcount 
BEGIN 
	EXEC 		amGetErrorMessage_sp 20255, ".\\amtmplas.itr", 105, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20255 @message 
	SELECT 		@rollback = 1 
END 

 
IF @rollback = 1 
BEGIN 
	ROLLBACK TRANSACTION 
	RETURN 
END 

 		 

EXEC amGetCompanyID_sp 
			@company_id OUT 

SELECT 	@template_code 	= MIN(template_code)
FROM 	inserted 
WHERE 	company_id 		= @company_id 

WHILE @template_code IS NOT NULL 
BEGIN 



	 
	SELECT 
			@category_code 		= category_code,
			@acct_ref_code 		= account_reference_code,
			@bus_use 			= business_usage,
			@pers_use 			= personal_usage,
			@inv_use 	 		= investment_usage,
			@location_code		= location_code,
			@employee_code		= employee_code,
			@asset_type_code 	= asset_type_code,
			@status_code		= status_code
	FROM 	inserted 
	WHERE 	inserted.template_code 	= @template_code 
	AND 	inserted.company_id 	= @company_id 
	
	 
	IF @category_code IS NOT NULL
	BEGIN
		IF NOT EXISTS (SELECT 	category_code 
						FROM 	amcat 
						WHERE 	category_code = @category_code) 
		BEGIN 

			EXEC	 	amGetErrorMessage_sp 20256, ".\\amtmplas.itr", 160, @template_code, @category_code, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	20256 @message 
			SELECT 		@rollback = 1 			 
		END 
	END

	 
	IF @status_code IS NOT NULL
	BEGIN
		IF NOT EXISTS (SELECT 	status_code 
						FROM 	amstatus 
						WHERE 	status_code = @status_code) 
		BEGIN 
			EXEC 		amGetErrorMessage_sp 20252, ".\\amtmplas.itr", 175, @template_code, @status_code, @error_message = @message OUT 
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
			EXEC	 	amGetErrorMessage_sp 20257, ".\\amtmplas.itr", 190, @template_code, @asset_type_code, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	20257 @message 
			SELECT 		@rollback = 1 
		END 
	END

	 
	IF @employee_code IS NOT NULL
	BEGIN
		IF NOT EXISTS (SELECT 	employee_code 
						FROM 	amemp 
						WHERE 	employee_code = @employee_code) 
		BEGIN 
			EXEC 		amGetErrorMessage_sp 20254, ".\\amtmplas.itr", 205, @template_code, @employee_code, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	20254 @message 
			SELECT 		@rollback = 1 
		END 
	END

	 
	IF @location_code IS NOT NULL
	BEGIN
		IF NOT EXISTS (SELECT 	location_code 
						FROM 	amloc 
						WHERE 	location_code = @location_code) 
		BEGIN 
			EXEC	 	amGetErrorMessage_sp 20253, ".\\amtmplas.itr", 220, @template_code, @location_code, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	20253 @message 
			SELECT 		@rollback = 1
		END 
	END 

	 
	IF ( LTRIM(@acct_ref_code) IS NOT NULL AND LTRIM(@acct_ref_code) != " " )
	BEGIN
		IF NOT EXISTS (SELECT 	reference_code 
						FROM 	glref 
						WHERE 	reference_code = @acct_ref_code) 
		BEGIN 
			EXEC	 	amGetErrorMessage_sp 20251, ".\\amtmplas.itr", 236, @template_code, @acct_ref_code, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	20251 @message 
			SELECT 		@rollback = 1 
		END 
	END

	 
	IF (ABS(100.00 - ( @bus_use + @pers_use + @inv_use)) > 0.00001)  
	BEGIN 
		SELECT @param1 = RTRIM(CONVERT(char(255), @bus_use))
		SELECT @param2 = RTRIM(CONVERT(char(255), @pers_use))
		SELECT @param3 = RTRIM(CONVERT(char(255), @inv_use))

		EXEC	 	amGetErrorMessage_sp 20250, ".\\amtmplas.itr", 251, @template_code, @param1, @param2, @param3, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20250 @message 
		SELECT 		@rollback = 1 
	END 
	
	
	
	IF @rollback = 1 
	BEGIN 



		ROLLBACK TRANSACTION 
		RETURN 
	END 

	



	 
	SELECT 	@template_code 	= MIN(template_code)
	FROM 	inserted 
	WHERE 	template_code 	> @template_code 
	AND 	company_id 		= @company_id 

END 





GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER 	[dbo].[amtmplas_upd_trg] 
ON 				[dbo].[amtmplas] 
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
 	@company_id 		smCompanyID, 			
 	@template_code	 	smTemplateCode,			
 	@acct_ref_code 		smAccountReferenceCode, 
	@cat_code 			smCategoryCode, 	 	
	@emp_code 			smEmployeeCode, 	 	
	@loc_code 			smLocationCode, 	 	
	@type_code 			smAssetTypeCode, 		
	@status_code 		smStatusCode, 			
	@bus_use 			smPercentage, 			
	@pers_use 			smPercentage, 			
	@inv_use 			smPercentage 			

SELECT 	@rowcount = @@rowcount, 
 		@rollback = 0 





EXEC amGetCompanyID_sp 
		@company_id OUT 

 
SELECT 	@template_code 	= MIN(template_code)
FROM 	inserted 
WHERE	company_id		= @company_id

 
WHILE @template_code IS NOT NULL 
BEGIN 



 
	 
	SELECT 	@cat_code 		= category_code,
			@status_code 	= status_code,
			@type_code 		= asset_type_code,
			@emp_code 		= employee_code,
			@loc_code 		= location_code,
			@bus_use 		= business_usage,
			@pers_use 		= personal_usage,
			@inv_use 		= investment_usage,
			@acct_ref_code 	= account_reference_code
	FROM	inserted 
	WHERE	template_code 	= @template_code 
		
	 
	IF 	UPDATE(category_code)
	AND	@cat_code IS NOT NULL
	BEGIN
		IF NOT EXISTS (SELECT 	category_code 
						FROM 	amcat 
						WHERE 	category_code = @cat_code) 
		BEGIN 

			EXEC	 	amGetErrorMessage_sp 20256, ".\\amtmplas.utr", 140, @template_code, @cat_code, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	20256 @message 
			SELECT 		@rollback = 1 			 
		END
	END

	 
	IF 	UPDATE(status_code)
	AND	@status_code IS NOT NULL
	BEGIN
		IF NOT EXISTS (SELECT 	status_code 
						FROM 	amstatus 
						WHERE 	status_code = @status_code) 
		BEGIN 
			EXEC 		amGetErrorMessage_sp 20252, ".\\amtmplas.utr", 156, @template_code, @status_code, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	20252 @message 
			SELECT 		@rollback = 1 
		END 
	END
	 
	IF 	UPDATE(asset_type_code)
	AND	@type_code IS NOT NULL
	BEGIN
		IF NOT EXISTS (SELECT 	asset_type_code 
						FROM 	amasttyp 
						WHERE 	asset_type_code = @type_code) 
		BEGIN 
			EXEC	 	amGetErrorMessage_sp 20257, ".\\amtmplas.utr", 171, @template_code, @type_code, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	20257 @message 
			SELECT 		@rollback = 1 
		END 
	END

	 
	IF 	UPDATE(employee_code)
	AND	@emp_code 	IS NOT NULL
	BEGIN
		IF NOT EXISTS (SELECT 	employee_code 
						FROM 	amemp 
						WHERE 	employee_code = @emp_code) 
		BEGIN 
			EXEC 		amGetErrorMessage_sp 20254, ".\\amtmplas.utr", 187, @template_code, @emp_code, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	20254 @message 
			SELECT 		@rollback = 1 
		END 
	END

	 
	IF 	UPDATE(location_code)
	AND	@loc_code 	IS NOT NULL
	BEGIN
		IF NOT EXISTS (SELECT 	location_code 
						FROM 	amloc 
						WHERE 	location_code = @loc_code) 
		BEGIN 
			EXEC	 	amGetErrorMessage_sp 20253, ".\\amtmplas.utr", 203, @template_code, @loc_code, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	20253 @message 
			SELECT 		@rollback = 1
		END 
	END 

	 
	IF 	UPDATE(account_reference_code)
	AND	( LTRIM(@acct_ref_code) IS NOT NULL AND LTRIM(@acct_ref_code) != " " )
	BEGIN
		IF NOT EXISTS (SELECT 	reference_code 
						FROM 	glref 
						WHERE 	reference_code = @acct_ref_code) 
		BEGIN 
			EXEC	 	amGetErrorMessage_sp 20251, ".\\amtmplas.utr", 219, @template_code, @acct_ref_code, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	20251 @message 
			SELECT 		@rollback = 1 
		END 
	END

	 
	IF (ABS(100.00 - ( @bus_use + @pers_use + @inv_use)) > 0.00001)  
	BEGIN 
		SELECT 		@param1 = RTRIM(CONVERT(char(255), @bus_use))
		SELECT 		@param2 = RTRIM(CONVERT(char(255), @pers_use))
		SELECT 		@param3 = RTRIM(CONVERT(char(255), @inv_use))
		EXEC	 	amGetErrorMessage_sp 20250, ".\\amtmplas.utr", 233, @template_code, @param1, @param2, @param3, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20250 @message 
		SELECT 		@rollback = 1 
	END 
	

	 

	IF @rollback = 1 
	BEGIN 



		ROLLBACK TRANSACTION 
		RETURN 
	END 


	 
	SELECT 	@template_code 	= MIN(template_code)
	FROM 	inserted 
	WHERE 	template_code 	> @template_code 
	AND		company_id		= @company_id
END 





GO
CREATE UNIQUE CLUSTERED INDEX [amtmplas_ind_0] ON [dbo].[amtmplas] ([company_id], [template_code]) WITH (FILLFACTOR=70) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amtmplas].[template_description]'
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[amtmplas].[is_new]'
GO
EXEC sp_bindefault N'[dbo].[smTrue_df]', N'[dbo].[amtmplas].[is_new]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amtmplas].[original_cost]'
GO
EXEC sp_bindefault N'[dbo].[smQuantity_df]', N'[dbo].[amtmplas].[orig_quantity]'
GO
EXEC sp_bindefault N'[dbo].[smPercentage_df]', N'[dbo].[amtmplas].[business_usage]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amtmplas].[personal_usage]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amtmplas].[investment_usage]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amtmplas].[account_reference_code]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amtmplas].[tag]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amtmplas].[note_id]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amtmplas].[user_field_id]'
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[amtmplas].[is_pledged]'
GO
EXEC sp_bindefault N'[dbo].[smFalse_df]', N'[dbo].[amtmplas].[is_pledged]'
GO
EXEC sp_bindrule N'[dbo].[smLeaseType_rl]', N'[dbo].[amtmplas].[lease_type]'
GO
EXEC sp_bindefault N'[dbo].[smLeaseType_df]', N'[dbo].[amtmplas].[lease_type]'
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[amtmplas].[is_property]'
GO
EXEC sp_bindefault N'[dbo].[smFalse_df]', N'[dbo].[amtmplas].[is_property]'
GO
EXEC sp_bindrule N'[dbo].[smLinkType_rl]', N'[dbo].[amtmplas].[linked]'
GO
EXEC sp_bindefault N'[dbo].[smLinkType_df]', N'[dbo].[amtmplas].[linked]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amtmplas].[parent_id]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amtmplas].[policy_number]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amtmplas].[modified_by]'
GO
GRANT REFERENCES ON  [dbo].[amtmplas] TO [public]
GO
GRANT SELECT ON  [dbo].[amtmplas] TO [public]
GO
GRANT INSERT ON  [dbo].[amtmplas] TO [public]
GO
GRANT DELETE ON  [dbo].[amtmplas] TO [public]
GO
GRANT UPDATE ON  [dbo].[amtmplas] TO [public]
GO
