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


CREATE procedure [dbo].[amOrganization_vwFirst_sp] 
( 
	@rowsrequested smallint = 1 
) as 

--set nocount off

create table #temp ( 
--	timestamp varbinary(8) null,
	org_id varchar(30) null,
	organizationname varchar(60) null
	
)
declare @rowsfound smallint 
select @rowsfound = 0 
declare @MSKorganization varchar(30) 

select @MSKorganization = min(org_id) from amOrganization_vw 
if @MSKorganization is null 
begin 
 drop table #temp 
 return 
end 

insert into #temp 
select 
--		timestamp,
	    org_id,
		organizationname
from amOrganization_vw 
where 
		org_id = @MSKorganization 

select @rowsfound = @@rowcount 

select @MSKorganization = min(org_id) from amOrganization_vw where 
	org_id > @MSKorganization 
while @MSKorganization is not null and @rowsfound < @rowsrequested 
begin 

	insert into #temp
	select 
--		timestamp,
	        org_id,
		organizationname
		 
	from amOrganization_vw
	where 
		org_id = @MSKorganization 

		select @rowsfound = @rowsfound + @@rowcount 
	 
	select @MSKorganization = min(org_id) from amOrganization_vw where 
	org_id > @MSKorganization 
end 
select 
--	timestamp,
	org_id,
	organizationname
	 
from #temp order by org_id 
drop table #temp 

return @@error 

commit tran




/**/                                              
GO
GRANT EXECUTE ON  [dbo].[amOrganization_vwFirst_sp] TO [public]
GO
