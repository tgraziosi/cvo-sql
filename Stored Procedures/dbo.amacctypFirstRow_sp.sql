SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amacctypFirstRow_sp]
			 
as 


declare @MSKaccount_type_name smName

select @MSKaccount_type_name = min(account_type_name) 
from amacctyp
 
select timestamp, account_type, system_defined, income_account, display_order, account_type_name, account_type_short_name, account_type_description, updated_by 	 
from amacctyp 
where 	account_type_name = @MSKaccount_type_name 

return @@error 
GO
GRANT EXECUTE ON  [dbo].[amacctypFirstRow_sp] TO [public]
GO
