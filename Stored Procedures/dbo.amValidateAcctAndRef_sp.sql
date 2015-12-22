SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amValidateAcctAndRef_sp] 
(	
	@home_currency_code		smCurrencyCode,			
	@asset_ctrl_num			smControlNumber,		
	@account_code			smAccountCode,			
	@account_reference_code	smAccountReferenceCode,	
	@apply_date				smApplyDate,			
	@debug_level			smDebugLevel	= 0		
)
AS 

DECLARE 
	@error 					smErrorCode,						
	@message				smErrorLongDesc,		
	@param					smErrorParam,			
	@jul_apply_date			smJulianDate					

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amvldact.sp" + ", line " + STR( 72, 5 ) + " -- ENTRY: "

SELECT	@param 			= ISNULL(RTRIM(CONVERT(char(255), @apply_date, 107)), ""),
		@jul_apply_date = DATEDIFF(dd, "1/1/1980", @apply_date) + 722815

IF @debug_level >= 3
	SELECT 	account_code	= @account_code,
			account_ref 	= @account_reference_code


IF NOT EXISTS (SELECT 	account_code
				FROM 	glchart 
				WHERE 	account_code 	= @account_code)
BEGIN
	EXEC 		amGetErrorMessage_sp 
						20210, "tmp/amvldact.sp", 89, 
						@account_code, @asset_ctrl_num, @param,
						@error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20210 @message 
	RETURN 		20210 
END
	 

IF EXISTS (SELECT 	account_code
 			FROM 	glchart
 			WHERE	account_code	= @account_code
 			AND	 	inactive_flag 	= 1)  

BEGIN
	EXEC 		amGetErrorMessage_sp 
						20211, "tmp/amvldact.sp", 106, 
						@account_code, @asset_ctrl_num, @param, 
						@error_message 	= @message OUT 
	IF @message IS NOT NULL RAISERROR 	20211 @message 
	RETURN 		20211 
END


IF EXISTS (SELECT 	account_code
			FROM 	glchart
			WHERE 	account_code 			= @account_code
			AND		glchart.inactive_flag	= 0 
			AND	
			(	
				(			active_date 	<> 0
					AND		inactive_date	<> 0 
					AND		@jul_apply_date	NOT BETWEEN	glchart.active_date AND glchart.inactive_date
				)
				OR
				(
							active_date 	= 0
					AND		inactive_date	<> 0 
					AND		@jul_apply_date	>= glchart.inactive_date
				)
				OR
				(
							active_date 	<> 0
					AND		inactive_date	= 0 
					AND		@jul_apply_date	< glchart.active_date
				)
			))
BEGIN
	EXEC 		amGetErrorMessage_sp 
						20212, "tmp/amvldact.sp", 145, 
						@account_code, @asset_ctrl_num, @param, 
						@error_message 	= @message OUT 
	IF @message IS NOT NULL RAISERROR 	20212 @message 
	RETURN 		20212 
END


IF EXISTS (SELECT 	account_code
 			FROM 	glchart
 			WHERE	account_code	= @account_code
 			AND	 	currency_code	!= ""
 			AND		currency_code	!= @home_currency_code)

BEGIN
	EXEC 		amGetErrorMessage_sp 
						20219, "tmp/amvldact.sp", 163, 
						@account_code, @asset_ctrl_num, @param, 
						@error_message 	= @message OUT 
	IF @message IS NOT NULL RAISERROR 	20219 @message 
	RETURN 		20219 
END



IF 	( LTRIM(@account_reference_code) IS NOT NULL AND LTRIM(@account_reference_code) != " " )
BEGIN
	
	IF NOT EXISTS(SELECT 	reference_code
					FROM 	glref
					WHERE	reference_code	= @account_reference_code)
	BEGIN
		EXEC 		amGetErrorMessage_sp 
							20217, "tmp/amvldact.sp", 182, 
							@account_reference_code, @asset_ctrl_num, @param, 
							@error_message 	= @message OUT 
		IF @message IS NOT NULL RAISERROR 	20217 @message 
		RETURN 		20217 
	END

	
	IF EXISTS(SELECT 	reference_code
				FROM 	glref
				WHERE	reference_code		= @account_reference_code
				AND		glref.status_flag	= 1 )				

	BEGIN
		EXEC 		amGetErrorMessage_sp 
							20216, "tmp/amvldact.sp", 199, 
							@account_reference_code, @asset_ctrl_num, @param, 
							@error_message 	= @message OUT 
		IF @message IS NOT NULL RAISERROR 	20216 @message 
		RETURN 		20216 
	END

END






IF EXISTS (SELECT r.reference_code
			FROM	glref r,
					glrefact 	ra,
					glratyp		rat
			WHERE	@account_code			LIKE	RTRIM(ra.account_mask)
			AND		ra.reference_flag 		= 1 
			AND		ra.account_mask			= rat.account_mask
			AND		rat.reference_type 		= r.reference_type
			AND		r.reference_code		= @account_reference_code) 

BEGIN
	EXEC 		amGetErrorMessage_sp 
						20215, "tmp/amvldact.sp", 228, 
						@account_code, @account_reference_code, @asset_ctrl_num, @param,
						@error_message 	= @message OUT 
	IF @message IS NOT NULL RAISERROR 	20215 @message 
	RETURN 		20215 
END


IF 	( LTRIM(@account_reference_code) IS NOT NULL AND LTRIM(@account_reference_code) != " " )
BEGIN
	
	IF EXISTS (SELECT 	r.reference_code
					FROM	glref 		r,
							glrefact	ra
					WHERE	@account_code		LIKE	RTRIM(ra.account_mask)
					AND		ra.reference_flag 	= 3 
					AND		r.reference_code	= @account_reference_code	
					AND		r.reference_type	NOT IN (SELECT 	reference_type 
														FROM 	glratyp rat
														WHERE	rat.account_mask = ra.account_mask))
	BEGIN
		EXEC 		amGetErrorMessage_sp 
							20213, "tmp/amvldact.sp", 254, 
							@account_reference_code, @account_code, @asset_ctrl_num, @param, 
							@error_message 	= @message OUT 
		IF @message IS NOT NULL RAISERROR 	20213 @message 
		RETURN 		20213 
	END
	
	
	IF EXISTS (SELECT 	r.reference_code
					FROM	glref 		r,
							glrefact	ra
					WHERE	@account_code		LIKE	RTRIM(ra.account_mask)
					AND		ra.reference_flag 	= 2 
					AND		r.reference_code	= @account_reference_code	
					AND		r.reference_type	NOT IN (SELECT 	reference_type 
														FROM 	glratyp rat
														WHERE	rat.account_mask = ra.account_mask))

	BEGIN
		EXEC 		amGetErrorMessage_sp 
							20218, "tmp/amvldact.sp", 276, 
							@account_reference_code, @account_code, @asset_ctrl_num, @param,
							@error_message 	= @message OUT 
		IF @message IS NOT NULL RAISERROR 	20218 @message 
		RETURN 		20218 
	END
END	
ELSE	
BEGIN
	IF EXISTS (SELECT r.reference_code
			FROM	glref		r,
					glrefact	ra
			WHERE	@account_code			LIKE	RTRIM(ra.account_mask)
			AND		ra.reference_flag 		= 3) 
			

	BEGIN
		EXEC 		amGetErrorMessage_sp 
							20214, "tmp/amvldact.sp", 294, 
							@account_code, @asset_ctrl_num, @param,
							@error_message 	= @message OUT 
		IF @message IS NOT NULL RAISERROR 	20214 @message 
		RETURN 		20214 
	END
END
	
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amvldact.sp" + ", line " + STR( 302, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amValidateAcctAndRef_sp] TO [public]
GO
