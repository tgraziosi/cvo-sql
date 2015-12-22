SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[SMTPSNextObject_SP] 
AS
declare @name	varchar( 128 )

BEGIN

	SELECT @name = NULL

	SELECT @name = MIN( name )
	FROM	#object_list

	IF ( @@rowcount = 1 )
		SELECT	@name

	DELETE 	#object_list
	WHERE 	name = @name

END
GO
GRANT EXECUTE ON  [dbo].[SMTPSNextObject_SP] TO [public]
GO
