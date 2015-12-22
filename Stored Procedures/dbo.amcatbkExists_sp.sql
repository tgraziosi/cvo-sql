SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amcatbkExists_sp] 
( 
	@category_code 	smCategoryCode, 
	@book_code 	smBookCode, 
	@effective_date 	varchar(30), 
	@valid int output 
) as 


if exists (select 1 from amcatbk where 
	category_code 	= @category_code and 
	book_code 	= @book_code and 
	effective_date 	= @effective_date 
)
 select @valid = 1 
else 
 select @valid = 0 
return @@error 
GO
GRANT EXECUTE ON  [dbo].[amcatbkExists_sp] TO [public]
GO
