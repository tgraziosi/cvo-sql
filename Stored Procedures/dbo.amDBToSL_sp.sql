SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amDBToSL_sp] 
( 	
	@co_asset_book_id smSurrogateKey, 	 
	@from_date 			smApplyDate, 		
	@convention_id		smConventionID,		
	@salvage_value 		smMoneyZero, 		
	@use_addition_info 	smLogical,			
	@acquisition_date	smApplyDate, 		
	@placed_date		smApplyDate,		
	@do_post 			smLogical, 			
	@curr_precision		smallint,			
	@depr_expense 		smMoneyZero OUTPUT,	
	@debug_level		smDebugLevel 	= 0,
	@perf_level			smPerfLevel 	= 0	
)
AS 

DECLARE 
	@result				smErrorCode, 
	@db_depr 			smMoneyZero, 
	@first_calc 		smLogical, 
	@sl_date 			smApplyDate, 
	@sl_depr 			smMoneyZero 







DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amdbtosl.sp" + ", line " + STR( 87, 5 ) + " -- ENTRY: "
IF ( @perf_level >= 1 ) EXEC perf_sp "", "tmp/amdbtosl.sp", 88, "Entry amDBToSL_sp", @PERF_time_last OUTPUT

IF @use_addition_info = 1 
BEGIN  
	IF @debug_level >= 3
		SELECT "First year - use DB"

	 
	EXEC @result = amDB_sp 
							@co_asset_book_id,
							@from_date,
							@convention_id,
							0,		
							@use_addition_info,
							@acquisition_date,
							@placed_date,
							@curr_precision,
							@depr_expense 	OUTPUT,
							@debug_level,
							@perf_level 

	IF ( @result != 0 )
		RETURN @result 

END  

ELSE 
BEGIN  
	 
	EXEC @result = amGetSwitchToSL_sp 
							@co_asset_book_id,
							@from_date,
							@sl_date 	OUTPUT,
							@debug_level 

	IF ( @result != 0 )
		RETURN @result
		 
	IF @sl_date IS NOT NULL 
	BEGIN 

		IF @debug_level >= 3
			SELECT "Switch already done"

		EXEC @result = amSLSpecifiedLife_sp 
								@co_asset_book_id,
								@from_date,
								@convention_id,
								0,		
								@use_addition_info,
								@acquisition_date,
								@placed_date,
								@curr_precision,
								@sl_depr 	OUTPUT,
								@debug_level,
								@perf_level 
 

		IF ( @result != 0 )
			RETURN @result 

		SELECT @depr_expense = @sl_depr 

		IF @debug_level >= 3
			SELECT 	sl_depr = @sl_depr

	END
	ELSE 
	BEGIN
		
		
		 
		EXEC @result = amFirstCalcInYear_sp 
								@from_date,
								@first_calc OUTPUT,
								@debug_level 

		IF ( @result != 0 )
			RETURN @result 
		
		IF ( @perf_level >= 2 ) EXEC perf_sp "", "tmp/amdbtosl.sp", 168, "Checked for first calc in year", @PERF_time_last OUTPUT

		
		IF @first_calc = 1 OR @do_post = 0
		BEGIN  


			IF @debug_level >= 3
				PRINT "First calculation in year or Perview mode - check both"

			 
			EXEC @result = amDB_sp 
									@co_asset_book_id,
									@from_date,
									@convention_id,
									0,		
									@use_addition_info,
									@acquisition_date,
									@placed_date,
									@curr_precision,
									@db_depr 	OUTPUT,
									@debug_level 
 

			IF ( @result != 0 )
				RETURN @result 

			IF ( @perf_level >= 2 ) EXEC perf_sp "", "tmp/amdbtosl.sp", 203, "Calc using DB", @PERF_time_last OUTPUT
			
			EXEC @result = amSLSpecifiedLife_sp 
									@co_asset_book_id,
									@from_date,	 
									@convention_id,
									0,		
									@use_addition_info,
									@acquisition_date,
									@placed_date,
									@curr_precision,
									@sl_depr OUTPUT,
									@debug_level,
									@perf_level 
									 
 

			IF ( @result != 0 )
				RETURN @result 

			IF ( @perf_level >= 2 ) EXEC perf_sp "", "tmp/amdbtosl.sp", 223, "Calc using SLSL", @PERF_time_last OUTPUT
			
			IF @sl_depr > @db_depr 
			BEGIN  

				IF @do_post = 1 
				BEGIN  
					EXEC @result = amSetSLSwitch_sp 
											@co_asset_book_id,
											1,
											@from_date,
											@debug_level 

					IF ( @result != 0 )
						RETURN @result 
				
				END  

				SELECT @depr_expense = @sl_depr 

			END  

			ELSE 
				SELECT @depr_expense = @db_depr 

			IF @debug_level >= 3
				SELECT 	sl_depr = @sl_depr,
						db_depr = @db_depr

			IF ( @perf_level >= 2 ) EXEC perf_sp "", "tmp/amdbtosl.sp", 252, "Set switch if required", @PERF_time_last OUTPUT
			
		END  

		ELSE 
		 
		BEGIN  

			IF @debug_level >= 3
				SELECT "Using DB"
			
			EXEC @result = amDB_sp 
									@co_asset_book_id,
									@from_date,
									@convention_id,
									0,		
									@use_addition_info,
									@acquisition_date,
									@placed_date,
									@curr_precision,
									@db_depr 	OUTPUT,
									@debug_level 
 

			IF ( @result != 0 )
				RETURN @result

			SELECT @depr_expense = @db_depr 

			IF @debug_level >= 3
				SELECT 	db_depr = @db_depr

		END  
	END	 
END  

IF ( @perf_level >= 1 ) EXEC perf_sp "", "tmp/amdbtosl.sp", 291, "Exit amDBToSL_sp", @PERF_time_last OUTPUT
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amdbtosl.sp" + ", line " + STR( 292, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amDBToSL_sp] TO [public]
GO
