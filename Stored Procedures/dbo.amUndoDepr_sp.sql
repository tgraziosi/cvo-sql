SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amUndoDepr_sp] 
( 
	@co_trx_id 	smSurrogateKey, 	 
	@company_id			smCompanyID,		
	@company_code		smCompanyCode,		
	@user_id			smUserID,			
	@debug_level		smDebugLevel	= 0	
)
AS 

DECLARE 
	@process_ctrl_num smProcessCtrlNum,
	@result			 	smErrorCode,
	@rowcount			smCounter,
	@message			smErrorLongDesc

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amunddpr.sp" + ", line " + STR( 60, 5 ) + " -- ENTRY: "

EXEC @result = amStartDeprProcess_sp
						@co_trx_id,					
						@user_id,					
						@company_id,				
						@company_code,				
						1,
						100,
						-101,
						2,
						@process_ctrl_num OUTPUT	
IF ( @result <> 0 )
 	RETURN 	@result 



EXEC @result = amUndoDeprTrx_sp
					@co_trx_id
IF @result <> 0
BEGIN
	
	RETURN @result
END


EXEC @result = amEndDeprProcess_sp
					@company_id,
					@co_trx_id,
					1,
					-101,
					0,
					@process_ctrl_num,
					NULL				
IF @result <> 0
	RETURN @result


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amunddpr.sp" + ", line " + STR( 105, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amUndoDepr_sp] TO [public]
GO
