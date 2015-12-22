SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

create proc [dbo].[CTELQuote_SP] @WhereClause varchar(255) as 
	exec [DEV-DB-01].[CVO_CRM]..CTELExplSource_SP @WhereClause, 'ExplQuoteView'
GO
GRANT EXECUTE ON  [dbo].[CTELQuote_SP] TO [public]
GO
