SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[fs_generic_find] @sqltext varchar(1000) AS

declare @name varchar(50), @description varchar(255)

exec( @sqltext )
GO
GRANT EXECUTE ON  [dbo].[fs_generic_find] TO [public]
GO
