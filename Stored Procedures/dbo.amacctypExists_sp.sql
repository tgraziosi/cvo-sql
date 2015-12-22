SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amacctypExists_sp] 
( 
	@account_type_name smName, 
	@valid int output 
) as 


if exists (select 1 from amacctyp where 
	
	account_type_name = @account_type_name 
)
 select @valid = 1 
else 
 select @valid = 0 
return @@error 
GO
GRANT EXECUTE ON  [dbo].[amacctypExists_sp] TO [public]
GO
