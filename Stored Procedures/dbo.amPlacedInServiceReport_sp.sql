SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[amPlacedInServiceReport_sp] 
( 	
	@company_id			smCompanyID,	  		
	@book_code			smBookCode,				
	@iso_apply_date		datetime,				
	@debug_level		smDebugLevel	= 0		

)
AS 

DECLARE 
	@jul_year_start_date	smJulianDate,			
	@jul_year_end_date		smJulianDate,					
	@prd_end_date			smApplyDate,			
	@year_start_date		smApplyDate,			
	@year_end_date			smApplyDate,					
	@total_cost				smMoneyZero,			

			
	@curr_precision			smallint,				
	@round_factor			float,	 				
	@num_periods			smCounter,				
	@i						smCounter,				
	@j						smCounter,				
	@prds_per_qtr			smCounter,				
	@result					smErrorCode,				
	@total_percentage		float

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "amplaced.cpp" + ", line " + STR( 90, 5 ) + " -- ENTRY: "

SELECT	@year_end_date = CONVERT(datetime, @iso_apply_date)  

EXEC  @result = amGetFiscalYear_sp 
						@year_end_date,
                        0,
                        @year_start_date OUTPUT 
IF @result <> 0
	RETURN @result
						 
SELECT	@jul_year_end_date 		=  DATEDIFF(dd, "1/1/1980", @year_end_date) + 722815,
		@jul_year_start_date 	=  DATEDIFF(dd, "1/1/1980", @year_start_date) + 722815



 
EXEC @result = amGetCurrencyPrecision_sp 
						@curr_precision 	OUTPUT,
						@round_factor 		OUTPUT 

IF @debug_level	>= 5
	SELECT 	book_code 		= @book_code,
			year_end_date 	= @year_end_date




CREATE TABLE #period_summary
(
	quarter				int,
	jul_period_end_date	int,
	period_start_date	datetime,
	period_end_date		datetime,
	cost				float,
	percentage_cost		float
)

INSERT INTO #period_summary
(
	quarter,
	jul_period_end_date,
	period_start_date,
	period_end_date,
	cost,
	percentage_cost
)
SELECT
	0,
	period_end_date,
	DATEADD(dd, period_start_date - 722815, "1/1/1980"),
	DATEADD(dd, period_end_date - 722815, "1/1/1980"),
	0.00,
	0.00
FROM	glprd
WHERE	period_end_date BETWEEN @jul_year_start_date AND @jul_year_end_date 

SELECT @result = @@error
IF	@result <> 0
	RETURN @result

SELECT 	@num_periods = COUNT(quarter)
FROM	#period_summary





IF @num_periods % 4 = 0
BEGIN
	SELECT	@prds_per_qtr 	= @num_periods / 4,
			@i				= 1

	WHILE @i <= 4
	BEGIN
		SELECT	@j = 0
		
		WHILE	@j < @prds_per_qtr
		BEGIN
			SELECT 	@prd_end_date 	= MIN(period_end_date)
			FROM	#period_summary
			WHERE	quarter 		= 0
			
			UPDATE	#period_summary
			SET		quarter			= @i
			WHERE	period_end_date	= @prd_end_date

			SELECT @result = @@error
			IF	@result <> 0
				RETURN @result

			SELECT	@j = @j + 1
		END
		
		SELECT	@i = @i + 1
	END 
END







CREATE TABLE #sum_per_prd
(	
	period_end_date	datetime,
	cost			float
)
INSERT INTO #sum_per_prd
(
	period_end_date,
	cost
)
SELECT 
		tmp.period_end_date,
		(SIGN(ISNULL(SUM(amount),0.0)) * ROUND(ABS(ISNULL(SUM(amount),0.0)) + 0.0000001, @curr_precision))
FROM	#period_summary tmp,
		amvalues v,
		amastbk	ab,
		#amasset a
WHERE		a.company_id				= @company_id
AND		a.co_asset_id	 			= ab.co_asset_id
AND		ab.book_code				= @book_code
AND		ab.placed_in_service_date	BETWEEN tmp.period_start_date AND tmp.period_end_date
AND		ab.co_asset_book_id			= v.co_asset_book_id
AND		v.account_type_id			= 0
AND		v.apply_date				<= @year_end_date
GROUP BY tmp.period_end_date	

SELECT @result = @@error
IF @result <> 0
	RETURN @result

SELECT 	@total_cost = (SIGN(ISNULL(SUM(cost),0.0)) * ROUND(ABS(ISNULL(SUM(cost),0.0)) + 0.0000001, @curr_precision))
FROM	#sum_per_prd

UPDATE	#period_summary
SET		cost					= costs.cost,
		percentage_cost 		= ROUND(costs.cost / @total_cost * 100.00, 2)   
FROM	#period_summary tmp, #sum_per_prd costs
WHERE	costs.period_end_date	= tmp.period_end_date

SELECT @result = @@error
IF @result <> 0
	RETURN @result







SELECT 	@total_percentage 	= ISNULL(SUM(percentage_cost), 0.0)
FROM	#period_summary

IF (ABS((@total_percentage - 100.00)-(0.00)) > 0.0000001)
BEGIN
	SELECT @prd_end_date 	= MIN(period_end_date)
	FROM   #period_summary 
	WHERE  percentage_cost 	> 0.0

	UPDATE 	#period_summary
	SET		percentage_cost 	= ROUND(percentage_cost - (@total_percentage - 100.00), 2)
	FROM	#period_summary
	WHERE	period_end_date		= @prd_end_date

	SELECT @result = @@error
	IF @result <> 0
		RETURN @result

END

INSERT INTO #amplinsv 
SELECT
		tmp.quarter,
		prd.period_description,
		tmp.period_end_date,
		tmp.cost,
		tmp.percentage_cost
FROM	#period_summary tmp,
		glprd	prd
WHERE	tmp.jul_period_end_date 	= prd.period_end_date
ORDER BY tmp.quarter, tmp.jul_period_end_date

DROP TABLE 	#sum_per_prd
DROP TABLE	#period_summary

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "amplaced.cpp" + ", line " + STR( 279, 5 ) + " -- EXIT: "

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amPlacedInServiceReport_sp] TO [public]
GO
