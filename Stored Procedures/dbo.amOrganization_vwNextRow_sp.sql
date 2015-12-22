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


create procedure [dbo].[amOrganization_vwNextRow_sp] 
( 
	@org_id smOrgId
) as 


declare @MSKorg_id smOrgId

select @MSKorg_id = @org_id 
 
select @MSKorg_id = min(org_id ) 
from 	amOrganization_vw 
where 	org_id > @MSKorg_id 

select timestamp,organization_id,organization_name,active_flag,outline_num,branch_account_number,new_flag,create_date,create_username,last_change_date,last_change_username,addr1,addr2,addr3,addr4,addr5,addr6,city,state,postal_code,country,tax_id_num,region_flag
from amOrganization_vw 
where org_id = @MSKorg_id 

return @@error 
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[amOrganization_vwNextRow_sp] TO [public]
GO
