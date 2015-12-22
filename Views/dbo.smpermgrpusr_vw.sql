SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2006 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2006 Epicor Software Corporation, 2006    
                  All Rights Reserved                    
*/                                                
 
CREATE VIEW [dbo].[smpermgrpusr_vw]
AS
SELECT sup.user_id, sup.company_id, sup.app_id, sup.form_id, 
sup.object_type, sup.read_perm, sup.write, sup.user_copy,1 as 'user_grant',0  as 'group_grant','' as group_id
FROM CVO_Control..smuserperm sup (NOLOCK)
UNION
SELECT smgvw.user_id, sgp.company_id, sgp.app_id, sgp.form_id, 
sgp.object_type, sgp.read_perm, sgp.write, 0,0  as 'user_grant',1 as 'group_grant',smgvw.group_id as group_id
FROM CVO_Control..smgrpperm sgp (NOLOCK)
	INNER JOIN CVO_Control..smgrpdet smgvw(NOLOCK) ON sgp.group_id = smgvw.group_id  
	LEFT JOIN CVO_Control..smuserperm sup (NOLOCK) on sgp.company_id = sup.company_id and sgp.app_id = sup.app_id and sgp.form_id = sup.app_id and smgvw.user_id = sup.user_id
WHERE sup.company_id IS NULL

GO
GRANT REFERENCES ON  [dbo].[smpermgrpusr_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[smpermgrpusr_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[smpermgrpusr_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[smpermgrpusr_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[smpermgrpusr_vw] TO [public]
GO
