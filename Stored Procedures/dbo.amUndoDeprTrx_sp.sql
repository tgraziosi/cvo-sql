SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amUndoDeprTrx_sp] 
( 
	@co_trx_id 	 	smSurrogateKey,		
	@debug_level		smDebugLevel = 0 	

)

AS 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amundptx.sp" + ", line " + STR( 64, 5 ) + " -- ENTRY: "

DECLARE 
	@error			smErrorCode,			
	@trx_ctrl_num	smControlNumber			


SELECT	@trx_ctrl_num	= trx_ctrl_num
FROM	amtrxhdr
WHERE	co_trx_id		= @co_trx_id


IF @debug_level >= 3
	SELECT "Deleting from amvalues"
	
DELETE	
FROM 	amvalues
WHERE	co_trx_id = @co_trx_id

SELECT @error = @@error
IF @error <> 0
	RETURN @error


IF @debug_level >= 3
	SELECT "Deleting from amastprf for existing assets"
	
DELETE	amastprf
FROM	amastprf	ap,
		amastbk		ab
WHERE	ap.co_asset_book_id 		= ab.co_asset_book_id
AND		ab.last_depr_co_trx_id 		= @co_trx_id
AND		ap.fiscal_period_end		> ab.prev_posted_depr_date
AND		ab.prev_posted_depr_date 	is not NULL

SELECT @error = @@error
IF @error <> 0
	RETURN @error



IF @debug_level >= 3
	SELECT "Creating temp table #asset_book"
	
SELECT 	co_asset_book_id,
		last_posted_activity_date
INTO 	#asset_book
FROM	amastbk		
WHERE	last_depr_co_trx_id 	= @co_trx_id
AND		prev_posted_depr_date IS NULL


IF @debug_level >= 3
	SELECT "Deleting from amastprf for new assets"
	
DELETE	amastprf
FROM	#asset_book	tmp,
		amastprf	ap
WHERE	ap.co_asset_book_id 		= tmp.co_asset_book_id

SELECT @error = @@error
IF @error <> 0
	RETURN @error


IF @debug_level >= 3
	SELECT "Updating ammandpr"
	
UPDATE	ammandpr 
SET		posting_flag 				= 0
FROM	#asset_book	tmp,
		ammandpr	md
WHERE	md.co_asset_book_id 		= tmp.co_asset_book_id

SELECT @error = @@error
IF @error <> 0
	RETURN @error


IF @debug_level >= 3
	SELECT "Updating ammandpr for previously depreciated assets"
	
UPDATE	ammandpr 
SET		posting_flag 				= 0
FROM	ammandpr	md,
		amastbk		ab
WHERE	md.co_asset_book_id 		= ab.co_asset_book_id
AND		ab.last_depr_co_trx_id 		= @co_trx_id
AND		md.fiscal_period_end		> ab.prev_posted_depr_date
AND		ab.prev_posted_depr_date 	is not NULL

SELECT @error = @@error
IF @error <> 0
	RETURN @error


IF @debug_level >= 3
	SELECT "Updating amdprhst"
	
UPDATE	amdprhst	
SET		posting_flag 				= 0
FROM	#asset_book	tmp,
		amdprhst	dh
WHERE	dh.co_asset_book_id 		= tmp.co_asset_book_id

SELECT @error = @@error
IF @error <> 0
	RETURN @error


IF @debug_level >= 3
	SELECT "Updating amdprhst for previously depreciated assets"
	
UPDATE	amdprhst 
SET		posting_flag 				= 0
FROM	amdprhst	dh,
		amastbk		ab
WHERE	dh.co_asset_book_id 		= ab.co_asset_book_id
AND		ab.last_depr_co_trx_id 		= @co_trx_id
AND		dh.effective_date			> ab.prev_posted_depr_date
AND		ab.prev_posted_depr_date 	is not NULL

SELECT @error = @@error
IF @error <> 0
	RETURN @error


IF @debug_level >= 3
	SELECT "Updating amtrxhdr"
	
UPDATE	amtrxhdr 					
SET		posting_flag 				= 0,
		journal_ctrl_num			= ""
FROM	amtrxhdr
WHERE	journal_ctrl_num 			= @trx_ctrl_num
AND		posting_flag 				= 100

SELECT @error = @@error
IF @error <> 0
	RETURN @error


IF @debug_level >= 3
	SELECT "Updating amacthst"
	
UPDATE	amacthst 					
SET		delta_cost					= 0.0,
		delta_accum_depr			= 0.0,
		revised_cost				= 0.0,
		revised_accum_depr			= 0.0,
		posting_flag 				= 0,
		journal_ctrl_num			= ""
FROM	amacthst
WHERE	journal_ctrl_num 			= @trx_ctrl_num
AND		posting_flag 				= 100

SELECT @error = @@error
IF @error <> 0
	RETURN @error

	


IF @debug_level >= 3
	SELECT "Updating amastbk"
	
UPDATE	amastbk	 
SET		last_posted_depr_date		= prev_posted_depr_date,
		prev_posted_depr_date		= NULL,
		last_depr_co_trx_id			= 0
WHERE	last_depr_co_trx_id			= @co_trx_id

SELECT @error = @@error
IF @error <> 0
	RETURN @error

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amundptx.sp" + ", line " + STR( 285, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amUndoDeprTrx_sp] TO [public]
GO
