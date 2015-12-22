SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amFirstCalcInYear_sp] 
( 	
	@from_date 			smApplyDate, 	 	 
	@first_time 		smLogical OUTPUT, 	
	@debug_level		smDebugLevel 	= 0 
)
AS 

DECLARE 
	@result			 	smErrorCode, 
	@yr_start_date 		smApplyDate 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amfstclc.sp" + ", line " + STR( 56, 5 ) + " -- ENTRY: "

IF @debug_level >= 5
	SELECT from_date = @from_date 

EXEC @result = amGetFiscalYear_sp 
						@from_date,
						0,
						@yr_start_date OUTPUT 

IF ( @result != 0 )
	RETURN @result

IF @from_date = @yr_start_date 
	SELECT @first_time = 1 
ELSE 
	SELECT @first_time = 0 

IF @debug_level >= 3
	SELECT first_time = @first_time 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amfstclc.sp" + ", line " + STR( 77, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amFirstCalcInYear_sp] TO [public]
GO
