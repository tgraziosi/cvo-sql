SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amastbk_ammandprChildAll_sp] 
( 
	@co_asset_book_id 	smSurrogateKey 
) 
AS 

SELECT 
	timestamp,
	co_asset_book_id,
	fiscal_period_end= convert(char(8), fiscal_period_end,112), 
	last_modified_date = convert(char(8), last_modified_date,112), 
	modified_by,
	posting_flag,
	depr_expense 
FROM 
	ammandpr 
WHERE 
	co_asset_book_id = @co_asset_book_id 
ORDER BY 
	co_asset_book_id, 
	fiscal_period_end 

RETURN @@error 
GO
GRANT EXECUTE ON  [dbo].[amastbk_ammandprChildAll_sp] TO [public]
GO
