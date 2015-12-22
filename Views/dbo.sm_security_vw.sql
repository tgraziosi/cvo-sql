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

Create view [dbo].[sm_security_vw]
as
select sm.company_id,						
	   smc.company_name,					
	   sm.user_id,			
	   smu.user_name,		
	   sm.app_id as 'application_id',		
	   sma.app_name as 'application_name',	
	   sm.form_id,			
	   smm.form_desc,					
	   case sm.user_grant  when 1 then 'X' else '' end as 'user_grant',						
	   case sm.group_grant  when 1 then 'X' else '' end as 'group_grant',						
	   sm.group_id
from smpermgrpusr_vw sm inner join CVO_Control..smcomp smc on (sm.company_id = smc.company_id) 
inner join CVO_Control..smapp sma on (sm.app_id = sma.app_id)
inner join CVO_Control..smusers smu on (sm.user_id = smu.user_id)
inner join CVO_Control..smmenus smm on (smm.form_id = sm.form_id)

GO
GRANT REFERENCES ON  [dbo].[sm_security_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[sm_security_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[sm_security_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[sm_security_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[sm_security_vw] TO [public]
GO
