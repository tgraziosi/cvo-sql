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


CREATE procedure [dbo].[amRegion_vwFirst_sp] 
( 
	@rowsrequested smallint = 1 
) as 

--set nocount off

create table #temp ( 
--	timestamp varbinary(8) null,
	region_id varchar(30) null
)

declare @rowsfound smallint 
select @rowsfound = 0 
declare @MSKregion varchar(30) 

select @MSKregion = min(region_id) from amRegion_vw 
if @MSKregion is null 
begin 
 drop table #temp 
 return 
end 

insert into #temp 
select 
	    region_id
from amRegion_vw 
where 
		region_id = @MSKregion 

select @rowsfound = @@rowcount 

select @MSKregion = min(region_id) from amRegion_vw where 
	region_id > @MSKregion 
while @MSKregion is not null and @rowsfound < @rowsrequested 
begin 

	insert into #temp
	select 
	        region_id 
	from amRegion_vw
	where 
		region_id = @MSKregion 

		select @rowsfound = @rowsfound + @@rowcount 
	 
	select @MSKregion = min(region_id) from amRegion_vw where 
	region_id > @MSKregion 
end 
select 
	region_id 
from #temp order by region_id 
drop table #temp 

return @@error 

commit tran




/**/                                              
GO
GRANT EXECUTE ON  [dbo].[amRegion_vwFirst_sp] TO [public]
GO
