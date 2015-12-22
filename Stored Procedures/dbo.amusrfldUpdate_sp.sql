SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amusrfldUpdate_sp] 
( 
	@timestamp 			timestamp,
	@user_field_id 		smSurrogateKey, 
	@user_code_1 		smStdDescription, 
	@user_code_2 		smStdDescription, 
	@user_code_3 		smStdDescription, 
	@user_code_4 		smStdDescription, 
	@user_code_5 		smStdDescription, 
	@user_date_1 		varchar(30), 
	@user_date_2 		varchar(30), 
	@user_date_3 		varchar(30), 
	@user_date_4		varchar(30), 
	@user_date_5 		varchar(30), 
	@user_amount_1 		smMoneyZero, 
	@user_amount_2 	smMoneyZero, 
	@user_amount_3 		smMoneyZero, 
	@user_amount_4 	smMoneyZero, 
	@user_amount_5 	smMoneyZero 
) 
AS 
DECLARE 
	@ts 		timestamp, 
	@rowcount 	smCounter, 
	@error 		smErrorCode, 
	@message 	smErrorLongDesc

IF EXISTS(SELECT 	user_field_id
			FROM	amusrfld
			WHERE	user_field_id = @user_field_id)
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
		SELECT @user_code_1 = ' '
	IF @user_code_2 IS NULL 
		SELECT @user_code_2 = ' '
	IF @user_code_3 IS NULL 
		SELECT @user_code_3 = ' '
	IF @user_code_4 IS NULL 
		SELECT @user_code_4 = ' '
	IF @user_code_5 IS NULL 
		SELECT @user_code_5 = ' '

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
			EXEC 		amGetErrorMessage_sp 20004, "tmp/amusfdup.sp", 162, amusrfld, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	20004 @message 
			RETURN 		20004 
		END 
		
		IF @ts <> @timestamp 
		BEGIN 
			EXEC 		amGetErrorMessage_sp 20003, "tmp/amusfdup.sp", 169, amusrfld, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	20003 @message
			RETURN 		20003 
		END 
	END 
END
ELSE
BEGIN
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
GRANT EXECUTE ON  [dbo].[amusrfldUpdate_sp] TO [public]
GO
