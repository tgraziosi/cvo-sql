SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amValidateSummary_sp] 
(
	@rounding_factor	float,					
	@curr_precision		smallint,			
	@debug_level		smDebugLevel 	= 0		
)
AS 

DECLARE 
	@result 			smErrorCode,
	@message			smErrorLongDesc,
	@value 				float

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amvalsum.sp" + ", line " + STR( 103, 5 ) + " -- ENTRY: "


SELECT 	@value 		= (SIGN(ISNULL(SUM(amount), 0.0)) * ROUND(ABS(ISNULL(SUM(amount), 0.0)) + 0.0000001, @curr_precision))
FROM 	#amsumval

IF @debug_level > 3
	SELECT	"trx_total = " + CONVERT(char(40), ROUND(@value, 4))


IF (ABS((@value)-(0.0)) > 0.0000001)
BEGIN
 EXEC	 	amGetErrorMessage_sp 20608, "tmp/amvalsum.sp", 118, @error_message = @message OUTPUT 
 IF @message IS NOT NULL RAISERROR 	20608 @message 
	RETURN 		20608
END



SELECT 	@value 		= (SIGN(ISNULL(SUM(amount), 0.0)) * ROUND(ABS(ISNULL(SUM(amount), 0.0)) + 0.0000001, @curr_precision))
FROM 	#amsumactval

IF @debug_level > 3
	SELECT	"trx_total = " + CONVERT(char(40), ROUND(@value, 4))


IF (ABS((@value)-(0.0)) > 0.0000001)
BEGIN
 EXEC	 	amGetErrorMessage_sp 20608, "tmp/amvalsum.sp", 140, @error_message = @message OUTPUT 
 IF @message IS NOT NULL RAISERROR 	20608 @message 
	RETURN 		20608
END




IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amvalsum.sp" + ", line " + STR( 148, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amValidateSummary_sp] TO [public]
GO
