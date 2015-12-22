SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[imCreateProfile_sp] 
( 	
	@co_asset_book_id 	smSurrogateKey, 
	@profile_date 	smApplyDate, 
	@cost 					smMoneyZero 	= 0,
	@accum_depr 			smMoneyZero 	= 0,
	@debug_level			smDebugLevel	= 0	
) 
AS 

DECLARE 
 	@effective_date 		smApplyDate, 
	@result 				smErrorCode 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imcreprf.sp" + ", line " + STR( 67, 5 ) + " -- ENTRY: "

IF @debug_level	>= 5
	SELECT * FROM #imastprf

IF EXISTS(SELECT co_asset_book_id 
			FROM 	#imastprf
			WHERE 	co_asset_book_id 	= @co_asset_book_id
			AND		fiscal_period_end	= @profile_date)
BEGIN
	IF @debug_level	>= 5
		SELECT 	"Updating existing profile" 

	
	UPDATE #imastprf 
	SET
			current_cost		= @cost,
			accum_depr			= @accum_depr
	FROM	#imastprf
	WHERE 	co_asset_book_id 	= @co_asset_book_id
	AND		fiscal_period_end	= @profile_date

	SELECT @result = @@error
	IF ( @result <> 0 ) 
		 RETURN @result 
END
ELSE
BEGIN
	IF @debug_level	>= 5
		SELECT 	"Adding new profile" 

	 
	SELECT @effective_date 	= MAX(effective_date)
	FROM 	amdprhst 
	WHERE 	co_asset_book_id 	= @co_asset_book_id 
	AND 	effective_date 		<= @profile_date 

	INSERT into #imastprf 
	( 
		co_asset_book_id,
		fiscal_period_end,
		current_cost,
		accum_depr,
		effective_date
	)
	VALUES 
	( 
		@co_asset_book_id,
		@profile_date,
		@cost, 
		@accum_depr, 
		@effective_date
	)

	SELECT @result = @@error
	IF ( @result <> 0 ) 
		 RETURN @result 
END

IF @debug_level	>= 5
	SELECT * FROM #imastprf

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imcreprf.sp" + ", line " + STR( 134, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[imCreateProfile_sp] TO [public]
GO
