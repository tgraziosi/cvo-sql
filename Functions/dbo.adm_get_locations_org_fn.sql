SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

-- v1.0 Only using one org

CREATE FUNCTION [dbo].[adm_get_locations_org_fn] (@loc varchar(10))
RETURNS varchar(30)
BEGIN		


		DECLARE @ret varchar(30)

		select @ret = 'CVO' --isnull((select organization_id from locations_all (nolock) where location = @loc),'CVO') v1.0
	RETURN @ret
END

GO
GRANT REFERENCES ON  [dbo].[adm_get_locations_org_fn] TO [public]
GO
GRANT EXECUTE ON  [dbo].[adm_get_locations_org_fn] TO [public]
GO
