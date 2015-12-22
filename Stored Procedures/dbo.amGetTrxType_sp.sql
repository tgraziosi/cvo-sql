SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[amGetTrxType_sp] 
(
	@company_id			smCompanyID,				
	@trx_ctrl_num		smControlNumber,			
	@trx_type			smTrxType 		OUTPUT,		
	@debug_level		smDebugLevel 	= 0			
)
AS 

DECLARE
 	@result		smErrorCode,
	@message	smErrorLongDesc

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amgttxty.sp" + ", line " + STR( 61, 5 ) + " -- ENTRY: "

SELECT 	@trx_type 		= trx_type
FROM 	amtrxhdr
WHERE 	company_id		= @company_id
AND		trx_ctrl_num 	= @trx_ctrl_num

IF @@rowcount = 0
BEGIN
	
	EXEC	 	amGetErrorMessage_sp 20602, "tmp/amgttxty.sp", 73, @trx_ctrl_num, @error_message = @message OUTPUT 
 	IF @message IS NOT NULL RAISERROR 	20602 @message 
	RETURN 		20602
END

IF @debug_level >= 3
	SELECT "Trx Type = " + CONVERT(char(20), @trx_type)

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amgttxty.sp" + ", line " + STR( 81, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amGetTrxType_sp] TO [public]
GO
