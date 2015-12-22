SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE FUNCTION [dbo].[gl_count_organizations_fn] ()
RETURNS smallint
BEGIN		
		DECLARE @ret SMALLINT
		SELECT @ret =  COUNT (1) 
		FROM Organization_all

		RETURN @ret
END
GO
GRANT REFERENCES ON  [dbo].[gl_count_organizations_fn] TO [public]
GO
GRANT EXECUTE ON  [dbo].[gl_count_organizations_fn] TO [public]
GO
