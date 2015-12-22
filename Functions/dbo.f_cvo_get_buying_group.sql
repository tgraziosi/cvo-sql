SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- SELECT dbo.f_cvo_get_buying_group('010194',GETDATE())

CREATE FUNCTION [dbo].[f_cvo_get_buying_group]	(@child		varchar(10),
											@asofdate	datetime)
RETURNS varchar(10)
AS
BEGIN

	-- DECLARATIONS
	DECLARE	@relation_code	varchar(10),
			@parent			varchar(10)

	-- Get the relation ship code from arco
	SELECT	@relation_code = credit_check_rel_code  
	FROM	arco (NOLOCK)  
  
	-- Retrieve the buying group 
	SELECT	@parent = parent
	FROM	cvo_buying_groups_hist (NOLOCK)
	WHERE	relation_code = @relation_code
	AND		child = @child
	AND		start_date <= CONVERT(varchar(10),@asofdate,121)
	AND		(end_date >= CONVERT(varchar(10),@asofdate,121) OR end_date IS NULL)	 

	RETURN ISNULL(@parent,'')

END
GO
GRANT REFERENCES ON  [dbo].[f_cvo_get_buying_group] TO [public]
GO
GRANT EXECUTE ON  [dbo].[f_cvo_get_buying_group] TO [public]
GO
