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


create procedure [dbo].[amOrganization_vwPrev_sp] 
( 
	@rowsrequested smallint = 1,
	@org_id varchar(30) 
) as 


create table #temp ( 
	--timestamp varbinary(8) null,
	org_id varchar(30) null,
	organizationname varchar(60) null
	
)
declare @rowsfound smallint 
select @rowsfound = 0 
declare @MSKorg_id varchar(30)
select @MSKorg_id = @org_id 
select @MSKorg_id = max(org_id) from amOrganization_vw where 
	org_id < @MSKorg_id 
while @MSKorg_id is not null and @rowsfound < @rowsrequested 
begin 
	insert into #temp 
	select 
		--timestamp,
		org_id,
		organizationname
		
	from 	amOrganization_vw 
	where 	org_id = @MSKorg_id 

		select @rowsfound = @rowsfound + @@rowcount 
	 
	select @MSKorg_id = max(org_id) from amOrganization_vw where 
	org_id < @MSKorg_id 
end 
select 
	--timestamp,
	org_id,
	organizationname
	
from #temp order by org_id 
drop table #temp 

return @@error 



/**/                                              
GO
GRANT EXECUTE ON  [dbo].[amOrganization_vwPrev_sp] TO [public]
GO
