SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create proc [dbo].[mls_find_out_of_syncs] @typ int = 11 as
create table #t1 (part_no varchar(30), location varchar(10),trx_type char(1), tran_no int, tran_ext int, line_no int, status char(1), iqty decimal(20,8), iqty2 decimal(20,8),lqty decimal(20,8))

create table #t2 (part_no varchar(30), location varchar(10), trx_type char(1), tran_no int, tran_ext int, line_no int, status char(1), iqty decimal(20,8), iqty2 decimal(20,8),lqty decimal(20,8))

create index #t2i on #t2(location,part_no)

create table #t3 (location varchar(10), part_no varchar(30), descr varchar(255),
begin_stock decimal(20,8), in_stock decimal(20,8), rec_sum decimal(20,8),
ship_sum decimal(20,8), sales_sum decimal(20,8), xfer_to decimal(20,8),
xfer_from decimal(20,8), iss_sum decimal(20,8), mfg_sum decimal(20,8), used_sum decimal(20,8))

declare @p varchar(30), @l varchar(10)
-- typ  =  1 - only update mls_lb_sync with list of out of syncs
-- typ  = 11 - get list of out of syncs and then get list of transactions in mls_lb_sync_info
-- typ  = 10 - get list of transactions in mls_lb_sync_info

if @typ in ( 1, 11)
begin
insert mls_lb_sync
select i.part_no, i.location,i.in_stock,0,
isnull((select sum(s.qty) from lot_bin_stock s (nolock) where s.part_no = i.part_no and s.location = i.location),0),
0,0,0,0,0,0,0,0
from inventory i where i.lb_tracking = 'y' /* part_no = @part and location = @loc */
and i.in_stock != 
isnull((select sum(s.qty) from lot_bin_stock s (nolock) where s.part_no = i.part_no and s.location = i.location),0)
order by i.location, i.part_no

if @typ = 1 return
end
if @typ in ( 10, 11)
begin
insert #t2
select s.part_no, s.location,'S',0,0,0,'',i.in_stock,0,
isnull((select sum(s.qty) from lot_bin_stock s (nolock) where s.part_no = i.part_no and s.location = i.location),0)
from inventory i, mls_lb_sync s 
where s.part_no = i.part_no and s.location = i.location and lb_tracking = 'y' /* part_no = @part and location = @loc */
and i.in_stock != 
isnull((select sum(s.qty) from lot_bin_stock s (nolock) where s.part_no = i.part_no and s.location = i.location),0)

truncate table mls_lb_sync
insert mls_lb_sync
select part_no, location,lqty,0,iqty,0,0,0,0,0,0,0,0
from #t2
order by location, part_no
if @typ = 10 return
end
drop table #t1
drop table #t2
drop table #t3

create table #t4 (part_no varchar(30), location varchar(10),trx_type char(1), tran_no int, tran_ext int, 
line_no int, status char(1), iqty decimal(20,8), iqty2 decimal(20,8),lqty decimal(20,8),
uom char(2) default('EA'), conv_factor decimal(20,8) default(1.0),serial_flag int,
priority int default(0))

declare @update char(1),@psize int, @lsize int, @prod int, @fixed int
    declare @uom varchar(2), @conv_fact decimal(20,8)
declare @part varchar(30), @loc varchar(10),@trx_type char(1),@tran_no int,@tran_ext int, @line int,
@iqty decimal(20,8), @iqty2 decimal(20,8), @lqty decimal(20,8),@stat char(1)
select @update = 'n'

insert #t4
select m.part_no, m.location, 'S',0,0,0,'',in_stock,0,lbqty,'EA',1,0,-1
from mls_lb_sync m (nolock)

insert #t4
select i.part_no, i.location,'1',0,0,0,'',i.in_stock,0,0,i.uom,1,serial_flag, 90
from inventory i,mls_lb_sync m (nolock) where i.part_no = m.part_no and i.location = m.location

insert #t4
select s.part_no,s.location,'1',0,0,0,'',0,0,sum(qty),i.uom,1,serial_flag, 90
from lot_bin_stock s (nolock)
left outer join inv_master i (nolock) on i.part_no = s.part_no
where exists (select * from mls_lb_sync m (nolock) where s.part_no = m.part_no and s.location = m.location)
group by s.part_no, s.location, i.uom,i.serial_flag

insert #t4
select i.part_no, i.location,'A',0,0,0,'',produced_ytd * -1,0,0,im.uom,1,serial_flag,99
from inv_produce i (nolock)
join  mls_lb_sync m (nolock) on i.part_no = m.part_no and i.location = m.location
left outer join inv_master im (nolock) on im.part_no = i.part_no

insert #t4
select i.part_no, i.location,'A',0,0,0,'',sum(used_qty - scrap_pcs),0,0,im.uom,1,serial_flag,99
from prod_list i (nolock)
join mls_lb_sync m on i.part_no = m.part_no and i.location = m.location 
left outer join inv_master im on im.part_no = i.part_no
where  i.direction = 1 and (used_qty - scrap_pcs) <> 0 and i.status < 'V'
group by i.part_no, i.location, im.uom,serial_flag

insert #t4
select i.part_no, i.location,'B',0,0,0,'',usage_mtd * -1,0,0,im.uom,1,serial_flag,99
from inv_produce i (nolock)
join mls_lb_sync m (nolock) on i.part_no = m.part_no and i.location = m.location
left outer join inv_master im  (nolock) on im.part_no = i.part_no

insert #t4
select i.part_no, i.location,'B',0,0,0,'',sum(used_qty * i.conv_factor),0,0,im.uom,1,serial_flag,99
from prod_list i (nolock)
join mls_lb_sync m on i.part_no = m.part_no and i.location = m.location 
left outer join inv_master im (nolock) on im.part_no = i.part_no
where i.direction = -1 and (used_qty) <> 0 and i.status < 'V'
group by i.part_no, i.location, im.uom,serial_flag

insert #t4
select i.part_no, i.location,'T',0,0,0,'',sales_qty_ytd * -1,0,0,im.uom,1,serial_flag,99
from inv_sales i  (nolock) 
left outer join inv_master im (nolock) on im.part_no = i.part_no
where exists (select * from mls_lb_sync m (nolock) where i.part_no = m.part_no and i.location = m.location)

insert #t4
select o.part_no, o.location, 'T',0,0,0,'',sum(o.conv_factor * (shipped - cr_shipped)),0,0,im.uom,1,serial_flag,99
from ord_list o (nolock)
join mls_lb_sync m on o.part_no = m.part_no and o.location = m.location
left outer join inv_master im (nolock)on im.part_no = o.part_no
where o.status < 'V' and (shipped - cr_shipped) <> 0 and o.status <> 'M'
and o.part_type in ('P','C')
group by o.part_no, o.location, im.uom,serial_flag

insert #t4
select o.part_no, o.location, 'T',0,0,0,'',sum(qty_per * o.conv_factor * (shipped - cr_shipped)),0,0,im.uom,1,serial_flag,99
from ord_list_kit o (nolock)
join mls_lb_sync m on o.part_no = m.part_no and o.location = m.location
left outer join inv_master im (nolock) on im.part_no = o.part_no
where o.status < 'V' and (shipped - cr_shipped) <> 0 and o.status <> 'M'
and o.part_type = 'P'
group by o.part_no, o.location, im.uom,serial_flag

insert #t4
select i.part_no, i.location_from,'I',issue_no,0,0,i.status,qty*direction,0,0,im.uom,1,im.serial_flag,0
from issues i (nolock)
join mls_lb_sync m on i.part_no = m.part_no and i.location_from = m.location
left outer join inv_master im (nolock) on im.part_no = i.part_no
where (qty) <> 0 
and i.lb_tracking = 'y'

if exists (select 1 from sysobjects where name = 'lot_serial_bin_issue')
begin
insert #t4
select r.part_no, r.location, 'I',tran_no,0,0,'',0,0,qty*direction,im.uom,1,serial_flag,0
from lot_serial_bin_issue r (nolock)
join mls_lb_sync m on r.part_no = m.part_no and r.location = m.location
left outer join inv_master im (nolock) on im.part_no = r.part_no
end
else
begin
insert #t4
select i.part_no, i.location_from,'I',issue_no,0,0,i.status,0,0,qty*direction,im.uom,1,im.serial_flag,0
from issues i (nolock)
join mls_lb_sync m on i.part_no = m.part_no and i.location_from = m.location 
left outer join inv_master im (nolock) on im.part_no = i.part_no
where (qty) <> 0 
and i.lb_tracking = 'y'
end

insert #t4
select r.part_no, r.location, 'R',receipt_no,0,0,r.status,r.conv_factor * quantity,0,0,im.uom,1,serial_flag,0
from receipts r (nolock)
join mls_lb_sync m on r.part_no = m.part_no and r.location = m.location
left outer join inv_master im (nolock) on im.part_no = r.part_no
where r.status != 'V' and r.lb_tracking = 'y'

insert #t4
select r.part_no, r.location, 'R',tran_no,0,0,'',0,0,qty,im.uom,1,serial_flag,0
from lot_bin_recv r (nolock)
join mls_lb_sync m on r.part_no = m.part_no and r.location = m.location
left outer join inv_master im (nolock) on im.part_no = r.part_no

insert #t4
select o.part_no, o.location, 'O' ,order_no, order_ext, line_no, o.status, o.conv_factor * (shipped - cr_shipped), 0,0,
i.uom,1,serial_flag,0
from ord_list o (nolock)
join mls_lb_sync m on o.part_no = m.part_no and o.location = m.location
left outer join inv_master i (nolock) on i.part_no = o.part_no
where  o.status < 'V' and (shipped - cr_shipped) <> 0 and o.status not in ('M')
and o.lb_tracking = 'y'
and o.part_type in ('P','C')

insert #t4
select o.part_no,o.location, 'O', order_no, order_ext, line_no, o.status, 0,o.conv_factor * qty_per * (shipped - cr_shipped), 0,
i.uom,1,serial_flag,0
from ord_list_kit o (nolock)
join mls_lb_sync m on o.part_no = m.part_no and o.location = m.location 
left outer join inv_master i (nolock) on i.part_no = o.part_no
where o.status < 'V' and (shipped - cr_shipped) != 0 and o.status not in ('M')
and o.lb_tracking = 'y'
and o.part_type = 'P'

insert #t4
select o.part_no,o.location, 'O' ,tran_no, tran_ext, line_no, '', 0,0, (qty * direction) * -1,
i.uom,1,serial_flag,0
from lot_bin_ship o (nolock)
join mls_lb_sync m on o.part_no = m.part_no and o.location = m.location 
left outer join inv_master i (nolock) on i.part_no = o.part_no

insert #t4
select o.part_no, o.from_loc, 'X', xfer_no, 0, line_no, o.status, (o.conv_factor * shipped * -1) ,0,0,i.uom,1,serial_flag,0
from xfer_list o (nolock)
join  mls_lb_sync m on o.part_no = m.part_no and o.from_loc = m.location
left outer join inv_master i (nolock) on i.part_no = o.part_no
where o.status < 'V' and o.lb_tracking = 'y'

insert #t4
select o.part_no, o.to_loc, 'Y', xfer_no, 0, line_no, o.status, (o.conv_factor * shipped * 1) ,0,0,i.uom,1,serial_flag,0
from xfer_list o (nolock)
join mls_lb_sync m on o.part_no = m.part_no and o.to_loc = m.location
left outer join inv_master i (nolock) on i.part_no = o.part_no
where o.status < 'V' and o.lb_tracking = 'y'

insert #t4
select o.part_no,x.to_loc,  'Y', tran_no, tran_ext, o.line_no, '', 0,0,sum(qty * direction * -1),i.uom,1,serial_flag,0
from lot_bin_xfer o (nolock)
join xfer_list x (nolock) on o.tran_no = x.xfer_no and o.line_no = x.line_no 
join mls_lb_sync m on o.part_no = m.part_no and x.to_loc = m.location
left outer join inv_master i (nolock) on i.part_no = o.part_no
group by o.part_no, x.to_loc, tran_no, tran_ext, o.line_no,i.uom,i.serial_flag

insert #t4
select o.part_no,o.location,  'X', tran_no, tran_ext, o.line_no, '', 0,0,sum(qty * direction),i.uom,1,serial_flag,0
from lot_bin_xfer o (nolock)
join mls_lb_sync m on o.part_no = m.part_no and o.location = m.location 
left outer join inv_master i (nolock) on i.part_no = o.part_no
group by o.part_no, o.location, tran_no, tran_ext, o.line_no,i.uom,i.serial_flag

insert #t4
select o.part_no, o.location, 'P', prod_no, prod_ext, line_no, o.status, 
case when direction = 1 then (o.conv_factor * used_qty * direction) else (o.conv_factor * used_qty  * direction) end ,
case when direction = 1 then (o.conv_factor * scrap_pcs * direction * -1) else (o.conv_factor * scrap_pcs  * direction * -1) end,0,i.uom,1,i.serial_flag,0
from prod_list o (nolock)
join mls_lb_sync m on o.part_no = m.part_no and o.location = m.location 
left outer join inv_master i (nolock) on i.part_no = o.part_no
where o.status < 'V' 
and o.lb_tracking = 'y'

insert #t4
select o.part_no,o.location,  'P', tran_no, tran_ext, line_no, '', 0,0,sum(qty * direction),i.uom,1, i.serial_flag,0
from lot_bin_prod o (nolock)
join  mls_lb_sync m on o.part_no = m.part_no and o.location = m.location 
left outer join inv_master i (nolock) on i.part_no = o.part_no
group by o.part_no, o.location, tran_no, tran_ext, line_no,i.uom,i.serial_flag

insert mls_lb_sync_info
(part_no,location,trx_type,tran_no,tran_ext,line_no,status,iqty,iqty2,lqty,uom,conv_factor,serial_flag,priority)
select part_no,location,trx_type, tran_no, tran_ext, line_no, max(status), sum(iqty), sum(iqty2), sum(lqty),uom,conv_factor,
serial_flag, max(priority)
from #t4
group by part_no,location,trx_type, tran_no, tran_ext, line_no, uom,conv_factor,serial_flag
having sum(iqty) + sum(iqty2) <> sum(lqty)
order by location,part_no,max(priority),trx_type,tran_no desc,tran_ext desc,line_no desc
drop table #t4
GO
