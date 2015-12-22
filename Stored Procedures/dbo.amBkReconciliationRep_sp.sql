SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[amBkReconciliationRep_sp] 
( 	
	@company_id			smCompanyID, 					
	@book_code1 		smBookCode, 					
	@book_code2 		smBookCode, 					
	@period_start 		datetime, 						
	@period_end 		datetime, 						
	@classification_id	smSurrogateKey 			= 0,	


	@show_asset_detail	smLogical				= 1,	



	@debug_level		smDebugLevel			= 0		
) 
AS 

DECLARE 
	@trx_type				smTrxType,
	@str_text				smStdDescription,
	@rowcount 				smCounter, 
	@result		 			smErrorCode,	
	@is_imported			smLogical,
	@co_asset_id 			smSurrogateKey, 
	@co_asset_book_id 		smSurrogateKey, 
	@asset_first_num 		smControlNumber, 
	@asset_secnd_num 		smControlNumber,	
	@fiscal_period_start 	smApplyDate, 
	@fiscal_period_end 		smApplyDate,
	@curr_precision			smallint,			
	@rounding_factor		float				


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "AMBKPFRP.cpp" + ", line " + STR( 93, 5 ) + " -- ENTRY: "

 

SELECT 	@fiscal_period_start 	= CONVERT(datetime, @period_start)
SELECT 	@fiscal_period_end 		= CONVERT(datetime, @period_end)




EXEC	@result = amGetCurrencyPrecision_sp
					@curr_precision		OUTPUT,
					@rounding_factor 	OUTPUT

IF @result <> 0
	RETURN @result




 

















CREATE TABLE #ambkprf
(	
	report_group		tinyint,		




	co_asset_id			int,			
	classification_code	char(8) NULL,	
	report_subgroup		tinyint,		



	type_flag			tinyint ,		




	account_type		tinyint,		




	account_desc		char(30) NULL,  
		
	book_value1			float,    
	flag_book1			tinyint NULL,		
	book_value2			float,   	
	flag_book2			tinyint NULL,		
	difference 			float   NULL	   	
)











INSERT #ambkprf 
( 
	report_group,
	co_asset_id,
	classification_code,
	report_subgroup,
	type_flag,
	account_type,
	book_value1,
	flag_book1,
	book_value2,
	flag_book2
	
)
SELECT DISTINCT 
	0,
	tmp.co_asset_id,
	tmp.classification_code,
	0,
	1,		   
	0,	
	0.0,
	0,
	0.0,
	0
	
FROM 	#amassets tmp,
		amastbk ab
WHERE  	ab.co_asset_id 	= tmp.co_asset_id
AND		ab.book_code 	IN (@book_code1, @book_code2)

	
INSERT #ambkprf 
( 
	report_group,
	co_asset_id,
	classification_code,
	report_subgroup,
	type_flag,
	account_type,
	book_value1,
	flag_book1,
	book_value2,
	flag_book2
)
SELECT DISTINCT 
	0,
	tmp.co_asset_id,
	tmp.classification_code,
	0,
	1,
	1,   
	0.0,
	0,
	0.0,
	0
	
FROM 	#amassets tmp,
		amastbk ab
WHERE  	ab.co_asset_id 	= tmp.co_asset_id
AND		ab.book_code 	IN (@book_code1, @book_code2)

	
INSERT #ambkprf 
( 
	report_group,
	co_asset_id,
	classification_code,
	report_subgroup,
	type_flag,
	account_type,
	book_value1,
	flag_book1,
	book_value2,
	flag_book2
)
SELECT DISTINCT 
	0,
	tmp.co_asset_id,
	tmp.classification_code,
	0,
	1,
	2,   
	0.0,
	0,
	0.0,
	0 
		
FROM 	#amassets tmp,
		amastbk ab
WHERE  	ab.co_asset_id 	= tmp.co_asset_id
AND		ab.book_code 	IN (@book_code1, @book_code2)
	








 
INSERT #ambkprf 
( 
	report_group,
	co_asset_id,
	classification_code,
	report_subgroup,
	type_flag,
	account_type,
	book_value1,
	flag_book1,
	book_value2,
	flag_book2
	)
SELECT DISTINCT 
	0,
	tmp.co_asset_id,
	tmp.classification_code,
	0,
	2,
	trx.trx_type,
   	0.0,
	0,
	0.0,
	0

	
FROM 	#amassets tmp,
		amastbk ab,
		amtrxdef trx
WHERE  	ab.co_asset_id 	= tmp.co_asset_id
AND		ab.book_code 	IN (@book_code1, @book_code2)
AND		trx.display_in_reports > 0

	








INSERT #ambkprf 
( 
	report_group,
	co_asset_id,
	classification_code,
	report_subgroup,
	type_flag,
	account_type,
	book_value1,
	flag_book1,
	book_value2,
	flag_book2
	
)
SELECT DISTINCT 
	0,
	tmp.co_asset_id,
	tmp.classification_code,
	0,
	3,
	0,	
	0.0,
	0,
	0.0,
	0
	 
FROM 	#amassets tmp,
		amastbk ab
WHERE  	ab.co_asset_id 	= tmp.co_asset_id
AND		ab.book_code 	IN (@book_code1, @book_code2)


	
INSERT #ambkprf 
( 
	report_group,
	co_asset_id,
	classification_code,
	report_subgroup,
	type_flag,
	account_type,
	book_value1,
	flag_book1,
	book_value2,
	flag_book2
	
)
SELECT DISTINCT 
	0,
	tmp.co_asset_id,
	tmp.classification_code,
	0,
	3,
	1,
	0.0,
	0,
	0.0,
	0
	 
FROM 	#amassets tmp,
		amastbk ab
WHERE  	ab.co_asset_id 	= tmp.co_asset_id
AND		ab.book_code 	IN (@book_code1, @book_code2)

	
INSERT #ambkprf 
( 
	report_group,
	co_asset_id,
	classification_code,
	report_subgroup,
	type_flag,
	account_type,
	book_value1,
	flag_book1,
	book_value2,
	flag_book2
	
)
SELECT DISTINCT 
	0,
	tmp.co_asset_id,
	tmp.classification_code,
	0,
	3,
	2,
	0.0,
	0,
	0.0,
	0
	 
FROM 	#amassets tmp,
		amastbk ab
WHERE  	ab.co_asset_id 	= tmp.co_asset_id
AND		ab.book_code 	IN (@book_code1, @book_code2)



 
EXEC @result = amBkBkReconciliation_sp
						1,
						@book_code1,
						@fiscal_period_start,
						@fiscal_period_end,
						@curr_precision 

IF ( @result != 0 )
BEGIN
	DROP TABLE #ambkprf
	DROP TABLE #amassets
	RETURN @result 
END



 
EXEC @result = amBkBkReconciliation_sp 
						2,
						@book_code2,
						@fiscal_period_start,
						@fiscal_period_end,
						@curr_precision 

IF ( @result != 0 )
BEGIN
	DROP TABLE #ambkprf
	DROP TABLE #amassets
	RETURN @result 
END







CREATE TABLE #sum_bkbk
(
	type_flag			tinyint,	




	account_type		tinyint,		
	book_value1			float,
	book_value2			float 
)

INSERT INTO #sum_bkbk
SELECT

	type_flag,
	account_type,
	(SIGN(ISNULL(SUM(book_value1), 0.0)) * ROUND(ABS(ISNULL(SUM(book_value1), 0.0)) + 0.0000001, @curr_precision)),
	(SIGN(ISNULL(SUM(book_value2), 0.0)) * ROUND(ABS(ISNULL(SUM(book_value2), 0.0)) + 0.0000001, @curr_precision))
FROM  #ambkprf
GROUP BY   type_flag, account_type

IF @classification_id != 0
BEGIN
	


	SELECT
		classification_code,
		type_flag,
		account_type,
		book_value1 = (SIGN(ISNULL(SUM(book_value1), 0.0)) * ROUND(ABS(ISNULL(SUM(book_value1), 0.0)) + 0.0000001, @curr_precision)),
		book_value2 = (SIGN(ISNULL(SUM(book_value2), 0.0)) * ROUND(ABS(ISNULL(SUM(book_value2), 0.0)) + 0.0000001, @curr_precision))
	INTO 	#sum_cls
	FROM  	#ambkprf
	GROUP BY   classification_code, type_flag, account_type

	SELECT @result = @@error
	IF	@result <> 0
		RETURN @result
	
	INSERT #ambkprf 
	( 
		report_group,
		co_asset_id,
		classification_code,
		report_subgroup,
		type_flag,
		account_type,		
		book_value1,
		book_value2
		
	)
	SELECT 
		0,					
		0,
		classification_code,
		1,
		type_flag,
		account_type,
		book_value1,
		book_value2
	FROM 	#sum_cls tmp
	
	SELECT @result = @@error
	IF	@result <> 0
		RETURN @result
	
	DROP TABLE #sum_cls
END




INSERT #ambkprf 
( 
	report_group,
	co_asset_id,
	report_subgroup,
	type_flag,
	account_type,		
	book_value1,
	book_value2
	
)
SELECT 
	1,					
	0,
	1,
	type_flag,
	account_type,
	book_value1,
	book_value2
FROM 	#sum_bkbk tmp

SELECT @result = @@error
IF @result <> 0
	RETURN @result						

DROP TABLE #sum_bkbk



 
UPDATE 	#ambkprf 
SET 	difference 			= (SIGN(book_value1 - book_value2) * ROUND(ABS(book_value1 - book_value2) + 0.0000001, @curr_precision))





EXEC @result = amGetString_sp
						36,
						@str_text OUTPUT
IF @result <> 0
	RETURN 	@result

SELECT	@str_text = ISNULL(RTRIM(@str_text), '')

UPDATE #ambkprf
SET account_desc = @str_text 
WHERE account_type = 0






EXEC @result = amGetString_sp
						37,
						@str_text OUTPUT
IF @result <> 0
	RETURN 	@result

SELECT	@str_text = ISNULL(RTRIM(@str_text), '')


UPDATE #ambkprf
SET account_desc = @str_text 
WHERE account_type = 1





EXEC @result = amGetString_sp
						38,
						@str_text OUTPUT
IF @result <> 0
	RETURN 	@result

SELECT	@str_text = ISNULL(RTRIM(@str_text), '')

UPDATE #ambkprf
SET account_desc = @str_text 
WHERE account_type = 2






UPDATE #ambkprf
SET account_desc = trx.trx_name
FROM #ambkprf tmp,amtrxdef trx 
WHERE tmp.account_type = trx.trx_type





 
IF @classification_id = 0
BEGIN
	INSERT INTO #ambk2bk
	SELECT 	DISTINCT
			tmp.report_group,
			ISNULL(tmp.classification_code,""),
			tmp.report_subgroup,
			asset_ctrl_num 		= ISNULL(a.asset_ctrl_num,""),
			tmp.co_asset_id,
			asset_description 	= ISNULL(a.asset_description,""),
			tmp.type_flag,
			tmp.account_type,
			tmp.book_value1,
			tmp.book_value2,
			tmp.difference,
			tmp.account_desc,
			a.org_id,
			dbo.IBGetParent_fn (a.org_id)
		FROM 	#ambkprf  tmp LEFT OUTER JOIN amasset a
			ON (tmp.co_asset_id = a.co_asset_id)
	ORDER BY 
			tmp.report_group,
			asset_ctrl_num, 
			tmp.type_flag,
			tmp.account_type 
END
ELSE
BEGIN
	IF @show_asset_detail = 1
		INSERT INTO #ambk2bk
		SELECT 	DISTINCT
			tmp.report_group,
			classification_code	= ISNULL(tmp.classification_code,""),
			tmp.report_subgroup,
			asset_ctrl_num 		= ISNULL(a.asset_ctrl_num,""),
			tmp.co_asset_id,
			asset_description 	= ISNULL(a.asset_description,""),
			tmp.type_flag,
			tmp.account_type,
			tmp.book_value1,
			tmp.book_value2,
			tmp.difference,
			tmp.account_desc,
			a.org_id,
			dbo.IBGetParent_fn (a.org_id)
		FROM 	#ambkprf  tmp LEFT OUTER JOIN amasset a
			ON (tmp.co_asset_id = a.co_asset_id)
		ORDER BY 
				tmp.report_group,
				tmp.classification_code,
				tmp.report_subgroup,
				asset_ctrl_num, 
				tmp.type_flag,
				tmp.account_type 
	ELSE
		INSERT INTO #ambk2bk
		SELECT 	DISTINCT
			tmp.report_group,
			classification_code	= ISNULL(tmp.classification_code,""),
			tmp.report_subgroup,
			asset_ctrl_num 		= ISNULL(a.asset_ctrl_num,""),
			tmp.co_asset_id,
			asset_description 	= ISNULL(a.asset_description,""),
			tmp.type_flag,
			tmp.account_type,
			tmp.book_value1,
			tmp.book_value2,
			tmp.difference,
			tmp.account_desc,
			a.org_id,
			dbo.IBGetParent_fn (a.org_id)
		FROM 	#ambkprf  tmp LEFT OUTER JOIN amasset a
			ON (tmp.co_asset_id = a.co_asset_id)
		AND		report_subgroup = 1
		ORDER BY 
				tmp.report_group,
				tmp.classification_code,
				tmp.report_subgroup,
				asset_ctrl_num, 
				tmp.type_flag,
				tmp.account_type 

END



 
DROP TABLE #ambkprf 


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "AMBKPFRP.cpp" + ", line " + STR( 682, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amBkReconciliationRep_sp] TO [public]
GO
