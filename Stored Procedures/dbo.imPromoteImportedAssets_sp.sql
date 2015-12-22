SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE [dbo].[imPromoteImportedAssets_sp] 
(
	@company_id 		smCompanyID, 		
	@start_asset 		smControlNumber, 	
	@end_asset 			smControlNumber, 	
	@stop_on_error		smLogical,			
	@batch_size			smCounter,			
	@debug_level		smDebugLevel	= 0	
)
AS 

DECLARE 
	@ret_status 		smErrorCode, 
	@message 			smErrorLongDesc, 
	@co_asset_id 		smSurrogateKey, 
	@is_valid 			smLogical, 
	@asset_ctrl_num 	smControlNumber, 
	@cur_prd_end_date 	smApplyDate, 		
	@cur_yr_start_date 	smApplyDate, 		
	@prev_yr_end_date 	smApplyDate, 		
	@str_pos			smCounter,
	@count				smCounter,
	@curr_precision		smallint,			
	@rounding_factor	float					

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imprmimp.sp" + ", line " + STR( 92, 5 ) + " -- ENTRY: "



IF NOT EXISTS(SELECT name FROM tempdb..sysobjects WHERE name LIKE '##amcancel%' AND type = 'U')
	CREATE TABLE ##amcancel
	(	
		spid					int			
	
	)



EXEC	@ret_status = amGetCurrencyPrecision_sp
						@curr_precision		OUTPUT,
						@rounding_factor 	OUTPUT

IF @ret_status <> 0
	RETURN @ret_status

 
EXEC @ret_status = amGetCurrentFiscalPeriod_sp 
						@company_id,
						@cur_prd_end_date OUTPUT 
IF @ret_status <> 0 
	RETURN @ret_status 

EXEC @ret_status = amGetFiscalYear_sp 
						@cur_prd_end_date,
						0,
						@cur_yr_start_date 	OUTPUT 
IF @ret_status <> 0 
	RETURN @ret_status 

SELECT 	@prev_yr_end_date = DATEADD(dd, -1, @cur_yr_start_date)

IF @debug_level >= 3
	SELECT 	cur_yr_start 	= @cur_yr_start_date,
			start_asset 	= @start_asset,
			end_asset 		= @end_asset 


IF @start_asset = "<Start>"
BEGIN
	SELECT 	@start_asset 	= MIN(asset_ctrl_num)
	FROM	amasset
	WHERE	company_id		= @company_id
END

IF @end_asset = "<End>"
BEGIN
	SELECT 	@end_asset 		= MAX(asset_ctrl_num)
	FROM	amasset
	WHERE	company_id		= @company_id
END





CREATE TABLE #imastprf
(
	co_asset_book_id	int			NOT NULL,
	fiscal_period_end	datetime	NOT NULL,
	current_cost		float		NOT NULL,
	accum_depr			float		NOT NULL,
	effective_date		datetime 	NOT NULL
)




CREATE TABLE #imbkinfo
(
	co_asset_book_id	int			NOT NULL,	
	last_depr_date		datetime 	NULL		
)




CREATE TABLE #am_new_activities
(
	co_trx_id			int		 	NOT NULL, 
	trx_ctrl_num		char(16)	NOT NULL,
	co_asset_id			int			NOT NULL,
	co_asset_book_id	int			NOT NULL, 
	apply_date			datetime 	NOT NULL, 
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
	apply_date			datetime 	NOT NULL, 
	trx_type			tinyint		NOT NULL, 
 	amount				float		NOT NULL, 
	account_id			int			NOT NULL 
)


 
SELECT 	@asset_ctrl_num 	= MIN(asset_ctrl_num)
FROM 	amasset 
WHERE 	asset_ctrl_num 		BETWEEN @start_asset AND @end_asset 
AND 	company_id 			= @company_id 
AND 	activity_state 		= 100 
AND		is_imported			= 1

SELECT @count = 1 

WHILE @asset_ctrl_num IS NOT NULL 
BEGIN 

	IF @debug_level >= 3
		SELECT 	asset_ctrl_num 	= @asset_ctrl_num

	EXEC @ret_status = amCancel_sp @@SPID,@debug_level IF @ret_status = 1 RETURN -1

	
	SELECT	@co_asset_id 		= co_asset_id
	FROM	amasset
	WHERE 	asset_ctrl_num 		= @asset_ctrl_num 
	AND 	company_id 			= @company_id 
	
	
	EXEC @ret_status = imCheckAssetForPromotion_sp
						@co_asset_id,
						@cur_yr_start_date,
						@stop_on_error,
						@curr_precision,
						@is_valid	OUTPUT,
						@debug_level	= @debug_level

	IF @ret_status <> 0
	BEGIN
		DROP TABLE #imastprf
		DROP TABLE #imastprf
		DROP TABLE #am_new_activities
		DROP TABLE #am_new_values
		RETURN @ret_status

	END
	
	IF @is_valid = 1
	BEGIN
		IF @debug_level >= 3
			SELECT "Promoting Asset!!!"

		EXEC	@ret_status = imPromoteAsset_sp
								@company_id,
								@co_asset_id,
								@cur_yr_start_date,
								@curr_precision,
								@debug_level	= @debug_level
		IF @ret_status <> 0
		BEGIN
			IF @debug_level >= 3
				SELECT "imPromoteAsset_sp failed"
			DROP TABLE #imastprf
			DROP TABLE #imbkinfo
			DROP TABLE #am_new_activities
			DROP TABLE #am_new_values
			RETURN @ret_status
		END
		ELSE
		BEGIN
			EXEC 		amGetErrorMessage_sp 20400, "tmp/imprmimp.sp", 227, @asset_ctrl_num, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	20400 @message 
		END

	END

	 
	SELECT 	@asset_ctrl_num 	= 	MIN(asset_ctrl_num)
	FROM 	amasset 
	WHERE 	activity_state 		= 	100 
	AND 	asset_ctrl_num 		> 	@asset_ctrl_num 
	AND 	asset_ctrl_num 		<= 	@end_asset 
	AND 	company_id 			= 	@company_id 
	AND		is_imported			= 1

	
	 
	IF 	(@batch_size > 0)
	AND (@count = @batch_size) 
	BEGIN 
		EXEC 		amGetErrorMessage_sp 20300, "tmp/imprmimp.sp", 252, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20300 @message 

		SELECT 		@count = 0
	END 

	SELECT @count = @count + 1 

END 
	
 

EXEC 		amGetErrorMessage_sp 20301, "tmp/imprmimp.sp", 267, @error_message = @message OUT 
IF @message IS NOT NULL RAISERROR 	20301 @message 


DROP TABLE #imastprf
DROP TABLE #imbkinfo
DROP TABLE #am_new_activities
DROP TABLE #am_new_values




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


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imprmimp.sp" + ", line " + STR( 280, 5 ) + " -- EXIT: "
 
RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[imPromoteImportedAssets_sp] TO [public]
GO
