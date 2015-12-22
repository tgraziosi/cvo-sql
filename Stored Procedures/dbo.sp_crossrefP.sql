SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create proc [dbo].[sp_crossrefP]
@vcColumnName1 varchar(30)
AS
DECLARE @vcMsg varchar(50)

Select @vcMsg = 'Procs Containing ' + @vcColumnName1
Print @vcMsg
Print ''
Select tablename = o.name from sysobjects o, syscomments c
 where c.text like @vccolumnName1 And c.id = o.id And o.type = 'P'
 Order by o.name
GO
GRANT EXECUTE ON  [dbo].[sp_crossrefP] TO [public]
GO
