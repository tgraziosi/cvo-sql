SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amDepreciate_sp] 
( 
	@co_trx_id 	 		smSurrogateKey, 	 
	@company_id 			smCompanyID, 		
	@start_book				smBookCode,			
	@end_book				smBookCode,			
	@do_post 			smLogical	= 0,
	@batch_size				smCounter	= 0,	
	@show_acct_msgs			smLogical	= 1,	
	@break_down_by_prd		smLogical	= 0,
	@start_org_id                   smOrgId,
	@end_org_id                     smOrgId,
	@debug_level			smDebugLevel = 0, 	
	@perf_level				smPerfLevel = 0		
)
AS 







DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()


 


DECLARE 
	@result		 			smErrorCode, 		
	@message 				smErrorLongDesc, 	
	@param1 				smErrorParam, 		
	@apply_date				smApplyDate,		
	@apply_date_jul			smJulianDate,		 
	@last_date 				smJulianDate,		 
	@last_posted_depr_date 	smApplyDate, 		
	@start_date 			smApplyDate,		 
	@placed_in_service_date	smApplyDate,		 
	@acquisition_date		smApplyDate,		 
	@fe_counter 			smCounter, 			
	@be_counter 			smCounter, 			
	@asset_ctrl_num 		smControlNumber, 	
	@co_asset_id 			smSurrogateKey, 	
	@co_asset_book_id 		smSurrogateKey, 	
	@depr_exp_acct_id 		smSurrogateKey, 	
	@accum_depr_acct_id 	smSurrogateKey, 	
	@depr_expense 			smMoneyZero, 		
	@cost 					smMoneyZero, 		
	@accum_depr 			smMoneyZero, 		
	@cur_precision 			smallint,			
	@round_factor 			float,				
	@trx_ctrl_num			smControlNumber,	
	@book_code				smBookCode,			
	@is_new					int,
	@asset_org_id                   varchar(30) 

DECLARE
	@old_perf_level			smPerfLevel
	
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amdepr.sp" + ", line " + STR( 140, 5 ) + " -- ENTRY: "
IF ( @perf_level >= 1 ) EXEC perf_sp "Depreciate", "tmp/amdepr.sp", 141, "Entry amDepreciate_sp", @PERF_time_last OUTPUT

IF @debug_level >= 5
	SELECT 	do_post 	= @do_post,
		start_book	= @start_book,
		end_book	= @end_book 


SELECT	@apply_date		= apply_date,
		@trx_ctrl_num	= trx_ctrl_num
FROM	amtrxhdr
WHERE	co_trx_id		= @co_trx_id

IF @debug_level >= 5
BEGIN
	SELECT	apply_date, trx_ctrl_num
	FROM	amtrxhdr
         WHERE	co_trx_id		= @co_trx_id
	
END


 
EXEC @result = amGetCurrencyPrecision_sp 
						@cur_precision 	OUTPUT,
						@round_factor 	OUTPUT 

IF @result <> 0 
	RETURN @result 


IF @debug_level >= 5
BEGIN
	SELECT cur_precision = @cur_precision , round_factor = @round_factor
	
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
SELECT	DISTINCT						
		a.co_asset_id,
		a.asset_ctrl_num
FROM	amasset	a,
	amastbk	ab,
	amtrxast att,
	amOrganization_vw o
WHERE 	a.company_id 				= @company_id 
AND 	a.co_asset_id				= att.co_asset_id
AND     a.org_id                                =  o.org_id
AND     a.org_id   BETWEEN @start_org_id AND @end_org_id 
AND 	att.co_trx_id				= @co_trx_id
AND 	ab.book_code	 			BETWEEN @start_book AND @end_book
AND		a.co_asset_id				= ab.co_asset_id
AND 	a.activity_state 			= 0 		 
AND 	a.acquisition_date 			<= @apply_date 		 
AND		(ab.last_posted_depr_date	< @apply_date		
	OR	ab.last_posted_depr_date	IS NULL)
	
	

EXEC @result = amCancel_sp @@SPID,@debug_level IF @result = 1 RETURN -1


EXEC @result = amCreateAllAccounts_sp
						@company_id,
						@apply_date,
						50,
						@start_book,
						@end_book,
						@show_acct_msgs,
						@start_org_id,
	                                        @end_org_id,
						@debug_level,
						@perf_level
						
IF @result <> 0 
BEGIN 
	DROP TABLE #amastnum 
	DROP TABLE #amaccts
	RETURN @result 
END 

/*rev JVC */

IF @debug_level >= 5
BEGIN
    SELECT ' #amastnum '
    select * from #amastnum
    SELECT ' #amaccts '
    select * from #amaccts
END

/* JVC */



CREATE TABLE #amastprf
(
	co_asset_book_id	int			NOT NULL,
	fiscal_period_end	datetime	NOT NULL,
	current_cost		float		NOT NULL,
	accum_depr			float		NOT NULL,
	effective_date		datetime	NOT NULL,
	posting_flag		tinyint		NOT NULL
)

CREATE UNIQUE INDEX #amastprf_ind_0 ON #amastprf (co_asset_book_id, fiscal_period_end)



CREATE TABLE #amvalues
(
	co_asset_book_id	int,
	co_asset_id		int,
	account_type_id		smallint,
	apply_date		datetime,
	trx_type		tinyint,
	cost			float,		
	accum_depr		float,		
	amount			float,	 	
	account_id		int
)



CREATE TABLE #amfstdpr
(
	co_asset_id		int,		
	co_asset_book_id	int,		
	original_cost		float,		
	post_to_gl		tinyint		
)



CREATE TABLE #amcalval
(
	co_asset_book_id	int,			
	apply_date		datetime,		
	beg_cost		float,			
	beg_accum_depr		float,			
	end_cost		float,			
	end_accum_depr		float,			
	ytd_depr		float,	 		
	year_end_date		datetime NULL	
)


 
SELECT 	@asset_ctrl_num 	= MIN(asset_ctrl_num)
FROM 	#amastnum 

SELECT  @asset_org_id = a.org_id
FROM    amasset a
WHERE   a.asset_ctrl_num 	= @asset_ctrl_num AND
        a.company_id 	= @company_id
      
        


SELECT 	@fe_counter = 0,
		@be_counter = 0 

IF ( @perf_level >= 2 ) EXEC perf_sp "Depreciate", "tmp/amdepr.sp", 242, "Beginning loop through assets", @PERF_time_last OUTPUT

WHILE @asset_ctrl_num IS NOT NULL 
BEGIN 

	IF @debug_level >= 3
		SELECT asset_ctrl_num = @asset_ctrl_num,
		       asset_org_id = @asset_org_id

	EXEC @result = amCancel_sp @@SPID,@debug_level IF @result = 1 RETURN -1

	SELECT	@co_asset_id 		= co_asset_id,
		@acquisition_date	= acquisition_date,
		@is_new			= is_new
	FROM	amasset
	WHERE	company_id 		= @company_id
	AND	asset_ctrl_num 		= @asset_ctrl_num
	AND     org_id                  = @asset_org_id  
	
	
	EXEC @result = amGetDeprAccounts_sp 	
							@company_id,
							@co_asset_id,
							@apply_date,
							@depr_exp_acct_id 	OUTPUT,
							@accum_depr_acct_id OUTPUT,
							@debug_level
 

	IF ( @result <> 0 )
		GOTO error_target
	
	
	
	 
	SELECT 	@co_asset_book_id 	= MIN(co_asset_book_id)
	FROM 	amastbk 
	WHERE 	co_asset_id 		= @co_asset_id 
	AND		book_code			BETWEEN	@start_book AND @end_book

	IF ( @perf_level >= 2 ) EXEC perf_sp "Depreciate", "tmp/amdepr.sp", 282, "Beginning loop through books", @PERF_time_last OUTPUT
	
	
	
	 
	WHILE @co_asset_book_id IS NOT NULL 
	BEGIN 

            	
		EXEC @result = amCancel_sp @@SPID,@debug_level IF @result = 1 RETURN -1


		 
		SELECT 	@depr_expense 		= 0.0, 
			 	@cost 				= 0.0, 
				@accum_depr 		= 0.0
		
		 
		SELECT 	@last_posted_depr_date 	= last_posted_depr_date,
				@placed_in_service_date	= placed_in_service_date,
				@book_code				= book_code
		FROM 	amastbk 
		WHERE 	co_asset_book_id 		= @co_asset_book_id 

	        IF @debug_level >= 3
	        BEGIN
			SELECT "Beginning loop through books" 
			
			SELECT co_asset_id = @co_asset_id,
				apply_date = @apply_date,
				depr_exp_acct_id = @depr_exp_acct_id,
				accum_depr_acct_id = @accum_depr_acct_id, 
	                        co_asset_book_id = @co_asset_book_id,
	                        placed_in_service_date	= @placed_in_service_date,
				last_posted_depr_date	= @last_posted_depr_date 
				
				
				
                END
			

		 
		IF 	(@placed_in_service_date IS NOT NULL)
		AND (@placed_in_service_date <= @apply_date)
		BEGIN 	
		
			
			SELECT	@apply_date_jul = DATEDIFF(dd, "1/1/1980", @apply_date) + 722815 - 1

			IF @last_posted_depr_date IS NULL
				SELECT 	@last_date 	= DATEDIFF(dd, "1/1/1980", @placed_in_service_date) + 722815
			ELSE
				SELECT	@last_date	= DATEDIFF(dd, "1/1/1980", DATEADD(dd, 1, @last_posted_depr_date)) + 722815
				 
			IF 	@do_post = 0
			OR 	NOT EXISTS(SELECT 	period_start_date
								FROM 	glprd
								WHERE	period_end_date	BETWEEN	@last_date AND @apply_date_jul
								AND		period_type		= 1003)
			BEGIN
			 	
				 
				IF (@last_posted_depr_date IS NULL)
				BEGIN 
					SELECT	@start_date	= NULL
					EXEC @result = amSetFirstDeprDate_sp 
										@co_asset_book_id,
										@placed_in_service_date 

					IF ( @result != 0 ) 
						GOTO error_target
				END 
				ELSE
					SELECT	@start_date	= DATEADD(dd, 1, @last_posted_depr_date)
				
				
				IF 	(@last_posted_depr_date IS NOT NULL)
				BEGIN 
					 
					SELECT 	@cost 				= ISNULL(current_cost, 0.0), 
							@accum_depr 		= ISNULL(accum_depr, 0.0)
					FROM 	amastprf 
					WHERE 	co_asset_book_id 	= @co_asset_book_id 
					AND 	fiscal_period_end 	= @last_posted_depr_date 
				END 
				
				IF ( @perf_level >= 2 ) EXEC perf_sp "Depreciate", "tmp/amdepr.sp", 367, "Fetched initial data", @PERF_time_last OUTPUT

				
				IF (@last_posted_depr_date IS NULL)
				OR (@last_posted_depr_date < @apply_date)
				BEGIN 
					
					IF @do_post = 1 
					BEGIN 

						 
						UPDATE 	amtrxhdr 
						SET 	posting_flag 		= 100,
								journal_ctrl_num	= @trx_ctrl_num
						FROM 	amtrxhdr trx,
								amastbk ab 	
						WHERE 	trx.apply_date 		<= @apply_date
						AND		trx.co_asset_id		= ab.co_asset_id 
						AND 	ab.co_asset_book_id = @co_asset_book_id 
		 				AND		posting_flag 		= 0

		 				SELECT @result = @@error 
						IF @result <> 0 
							GOTO error_target

						IF ( @perf_level >= 2 ) EXEC perf_sp "Depreciate", "tmp/amdepr.sp", 400, "Updated amtrxhdr", @PERF_time_last OUTPUT
						
						 
						UPDATE 	amacthst 
						SET 	posting_flag 		= 100,
								journal_ctrl_num	= @trx_ctrl_num
						FROM 	amacthst 	
						WHERE 	apply_date 			<= @apply_date 
						AND 	co_asset_book_id 	= @co_asset_book_id 
		 				AND		posting_flag 		= 0

		 				SELECT @result = @@error 
						IF @result <> 0 
							GOTO error_target

						IF ( @perf_level >= 2 ) EXEC perf_sp "Depreciate", "tmp/amdepr.sp", 423, "Updated amacthst", @PERF_time_last OUTPUT
						
						 
						UPDATE 	amdprhst 
						SET 	posting_flag 		= 1 
						FROM 	amdprhst 
						WHERE 	effective_date 		<= @apply_date 
						AND 	co_asset_book_id 	= @co_asset_book_id 
		 				AND		posting_flag 		= 0

						SELECT @result = @@error 
						IF @result <> 0 
							GOTO error_target

						IF ( @perf_level >= 2 ) EXEC perf_sp "Depreciate", "tmp/amdepr.sp", 442, "Updated amdprhst", @PERF_time_last OUTPUT
						
						 
						UPDATE 	ammandpr 
						SET 	posting_flag 		= 1 
						FROM 	ammandpr 
						WHERE 	fiscal_period_end 	<= @apply_date 
						AND 	co_asset_book_id 	= @co_asset_book_id 
		 				AND		posting_flag 		= 0

						SELECT @result = @@error 
						IF @result <> 0 
							GOTO error_target

						IF ( @perf_level >= 2 ) EXEC perf_sp "Depreciate", "tmp/amdepr.sp", 460, "Updated ammandpr", @PERF_time_last OUTPUT
						
					END 

					 
 					EXEC @result = amCalcAssetBookDepr_sp 	
									@co_asset_id,
									@co_asset_book_id,
									@is_new,					
									@start_date, 				 
									@apply_date, 				 
									@depr_exp_acct_id,
									@accum_depr_acct_id,
									@acquisition_date,			
									@placed_in_service_date,	 
									@do_post,	 				 
									@break_down_by_prd,
									@cur_precision,				 
									@round_factor, 				 
					 				@cost 	 			OUTPUT,  
						 			@accum_depr 		OUTPUT,  
						 			@depr_expense 		OUTPUT,	 
									@debug_level,
									@perf_level

					IF ( @result <> 0 )
						GOTO error_target

					IF ( @perf_level >= 2 ) EXEC perf_sp "Depreciate", "tmp/amdepr.sp", 494, "Calculated asset book depreciation", @PERF_time_last OUTPUT

				END 
			END	
			ELSE
			BEGIN
				 
				EXEC 		amGetErrorMessage_sp 26001, "tmp/amdepr.sp", 501, @asset_ctrl_num, @book_code, @error_message = @message OUT 
				IF @message IS NOT NULL RAISERROR 	26001 @message 
			END
	 	END  
	 
	 	ELSE
		BEGIN
			 
			EXEC 		amGetErrorMessage_sp 26000, "tmp/amdepr.sp", 509, @asset_ctrl_num, @book_code, @error_message = @message OUT 
			IF @message IS NOT NULL RAISERROR 	26000 @message 
		
			IF @do_post = 1 
			BEGIN 

				 
				UPDATE 	amtrxhdr 
				SET 	posting_flag 		= 100,
						journal_ctrl_num	= @trx_ctrl_num
				FROM 	amtrxhdr trx,
						amastbk ab 	
				WHERE 	trx.apply_date 		<= @apply_date
				AND		trx.co_asset_id		= ab.co_asset_id 
				AND 	ab.co_asset_book_id = @co_asset_book_id 
				AND		posting_flag 		= 0

				SELECT @result = @@error 
				IF @result <> 0 
					GOTO error_target

				 
				UPDATE 	amacthst 
				SET 	posting_flag 		= 100,
						journal_ctrl_num	= @trx_ctrl_num
				FROM 	amacthst 	
				WHERE 	apply_date 			<= @apply_date 
				AND 	co_asset_book_id 	= @co_asset_book_id 
				AND		posting_flag 		= 0

				SELECT @result = @@error 
				IF @result <> 0 
					GOTO error_target

				EXEC @result = amProcessUnplaced_sp 
										@apply_date,
										@co_asset_book_id,
										@cur_precision, 
						 				@cost 			OUTPUT,
						 				@accum_depr 	OUTPUT,
						 				@debug_level = @debug_level

				IF @result <> 0
					GOTO error_target

			END
		END

		 
		SELECT 	@co_asset_book_id 	= MIN(co_asset_book_id)
		FROM 	amastbk 
		WHERE 	co_asset_id 		= @co_asset_id 
		AND		book_code			BETWEEN @start_book AND @end_book
		AND 	co_asset_book_id 	> @co_asset_book_id 

	END  
	
	IF ( @perf_level >= 2 ) EXEC perf_sp "Depreciate", "tmp/amdepr.sp", 582, "Ending loop through books", @PERF_time_last OUTPUT 	

	EXEC @result = amCancel_sp @@SPID,@debug_level IF @result = 1 RETURN -1

	
	IF (@do_post = 1)
	BEGIN
		EXEC @result = amUpdateActivityAccountIDs_sp
							@company_id,
							@co_asset_id,
							@debug_level
		IF @result != 0 
			GOTO error_target
		
		IF ( @perf_level >= 2 ) EXEC perf_sp "Depreciate", "tmp/amdepr.sp", 599, "Updated accounts", @PERF_time_last OUTPUT
	END
		

	 
	SELECT 	@asset_ctrl_num 	= MIN(asset_ctrl_num)
	FROM 	#amastnum 
	WHERE 	asset_ctrl_num 		> @asset_ctrl_num 
	
	/* rev */
	SELECT  @asset_org_id = a.org_id
	FROM    amasset a , amOrganization_vw o
	WHERE   a.asset_ctrl_num 	= @asset_ctrl_num
	       AND a.company_id 	= @company_id 
	       AND a.org_id        = o.org_id
	       AND a.org_id     BETWEEN @start_org_id AND @end_org_id 
	        
               
        /* rev */

	SELECT 	@fe_counter = @fe_counter + 1,
			@be_counter = @be_counter + 1 
	
	EXEC @result = amCancel_sp @@SPID,@debug_level IF @result = 1 RETURN -1

	 
	IF 	(@be_counter = 100)
	OR 	(@asset_ctrl_num IS NULL)
	BEGIN 
		EXEC @result = amUpdateDepreciation_sp 
									@co_trx_id,
									@apply_date,
									@do_post,
									@debug_level,
									@perf_level
									 

		IF ( @result != 0 ) 
			GOTO error_target
		
		SELECT @be_counter = 0
		
		IF ( @perf_level >= 2 ) EXEC perf_sp "Depreciate", "tmp/amdepr.sp", 633, "Updated depreciation", @PERF_time_last OUTPUT
	END 

	 
	IF 	(@batch_size > 0)
	AND (@fe_counter = @batch_size) 
	BEGIN 
		EXEC 		amGetErrorMessage_sp 20300, "tmp/amdepr.sp", 648, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20300 @message 

		SELECT @fe_counter = 0
	END 

END  

IF ( @perf_level >= 2 ) EXEC perf_sp "Depreciate", "tmp/amdepr.sp", 656, "Ending loop through assets", @PERF_time_last OUTPUT


 
EXEC 		amGetErrorMessage_sp 20301, "tmp/amdepr.sp", 663, @error_message = @message OUT 
IF @message IS NOT NULL RAISERROR 	20301 @message 

error_target:

 
DROP TABLE 	#amastnum 
DROP TABLE 	#amvalues 
DROP TABLE 	#amfstdpr 
DROP TABLE 	#amcalval 
DROP TABLE 	#amastprf 
DROP TABLE 	#amaccts


IF @result = 0
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/amdepr.sp" + ", line " + STR( 680, 5 ) + " -- EXIT: "

IF ( @perf_level >= 1 ) EXEC perf_sp "Depreciate", "tmp/amdepr.sp", 682, "Exit amDepreciate_sp", @PERF_time_last OUTPUT
RETURN @result 
GO
GRANT EXECUTE ON  [dbo].[amDepreciate_sp] TO [public]
GO
