SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create proc [dbo].[sp_crossref]
@vcColumnName1 varchar(30)
AS
DECLARE @vcMsg varchar(50)

Select @vcMsg = 'Tables with ' + @vcColumnName1
Print @vcMsg
Print ''
Select 'SELECT * FROM '+o.name from sysobjects o, syscolumns c
 where c.name = @vccolumnName1 And c.id = o.id And o.type = 'U'
 Order by o.name
GO
GRANT EXECUTE ON  [dbo].[sp_crossref] TO [public]
GO
