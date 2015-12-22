SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amGetBasis_sp] 
( 	
	@co_asset_book_id   smSurrogateKey, 	      
	@placed_date		smApplyDate,		
	@from_date 			smApplyDate, 		
	@salvage_value 		smMoneyZero, 		
	@method_id 			smDeprMethodID, 	
	@convention_id		smConventionID,		
	@use_addition_info 	smLogical, 			
	@curr_precision		smallint,			
	@basis  			smMoneyZero OUTPUT,	
	@basis_date			smApplyDate	OUTPUT,	
	@debug_level		smDebugLevel  = 0, 	
	@perf_level			smPerfLevel 	= 0	
)
AS 









DECLARE
        @PERF_time_last     datetime

SELECT  @PERF_time_last = GETDATE()

















									







DECLARE 
	@return_status  	smErrorCode, 
	@cost 				smMoneyZero, 
	@accum_depr 		smMoneyZero, 
	@cost_delta 		smMoneyZero, 
	@accum_depr_delta 	smMoneyZero, 
	@profile_date 		smApplyDate, 
	@basis_start 		smApplyDate, 
	@fiscal_year_start 	smApplyDate,
	@prd_end_date		smApplyDate		

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ambasis.cpp" + ", line " + STR( 94, 5 ) + " -- ENTRY: "
IF ( @perf_level >= 1 ) EXEC perf_sp "", "ambasis.cpp", 95, "Entry amGetBasis_sp", @PERF_time_last OUTPUT

IF @debug_level > 3
	SELECT  co_asset_book_id 	= @co_asset_book_id,
			from_date 			= @from_date,
			salvage_value 		= @salvage_value,
			method_id 			= @method_id,
			use_addition_info 	= @use_addition_info 




SELECT	@cost 				= 0.0,
		@accum_depr 		= 0.0,
		@cost_delta			= 0.0,
		@accum_depr_delta	= 0.0
		
EXEC @return_status = amGetFiscalPeriod_sp 
						@from_date,
						1,
						@prd_end_date OUTPUT 

IF ( @return_status != 0 )
	RETURN @return_status

IF @use_addition_info = 1 
BEGIN 
		
	


	SELECT 	@cost 				= (SIGN(ISNULL(SUM(amount), 0.0)) * ROUND(ABS(ISNULL(SUM(amount), 0.0)) + 0.0000001, @curr_precision))
	FROM 	amvalues 
	WHERE 	co_asset_book_id 	= @co_asset_book_id 
	AND 	account_type_id 	= 0 
	AND		apply_date			<= @prd_end_date
		
	IF @method_id = 1
 		SELECT @basis = (SIGN(@cost - @salvage_value) * ROUND(ABS(@cost - @salvage_value) + 0.0000001, @curr_precision)) 
	ELSE
	BEGIN
		SELECT 	@accum_depr 		= (SIGN(ISNULL(SUM(amount), 0.0)) * ROUND(ABS(ISNULL(SUM(amount), 0.0)) + 0.0000001, @curr_precision))
		FROM 	amvalues 
		WHERE 	co_asset_book_id 	= @co_asset_book_id 
		AND		trx_type			!= 50
		AND 	account_type_id 	= 1 
		AND		apply_date			<= @prd_end_date

		SELECT 	@accum_depr 		= (SIGN(@accum_depr - ISNULL(SUM(disposed_depr), 0.0)) * ROUND(ABS(@accum_depr - ISNULL(SUM(disposed_depr), 0.0)) + 0.0000001, @curr_precision))
		FROM 	amacthst 
		WHERE 	co_asset_book_id 	= @co_asset_book_id
		AND		trx_type			= 70
		AND		apply_date			<= @prd_end_date

		IF @method_id = 2 
			SELECT @basis = (SIGN(@cost + @accum_depr - @salvage_value) * ROUND(ABS(@cost + @accum_depr - @salvage_value) + 0.0000001, @curr_precision)) 
		ELSE 
		BEGIN 
			IF @method_id = 4 
				SELECT @basis = (SIGN(@cost + @accum_depr) * ROUND(ABS(@cost + @accum_depr) + 0.0000001, @curr_precision))
		END 
	END
	
	



 
	IF @method_id = 2
	BEGIN
		EXEC @return_status = amGetConventionDate_sp 
								@placed_date,
								@convention_id,
								@basis_date OUT 
		IF ( @return_status != 0 )
			RETURN @return_status 

	END
	
	IF @debug_level > 3
		SELECT 	cost 				= @cost,
				accum_depr 			= @accum_depr,
				salvage 			= @salvage_value,
				basis				= @basis 

END 

ELSE  
BEGIN 

	 
	IF @method_id = 1 
	BEGIN 
		 
		EXEC @return_status = amGetProfile_sp 	
									@co_asset_book_id,
									@from_date,
									@cost 		OUTPUT,	
									@accum_depr OUTPUT,	 	 
									@profile_date OUTPUT 

		IF ( @return_status != 0 )
			RETURN @return_status 

		EXEC @return_status = amGetChangesToProfile_sp 	
									@co_asset_book_id,
									@profile_date, 
									@prd_end_date,
									@curr_precision,
									@cost_delta 		OUTPUT,	
									@accum_depr_delta 	OUTPUT,   
									@debug_level
		IF ( @return_status != 0 )
			RETURN @return_status

		IF @debug_level > 3
		 	SELECT 	method			= "SL Percentage",
		 			cost_bop 		= @cost,
			 		cost_curr_prd 	= @cost_delta 

 		SELECT @basis = (SIGN(@cost + @cost_delta - @salvage_value) * ROUND(ABS(@cost + @cost_delta - @salvage_value) + 0.0000001, @curr_precision)) 

	END 
	
	ELSE 

	IF @method_id = 2 
	BEGIN 

		EXEC @return_status = amGetBasisLastChange_sp 
								@co_asset_book_id,
								@from_date,
								@prd_end_date,
								@salvage_value,
								@curr_precision,	
								@basis 			OUTPUT,	
								@basis_date 	OUTPUT,
								@debug_level,
								@perf_level 

		IF @debug_level > 3
		 	SELECT 	method		= "SL Specified Life",
	 			 	basis 		= @basis,
		 			basis_date 	= @basis_date 

		IF ( @return_status != 0 )
			RETURN @return_status
	END 

	ELSE 

	IF @method_id = 4 
	BEGIN 

		EXEC @return_status = amGetFiscalYear_sp 
							@from_date,
							0,
							@fiscal_year_start OUTPUT 

		IF ( @return_status != 0 )
			RETURN @return_status

		IF @debug_level > 3
	 		SELECT fiscal_year_start = @fiscal_year_start 

		EXEC @return_status = amGetProfile_sp 	
								@co_asset_book_id,
								@fiscal_year_start,
								@cost  			OUTPUT,	
								@accum_depr  	OUTPUT,	
								@profile_date 	OUTPUT 

		IF ( @return_status != 0 )
			RETURN @return_status

		EXEC @return_status = amGetChangesToProfile_sp 	
								@co_asset_book_id,
								@profile_date, 		
								@prd_end_date,
								@curr_precision,
								@cost_delta 		OUTPUT,	
								@accum_depr_delta 	OUTPUT,
								@debug_level 
		IF ( @return_status != 0 )
			RETURN @return_status


		IF @debug_level > 3
		 	SELECT 	method				= "Declining Balance",
	 		 		cost_boy 			= @cost,
					accum_depr_boy 		= @accum_depr,
		 			cost_curr_yr 		= @cost_delta,
					accum_depr_curr_yr 	= @accum_depr_delta 

		SELECT @basis = (SIGN(@cost + @accum_depr + @cost_delta + @accum_depr_delta) * ROUND(ABS(@cost + @accum_depr + @cost_delta + @accum_depr_delta) + 0.0000001, @curr_precision))
	END 
	
END 
	
IF @debug_level > 3
	SELECT  basis 		= @basis,
			basis_date = @basis_date 

IF ( @perf_level >= 1 ) EXEC perf_sp "", "ambasis.cpp", 298, "Exit amGetBasis_sp", @PERF_time_last OUTPUT
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ambasis.cpp" + ", line " + STR( 299, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amGetBasis_sp] TO [public]
GO
