SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amacctypLastFilt_sp] 
( 
	@rowsrequested smallint = 1,
	@account_type_name_filter varchar(30) 
) as 


declare
 	@rowsfound 			smallint, 
	@MSKaccount_type_name 	smName 
	
select @rowsfound = 0 
SELECT @account_type_name_filter = RTRIM(@account_type_name_filter)


select 	@MSKaccount_type_name 	= max(account_type_name) 
from 	amacctyp 
where 	RTRIM(CONVERT(char(30),account_type_name)) 		like @account_type_name_filter


if @MSKaccount_type_name is null 
begin 
 return 
end 

create table #temp ( timestamp varbinary(8) null, account_type smallint, system_defined tinyint, income_account tinyint, display_order int, account_type_name varchar(30), account_type_short_name varchar(30), account_type_description varchar(40) null, updated_by int )

insert into #temp 
select timestamp, account_type, system_defined, income_account, display_order, account_type_name, account_type_short_name, account_type_description, updated_by			 
from 	amacctyp 
where 	account_type_name 	= @MSKaccount_type_name 

select @rowsfound = @@rowcount 

select 	@MSKaccount_type_name 	= max(account_type_name) 
from 	amacctyp 
where 	account_type_name 		< @MSKaccount_type_name 
and 	RTRIM(CONVERT(char(30),account_type_name)) 		like @account_type_name_filter

while @MSKaccount_type_name is not null and @rowsfound < @rowsrequested 
begin 

	insert 	into #temp 
	select timestamp, account_type, system_defined, income_account, display_order, account_type_name, account_type_short_name, account_type_description, updated_by	 
	from 	amacctyp 
	where 	account_type_name = @MSKaccount_type_name 

	select @rowsfound = @rowsfound + @@rowcount 

	 
	select 	@MSKaccount_type_name = max(account_type_name) 
	from 	amacctyp 
	where 	account_type_name < @MSKaccount_type_name 
 	and 	RTRIM(CONVERT(char(30),account_type_name)) 		like @account_type_name_filter
end 

select timestamp, account_type, system_defined, income_account, display_order, account_type_name, account_type_short_name, account_type_description, updated_by		 
from #temp 
order by account_type_name 

drop table #temp 

return @@error 
GO
GRANT EXECUTE ON  [dbo].[amacctypLastFilt_sp] TO [public]
GO
