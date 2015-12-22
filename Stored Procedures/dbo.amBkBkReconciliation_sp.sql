SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[amBkBkReconciliation_sp] 
( 	
	@book_num 				smLogical, 					
	@book_code 				smBookCode, 			
	@fiscal_period_start 	smApplyDate, 			
	@fiscal_period_end 		smApplyDate, 			
	@curr_precision			smallint,			
	@debug_level			smDebugLevel	= 0		
) 
AS 

DECLARE 
	@trx_type			int,
	@rowcount 			smCounter, 
	@error 				smErrorCode, 
	@co_asset_id 		smSurrogateKey, 
	@co_asset_book_id 	smSurrogateKey, 
	@cost 				smMoneyZero, 
	@accum_depr 		smMoneyZero, 
	@return_status 		int,
	@value 	 			smMoneyZero, 
	@sum_val			smMoneyZero,
	@asset_total_val 	smMoneyZero, 
	@depr_total_val 	smMoneyZero,	
	@profile_date		smApplyDate 


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ambkbkrp.sp" + ", line " + STR( 79, 5 ) + " -- ENTRY: "

SELECT @profile_date		= @fiscal_period_start
SELECT @fiscal_period_start = DATEADD(dd, 1, @fiscal_period_start)

 
SELECT 	co_asset_id,
		co_asset_book_id 
INTO 	#counter1 
FROM 	amastbk 	
WHERE 	book_code = @book_code 
AND 	co_asset_id IN ( SELECT co_asset_id FROM #amassets )

 

WHILE 1=1 
BEGIN  
	SET ROWCOUNT 1 

	 
	SELECT 	@co_asset_id 		= co_asset_id,
			@co_asset_book_id 	= co_asset_book_id 
	FROM 	#counter1 

	
	IF @@rowcount = 0 
	BEGIN 
		SET ROWCOUNT 0 
		BREAK 
	END 

	IF @debug_level >= 5	
	 	SELECT "*** co_asset_id is", @co_asset_id


	 
	EXEC @return_status = amGetPrfRep_sp 
							@co_asset_book_id,
				 			@profile_date,
							@curr_precision,
							@cost 		OUTPUT,
							@accum_depr OUTPUT 

	IF @book_num = 1 
	BEGIN  
		 
		UPDATE #ambkprf 
		SET 	book_value1 	= ISNULL(@cost, 0.0)
		WHERE 	co_asset_id 	= @co_asset_id 
		AND 	account_type 	= 0 
		AND 	type_flag 	= 1 
	
		 
		UPDATE #ambkprf 
		SET 	book_value1 	= ISNULL(@accum_depr, 0.0)
		WHERE 	co_asset_id 	= @co_asset_id 
		AND 	account_type 	= 1 
		AND 	type_flag 	= 1 

		 
		UPDATE #ambkprf 
		SET 	book_value1 	= (SIGN(ISNULL((@cost + @accum_depr), 0.0)) * ROUND(ABS(ISNULL((@cost + @accum_depr), 0.0)) + 0.0000001, @curr_precision))
		WHERE 	co_asset_id 	= @co_asset_id 
		AND 	account_type 	= 2 
		AND 	type_flag 	= 1 

	END  

	IF @book_num = 2 
	BEGIN  
		 
		UPDATE #ambkprf 
		SET 	book_value2 	= ISNULL(@cost, 0.0)
		WHERE 	co_asset_id 	= @co_asset_id 
		AND 	account_type 	= 0 
		AND 	type_flag 	= 1 
	
		 
		UPDATE #ambkprf 
		SET 	book_value2 	= ISNULL(@accum_depr, 0.0)
		WHERE 	co_asset_id 	= @co_asset_id 
		AND 	account_type 	= 1 
		AND 	type_flag 	= 1 

		 
		UPDATE #ambkprf 
		SET 	book_value2 	= (SIGN(ISNULL((@cost + @accum_depr), 0.0)) * ROUND(ABS(ISNULL((@cost + @accum_depr), 0.0)) + 0.0000001, @curr_precision))
		WHERE	co_asset_id 	= @co_asset_id 
		AND 	account_type 	= 2 
		AND 	type_flag 	= 1 

	END  



	 
	SELECT 	
		@asset_total_val 	= 0.0,
		@depr_total_val 	= 0.0,
		@sum_val 			= 0.0
		
	SELECT @asset_total_val = (SIGN(ISNULL((@asset_total_val + @cost), 0.0)) * ROUND(ABS(ISNULL((@asset_total_val + @cost), 0.0)) + 0.0000001, @curr_precision))
	SELECT @depr_total_val 	= (SIGN(ISNULL((@depr_total_val + @accum_depr), 0.0)) * ROUND(ABS(ISNULL((@depr_total_val + @accum_depr), 0.0)) + 0.0000001, @curr_precision))


	WHILE (1=1)
	BEGIN
		

		SET ROWCOUNT 1


		
		IF @book_num = 1
		BEGIN

						
			SELECT @trx_type = account_type
			FROM #ambkprf
			WHERE co_asset_id 	= @co_asset_id
			AND type_flag = 2
			AND flag_book1 = 0


			IF @@rowcount = 0 
			BEGIN 
				 
				BREAK 
			END
		END
		
			 		
		IF @book_num = 2
		BEGIN

			 			
			SELECT @trx_type = account_type
			FROM #ambkprf
			WHERE co_asset_id 	= @co_asset_id
			AND type_flag = 2
			AND flag_book2 = 0

			IF @@rowcount = 0 
			BEGIN 
				 
				BREAK 
			END
 

		END

		IF @debug_level >= 5	
			SELECT "*** trx_type is" , @trx_type
		 
		EXEC @return_status = amGetValueRep_sp 
								@co_asset_book_id,
								0,
					 			@fiscal_period_start,
					 			@fiscal_period_end,
								@trx_type,
								@curr_precision,
								@value OUTPUT 

		IF ( @return_status != 0 )
			RETURN @return_status

		SELECT @sum_val = ISNULL(@value,0.0)
		SELECT @asset_total_val = (SIGN(@asset_total_val + ISNULL(@value, 0.0)) * ROUND(ABS(@asset_total_val + ISNULL(@value, 0.0)) + 0.0000001, @curr_precision))

		 
		EXEC @return_status = amGetValueRep_sp 
								@co_asset_book_id,
								1,
					 			@fiscal_period_start,
					 			@fiscal_period_end,
								@trx_type,
								@curr_precision,
								@value OUTPUT 

		IF ( @return_status != 0 )
			RETURN @return_status

		SELECT @depr_total_val = (SIGN(@depr_total_val + ISNULL(@value, 0.0)) * ROUND(ABS(@depr_total_val + ISNULL(@value, 0.0)) + 0.0000001, @curr_precision))
		SELECT @sum_val = (SIGN(ISNULL((@sum_val + @value), 0.0)) * ROUND(ABS(ISNULL((@sum_val + @value), 0.0)) + 0.0000001, @curr_precision))


		IF @book_num = 1 
		BEGIN  

			 
			UPDATE #ambkprf 
			SET 	book_value1 	= ISNULL(@sum_val, 0.0),
					flag_book1		= 1

			WHERE 	co_asset_id 	= @co_asset_id 
			AND 	account_type 	= @trx_type 
			AND 	type_flag 	= 2 
		
		END  

		IF @book_num = 2 
		BEGIN  

			 
			UPDATE #ambkprf 
			SET 	book_value2 	= ISNULL(@sum_val, 0.0),
					flag_book2		= 1
			WHERE	co_asset_id 	= @co_asset_id 
			AND 	account_type 	= @trx_type 
			AND 	type_flag 	= 2 
		
		END  

	END 

	


	IF @book_num = 1 
	BEGIN  
		 

		UPDATE #ambkprf 
		SET 	book_value1 	= ISNULL(@asset_total_val, 0.0)
		WHERE 	co_asset_id 	= @co_asset_id 
		AND 	account_type 	= 0 
		AND 	type_flag 	= 3 
	
		 

		UPDATE #ambkprf 
		SET 	book_value1 	= ISNULL(@depr_total_val, 0.0)
		WHERE 	co_asset_id 	= @co_asset_id 
		AND 	account_type 	= 1 
		AND 	type_flag 	= 3 

		 

		UPDATE #ambkprf 
		SET 	book_value1 	= (SIGN(ISNULL((@asset_total_val + @depr_total_val), 0.0)) * ROUND(ABS(ISNULL((@asset_total_val + @depr_total_val), 0.0)) + 0.0000001, @curr_precision))
		WHERE 	co_asset_id 	= @co_asset_id 
		AND 	account_type 	= 2 
		AND 	type_flag 	= 3 

	END  

	IF @book_num = 2 
	BEGIN  
		 

		UPDATE #ambkprf 
		SET 	book_value2 	= ISNULL(@asset_total_val, 0.0)
		WHERE 	co_asset_id 	= @co_asset_id 
		AND 	account_type 	= 0 
		AND 	type_flag 	= 3 
	
		 

		UPDATE #ambkprf 
		SET 	book_value2 	= ISNULL(@depr_total_val, 0.0)
		WHERE 	co_asset_id 	= @co_asset_id 
		AND 	account_type 	= 1 
		AND 	type_flag 	= 3 

		 

		UPDATE #ambkprf 
		SET 	book_value2 	= (SIGN(ISNULL((@asset_total_val + @depr_total_val), 0.0)) * ROUND(ABS(ISNULL((@asset_total_val + @depr_total_val), 0.0)) + 0.0000001, @curr_precision))
		WHERE 	co_asset_id 	= @co_asset_id 
		AND 	account_type 	= 2 
		AND 	type_flag 	= 3 

	END  

	DELETE #counter1 

	SET ROWCOUNT 0 

END  

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ambkbkrp.sp" + ", line " + STR( 418, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amBkBkReconciliation_sp] TO [public]
GO
