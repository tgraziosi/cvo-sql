SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[amValidConvention_sp] 
(
 @method_id smDeprMethodID,		 	
	@convention_id smConventionID,		 	
	@is_valid smLogical		OUTPUT,	
	@debug_level	smDebugLevel	= 0		
)
AS 

DECLARE 
	@message 		smErrorLongDesc			

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amvldcnv.sp" + ", line " + STR( 58, 5 ) + " -- ENTRY: "

SELECT @is_valid = 1

IF @convention_id = 3
BEGIN
	IF (@method_id = 7)
	OR 	(@method_id = 0)
	BEGIN 
		SELECT		@is_valid = 0
		EXEC 		amGetErrorMessage_sp 20114, "tmp/amvldcnv.sp", 68, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20114 @message 
		RETURN 		20114 	
	END 
END

ELSE IF @convention_id = 1
BEGIN
	IF (@method_id = 7)
	OR 	(@method_id = 0)
	BEGIN 
		SELECT		@is_valid = 0
		EXEC 		amGetErrorMessage_sp 20112, "tmp/amvldcnv.sp", 80, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20112 @message 
		RETURN 		20112 	
	END 
END

ELSE IF @convention_id = 2
BEGIN
	IF (@method_id = 7)
	OR 	(@method_id = 0)
	BEGIN 
		SELECT		@is_valid = 0
		EXEC 		amGetErrorMessage_sp 20113, "tmp/amvldcnv.sp", 92, @error_message = @message OUT 		
		IF @message IS NOT NULL RAISERROR 	20113 @message 
		RETURN 		20113 	
	END 		
	
END

ELSE IF @convention_id = 0
BEGIN
	IF (@method_id = 7)
	OR 	(@method_id = 0)
	BEGIN 
		SELECT		@is_valid = 0
		EXEC 		amGetErrorMessage_sp 20111, "tmp/amvldcnv.sp", 105, @error_message = @message OUT 		
		IF @message IS NOT NULL RAISERROR 	20111 @message 
		RETURN 		20111 	
	END 		
	
END

ELSE IF @convention_id = 4
BEGIN
	IF (@method_id = 7)
	OR 	(@method_id = 0)
	BEGIN 
		SELECT		@is_valid = 0
		EXEC 		amGetErrorMessage_sp 20115, "tmp/amvldcnv.sp", 118, @error_message = @message OUT 			
		IF @message IS NOT NULL RAISERROR 	20115 @message 
		RETURN 		20115 	
	END 	
END

ELSE IF @convention_id = 5
BEGIN
	IF (@method_id = 7)
	OR 	(@method_id = 0)
	BEGIN 
		SELECT		@is_valid = 0
		EXEC 		amGetErrorMessage_sp 20116, "tmp/amvldcnv.sp", 130, @error_message = @message OUT 			
		IF @message IS NOT NULL RAISERROR 	20116 @message 
		RETURN 		20116 	
	END 	
END

ELSE
BEGIN
	IF (@method_id = 1)
	OR (@method_id = 2)
	OR (@method_id = 3)
	OR (@method_id = 4)
	OR (@method_id = 5)
	BEGIN 
		SELECT		@is_valid = 0
		EXEC 		amGetErrorMessage_sp 20117, "tmp/amvldcnv.sp", 145, @error_message = @message OUT 		
		IF @message IS NOT NULL RAISERROR 	20117 @message 
		RETURN 		20117 	
	END 		
END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amvldcnv.sp" + ", line " + STR( 151, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amValidConvention_sp] TO [public]
GO
