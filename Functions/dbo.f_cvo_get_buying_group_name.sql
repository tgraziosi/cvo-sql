SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- SELECT dbo.f_cvo_get_buying_group_name('000500')

CREATE FUNCTION [dbo].[f_cvo_get_buying_group_name]	(@parent	varchar(10))
RETURNS varchar(60)
AS
BEGIN

	-- DECLARATIONS
	DECLARE	@parent_name	varchar(60)
  
	-- Retrieve the buying group 
	SELECT	@parent_name = address_name
	FROM	armaster_all (NOLOCK)
	WHERE	customer_code = @parent
	AND		address_type = 0

	RETURN ISNULL(@parent_name,'')

END
GO
GRANT REFERENCES ON  [dbo].[f_cvo_get_buying_group_name] TO [public]
GO
GRANT EXECUTE ON  [dbo].[f_cvo_get_buying_group_name] TO [public]
GO
