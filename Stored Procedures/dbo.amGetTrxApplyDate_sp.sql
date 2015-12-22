SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[amGetTrxApplyDate_sp] 
(	
 	@co_trx_id 			smSurrogateKey,			 
 	@apply_date			smApplyDate OUTPUT, 	
	@debug_level		smDebugLevel	= 0		
)
AS 

DECLARE 
	@message smErrorLongDesc,
	@param			smErrorParam

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amtrxdt.sp" + ", line " + STR( 55, 5 ) + " -- ENTRY: " 

SELECT 	@apply_date 	= apply_date 
FROM 	amtrxhdr 
WHERE 	co_trx_id 		= @co_trx_id 

IF @@rowcount = 0
BEGIN 
	SELECT	@param	= RTRIM(CONVERT(char(255), @co_trx_id))
	
	EXEC 		amGetErrorMessage_sp 20031, "tmp/amtrxdt.sp", 65, @param, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20031 @message 
	RETURN 		20031 
END 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amtrxdt.sp" + ", line " + STR( 70, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amGetTrxApplyDate_sp] TO [public]
GO
