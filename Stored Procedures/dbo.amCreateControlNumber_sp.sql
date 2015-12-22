SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[amCreateControlNumber_sp] 
( 
	@control_mask 	smControlNumber,  
	@next_num 	smCounter,  
	@control_number 	smControlNumber OUTPUT,  
	@debug_level		smDebugLevel	= 0			
)
AS 
 
DECLARE 
	@first_zero int, 
	@first_hash int, 
	@start_num int, 
	@i int, 
	@num_length int, 
	@next_number smControlNumber, 
	@next_char 	char(1),
	@temp_length int,
	@temp_mask smControlNumber,
	@temp_next smControlNumber,
	@next_num_length int

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amctlnum.sp" + ", line " + STR( 118, 5 ) + " -- ENTRY: " 

 
SELECT @first_zero = charindex("0", @control_mask)
SELECT @first_hash = charindex("#", @control_mask)

IF @first_zero > 0 AND @first_hash > 0 
BEGIN 
 IF @first_zero > @first_hash 
	SELECT @start_num = @first_hash 
 ELSE 
	SELECT @start_num = @first_zero 
END 
ELSE IF @first_hash > 0 
 SELECT @start_num = @first_hash 
ELSE IF @first_zero > 0 
 SELECT @start_num = @first_zero 
ELSE 
 SELECT @start_num = 0 
 

 
IF @start_num > 0 
BEGIN 
 SELECT @control_number = SUBSTRING(@control_mask, 1, @start_num - 1)
	
	SELECT @temp_mask = RTRIM(@control_mask)
	IF	@temp_mask = "" 
		SELECT @temp_mask = NULL
		
	EXEC amStringLength_sp 
					@temp_mask,
					@temp_length OUT
 SELECT @num_length = @temp_length - @start_num + 1 
END 
ELSE 
BEGIN 
 SELECT @control_number = "" 
	
	SELECT @temp_mask = RTRIM(@control_mask)
	IF	@temp_mask = "" 
		SELECT @temp_mask = NULL
	
	EXEC amStringLength_sp 
					@temp_mask,
					@num_length OUT
END 
 
 
SELECT @next_number = CONVERT(char(16), @next_num)


SELECT @temp_next = RTRIM(@next_number)
IF	@temp_next = "" 
	SELECT @temp_next = NULL

EXEC amStringLength_sp 
				@temp_next,
				@next_num_length OUT

IF @next_num_length > @num_length 
	SELECT @control_number = RTRIM(@control_number) + 
								SUBSTRING(@next_number, @next_num_length - @num_length + 1, @num_length)
ELSE 
BEGIN 
 SELECT @i = 1 
 WHILE @i <= @num_length - @next_num_length
 BEGIN 
		SELECT @next_char = SUBSTRING(@control_mask, @start_num + @i - 1, 1)
		IF @next_char = "0" 
		BEGIN
		 SELECT @control_number = RTRIM(@control_number) + "0" 
		END
		SELECT @i = @i + 1 
	END 

	SELECT @control_number = RTRIM(@control_number) + @next_number 
END 

IF @debug_level >= 3
	SELECT	control_number 	= @control_number

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amctlnum.sp" + ", line " + STR( 202, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amCreateControlNumber_sp] TO [public]
GO
