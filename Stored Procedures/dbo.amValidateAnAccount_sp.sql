SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amValidateAnAccount_sp] 
(	
	@home_currency_code	smCurrencyCode,		
	@account_code		smAccountCode,		
	@from_date			smApplyDate,		
	@to_date			smApplyDate,		
	@debug_level		smDebugLevel	= 0	
)
AS 

DECLARE @error 				smErrorCode,
		@message			smErrorLongDesc,
		@jul_from_date		smJulianDate,
		@jul_to_date 		smJulianDate



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amvldone.sp" + ", line " + STR( 97, 5 ) + " -- ENTRY: "


IF NOT EXISTS (SELECT 	account_code
				FROM 	glchart 
				WHERE 	account_code 	= @account_code)
BEGIN
	EXEC 		amGetErrorMessage_sp 20160, "tmp/amvldone.sp", 104, @account_code, @error_message = @message out 
	IF @message IS NOT NULL RAISERROR 	20160 @message 
	RETURN 		20160 
END
	 


IF EXISTS (SELECT 	account_code
				FROM 	glchart
				WHERE	account_code	= @account_code
				AND	 	inactive_flag 	= 1)  

BEGIN
	EXEC 		amGetErrorMessage_sp 20161, "tmp/amvldone.sp", 117, @account_code, @error_message = @message out 
	IF @message IS NOT NULL RAISERROR 	20161 @message 
	RETURN 		20161 
END


SELECT 	@jul_from_date 	= DATEDIFF(dd, "1/1/1980", @from_date) + 722815,
		@jul_to_date 	= DATEDIFF(dd, "1/1/1980", @to_date) + 722815	


IF EXISTS (SELECT 	account_code
			FROM 	glchart
			WHERE 	account_code 			= @account_code
			AND		glchart.inactive_flag	= 0 
			AND	
			(	
				(			active_date 	<> 0
					AND		inactive_date	<> 0 
					AND		(@jul_from_date	NOT BETWEEN	glchart.active_date AND glchart.inactive_date
						OR	@jul_to_date	NOT BETWEEN	glchart.active_date AND glchart.inactive_date)
				)
				OR
				(
							active_date 	= 0
					AND		inactive_date	<> 0 
					AND		@jul_to_date	>= glchart.inactive_date
				)
				OR
				(
							active_date 	<> 0
					AND		inactive_date	= 0 
					AND		@jul_from_date	< glchart.active_date
				)
			))
BEGIN
	DECLARE	@param1 smErrorParam,
			@param2	smErrorParam
			
	SELECT	@param1 = RTRIM(CONVERT(char(255), @from_date)),
			@param2	= RTRIM(CONVERT(char(255), @to_date))
	
	EXEC 		amGetErrorMessage_sp 20162, "tmp/amvldone.sp", 166, @param1, @param2, @account_code, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20162 @message 
	RETURN 		20162 
END



IF EXISTS (SELECT account_mask
			FROM	glrefact	ra
			WHERE	@account_code			LIKE	RTRIM(ra.account_mask)
			AND		ra.reference_flag 		= 3 
			)
BEGIN
	EXEC 		amGetErrorMessage_sp 20163, "tmp/amvldone.sp", 181, @account_code, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20163 @message 
	RETURN 		20163 
END
	

IF EXISTS (SELECT 	account_code
				FROM 	glchart
				WHERE	account_code	= @account_code
				AND	 	currency_code 	!= ""
				AND		currency_code	!= @home_currency_code)

BEGIN
	EXEC 		amGetErrorMessage_sp 20164, "tmp/amvldone.sp", 196, @account_code, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20164 @message 
	RETURN 		20164 
END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amvldone.sp" + ", line " + STR( 201, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amValidateAnAccount_sp] TO [public]
GO
