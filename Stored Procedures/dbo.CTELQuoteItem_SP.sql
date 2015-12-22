SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

create proc [dbo].[CTELQuoteItem_SP] @WhereClause varchar(255) as 
	exec [DEV-DB-01].[CVO_CRM]..CTELExplSource_SP @WhereClause, 'ExplQuoteItemView'
GO
GRANT EXECUTE ON  [dbo].[CTELQuoteItem_SP] TO [public]
GO
