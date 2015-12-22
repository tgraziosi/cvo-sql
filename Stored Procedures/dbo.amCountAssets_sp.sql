SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amCountAssets_sp] 
(
	@co_trx_id smSurrogateKey,		 	 
	@num_assets		smCounter		OUTPUT,
	@start_org_id              smOrgId,
	@end_org_id                 smOrgId, 
	@debug_level	smDebugLevel	= 0		
)
AS 

DECLARE 
	@result		 	smErrorCode, 			
	@message 		smErrorLongDesc, 		
	@company_id		smCompanyID,			
	@start_book 	smBookCode, 			 
	@end_book 		smBookCode,				 
	@apply_date		smApplyDate,				
	@trx_type		smTrxType				


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amcntast.sp" + ", line " + STR( 69, 5 ) + " -- ENTRY: " 


IF @start_org_id  = '<Start>' or @start_org_id = ''
BEGIN
	SELECT 	@start_org_id  	= MIN(org_id)
	FROM	amOrganization_vw
END

IF @end_org_id = '<End>' or @end_org_id = ''
BEGIN
	SELECT 	@end_org_id  	= MAX(org_id)
	FROM	amOrganization_vw
END

IF ( @debug_level > 1 ) 
BEGIN
   SELECT start_org_id = @start_org_id,
          end_org_id = @end_org_id

END



SELECT 	@num_assets = 0,
		@apply_date	= NULL

 
SELECT	@trx_type	= trx_type,
		@apply_date	= apply_date,
		@company_id	= company_id
FROM	amtrxhdr
WHERE	co_trx_id	= @co_trx_id

IF @apply_date IS NULL 
BEGIN 
	DECLARE		@param	smErrorParam
	
	SELECT		@param = RTRIM(CONVERT(char(255), @co_trx_id))
	EXEC 		amGetErrorMessage_sp 20120, "tmp/amcntast.sp", 88, @param, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20120 @message 
	RETURN 		20120 
END 


IF @trx_type = 50
BEGIN
	
	EXEC @result = amGetBookRange_sp 
						@co_trx_id,
						@start_book 	OUTPUT,
						@end_book		OUTPUT,
						@debug_level
	IF ( @result <> 0 )
		RETURN 	@result 
	
	SELECT 	@num_assets 				= COUNT(DISTINCT a.asset_ctrl_num)
	FROM	amasset	a,
		amastbk	ab,
		amtrxast att,
		amOrganization_vw o
	WHERE 	a.company_id 				= @company_id 
	AND	a.co_asset_id				= att.co_asset_id
	AND     a.org_id         = o.org_id
	AND     a.org_id                        BETWEEN @start_org_id AND @end_org_id
	AND	att.co_trx_id				= @co_trx_id
	AND 	a.activity_state 			= 0 		 
	AND 	a.acquisition_date 			<= @apply_date 		 
	AND		a.co_asset_id				= ab.co_asset_id
	AND		ab.book_code				BETWEEN @start_book AND @end_book
	AND		(ab.last_posted_depr_date	< @apply_date		
		OR	ab.last_posted_depr_date	IS NULL)
END

ELSE IF @trx_type = 100
BEGIN
	SELECT 	@num_assets 		= COUNT(a.asset_ctrl_num)
	FROM 	amasset a,
		amtrxast att,
		amOrganization_vw o
	WHERE 	a.co_asset_id				= att.co_asset_id
	AND	att.co_trx_id				= @co_trx_id
	AND 	a.company_id 			= 	@company_id 
	AND     a.org_id           =   o.org_id
	AND     a.org_id                        BETWEEN @start_org_id AND @end_org_id
	AND 	a.activity_state 		= 	100 
	AND 	a.acquisition_date 	<= 	@apply_date 	
	AND		a.is_imported			= 	0
END

ELSE	
BEGIN
	SELECT 	@num_assets		 	= COUNT(a.asset_ctrl_num)
	FROM 	amasset a,
		amtrxast att,
		amOrganization_vw o
	WHERE 	a.co_asset_id				= att.co_asset_id
	AND	att.co_trx_id				= @co_trx_id
	AND 	a.company_id 			= @company_id 
	AND 	a.activity_state 		= 1 
	AND     a.org_id            = o.org_id
	AND     a.org_id                        BETWEEN @start_org_id AND @end_org_id
	AND 	a.disposition_date 	IS NOT NULL 
	AND 	a.disposition_date 	<= @apply_date 	 
END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amcntast.sp" + ", line " + STR( 153, 5 ) + " -- EXIT: " 
 
RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amCountAssets_sp] TO [public]
GO
