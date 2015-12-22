SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amRecoverDepr_sp] 
( 
	@process_ctrl_num		smProcessCtrlNum,			
	@company_id				smCompanyID,				
	@recover_backwards		smLogical		= 1,		
	@batch_size				smCounter		= 0,		
	@show_acct_msgs			smLogical		= 1,		
	@trx_ctrl_num			smControlNumber OUTPUT,		
	@debug_level			smDebugLevel 	= 0 		
)
AS 

DECLARE 
	@result		 			smErrorCode, 		
	@message 				smErrorLongDesc, 	
	@co_trx_id				smSurrogateKey,		
	@start_book 			smBookCode, 		 
	@end_book 				smBookCode			 	

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amrecdpr.sp" + ", line " + STR( 76, 5 ) + " -- ENTRY: "


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
	RETURN 	@result



IF @recover_backwards = 0
BEGIN
	
	EXEC @result = amGetBookRange_sp 
						@co_trx_id,
						@start_book 	OUTPUT,
						@end_book		OUTPUT

	IF @result <> 0 
		RETURN @result 

END

IF @recover_backwards = 0
BEGIN
	
	EXEC @result = pctrlchg_sp
						@process_ctrl_num

	IF (@result <> 0)
	BEGIN
		EXEC 		amGetErrorMessage_sp 20600, "tmp/amrecdpr.sp", 142, @process_ctrl_num, @error_message = @message OUT
		IF @message IS NOT NULL RAISERROR 	20600 @message
		RETURN 		20600
	END

	
	EXEC @result = amDepreciate_sp
						@co_trx_id, 	 
						@company_id, 	
						@start_book,
						@end_book,
						1, 			
						@batch_size,
						@show_acct_msgs,
						@debug_level			

	IF ( @result <> 0 )
		RETURN 	@result 

	
	EXEC @result = amEndDeprProcess_sp
						@company_id,
						@co_trx_id,
						1,
						-100,
						100,
						@process_ctrl_num
	IF @result <> 0
		RETURN @result
END
ELSE
BEGIN

	
	EXEC @result = pctrlchg_sp
						@process_ctrl_num,
						2

	IF (@result <> 0)
	BEGIN
		EXEC 		amGetErrorMessage_sp 20600, "tmp/amrecdpr.sp", 196, @process_ctrl_num, @error_message = @message OUT
		IF @message IS NOT NULL RAISERROR 	20600 @message
		RETURN 		20600
	END
	
	
	EXEC @result = amChangeTrxState_sp 
						@co_trx_id,
						@process_ctrl_num,
						-100,
						@process_ctrl_num,
						-101,
						@debug_level		
	
	
	
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

END




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

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amrecdpr.sp" + ", line " + STR( 246, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amRecoverDepr_sp] TO [public]
GO
