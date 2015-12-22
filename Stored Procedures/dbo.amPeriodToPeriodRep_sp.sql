SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[amPeriodToPeriodRep_sp] 
( 
	@co_asset_book_id 		smSurrogateKey, 
	@col_nr					tinyint,
	@fiscal_period_start 	smApplyDate, 
	@fiscal_period_end 		smApplyDate,
	@curr_precision			smallint,			
	@asset_val 			 smMoneyZero OUTPUT,	
	@asset_total_val 		smMoneyZero OUTPUT,
	@accum_val 				smMoneyZero OUTPUT, 
	@depr_total_val 		smMoneyZero OUTPUT,									
	@debug_level		smDebugLevel = 0 				
) 
AS 

DECLARE 
	@trx_type				smTrxType,
	@rowcount 				smCounter, 
	@result 				smErrorCode,
	@value 	 				smMoneyZero 
		
		
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ampdrep.sp" + ", line " + STR( 90, 5 ) + " -- ENTRY: "
			
	
WHILE (1=1)
BEGIN

	SET ROWCOUNT 1 

	 
	SELECT 	@trx_type		= trx_type				 
	FROM 	#amtrxdef
	WHERE prd_to_prd_column = @col_nr
	AND 	col_flag = 0

	
	IF @@rowcount = 0 
	BEGIN 
		SET ROWCOUNT 0 
		BREAK 
	END

	SET ROWCOUNT 0

	EXEC @result = amGetValueRep_sp 
						@co_asset_book_id,
						0,
			 			@fiscal_period_start,
			 			@fiscal_period_end,
						@trx_type,
						@curr_precision,
						@value 		OUTPUT 

	IF ( @result != 0 )
		RETURN @result 

	SELECT @asset_val = (SIGN(@asset_val + isnull(@value,0.0)) * ROUND(ABS(@asset_val + isnull(@value,0.0)) + 0.0000001, @curr_precision))
	SELECT @asset_total_val = (SIGN(@asset_total_val + isnull(@value,0.0)) * ROUND(ABS(@asset_total_val + isnull(@value,0.0)) + 0.0000001, @curr_precision))


	 

	EXEC @result = amGetValueRep_sp 
							@co_asset_book_id,
							1,
				 			@fiscal_period_start,
				 			@fiscal_period_end,
							@trx_type,
							@curr_precision,
							@value output 

	IF ( @result != 0 )
		RETURN @result 

	IF isnull(@value,0.0) = 0.0
		SELECT @accum_val = (SIGN(@accum_val + isnull(@value,0.0)) * ROUND(ABS(@accum_val + isnull(@value,0.0)) + 0.0000001, @curr_precision))
	ELSE
		SELECT @accum_val = (SIGN(@accum_val - isnull(@value,0.0)) * ROUND(ABS(@accum_val - isnull(@value,0.0)) + 0.0000001, @curr_precision))

	SELECT @depr_total_val = (SIGN(@depr_total_val - isnull(@value,0.0)) * ROUND(ABS(@depr_total_val - isnull(@value,0.0)) + 0.0000001, @curr_precision))


	UPDATE #amtrxdef
	SET col_flag = 1
	WHERE trx_type = @trx_type

END	

 



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ampdrep.sp" + ", line " + STR( 163, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amPeriodToPeriodRep_sp] TO [public]
GO
