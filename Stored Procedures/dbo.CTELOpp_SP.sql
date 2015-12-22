SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

create proc [dbo].[CTELOpp_SP] @WhereClause varchar(255) as 
	exec [DEV-DB-01].[CVO_CRM]..CTELExplSource_SP @WhereClause, 'ExplOppView'
GO
GRANT EXECUTE ON  [dbo].[CTELOpp_SP] TO [public]
GO
