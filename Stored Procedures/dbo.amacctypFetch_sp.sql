SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amacctypFetch_sp] 
( 
	@rowsrequested smallint = 1,
	@account_type_name smName 
) as 

SET ROWCOUNT @rowsrequested


SELECT timestamp, account_type, system_defined, income_account, display_order, account_type_name, account_type_short_name, account_type_description, updated_by
FROM amacctyp
WHERE	account_type_name >= @account_type_name

SET ROWCOUNT 0

return @@error 
GO
GRANT EXECUTE ON  [dbo].[amacctypFetch_sp] TO [public]
GO
