SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amMoveBadAcctRefCodes_sp]
(
	@error_code		smErrorCode,		
	@ref_only		smLogical, 			
	@debug_level	smDebugLevel = 0	
)
AS 

DECLARE 
	@message			smErrorLongDesc,
	@e_level 			smErrorLevel, 
	@client_id 			smClientID, 
	@e_active 			smErrorActive, 
	@e_sdesc 			smErrorShortDesc, 
	@severity 		varchar(40),
	@char_index			smSmallCounter,
	@error				smErrorCode,
	@start_time 		datetime


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ammvbdrf.sp" + ", line " + STR( 109, 5 ) + " -- ENTRY: "

SELECT @start_time = GETDATE()


EXEC 	@error = amGetError_sp 	@error_code, 
								@client_id 		OUTPUT,
								@e_level 		OUTPUT,
								@e_active 		OUTPUT,
								@e_sdesc 		OUTPUT,
								@message 		OUTPUT 
IF @error <> 0
	RETURN @error
	

SELECT @char_index = CHARINDEX('"', @message) 
IF @char_index <> 0
	SELECT @message = SUBSTRING(@message, 1, @char_index - 1) + SUBSTRING(@message, @char_index + 1, DATALENGTH(@message) - @char_index)

SELECT @char_index = CHARINDEX('"', @message) 
IF @char_index <> 0
	SELECT @message = SUBSTRING(@message, 1, @char_index - 1) + SUBSTRING(@message, @char_index + 1, DATALENGTH(@message) - @char_index)


INSERT INTO #amaccerr
(
	error_code,
	error_message
)
VALUES 
(
	@error_code,
	@message
)

SELECT @error = @@error
IF @error <> 0
	RETURN @error


IF @ref_only = 1 
BEGIN
	UPDATE 	#amaccts
	SET 	error_code 						= @error_code
	FROM	#amaccts accounts, #amvldref tmp 
	WHERE	tmp.invalid_flag 				= 1
	AND		accounts.account_reference_code	= tmp.account_reference_code
	
	SELECT @error = @@error
	IF @error <> 0
		RETURN @error

	
	DELETE 
	FROM 	#amvldref
	WHERE	invalid_flag 	= 1

	SELECT @error = @@error
	IF @error <> 0
		RETURN @error
END
ELSE
BEGIN
	UPDATE 	#amaccts
	SET 	error_code 						= @error_code
	FROM	#amaccts accounts, #amvldarf tmp 
	WHERE	tmp.invalid_flag 				= 1
	AND		accounts.new_account_code 		= tmp.account_code
	AND		accounts.account_reference_code	= tmp.account_reference_code

	SELECT @error = @@error
	IF @error <> 0
		RETURN @error
		
	
	DELETE 
	FROM 	#amvldarf
	WHERE	invalid_flag 	= 1

	SELECT @error = @@error
	IF @error <> 0
		RETURN @error
END
	
IF @debug_level >= 5
	SELECT time_taken = DATEDIFF(ms, @start_time, GETDATE())

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ammvbdrf.sp" + ", line " + STR( 196, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amMoveBadAcctRefCodes_sp] TO [public]
GO
