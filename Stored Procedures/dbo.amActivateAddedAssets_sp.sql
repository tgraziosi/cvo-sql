SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO





CREATE PROCEDURE [dbo].[amActivateAddedAssets_sp] 
(
	@co_trx_id				smSurrogateKey,		
	@company_id 			smCompanyID, 		
	@company_code			smCompanyCode,		
	@user_id				smUserID,			
	@batch_size				smCounter	= 0,	
	@show_acct_msgs			smLogical	= 1,	




	@start_org_id           	smOrgId,
	@end_org_id             	smOrgId,
	@debug_level			smDebugLevel 	= 0	
)
AS 

DECLARE 
	@ret_status    			smErrorCode, 		
	@message 				smErrorLongDesc, 	
	@start_asset			smControlNumber,	
	@end_asset				smControlNumber,  	
	@process_ctrl_num		smControlNumber,	
	@min_from_date 			smApplyDate,		 
	@apply_date 			smApplyDate			 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "amactast.cpp" + ", line " + STR( 233, 5 ) + " -- ENTRY: "
























IF NOT EXISTS(SELECT name FROM tempdb..sysobjects WHERE name LIKE '##amcancel%' AND type = 'U')
	CREATE TABLE ##amcancel
	(	
		spid					int			
	
	)


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

IF @debug_level > 0
	SELECT 	company_id  	= @company_id,
		co_trx_id	  	= @co_trx_id 






SELECT dummy_select = 1




SELECT	@apply_date		= apply_date
FROM	amtrxhdr
WHERE	co_trx_id		= @co_trx_id


IF @debug_level >= 3
	SELECT 	apply_date 		= @apply_date 	
 





SELECT	@min_from_date 		= MIN(acquisition_date)
FROM	amasset a,
	amtrxast ata,
	amOrganization_vw o
WHERE	a.company_id		= 	@company_id
AND	a.co_asset_id		=	ata.co_asset_id
AND	ata.co_trx_id		=	@co_trx_id	
AND 	a.activity_state 	=  	100 
AND 	a.acquisition_date 	<= 	@apply_date 
AND	a.is_imported		= 	0
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
						-102,	
						3,			
						@process_ctrl_num 	OUTPUT	
IF 	(@ret_status <> 0)
	RETURN @ret_status 




EXEC @ret_status = amDoActivateAdded_sp
						@co_trx_id,					
						@company_id,
						@user_id,					
						@batch_size,
						@show_acct_msgs,
						@debug_level
IF 	(@ret_status <> 0)
	RETURN @ret_status 





EXEC @ret_status = amEndDeprProcess_sp
					@company_id,
					@co_trx_id,
					1,
					-102,
					1,
					@process_ctrl_num,
					NULL		
IF @ret_status <> 0
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


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "amactast.cpp" + ", line " + STR( 352, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amActivateAddedAssets_sp] TO [public]
GO
