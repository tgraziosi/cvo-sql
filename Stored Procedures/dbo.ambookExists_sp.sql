SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[ambookExists_sp] 
( 
	@book_code 	smBookCode, 
	@valid int output 
) as 


if exists (select 1 from ambook where 
	book_code 	= @book_code 
)
 select @valid = 1 
else 
 select @valid = 0 
return @@error 
GO
GRANT EXECUTE ON  [dbo].[ambookExists_sp] TO [public]
GO
