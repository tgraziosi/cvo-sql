SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amGetEffectiveDate_sp] 
(
 @apply_date smApplyDate, 		 
	@trx_type 			smTrxType, 			 
	@convention_id 		smConventionID, 	 
	@effective_date 	smApplyDate OUTPUT,	 
	@debug_level		smDebugLevel	= 0	
)
AS 

DECLARE 
	@error 			smErrorCode,
	@midpoint_date 	smApplyDate,
	@effective_date_type smCounter 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ameffdt.sp" + ", line " + STR( 86, 5 ) + " -- ENTRY: "

IF @debug_level >= 5
	SELECT apply_date 		= @apply_date, 
			trx_type 		= @trx_type,
			convention_id 	= @convention_id 


SELECT @effective_date_type = effective_date_type 
FROM amtrxdef
WHERE trx_type = @trx_type

IF @effective_date_type = 1 
BEGIN 
	
	EXEC @error = amGetFullMonthDate_sp 
							@apply_date, 
							@effective_date OUT 
	IF (@error <> 0)
		RETURN @error 
		
END 

ELSE 
BEGIN  
	 
	EXEC @error = amGetConventionDate_sp @apply_date,
											@convention_id,
											@effective_date OUT 
	IF (@error <> 0)
		RETURN @error 

END 

IF @debug_level >= 3
	SELECT 	effective_date = @effective_date 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ameffdt.sp" + ", line " + STR( 125, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amGetEffectiveDate_sp] TO [public]
GO
