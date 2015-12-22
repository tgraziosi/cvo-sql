SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amValidClsOverride_sp] 
(
	@company_id		smCompanyID,	 		
	@acct_level		smAcctLevel,	 		
	@start_col		smSmallCounter,	 		
	@length			smSmallCounter,	 		
	@override		smAccountOverride,		
	@is_valid		smLogical		OUTPUT,	
	@debug_level	smDebugLevel	= 0		
)
AS 

DECLARE 
	@message smErrorLongDesc, 
	@ret_status smErrorCode

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amvldovr.sp" + ", line " + STR( 71, 5 ) + " -- ENTRY: "

SELECT @is_valid = 0

IF @acct_level = 0
BEGIN
	IF EXISTS(SELECT 	account_code
				FROM	glchart
				WHERE	SUBSTRING(account_code, @start_col, @length) = @override)
		SELECT @is_valid = 1

END
ELSE IF @acct_level = 1
BEGIN
	IF EXISTS (SELECT	seg_code
				FROM	glseg1
				WHERE 	seg_code = @override)
		SELECT @is_valid = 1
END
ELSE IF @acct_level = 2
BEGIN
	IF EXISTS (SELECT	seg_code
				FROM	glseg2
				WHERE 	seg_code = @override)
		SELECT @is_valid = 1
END
ELSE IF @acct_level = 3
BEGIN
	IF EXISTS (SELECT	seg_code
				FROM	glseg3
				WHERE 	seg_code = @override)
		SELECT @is_valid = 1
END
ELSE IF @acct_level = 4
BEGIN
	IF EXISTS (SELECT	seg_code
				FROM	glseg4
				WHERE 	seg_code = @override)
		SELECT @is_valid = 1
END


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amvldovr.sp" + ", line " + STR( 113, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amValidClsOverride_sp] TO [public]
GO
