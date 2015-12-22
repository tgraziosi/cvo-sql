SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amacctypFirst_sp] 
( 
	@rowsrequested smallint = 1
		 
) as 

DECLARE @result 				smErrorCode
declare @MSKaccount_type_name smName


select @MSKaccount_type_name = min(account_type_name) 
from amacctyp 


if @MSKaccount_type_name is null 
begin 
 return 
end 

SET ROWCOUNT @rowsrequested

select timestamp, account_type, system_defined, income_account, display_order, account_type_name, account_type_short_name, account_type_description, updated_by
FROM amacctyp
where	account_type_name >= @MSKaccount_type_name
	
select @result = @@error

SET ROWCOUNT 0	 
return @result

GO
GRANT EXECUTE ON  [dbo].[amacctypFirst_sp] TO [public]
GO
