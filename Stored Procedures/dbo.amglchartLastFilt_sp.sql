SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amglchartLastFilt_sp] 
( 
	@rowsrequested smallint = 1,
	@account_code_filter 	varchar(32 )
) as 


CREATE TABLE #temp 
( 
	timestamp 				varbinary(8) null,
	account_code 			varchar(32) null,
	account_description 	varchar(40) null,
	account_type 			smallint null,
	new_flag 				smallint null,
	seg1_code 				varchar(32) null,
	seg2_code 				varchar(32) null,
	seg3_code 				varchar(32) null,
	seg4_code 				varchar(32) null,
	consol_detail_flag 		smallint null,
	consol_type 			smallint null,
	active_date 			int null,
	inactive_date 			int null,
	inactive_flag 			smallint null,
	currency_code 			varchar(8) null,
	revaluate_flag 			smallint null 
)

declare @rowsfound smallint 
declare @MSKaccount_code varchar(32 )

select @rowsfound = 0 

select 	@MSKaccount_code 	= max(account_code) 
from 	glchart 
where 	account_code 		like RTRIM(@account_code_filter)

if @MSKaccount_code is null 
begin 
 drop table #temp 
 return 
end 

insert into #temp 
select 	
	timestamp,
	account_code,
	account_description,
	account_type,
	new_flag,
	seg1_code,
	seg2_code,
	seg3_code,
	seg4_code,
	consol_detail_flag,
	consol_type,
	active_date,
	inactive_date,
	inactive_flag,
	currency_code,
	revaluate_flag 
from 	glchart 
where 	account_code = @MSKaccount_code 

select @rowsfound = @@rowcount 

select 	@MSKaccount_code = max(account_code) 
from 	glchart 
where 	account_code 	< @MSKaccount_code 
and 	account_code 	like RTRIM(@account_code_filter)

while @MSKaccount_code is not null and @rowsfound < @rowsrequested 
begin 

	insert into #temp 
	select 
		timestamp,
		account_code,
		account_description,
		account_type,
		new_flag,
		seg1_code,
		seg2_code,
		seg3_code,
		seg4_code,
		consol_detail_flag,
		consol_type,
		active_date,
		inactive_date,
		inactive_flag,
		currency_code,
		revaluate_flag 
	from 	glchart 
	where 	account_code = @MSKaccount_code 

	select @rowsfound = @rowsfound + @@rowcount 

	 
	select 	@MSKaccount_code 	= max(account_code) 
	from 	glchart 
	where 	account_code 		< @MSKaccount_code 
 	and 	account_code 		like RTRIM(@account_code_filter)
end 

select 
	timestamp,
	account_code,
	account_description,
	account_type,
	new_flag,
	seg1_code,
	seg2_code,
	seg3_code,
	seg4_code,
	consol_detail_flag,
	consol_type,
	active_date,
	inactive_date,
	inactive_flag,
	currency_code,
	revaluate_flag 
from #temp 
order by account_code 
drop table #temp 

return 0 
GO
GRANT EXECUTE ON  [dbo].[amglchartLastFilt_sp] TO [public]
GO
