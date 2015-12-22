SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amSetFirstDeprDate_sp] 
(
 @co_asset_book_id 		smSurrogateKey, 	
 	@placed_date 			smApplyDate,	 	 
	@debug_level			smDebugLevel	= 0	
)
AS 

DECLARE 
	@ret_status 		smErrorCode, 
	@convention_id 		smConventionID, 
	@first_depr_date 	smApplyDate,
	@mid_point_date		smApplyDate 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amclfsdp.sp" + ", line " + STR( 141, 5 ) + " -- ENTRY: "

EXEC @ret_status = amGetConventionID_sp 
						@co_asset_book_id,
						@placed_date,
						@convention_id OUTPUT,
						@debug_level	= @debug_level

IF @ret_status <> 0 
	RETURN @ret_status 

IF @convention_id = 1 
BEGIN
	
	EXEC @ret_status = amGetPeriodMidPoint_sp 
						@placed_date,
						@first_depr_date OUTPUT,
						@debug_level	= @debug_level

	IF @ret_status <> 0 
		RETURN @ret_status 
END

ELSE IF @convention_id = 3 
BEGIN
	
	EXEC @ret_status = amGetPeriodMidPoint_sp 
								@placed_date,
								@mid_point_date OUTPUT, 
								@debug_level	= @debug_level
	IF @ret_status <> 0 
		RETURN @ret_status 

	IF @placed_date < @mid_point_date
	BEGIN
		EXEC @ret_status = amGetFiscalPeriod_sp 
							@placed_date,
							0,
							@first_depr_date OUTPUT,
							@debug_level	= @debug_level							 
			
		IF @ret_status <> 0 
			RETURN @ret_status 
	END
	ELSE
	BEGIN
		EXEC @ret_status = amGetFiscalPeriod_sp 
							@placed_date,
							1,
							@first_depr_date OUTPUT,
							@debug_level	= @debug_level							 
			
		IF @ret_status <> 0 
			RETURN @ret_status 

		SELECT @first_depr_date = dateadd(dd, 1, @first_depr_date)
	END

END

ELSE IF	@convention_id = 5 
BEGIN
	
	SELECT @first_depr_date = @placed_date

END

ELSE 
BEGIN
	EXEC @ret_status = amGetFiscalPeriod_sp 
						@placed_date,
						0,
						@first_depr_date OUTPUT,
						@debug_level	= @debug_level						 

	IF @ret_status <> 0 
		RETURN @ret_status 
END


UPDATE 	amastbk 
SET 	first_depr_date 	= @first_depr_date 
WHERE 	co_asset_book_id 	= @co_asset_book_id 

SELECT @ret_status = @@error
IF @ret_status <> 0 
	RETURN @ret_status 

IF @debug_level >= 3
	SELECT	first_depr_date = @first_depr_date

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amclfsdp.sp" + ", line " + STR( 243, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amSetFirstDeprDate_sp] TO [public]
GO
