SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[amNextKey_sp] 
( 
    @key_type    	smKeyType, 				
    @sequence_id    smSurrogateKey OUTPUT, 	
	@debug_level	smDebugLevel	= 0		
)
AS 
 
DECLARE 
	@error 			smErrorCode, 
	@message        smErrorLongDesc, 
	@ok             smLogical, 
	@tran_started 	smLogical 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "amnxtkey.cpp" + ", line " + STR( 102, 5 ) + " -- ENTRY: " 
 


 

SELECT @tran_started = 0 

IF (@@trancount = 0)
BEGIN 
	SELECT @tran_started = 1 
	BEGIN TRANSACTION 
END 
 
SELECT 	@sequence_id = sequence_id 
FROM 	amsurkey WITH (HOLDLOCK)
WHERE 	key_type = @key_type 
 
IF @@rowcount = 0 
BEGIN 
    EXEC 		amGetErrorMessage_sp 20060, "amnxtkey.cpp", 122, "amsurkey", @error_message = @message OUTPUT 
    IF @message IS NOT NULL RAISERROR 	20060 @message 
    IF (@tran_started= 1)
    BEGIN 
    	SELECT 		@tran_started = 0 
    	ROLLBACK 	TRANSACTION 
    END 
    RETURN 		20060 
END 
 
UPDATE 	amsurkey 
SET 	sequence_id = sequence_id + 1 
WHERE 	key_type = @key_type 

SELECT @error = @@error 
IF @error <> 0 
BEGIN 
	SELECT 		@tran_started = 0 
	ROLLBACK 	TRANSACTION 
END 

IF (@tran_started = 1)
BEGIN 
	SELECT @tran_started = 0 
	COMMIT TRANSACTION 
END 
 
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "amnxtkey.cpp" + ", line " + STR( 149, 5 ) + " -- EXIT: "
 
RETURN @@error 
GO
GRANT EXECUTE ON  [dbo].[amNextKey_sp] TO [public]
GO
