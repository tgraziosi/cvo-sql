SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amUseFirstYearMethod_sp] 
( 
	@from_date 			smApplyDate, 			
	@placed_date		smApplyDate,			
	@use_first 			smLogical 		OUTPUT, 
	@debug_level		smDebugLevel 	= 0 	
)
AS 

DECLARE 
	@result			 	smErrorCode, 			
	@yr_end_date 		smApplyDate 			

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amusefst.sp" + ", line " + STR( 54, 5 ) + " -- ENTRY: "

IF @debug_level >= 5
	SELECT from_date	= @from_date 

 
EXEC @result = amGetFiscalYear_sp 	
						@placed_date,
						1,
						@yr_end_date OUTPUT 

IF ( @result != 0 )
	RETURN @result

 
IF @from_date <= @yr_end_date 
	SELECT @use_first = 1 
ELSE 
	SELECT @use_first = 0 

IF @debug_level >= 3
	SELECT use_first = @use_first 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amusefst.sp" + ", line " + STR( 81, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amUseFirstYearMethod_sp] TO [public]
GO
