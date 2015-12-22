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



























CREATE VIEW [dbo].[ibregion_vw]
AS

	SELECT 	organization_id,
		organization_name,
		outline_num,
		active_flag = CASE active_flag WHEN 1 THEN 'YES' WHEN 0 THEN 'NO' END,
		new_flag = CASE new_flag WHEN 1 THEN 'YES' WHEN 0 THEN 'NO' END,
		inherit_security = CASE inherit_security WHEN 1 THEN 'YES' WHEN 0 THEN 'NO' END,
		inherit_setup = CASE inherit_setup WHEN 1 THEN 'YES' WHEN 0 THEN 'NO' END
	FROM Organization
	WHERE region_flag = 1
		OR outline_num = '1'

GO
GRANT REFERENCES ON  [dbo].[ibregion_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[ibregion_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[ibregion_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[ibregion_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[ibregion_vw] TO [public]
GO
