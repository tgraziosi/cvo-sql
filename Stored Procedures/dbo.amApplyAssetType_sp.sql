SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amApplyAssetType_sp] 
(
	@debug_level		smDebugLevel  	= 0,	
	@perf_level			smPerfLevel		= 0		
)
AS 









DECLARE
        @PERF_time_last     datetime

SELECT  @PERF_time_last = GETDATE()

















									







DECLARE 
	@error 	   			smErrorCode,
	@message			smErrorLongDesc,
	@nat_length 		smSmallCounter,
	@acct_format		smAccountCode,
	@start_col_part2	smSmallCounter,
	@length_part1		smSmallCounter,
	@length_part2		smSmallCounter
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "amapptyp.cpp" + ", line " + STR( 140, 5 ) + " -- ENTRY: "

IF ( @perf_level >= 1 ) EXEC perf_sp "Create Accounts", "amapptyp.cpp", 142, "Enter amApplyAssetType_sp", @PERF_time_last OUTPUT







SELECT 	@length_part1 		= start_col - 1,  			
		@acct_format 		= LTRIM(acct_format)	 	
FROM	glaccdef
WHERE  	natural_acct_flag 	= 1

IF @@rowcount <> 1
BEGIN
	EXEC 		amGetErrorMessage_sp 20134, "amapptyp.cpp", 157, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR	20134 @message
	RETURN 		20134
END

EXEC @error = amStringLength_sp @acct_format, @nat_length OUTPUT
IF @error <> 0
BEGIN
	RETURN @error
END

SELECT 	@start_col_part2 	= @length_part1 + @nat_length + 1
SELECT	@length_part2 		=  32 - @start_col_part2 + 1

IF @debug_level >= 5
	SELECT 	start_col_part2 = @start_col_part2,
			length_part1 	= @length_part1,
			length_part2 	= @length_part2














UPDATE 	#amcreact
SET 	account_code = dbo.IBReplaceBranchMask_fn(	
			SUBSTRING(account_code, 1, @length_part1)
							+ asttyp.asset_gl_override 
							+ SUBSTRING(account_code, @start_col_part2, @length_part2)
		       ,  a.org_id)
FROM 	#amcreact 	tmp,
		amasset		a,
		amasttyp	asttyp 
WHERE   tmp.account_type_id			= 0
AND		tmp.co_asset_id				= a.co_asset_id
AND		a.asset_type_code			= asttyp.asset_type_code
AND     asttyp.asset_gl_override 	IS NOT NULL

SELECT @error = @@error
IF @error <> 0
	RETURN @error




UPDATE 	#amcreact
SET 	account_code = dbo.IBReplaceBranchMask_fn(	
			SUBSTRING(account_code, 1, @length_part1)
							+ asttyp.accum_depr_gl_override 
							+ SUBSTRING(account_code, @start_col_part2, @length_part2)
		       ,  a.org_id)
FROM 	#amcreact	tmp,
		amasset		a,
		amasttyp	asttyp 
WHERE   tmp.account_type_id				= 1
AND		tmp.co_asset_id				= a.co_asset_id
AND		a.asset_type_code			= asttyp.asset_type_code
AND     asttyp.accum_depr_gl_override 	IS NOT NULL

SELECT @error = @@error
IF @error <> 0
	RETURN @error




UPDATE 	#amcreact
SET 	account_code = dbo.IBReplaceBranchMask_fn(	
			SUBSTRING(account_code, 1, @length_part1)
							+ asttyp.depr_exp_gl_override 
							+ SUBSTRING(account_code, @start_col_part2, @length_part2)
		       ,  a.org_id)
FROM 	#amcreact 	tmp,
		amasset		a,
		amasttyp	asttyp 
WHERE   tmp.account_type_id			= 5
AND		tmp.co_asset_id				= a.co_asset_id
AND		a.asset_type_code			= asttyp.asset_type_code
AND     asttyp.depr_exp_gl_override IS NOT NULL


SELECT @error = @@error
IF @error <> 0
	RETURN @error

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "amapptyp.cpp" + ", line " + STR( 250, 5 ) + " -- EXIT: "
IF ( @perf_level >= 1 ) EXEC perf_sp "Create Accounts", "amapptyp.cpp", 251, "Enter amApplyAssetType_sp", @PERF_time_last OUTPUT

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amApplyAssetType_sp] TO [public]
GO
