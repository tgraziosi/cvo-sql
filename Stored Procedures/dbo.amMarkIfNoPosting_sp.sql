SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[amMarkIfNoPosting_sp] 
(
	@company_code		smCompanyCode,				
	@trx_type			smTrxType,					
	@process_ctrl_num	smProcessCtrlNum,			
 
	@debug_level		smDebugLevel 	= 0			
)

AS 

DECLARE
 	@result					smErrorCode,
	@company_id				smCompanyID,
	@post_additions			smLogical,
	@post_other_activities	smLogical,
	@post_to_gl				smLogical

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amifnpst.sp" + ", line " + STR( 94, 5 ) + " -- ENTRY: "

SELECT	@company_id		= company_id
FROM	glco
WHERE	company_code 	= @company_code

IF @trx_type = 50
BEGIN
	
	SELECT 	@post_to_gl 			= post_depreciation,
			@post_additions			= post_additions,
			@post_other_activities	= post_other_activities
	FROM 	amco
	WHERE 	company_id				= @company_id

END
ELSE 
BEGIN
	SELECT 	@post_to_gl 			= post_disposals,
			@post_additions			= post_additions,
			@post_other_activities	= post_other_activities
	FROM 	amco
	WHERE 	company_id				= @company_id
END


IF @post_to_gl = 0
BEGIN
	SELECT 	@post_to_gl 	= @post_other_activities

	IF @post_to_gl = 0
		SELECT 	@post_to_gl 	= @post_additions
END

IF @debug_level >= 3
	SELECT "Post To GL = " + CONVERT(char(20), @post_to_gl)
	

IF (@post_to_gl = 0)
BEGIN
	EXEC @result = amMarkTrxPosted_sp 
						@process_ctrl_num,
						@trx_type,
						@debug_level
	IF @result <> 0
		RETURN @result

	
END 


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amifnpst.sp" + ", line " + STR( 157, 5 ) + " -- EXIT: "

RETURN @post_to_gl
GO
GRANT EXECUTE ON  [dbo].[amMarkIfNoPosting_sp] TO [public]
GO
