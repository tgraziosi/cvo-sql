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





















	CREATE VIEW  [dbo].[IBDirectChilds_vw]
	as
	SELECT 	parent.organization_id parent_org_id,
		parent.outline_num parent_outline_num,
		childs.organization_id child_org_id,
		childs.outline_num child_outline_num,
       		 childs.region_flag child_region_flag
 	FROM Organization childs
	INNER JOIN  Organization  as parent
		ON childs.outline_num  like parent.outline_num + '.%'
	WHERE parent.organization_id <> childs.organization_id 
	AND CHARINDEX ( '.',
			SUBSTRING(	childs.outline_num, 
					CHARINDEX (	parent.outline_num+'.',childs.outline_num  )+len(parent.outline_num+'.') , 
							len(childs.outline_num) 
				  )  
			) = 0  
	 AND CHARINDEX ( '.',childs.outline_num  )<> 0 

	
GO
GRANT REFERENCES ON  [dbo].[IBDirectChilds_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[IBDirectChilds_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[IBDirectChilds_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[IBDirectChilds_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[IBDirectChilds_vw] TO [public]
GO
