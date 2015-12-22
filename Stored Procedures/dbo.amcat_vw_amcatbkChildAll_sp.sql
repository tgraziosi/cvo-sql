SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amcat_vw_amcatbkChildAll_sp] 
( 
	@category_code smCategoryCode 
) 
AS 

SELECT 
 cb.timestamp,
 cb.category_code, 
 cb.book_code,
 effective_date = convert(char(8), cb.effective_date,112), 
 cb.depr_rule_code, 
 dr.rule_description, 
 cb.limit_rule_code 
FROM 
	amcatbk cb,
	amdprrul dr 
WHERE 
 cb.category_code = @category_code
AND	cb.depr_rule_code = dr.depr_rule_code 
ORDER BY 
 cb.category_code,
	cb.book_code,
	cb.effective_date 

GO
GRANT EXECUTE ON  [dbo].[amcat_vw_amcatbkChildAll_sp] TO [public]
GO
