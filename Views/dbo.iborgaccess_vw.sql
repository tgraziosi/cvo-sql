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


























CREATE VIEW [dbo].[iborgaccess_vw]
AS
	SELECT
		ch.parent_org_id,
		parent_region_flag = CASE ch.parent_region WHEN 1 THEN 'YES' WHEN 0 THEN 'NO' END,
		ch.child_org_id,
		active_flag = CASE o.active_flag WHEN 1 THEN 'YES' WHEN 0 THEN 'NO' END,
		ch.child_outline_num,
		o.branch_account_number,
		new_flag = CASE o.new_flag WHEN 1 THEN 'YES' WHEN 0 THEN 'NO' END,
		inherit_security = CASE ch.child_inherit_security WHEN 1 THEN 'YES' WHEN 0 THEN 'NO' END,
		inherit_setup = CASE ch.child_inherit_setup WHEN 1 THEN 'YES' WHEN 0 THEN 'NO' END
	FROM
		Organization o INNER JOIN IBAllChilds_vw ch ON o.organization_id = ch.child_org_id
	WHERE 
		ch.child_region = 0
GO
GRANT REFERENCES ON  [dbo].[iborgaccess_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[iborgaccess_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[iborgaccess_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[iborgaccess_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[iborgaccess_vw] TO [public]
GO
