SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[gltrxcan_sp]

AS

BEGIN

	DELETE	#gltrx
	DELETE	#gltrxdet
	
	RETURN	0
END
GO
GRANT EXECUTE ON  [dbo].[gltrxcan_sp] TO [public]
GO
