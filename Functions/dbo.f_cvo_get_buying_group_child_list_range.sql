SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- SELECT * FROM dbo.f_cvo_get_buying_group_child_list_range('000500','2011-01-01','2013-07-17')

CREATE FUNCTION [dbo].[f_cvo_get_buying_group_child_list_range]	(@parent	varchar(10),
															 @startdate	datetime,
															 @enddate	datetime)
RETURNS @child_list TABLE (child varchar(10))
AS
BEGIN

	-- DECLARATIONS
	DECLARE	@relation_code	varchar(10)

	-- Get the relation ship code from arco
	SELECT	@relation_code = credit_check_rel_code  
	FROM	arco (NOLOCK)  
  
	-- Retrieve the buying group child list
	IF (@startdate IS NULL)
	BEGIN
		INSERT	@child_list
		SELECT	DISTINCT child
		FROM	cvo_buying_groups_hist (NOLOCK)
		WHERE	relation_code = @relation_code
		AND		parent = @parent
	END
	ELSE
	BEGIN
		INSERT	@child_list
		SELECT	DISTINCT child
		FROM	cvo_buying_groups_hist (NOLOCK)
		WHERE	relation_code = @relation_code
		AND		parent = @parent
		AND		start_date <= CONVERT(varchar(10),@enddate,121)
		AND		(end_date >= CONVERT(varchar(10),@startdate,121) OR end_date IS NULL)
	END

	RETURN
END
GO
GRANT REFERENCES ON  [dbo].[f_cvo_get_buying_group_child_list_range] TO [public]
GO
GRANT SELECT ON  [dbo].[f_cvo_get_buying_group_child_list_range] TO [public]
GO
