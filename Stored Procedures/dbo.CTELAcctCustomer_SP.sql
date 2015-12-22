SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

create proc [dbo].[CTELAcctCustomer_SP] @WhereClause varchar(255) as 
	exec [DEV-DB-01].[CVO_CRM]..CTELExplSource_SP @WhereClause, 'ExplAcctCustomerView'
GO
GRANT EXECUTE ON  [dbo].[CTELAcctCustomer_SP] TO [public]
GO
