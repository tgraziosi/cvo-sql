SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amDeprSummaryRep_sp] 
( 	
	@book_code 			smBookCode, 		
	@period_start 		datetime, 			
	@period_end 		datetime, 			
	@debug_level		smDebugLevel	= 0	
) 
AS 

DECLARE 
	@result 				smErrorCode,
	@co_asset_book_id 		smSurrogateKey, 
	@is_imported			smLogical,
	@cost 					smMoneyZero, 
	@accum_depr 			smMoneyZero, 
	@depr_exp 				smMoneyZero, 
	@counter 				smCounter, 
	@ctr 					smCounter, 
	@n_ctr 					smCounter, 
	@ctrnum					smCounter, 
	@ctrnum_o 				smCounter, 
	@rule_cd 				smDeprRuleCode, 
	@conv_id 				smConventionID, 
	@dpr_code 				smDeprRuleCode, 
	@cnv_id 				smConventionID, 
	@book_value  			smMoneyZero, 
	@fiscal_period_start 	smApplyDate, 
	@fiscal_period_end 		smApplyDate,
	@company_id				smCompanyID,
	@curr_precision			smallint,			
	@rounding_factor		float				
 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "AMDPSMRP.cpp" + ", line " + STR( 148, 5 ) + " -- ENTRY: "

SELECT 	@fiscal_period_start 	= CONVERT(datetime, @period_start)
SELECT 	@fiscal_period_end 		= CONVERT(datetime, @period_end)




EXEC	@result = amGetCurrencyPrecision_sp
					@curr_precision		OUTPUT,
					@rounding_factor 	OUTPUT

IF @result <> 0
	RETURN @result






EXEC @result = amGetCompanyID_sp
						@company_id OUTPUT
						
IF @result <> 0 
	RETURN @result




 























CREATE TABLE #amrldprp
(	
	ctr_code		smallint 	NOT NULL,
	depr_rule_code	char(8) 	NOT NULL,
	depr_conv_id	tinyint 	NOT NULL
)





















CREATE TABLE #amctrast
(	
	ctr_code	 		int NOT NULL,
	co_asset_book_id 	int NOT NULL
)




SELECT 	@counter 	= 0,
	@ctr 		= 0 
 

WHILE 1=1  
BEGIN 	 
 
	SET ROWCOUNT 1 

	SELECT 	@co_asset_book_id = co_asset_book_id 
	FROM 	#counter1 

	IF @@rowcount = 0 
	BEGIN 
		SET ROWCOUNT 0 
		BREAK 
	END 
	 
	IF @debug_level >= 3
		SELECT 	co_asset_book_id 	= @co_asset_book_id,
				fiscal_period_end 	= @fiscal_period_end

	
	SELECT 	@rule_cd 			= depr_rule_code 
	FROM 	amdprhst 
	WHERE 	co_asset_book_id 	= @co_asset_book_id 
	AND 	effective_date  	= (SELECT 	MAX(effective_date)
				  					FROM 	amdprhst 
				  					WHERE 	effective_date 		<= @fiscal_period_end 
				  					AND 	co_asset_book_id 	= @co_asset_book_id )
	   	
	IF @debug_level >= 3
		SELECT rule_code = @rule_cd

	SELECT 	@conv_id 		= convention_id 
	FROM 	amdprrul 
	WHERE 	depr_rule_code 	= @rule_cd 

	IF @counter = 0 
	BEGIN 
		SELECT 	@counter 	= @counter + 1,
				@ctr   		= @ctr + 1 

		INSERT #amrldprp 
		(
			ctr_code,
			depr_rule_code,
			depr_conv_id 
		)
		VALUES 
		(
			@ctr,
			@rule_cd,
			@conv_id  
		)

		INSERT #amctrast 
		(	
			ctr_code,
			co_asset_book_id
		)
		VALUES 
		(
			@ctr,
	 		@co_asset_book_id 
	 	)
 
	 	DELETE #counter1 

		SET ROWCOUNT 0 

		CONTINUE 

	END 

	IF @rule_cd IN (SELECT depr_rule_code 
			 		FROM 	#amrldprp )
		
	BEGIN 

		SELECT 	@n_ctr			= ctr_code
		FROM 	#amrldprp
		WHERE 	depr_rule_code 	= @rule_cd

		INSERT #amctrast 
		(	
			ctr_code,
			co_asset_book_id
		)
		VALUES 
		(
			@n_ctr,
	 		@co_asset_book_id 
	 	)
	END 
	ELSE 
	BEGIN 
		
		SELECT @ctr   = @ctr + 1 

		INSERT #amrldprp 
		(
			ctr_code,
			depr_rule_code,
			depr_conv_id 
		)
		VALUES 
		(
			@ctr,
			@rule_cd,
			@conv_id
		)

		INSERT #amctrast 
		(	
			ctr_code,
			co_asset_book_id
		)
		VALUES 
		(
			@ctr,
			@co_asset_book_id 
		)

	END 

	DELETE #counter1 

	SET ROWCOUNT 0 

END   

SET ROWCOUNT 0 



 
INSERT 	#amdpsmrp 
(
	book_code,
	depr_rule_code,
	depr_conv_id,
	cost,
	accum_depr,
	book_value,
	depr_expense
)
SELECT 	@book_code,
		depr_rule_code,
		depr_conv_id,
		0.0,
		0.0,
		0.0,
		0.0 
FROM 	#amrldprp 

SELECT 	@counter = 0 ,
		@ctrnum = 0

WHILE 1=1 

BEGIN 	  

	SET ROWCOUNT 1 

	SELECT 	@co_asset_book_id 	= co_asset_book_id,
			@ctrnum 	  		= ctr_code 
	FROM 	#amctrast 

	IF @@rowcount = 0 
	BEGIN 
		SET ROWCOUNT 0 
		BREAK 
	END 

	SELECT  @cost 		= 0.0,
			@accum_depr = 0.0,
			@depr_exp 	= 0.0 
			
	SELECT  @dpr_code 	= depr_rule_code,
			@cnv_id 	= depr_conv_id 
	FROM 	#amrldprp 
	WHERE   ctr_code 	= @ctrnum 


	 
	EXEC @result = amGetPrfRep_sp 
							@co_asset_book_id,
				 			@fiscal_period_end,
							@curr_precision,
							@cost 				OUTPUT,
							@accum_depr 		OUTPUT 

	IF ( @result != 0 )
		RETURN @result 


	SELECT 	@depr_exp 			= (SIGN(ISNULL(SUM(amount), 0.0)) * ROUND(ABS(ISNULL(SUM(amount), 0.0)) + 0.0000001, @curr_precision))
	FROM 	amvalues 
	WHERE 	co_asset_book_id 	= @co_asset_book_id 
	AND 	account_type_id  	= 5 
	AND 	trx_type  			IN (50, 60)
	AND 	apply_date 			>= @fiscal_period_start 
	AND 	apply_date 			<= @fiscal_period_end 
	AND		posting_flag		= 1

	UPDATE 	#amdpsmrp 
	SET 	cost 			= (SIGN(cost + @cost) * ROUND(ABS(cost + @cost) + 0.0000001, @curr_precision)),
			accum_depr 		= (SIGN(accum_depr - @accum_depr) * ROUND(ABS(accum_depr - @accum_depr) + 0.0000001, @curr_precision)), 
			book_value 		= (SIGN(book_value + ISNULL((@cost + @accum_depr), 0.0)) * ROUND(ABS(book_value + ISNULL((@cost + @accum_depr), 0.0)) + 0.0000001, @curr_precision)), 
			depr_expense 	= (SIGN(depr_expense + @depr_exp) * ROUND(ABS(depr_expense + @depr_exp) + 0.0000001, @curr_precision))
	FROM 	#amdpsmrp  
	WHERE 	book_code 		= @book_code 
	AND 	depr_rule_code 	= @dpr_code 
	AND 	depr_conv_id 	= @cnv_id 
	
	DELETE #amctrast 

	SET ROWCOUNT 0 

END   



 
SELECT 	* 
FROM 	#amdpsmrp 
ORDER BY depr_rule_code




 
DROP TABLE #amrldprp 
DROP TABLE #amctrast 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "AMDPSMRP.cpp" + ", line " + STR( 420, 5 ) + " -- EXIT: "

RETURN 
GO
GRANT EXECUTE ON  [dbo].[amDeprSummaryRep_sp] TO [public]
GO
