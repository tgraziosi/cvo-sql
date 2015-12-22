SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[amRecoverRetireDisposed_sp] 
( 
	@process_ctrl_num		smProcessCtrlNum,		
	@company_id				smCompanyID,			
	@user_id				smUserID,				
	@batch_size				smCounter		= 0,	
	@show_acct_msgs			smLogical		= 1,	
	@trx_ctrl_num			smControlNumber OUTPUT,	
	@debug_level			smDebugLevel	= 0		
)
AS 

DECLARE 
	@result		 			smErrorCode, 		
	@message 				smErrorLongDesc, 	
	@co_trx_id				smSurrogateKey,		
	@start_asset 			smControlNumber, 	 
	@end_asset 				smControlNumber		 	

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amrecret.sp" + ", line " + STR( 73, 5 ) + " -- ENTRY: "


SELECT dummy_select = 1



IF NOT EXISTS(SELECT name FROM tempdb..sysobjects WHERE name LIKE '##amcancel%' AND type = 'U')
	CREATE TABLE ##amcancel
	(	
		spid					int			
	
	)



EXEC @result = amGetTrxToRecover_sp 
				@process_ctrl_num,		
				@co_trx_id 		OUTPUT,
				@trx_ctrl_num	OUTPUT

IF @result = 20613
BEGIN
	
	EXEC @result = pctrlupd_sp @process_ctrl_num,3
	RETURN 0
END



IF @result <> 0 
	RETURN @result 


EXEC @result = pctrlchg_sp
					@process_ctrl_num

IF (@result <> 0)
BEGIN
	EXEC 		amGetErrorMessage_sp 20600, "tmp/amrecret.sp", 121, @process_ctrl_num, @error_message = @message OUT
	IF @message IS NOT NULL RAISERROR 	20600 @message
	RETURN 		20600
END




EXEC @result = amDoRetireDisposed_sp
						@co_trx_id,					
						@company_id,
						@batch_size,
						@show_acct_msgs,
						@debug_level	= @debug_level
IF 	(@result <> 0)
	RETURN @result 








IF EXISTS(SELECT name FROM tempdb..sysobjects WHERE name LIKE '##amcancel%' AND type = 'U')
BEGIN

	
 	BEGIN TRANSACTION

		DELETE ##amcancel
		WHERE spid = @@spid

		SELECT * 
		FROM ##amcancel

		IF @@rowcount = 0
			DROP TABLE ##amcancel

	COMMIT TRANSACTION
END


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amrecret.sp" + ", line " + STR( 153, 5 ) + " -- EXIT: " 

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amRecoverRetireDisposed_sp] TO [public]
GO
