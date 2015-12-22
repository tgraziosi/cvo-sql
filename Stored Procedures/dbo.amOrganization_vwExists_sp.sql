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

create procedure [dbo].[amOrganization_vwExists_sp]
( 
	@org_id varchar(30), 
	@valid int output 
) as 


if exists (select 1 from amOrganization_vw where 
	org_id = @org_id 
        and active_flag = 1 
)
 select @valid = 1 
else 
 select @valid = 0 
return @@error 

grant all  on   amOrganization_vwExists_sp to public 
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[amOrganization_vwExists_sp] TO [public]
GO
