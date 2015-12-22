SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO





CREATE PROCEDURE [dbo].[amRetireDisposedAssets_sp] 
(
	@co_trx_id				smSurrogateKey,		
	@company_id 			smCompanyID, 		
	@company_code			smCompanyCode,		
	@user_id				smUserID,			
	@batch_size				smCounter	= 0,	
	@show_acct_msgs			smLogical	= 1,	




	@start_org_id           	smOrgId,
	@end_org_id             	smOrgId,
	@debug_level			smDebugLevel = 0	
)
AS 


DECLARE 
	@ret_status    			smErrorCode, 		
	@message 				smErrorLongDesc, 	
	@min_from_date			smApplyDate,		
	@apply_date 			smApplyDate, 		
	@process_ctrl_num		smControlNumber		

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "amdisast.cpp" + ", line " + STR( 218, 5 ) + " -- ENTRY: "

IF @start_org_id  = '<Start>'
BEGIN
	SELECT 	@start_org_id  	= MIN(organization_id)
	FROM	amOrganization_vw
END

IF @end_org_id = '<End>'
BEGIN
	SELECT 	@end_org_id  	= MAX(organization_id)
	FROM	amOrganization_vw
END






SELECT dummy_select = 1
























IF NOT EXISTS(SELECT name FROM tempdb..sysobjects WHERE name LIKE '##amcancel%' AND type = 'U')
	CREATE TABLE ##amcancel
	(	
		spid					int			
	
	)





SELECT	@apply_date		= apply_date
FROM	amtrxhdr
WHERE	co_trx_id		= @co_trx_id





							
SELECT	@min_from_date 		= MIN(a.disposition_date)
FROM	amasset a,
	amtrxast ata,
	amOrganization_vw o
WHERE	a.co_asset_id		= ata.co_asset_id
AND	ata.co_trx_id		= @co_trx_id
AND 	a.company_id 		=  @company_id 
AND 	a.activity_state 		=  1 
AND 	a.disposition_date 	IS NOT NULL 
AND 	a.disposition_date 	<= @apply_date 
AND     a.org_id 		= o.org_id
AND     a.org_id 		BETWEEN @start_org_id AND @end_org_id


IF @min_from_date IS NULL
	SELECT	@min_from_date = @apply_date





EXEC @ret_status = amValidateAllSuspenseAccts_sp
						@company_id,
						@min_from_date,	
						@apply_date		
IF @ret_status <> 0 
	RETURN @ret_status 

EXEC @ret_status = amCancel_sp @@SPID,@debug_level IF @ret_status = 1 RETURN -1

EXEC @ret_status = amStartDeprProcess_sp
						@co_trx_id,					
						@user_id,					
						@company_id,				
						@company_code,				
						0,						
						0,					
						-103,	
						4,			
						@process_ctrl_num 	OUTPUT,	
						@debug_level
IF 	(@ret_status <> 0)
	RETURN @ret_status 

EXEC @ret_status = amDoRetireDisposed_sp
						@co_trx_id,					
						@company_id,				
						@batch_size,
						@show_acct_msgs,
						@start_org_id,			
						@end_org_id,				
						@debug_level

IF 	(@ret_status <> 0)
	RETURN @ret_status 



























IF EXISTS(SELECT name FROM tempdb..sysobjects WHERE name LIKE '##amcancel%' AND type = 'U')
BEGIN

	



   	BEGIN TRANSACTION

		DELETE ##amcancel
		WHERE  spid = @@spid

		SELECT * 
		FROM  ##amcancel

		IF @@rowcount = 0
			DROP TABLE ##amcancel

	COMMIT TRANSACTION
END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "amdisast.cpp" + ", line " + STR( 311, 5 ) + " -- EXIT: " 

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amRetireDisposedAssets_sp] TO [public]
GO
