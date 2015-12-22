SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amManual_sp] 
( 
	@co_asset_book_id 		smSurrogateKey, 		 
	@from_date 				smApplyDate, 			
	@to_date 				smApplyDate, 			
	@curr_precision			smallint,				
	@range_depr_expense 	smMoneyZero 	OUTPUT,	
	@debug_level			smDebugLevel 	= 0 	
)
AS 
	
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ammanual.sp" + ", line " + STR( 57, 5 ) + " -- ENTRY: "

DECLARE
	@message			smErrorLongDesc,			
	@asset_ctrl_num		smControlNumber,			
	@book_code			smBookCode,					
	@num_prds			smCounter,					
	@num_entered		smCounter,					
	@from_date_jul		smJulianDate,				
	@to_date_jul		smJulianDate,				
	@from_date_str		smErrorParam,				
	@to_date_str		smErrorParam				

IF @debug_level >= 5
SELECT	from_date 	= @from_date,
		to_date 	= @to_date 

SELECT 	@range_depr_expense = 0.0 

SELECT 	@range_depr_expense = (SIGN(ISNULL(SUM(depr_expense), 0.0)) * ROUND(ABS(ISNULL(SUM(depr_expense), 0.0)) + 0.0000001, @curr_precision))
FROM 	ammandpr 
WHERE 	co_asset_book_id 	= @co_asset_book_id 
AND 	fiscal_period_end 	>= @from_date 
AND 	fiscal_period_end 	<= @to_date 

IF @debug_level >= 2
	SELECT range_depr_expense = @range_depr_expense 


SELECT 	@from_date_jul 	= DATEDIFF(dd, "1/1/1980", @from_date) + 722815,
		@to_date_jul 	= DATEDIFF(dd, "1/1/1980", @to_date) + 722815,
		@num_prds 		= 0,
		@num_entered 	= 0

 
SELECT 	@num_prds 		= COUNT(timestamp)
FROM 	glprd 
WHERE 	period_end_date BETWEEN @from_date_jul AND @to_date_jul
					
 
SELECT 	@num_entered 		= COUNT(timestamp)
FROM 	ammandpr 
WHERE 	co_asset_book_id	= @co_asset_book_id
AND		fiscal_period_end 	BETWEEN @from_date AND @to_date

IF @debug_level >= 5
	SELECT 	num_prds 	= @num_prds,
			num_entered	= @num_entered 
	
IF @num_prds != @num_entered
BEGIN
	SELECT 	@from_date_str 	= RTRIM(CONVERT(char(255), @from_date, 107))
	SELECT 	@to_date_str 	= RTRIM(CONVERT(char(255), @to_date, 107))

	SELECT 	@asset_ctrl_num		= a.asset_ctrl_num,
			@book_code			= ab.book_code
	FROM	amasset a,
			amastbk ab,
			amOrganization_vw o 
	WHERE	a.co_asset_id		= ab.co_asset_id
	AND		ab.co_asset_book_id	= @co_asset_book_id
	AND     a.org_id  = o.org_id
	
	EXEC 		amGetErrorMessage_sp 
					26005, "tmp/ammanual.sp", 123, 
					@asset_ctrl_num, @book_code, @from_date_str, @to_date_str,
					@error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	26005 @message 
END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ammanual.sp" + ", line " + STR( 129, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amManual_sp] TO [public]
GO
