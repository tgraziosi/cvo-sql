SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[ambookLastRow_sp] 
AS 

DECLARE @MSKbook_code smBookCode 

SELECT 	@MSKbook_code = MAX(book_code) 
FROM 	ambook 

SELECT 
	timestamp,
	book_code,
	book_description,
	capitalization_threshold,
	currency_code,
	allow_revaluations,
	allow_writedowns,
	allow_adjustments,
	suspend_depr,
	post_to_gl,
	gl_book_code,
	depr_if_less_than_yr 
FROM 	ambook 
WHERE 	book_code = @MSKbook_code 

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[ambookLastRow_sp] TO [public]
GO
