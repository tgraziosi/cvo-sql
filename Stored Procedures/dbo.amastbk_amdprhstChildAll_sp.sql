SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amastbk_amdprhstChildAll_sp] 
( 
	@co_asset_book_id 	smSurrogateKey 
) 
AS 

SELECT 
	timestamp,
	co_asset_book_id,
	effective_date = convert(char(8), effective_date,112), 
	last_modified_date,
	modified_by,
	posting_flag,
	depr_rule_code,
	limit_rule_code,
	salvage_value,
	catch_up_diff,
	end_life_date = convert(char(8), end_life_date,112), 
	switch_to_sl_date 
FROM 
	amdprhst 
WHERE 
	co_asset_book_id = @co_asset_book_id 
ORDER BY 
	co_asset_book_id, 
	effective_date 

RETURN @@error 
GO
GRANT EXECUTE ON  [dbo].[amastbk_amdprhstChildAll_sp] TO [public]
GO
