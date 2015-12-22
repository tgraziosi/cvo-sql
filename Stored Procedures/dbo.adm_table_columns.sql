SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[adm_table_columns] @table varchar(100)
AS

select c.name
from sysobjects o, syscolumns c
where o.id = c.id and o.name = @table
order by c.colid
GO
GRANT EXECUTE ON  [dbo].[adm_table_columns] TO [public]
GO
