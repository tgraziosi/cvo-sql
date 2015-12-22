SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[amPrdReconciliationRep_sp] 
( 	
	@company_id 		smCompanyID, 					
	@book_code 			smBookCode, 					
	@period_start  		datetime, 						
	@period_end 		datetime, 						
	@classification_id	smSurrogateKey 	= 0,	


	@show_asset_details	smLogical = 1,	


	@debug_level		smDebugLevel = 0 				
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
	@cost 					smMoneyZero, 
	@accum_depr 			smMoneyZero, 
	@value 	 				smMoneyZero, 
	@asset_total_val 		smMoneyZero, 
	@depr_total_val 		smMoneyZero, 
	
	@asset1_val 			smMoneyZero, 
	@asset2_val 			smMoneyZero, 
	@asset3_val 			smMoneyZero, 
	@asset4_val 			smMoneyZero, 
	@asset5_val 	     	smMoneyZero, 
	@asset6_val  	    	smMoneyZero, 
	@asset7_val 		    smMoneyZero,
	
	@accum1_val 			smMoneyZero, 
	@accum2_val 			smMoneyZero, 
	@accum3_val 			smMoneyZero, 
	@accum4_val 			smMoneyZero, 
	@accum5_val 	     	smMoneyZero, 
	@accum6_val  	    	smMoneyZero, 
	@accum7_val 		    smMoneyZero, 
 
	
	@profile_date 			smApplyDate, 
	@fiscal_period_start 	smApplyDate, 
	@fiscal_period_end 		smApplyDate,
	@total_string		   	smStringText,
	@curr_precision			smallint,			
	@rounding_factor		float				
 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'AMPDPDRP.cpp' + ', line ' + STR( 117, 5 ) + ' -- ENTRY: '
							
SELECT 	@profile_date 			= CONVERT(datetime, @period_start)
SELECT 	@fiscal_period_start 	= DATEADD(dd, 1, @profile_date)
SELECT 	@fiscal_period_end 		= CONVERT(datetime, @period_end)




EXEC	@result = amGetCurrencyPrecision_sp
					@curr_precision		OUTPUT,
					@rounding_factor 	OUTPUT

IF @result <> 0
	RETURN @result






 

















CREATE table #ampdrep
(	
	report_group		tinyint		NOT NULL,
	co_asset_id			int 		NOT NULL,
	classification_code	char(8)		NULL,
	report_subgroup		tinyint		NOT NULL,
	account_type		tinyint 	NOT NULL,
	start_value			float 		NOT NULL,
	addition			float 		NOT NULL,
	improvements		float 		NOT NULL,
	revaluation			float 		NOT NULL,
	adjustment			float 		NOT NULL,
	impairment			float 		NOT NULL,
	disposition			float 		NOT NULL,
	depreciation		float 		NOT NULL,
	end_value			float 		NOT NULL,
	org_id		varchar(30) NULL, 
 	region_id 	varchar(30) NULL 		
)



















CREATE table #amtrxdef
(
	trx_type			tinyint,
	prd_to_prd_column      tinyint,
	col_flag			tinyint
)  





 

INSERT #ampdrep 
( 
	report_group,
	co_asset_id,
	classification_code,
	report_subgroup,
	account_type, 
	start_value,
	addition,
	improvements,
	revaluation,
	adjustment,
	impairment,
	disposition,
	depreciation,
	end_value,
	org_id,
	region_id
)
SELECT 
	0,
	tmp.co_asset_id,
	tmp.classification_code,
	0,
	0, 
	0.0,
	0.0,
	0.0,
	0.0,
	0.0,
	0.0,
	0.0,
	0.0,
	0.0,
	tmp.org_id,
	tmp.region_id
FROM 	#amassets tmp,
		amastbk ab
WHERE 	tmp.co_asset_id	= ab.co_asset_id
AND		ab.book_code 	= @book_code 
	
 

INSERT #ampdrep 
( 
	report_group,
	co_asset_id,
	classification_code,
	report_subgroup,
	account_type, 
	start_value,
	addition,
	improvements,
	revaluation,
	adjustment,
	impairment,
	disposition,
	depreciation,
	end_value,
	org_id,
	region_id	
)
SELECT 
	0,
	tmp.co_asset_id,
	tmp.classification_code,
	0,
	1, 
	0.0,
	0.0,
	0.0,
	0.0,
	0.0,
	0.0,
	0.0,
	0.0,
	0.0,
	tmp.org_id,
	tmp.region_id	
FROM 	#amassets tmp,
		amastbk ab
WHERE 	tmp.co_asset_id	= ab.co_asset_id
AND		ab.book_code 	= @book_code 
	
 

INSERT #ampdrep 
( 
	report_group,
	co_asset_id,
	classification_code,
	report_subgroup,
	account_type, 
	start_value,
	addition,
	improvements,
	revaluation,
	adjustment,
	impairment,
	disposition,
	depreciation,
	end_value,
	org_id,
	region_id	
)
SELECT 
	0,
	tmp.co_asset_id,
	tmp.classification_code,
	0,
	2,
	0.0,
	0.0,
	0.0,
	0.0,
	0.0,
	0.0,
	0.0,
	0.0,
	0.0,
	tmp.org_id,
	tmp.region_id	
FROM 	#amassets tmp,
		amastbk ab
WHERE 	tmp.co_asset_id	= ab.co_asset_id
AND		ab.book_code 	= @book_code 
	



 

SELECT 	ab.co_asset_id,
		ab.co_asset_book_id 
INTO 	#counter1 
FROM 	#amassets tmp,
		amastbk 	ab
WHERE 	tmp.co_asset_id	= ab.co_asset_id
AND		ab.book_code 	= @book_code 





INSERT #amtrxdef
(
    	trx_type,
		prd_to_prd_column,
		col_flag
) 	
SELECT 	trx_type,
		prd_to_prd_column,
		0 	   
FROM 	amtrxdef	
WHERE 	prd_to_prd_column > 0 


 

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

	SET ROWCOUNT 0

	 
	EXEC @result = amGetPrfRep_sp 
							@co_asset_book_id,
				 			@profile_date,
							@curr_precision,
							@cost 				OUTPUT,
							@accum_depr 		OUTPUT 
	IF ( @result != 0 )
	BEGIN
		DROP TABLE #counter1
		DROP TABLE #amtrxdef
		RETURN @result 
	END

	
     

	SELECT 	
		@asset_total_val = 0.0,
		@asset1_val 	 = 0.0,
		@asset2_val 	= 0.0,
		@asset3_val 	= 0.0,
		@asset4_val 	= 0.0,
		@asset5_val 	= 0.0,
		@asset6_val 	= 0.0,
		@asset7_val 	= 0.0,					  
		@depr_total_val = 0.0,
		@accum1_val 	= 0.0,
		@accum2_val 	= 0.0,
		@accum3_val 	= 0.0,
		@accum4_val 	= 0.0,
		@accum5_val 	= 0.0,
		@accum6_val 	= 0.0,
		@accum7_val 	= 0.0 

	SELECT @depr_total_val = (SIGN(@depr_total_val - isnull(@accum_depr,0.0)) * ROUND(ABS(@depr_total_val - isnull(@accum_depr,0.0)) + 0.0000001, @curr_precision))		 

	SELECT @asset_total_val = (SIGN(isnull(@asset_total_val,0.0) + isnull(@cost,0.0)) * ROUND(ABS(isnull(@asset_total_val,0.0) + isnull(@cost,0.0)) + 0.0000001, @curr_precision))


	 
	UPDATE #amtrxdef
	SET col_flag = 0

	EXEC @result = amPeriodToPeriodRep_sp
							@co_asset_book_id,
							1,						   
				 			@fiscal_period_start,
				 			@fiscal_period_end,
							@curr_precision,
							@asset1_val OUTPUT, 
							@asset_total_val OUTPUT,
							@accum1_val OUTPUT,
							@depr_total_val OUTPUT

	IF ( @result != 0 )
	BEGIN
		DROP TABLE #counter1
		DROP TABLE #amtrxdef
		RETURN @result 
	END

						
						
	EXEC @result = amPeriodToPeriodRep_sp
							@co_asset_book_id,
							2,						   
				 			@fiscal_period_start,
				 			@fiscal_period_end,
							@curr_precision,
							@asset2_val OUTPUT, 
							@asset_total_val OUTPUT,
							@accum2_val OUTPUT,
							@depr_total_val OUTPUT

	IF ( @result != 0 )
	BEGIN
		DROP TABLE #counter1
		DROP TABLE #amtrxdef
		RETURN @result 
	END
 
							
	EXEC @result = amPeriodToPeriodRep_sp
							@co_asset_book_id,
							3,						   
				 			@fiscal_period_start,
				 			@fiscal_period_end,
							@curr_precision,
							@asset3_val OUTPUT, 
							@asset_total_val OUTPUT,
							@accum3_val OUTPUT,
							@depr_total_val OUTPUT

	IF ( @result != 0 )
	BEGIN
		DROP TABLE #counter1
		DROP TABLE #amtrxdef
		RETURN @result 
	END
 
							
	EXEC @result = amPeriodToPeriodRep_sp
							@co_asset_book_id,
							4,						   
				 			@fiscal_period_start,
				 			@fiscal_period_end,
							@curr_precision,
							@asset4_val OUTPUT, 
							@asset_total_val OUTPUT,
							@accum4_val OUTPUT,
							@depr_total_val OUTPUT

	IF ( @result != 0 )
	BEGIN
		DROP TABLE #counter1
		DROP TABLE #amtrxdef
		RETURN @result 
	END
 
							
	EXEC @result = amPeriodToPeriodRep_sp
							@co_asset_book_id,
							5,						   
				 			@fiscal_period_start,
				 			@fiscal_period_end,
							@curr_precision,
							@asset5_val OUTPUT, 
							@asset_total_val OUTPUT,
							@accum5_val OUTPUT,
							@depr_total_val OUTPUT

	IF ( @result != 0 )
	BEGIN
		DROP TABLE #counter1
		DROP TABLE #amtrxdef
		RETURN @result 
	END
 
							
	EXEC @result = amPeriodToPeriodRep_sp
							@co_asset_book_id,
							6,						   
				 			@fiscal_period_start,
				 			@fiscal_period_end,
							@curr_precision,
							@asset6_val OUTPUT, 
							@asset_total_val OUTPUT,
							@accum6_val OUTPUT,
							@depr_total_val OUTPUT

	IF ( @result != 0 )
	BEGIN
		DROP TABLE #counter1
		DROP TABLE #amtrxdef
		RETURN @result 
	END

							
	EXEC @result = amPeriodToPeriodRep_sp
							@co_asset_book_id,
							7,						   
				 			@fiscal_period_start,
				 			@fiscal_period_end,
							@curr_precision,
							@asset7_val OUTPUT, 
							@asset_total_val OUTPUT,
							@accum7_val OUTPUT,
							@depr_total_val OUTPUT

	IF ( @result != 0 )
	BEGIN
		DROP TABLE #counter1
		DROP TABLE #amtrxdef
		RETURN @result 
	END
 
							
	 

	 


	UPDATE 	#ampdrep 
	SET 	start_value 	= ISNULL(@cost,0.0), 
			addition    	= ISNULL(@asset1_val,0.0), 	
			improvements 	= ISNULL(@asset2_val,0.0), 
			impairment 		= ISNULL(@asset3_val,0.0),
			revaluation 	= ISNULL(@asset4_val,0.0),
			adjustment  	= ISNULL(@asset5_val,0.0),
			disposition 	= ISNULL(@asset6_val,0.0), 	
			depreciation 	= ISNULL(@asset7_val,0.0), 	
			end_value 		= ISNULL(@asset_total_val,0.0)
	WHERE 	co_asset_id 	= @co_asset_id 
	AND 	account_type 	= 0 

	SELECT	@result = @@error
	IF ( @result != 0 )
	BEGIN
		DROP TABLE #counter1
		DROP TABLE #amtrxdef
		RETURN @result 
	END



	IF isnull(@accum_depr, 0.0) = 0.0
		SELECT @accum_depr = isnull(@accum_depr, 0.0)
	ELSE
		SELECT @accum_depr = -(isnull(@accum_depr, 0.0))

 


	UPDATE 	#ampdrep 
	SET 	start_value 	= ISNULL(@accum_depr,0.0), 
			addition    	= ISNULL(@accum1_val,0.0),
			improvements 	= ISNULL(@accum2_val,0.0), 
			impairment 		= ISNULL(@accum3_val,0.0), 
			revaluation 	= ISNULL(@accum4_val,0.0), 
			adjustment 		= ISNULL(@accum5_val,0.0), 	
			disposition 	= ISNULL(@accum6_val,0.0), 	
			depreciation 	= ISNULL(@accum7_val,0.0), 	
			end_value 		= ISNULL(@depr_total_val,0.0)
	WHERE 	co_asset_id 	= @co_asset_id 
	AND 	account_type 	= 1 

	SELECT @result = @@error
	IF ( @result != 0 )
	BEGIN
		DROP TABLE #counter1
		DROP TABLE #amtrxdef
		RETURN @result 
	END

   
 

	UPDATE 	#ampdrep 
	SET 	start_value 	= (SIGN(ISNULL(@cost, 0.0) - ISNULL(@accum_depr, 0.0)) * ROUND(ABS(ISNULL(@cost, 0.0) - ISNULL(@accum_depr, 0.0)) + 0.0000001, @curr_precision)), 	
			end_value 		= (SIGN(ISNULL(@asset_total_val, 0.0) - ISNULL(@depr_total_val, 0.0)) * ROUND(ABS(ISNULL(@asset_total_val, 0.0) - ISNULL(@depr_total_val, 0.0)) + 0.0000001, @curr_precision))
	WHERE 	co_asset_id 	= @co_asset_id 
	AND 	account_type 	= 2 
	

	DELETE #counter1
	WHERE co_asset_id 		= @co_asset_id 

	
	SET ROWCOUNT 0 

END  

DROP TABLE #counter1
DROP TABLE #amtrxdef




IF @classification_id != 0
BEGIN
	SELECT
		classification_code,
		account_type, 
		start_value		= (SIGN(ISNULL(SUM(start_value), 0.0)) * ROUND(ABS(ISNULL(SUM(start_value), 0.0)) + 0.0000001, @curr_precision)),
		addition		= (SIGN(ISNULL(SUM(addition), 0.0)) * ROUND(ABS(ISNULL(SUM(addition), 0.0)) + 0.0000001, @curr_precision)),
		improvements	= (SIGN(ISNULL(SUM(improvements), 0.0)) * ROUND(ABS(ISNULL(SUM(improvements), 0.0)) + 0.0000001, @curr_precision)),
		revaluation		= (SIGN(ISNULL(SUM(revaluation), 0.0)) * ROUND(ABS(ISNULL(SUM(revaluation), 0.0)) + 0.0000001, @curr_precision)),
		adjustment		= (SIGN(ISNULL(SUM(adjustment), 0.0)) * ROUND(ABS(ISNULL(SUM(adjustment), 0.0)) + 0.0000001, @curr_precision)),
		impairment		= (SIGN(ISNULL(SUM(impairment), 0.0)) * ROUND(ABS(ISNULL(SUM(impairment), 0.0)) + 0.0000001, @curr_precision)),
		disposition		= (SIGN(ISNULL(SUM(disposition), 0.0)) * ROUND(ABS(ISNULL(SUM(disposition), 0.0)) + 0.0000001, @curr_precision)),
		depreciation	= (SIGN(ISNULL(SUM(depreciation), 0.0)) * ROUND(ABS(ISNULL(SUM(depreciation), 0.0)) + 0.0000001, @curr_precision)),
		end_value		= (SIGN(ISNULL(SUM(end_value), 0.0)) * ROUND(ABS(ISNULL(SUM(end_value), 0.0)) + 0.0000001, @curr_precision)) 
	INTO 	#sum_cls
	FROM  	#ampdrep
	GROUP BY   classification_code, account_type

	SELECT @result = @@error
	IF	@result <> 0
		RETURN @result
	
END







 

INSERT #ampdrep 
( 
	report_group,
	co_asset_id,
	report_subgroup,
	account_type, 
	start_value,
	addition,
	improvements,
	revaluation,
	adjustment,
	impairment,
	disposition,
	depreciation,
	end_value 
)
SELECT 
	1,	
	0,
	1,
	account_type, 
	(SIGN(ISNULL(SUM(start_value), 0.0)) * ROUND(ABS(ISNULL(SUM(start_value), 0.0)) + 0.0000001, @curr_precision)),
	(SIGN(ISNULL(SUM(addition), 0.0)) * ROUND(ABS(ISNULL(SUM(addition), 0.0)) + 0.0000001, @curr_precision)),
	(SIGN(ISNULL(SUM(improvements), 0.0)) * ROUND(ABS(ISNULL(SUM(improvements), 0.0)) + 0.0000001, @curr_precision)),
	(SIGN(ISNULL(SUM(revaluation), 0.0)) * ROUND(ABS(ISNULL(SUM(revaluation), 0.0)) + 0.0000001, @curr_precision)),
	(SIGN(ISNULL(SUM(adjustment), 0.0)) * ROUND(ABS(ISNULL(SUM(adjustment), 0.0)) + 0.0000001, @curr_precision)),
	(SIGN(ISNULL(SUM(impairment), 0.0)) * ROUND(ABS(ISNULL(SUM(impairment), 0.0)) + 0.0000001, @curr_precision)),
	(SIGN(ISNULL(SUM(disposition), 0.0)) * ROUND(ABS(ISNULL(SUM(disposition), 0.0)) + 0.0000001, @curr_precision)),
	(SIGN(ISNULL(SUM(depreciation), 0.0)) * ROUND(ABS(ISNULL(SUM(depreciation), 0.0)) + 0.0000001, @curr_precision)),
	(SIGN(ISNULL(SUM(end_value), 0.0)) * ROUND(ABS(ISNULL(SUM(end_value), 0.0)) + 0.0000001, @curr_precision)) 
FROM 	#ampdrep 
GROUP BY	account_type
	
IF @classification_id != 0
BEGIN
	INSERT #ampdrep 
	( 
		report_group,
		co_asset_id,
		classification_code,
		report_subgroup,
		account_type, 
		start_value,
		addition,
		improvements,
		revaluation,
		adjustment,
		impairment,
		disposition,
		depreciation,
		end_value 
	)
	SELECT 
		0,					
		0,
		classification_code,
		1,
		account_type, 
		start_value,
		addition,
		improvements,
		revaluation,
		adjustment,
		impairment,
		disposition,
		depreciation,
		end_value 
	FROM 	#sum_cls 
	
	SELECT @result = @@error
	IF	@result <> 0
		RETURN @result

	DROP TABLE #sum_cls
END



 

IF @classification_id = 0
BEGIN	
	INSERT INTO #amper2peren
	SELECT 	
			report_group,
			asset_ctrl_num 		= ISNULL(a.asset_ctrl_num,''), 
			tmp.co_asset_id,
			ISNULL(classification_code,''),
			report_subgroup,
			asset_description 	= ISNULL(a.asset_description,''),
			tmp.account_type,
			tmp.start_value,
			tmp.addition,
			tmp.improvements,
			tmp.revaluation,
			tmp.adjustment,
			tmp.impairment,
			tmp.disposition,
			tmp.depreciation,
			tmp.end_value,
			org_id = ISNULL(tmp.org_id,''),
			region_id = ISNULL(tmp.region_id,'')
	FROM	#ampdrep tmp
	LEFT OUTER JOIN amasset a
	on tmp.co_asset_id = a.co_asset_id
	ORDER BY 
		tmp.report_group,
		a.asset_ctrl_num,
		tmp.account_type 
END
ELSE
BEGIN
	IF @show_asset_details = 0
	BEGIN
		INSERT INTO #amper2peren
		SELECT 	
			report_group,
			asset_ctrl_num 		= ISNULL(a.asset_ctrl_num,''), 
			tmp.co_asset_id,
			ISNULL(classification_code,''),
			report_subgroup,
			asset_description 	= ISNULL(a.asset_description,''),
			tmp.account_type,
			tmp.start_value,
			tmp.addition,
			tmp.improvements,
			tmp.revaluation,
			tmp.adjustment,
			tmp.impairment,
			tmp.disposition,
			tmp.depreciation,
			tmp.end_value,
			org_id = ISNULL(tmp.org_id,''),
			region_id = ISNULL(tmp.region_id,'')			
		FROM	#ampdrep tmp
		left outer join amasset a
		on 	tmp.co_asset_id = a.co_asset_id
		where report_subgroup = 1
		ORDER BY 
			tmp.report_group,
			tmp.classification_code,
			a.asset_ctrl_num,
			tmp.account_type 
	END
	ELSE
	BEGIN
		INSERT INTO #amper2peren
		SELECT 	
			report_group,
			asset_ctrl_num 		= ISNULL(a.asset_ctrl_num,''), 
			tmp.co_asset_id,
			ISNULL(classification_code,''),
			report_subgroup,
			asset_description 	= ISNULL(a.asset_description,''),
			tmp.account_type,
			tmp.start_value,
			tmp.addition,
			tmp.improvements,
			tmp.revaluation,
			tmp.adjustment,
			tmp.impairment,
			tmp.disposition,
			tmp.depreciation,
			tmp.end_value,
			org_id = ISNULL(tmp.org_id,''),
			region_id = ISNULL(tmp.region_id,'')			
		FROM	#ampdrep tmp
		left outer join amasset a
		on    tmp.co_asset_id = a.co_asset_id
		ORDER BY 
			tmp.report_group,
			tmp.classification_code,
			tmp.report_subgroup,
			a.asset_ctrl_num,
			tmp.account_type 
	END

END

 

DROP TABLE #ampdrep 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'AMPDPDRP.cpp' + ', line ' + STR( 780, 5 ) + ' -- EXIT: '

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amPrdReconciliationRep_sp] TO [public]
GO
