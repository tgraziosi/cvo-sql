SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_server_type_sp] 	

AS
	IF substring((select @@version),1,9) like "Microsoft"
		SELECT 0
	ELSE
		SELECT 1
 
GO
GRANT EXECUTE ON  [dbo].[cc_server_type_sp] TO [public]
GO
