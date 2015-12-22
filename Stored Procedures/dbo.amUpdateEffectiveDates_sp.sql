SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amUpdateEffectiveDates_sp] 
( 
	@co_asset_book_id	 	smSurrogateKey, 
	@placed_date			smApplyDate,		
	@debug_level		 	smDebugLevel = 0 	
)
AS 

DECLARE 
	@result		 			smErrorCode, 
	@acquisition_date		smApplyDate,		
	@yr_end_date 			smApplyDate,		 
	@jul_yr_end_date 		smJulianDate		 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amupefdt.sp" + ", line " + STR( 65, 5 ) + " -- ENTRY: "

IF @debug_level >= 3
	SELECT 	co_asset_book_id 	= @co_asset_book_id,
			acquisition_date 	= @acquisition_date,
			placed_date			= @placed_date 

EXEC @result = amGetFiscalYear_sp 
				 @placed_date, 	 
				 1,					
				 @yr_end_date OUTPUT 

IF @result <> 0 
	RETURN @result 

SELECT	@jul_yr_end_date = DATEDIFF(dd, "1/1/1980", @yr_end_date) + 722815

SELECT	@acquisition_date	= a.acquisition_date
FROM	amasset a,
		amastbk ab
WHERE	ab.co_asset_book_id = @co_asset_book_id
AND		ab.co_asset_id 		= a.co_asset_id


UPDATE 	amacthst 
SET 	effective_date 		= @acquisition_date 
WHERE 	co_asset_book_id 	= @co_asset_book_id
AND		apply_date			<= @yr_end_date 
AND		trx_type			!= 30

SELECT @result = @@error
IF @result <> 0 
	RETURN @result 


UPDATE 	amacthst 
SET 	effective_date 		= DATEADD(dd, prd.period_start_date - 722815, "1/1/1980")
FROM	amacthst 	ah,
		glprd		prd 
WHERE 	ah.co_asset_book_id 	= @co_asset_book_id
AND		ah.apply_date			> @yr_end_date 
AND		trx_type				!= 30
AND		prd.period_start_date 	= (SELECT	MAX(period_start_date)
									FROM	glprd
									WHERE 	period_start_date	<= DATEDIFF(dd, "1/1/1980", ah.apply_date) + 722815	
									AND		period_end_date		>= DATEDIFF(dd, "1/1/1980", ah.apply_date) + 722815)

SELECT @result = @@error
IF @result <> 0 
	RETURN @result 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amupefdt.sp" + ", line " + STR( 122, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amUpdateEffectiveDates_sp] TO [public]
GO
