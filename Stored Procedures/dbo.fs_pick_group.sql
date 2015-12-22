SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_pick_group] @load_no int, @user varchar(40)
as
BEGIN
declare @order_no int, @ext int, @prod_no int
declare @indirect int, @rc int, @err int

DECLARE @result int				

select @prod_no = last_no from next_prod_no

create table #Corders (order_no int, ext int)

begin tran
update o
set status = status
from orders_shipping_vw o
where (not exists (select 1 from load_master_all lm (nolock) 
  where lm.load_no = o.load_no and lm.status in ('H','C')) and
  o.load_no = @load_no and o.type = 'I' and o.printed <= o.status and status < 'Q')

insert #Corders
select order_no, ext
from orders_shipping_vw o
where (not exists (select 1 from load_master_all lm (nolock) 
  where lm.load_no = o.load_no and lm.status in ('H','C')) and
  o.load_no = @load_no and o.type = 'I' and o.printed <= o.status and status < 'Q')

update o
set printed = 'Q'
from orders_shipping_vw o, #Corders c
where o.order_no = c.order_no and o.ext = c.ext

commit tran

DECLARE Corders CURSOR LOCAL FOR
SELECT order_no, ext FROM #Corders

OPEN Corders
FETCH NEXT FROM Corders INTO @order_no, @ext

While @@FETCH_STATUS = 0
begin

  exec fs_pick_stock 'S', @order_no, @ext, @user

  update orders_shipping_vw
  set status = 'P', printed = 'P',
  freight = case when freight = 0 then tot_ord_freight else freight end -- mls 6/17/04 SCR 33041
  where order_no = @order_no and ext = @ext

  EXEC @result = fs_updordtots @order_no, @ext  		  

  FETCH NEXT FROM Corders INTO @order_no, @ext

end

close Corders
deallocate Corders

if (select last_no from next_prod_no) <> @prod_no and
  exists (select 1 from config (nolock) where flag = 'PSQL_GLPOST_MTH' and value_str != 'I')
begin
  select @indirect = indirect_flag from glco (nolock)
  exec @rc = adm_process_gl @user, @indirect, 'P',0,0,@err out
end

if exists (select 1 from orders_shipping_vw (nolock) where load_no = @load_no and status > 'N')
begin
  update load_master_all
  set status = 'P',
    picked_who_nm = @user, picked_dt = getdate()
  where load_no = @load_no and status = 'N'
end


END
GO
GRANT EXECUTE ON  [dbo].[fs_pick_group] TO [public]
GO
