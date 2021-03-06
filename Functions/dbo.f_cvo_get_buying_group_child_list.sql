SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- SELECT * FROM dbo.f_cvo_get_buying_group_child_list('BG1',GETDATE())

CREATE FUNCTION [dbo].[f_cvo_get_buying_group_child_list]	(@parent	varchar(10),
														@asofdate	datetime)
RETURNS @child_list TABLE (child varchar(10))
AS
BEGIN

	-- DECLARATIONS
	DECLARE	@relation_code	varchar(10)

	-- Get the relation ship code from arco
	SELECT	@relation_code = credit_check_rel_code  
	FROM	arco (NOLOCK)  
  
	-- Retrieve the buying group child list
	INSERT	@child_list
	SELECT	DISTINCT child
	FROM	cvo_buying_groups_hist (NOLOCK)
	WHERE	relation_code = @relation_code
	AND		parent = @parent
	AND		start_date <= CONVERT(varchar(10),@asofdate,121)
	AND		(end_date >= CONVERT(varchar(10),@asofdate,121) OR end_date IS NULL)
	ORDER BY child ASC

	RETURN
END
GO
GRANT REFERENCES ON  [dbo].[f_cvo_get_buying_group_child_list] TO [public]
GO
GRANT SELECT ON  [dbo].[f_cvo_get_buying_group_child_list] TO [public]
GO
