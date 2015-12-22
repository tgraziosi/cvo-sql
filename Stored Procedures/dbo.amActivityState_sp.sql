SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amActivityState_sp] 
(
	@co_trx_id 	 		smSurrogateKey,			
	@co_asset_book_id	smSurrogateKey,			
	@any_book_posted	smLogical		OUTPUT,	
	@all_books_posted	smLogical		OUTPUT,	
	@gl_book_posted		smLogical		OUTPUT,	
	@debug_level		smDebugLevel 	= 0		
)
AS 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amactstt.sp" + ", line " + STR( 52, 5 ) + " -- ENTRY: "


IF EXISTS(SELECT 	posting_flag
			FROM	amacthst
			WHERE	co_trx_id		= @co_trx_id
			AND		posting_flag	!= 0)
BEGIN
	SELECT	@any_book_posted 	= 1,
			@gl_book_posted		= 0

	IF EXISTS(SELECT	co_asset_book_id
				FROM	amacthst
				WHERE	co_trx_id		= @co_trx_id
				AND		posting_flag	= 0)
		SELECT	@all_books_posted 	= 0	 
	ELSE
		SELECT	@all_books_posted 	= 1

	
	IF EXISTS(SELECT 	posting_flag
				FROM	amacthst
				WHERE	co_trx_id			= @co_trx_id
				AND		co_asset_book_id	= @co_asset_book_id
				AND		posting_flag		!= 0)
		SELECT 	@gl_book_posted	 	= 1
	ELSE
		SELECT 	@gl_book_posted	 	= 1
	

END			
ELSE
BEGIN
	
	SELECT	@any_book_posted 	= 0,
			@gl_book_posted 	= 0,
			@all_books_posted 	= 0
END			

IF @debug_level >= 3
	SELECT	any_book_posted 	= @any_book_posted,
			gl_book_posted	 	= @gl_book_posted,
			all_books_posted 	= @all_books_posted

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amactstt.sp" + ", line " + STR( 102, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amActivityState_sp] TO [public]
GO
