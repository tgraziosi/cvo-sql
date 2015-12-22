SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[ambookPrevRow_sp] 
( 
	@book_code 	smBookCode 
) 
AS 

DECLARE @MSKbook_code smBookCode 
SELECT 	@MSKbook_code = @book_code 

SELECT 	@MSKbook_code = max(book_code) 
FROM 	ambook 
WHERE 	book_code < @MSKbook_code 

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
GRANT EXECUTE ON  [dbo].[ambookPrevRow_sp] TO [public]
GO
