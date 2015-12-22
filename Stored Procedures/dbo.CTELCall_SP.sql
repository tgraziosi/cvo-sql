SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

create proc [dbo].[CTELCall_SP] @WhereClause varchar(255) as 
	exec [DEV-DB-01].[CVO_CRM]..CTELExplSource_SP @WhereClause, 'ExplCallView'
GO
GRANT EXECUTE ON  [dbo].[CTELCall_SP] TO [public]
GO
