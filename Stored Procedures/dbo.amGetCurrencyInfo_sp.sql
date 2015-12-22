SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[amGetCurrencyInfo_sp] 
(
	@symbol 			smGenericCode OUTPUT,	 	
	@currency_mask 		smCurrencyMask 	OUTPUT,		
	@curr_precision 	smallint 	OUTPUT,		
	@debug_level		smDebugLevel	= 0			
)
AS 

DECLARE @rowcount 	smCounter, 
		@error 		smErrorCode,
		@message 	smErrorLongDesc

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amcurinf.sp" + ", line " + STR( 62, 5 ) + " -- ENTRY: "

SELECT 	@symbol 	= NULL,
		@currency_mask 	= NULL,
		@curr_precision = NULL 


SELECT 	@currency_mask = m.currency_mask,
		@symbol = m.symbol,
		@curr_precision = m.curr_precision 
FROM 	glco g, CVO_Control..mccurr m 
WHERE 	g.home_currency = m.currency_code 

SELECT @error = @@error, @rowcount = @@rowcount 

IF @rowcount = 0  
BEGIN 
	EXEC 		amGetErrorMessage_sp 20022, "tmp/amcurinf.sp", 79, @error_message = @message out 
	IF @message IS NOT NULL RAISERROR 	20022 @message 
	RETURN 		20022 
END 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amcurinf.sp" + ", line " + STR( 84, 5 ) + " -- EXIT: "

RETURN @error 
GO
GRANT EXECUTE ON  [dbo].[amGetCurrencyInfo_sp] TO [public]
GO
