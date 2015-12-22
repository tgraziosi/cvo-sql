SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[amQuickPrdRecRep_sp] 
( 	
	@company_id 		smCompanyID, 					
	@book_code 			smBookCode, 					
	@period_start  		datetime, 						
	@period_end 		datetime, 						
	@classification_id	smSurrogateKey 			= 0,	


	@debug_level		smDebugLevel 			= 0 	
) 
AS 

DECLARE 
	@rowcount 				smCounter, 
	@result 				smErrorCode,
	@co_asset_id1      		smSurrogateKey,       
	@co_asset_id2 			smSurrogateKey, 
	@is_imported			smLogical,
	@co_asset_id 			smSurrogateKey, 
	@co_asset_book_id 		smSurrogateKey, 
	@asset_first_num 		smControlNumber, 
	@asset_secnd_num 		smControlNumber, 
	@beg_cost 				smMoneyZero, 
	@beg_accum_depr 		smMoneyZero, 
	@end_cost 				smMoneyZero, 
	@end_accum_depr 		smMoneyZero, 
	@book_value 			smMoneyZero, 
	@ytd_depr_exp			smMoneyZero, 
	@profile_date 			smApplyDate, 
	@fiscal_period_start 	smApplyDate, 
	@fiscal_period_end 		smApplyDate,
	@curr_precision			smallint,			
	@rounding_factor		float				

							
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'amqkpdrp.cpp' + ', line ' + STR( 94, 5 ) + ' -- ENTRY: '

SELECT 	@profile_date 			= CONVERT(datetime, @period_start)
SELECT 	@fiscal_period_start 	= DATEADD(dd, 1, @profile_date)
SELECT 	@fiscal_period_end 		= CONVERT(datetime, @period_end)




EXEC	@result = amGetCurrencyPrecision_sp
					@curr_precision		OUTPUT,
					@rounding_factor 	OUTPUT

IF @result <> 0
	RETURN @result




 
CREATE table #ampdrep2
(	
	asset_ctrl_num		char(16)	NOT NULL,
	co_asset_id			int			NOT NULL,
	classification_code	char(8)		NULL,
	depr_rule_code		char(8)		NOT NULL,
	beg_cost			float 		NOT NULL,
	end_cost			float 		NOT NULL,
	beg_accum_depr		float 		NOT NULL,
	end_accum_depr		float 		NOT NULL,
	ytd_depr_exp		float 		NOT NULL,
	org_id varchar(30) NULL, 
 	region_id varchar(30) NULL 	
)


 

INSERT #ampdrep2 
( 
	asset_ctrl_num,
	co_asset_id,
	classification_code,
	depr_rule_code,
	beg_cost,
	end_cost,
	beg_accum_depr, 
	end_accum_depr, 
	ytd_depr_exp,
	org_id,
	region_id	
)
SELECT 
	a.asset_ctrl_num,
	tmp.co_asset_id,
	tmp.classification_code,
	dh.depr_rule_code, 
	0.0,
	0.0,
	0.0,
	0.0,
	0.0,
	tmp.org_id,
	tmp.region_id	
FROM 	#amassets tmp,
		amasset a,
		amastbk ab,
		amdprhst dh
WHERE 	ab.book_code 		= @book_code 
AND 	ab.co_asset_id 		= tmp.co_asset_id
AND		ab.co_asset_id	= a.co_asset_id
AND		a.co_asset_id	 = tmp.co_asset_id
AND		ab.co_asset_book_id = dh.co_asset_book_id
AND		dh.effective_date  = (SELECT MAX(effective_date)
					FROM amdprhst
					WHERE co_asset_book_id 	= ab.co_asset_book_id
					AND  effective_date <= @fiscal_period_end)
	
	
IF @debug_level >= 3
	SELECT	*
	FROM	#ampdrep2




 

SELECT 	co_asset_id,
		co_asset_book_id 
INTO 	#counter1 
FROM 	amastbk 	
WHERE 	book_code 		= @book_code 
AND 	co_asset_id 	IN ( SELECT co_asset_id FROM #amassets )

 

SELECT	@co_asset_book_id = MIN(co_asset_book_id)
FROM	#counter1

WHILE @co_asset_book_id IS NOT NULL
BEGIN
 

	
	IF @debug_level >= 3
		SELECT	co_asset_book_id = @co_asset_book_id
	
	SELECT 	@co_asset_id 		= co_asset_id 
	FROM 	#counter1 
	WHERE	co_asset_book_id	= @co_asset_book_id

	 
	SELECT 	
			@beg_cost		= 0.0,
			@end_cost		= 0.0,
			@beg_accum_depr	= 0.0,
			@end_accum_depr	= 0.0,
			@ytd_depr_exp 	= 0.0

	 
	EXEC @result = amGetPrfRep_sp 
							@co_asset_book_id,
				 			@profile_date,
							@curr_precision,
							@beg_cost			OUTPUT,
							@beg_accum_depr 	OUTPUT,
							@debug_level 


	 
	EXEC @result = amGetPrfRep_sp 
							@co_asset_book_id,
				 			@fiscal_period_end,
							@curr_precision,
							@end_cost 				OUTPUT,
							@end_accum_depr 		OUTPUT,
							@debug_level 
 

	


	EXEC @result = amGetValueRep_sp 
							@co_asset_book_id,
							5,
				 			@fiscal_period_start,
				 			@fiscal_period_end,
							50,
							@curr_precision,
							@ytd_depr_exp OUTPUT 

	IF ( @result != 0 )
		RETURN @result 

	IF @debug_level >= 3
		SELECT	beg_cost 		= @beg_cost,
				end_cost		= @end_cost,
				beg_accum_depr	= @beg_accum_depr,
				end_accum_depr	= @end_accum_depr,
				ytd_depr_exp	= @ytd_depr_exp
	
	UPDATE 	#ampdrep2 
	SET 	beg_cost		= @beg_cost,
			end_cost		= @end_cost,
			beg_accum_depr	= -@beg_accum_depr,
			end_accum_depr	= -@end_accum_depr,
			ytd_depr_exp	= @ytd_depr_exp
	WHERE 	co_asset_id 	= @co_asset_id 
	
	


	SELECT	@co_asset_book_id 	= MIN(co_asset_book_id)
	FROM	#counter1
	WHERE	co_asset_book_id	> @co_asset_book_id

END  

 
IF @classification_id != 0 
	INSERT INTO #amper2perabb
	SELECT 		ISNULL(tmp.classification_code,''),
				tmp.asset_ctrl_num,
				tmp.depr_rule_code,
				tmp.end_cost,
				tmp.beg_accum_depr,
				ytd_accum_depr 	= tmp.end_accum_depr,
				tmp.ytd_depr_exp,
				book_value 	= (SIGN(tmp.end_cost - tmp.end_accum_depr) * ROUND(ABS(tmp.end_cost - tmp.end_accum_depr) + 0.0000001, @curr_precision)),
				tmp.co_asset_id,
				tmp.org_id,
				tmp.region_id
	FROM		#ampdrep2 	tmp
	ORDER BY 	tmp.classification_code,
				tmp.asset_ctrl_num 
ELSE
	INSERT INTO #amper2perabb
	SELECT 		ISNULL(tmp.classification_code,''),
				tmp.asset_ctrl_num,
				tmp.depr_rule_code,
				tmp.end_cost,
				tmp.beg_accum_depr,
				ytd_accum_depr 	= tmp.end_accum_depr,
				tmp.ytd_depr_exp,
				book_value = (SIGN(tmp.end_cost - tmp.end_accum_depr) * ROUND(ABS(tmp.end_cost - tmp.end_accum_depr) + 0.0000001, @curr_precision)),
				tmp.co_asset_id,
				tmp.org_id,
				tmp.region_id
	FROM		#ampdrep2 	tmp	
	ORDER BY 	tmp.asset_ctrl_num 

 
DROP TABLE #ampdrep2 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'amqkpdrp.cpp' + ', line ' + STR( 297, 5 ) + ' -- EXIT: '

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amQuickPrdRecRep_sp] TO [public]
GO
