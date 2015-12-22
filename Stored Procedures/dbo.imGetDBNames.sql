SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[imGetDBNames]
AS
    BEGIN
       select name from master..sysdatabases order by name 
    END

GO
GRANT EXECUTE ON  [dbo].[imGetDBNames] TO [public]
GO
