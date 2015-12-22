SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amAssetUserFieldsUpdate_sp]
( 
	
	@co_asset_id 		smSurrogateKey = NULL, 
	@user_code_1 		smStdDescription = NULL, 
	@user_code_2 		smStdDescription = NULL, 
	@user_code_3 		smStdDescription = NULL, 
	@user_code_4 		smStdDescription = NULL, 
	@user_code_5 		smStdDescription = NULL, 
	@user_date_1 		varchar(30)= NULL, 
	@user_date_2 		varchar(30)= NULL, 
	@user_date_3 		varchar(30)= NULL, 
	@user_date_4		varchar(30)= NULL, 
	@user_date_5 		varchar(30)= NULL, 
	@user_amount_1 		float= NULL, 
	@user_amount_2 	float= NULL, 
	@user_amount_3 		float= NULL, 
	@user_amount_4 	float= NULL, 
	@user_amount_5 	float= NULL 
) 
AS 
DECLARE
	@user_field_id smSurrogateKey,
	@ts 		timestamp, 
	@timestamp timestamp,
	@rowcount 	smCounter, 
	@error 		smErrorCode, 
	@message 	smErrorLongDesc,
	@user_code_1_t 			smStdDescription, 
	@user_code_2_t 			smStdDescription, 
	@user_code_3_t 		smStdDescription, 
	@user_code_4_t 		smStdDescription, 
	@user_code_5_t 		smStdDescription, 
	@user_date_1_t 		varchar(30), 
	@user_date_2_t 			varchar(30), 
	@user_date_3_t 		varchar(30), 
	@user_date_4_t			varchar(30), 
	@user_date_5_t 			varchar(30), 
	@user_amount_1_t 		float, 
	@user_amount_2_t 	float, 
	@user_amount_3_t 		float, 
	@user_amount_4_t 		float, 
	@user_amount_5_t 		float 



SELECT 	@user_field_id	= user_field_id
FROM	amasset
WHERE	co_asset_id		= @co_asset_id


SELECT @error = @@error, @rowcount = @@rowcount 
IF @error <> 0
	RETURN @error 

IF @rowcount <> 1 
	RETURN 0 



IF EXISTS(SELECT 	user_field_id
			FROM	amusrfld
			WHERE	user_field_id = @user_field_id)
BEGIN

 
	 
	SELECT 	@timestamp		= timestamp,
			@user_code_1_t	= user_code_1, 
			@user_code_2_t 	= user_code_2, 
			@user_code_3_t = user_code_3,	 
			@user_code_4_t = user_code_4, 
			@user_code_5_t = user_code_5, 
			@user_date_1_t = user_date_1, 
			@user_date_2_t 	= user_date_2, 
			@user_date_3_t = user_date_3, 
			@user_date_4_t	= user_date_4, 
			@user_date_5_t 	= user_date_5, 
			@user_amount_1_t = user_amount_1, 
			@user_amount_2_t = user_amount_2, 
			@user_amount_3_t = user_amount_3, 
			@user_amount_4_t = user_amount_4, 
			@user_amount_5_t = user_amount_5 
	FROM 	amusrfld 
	WHERE 	user_field_id 	= @user_field_id 


	IF @user_code_1 IS NULL 
		SELECT @user_code_1 = @user_code_1_t
	IF @user_code_2 IS NULL 
		SELECT @user_code_2 = @user_code_2_t
	IF @user_code_3 IS NULL 
		SELECT @user_code_3 = @user_code_3_t
	IF @user_code_4 IS NULL 
		SELECT @user_code_4 = @user_code_4_t
	IF @user_code_5 IS NULL 
		SELECT @user_code_5 = @user_code_5_t


	IF @user_date_1 IS NULL 
		SELECT @user_date_1 = @user_date_1_t
	IF @user_date_2 IS NULL 
		SELECT @user_date_2 = @user_date_2_t
	IF @user_date_3 IS NULL 
		SELECT @user_date_3 = @user_date_3_t
	IF @user_date_4 IS NULL 
		SELECT @user_date_4 = @user_date_4_t
	IF @user_date_5 IS NULL 
		SELECT @user_date_5 = @user_date_5_t


	IF @user_amount_1 IS NULL 
		SELECT @user_amount_1 = @user_amount_1_t 
	IF @user_amount_2 IS NULL 
		SELECT @user_amount_2 = @user_amount_2_t
	IF @user_amount_3 IS NULL 
		SELECT @user_amount_3 = @user_amount_3_t
	IF @user_amount_4 IS NULL 
		SELECT @user_amount_4 = @user_amount_4_t
	IF @user_amount_5 IS NULL 
		SELECT @user_amount_5 = @user_amount_5_t 



	UPDATE amusrfld 
	SET 
		user_code_1			= @user_code_1,
		user_code_2 		= @user_code_2,
		user_code_3 		= @user_code_3,
		user_code_4 		= @user_code_4,
		user_code_5			= @user_code_5,
		user_date_1 		= @user_date_1,
		user_date_2 		= @user_date_2,
		user_date_3 		= @user_date_3,
		user_date_4 		= @user_date_4,
		user_date_5 		= @user_date_5,
		user_amount_1 	= @user_amount_1,
		user_amount_2 	= @user_amount_2,
		user_amount_3 	= @user_amount_3,
		user_amount_4 	= @user_amount_4,
		user_amount_5 	= @user_amount_5 
	WHERE 	user_field_id		= @user_field_id 
	AND 	timestamp			= @timestamp 
	
	SELECT @error = @@error, @rowcount = @@rowcount 
	IF @error <> 0  
		RETURN @error 

	IF @rowcount = 0  
	BEGIN 
		 
		SELECT 	@ts 			= timestamp 
		FROM 	amusrfld 
		WHERE 	user_field_id 	= @user_field_id 

		SELECT @error = @@error, @rowcount = @@rowcount 
		IF @error <> 0  
			RETURN @error 
		IF @rowcount = 0  
		BEGIN 
			EXEC 		amGetErrorMessage_sp 20004, "tmp/amastusfdup.sp", 227, amusrfld, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	20004 @message 
			RETURN 		20004 
		END 
		
		IF @ts <> @timestamp 
		BEGIN 
			EXEC 		amGetErrorMessage_sp 20003, "tmp/amastusfdup.sp", 234, amusrfld, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	20003 @message
			RETURN 		20003 
		END 
	END 
END
ELSE
BEGIN

	IF @user_amount_1 IS NULL 
		SELECT @user_amount_1 = 0.0
	IF @user_amount_2 IS NULL 
		SELECT @user_amount_2 = 0.0
	IF @user_amount_3 IS NULL 
		SELECT @user_amount_3 = 0.0
	IF @user_amount_4 IS NULL 
		SELECT @user_amount_4 = 0.0
	IF @user_amount_5 IS NULL 
		SELECT @user_amount_5 = 0.0
		
	IF @user_code_1 IS NULL 
		SELECT @user_code_1 = ""
	IF @user_code_2 IS NULL 
		SELECT @user_code_2 = ""
	IF @user_code_3 IS NULL 
		SELECT @user_code_3 = ""
	IF @user_code_4 IS NULL 
		SELECT @user_code_4 = ""
	IF @user_code_5 IS NULL 
		SELECT @user_code_5 = ""
 


	EXEC @error = amusrfldInsert_sp
					@user_field_id, 
					@user_code_1, 
					@user_code_2, 
					@user_code_3, 
					@user_code_4, 
					@user_code_5, 
					@user_date_1, 
					@user_date_2, 
					@user_date_3, 
					@user_date_4, 
					@user_date_5, 
					@user_amount_1, 
					@user_amount_2, 
					@user_amount_3, 
					@user_amount_4, 
					@user_amount_5 
	RETURN @error 

END

RETURN 0

GO
GRANT EXECUTE ON  [dbo].[amAssetUserFieldsUpdate_sp] TO [public]
GO
