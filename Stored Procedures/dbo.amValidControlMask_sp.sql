SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[amValidControlMask_sp] 
( 
	@control_mask 	smControlNumber, 	 
	@is_valid smLogical OUTPUT, 	 
	@debug_level	smDebugLevel	= 0	
)
AS 
 
DECLARE @last_letter int 
DECLARE @first_number int 
DECLARE @i int 
DECLARE @temp_str smControlNumber 
DECLARE @message smErrorLongDesc 
DECLARE @length int 
DECLARE @temp_mask smControlNumber
 
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amvldmsk.sp" + ", line " + STR( 109, 5 ) + " -- ENTRY: "

SELECT @is_valid = 1 
SELECT @last_letter = 0 
SELECT @i = 1 
SELECT @temp_str = @control_mask 
 
 
WHILE @i > 0 
BEGIN 
	SELECT @i = PATINDEX("%[a-zA-Z]%", @temp_str)
	IF @i > 0 
	BEGIN 
		SELECT @last_letter = @last_letter + @i 
		EXEC amStringLength_sp 
						@temp_str,
						@length OUT
		SELECT @temp_str = SUBSTRING(@temp_str, @i + 1, @length - @i)
	END 
END 

SELECT @first_number = PATINDEX("%[0#]%", @control_mask)
IF @first_number > 0 AND @last_letter > 0 
BEGIN 
 IF @first_number < @last_letter 
 BEGIN 
		EXEC amGetErrorMessage_sp 20040, "tmp/amvldmsk.sp", 135, @control_mask, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 20040 @message 
		SELECT @is_valid = 0 
 END 
END 
 
 
SELECT @temp_mask = RTRIM(@control_mask)
EXEC amStringLength_sp @temp_mask,
							@length OUT
IF @length - @first_number + 1 < 6 
BEGIN 
 EXEC amGetErrorMessage_sp 20041, "tmp/amvldmsk.sp", 147, @control_mask, @error_message =@message OUT 
 IF @message IS NOT NULL RAISERROR 20041 @message 
 SELECT @is_valid = 0 
END 
 
 
 
 
SELECT @i = PATINDEX("[^0A-Z#]%", UPPER(RTRIM(LTRIM(@control_mask))))
IF @i = 1 
BEGIN 
 EXEC amGetErrorMessage_sp 20042, "tmp/amvldmsk.sp", 158, @control_mask, @error_message =@message OUT 
 IF @message IS NOT NULL RAISERROR 20042 @message 
 SELECT @is_valid = 0 
END 
 
 
SELECT @i = PATINDEX("%[^0A-Z#]%", UPPER(RTRIM(LTRIM(@control_mask))))
IF @i > 1 
BEGIN 
 EXEC amGetErrorMessage_sp 20042, "tmp/amvldmsk.sp", 167, @control_mask, @error_message =@message OUT 
 IF @message IS NOT NULL RAISERROR 20042 @message 
 SELECT @is_valid = 0 
END 
 
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amvldmsk.sp" + ", line " + STR( 172, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amValidControlMask_sp] TO [public]
GO
