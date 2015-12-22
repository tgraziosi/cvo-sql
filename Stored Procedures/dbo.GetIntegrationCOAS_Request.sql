SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[GetIntegrationCOAS_Request] (@accountI as VARCHAR(32) = NULL, @accountF as VARCHAR(32) = NULL, @companyCode VARCHAR(20))
AS

DECLARE @db_name varchar(20), @STR varchar(500)
SELECT @db_name = db_name 
FROM CVO_Control..smcomp WHERE company_id = @companyCode

SET @STR = @db_name + '..GetIntegrationCOAS ' + '''' + @accountI + '''' + ',' + '''' + @accountF + ''''

EXEC (@STR)



GO
GRANT EXECUTE ON  [dbo].[GetIntegrationCOAS_Request] TO [public]
GO
