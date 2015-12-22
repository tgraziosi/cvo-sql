SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

create proc [dbo].[CTELPeople_SP] @WhereClause varchar(255) as 
	exec [DEV-DB-01].[CVO_CRM]..CTELExplSource_SP @WhereClause, 'ExplPeopleView'
GO
GRANT EXECUTE ON  [dbo].[CTELPeople_SP] TO [public]
GO
