SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amPrepareSummary_sp] 
(
	@trx_type			smTrxType,				
	@debug_level		smDebugLevel 	= 0		
)
AS 

DECLARE 
	@result 			smErrorCode,
	@curr_precision		smallint,			
	@rounding_factor 	float				

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amprpsum.sp" + ", line " + STR( 58, 5 ) + " -- ENTRY: "

EXEC	@result = amGetCurrencyPrecision_sp
					@curr_precision		OUTPUT,
					@rounding_factor 	OUTPUT

IF @result <> 0
	RETURN @result


EXEC @result = amSummariseTrx_sp
					@trx_type,
					@rounding_factor,
					@curr_precision,
					@debug_level

IF @result <> 0
	RETURN @result


EXEC @result = amValidateSummary_sp
					@rounding_factor,
					@curr_precision,
					@debug_level

IF @result <> 0
	RETURN @result

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amprpsum.sp" + ", line " + STR( 90, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amPrepareSummary_sp] TO [public]
GO
