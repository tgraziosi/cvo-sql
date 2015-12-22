SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[cvo_mass_order_update_sp] as 

set nocount on

/*

exec cvo_mass_order_update_sp

select * From cvo_interim_order_updates where proc_flag is null

update cvo_interim_order_updates set userid = 'tgraziosi' where userid = 'rlanka'
update cvo_interim_order_updates set userid = 'jberman' where order_no = 2084285           

update cvo_interim_order_updates set proc_flag = -1 where proc_flag = -2

update cvo_interim_order_updates set proc_flag = -1, err_msg = 'error 123' where userid is not null
*/

DECLARE
@order_no				int,
@order_ext				int,
@freight_allow_type		varchar(10) ,
@attention				varchar(40) ,
@phone					varchar(20) ,
@cust_po				varchar(20) ,
@user_category			varchar(10) ,				
@so_priority_code		char(1) ,
@routing				varchar(20) ,
@terms_code				varchar(10) ,
@sold_to				varchar(10) ,	
@sch_ship_date			datetime ,
@note					varchar(255) ,
@special_instr			varchar(255) 

declare @allocation_date datetime, @last_id int, @today datetime

set @today = dateadd(dd,datediff(dd,0,getdate()), 0)

create table #log
(
id int null,
ret int null,
err_msg varchar(255) null
)

select @last_id = min(id) from cvo_interim_order_updates where isnull(proc_flag,0) = 0

while @last_id is not null
begin

	select @order_no = order_no, @order_ext = order_ext,
	@freight_allow_type = freight_allowed_type,
	@sch_ship_date = sch_ship_date,
	@allocation_date = allocation_date,
	@routing = case when ship_via = 'BLANK' then null else ship_via end,
	@terms_code = terms
	from cvo_interim_order_updates where id = @last_id

	if ( isnull(@sch_ship_date,@today) < @today or 
	     isnull(@allocation_date,@today) < @today or
	     isnull(@sch_ship_date,@today) < isnull(@allocation_date,@today) )
	insert into #log (ret,err_msg) values (-1,'Invalid ship or allocation date update')
	else
	begin
		update cvo_orders_all set allocation_date = @allocation_date
		where order_no = @order_no and ext = @order_ext 
		and allocation_date <> isnull(@allocation_date,@today)
		if (@@error <> 0) 
			insert into #log (ret,err_msg) values (-1,'Error updating allocation date')
		
		update orders_all set req_ship_date = @sch_ship_date
		where order_no = @order_no and ext = @order_ext 
		and req_ship_date <> isnull(@sch_ship_date,req_ship_date)
		if (@@error <> 0) 
			insert into #log (ret,err_msg) values (-1,'Error updating delivery date')

		if object_id('tempdb..#cvo_order_update_temp') is not null
		drop table #cvo_order_update_temp
		create table #cvo_order_update_temp
		(order_no int, order_ext int, line_no int, changed int, notes varchar(255) null)

		insert into #log (ret, err_msg)
	--	select -1,'Error 123'
		EXEC CVO_UPDATE_ORDER_INFO_SP @ORDER_NO, @ORDER_EXT, @FREIGHT_ALLOW_TYPE, @ATTENTION,
		 @PHONE, @CUST_PO, @USER_CATEGORY, @SO_PRIORITY_CODE, @ROUTING, @TERMS_CODE, @SOLD_TO,
		 @SCH_SHIP_DATE, @NOTE, @SPECIAL_INSTR
	end
		 
	update #log set id = @last_id, ret = case when ret = 0 then 1 end where id is null

	select @last_id = min(id) from cvo_interim_order_updates 
	where id > @last_id and isnull(proc_flag,0) = 0


end

update u set 
u.err_msg = #log.err_msg, u.proc_flag = #log.ret
from cvo_interim_order_updates u join #log on u.id = #log.id

-- finish up 
-- send email(s) for errors encountered in this batch
-- for all entries with proc_flag = -1 list the orders and the err_msg and compile into an email
-- select * from cvo_user_email

declare @user_email varchar(255), @userid varchar(50), @message nvarchar(600)

select @userid = min(userid) from cvo_interim_order_updates where proc_flag = -1

while @userid is not null
 begin
	 select @user_email = email_address from cvo_user_email where userid = @userid
	 set @message = 
	 'select order_no, order_ext, err_msg
	 from cvo.dbo.cvo_interim_order_updates where proc_flag = -1
	 and userid = '''+@userid+''''
	 
	 if isnull(@user_email,'')<>'' 
	 EXEC msdb.dbo.sp_send_dbmail @recipients=@user_email,
	 @subject = 'CVO Mass Sales Order Update - error notification',
	 @body = 'Mass Order updates encountered errors. View attachment to see the details.',
	 @query = @message,
	 @query_result_width = 600,
	 @profile_name='WMS_1',
	 @attach_query_result_as_file = 1
	 
	 if @@error = 0
	 update cvo_interim_order_updates set proc_flag = -2 -- email sent for error
		where proc_flag = -1 and userid = @userid

	 select @userid = min(userid) 
	 from cvo_interim_order_updates where proc_flag = -1

 end -- while @userid is not null
 
GO
GRANT EXECUTE ON  [dbo].[cvo_mass_order_update_sp] TO [public]
GO
