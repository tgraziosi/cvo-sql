SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[ambookNextRow_sp] 
( 
	@book_code 	smBookCode 
) 
as 

declare @MSKbook_code smBookCode 

select 	@MSKbook_code = @book_code 
select 	@MSKbook_code = min(book_code) 
from 	ambook 
where 	book_code > @MSKbook_code 

select 
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
from ambook where 
		book_code = @MSKbook_code 

return @@error 
GO
GRANT EXECUTE ON  [dbo].[ambookNextRow_sp] TO [public]
GO
