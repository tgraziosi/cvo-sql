SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amIsFiscalYearStart_sp] 
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

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amfyrstr.sp" + ", line " + STR( 56, 5 ) + " -- ENTRY: "
	
SELECT @apply_date 	= CONVERT(datetime, @given_date)
SELECT @valid 		= 0

EXEC @result = amGetFiscalYear_sp 
					@apply_date, 
					0, 
					@yr_end_date OUTPUT,
					@debug_level 

IF @result <> 0 
	RETURN @result
	
IF @apply_date <> @yr_end_date 
BEGIN
	SELECT 		@param1 = RTRIM(CONVERT(varchar(255), @apply_date, 107))

	EXEC 		amGetErrorMessage_sp 20044, "tmp/amfyrstr.sp", 74, @param1, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20044 @message 
	RETURN 		20044 
END

SELECT @valid = 1 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amfyrstr.sp" + ", line " + STR( 81, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amIsFiscalYearStart_sp] TO [public]
GO
