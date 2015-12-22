SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[amMarkDepr_sp] 
( 
    @company_id    	smCompanyID,		
    @user_id		smUserID, 			


    @valid		    smLogical OUTPUT, 	
	@debug_level	smDebugLevel	= 0	
)
AS 
 
DECLARE 
	@error 			smErrorCode,
	@message        smErrorLongDesc, 
	@tran_started 	smLogical, 
	@process_id 	smSurrogateKey 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ammrkdpr.cpp" + ", line " + STR( 97, 5 ) + " -- ENTRY: "
 
SELECT 	@valid 			= 0,
		@tran_started 	= 0 

IF (@@trancount = 0)
BEGIN 
	SELECT @tran_started = 1 
	BEGIN TRANSACTION 
END 
 



SELECT 	@process_id 	= process_id 
FROM 	amco WITH (HOLDLOCK)
WHERE 	company_id 		= @company_id 
 
IF @process_id IS NULL 
BEGIN 
    EXEC 		amGetErrorMessage_sp 20206, "ammrkdpr.cpp", 117, @error_message = @message OUTPUT 
    IF @message IS NOT NULL RAISERROR 	20206 @message 

    IF (@tran_started= 1)
    BEGIN 
    	SELECT 		@tran_started = 0 
    	ROLLBACK 	TRANSACTION 
    END 
    RETURN 20206 
END 
 









IF 	@process_id = 0
OR	@user_id = 0
BEGIN
	UPDATE 	amco 
	SET 	process_id = @user_id 
	WHERE 	company_id = @company_id 

	SELECT @error = @@error 
	IF @error <> 0 
	BEGIN 
		SELECT 		@tran_started = 0 
		ROLLBACK 	TRANSACTION 
		RETURN		@error
	END 
	SELECT @valid = 1
END

IF (@tran_started = 1)
BEGIN 
	SELECT @tran_started = 0 
	COMMIT TRANSACTION 
END 
 
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ammrkdpr.cpp" + ", line " + STR( 160, 5 ) + " -- EXIT: " 
 
RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amMarkDepr_sp] TO [public]
GO
