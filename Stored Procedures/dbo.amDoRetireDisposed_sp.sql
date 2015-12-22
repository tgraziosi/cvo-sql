SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amDoRetireDisposed_sp] 
(
	@co_trx_id				smSurrogateKey,			
	@company_id 			smCompanyID, 			
	@batch_size				smCounter		= 0,	
	@show_acct_msgs			smLogical		= 1,	




	@start_org_id           	smOrgId,			
	@end_org_id             	smOrgId,			
	@debug_level			smDebugLevel	= 0		
)
AS 

DECLARE 
	@result    				smErrorCode, 		
	@message 				smErrorLongDesc, 	
	@rowcount				smCounter,			
	@co_asset_id 			smSurrogateKey, 	
	@co_asset_book_id 		smSurrogateKey, 	
	@depr_co_trx_id   		smSurrogateKey, 		
	@disp_co_trx_id   		smSurrogateKey, 		
	@cost 					smMoneyZero, 		
	@accum_depr 			smMoneyZero, 		
	@gain 					smMoneyZero, 		
	@proceeds 				smMoneyZero, 		
	@apply_date 			smApplyDate, 		
	@disposition_date 		smApplyDate, 		
	@disp_prd_end_date		smApplyDate,		
	@last_posted_depr_date	smApplyDate,		
	@start_date				smApplyDate,
	@first_time_depr		smLogical,			
	@asset_ok 				smLogical, 			
	@book_code 				smBookCode, 		
	@asset_ctrl_num 		smControlNumber,	 
	@trx_ctrl_num			smControlNumber,	
	@process_ctrl_num		smControlNumber,	
	@precision 				smallint,			
	@rounding_factor 		float,				
	@count					smCounter			

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "amdoret.cpp" + ", line " + STR( 119, 5 ) + " -- ENTRY: "




SELECT	@trx_ctrl_num	= trx_ctrl_num,
		@apply_date		= apply_date
FROM	amtrxhdr
WHERE	co_trx_id		= @co_trx_id



 





































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
	amtrxast at
WHERE 	a.co_asset_id		= at.co_asset_id
AND	at.co_trx_id		= @co_trx_id
AND 	a.company_id 		=  @company_id 
AND 	a.activity_state 		=  1 
AND 	a.disposition_date 	IS NOT NULL 
AND 	a.disposition_date 	<= @apply_date 

EXEC @result = amCancel_sp @@SPID,@debug_level IF @result = 1 RETURN -1



 











































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







EXEC @result = amCreateAllAccounts_sp
						@company_id,
						@apply_date,
						120,
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
EXEC @result = amCancel_sp @@SPID,@debug_level IF @result = 1 RETURN -1

 

























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

 
 
EXEC 	amGetCurrencyPrecision_sp 
			@precision 			OUT,
			@rounding_factor 	OUT 

IF @debug_level >= 4
	SELECT 	apply_date 	= @apply_date
    		
SELECT	@count = 0



 
SELECT 	@asset_ctrl_num 	= MIN(asset_ctrl_num)
FROM 	#amastnum 

WHILE @asset_ctrl_num IS NOT NULL 
BEGIN 

	IF @debug_level >= 5
	   SELECT	processing_asset = @asset_ctrl_num

	EXEC @result = amCancel_sp @@SPID,@debug_level IF @result = 1 RETURN -1


	 
	SELECT 	@co_asset_id 		= co_asset_id,
			@disposition_date 	= disposition_date 
	FROM 	amasset 
	WHERE 	asset_ctrl_num 		= @asset_ctrl_num 
	AND 	company_id 			= @company_id 

	 
	SELECT 	@asset_ok 			= 1  

	 
	SELECT 	@disp_co_trx_id 	= co_trx_id,
			@depr_co_trx_id		= linked_trx 
	FROM 	amtrxhdr 
	WHERE 	co_asset_id 		= @co_asset_id 
	AND 	trx_type 			= 30 

	



	EXEC	@result = amGetFiscalPeriod_sp
							@disposition_date,
							1,
							@disp_prd_end_date OUTPUT
							
	IF @result <> 0 
	BEGIN 
		DROP TABLE 	#amastnum
		DROP TABLE 	#amaccts 
		DROP TABLE 	#amastprf 
		RETURN 		@result 
	END 

	


	BEGIN TRANSACTION 

		UPDATE 	amtrxhdr
		SET		posting_flag	= 100
		FROM	amtrxhdr
		WHERE	co_trx_id		IN (@disp_co_trx_id, @depr_co_trx_id)
		AND		posting_flag	IN (0, 100)
		
		SELECT	@result = @@error, @rowcount = @@rowcount
		IF @result <> 0
		BEGIN 
			DROP TABLE 	#amastnum
			DROP TABLE 	#amaccts 
			DROP TABLE 	#amastprf 
			ROLLBACK TRANSACTION 
			RETURN 		@result 
		END 
		
		






		UPDATE 	amacthst
		SET		posting_flag	= 100
		FROM	amacthst
		WHERE	co_trx_id		IN (@disp_co_trx_id, @depr_co_trx_id)
		AND		posting_flag	= 0
		
		SELECT	@result = @@error, @rowcount = @@rowcount
		IF @result <> 0
		BEGIN 
			DROP TABLE 	#amastnum
			DROP TABLE 	#amaccts 
			DROP TABLE 	#amastprf 
			ROLLBACK TRANSACTION 
			RETURN 		@result 
		END 
	
	COMMIT TRANSACTION 
		
	IF @debug_level >= 5
		SELECT 	ah.co_trx_id,
				ah.co_asset_book_id,
				ah.trx_type,
				v.account_type_id,
				v.account_id,
				v.posting_flag 
		FROM	amacthst ah, amastbk ab, amvalues v
		WHERE	ah.co_asset_book_id = ab.co_asset_book_id
		AND		ab.co_asset_id		= @co_asset_id
		AND		ah.co_trx_id		= v.co_trx_id
		AND		ah.co_asset_book_id	= v.co_asset_book_id
	
	









 
	SELECT 	@co_asset_book_id 	= MIN(co_asset_book_id)
	FROM 	amastbk 
	WHERE 	co_asset_id 		= @co_asset_id 

	WHILE @co_asset_book_id IS NOT NULL 
	BEGIN 
		
		 
		SELECT 	@cost				= 0.0,
				@accum_depr			= 0.0,
				@gain 				= 0.0,
				@proceeds 			= 0.0
		
		SELECT	@last_posted_depr_date	= last_posted_depr_date
		FROM	amastbk
		WHERE	co_asset_book_id		= @co_asset_book_id
		
		IF @last_posted_depr_date IS NULL
		BEGIN
			SELECT 	@first_time_depr 	= 1,
					@start_date 		= NULL		 
		END
		ELSE
		BEGIN
			SELECT	@first_time_depr 	= 0,
					@start_date			= DATEADD(dd, 1, @last_posted_depr_date)

			SELECT  @cost 				= current_cost,
			        @accum_depr 		= accum_depr 
			FROM    amastprf 
			WHERE   co_asset_book_id 	= @co_asset_book_id 
			AND     fiscal_period_end 	= @last_posted_depr_date 
		END
					

		IF @debug_level >= 5
		    SELECT 	last_posted_depr_date	= @last_posted_depr_date,
		    		old_cost 				= @cost, 
		    		old_accum_depr 			= @accum_depr 
		
		




		EXEC @result 	= amApplyStartPeriodActivity_sp
									@co_asset_book_id,
									@first_time_depr,
									@start_date,
									@disposition_date,
									@precision,
									@cost 				OUTPUT,
									@accum_depr 		OUTPUT,
									0,	
									@debug_level
		IF @result <> 0
			RETURN @result

		IF @debug_level >= 5
		    SELECT 	new_cost 			= @cost, 
		    		new_accum_depr 		= @accum_depr

		


 
		IF ((ABS((@cost)-(0.0)) > 0.0000001))
		OR ((ABS((@accum_depr)-(0.0)) > 0.0000001))
		BEGIN 

			IF @debug_level >= 1
		    BEGIN
			    SELECT 	cost_balance 		= @cost, 
			    		accum_depr_balance 	= @accum_depr,
			    		rounding_factor 	= @rounding_factor
			END
		
			SELECT 	@book_code 			= book_code
			FROM 	amastbk 
			WHERE 	co_asset_book_id 	= @co_asset_book_id 

			SELECT 	@asset_ok = 0 

			EXEC 		amGetErrorMessage_sp 20172, "amdoret.cpp", 400, @asset_ctrl_num, @book_code, @error_message = @message out 
			IF @message IS NOT NULL RAISERROR 	20172 @message 
			BREAK 		 
		END 
		
		 
		EXEC @result = amCreateProfile_sp 
							@co_asset_book_id, 
							@disp_prd_end_date,
							0.0,		 
							0.0,		 
		   					1		 
		IF @result <> 0 
		BEGIN 
			DROP TABLE #amastnum
			DROP TABLE #amaccts 
			DROP TABLE #amastprf 
			RETURN @result 
		END 

		

 
		SELECT 	@gain 				= amount 
		FROM 	amvalues 
		WHERE 	co_trx_id 			= @disp_co_trx_id 
		AND 	co_asset_book_id 	= @co_asset_book_id 
		AND 	account_type_id 	= 8 

		SELECT 	@proceeds 			= amount 
		FROM 	amvalues a 
		WHERE 	co_trx_id 			= @disp_co_trx_id 
		AND 	co_asset_book_id 	= @co_asset_book_id 
		AND 	account_type_id 	= 4 

		UPDATE 	amastbk 
		SET 	gain_loss 			= @gain,
				proceeds 			= @proceeds 
		FROM 	amastbk 
		WHERE 	co_asset_book_id 	= @co_asset_book_id 
		
		SELECT @result = @@error
		IF @result <> 0 
		BEGIN 
			DROP TABLE #amastnum
			DROP TABLE #amaccts 
			DROP TABLE #amastprf 
			RETURN @result 
		END 

		 
		SELECT 	@co_asset_book_id 	= MIN(co_asset_book_id)
		FROM 	amastbk 
		WHERE 	co_asset_id 		= @co_asset_id 
		AND 	co_asset_book_id 	> @co_asset_book_id 

	END 
	
	 
	IF @asset_ok = 0 
	BEGIN 
		UPDATE 	#amastprf 
		SET 	posting_flag 		= 0 
		FROM 	#amastprf 	ap,	
				amastbk 	ab 
		WHERE 	ap.co_asset_book_id = ab.co_asset_book_id 
		AND 	ab.co_asset_id 		= @co_asset_id 
		
		SELECT @result = @@error
		IF @result <> 0 
		BEGIN 
			DROP TABLE #amastnum
			DROP TABLE #amaccts 
			DROP TABLE #amastprf 
			RETURN @result 
		END 

		BEGIN TRANSACTION 
			




			UPDATE 	amtrxhdr
			SET		posting_flag	= 0
			FROM	amtrxhdr
			WHERE	co_trx_id		IN (@disp_co_trx_id, @depr_co_trx_id)
			AND		posting_flag	= 100
			
			SELECT	@result = @@error, @rowcount = @@rowcount
			IF @result <> 0
			BEGIN 
				DROP TABLE 	#amastnum
				DROP TABLE 	#amaccts 
				DROP TABLE 	#amastprf 
				ROLLBACK TRANSACTION 
				RETURN 		@result 
			END 
			
			






			UPDATE 	amacthst
			SET		posting_flag	= 0
			FROM	amacthst
			WHERE	co_trx_id		IN (@disp_co_trx_id, @depr_co_trx_id)
			AND		posting_flag	= 100
			
			SELECT	@result = @@error, @rowcount = @@rowcount
			IF @result <> 0
			BEGIN 
				DROP TABLE 	#amastnum
				DROP TABLE 	#amaccts 
				DROP TABLE 	#amastprf 
				ROLLBACK TRANSACTION 
				RETURN 		@result 
			END 
		
		COMMIT TRANSACTION 
 	END 
	ELSE
	BEGIN
		 
		EXEC @result = amUpdateActivityAccountIDs_sp 
								@company_id,
								@co_asset_id,
								@debug_level
								
		IF @result <> 0 
		BEGIN 
			DROP TABLE #amastnum
			DROP TABLE #amaccts 
			DROP TABLE #amastprf 
			RETURN @result 
		END 
				
		IF @debug_level >= 5
			SELECT 	ah.co_trx_id,
					ah.co_asset_book_id,
					ah.trx_type,
					v.account_type_id,
					v.account_id,
					v.posting_flag 
			FROM	amacthst ah, amastbk ab, amvalues v
			WHERE	ah.co_asset_book_id = ab.co_asset_book_id
			AND		ab.co_asset_id		= @co_asset_id
			AND		ah.co_trx_id		= v.co_trx_id
			AND		ah.co_asset_book_id	= v.co_asset_book_id

		BEGIN TRANSACTION 
		
			











			UPDATE 	amasset 
			SET 	activity_state 	= 101,
					rem_quantity	= 0					
			FROM 	amasset 
			WHERE 	co_asset_id 	= @co_asset_id 
			AND		activity_state	= 1	

			SELECT @result = @@error, @rowcount = @@rowcount 
			IF @result <> 0 
			BEGIN 
				DROP TABLE 	#amastnum
		  		DROP TABLE 	#amaccts 
		  		DROP TABLE	#amastprf 
				ROLLBACK TRANSACTION 
		  		RETURN 		@result 
			END 

			IF @rowcount > 0
			BEGIN
				




				UPDATE	amastprf
				SET		current_cost 			= tmp.current_cost,
						accum_depr				= tmp.accum_depr,
						effective_date			= tmp.effective_date
				FROM	#amastprf tmp,
						amastprf ap
				WHERE	ap.co_asset_book_id		= tmp.co_asset_book_id
				AND		ap.fiscal_period_end	= tmp.fiscal_period_end
				AND 	tmp.posting_flag 		= 1 

				SELECT @result = @@error 
				IF ( @result != 0 ) 
				BEGIN 
					DROP TABLE 	#amastnum
			  		DROP TABLE 	#amaccts 
			  		DROP TABLE	#amastprf 
					ROLLBACK TRANSACTION 
			  		RETURN 		@result 
				END 
				
				


				DELETE	amastprf
				FROM	#amastprf tmp,
						amastprf ap
				WHERE	ap.co_asset_book_id		= tmp.co_asset_book_id
				AND		ap.fiscal_period_end	= tmp.fiscal_period_end

				SELECT @result = @@error 
				IF ( @result != 0 ) 
				BEGIN 
					DROP TABLE 	#amastnum
			  		DROP TABLE 	#amaccts 
			  		DROP TABLE	#amastprf 
					ROLLBACK TRANSACTION 
			  		RETURN 		@result 
				END 
				
				



 
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

				SELECT @result = @@error 
				IF ( @result != 0 ) 
				BEGIN 
					DROP TABLE 	#amastnum
			  		DROP TABLE 	#amaccts 
			  		DROP TABLE	#amastprf 
					ROLLBACK TRANSACTION 
			  		RETURN 		@result 
				END 

			
				



				UPDATE 	amacthst
				SET		journal_ctrl_num	= @trx_ctrl_num,
						posting_flag		= -1
				FROM	amastbk ab,
						amacthst ah
				WHERE	ab.co_asset_id		= @co_asset_id
				AND		ab.co_asset_book_id	= ah.co_asset_book_id
				AND		ah.posting_flag		NOT IN (-1, 1)
				
				SELECT @result = @@error
				IF @result <> 0 
				BEGIN 
					DROP TABLE 	#amastnum
					DROP TABLE 	#amaccts 
					DROP TABLE 	#amastprf 
					ROLLBACK TRANSACTION
					RETURN 		@result 
				END 
				
			END
			
			
			DELETE FROM #amastprf

		COMMIT TRANSACTION 
	END

	 
	SELECT 	@asset_ctrl_num 	= MIN(asset_ctrl_num)
	FROM 	#amastnum 
	WHERE 	asset_ctrl_num 		>  @asset_ctrl_num 

	


 
	SELECT @count = @count + 1 

	IF 	(@batch_size > 0)
	AND (@count = @batch_size) 
	BEGIN 
		EXEC 		amGetErrorMessage_sp 20300, "amdoret.cpp", 708, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20300 @message 

		SELECT 		@count = 0
	END  
END 




 
EXEC 		amGetErrorMessage_sp 20301, "amdoret.cpp", 719, @error_message = @message OUT 
IF @message IS NOT NULL RAISERROR 	20301 @message 
 


 
DROP TABLE 	#amastnum 
DROP TABLE 	#amaccts 
DROP TABLE 	#amastprf 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "amdoret.cpp" + ", line " + STR( 729, 5 ) + " -- EXIT: "
 
RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amDoRetireDisposed_sp] TO [public]
GO
