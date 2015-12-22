SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amUpdateDepreciation_sp] 
(
	@co_trx_id		smSurrogateKey,		
	@apply_date 	smApplyDate, 		 
	@do_post 		smLogical, 			
	@debug_level	smDebugLevel = 0, 	
	@perf_level		smPerfLevel = 0 	
)
AS 






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







DECLARE 
	@ret_status 	smErrorCode, 		
	@message 		smErrorLongDesc, 	
	@jul_apply_date	smJulianDate		

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amupddpr.sp" + ", line " + STR( 192, 5 ) + " -- ENTRY: "
IF ( @perf_level >= 1 ) EXEC perf_sp "", "tmp/amupddpr.sp", 193, "Entry amUpdateDepreciation_sp", @PERF_time_last OUTPUT

IF @debug_level >= 5
	SELECT do_post = @do_post

SELECT @jul_apply_date = DATEDIFF(dd, "1/1/1980", @apply_date) + 722815

IF @do_post = 1 
BEGIN 

	BEGIN TRAN  
	 
		 
		IF EXISTS (SELECT co_asset_book_id FROM #amvalues)
		BEGIN
			IF @debug_level >= 5
				SELECT "The temp values table contains rows"

			INSERT amvalues 
			( 
				co_trx_id,
				co_asset_book_id,
				account_type_id,
				apply_date,
				trx_type,
				amount, 
				account_id,
				posting_flag 
			)
			SELECT 
				@co_trx_id,
				co_asset_book_id,
				account_type_id,
				apply_date,
				trx_type,
				amount,
				account_id,
				100		 
			FROM #amvalues 

			SELECT @ret_status = @@error 
			IF ( @ret_status != 0 ) 
			BEGIN 
				ROLLBACK TRAN 
		 		RETURN 	@ret_status 
			END 
	 	END
		
		IF ( @perf_level >= 2 ) EXEC perf_sp "", "tmp/amupddpr.sp", 245, "Inserted Values", @PERF_time_last OUTPUT

		 
		DELETE 	amastprf 
		FROM 	#amastprf 	tmp,
				amastprf 	ap 
		WHERE 	ap.co_asset_book_id 	= tmp.co_asset_book_id 
		AND 	ap.fiscal_period_end 	>= tmp.fiscal_period_end

		SELECT @ret_status = @@error 
		IF ( @ret_status != 0 ) 
		BEGIN 
			ROLLBACK TRAN 
	 		RETURN @ret_status 
		END 
		
		IF ( @perf_level >= 2 ) EXEC perf_sp "", "tmp/amupddpr.sp", 268, "Removed old profiles", @PERF_time_last OUTPUT
				
		INSERT amastprf 
		( 
				co_asset_book_id,
			 	fiscal_period_end,
			 	current_cost,
			 	accum_depr,
			 	effective_date 
		)
		SELECT 
				co_asset_book_id,
				fiscal_period_end,
				current_cost,
				accum_depr,
				effective_date 
		FROM 	#amastprf 
		WHERE 	posting_flag = 1 

		SELECT @ret_status = @@error 
		IF ( @ret_status != 0 ) 
		BEGIN 
			ROLLBACK TRAN 
	 		RETURN @ret_status 
		END 
		
		IF ( @perf_level >= 2 ) EXEC perf_sp "", "tmp/amupddpr.sp", 294, "Inserted new profiles", @PERF_time_last OUTPUT
		
		 
		UPDATE 	amastbk 
		SET 	last_depr_co_trx_id 		= @co_trx_id,
				prev_posted_depr_date		= ab.last_posted_depr_date,
				last_posted_depr_date 		= @apply_date 
		FROM 	#amvalues 	v,
				amastbk 	ab
		WHERE 	v.co_asset_book_id			= ab.co_asset_book_id
		AND		v.account_type_id			= 1

		SELECT @ret_status = @@error 
		IF @ret_status <> 0
		BEGIN 
			ROLLBACK TRAN 
			RETURN @ret_status 
		END 

		IF ( @perf_level >= 2 ) EXEC perf_sp "", "tmp/amupddpr.sp", 322, "Updated astbk", @PERF_time_last OUTPUT
		
		 
		UPDATE 	amasset 
		SET 	depreciated 				= 1,			
				original_cost				= tmp.original_cost 
		FROM 	#amfstdpr 	tmp,
				amasset 	a,
				amOrganization_vw o
		WHERE 	a.co_asset_id 				= tmp.co_asset_id 
		AND 	tmp.post_to_gl 				= 1
		AND     a.org_id  = o.org_id

		SELECT @ret_status = @@error 
		IF @ret_status <> 0 
		BEGIN 
			ROLLBACK TRAN 
			RETURN @ret_status 
		END 

		IF ( @perf_level >= 2 ) EXEC perf_sp "", "tmp/amupddpr.sp", 345, "Updated asset for posting book", @PERF_time_last OUTPUT
		
		 
		UPDATE 	amasset 
		SET 	depreciated 				= 1 
		FROM 	#amfstdpr 	tmp,
				amasset 	a,
				amOrganization_vw o
		WHERE 	a.co_asset_id 				= tmp.co_asset_id 
		AND		tmp.post_to_gl				= 0
		AND 	a.depreciated 				= 0
		AND     a.org_id  = o.org_id

		SELECT @ret_status = @@error 
		IF @ret_status <> 0 
		BEGIN 
			ROLLBACK TRAN 
			RETURN @ret_status 
		END 

		IF ( @perf_level >= 2 ) EXEC perf_sp "", "tmp/amupddpr.sp", 368, "Updated asset for non-posting books", @PERF_time_last OUTPUT


	COMMIT TRAN 


END 
ELSE  
BEGIN 
	 

	IF @debug_level >= 5
	BEGIN
		SELECT 	"Contents of #amcalval" 
		SELECT * from #amcalval 
	
		SELECT 	"Contents of #amaccts" 
		SELECT * from #amaccts 
	END 

	INSERT amcalval 
	( 
			co_trx_id,
		 	apply_date,
		 	co_asset_book_id,
		 	co_asset_id,
		 	book_code,
			placed_in_service_date,
		 	beg_cost,
		 	beg_accum_depr,
		 	end_cost,
		 	end_accum_depr,
		 	account_reference_code,
		 	depr_exp_account,
		 	accum_depr_account,
		 	amount,
		 	year_end_date 
	)
	SELECT 
		 	@co_trx_id, 	
	 	 	cv.apply_date,
	 	 	cv.co_asset_book_id,
		 	ab.co_asset_id,
		 	ab.book_code,
			ab.placed_in_service_date,
			cv.beg_cost,		  
			cv.beg_accum_depr,
			cv.end_cost,
			cv.end_accum_depr,
		 	acct.account_reference_code,
		 	acct.new_account_code,
		 	 "DUMMY",
		 	cv.ytd_depr,
		 	cv.year_end_date 

	FROM 	#amcalval 	cv, #amaccts acct,
			amastbk 	ab,
			amdprhst 	dh,
			amdprrul 	dr
	WHERE 	cv.co_asset_book_id 		= ab.co_asset_book_id 
	AND 	cv.co_asset_book_id 		= dh.co_asset_book_id 
	AND 	dh.effective_date 	= 
					(SELECT ISNULL( MAX(effective_date),"99990101")
					FROM 	amdprhst 
					WHERE 	co_asset_book_id 	= cv.co_asset_book_id 
					AND 	effective_date 		<= @apply_date)
	AND 	dh.depr_rule_code 			= dr.depr_rule_code 
	AND 	ab.co_asset_id 				= acct.co_asset_id 
	AND		acct.jul_apply_date			= @jul_apply_date
	AND 	acct.account_type_id	 	= 5 

	SELECT @ret_status = @@error 
	IF ( @ret_status != 0 ) 
 		RETURN @ret_status 

	UPDATE 	amcalval 
	SET 	accum_depr_account	 	= acct.new_account_code 
	FROM 	#amaccts 	acct,
			amcalval 	cv 
	WHERE 	cv.co_trx_id			= @co_trx_id
	AND		cv.co_asset_id 		 	= acct.co_asset_id 
	AND		acct.jul_apply_date	 	= @jul_apply_date
	AND 	acct.account_type_id 	= 1 


	SELECT @ret_status = @@error 
	IF ( @ret_status != 0 ) 
 		RETURN @ret_status 

END 

 
TRUNCATE TABLE #amvalues 
TRUNCATE TABLE #amfstdpr 
TRUNCATE TABLE #amcalval 
TRUNCATE TABLE #amastprf 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amupddpr.sp" + ", line " + STR( 465, 5 ) + " -- EXIT: "
IF ( @perf_level >= 1 ) EXEC perf_sp "", "tmp/amupddpr.sp", 466, "Exit amUpdateDepreciation_sp", @PERF_time_last OUTPUT

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amUpdateDepreciation_sp] TO [public]
GO
