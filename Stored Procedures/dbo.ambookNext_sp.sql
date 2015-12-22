SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[ambookNext_sp] 
( 
	@rowsrequested smallint = 1,
	@book_code 	smBookCode 
) 
AS 

CREATE TABLE #temp 
( 
	timestamp 					varbinary(8) 	null,
	book_code 					char(8) 		null,
	book_description 			varchar(40) 	null,
	capitalization_threshold 	float 			null,
	currency_code 				varchar(8) 		null,
	allow_revaluations 			tinyint 		null,
	allow_writedowns 			tinyint 		null,
	allow_adjustments 			tinyint 		null,
	suspend_depr 				tinyint 		null,
	post_to_gl 					tinyint 		null,
	gl_book_code 				varchar(8) 		null,
	depr_if_less_than_yr		tinyint 		null 
)
declare @rowsfound smallint 
declare @MSKbook_code smBookCode 

select 	@rowsfound = 0 
select 	@MSKbook_code = @book_code 
select 	@MSKbook_code = min(book_code) 
from 	ambook 
where 	book_code > @MSKbook_code 

while @MSKbook_code is not null and @rowsfound < @rowsrequested 
begin 

	insert 	into #temp 
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
	from 	ambook 
	where 	book_code = @MSKbook_code 

	select @rowsfound = @rowsfound + @@rowcount 

	 
	select 	@MSKbook_code = min(book_code) 
	from 	ambook 
	where 	book_code > @MSKbook_code 
END 

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
FROM 	#temp 
ORDER BY book_code 
DROP TABLE #temp 

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[ambookNext_sp] TO [public]
GO
