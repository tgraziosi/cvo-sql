SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_get_db_version_sp] 
AS

DECLARE @version smallint
SELECT @version = 1

IF ( 	SELECT COUNT(*) 
		FROM aeg_version_new
		WHERE appid = 25000 
		AND	major_version >= 7 
		AND (	( minor_version >= 2 AND	build_no >= 5 ) OR 
						( minor_version >= 3 AND	build_no >= 0 )	) ) > 0
			SELECT @version = 0 

SELECT @version

GO
GRANT EXECUTE ON  [dbo].[cc_get_db_version_sp] TO [public]
GO
