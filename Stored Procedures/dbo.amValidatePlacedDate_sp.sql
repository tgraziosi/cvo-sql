SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[amValidatePlacedDate_sp] 
(
	@co_asset_book_id		smSurrogateKey,			
	@placed_in_service_date	smApplyDate,		 
	@is_valid				smLogical OUTPUT,	
	@debug_level			smDebugLevel	= 0	
)
AS
DECLARE
	@result					smErrorCode,		
	@message				smErrorLongDesc,	
	@param1					smErrorLongDesc,	
	@param2					smErrorLongDesc,	
	@param3					smErrorLongDesc,	
	@param4					smErrorLongDesc,	
	@acquisition_date		smApplyDate,		
	@asset_ctrl_num			smControlNumber,	
	@book_code				smBookCode,			
	@jul_date				smJulianDate		

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amvlpldt.sp" + ", line " + STR( 70, 5 ) + " -- ENTRY: " 

SELECT @is_valid = 1


SELECT	@acquisition_date 	= acquisition_date,
		@asset_ctrl_num		= asset_ctrl_num,
		@book_code			= book_code
FROM	amastbk 	ab,
		amasset		a
WHERE	ab.co_asset_book_id	= @co_asset_book_id
AND		ab.co_asset_id		= a.co_asset_id


IF @placed_in_service_date IS NOT NULL
BEGIN
	SELECT @jul_date = DATEDIFF(dd, "1/1/1980", @placed_in_service_date) + 722815

	IF NOT EXISTS(SELECT *
					FROM glprd 
					WHERE period_end_date 		>= @jul_date
					AND	 period_start_date 	<= @jul_date) 
	BEGIN
		SELECT 	@param1 = RTRIM(@asset_ctrl_num),
				@param2 = RTRIM(@book_code)
		EXEC	 	amGetErrorMessage_sp 20038, "tmp/amvlpldt.sp", 99, @param1, @param2, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20038 @message 
		SELECT 		@is_valid = 0
	END

	 
	IF @acquisition_date > @placed_in_service_date
	BEGIN 
		SELECT 	@param1 = RTRIM(@asset_ctrl_num),
				@param2 = RTRIM(@book_code),
				@param3 = RTRIM(CONVERT(char(255), @acquisition_date)),
				@param4 = RTRIM(CONVERT(char(255), @placed_in_service_date))
		
		EXEC 		amGetErrorMessage_sp 20074, "tmp/amvlpldt.sp", 114, @param3, @param4, @param1, @param2, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20074 @message 
		SELECT 		@is_valid = 0
	END 
END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amvlpldt.sp" + ", line " + STR( 120, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amValidatePlacedDate_sp] TO [public]
GO
