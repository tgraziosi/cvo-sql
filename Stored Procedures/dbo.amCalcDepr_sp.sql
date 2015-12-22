SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO






CREATE PROCEDURE [dbo].[amCalcDepr_sp] 
( 
	@co_trx_id 	 		smSurrogateKey, 	 
	@company_id 			smCompanyID, 		
	@company_code			smCompanyCode,		
	@user_id				smUserID,			
	@do_post 			smLogical, 			
	@batch_size				smCounter	= 0,	
	@show_acct_msgs			smLogical	= 1,
	@start_org_id                   smOrgId,
	@end_org_id                     smOrgId,
	@break_down_by_prd		smLogical	= 0,
	@debug_level			smDebugLevel 	= 0,
	@perf_level				smPerfLevel 	= 0	
)
AS 







DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()









DECLARE 
	@result		 			smErrorCode, 		
	@param1 				smErrorParam, 		
	@message 				smErrorLongDesc, 	
	@prd_end_date 			smApplyDate, 		
	@min_from_date			smApplyDate, 		
	@apply_date 			smApplyDate, 		
	@start_book 			smBookCode,		 	 
	@end_book 				smBookCode,			 	
	@process_ctrl_num		smProcessCtrlNum,
	@sspid                          smallint 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amclcdpr.sp" + ", line " + STR( 103, 5 ) + " -- ENTRY: "
IF ( @perf_level >= 1 ) EXEC perf_sp "", "tmp/amclcdpr.sp", 104, "Entry amCalcDepr_sp", @PERF_time_last OUTPUT

SELECT @sspid = @@SPID

IF ( @debug_level >= 9 )
BEGIN 
    SELECT ID_Procss = @sspid	
END    


SELECT dummy_select = 1


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

IF @debug_level >= 3
    SELECT  start_org_id = @start_org_id,
            end_org_id = @end_org_id  


IF @debug_level >= 3
	SELECT 	co_trx_id = @co_trx_id, 	 
		company_id = @company_id, 		
		company_code = @company_code,		
		user_id = @user_id,			
		do_post = @do_post, 			
		batch_size =  @batch_size,	
		show_acct_msgs = @show_acct_msgs,	
		break_down_by_prd = @break_down_by_prd,
		start_org_id = @start_org_id,
		end_org_id = @end_org_id,
		debug_level = @debug_level,
	        perf_level = @perf_level



IF NOT EXISTS(SELECT name FROM tempdb..sysobjects WHERE name LIKE '##amcancel%' AND type = 'U')
	CREATE TABLE ##amcancel
	(	
		spid					int			
	
	)

	


 
SELECT @apply_date = NULL 

EXEC @result = amGetTrxApplyDate_sp 
							@co_trx_id,  
					 		@apply_date OUTPUT 

IF ( @result <> 0 )
BEGIN   
        SELECT 'Fail Get apply_date -- amGetTrxApplyDate_sp amtrxhdr no row'
	RETURN 	@result 
END	

IF @debug_level >= 3
	SELECT 	fiscal_period_end = @apply_date 

 
EXEC 	@result = amGetFiscalPeriod_sp 
							@apply_date,
							1,
							@prd_end_date OUTPUT 
IF @debug_level >= 3
	SELECT 	'If the ResultGetFiscalPeriod not eq to 0 then Abort',
	        prd_end_date = @prd_end_date,
	        ResultGetFiscalPeriod =  @prd_end_date ,
	        '--  amGetFiscalPeriod_sp '

IF @result <> 0 
	RETURN @result 



IF @apply_date <> @prd_end_date 
BEGIN 
	SELECT 		@param1 = RTRIM(CONVERT(char(100), @apply_date))
	EXEC 		amGetErrorMessage_sp 20033, "tmp/amclcdpr.sp", 150, @param1, @error_message = @message OUT 
	IF @message IS NOT NULL RAISERROR 	20033 @message 
	RETURN 		20033 

END 


EXEC @result = amGetBookRange_sp 
					@co_trx_id,
					@start_book 	OUTPUT,
					@end_book		OUTPUT,
					@debug_level

IF @result <> 0 
BEGIN     
        SELECT ' Fail Get Book Range -- amGetBookRange_sp'
	RETURN @result 
END

SELECT	@min_from_date 		= MIN(ab.last_posted_depr_date)
FROM	amasset a,
	amastbk ab,
	amtrxast att,
	amOrganization_vw o 
WHERE	a.co_asset_id 		= ab.co_asset_id
AND	a.company_id		= @company_id
AND     a.org_id                =  o.org_id
AND     a.org_id   BETWEEN @start_org_id AND @end_org_id 
AND	a.co_asset_id		= att.co_asset_id
AND	att.co_trx_id		= @co_trx_id
AND	ab.book_code		BETWEEN @start_book 	AND @end_book

IF @min_from_date IS NULL
	
	SELECT	@min_from_date 		= MIN(acquisition_date)
	FROM	amasset	a,
		amastbk ab,
		amtrxast att,
		amOrganization_vw o
	WHERE	a.company_id		= @company_id
        AND     a.org_id                =  o.org_id
        AND     a.org_id   BETWEEN @start_org_id AND @end_org_id 
        AND	a.co_asset_id		= att.co_asset_id
	AND	att.co_trx_id		= @co_trx_id
	AND	ab.book_code		BETWEEN @start_book AND @end_book
	AND	a.co_asset_id		= ab.co_asset_id
ELSE
	SELECT	@min_from_date	= DATEADD(dd, 1, @min_from_date)	

EXEC @result = amCancel_sp @@SPID,@debug_level 

IF @result = 1 
BEGIN
   SELECT ' amCancel_sp result = True'
   RETURN -1
END

EXEC @result = amValidateAllSuspenseAccts_sp
						@company_id,
						@min_from_date,	
						@apply_date,	
						@debug_level
IF @result <> 0
BEGIN
        SELECT 'Fail Validate Suspense Accts   --  amValidateAllSuspenseAccts_sp '
	RETURN @result 
END



DELETE 
FROM 	amcalval 
WHERE 	co_trx_id = @co_trx_id 

SELECT @result = @@error
IF @result <> 0 
	RETURN @result 



EXEC @result = amCancel_sp @@SPID,@debug_level IF @result = 1 RETURN -1

IF @do_post = 1
BEGIN
	
	EXEC @result = amStartDeprProcess_sp
							@co_trx_id,					
							@user_id,					
							@company_id,				
							@company_code,				
							1,
							0,
							-100,
							1,
							@process_ctrl_num 	OUTPUT	
	IF 	(@result <> 0)
		RETURN 	@result 
END

EXEC @result = amDepreciate_sp
					@co_trx_id, 		 
					@company_id, 		
					@start_book,
					@end_book,
					@do_post, 			
					@batch_size,
					@show_acct_msgs,
					@break_down_by_prd,
					@start_org_id,
					@end_org_id, 
					@debug_level,
					@perf_level			


 
 IF ( @result <> 0)
	RETURN 	@result 



IF @do_post = 1 
BEGIN
	EXEC @result = amEndDeprProcess_sp
						@company_id,
						@co_trx_id,
						1,
						-100,
						100,
						@process_ctrl_num,
						NULL		
	IF @result <> 0
		RETURN @result

END





IF EXISTS(SELECT name FROM tempdb..sysobjects WHERE name LIKE '##amcancel%' AND type = 'U')
BEGIN

	
 	BEGIN TRANSACTION

		DELETE ##amcancel
		WHERE spid = @@spid

		SELECT * 
		FROM ##amcancel

		IF @@rowcount = 0
			DROP TABLE ##amcancel

	COMMIT TRANSACTION
END


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amclcdpr.sp" + ", line " + STR( 299, 5 ) + " -- EXIT: "
IF ( @perf_level >= 1 ) EXEC perf_sp "", "tmp/amclcdpr.sp", 300, "Exit amCalcDepr_sp", @PERF_time_last OUTPUT

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amCalcDepr_sp] TO [public]
GO
