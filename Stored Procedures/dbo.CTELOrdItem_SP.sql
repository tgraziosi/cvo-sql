SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

create proc [dbo].[CTELOrdItem_SP] @WhereClause varchar(255) as 
	exec [DEV-DB-01].[CVO_CRM]..CTELExplSource_SP @WhereClause, 'ExplOrdItemView'
GO
GRANT EXECUTE ON  [dbo].[CTELOrdItem_SP] TO [public]
GO
