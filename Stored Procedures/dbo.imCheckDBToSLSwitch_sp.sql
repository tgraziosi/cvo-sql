SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[imCheckDBToSLSwitch_sp] 
(
	@co_asset_book_id 		smSurrogateKey,		
	@acquisition_date		smApplyDate,		
	@curr_yr_start_date		smApplyDate,		
	@curr_precision			smallint,			
	@debug_level			smDebugLevel	= 0	
)
AS 

DECLARE @result	 		smErrorCode, 
		@message 			smErrorLongDesc,
		@effective_date		smApplyDate,
		@prev_yr_end_date	smApplyDate,
		@switch_to_sl_date	smApplyDate,
		@end_life_date		smApplyDate,
		@depr_method_id		smDeprMethodID,
		@current_cost		smMoneyZero,
		@accum_depr			smMoneyZero,
		@basis				smMoneyZero,
		@db_depr_expense	smMoneyZero,
		@sl_depr_expense	smMoneyZero,
		@service_life 		smLife, 
		@annual_rate 		smRate, 
		@depr_rate 			smRate, 
		@rate 				smRate,
		@days_remaining 	smCounter,
		@days_in_year		smCounter

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imchdbsl.sp" + ", line " + STR( 99, 5 ) + " -- ENTRY: "


IF @acquisition_date < @curr_yr_start_date
BEGIN
	IF @debug_level >= 3
		SELECT 	"Asset is acquired before the start of this fiscal year: must check db to sl rule" 

	SELECT	@prev_yr_end_date = DATEADD(dd, -1, @curr_yr_start_date)

	
	SELECT	@effective_date		= MAX(effective_date)
	FROM	amdprhst
	WHERE	co_asset_book_id	= @co_asset_book_id
	AND		effective_date		<= @curr_yr_start_date
		
	
	SELECT	@end_life_date		= dh.end_life_date,
			@depr_method_id		= dr.depr_method_id,
			@rate				= dr.annual_depr_rate,
			@service_life 	= dr.service_life 
	FROM	amdprhst	dh,
			amdprrul	dr
	WHERE	dh.co_asset_book_id	= @co_asset_book_id
	AND		dh.effective_date	= @effective_date
	AND		dh.depr_rule_code	= dr.depr_rule_code

	IF @depr_method_id = 5
	BEGIN
		IF @debug_level >= 3
			SELECT 	"Method is DB to SL" 

		SELECT	@current_cost 		= current_cost,
				@accum_depr			= accum_depr
		FROM	amastprf	
		WHERE	co_asset_book_id	= @co_asset_book_id
		AND		fiscal_period_end	= @prev_yr_end_date

		IF @@rowcount = 0 
		BEGIN
			
			SELECT	@current_cost 		= current_cost,
					@accum_depr			= accum_depr
			FROM	#imastprf	
			WHERE	co_asset_book_id	= @co_asset_book_id
			AND		fiscal_period_end	= @prev_yr_end_date
			
		END

		IF @debug_level >= 3
			SELECT	cost 		= @current_cost,
					accum_depr	= @accum_depr 
 
		
		SELECT @basis = (SIGN(@current_cost + @accum_depr) * ROUND(ABS(@current_cost + @accum_depr) + 0.0000001, @curr_precision)) 
		 
		
		IF @service_life !=0 
			SELECT @depr_rate = @rate / (100 * @service_life)
		ELSE 

			SELECT @depr_rate = @rate / 100 

		SELECT @db_depr_expense = (SIGN(@basis * @depr_rate) * ROUND(ABS(@basis * @depr_rate) + 0.0000001, @curr_precision)) 
		
		
		SELECT 	@days_remaining = datediff(day, @curr_yr_start_date, @end_life_date) + 1 
		SELECT 	@days_in_year 	= 365 		 


		IF @days_remaining != 0
			SELECT @sl_depr_expense= (SIGN((@basis * @days_in_year) / @days_remaining) * ROUND(ABS((@basis * @days_in_year) / @days_remaining) + 0.0000001, @curr_precision)) 
		ELSE
		 SELECT @sl_depr_expense = @basis
		

		IF @debug_level >= 3
			SELECT	db_depr_expense = @db_depr_expense,
					sl_depr_expense	= @sl_depr_expense 

		
		IF @sl_depr_expense > @db_depr_expense
			SELECT @switch_to_sl_date = @curr_yr_start_date
		ELSE
			SELECT @switch_to_sl_date = NULL

		IF @debug_level >= 3
			SELECT	switch_to_sl_date = @switch_to_sl_date
 
		UPDATE	amdprhst
		SET		switch_to_sl_date 	= @switch_to_sl_date
		FROM	amdprhst
		WHERE	co_asset_book_id 	= @co_asset_book_id
		AND		effective_date		= @effective_date

		SELECT @result = @@error
		IF ( @result <> 0 )
			RETURN @result 
		
	END
END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imchdbsl.sp" + ", line " + STR( 219, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[imCheckDBToSLSwitch_sp] TO [public]
GO
