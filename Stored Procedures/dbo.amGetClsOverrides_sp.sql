SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[amGetClsOverrides_sp] 
(
	@company_id		smCompanyID,	 		
	@acct_level		smAcctLevel,	 		
	@start_col		smSmallCounter,	 		
	@length			smSmallCounter, 	 	
	@debug_level	smDebugLevel	= 0		
)
AS 

DECLARE 
	@message smErrorLongDesc, 
	@ret_status smErrorCode

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amclsovr.sp" + ", line " + STR( 70, 5 ) + " -- ENTRY: "

IF @acct_level = 0
BEGIN
	SELECT 	distinct seg_code	= substring(account_code, @start_col, @length)
	FROM	glchart
END
ELSE IF @acct_level = 1
BEGIN
	SELECT	seg_code, 
			description,
			short_desc,
			account_type,
			new_flag
	FROM	glseg1
	ORDER BY 
			seg_code
END
ELSE IF @acct_level = 2
BEGIN
	SELECT	seg_code, 
			description,
			short_desc,
			account_type,
			new_flag
	FROM	glseg2
	ORDER BY 
			seg_code
END
ELSE IF @acct_level = 3
BEGIN
	SELECT	seg_code, 
			description,
			short_desc,
			account_type,
			new_flag
	FROM	glseg3
	ORDER BY 
			seg_code
END
ELSE IF @acct_level = 4
BEGIN
	SELECT	seg_code, 
			description,
			short_desc,
			account_type,
			new_flag
	FROM	glseg4
	ORDER BY 
			seg_code
END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amclsovr.sp" + ", line " + STR( 122, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amGetClsOverrides_sp] TO [public]
GO
