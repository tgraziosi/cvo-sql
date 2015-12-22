SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amastbk_amastprfChildFetch_sp]
(
	@rowsrequested smallint = 1,
	@co_asset_book_id				smSurrogateKey,
	@fiscal_period_end				varchar(30)
) 
AS

DECLARE 
	@rowsfound 				smallint,
	@MSKco_asset_book_id 	smSurrogateKey,
	@MSKfiscal_period_end 	smApplyDate


CREATE TABLE #temp 
(
	timestamp	 		varbinary(8) null,
	co_asset_book_id 	int null,
	fiscal_period_end 	datetime null,
	current_cost 		float null,
	accum_depr 			float null,
	effective_date 		datetime null
)
SELECT @rowsfound = 0
SELECT @MSKco_asset_book_id = @co_asset_book_id
SELECT @MSKfiscal_period_end = @fiscal_period_end

IF EXISTS (SELECT 	* 
			FROM 	amastprf 
			WHERE	co_asset_book_id	= @MSKco_asset_book_id 
			AND		fiscal_period_end	= @MSKfiscal_period_end)
BEGIN
	WHILE @MSKfiscal_period_end IS NOT NULL AND @rowsfound < @rowsrequested
	BEGIN

		INSERT 	INTO #temp 
		SELECT 	
			timestamp,
			co_asset_book_id,
			fiscal_period_end,
			current_cost,
			accum_depr,	 
			effective_date
		FROM 	amastprf 
		WHERE	co_asset_book_id 	= @MSKco_asset_book_id 
		AND	 	fiscal_period_end 	= @MSKfiscal_period_end

		SELECT @rowsfound = @rowsfound + @@rowcount

		
		SELECT 	@MSKfiscal_period_end 	= MIN(fiscal_period_end) 
		FROM 	amastprf
		WHERE	co_asset_book_id 		= @MSKco_asset_book_id 
		AND		fiscal_period_end 		> @MSKfiscal_period_end
	END
END
SELECT
	timestamp,
	co_asset_book_id,
	fiscal_period_end 	= CONVERT(char(8),fiscal_period_end, 112),
	current_cost,
	-accum_depr,	 	
	effective_date		= CONVERT(char(8),effective_date, 112)
FROM #temp 
ORDER BY	
	co_asset_book_id, fiscal_period_end

DROP TABLE #temp

RETURN @@error
GO
GRANT EXECUTE ON  [dbo].[amastbk_amastprfChildFetch_sp] TO [public]
GO
