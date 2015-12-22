SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amusrfldFetch_sp] 
( 
	@rowsrequested smallint = 1,
	@user_field_id 		smSurrogateKey 
) as 


create table #temp ( 
	timestamp varbinary(8) null,
	user_field_id int null,
	user_code_1 varchar(40) null,
	user_code_2 varchar(40) null,
	user_code_3 varchar(40) null,
	user_code_4 varchar(40) null,
	user_code_5 varchar(40) null,
	user_date_1 datetime null,
	user_date_2 datetime null,
	user_date_3 datetime null,
	user_date_4 datetime null,
	user_date_5 datetime null,
	user_amount_1 float null,
	user_amount_2 float null,
	user_amount_3 float null,
	user_amount_4 float null,
	user_amount_5 float null 
)
declare @rowsfound smallint 
select @rowsfound = 0 
declare @MSKuser_field_id int 

select @MSKuser_field_id = @user_field_id 
if exists (select * from amusrfld where 
	user_field_id = @MSKuser_field_id )
begin 
while @MSKuser_field_id is not null and @rowsfound < @rowsrequested 
begin 

	insert into #temp 
	select 
		timestamp,
		user_field_id,
		user_code_1,
		user_code_2,
		user_code_3,
		user_code_4,
		user_code_5,
		user_date_1, 
		user_date_2, 
		user_date_3, 
		user_date_4, 
		user_date_5, 
		user_amount_1,
		user_amount_2,
		user_amount_3,
		user_amount_4,
		user_amount_5 
	from amusrfld 
	where 
		 user_field_id= @MSKuser_field_id 

		select @rowsfound = @rowsfound + @@rowcount 
	 
	select @MSKuser_field_id = min(user_field_id) from amusrfld where 
	 user_field_id> @MSKuser_field_id 
end 
end 
select 
	timestamp,
	user_field_id,
	user_code_1,
	user_code_2,
	user_code_3,
	user_code_4,
	user_code_5,
	user_date_1 = convert(char(8), user_date_1,112), 
	user_date_2 = convert(char(8), user_date_2,112), 
	user_date_3 = convert(char(8), user_date_3,112), 
	user_date_4 = convert(char(8), user_date_4,112), 
	user_date_5 = convert(char(8), user_date_5,112), 
	user_amount_1,
	user_amount_2,
	user_amount_3,
	user_amount_4,
	user_amount_5 
from #temp order by user_field_id 
drop table #temp 

return @@error 
GO
GRANT EXECUTE ON  [dbo].[amusrfldFetch_sp] TO [public]
GO
