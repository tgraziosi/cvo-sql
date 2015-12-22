SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amUpdCoUserFields_sp]
(	 @company_id	smCompanyID,			
	 @debug_level		smDebugLevel	= 0	
 
) as

DECLARE @user_field_type	smUserFieldType,
	 	@user_field_subid	tinyint,
		@length				smCounter,
		@proc				smLongDesc,
		@zoom				smCounter,
		@count				int,
		@tbl_id				int,
		@fld_id				int,
		@base_fld_id		int,
		@error 				int,
		@message 			varchar(255),
		@popup_mnu			int,
		@default			varchar(40),
		@allow				int



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amupdfld.sp" + ", line " + STR( 74, 5 ) + " -- ENTRY: "

BEGIN TRANSACTION


SELECT	@tbl_id				= tbl_alt_id
FROM	amtblhdr a, amtblalt b
WHERE	a.tbl_name 		= "amusrfld"
AND		a.tbl_id 		= b.tbl_id
AND		b.alt_key	 	= @company_id

IF @tbl_id IS NULL 
BEGIN

	EXEC 		amGetErrorMessage_sp 20208, "tmp/amupdfld.sp", 90, "amusrhdr", @error_message = @message out
 IF @message IS NOT NULL RAISERROR 	20208 @message
	ROLLBACK 	TRANSACTION
 RETURN 		20208
	
END


UPDATE	amtblfld
SET		
		length			= 0,
		validation_proc = "",
		zoom_id			= 0,
		popup_mnu		= 0,
		fld_default = "",
		null_allow		= 1		
WHERE	tbl_id			= @tbl_id

SELECT @error = @@error
IF @error <> 0 
BEGIN
	ROLLBACK TRANSACTION
 RETURN @error
END
	 


SELECT	@base_fld_id		= 2


SELECT	@count 				= 1	

IF @debug_level >= 3
	SELECT "Text Fields"

SELECT	@user_field_subid	= MIN(user_field_subid)
FROM	amusrhdr
WHERE	company_id			= @company_id
AND		user_field_id		= 1000
AND		user_field_type	IN (11,12)
AND		user_field_subid <> 0

WHILE @user_field_subid IS NOT NULL
BEGIN
	 	
		
		SELECT 	@length	= user_field_length,
				@proc	= validation_proc,
				@zoom	= zoom_id,
				@allow = allow_null,
				@default= default_value 
		FROM	amusrhdr
		WHERE	company_id			= @company_id
		AND		user_field_id		= 1000
		AND		user_field_subid	= @user_field_subid

		SELECT @popup_mnu = 0
		IF @zoom IS NOT NULL 
			IF @zoom > 0 
				SELECT @popup_mnu = 1

		
		
		SELECT @fld_id = @count + @base_fld_id

		IF @debug_level >= 3
			SELECT
				 user_field_subid	= @user_field_subid	,
				 counter	= @count,
				 tbl_id	= @tbl_id,
				 fld_id 	= @fld_id,
				 zoom_id = @zoom,
				 popup_mnu= @popup_mnu,
				 validation_proc = ISNULL(@proc,"")	



		UPDATE	amtblfld
		SET		system_defined	= 0,
				length			= @length,
				validation_proc = ISNULL(@proc,""),
				zoom_id			= @zoom,
				popup_mnu		= @popup_mnu,
				fld_default		= ISNULL(@default,""),
				null_allow		= @allow

		WHERE	tbl_id			= @tbl_id
		AND		fld_id			= @fld_id

		SELECT @error = @@error
		IF @error <> 0 
		BEGIN
			ROLLBACK TRANSACTION
 	RETURN @error
		END


		
		
		SELECT @count = @count + 1
 

		SELECT	@user_field_subid	= MIN(user_field_subid)
		FROM	amusrhdr
		WHERE	company_id			= @company_id
		AND		user_field_id		= 1000
		AND		user_field_type		IN (11,12)
		AND		user_field_subid	> @user_field_subid 
		AND		user_field_subid <> 0


END




SELECT	@count 				= 1	
SELECT	@base_fld_id		= 2 + 5

IF @debug_level >= 3
	SELECT "Date Fields ", base = @base_fld_id


SELECT	@user_field_subid	= MIN(user_field_subid)
FROM	amusrhdr
WHERE	company_id			= @company_id
AND		user_field_id		= 1000
AND		user_field_type		IN (21 ,22, 23, 24,25)

WHILE @user_field_subid IS NOT NULL
BEGIN
	 	
		
		SELECT 	@length	= user_field_length,
				@proc	= validation_proc,
				@zoom	= zoom_id,
				@allow = allow_null,
				@default= default_value 

		FROM	amusrhdr
		WHERE	company_id			= @company_id
		AND		user_field_id		= 1000
		AND		user_field_subid	= @user_field_subid

		SELECT @popup_mnu = 0 
		IF @zoom IS NOT NULL 
			IF @zoom > 0 
				SELECT @popup_mnu = 1


		
		
		SELECT @fld_id = @count + @base_fld_id

		IF @debug_level >= 3
			SELECT
				 user_field_subid	= @user_field_subid	, 
				 counter	= @count,
				 tbl_id	= @tbl_id,
				 fld_id 	= @fld_id,
				 zoom_id = @zoom,
				 popup_mnu= @popup_mnu,
				 validation_proc = ISNULL(@proc,"")	

		UPDATE	amtblfld
		SET		system_defined	= 0,
				length			= @length,
				validation_proc = ISNULL(@proc,""),
				zoom_id			= @zoom,
			 popup_mnu		= @popup_mnu,
			 fld_default		= ISNULL(@default,""),
				null_allow		= @allow

		WHERE	tbl_id			= @tbl_id
		AND		fld_id			= @fld_id

		SELECT @error = @@error
		IF @error <> 0 
		BEGIN
			ROLLBACK TRANSACTION
 	RETURN @error
		END


		
		
		SELECT @count = @count + 1
 

		SELECT	@user_field_subid	= MIN(user_field_subid)
		FROM	amusrhdr
		WHERE	company_id			= @company_id
		AND		user_field_id		= 1000
		AND		user_field_type	IN (21 ,22, 23, 24,25)
		AND		user_field_subid	> @user_field_subid 

END


SELECT	@count 				= 1	
SELECT	@base_fld_id		= 2 + 5	+ 5

IF @debug_level >= 3
	SELECT "Number Fields ", base = @base_fld_id


SELECT	@user_field_subid	= MIN(user_field_subid)
FROM	amusrhdr
WHERE	company_id			= @company_id
AND		user_field_id		= 1000
AND		user_field_type		IN (31,32,33,34,35)

WHILE @user_field_subid IS NOT NULL
BEGIN
	 	
		
		SELECT 	@length	= user_field_length,
				@proc	= validation_proc,
				@zoom	= zoom_id,
				@allow = allow_null,
				@default= default_value 

		FROM	amusrhdr
		WHERE	company_id			= @company_id
		AND		user_field_id		= 1000
		AND		user_field_subid	= @user_field_subid


		SELECT @popup_mnu = 0
		IF @zoom IS NOT NULL 
			IF @zoom > 0 
				SELECT @popup_mnu = 1

		
		
		SELECT @fld_id = @count + @base_fld_id

		IF @debug_level >= 3
			SELECT 
				 user_field_subid	= @user_field_subid	,
				 counter	= @count,
				 tbl_id	= @tbl_id,
				 fld_id 	= @fld_id,
				 zoom_id = @zoom,
				 popup_mnu= @popup_mnu,
				 validation_proc = ISNULL(@proc,"")	

		UPDATE	amtblfld
		SET		system_defined	= 0,
				length			= @length,
				validation_proc = ISNULL(@proc,""),
				zoom_id			= @zoom	,
				popup_mnu		= @popup_mnu,
				fld_default		= ISNULL(@default,""),
				null_allow		= @allow

		WHERE	tbl_id			= @tbl_id
		AND		fld_id			= @fld_id

		SELECT @error = @@error
		IF @error <> 0 
		BEGIN
			ROLLBACK TRANSACTION
 	RETURN @error
		END


		
		
		SELECT @count = @count + 1
 

		SELECT	@user_field_subid	= MIN(user_field_subid)
		FROM	amusrhdr
		WHERE	company_id			= @company_id
		AND		user_field_id		= 1000
		AND		user_field_type		IN (31,32,33,34,35)		
		AND		user_field_subid	> @user_field_subid 

END

 
COMMIT TRANSACTION
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amupdfld.sp" + ", line " + STR( 408, 5 ) + " -- EXIT: "

return @@error
GO
GRANT EXECUTE ON  [dbo].[amUpdCoUserFields_sp] TO [public]
GO
