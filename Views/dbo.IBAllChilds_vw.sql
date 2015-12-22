SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2002 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2002 Epicor Software Corporation, 2002    
                  All Rights Reserved                    
*/                                                






















	

	CREATE VIEW [dbo].[IBAllChilds_vw]
	AS
	SELECT 	parent.organization_id 	parent_org_id,
		parent.outline_num 	parent_outline_num,
		parent.region_flag 	parent_region,
		childs.organization_id 	child_org_id,
		childs.outline_num 	child_outline_num,
		childs.region_flag 	child_region,
		childs.inherit_setup child_inherit_setup,
		childs.inherit_security child_inherit_security
	FROM Organization parent, Organization childs
	WHERE 	parent.outline_num = '1'
	AND	childs.outline_num <> '1'
	UNION
	SELECT	parent.organization_id 	parent_org_id,
		parent.outline_num 	parent_outline_num ,
		parent.region_flag 	parent_region,
		childs.organization_id 	child_org_id,
		childs.outline_num 	child_outline_num,
		childs.region_flag 	child_region,
		childs.inherit_setup child_inherit_setup,
		childs.inherit_security child_inherit_security
	FROM  Organization parent, Organization childs
	WHERE childs.outline_num LIKE parent.outline_num + '.%'
	AND	parent.organization_id <> childs.organization_id 
	AND	CHARINDEX ( '.', childs.outline_num  ) <> 0 
	UNION
	SELECT 	parent.organization_id 	parent_org_id,
		parent.outline_num 	parent_outline_num,
		parent.region_flag 	parent_region,
		parent.organization_id 	child_org_id,
		parent.outline_num 	child_outline_num,
		parent.region_flag 	child_region,
		parent.inherit_setup child_inherit_setup,
		parent.inherit_security child_inherit_security
	FROM Organization parent
	WHERE 	parent.outline_num = '1'

	
GO
GRANT REFERENCES ON  [dbo].[IBAllChilds_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[IBAllChilds_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[IBAllChilds_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[IBAllChilds_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[IBAllChilds_vw] TO [public]
GO
