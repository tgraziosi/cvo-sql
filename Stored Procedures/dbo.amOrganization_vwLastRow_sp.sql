SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/                                                

create procedure [dbo].[amOrganization_vwLastRow_sp] 
as 


declare @MSKorg_id smOrgId

select @MSKorg_id = max(org_id) from amOrganization_vw 

select 	
	org_id, 
	organizationname 
from 	amOrganization_vw
where   org_id = @MSKorg_id 

return @@error 
	
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[amOrganization_vwLastRow_sp] TO [public]
GO
