SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amIsFiscalStart_sp] 
(	
	@given_date smISODate, 			
	@valid smLogical OUTPUT, 	
	@debug_level	smDebugLevel	= 0	
)
AS 

DECLARE 
	@message smErrorLongDesc, 
	@yr_start_date smApplyDate, 
	@apply_date smApplyDate, 
	@param1 smErrorParam, 
	@ret_status smErrorCode 

	
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amfistar.sp" + ", line " + STR( 68, 5 ) + " -- ENTRY: "

SELECT @apply_date 	= CONVERT(datetime, @given_date)
SELECT @valid 		= 0 

EXEC @ret_status = amGetFiscalPeriod_sp 
					@apply_date, 
					0, 
					@yr_start_date OUTPUT 

IF @ret_status != 0
	RETURN @ret_status

IF @apply_date <> @yr_start_date 
BEGIN 
	SELECT 		@param1 = RTRIM(CONVERT(varchar(255), @apply_date, 107))
	EXEC 		amGetErrorMessage_sp 20034, "tmp/amfistar.sp", 84, @param1, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20034 @message 
	RETURN 	20034 
END 

SELECT @valid = 1

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amfistar.sp" + ", line " + STR( 91, 5 ) + " -- EXIT: "
 
RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amIsFiscalStart_sp] TO [public]
GO
