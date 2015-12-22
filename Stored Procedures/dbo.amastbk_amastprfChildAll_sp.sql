SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amastbk_amastprfChildAll_sp] 
( 
	@co_asset_book_id	smSurrogateKey		 
) 
AS 

SELECT 
	timestamp,
	co_asset_book_id,
	fiscal_period_end 	= CONVERT(char(8), fiscal_period_end, 112), 
	current_cost,
	-accum_depr, 												
	effective_date 		= CONVERT(char(8), effective_date, 112)
FROM 
	amastprf 
WHERE 
	co_asset_book_id 	= @co_asset_book_id 
ORDER BY 
	co_asset_book_id, 
	fiscal_period_end 

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amastbk_amastprfChildAll_sp] TO [public]
GO
