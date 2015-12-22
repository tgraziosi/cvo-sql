SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amGetDeprYTD_sp] 
( 
	@co_asset_book_id 	smSurrogateKey, 	
	@from_date			smApplyDate,		
	@up_to_date 		smApplyDate, 		
	@curr_precision		smallint,			
	@ytd_depr 			smMoneyZero OUTPUT,	
	@debug_level		smDebugLevel 	= 0,
	@perf_level			smPerfLevel 	= 0	
)
AS 

DECLARE 
	@flag 	smControlNumber







DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amdprytd.sp" + ", line " + STR( 117, 5 ) + " -- ENTRY: "
SELECT @flag = CONVERT(char(16), @co_asset_book_id)
IF ( @perf_level >= 1 ) EXEC perf_sp @flag, "tmp/amdprytd.sp", 119, "Entry amGetDeprYTD_sp", @PERF_time_last OUTPUT

IF @debug_level >= 5
	SELECT 	from_date	= @from_date,
			up_to_date 	= @up_to_date 

SELECT	@ytd_depr 			= 0.0 


IF @up_to_date IS NOT NULL
BEGIN
	SELECT 	@ytd_depr 			= (SIGN(ISNULL(SUM(amount), 0.0)) * ROUND(ABS(ISNULL(SUM(amount), 0.0)) + 0.0000001, @curr_precision))
	FROM 	amvalues 
	WHERE 	co_asset_book_id 	= @co_asset_book_id
	AND		trx_type			= 50
	AND		account_type_id		= 5 
	AND 	apply_date 			BETWEEN @from_date AND @up_to_date 

	IF @debug_level >= 3
	BEGIN
		SELECT 	depr_ytd = @ytd_depr 
		SELECT "Subtracting disposed depr"
	END

	IF ( @perf_level >= 1 ) EXEC perf_sp @flag, "tmp/amdprytd.sp", 145, "Summed regular depreciation", @PERF_time_last OUTPUT
	
	SELECT 	@ytd_depr 			= (SIGN(@ytd_depr - ISNULL(SUM(disposed_depr), 0.0)) * ROUND(ABS(@ytd_depr - ISNULL(SUM(disposed_depr), 0.0)) + 0.0000001, @curr_precision))
	FROM 	amacthst 
	WHERE 	co_asset_book_id 	= @co_asset_book_id
	AND		trx_type			= 70
	AND 	apply_date 			BETWEEN @from_date AND @up_to_date 

END

IF @debug_level >= 3
	SELECT 	depr_ytd = @ytd_depr 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amdprytd.sp" + ", line " + STR( 158, 5 ) + " -- EXIT: "
IF ( @perf_level >= 1 ) EXEC perf_sp @flag, "tmp/amdprytd.sp", 159, "Exit amGetDeprYTD_sp", @PERF_time_last OUTPUT

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amGetDeprYTD_sp] TO [public]
GO
