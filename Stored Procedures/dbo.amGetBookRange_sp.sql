SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amGetBookRange_sp] 
( 
	@co_trx_id 	 		smSurrogateKey, 		 
	@start_book 			smBookCode 		OUTPUT,  
	@end_book 				smBookCode		OUTPUT,	 	
	@debug_level			smDebugLevel 	= 0 	
)
AS 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ambkrng.sp" + ", line " + STR( 55, 5 ) + " -- ENTRY: "

SELECT	@start_book 	= NULL,
		@end_book		= NULL

SELECT	@start_book 	= ISNULL(from_code, "<Start>"),
		@end_book		= ISNULL(to_code, "<End>")
FROM	amdprcrt
WHERE	co_trx_id		= @co_trx_id
AND		field_type		= 8

IF @start_book IS NULL OR @start_book = ""
	SELECT @start_book = "<Start>"

IF @end_book IS NULL OR @end_book = ""
	SELECT @end_book = "<End>"

IF RTRIM(@start_book) = "<Start>"
BEGIN
	SELECT 	@start_book 	= MIN(book_code)
	FROM	ambook
END

IF RTRIM(@end_book) = "<End>"
BEGIN
	SELECT 	@end_book 		= MAX(book_code)
	FROM	ambook
END

IF @debug_level >= 4
	SELECT	start_book	= @start_book, 
			end_book	= @end_book

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ambkrng.sp" + ", line " + STR( 91, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amGetBookRange_sp] TO [public]
GO
