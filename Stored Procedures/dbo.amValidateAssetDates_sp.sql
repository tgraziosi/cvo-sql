SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[amValidateAssetDates_sp] 
(
	@co_asset_id			smSurrogateKey,		
	@asset_ctrl_num			smControlNumber,	
	@acquisition_date		smApplyDate,		
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
	@jul_date				smJulianDate		

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amvaldts.sp" + ", line " + STR( 104, 5 ) + " -- ENTRY: " 

SELECT @is_valid = 1


SELECT @jul_date = DATEDIFF(dd, "1/1/1980", @acquisition_date) + 722815
SELECT @param1 = RTRIM(@asset_ctrl_num)

IF NOT EXISTS(SELECT *
				FROM glprd 
				WHERE period_end_date 		>= @jul_date
				AND	 period_start_date 	<= @jul_date) 
BEGIN

	EXEC	 	amGetErrorMessage_sp 
							20036, "tmp/amvaldts.sp", 121, 
							@param1, 
							@error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20036 @message 
	SELECT 		@is_valid = 0
END


IF @placed_in_service_date IS NOT NULL
BEGIN
	SELECT @jul_date = DATEDIFF(dd, "1/1/1980", @placed_in_service_date) + 722815

	IF NOT EXISTS(SELECT *
					FROM glprd 
					WHERE period_end_date 		>= @jul_date
					AND	 period_start_date 	<= @jul_date) 
	BEGIN
		EXEC	 	amGetErrorMessage_sp 
								20037, "tmp/amvaldts.sp", 141, 
								@param1, 
								@error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20037 @message 
		SELECT 		@is_valid = 0
	END
END

 
IF @acquisition_date > @placed_in_service_date
BEGIN 
	SELECT 		@param2 = RTRIM(CONVERT(char(255), @acquisition_date, 107))
	SELECT 		@param3 = RTRIM(CONVERT(char(255), @placed_in_service_date, 107))
	
	EXEC 		amGetErrorMessage_sp 
							20071, "tmp/amvaldts.sp", 158, 
							@param2, @param3, @param1, 
							@error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20071 @message 
	SELECT 		@is_valid = 0
END 


IF @co_asset_id != 0
BEGIN
	IF EXISTS(SELECT 	co_trx_id
				FROM 	amtrxhdr
				WHERE	co_asset_id = @co_asset_id
				AND		apply_date	< @acquisition_date)
	BEGIN
	SELECT 		@param2 = RTRIM(CONVERT(char(255), @acquisition_date, 107))
	
	EXEC 		amGetErrorMessage_sp 
							20084, "tmp/amvaldts.sp", 178, 
							@param2, @asset_ctrl_num, 
							@error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20084 @message 
	SELECT 		@is_valid = 0
	END
END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amvaldts.sp" + ", line " + STR( 186, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amValidateAssetDates_sp] TO [public]
GO
