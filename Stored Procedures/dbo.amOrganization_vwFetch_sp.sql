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

create procedure [dbo].[amOrganization_vwFetch_sp]
(
	@rowsrequested smallint = 1,
	@org_id smOrgId
) as


create table #temp (
--	timestamp			timestamp,
	organization_id			varchar(30) NOT NULL,	
	organization_name		varchar(60) NOT NULL,
	active_flag 	                int NOT NULL, 
	outline_num 			varchar(120) NOT NULL,
	branch_account_number		varchar(32) NOT NULL,
	new_flag			integer,
	create_date			datetime,
	create_username			varchar(255),
	last_change_date		datetime,
	last_change_username		varchar(255),
	addr1				varchar(40),
	addr2				varchar(40),
	addr3				varchar(40),
	addr4				varchar(40),
	addr5				varchar(40),
	addr6				varchar(40),
	city				varchar(40),
	state				varchar(40),
	postal_code			varchar(15),
	country				varchar(3),
	tax_id_num			varchar(20)
)
declare @rowsfound 				smallint
declare @MSKorg_id			smOrgId

select @rowsfound = 0
select @MSKorg_id = @org_id

if exists (select * from amOrganization_vw where
	org_id = @MSKorg_id )
begin
	while @MSKorg_id is not null and @rowsfound < @rowsrequested
	begin

		insert into #temp select 
--			timestamp			,
			organization_id			,	
			organization_name		,
			active_flag 	                , 
			outline_num 			,
			branch_account_number		,
			new_flag			,
			create_date			,
			create_username			,
			last_change_date		,
			last_change_username		,
			addr1				,
			addr2				,
			addr3				,
			addr4				,
			addr5				,
			addr6				,
			city				,
			state				,
			postal_code			,
			country				,
			tax_id_num			
		 from amOrganization_vw where
			org_id = @MSKorg_id

			select @rowsfound = @rowsfound + @@rowcount
		
		select @MSKorg_id = min(org_id) from amOrganization_vw where
		org_id = @MSKorg_id
	end
end
select
--	timestamp			,
	organization_id			,	
	organization_name		,
	active_flag 	                , 
	outline_num 			,
	branch_account_number		,
	new_flag			,
	create_date	 = convert(char(8),create_date,112)	 ,
	create_username			,
	last_change_date = convert(char(8),last_change_date,112) ,
	last_change_username		,
	addr1				,
	addr2				,
	addr3				,
	addr4				,
	addr5				,
	addr6				,
	city				,
	state				,
	postal_code			,
	country				,
	tax_id_num		
from #temp order by organization_id
drop table #temp

return @@error
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[amOrganization_vwFetch_sp] TO [public]
GO
