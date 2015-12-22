SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[amStringLength_sp] 
( 
	@string			smControlNumber, 		 
	@length 	smCounter 	OUTPUT, 	 
	@debug_level	smDebugLevel	= 0		
)
AS 
 
DECLARE @temp_string varchar(32),
		@terminator varchar(32),
		@term_pattern varchar(32)

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amstrlen.sp" + ", line " + STR( 81, 5 ) + " -- ENTRY: "


SELECT @terminator = '$$$'
SELECT @temp_string = rtrim(@string) + @terminator


SELECT @term_pattern = '%' + @terminator + '%'
SELECT @length = PATINDEX(@term_pattern, @temp_string) - 1 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amstrlen.sp" + ", line " + STR( 91, 5 ) + " -- EXIT: "	
 
RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amStringLength_sp] TO [public]
GO
