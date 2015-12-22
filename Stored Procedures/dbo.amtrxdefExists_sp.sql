SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amtrxdefExists_sp] 
( 
	@trx_name smName, 
	@valid int output 
) as 


if exists (select 1 from amtrxdef where 
	
	trx_name = @trx_name 
)
 select @valid = 1 
else 
 select @valid = 0 
return @@error 
GO
GRANT EXECUTE ON  [dbo].[amtrxdefExists_sp] TO [public]
GO
