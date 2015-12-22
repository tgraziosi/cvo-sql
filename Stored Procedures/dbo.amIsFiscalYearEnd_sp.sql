SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amIsFiscalYearEnd_sp] 
(	
	@given_date smISODate, 			
	@valid smLogical OUTPUT, 	
	@debug_level	smDebugLevel = 0	
)
AS 

DECLARE 
	@message smErrorLongDesc, 
	@yr_end_date smApplyDate, 
	@apply_date smApplyDate, 
	@param1 smErrorParam, 
	@result			smErrorCode 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amfyrend.sp" + ", line " + STR( 56, 5 ) + " -- ENTRY: "
	
SELECT @apply_date 	= CONVERT(datetime, @given_date)
SELECT @valid 		= 0

EXEC @result = amGetFiscalYear_sp 
					@apply_date, 
					1, 
					@yr_end_date OUTPUT,
					@debug_level 

IF @result <> 0 
	RETURN @result
	
IF @apply_date <> @yr_end_date 
BEGIN
	SELECT 		@param1 = RTRIM(CONVERT(varchar(255), @apply_date, 107))

	EXEC 		amGetErrorMessage_sp 20043, "tmp/amfyrend.sp", 74, @param1, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20043 @message 
	RETURN 		20043 
END

SELECT @valid = 1 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amfyrend.sp" + ", line " + STR( 81, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amIsFiscalYearEnd_sp] TO [public]
GO
