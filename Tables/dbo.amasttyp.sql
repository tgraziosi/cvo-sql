CREATE TABLE [dbo].[amasttyp]
(
[timestamp] [timestamp] NOT NULL,
[asset_type_code] [dbo].[smAssetTypeCode] NOT NULL,
[asset_type_description] [dbo].[smStdDescription] NOT NULL,
[asset_gl_override] [dbo].[smAccountOverride] NULL,
[accum_depr_gl_override] [dbo].[smAccountOverride] NULL,
[depr_exp_gl_override] [dbo].[smAccountOverride] NULL,
[last_modified_date] [dbo].[smApplyDate] NOT NULL,
[modified_by] [dbo].[smUserID] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER 	[dbo].[amasttyp_del_trg] 
ON 				[dbo].[amasttyp] 
FOR	 			DELETE 
AS 

DECLARE 
	@rollback 			smLogical, 
	@message 	 		smErrorLongDesc, 
	@asset_type_code 	smAssetTypeCode, 
	@asset_ctrl_num		smControlNumber,
	@template_code		smTemplateCode 

SELECT @rollback 	= 0 

SELECT	@asset_type_code = MIN(asset_type_code)
FROM	deleted

WHILE @asset_type_code IS NOT NULL
BEGIN
	SELECT	@asset_ctrl_num = NULL,
			@template_code 	= NULL
	
	SELECT	@asset_ctrl_num = MIN(asset_ctrl_num)
	FROM	amasset
	WHERE	asset_type_code	= @asset_type_code
	
	IF @asset_ctrl_num IS NOT NULL 
	BEGIN 
		EXEC 		amGetErrorMessage_sp 20525, ".\\amasttyp.dtr", 98, @asset_type_code, @asset_ctrl_num, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20525 @message 
		SELECT 		@rollback = 1 
	END 

	IF @rollback = 0
	BEGIN
		SELECT	@template_code 	= MIN(template_code)
		FROM	amtmplas
		WHERE	asset_type_code	= @asset_type_code
		
		IF @template_code IS NOT NULL 
		BEGIN 
			EXEC 		amGetErrorMessage_sp 20563, ".\\amasttyp.dtr", 111, @asset_type_code, @template_code, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	20563 @message 
			SELECT 		@rollback = 1 
		END 
	END

	
	SELECT	@asset_type_code 	= MIN(asset_type_code)
	FROM	deleted
	WHERE	asset_type_code		> @asset_type_code

END

IF @rollback <> 0 
	ROLLBACK TRANSACTION 
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER 	[dbo].[amasttyp_ins_trg] 
ON 				[dbo].[amasttyp] 
FOR 			INSERT 
AS 

DECLARE 
	@rowcount 					smCounter, 
	@rollback 					smLogical, 
	@message 					smErrorLongDesc,
	@keycount 					smCounter, 
	@asset_type_code			smAssetTypeCode, 
	@valid_count				smCounter, 
 @natural_acct				smAcctLevel,
	@asset_override_count		smCounter,
	@accum_override_count		smCounter,
	@depr_override_count		smCounter,
	@asset_invalid_override		smAccountOverride,
	@accum_invalid_override		smAccountOverride,
	@depr_invalid_override		smAccountOverride,
	@asset_is_valid				smLogical,
	@accum_is_valid				smLogical,
	@depr_is_valid				smLogical


SELECT @rowcount = @@rowcount 
SELECT @rollback = 0 


SELECT	@asset_override_count 	= COUNT(DISTINCT asset_gl_override)
FROM	inserted
WHERE	asset_gl_override		IS NOT NULL
	
SELECT	@accum_override_count 	= COUNT(DISTINCT accum_depr_gl_override)
FROM	inserted
WHERE	accum_depr_gl_override	IS NOT NULL
	
SELECT	@depr_override_count 	= COUNT(DISTINCT depr_exp_gl_override)
FROM	inserted
WHERE	depr_exp_gl_override	IS NOT NULL
	

IF @rowcount = 1
	SELECT 	@asset_invalid_override = ISNULL(asset_gl_override, ""),
			@accum_invalid_override = ISNULL(accum_depr_gl_override, ""),
			@depr_invalid_override 	= ISNULL(depr_exp_gl_override, "")
	FROM	inserted 	


SELECT 	@natural_acct		= acct_level
FROM	glaccdef
WHERE	natural_acct_flag	= 1

SELECT 	@asset_is_valid	= 1,
		@accum_is_valid	= 1,
		@depr_is_valid	= 1

IF @natural_acct = 1
BEGIN
	
	SELECT 	@valid_count 			= COUNT(DISTINCT i.asset_gl_override)
	FROM	glseg1 		glseg,
			inserted 	i
	WHERE 	i.asset_gl_override 	= glseg.seg_code 
	AND		i.asset_gl_override		IS NOT NULL

	IF @asset_override_count <> @valid_count
	BEGIN
		SELECT @asset_is_valid = 0
		
		IF @rowcount > 1
			SELECT 	@asset_invalid_override = MIN(asset_gl_override)
			FROM	inserted 	
			WHERE 	asset_gl_override		IS NOT NULL
			AND		asset_gl_override 		NOT IN (SELECT 	seg_code
													FROM 	glseg1)
	END

	
	SELECT 	@valid_count 				= COUNT(DISTINCT i.accum_depr_gl_override)
	FROM	glseg1 		glseg,
			inserted 	i
	WHERE 	i.accum_depr_gl_override 	= glseg.seg_code 
	AND		i.accum_depr_gl_override	IS NOT NULL

	IF @accum_override_count <> @valid_count
	BEGIN
		SELECT @accum_is_valid = 0
		
		IF @rowcount > 1
			SELECT 	@accum_invalid_override	= MIN(accum_depr_gl_override)
			FROM	inserted 	
			WHERE 	accum_depr_gl_override	IS NOT NULL
			AND		accum_depr_gl_override 	NOT IN (SELECT 	seg_code
													FROM 	glseg1)
	END

	
	SELECT 	@valid_count 			= COUNT(DISTINCT i.depr_exp_gl_override)
	FROM	glseg1 		glseg,
			inserted 	i
	WHERE 	i.depr_exp_gl_override 	= glseg.seg_code 
	AND		i.depr_exp_gl_override		IS NOT NULL

	IF @depr_override_count <> @valid_count
	BEGIN
		SELECT @depr_is_valid = 0
		
		IF @rowcount > 1
			SELECT 	@depr_invalid_override 	= MIN(depr_exp_gl_override)
			FROM	inserted 	
			WHERE 	depr_exp_gl_override	IS NOT NULL
			AND		depr_exp_gl_override 	NOT IN (SELECT 	seg_code
													FROM 	glseg1)
	END
END
ELSE IF @natural_acct = 2
BEGIN
	
	SELECT 	@valid_count 			= COUNT(DISTINCT i.asset_gl_override)
	FROM	glseg2 		glseg,
			inserted 	i
	WHERE 	i.asset_gl_override 	= glseg.seg_code 
	AND		i.asset_gl_override		IS NOT NULL

	IF @asset_override_count <> @valid_count
	BEGIN
		SELECT @asset_is_valid = 0
		
		IF @rowcount > 1
			SELECT 	@asset_invalid_override = MIN(asset_gl_override)
			FROM	inserted 	
			WHERE 	asset_gl_override		IS NOT NULL
			AND		asset_gl_override 		NOT IN (SELECT 	seg_code
													FROM 	glseg2)
	END

	
	SELECT 	@valid_count 				= COUNT(DISTINCT i.accum_depr_gl_override)
	FROM	glseg2 		glseg,
			inserted 	i
	WHERE 	i.accum_depr_gl_override 	= glseg.seg_code 
	AND		i.accum_depr_gl_override	IS NOT NULL

	IF @accum_override_count <> @valid_count
	BEGIN
		SELECT @accum_is_valid = 0
		
		IF @rowcount > 1
			SELECT 	@accum_invalid_override	= MIN(accum_depr_gl_override)
			FROM	inserted 	
			WHERE 	accum_depr_gl_override	IS NOT NULL
			AND		accum_depr_gl_override 	NOT IN (SELECT 	seg_code
													FROM 	glseg2)
	END

	
	SELECT 	@valid_count 			= COUNT(DISTINCT i.depr_exp_gl_override)
	FROM	glseg2 		glseg,
			inserted 	i
	WHERE 	i.depr_exp_gl_override 	= glseg.seg_code 
	AND		i.depr_exp_gl_override		IS NOT NULL

	IF @depr_override_count <> @valid_count
	BEGIN
		SELECT @depr_is_valid = 0
		
		IF @rowcount > 1
			SELECT 	@depr_invalid_override 	= MIN(depr_exp_gl_override)
			FROM	inserted 	
			WHERE 	depr_exp_gl_override	IS NOT NULL
			AND		depr_exp_gl_override 	NOT IN (SELECT 	seg_code
													FROM 	glseg2)
	END
END
ELSE IF @natural_acct = 3
BEGIN
	
	SELECT 	@valid_count 			= COUNT(DISTINCT i.asset_gl_override)
	FROM	glseg3 		glseg,
			inserted 	i
	WHERE 	i.asset_gl_override 	= glseg.seg_code 
	AND		i.asset_gl_override		IS NOT NULL

	IF @asset_override_count <> @valid_count
	BEGIN
		SELECT @asset_is_valid = 0
		
		IF @rowcount > 1
			SELECT 	@asset_invalid_override = MIN(asset_gl_override)
			FROM	inserted 	
			WHERE 	asset_gl_override		IS NOT NULL
			AND		asset_gl_override 		NOT IN (SELECT 	seg_code
													FROM 	glseg3)
	END

	
	SELECT 	@valid_count 				= COUNT(DISTINCT i.accum_depr_gl_override)
	FROM	glseg3 		glseg,
			inserted 	i
	WHERE 	i.accum_depr_gl_override 	= glseg.seg_code 
	AND		i.accum_depr_gl_override	IS NOT NULL

	IF @accum_override_count <> @valid_count
	BEGIN
		SELECT @accum_is_valid = 0
		
		IF @rowcount > 1
			SELECT 	@accum_invalid_override	= MIN(accum_depr_gl_override)
			FROM	inserted 	
			WHERE 	accum_depr_gl_override	IS NOT NULL
			AND		accum_depr_gl_override 	NOT IN (SELECT 	seg_code
													FROM 	glseg3)
	END

	
	SELECT 	@valid_count 			= COUNT(DISTINCT i.depr_exp_gl_override)
	FROM	glseg3 		glseg,
			inserted 	i
	WHERE 	i.depr_exp_gl_override 	= glseg.seg_code 
	AND		i.depr_exp_gl_override		IS NOT NULL

	IF @depr_override_count <> @valid_count
	BEGIN
		SELECT @depr_is_valid = 0
		
		IF @rowcount > 1
			SELECT 	@depr_invalid_override 	= MIN(depr_exp_gl_override)
			FROM	inserted 	
			WHERE 	depr_exp_gl_override	IS NOT NULL
			AND		depr_exp_gl_override 	NOT IN (SELECT 	seg_code
													FROM 	glseg3)
	END
END
ELSE 
BEGIN
	
	SELECT 	@valid_count 			= COUNT(DISTINCT i.asset_gl_override)
	FROM	glseg4 		glseg,
			inserted 	i
	WHERE 	i.asset_gl_override 	= glseg.seg_code 
	AND		i.asset_gl_override		IS NOT NULL

	IF @asset_override_count <> @valid_count
	BEGIN
		SELECT @asset_is_valid = 0
		
		IF @rowcount > 1
			SELECT 	@asset_invalid_override = MIN(asset_gl_override)
			FROM	inserted 	
			WHERE 	asset_gl_override		IS NOT NULL
			AND		asset_gl_override 		NOT IN (SELECT 	seg_code
													FROM 	glseg4)
	END

	
	SELECT 	@valid_count 				= COUNT(DISTINCT i.accum_depr_gl_override)
	FROM	glseg4 		glseg,
			inserted 	i
	WHERE 	i.accum_depr_gl_override 	= glseg.seg_code 
	AND		i.accum_depr_gl_override	IS NOT NULL

	IF @accum_override_count <> @valid_count
	BEGIN
		SELECT @accum_is_valid = 0
		
		IF @rowcount > 1
			SELECT 	@accum_invalid_override	= MIN(accum_depr_gl_override)
			FROM	inserted 	
			WHERE 	accum_depr_gl_override	IS NOT NULL
			AND		accum_depr_gl_override 	NOT IN (SELECT 	seg_code
													FROM 	glseg4)
	END

	
	SELECT 	@valid_count 			= COUNT(DISTINCT i.depr_exp_gl_override)
	FROM	glseg4 		glseg,
			inserted 	i
	WHERE 	i.depr_exp_gl_override 	= glseg.seg_code 
	AND		i.depr_exp_gl_override		IS NOT NULL

	IF @depr_override_count <> @valid_count
	BEGIN
		SELECT @depr_is_valid = 0
		
		IF @rowcount > 1
			SELECT 	@depr_invalid_override 	= MIN(depr_exp_gl_override)
			FROM	inserted 	
			WHERE 	depr_exp_gl_override	IS NOT NULL
			AND		depr_exp_gl_override 	NOT IN (SELECT 	seg_code
													FROM 	glseg4)
	END
END

IF @asset_is_valid = 0
BEGIN
	EXEC 		amGetErrorMessage_sp 
						20135, ".\\amasttyp.itr", 371, 
						@asset_invalid_override, 
						@error_message = @message OUT
	IF @message IS NOT NULL RAISERROR	20135 @message
	SELECT 		@rollback = 1
END

IF @accum_is_valid = 0
BEGIN
	EXEC 		amGetErrorMessage_sp 
						20135, ".\\amasttyp.itr", 381, 
						@accum_invalid_override, 
						@error_message = @message OUT
	IF @message IS NOT NULL RAISERROR	20135 @message
	SELECT 		@rollback = 1
END

IF @depr_is_valid = 0
BEGIN
	EXEC 		amGetErrorMessage_sp 
						20135, ".\\amasttyp.itr", 391, 
						@depr_invalid_override, 
						@error_message = @message OUT
	IF @message IS NOT NULL RAISERROR	20135 @message
	SELECT 		@rollback = 1
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


CREATE TRIGGER 	[dbo].[amasttyp_upd_trg] 
ON 				[dbo].[amasttyp] 
FOR 			UPDATE 
AS 

DECLARE 
	@rowcount 					smCounter, 
	@rollback 					smLogical, 
	@error						smErrorCode,
	@message 					smErrorLongDesc,
	@keycount 					smCounter, 
	@asset_type_code			smAssetTypeCode, 
	@valid_count				smCounter, 
 @natural_acct				smAcctLevel,
	@asset_override_count		smCounter,
	@accum_override_count		smCounter,
	@depr_override_count		smCounter,
	@asset_invalid_override		smAccountOverride,
	@accum_invalid_override		smAccountOverride,
	@depr_invalid_override		smAccountOverride,
	@asset_override	 			smAccountOverride,
	@accum_depr_override		smAccountOverride,
	@depr_exp_override			smAccountOverride,
	@old_asset_override	 		smAccountOverride,
	@old_accum_depr_override	smAccountOverride,
	@old_depr_exp_override		smAccountOverride,
	@asset_is_valid				smLogical,
	@accum_is_valid				smLogical,
	@depr_is_valid				smLogical


SELECT @rowcount = @@rowcount 
SELECT @rollback = 0 

 
SELECT 	@keycount 			= COUNT(i.asset_type_code) 
FROM 	inserted 	i, 
		deleted 	d 
WHERE 	i.asset_type_code 	= d.asset_type_code 






IF @keycount <> @rowcount 
BEGIN 	
	EXEC 		amGetErrorMessage_sp 20524, ".\\amasttyp.utr", 131, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20524 @message 
	SELECT 		@rollback = 1 
END 



SELECT	@asset_override_count 	= COUNT(DISTINCT asset_gl_override)
FROM	inserted
WHERE	asset_gl_override		IS NOT NULL
	
SELECT	@accum_override_count 	= COUNT(DISTINCT accum_depr_gl_override)
FROM	inserted
WHERE	accum_depr_gl_override	IS NOT NULL
	
SELECT	@depr_override_count 	= COUNT(DISTINCT depr_exp_gl_override)
FROM	inserted
WHERE	depr_exp_gl_override	IS NOT NULL
	

IF @rowcount = 1
	SELECT 	@asset_invalid_override = ISNULL(asset_gl_override, ""),
			@accum_invalid_override = ISNULL(accum_depr_gl_override, ""),
			@depr_invalid_override 	= ISNULL(depr_exp_gl_override, "")
	FROM	inserted 	


SELECT 	@natural_acct		= acct_level
FROM	glaccdef
WHERE	natural_acct_flag	= 1

SELECT 	@asset_is_valid	= 1,
		@accum_is_valid	= 1,
		@depr_is_valid	= 1

IF @natural_acct = 1
BEGIN
	
	SELECT 	@valid_count 			= COUNT(DISTINCT i.asset_gl_override)
	FROM	glseg1 		glseg,
			inserted 	i
	WHERE 	i.asset_gl_override 	= glseg.seg_code 
	AND		i.asset_gl_override		IS NOT NULL

	IF @asset_override_count <> @valid_count
	BEGIN
		SELECT @asset_is_valid = 0
		
		IF @rowcount > 1
			SELECT 	@asset_invalid_override = MIN(asset_gl_override)
			FROM	inserted 	
			WHERE 	asset_gl_override		IS NOT NULL
			AND		asset_gl_override 		NOT IN (SELECT 	seg_code
													FROM 	glseg1)
	END

	
	SELECT 	@valid_count 				= COUNT(DISTINCT i.accum_depr_gl_override)
	FROM	glseg1 		glseg,
			inserted 	i
	WHERE 	i.accum_depr_gl_override 	= glseg.seg_code 
	AND		i.accum_depr_gl_override	IS NOT NULL

	IF @accum_override_count <> @valid_count
	BEGIN
		SELECT @accum_is_valid = 0
		
		IF @rowcount > 1
			SELECT 	@accum_invalid_override	= MIN(accum_depr_gl_override)
			FROM	inserted 	
			WHERE 	accum_depr_gl_override	IS NOT NULL
			AND		accum_depr_gl_override 	NOT IN (SELECT 	seg_code
													FROM 	glseg1)
	END

	
	SELECT 	@valid_count 			= COUNT(DISTINCT i.depr_exp_gl_override)
	FROM	glseg1 		glseg,
			inserted 	i
	WHERE 	i.depr_exp_gl_override 	= glseg.seg_code 
	AND		i.depr_exp_gl_override		IS NOT NULL

	IF @depr_override_count <> @valid_count
	BEGIN
		SELECT @depr_is_valid = 0
		
		IF @rowcount > 1
			SELECT 	@depr_invalid_override 	= MIN(depr_exp_gl_override)
			FROM	inserted 	
			WHERE 	depr_exp_gl_override	IS NOT NULL
			AND		depr_exp_gl_override 	NOT IN (SELECT 	seg_code
													FROM 	glseg1)
	END
END
ELSE IF @natural_acct = 2
BEGIN
	
	SELECT 	@valid_count 			= COUNT(DISTINCT i.asset_gl_override)
	FROM	glseg2 		glseg,
			inserted 	i
	WHERE 	i.asset_gl_override 	= glseg.seg_code 
	AND		i.asset_gl_override		IS NOT NULL

	IF @asset_override_count <> @valid_count
	BEGIN
		SELECT @asset_is_valid = 0
		
		IF @rowcount > 1
			SELECT 	@asset_invalid_override = MIN(asset_gl_override)
			FROM	inserted 	
			WHERE 	asset_gl_override		IS NOT NULL
			AND		asset_gl_override 		NOT IN (SELECT 	seg_code
													FROM 	glseg2)
	END

	
	SELECT 	@valid_count 				= COUNT(DISTINCT i.accum_depr_gl_override)
	FROM	glseg2 		glseg,
			inserted 	i
	WHERE 	i.accum_depr_gl_override 	= glseg.seg_code 
	AND		i.accum_depr_gl_override	IS NOT NULL

	IF @accum_override_count <> @valid_count
	BEGIN
		SELECT @accum_is_valid = 0
		
		IF @rowcount > 1
			SELECT 	@accum_invalid_override	= MIN(accum_depr_gl_override)
			FROM	inserted 	
			WHERE 	accum_depr_gl_override	IS NOT NULL
			AND		accum_depr_gl_override 	NOT IN (SELECT 	seg_code
													FROM 	glseg2)
	END

	
	SELECT 	@valid_count 			= COUNT(DISTINCT i.depr_exp_gl_override)
	FROM	glseg2 		glseg,
			inserted 	i
	WHERE 	i.depr_exp_gl_override 	= glseg.seg_code 
	AND		i.depr_exp_gl_override		IS NOT NULL

	IF @depr_override_count <> @valid_count
	BEGIN
		SELECT @depr_is_valid = 0
		
		IF @rowcount > 1
			SELECT 	@depr_invalid_override 	= MIN(depr_exp_gl_override)
			FROM	inserted 	
			WHERE 	depr_exp_gl_override	IS NOT NULL
			AND		depr_exp_gl_override 	NOT IN (SELECT 	seg_code
													FROM 	glseg2)
	END
END
ELSE IF @natural_acct = 3
BEGIN
	
	SELECT 	@valid_count 			= COUNT(DISTINCT i.asset_gl_override)
	FROM	glseg3 		glseg,
			inserted 	i
	WHERE 	i.asset_gl_override 	= glseg.seg_code 
	AND		i.asset_gl_override		IS NOT NULL

	IF @asset_override_count <> @valid_count
	BEGIN
		SELECT @asset_is_valid = 0
		
		IF @rowcount > 1
			SELECT 	@asset_invalid_override = MIN(asset_gl_override)
			FROM	inserted 	
			WHERE 	asset_gl_override		IS NOT NULL
			AND		asset_gl_override 		NOT IN (SELECT 	seg_code
													FROM 	glseg3)
	END

	
	SELECT 	@valid_count 				= COUNT(DISTINCT i.accum_depr_gl_override)
	FROM	glseg3 		glseg,
			inserted 	i
	WHERE 	i.accum_depr_gl_override 	= glseg.seg_code 
	AND		i.accum_depr_gl_override	IS NOT NULL

	IF @accum_override_count <> @valid_count
	BEGIN
		SELECT @accum_is_valid = 0
		
		IF @rowcount > 1
			SELECT 	@accum_invalid_override	= MIN(accum_depr_gl_override)
			FROM	inserted 	
			WHERE 	accum_depr_gl_override	IS NOT NULL
			AND		accum_depr_gl_override 	NOT IN (SELECT 	seg_code
													FROM 	glseg3)
	END

	
	SELECT 	@valid_count 			= COUNT(DISTINCT i.depr_exp_gl_override)
	FROM	glseg3 		glseg,
			inserted 	i
	WHERE 	i.depr_exp_gl_override 	= glseg.seg_code 
	AND		i.depr_exp_gl_override		IS NOT NULL

	IF @depr_override_count <> @valid_count
	BEGIN
		SELECT @depr_is_valid = 0
		
		IF @rowcount > 1
			SELECT 	@depr_invalid_override 	= MIN(depr_exp_gl_override)
			FROM	inserted 	
			WHERE 	depr_exp_gl_override	IS NOT NULL
			AND		depr_exp_gl_override 	NOT IN (SELECT 	seg_code
													FROM 	glseg3)
	END
END
ELSE 
BEGIN
	
	SELECT 	@valid_count 			= COUNT(DISTINCT i.asset_gl_override)
	FROM	glseg4 		glseg,
			inserted 	i
	WHERE 	i.asset_gl_override 	= glseg.seg_code 
	AND		i.asset_gl_override		IS NOT NULL

	IF @asset_override_count <> @valid_count
	BEGIN
		SELECT @asset_is_valid = 0
		
		IF @rowcount > 1
			SELECT 	@asset_invalid_override = MIN(asset_gl_override)
			FROM	inserted 	
			WHERE 	asset_gl_override		IS NOT NULL
			AND		asset_gl_override 		NOT IN (SELECT 	seg_code
													FROM 	glseg4)
	END

	
	SELECT 	@valid_count 				= COUNT(DISTINCT i.accum_depr_gl_override)
	FROM	glseg4 		glseg,
			inserted 	i
	WHERE 	i.accum_depr_gl_override 	= glseg.seg_code 
	AND		i.accum_depr_gl_override	IS NOT NULL

	IF @accum_override_count <> @valid_count
	BEGIN
		SELECT @accum_is_valid = 0
		
		IF @rowcount > 1
			SELECT 	@accum_invalid_override	= MIN(accum_depr_gl_override)
			FROM	inserted 	
			WHERE 	accum_depr_gl_override	IS NOT NULL
			AND		accum_depr_gl_override 	NOT IN (SELECT 	seg_code
													FROM 	glseg4)
	END

	
	SELECT 	@valid_count 			= COUNT(DISTINCT i.depr_exp_gl_override)
	FROM	glseg4 		glseg,
			inserted 	i
	WHERE 	i.depr_exp_gl_override 	= glseg.seg_code 
	AND		i.depr_exp_gl_override		IS NOT NULL

	IF @depr_override_count <> @valid_count
	BEGIN
		SELECT @depr_is_valid = 0
		
		IF @rowcount > 1
			SELECT 	@depr_invalid_override 	= MIN(depr_exp_gl_override)
			FROM	inserted 	
			WHERE 	depr_exp_gl_override	IS NOT NULL
			AND		depr_exp_gl_override 	NOT IN (SELECT 	seg_code
													FROM 	glseg4)
	END
END

IF @asset_is_valid = 0
BEGIN
	EXEC 		amGetErrorMessage_sp 
						20135, ".\\amasttyp.utr", 435, 
						@asset_invalid_override, 
						@error_message = @message OUT
	IF @message IS NOT NULL RAISERROR	20135 @message
	SELECT 		@rollback = 1
END

IF @accum_is_valid = 0
BEGIN
	EXEC 		amGetErrorMessage_sp 
						20135, ".\\amasttyp.utr", 445, 
						@accum_invalid_override, 
						@error_message = @message OUT
	IF @message IS NOT NULL RAISERROR	20135 @message
	SELECT 		@rollback = 1
END

IF @depr_is_valid = 0
BEGIN
	EXEC 		amGetErrorMessage_sp 
						20135, ".\\amasttyp.utr", 455, 
						@depr_invalid_override, 
						@error_message = @message OUT
	IF @message IS NOT NULL RAISERROR	20135 @message
	SELECT 		@rollback = 1
END

IF @rollback = 1 
BEGIN
	ROLLBACK TRANSACTION 
	RETURN
END

SELECT	@asset_type_code = MIN(asset_type_code)
FROM	inserted

WHILE @asset_type_code IS NOT NULL
BEGIN
	SELECT 	@asset_override 			= asset_gl_override,
			@accum_depr_override		= accum_depr_gl_override,
			@depr_exp_override			= depr_exp_gl_override
	FROM	inserted
	WHERE	asset_type_code				= @asset_type_code

	SELECT 	@old_asset_override 		= asset_gl_override,
			@old_accum_depr_override	= accum_depr_gl_override,
			@old_depr_exp_override		= depr_exp_gl_override
	FROM	deleted
	WHERE	asset_type_code				= @asset_type_code

	IF (@asset_override IS NOT NULL AND @old_asset_override IS NULL)
	OR (@asset_override IS NULL AND @old_asset_override IS NOT NULL)
	OR (@asset_override IS NOT NULL AND @old_asset_override IS NOT NULL AND @asset_override <> @old_asset_override)
	BEGIN
		UPDATE 	amastact
		SET		up_to_date			= 0,
				last_modified_date	= GETDATE()
		FROM	amastact aa,
				amasset a
		WHERE	aa.co_asset_id 		= a.co_asset_id
		AND		aa.account_type_id	= 0
		AND		a.asset_type_code	= @asset_type_code

		SELECT @error = @@error
		IF @error <> 0
		BEGIN
			ROLLBACK TRANSACTION
			RETURN 
		END
	END

	IF (@accum_depr_override IS NOT NULL AND @old_accum_depr_override IS NULL)
	OR (@accum_depr_override IS NULL AND @old_accum_depr_override IS NOT NULL)
	OR (@accum_depr_override IS NOT NULL AND @old_accum_depr_override IS NOT NULL AND @accum_depr_override <> @old_accum_depr_override)
	BEGIN
		UPDATE 	amastact
		SET		up_to_date			= 0,
				last_modified_date	= GETDATE()
		FROM	amastact aa,
				amasset a
		WHERE	aa.co_asset_id 		= a.co_asset_id
		AND		aa.account_type_id	= 1
		AND		a.asset_type_code	= @asset_type_code

		SELECT @error = @@error
		IF @error <> 0
		BEGIN
			ROLLBACK TRANSACTION
			RETURN 
		END
	END

	IF (@depr_exp_override IS NOT NULL AND @old_depr_exp_override IS NULL)
	OR (@depr_exp_override IS NULL AND @old_depr_exp_override IS NOT NULL)
	OR (@depr_exp_override IS NOT NULL AND @old_depr_exp_override IS NOT NULL AND @depr_exp_override <> @old_depr_exp_override)
	BEGIN
		UPDATE 	amastact
		SET		up_to_date			= 0,
				last_modified_date	= GETDATE()
		FROM	amastact aa,
				amasset a
		WHERE	aa.co_asset_id 		= a.co_asset_id
		AND		aa.account_type_id	= 5
		AND		a.asset_type_code	= @asset_type_code

		SELECT @error = @@error
		IF @error <> 0
		BEGIN
			ROLLBACK TRANSACTION
			RETURN 
		END
	END



	
	SELECT 	@asset_type_code	= MIN(asset_type_code)
	FROM	inserted
	WHERE	asset_type_code		> @asset_type_code

END

GO
CREATE UNIQUE CLUSTERED INDEX [amasttyp_ind_0] ON [dbo].[amasttyp] ([asset_type_code]) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amasttyp].[asset_type_description]'
GO
EXEC sp_bindefault N'[dbo].[smTodaysDate_df]', N'[dbo].[amasttyp].[last_modified_date]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amasttyp].[modified_by]'
GO
GRANT REFERENCES ON  [dbo].[amasttyp] TO [public]
GO
GRANT SELECT ON  [dbo].[amasttyp] TO [public]
GO
GRANT INSERT ON  [dbo].[amasttyp] TO [public]
GO
GRANT DELETE ON  [dbo].[amasttyp] TO [public]
GO
GRANT UPDATE ON  [dbo].[amasttyp] TO [public]
GO
