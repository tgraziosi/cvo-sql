SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE PROC [dbo].[IBregion_all_reg_sp]
AS
	BEGIN TRAN Refresh_IBregion_all

	TRUNCATE TABLE IBregion_all

	INSERT INTO IBregion_all
	SELECT 	parent.organization_id 	AS region_id,
		childs.organization_id 	AS org_id,
		parent.outline_num  AS parent_outline_num,
		parent.region_flag AS  parent_region_flag
	FROM Organization_all parent, Organization_all childs
	WHERE 	parent.outline_num = '1'
	AND	childs.outline_num <> '1'
	UNION
	SELECT 	parent.organization_id 	AS region_id,
		childs.organization_id 	AS org_id,
		parent.outline_num 	AS parent_outline_num,
		parent.region_flag AS  parent_region_flag
	FROM  Organization_all parent, Organization_all childs
	WHERE childs.outline_num LIKE parent.outline_num + '.%'
	AND	parent.organization_id <> childs.organization_id 
	AND	CHARINDEX ( '.', childs.outline_num  ) <> 0 
	UNION
	SELECT 	parent.organization_id 	AS region_id,
		parent.organization_id 	AS org_id,
		parent.outline_num  AS parent_outline_num,
		parent.region_flag AS  parent_region_flag
	FROM Organization_all parent
	WHERE 	parent.outline_num = '1'
	
	COMMIT TRAN Refresh_IBregion_all

GO
GRANT EXECUTE ON  [dbo].[IBregion_all_reg_sp] TO [public]
GO
