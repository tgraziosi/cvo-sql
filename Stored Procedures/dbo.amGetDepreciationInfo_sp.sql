SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amGetDepreciationInfo_sp] 
(
 @co_asset_book_id smSurrogateKey, 		
	@apply_date 		smApplyDate, 			
 @method_id 			smDeprMethodID OUTPUT, 
 @convention_id 		smConventionID OUTPUT,	
	@debug_level		smDebugLevel 	= 0		
)
AS 

DECLARE 
	@message smErrorLongDesc,
	@rowcount		smCounter
				 
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amdprinf.sp" + ", line " + STR( 52, 5 ) + " -- ENTRY: "

SELECT @method_id 	= r.depr_method_id,
		@convention_id		= r.convention_id 
FROM amdprhst h, 
		amdprrul r 
WHERE h.co_asset_book_id 	= @co_asset_book_id 
AND 	h.effective_date 	= (SELECT MAX(effective_date)
								FROM 	amdprhst 
								WHERE 	co_asset_book_id 	= 	@co_asset_book_id 
								AND 	effective_date 		<= 	@apply_date)
AND h.depr_rule_code = r.depr_rule_code 

SELECT @rowcount = @@rowcount

IF @rowcount = 0 
BEGIN 
	DECLARE	@date_param 	smErrorParam,
			@asset_ctrl_num	smControlNumber,
			@book_code		smBookCode
			
	SELECT	@date_param = CONVERT(char(255), @apply_date)

	SELECT	@book_code			= ab.book_code,
			@asset_ctrl_num		= a.asset_ctrl_num
	FROM	amasset	a,
			amastbk ab,
			amOrganization_vw o
	WHERE	ab.co_asset_book_id	= @co_asset_book_id
	AND		ab.co_asset_id		= a.co_asset_id
	AND     a.org_id       = o.org_id

	EXEC 		amGetErrorMessage_sp 20023, "tmp/amdprinf.sp", 82, @asset_ctrl_num, @book_code, @date_param, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20023 @message 
	RETURN 		20023 
END 

IF @debug_level >= 4
	SELECT 	method_id 		= @method_id,
			convention_id 	= @convention_id 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amdprinf.sp" + ", line " + STR( 91, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amGetDepreciationInfo_sp] TO [public]
GO
