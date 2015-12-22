SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO





CREATE PROCEDURE [dbo].[amDoActivateAdded_sp] 
(
	@co_trx_id				smSurrogateKey,		
	@company_id 			smCompanyID, 		
	@user_id				smUserID,			
	@batch_size				smCounter 	= 0,	
	@show_acct_msgs			smLogical	= 1,	




	@debug_level			smDebugLevel 	= 0	
)
AS 

DECLARE 
	@result    				smErrorCode, 		
	@message 				smErrorLongDesc, 	
	@home_currency_code		smCurrencyCode,		
	@cur_prd_end_date 		smApplyDate, 		
	@cur_yr_start_date 		smApplyDate, 		
	@prev_yr_end_date 		smApplyDate, 		
	@apply_date 			smApplyDate,		 
	@co_asset_id 			smSurrogateKey, 	
	@asset_ctrl_num 		smControlNumber, 	
	@acquisition_date		smApplyDate,		
	@is_new 				smLogical, 			
	@count					smCounter, 			
	@start_org_id           smOrgId,
	@end_org_id             smOrgId

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "amdoact.cpp" + ", line " + STR( 116, 5 ) + " -- ENTRY: "

IF @debug_level >= 3
	SELECT 	company_id  	= @company_id,
			co_trx_id	  	= @co_trx_id 




SELECT 	@count 				= 0, 
		@prev_yr_end_date 	= DATEADD(dd, -1, @cur_yr_start_date)




EXEC @result = amGetCurrencyCode_sp 
						@company_id,
						@home_currency_code OUTPUT 
IF @result <> 0 
	RETURN @result 



 
EXEC @result = amGetCurrentFiscalPeriod_sp 
						@company_id,
						@cur_prd_end_date OUTPUT 
IF @result <> 0 
	RETURN @result 

EXEC @result = amGetFiscalYear_sp 
					@cur_prd_end_date,
					0,
					@cur_yr_start_date OUTPUT 
IF @result <> 0 
	RETURN @result 

SELECT	@prev_yr_end_date = DATEADD(dd, -1, @cur_yr_start_date)




SELECT	@apply_date		= apply_date
FROM	amtrxhdr
WHERE	co_trx_id		= @co_trx_id

IF @debug_level >= 3
	SELECT 	cur_yr_start 	= @cur_yr_start_date,
			apply_date 		= @apply_date 	
 



 





































CREATE TABLE #amastnum
(	
	co_asset_id			int 		NOT NULL,	
	asset_ctrl_num		char(16) 	NOT NULL,	
	posting_code		char(8)		NULL
)

CREATE UNIQUE CLUSTERED INDEX tmp_amastnum_ind_0 on #amastnum (asset_ctrl_num)








INSERT INTO #amastnum
(
		co_asset_id,
		asset_ctrl_num
)
SELECT
		a.co_asset_id,
		a.asset_ctrl_num
FROM	amasset a,
	amtrxast ata,
	amOrganization_vw vw
WHERE 	a.co_asset_id		=	ata.co_asset_id
AND	ata.co_trx_id		=	@co_trx_id
AND 	a.company_id 		=  	@company_id 
AND 	a.activity_state 	=  	100 
AND 	a.acquisition_date 	<= 	@apply_date 
AND	a.is_imported		= 	0
AND	a.is_new		= 	0
AND	a.org_id 		=	vw.org_id

SELECT	@result = @@error
IF	@result <> 0
BEGIN
	DROP TABLE #amastnum
	RETURN @result
END



 











































CREATE TABLE #amaccts
(	
	co_asset_id				int,				
	co_trx_id				int,				


	jul_apply_date			int,				
	account_reference_code	varchar(32),		
	account_type_id			smallint,			
	original_account_code	char(32),			 
	new_account_code		char(32),			
	error_code				int,					
	org_id                  varchar (30)
)



EXEC @result = amCancel_sp @@SPID,@debug_level IF @result = 1 RETURN -1

	SELECT 	@start_org_id  	= MIN(org_id)
	FROM	amOrganization_vw 

	SELECT 	@end_org_id  	= MAX(org_id)
	FROM	amOrganization_vw


IF EXISTS (SELECT asset_ctrl_num
			FROM	#amastnum)
BEGIN
	


	EXEC @result = amCreateAllAccounts_sp
							@company_id,
							@apply_date,
							100,
							NULL,
							NULL,
							@show_acct_msgs,
							@start_org_id,
							@end_org_id,							
							@debug_level
	IF @result <> 0 
	BEGIN 
		DROP TABLE #amastnum
		DROP TABLE #amaccts
		RETURN @result 
	END 
END
EXEC @result = amCancel_sp @@SPID,@debug_level IF @result = 1 RETURN -1






INSERT INTO #amastnum
(
		co_asset_id,
		asset_ctrl_num
)
SELECT
		a.co_asset_id,
		a.asset_ctrl_num
FROM	amasset a,
	amtrxast ata,
	amOrganization_vw vw
WHERE 	a.co_asset_id		=	ata.co_asset_id
AND	ata.co_trx_id		=	@co_trx_id
AND 	a.company_id 		=  	@company_id 
AND 	a.activity_state 	=  	100 
AND 	a.acquisition_date 	<= 	@apply_date 
AND	a.is_imported		= 	0
AND	a.is_new		= 	1
AND	a.org_id 		=	vw.org_id

SELECT	@result = @@error
IF	@result <> 0
BEGIN
	DROP TABLE #amastnum
	RETURN @result
END



 


























CREATE TABLE #am_new_activities
(
	co_trx_id			int		   	NOT NULL, 
	trx_ctrl_num		char(16)	NOT NULL,
	co_asset_id			int			NOT NULL,
	co_asset_book_id	int			NOT NULL, 
	apply_date			datetime  	NOT NULL, 
	trx_type			tinyint		NOT NULL, 
	effective_date		datetime 	NOT NULL,
	revised_cost		float		NOT NULL, 
	revised_accum_depr	float		NOT NULL, 
	delta_cost			float		NOT NULL, 
	delta_accum_depr	float		NOT NULL 
)























CREATE TABLE #am_new_values
(
	co_trx_id			int			NOT NULL, 
	co_asset_book_id	int			NOT NULL, 
	account_type_id		smallint	NOT NULL, 
	apply_date			datetime  	NOT NULL, 
	trx_type			tinyint		NOT NULL, 
   	amount				float		NOT NULL, 
	account_id			int			NOT NULL 
)




 
SELECT 	@asset_ctrl_num 	= MIN(asset_ctrl_num)
FROM 	#amastnum 

WHILE @asset_ctrl_num IS NOT NULL 
BEGIN 

	EXEC @result = amCancel_sp @@SPID,@debug_level IF @result = 1 RETURN -1

	IF @debug_level >= 3
	    SELECT 	asset_ctrl_num 	= @asset_ctrl_num 

	


	SELECT 	@co_asset_id 			= co_asset_id,
			@acquisition_date		= acquisition_date,
			@is_new 				= is_new
	FROM 	amasset 
	WHERE 	asset_ctrl_num 			= @asset_ctrl_num 
	AND 	company_id 				= @company_id 


	IF @is_new = 1
	BEGIN
		EXEC	@result = amActivateNewAsset_sp
								@co_asset_id,
								@asset_ctrl_num,
								@acquisition_date,
								@debug_level = @debug_level

		IF @result <> 0
			GOTO error_handler
	END
	ELSE
	BEGIN
		EXEC	@result = amActivateExistingAsset_sp
							@company_id,
							@co_asset_id,
							@asset_ctrl_num,
							@acquisition_date,
							@prev_yr_end_date,
							@cur_yr_start_date,
							@home_currency_code,
							@user_id,
							@debug_level = @debug_level
		
		IF @result <> 0
			GOTO error_handler
	END

	

 
	SELECT 	@asset_ctrl_num 	= 	MIN(asset_ctrl_num)
	FROM 	#amastnum 
	WHERE 	asset_ctrl_num 		> 	@asset_ctrl_num 

	


 
	SELECT @count = @count + 1 

	IF 	(@batch_size > 0)
	AND (@count = @batch_size) 
	BEGIN 
		EXEC 		amGetErrorMessage_sp 
							20300, "amdoact.cpp", 351, 
							@error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20300 @message 

		SELECT 		@count = 0
	END  
END 




 

EXEC 		amGetErrorMessage_sp
					20301, "amdoact.cpp", 365, 
					@error_message = @message OUT 
IF @message IS NOT NULL RAISERROR 	20301 @message 
 




error_handler:

	

 
	DROP TABLE 	#amastnum 
	DROP TABLE 	#amaccts 
	DROP TABLE 	#am_new_activities 
	DROP TABLE 	#am_new_values 

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "amdoact.cpp" + ", line " + STR( 383, 5 ) + " -- EXIT: "

  	RETURN 	@result 

GO
GRANT EXECUTE ON  [dbo].[amDoActivateAdded_sp] TO [public]
GO
