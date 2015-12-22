SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amGetCurrencyPrecision_sp] 
(
	@curr_precision 	smallint 	OUTPUT,		
	@rounding_factor 	float 		OUTPUT, 	
	@debug_level		smDebugLevel = 0		
)
AS 

DECLARE	@message	smErrorLongDesc

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amcurpre.sp" + ", line " + STR( 70, 5 ) + " -- ENTRY: "

SELECT 	@rounding_factor = NULL,
		@curr_precision = NULL 

SELECT 	@rounding_factor 	= m.rounding_factor,
		@curr_precision 	= m.curr_precision 
FROM 	glco g, CVO_Control..mccurr m 
WHERE 	g.home_currency 	= m.currency_code 

IF ( @curr_precision IS NULL )
BEGIN 
	EXEC 		amGetErrorMessage_sp 20022, "tmp/amcurpre.sp", 82, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20022 @message 
	RETURN 		20022 
END 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amcurpre.sp" + ", line " + STR( 87, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amGetCurrencyPrecision_sp] TO [public]
GO
