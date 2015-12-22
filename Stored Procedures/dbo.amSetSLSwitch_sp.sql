SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amSetSLSwitch_sp] 
( 
	@co_asset_book_id smSurrogateKey, 	 
	@to_sl 				smLogical, 			
	@from_date 			smApplyDate,		
	@debug_level		smDebugLevel 	= 0 
)
AS 

DECLARE 
	@result			 	smErrorCode			 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amslswt.sp" + ", line " + STR( 65, 5 ) + " -- ENTRY: "

IF @to_sl = 1 
BEGIN 
	UPDATE 	amdprhst 
	SET 	switch_to_sl_date 	= @from_date 
	WHERE 	co_asset_book_id 	= @co_asset_book_id 
	AND 	effective_date 		= (SELECT 	MAX(effective_date)
									FROM 	amdprhst 
									WHERE 	co_asset_book_id 	= @co_asset_book_id 
									AND 	effective_date 	<= @from_date )
					 

	SELECT @result = @@error
	IF ( @result != 0 ) 
		RETURN @result 
END 

ELSE 
BEGIN 
	UPDATE 	amdprhst 
	SET 	switch_to_sl_date 	= NULL 
	WHERE 	co_asset_book_id 	= @co_asset_book_id 
	AND 	effective_date 		= (SELECT 	MAX(effective_date)
									FROM 	amdprhst 
									WHERE 	co_asset_book_id 	= @co_asset_book_id 
									AND 	effective_date 	<= @from_date ) 
	
	SELECT @result = @@error
	IF ( @result != 0 ) 
		RETURN @result 
END 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amslswt.sp" + ", line " + STR( 98, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amSetSLSwitch_sp] TO [public]
GO
