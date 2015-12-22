SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_inv_hold] @pn varchar(30), @loc varchar(10) AS

set nocount on

create table #thold (
   part_no varchar(30) ,
   location varchar(10) ,
   tran_code char(2) ,
   tran_no int ,
   tran_ext int ,
   line_no int ,
   hold_qty decimal(20,8) ,
   qty decimal(20,8) ,
   qc_flag char(1)            )
create index thold1 on #thold(tran_code,tran_no,tran_ext)

insert #thold
select part_no,  location,  'C',
       order_no, order_ext, line_no,
       shipped*conv_factor,  shipped*conv_factor,   'N'
from   ord_list (nolock)
where  part_no = @pn and location = @loc and status between 'P' and 'R' and
       shipped > 0 and part_type in ('P','C')							-- mls 3/10/03 SCR 30817
       
insert #thold 
select part_no,  location,  'C',
       order_no, order_ext, line_no,
       shipped*conv_factor*qty_per,  shipped*conv_factor*qty_per,   'N'
from   ord_list_kit (nolock)
where  part_no = @pn and location = @loc and status between 'P' and 'R' and
       shipped > 0 and part_type in ('P','C')							-- mls 3/10/03 SCR 30817
       

insert #thold
select part_no,                location,               'CR',
       order_no,               order_ext,              line_no,
       (cr_shipped - shipped)*conv_factor, (shipped - cr_shipped)*conv_factor, 
       case when status = 'Q' then 'Y' else 'N' end						-- mls 3/10/03 SCR 30817
from   ord_list (nolock)
where  part_no = @pn and location = @loc and status between 'Q' and 'R' and
       (cr_shipped - shipped) > 0 and part_type in ('P','C')					-- mls 3/10/03 SCR 30817
       
insert #thold 
select part_no,                location,               'CR',
       order_no,               order_ext,              line_no,
       (cr_shipped - shipped)*conv_factor*qty_per, (shipped - cr_shipped)*conv_factor*qty_per, 
       case when status = 'Q' then 'Y' else 'N' end						-- mls 3/10/03 SCR 30817
from   ord_list_kit (nolock)
where  part_no = @pn and location = @loc and status between 'Q' and 'R' and
       (cr_shipped - shipped) > 0 and part_type in ('P','C')					-- mls 3/10/03 SCR 30817
       
insert #thold
select part_no,  from_loc, 'T',
       xfer_no,  0,        line_no,
       shipped*conv_factor,  shipped*conv_factor,  'N'
from   xfer_list (nolock)
where  part_no = @pn and from_loc = @loc and status between 'P' and 'Q' and
       shipped > 0
       
insert #thold
select part_no,  to_loc, 'X',
       xfer_no,  0,        line_no,
       shipped*conv_factor,  shipped*conv_factor,  'N'
from   xfer_list (nolock)
where  part_no = @pn and to_loc = @loc and status = 'R' and
       shipped > 0
       
insert #thold
select part_no,  location, 'U',
       prod_no,  prod_ext, line_no,
       used_qty*conv_factor, used_qty*conv_factor, 'N'
from   prod_list (nolock)
where  part_no = @pn and location = @loc and status between 'P' and 'Q' and			-- mls 11/13/03 SCR 32107
       used_qty != 0 and direction < 0 and constrain != 'C' and constrain != 'Y'
       
insert #thold
select prod_list.part_no,  prod_list.location, 'P',
       prod_list.prod_no,  prod_list.prod_ext, prod_list.line_no,
       (used_qty - scrap_pcs)*prod_list.conv_factor, (used_qty - scrap_pcs)*prod_list.conv_factor,
       case p.status when 'R' then 'Y' else 'N' end						-- mls 2/12/01 SCR 24958
from   prod_list (nolock), produce_all p (nolock)							-- mls 10/15/99
where  prod_list.prod_no = p.prod_no and								-- mls 10/15/99
       prod_list.prod_ext = p.prod_ext and							-- mls 10/15/99
       prod_list.part_no = @pn and prod_list.location = @loc and 
       (((prod_list.status between 'P' and 'Q') and p.prod_type != 'R') or 		-- mls 10/15/99
       prod_list.status='R') and
       (used_qty - scrap_pcs) != 0 and direction > 0 and constrain != 'C' and constrain != 'Y'
       
insert #thold
select part_no,    location,  'R',
       receipt_no, 0,         0,
       quantity*conv_factor,   quantity*conv_factor, 'Y'
from   receipts_all (nolock)
where  part_no = @pn and location = @loc and
       qc_flag = 'Y' and quantity <> 0

insert #thold
select part_no,    location_from,  'I',
       issue_no, 0,         0,
       qty * direction,   qty * direction, 'Y'
from   issues_all (nolock)
where  part_no = @pn and location_from = @loc and status = 'Q'
       
select    
   t.part_no   ,   t.location  ,   t.tran_code ,
   t.tran_no   ,   t.tran_ext  ,   t.line_no   ,
   t.hold_qty  ,   t.qty       ,   t.qc_flag
from #thold t
join inv_master i (nolock) on i.part_no = t.part_no and i.status != 'C' and i.status != 'V'
order by tran_code,tran_no,tran_ext

GO
GRANT EXECUTE ON  [dbo].[fs_inv_hold] TO [public]
GO
