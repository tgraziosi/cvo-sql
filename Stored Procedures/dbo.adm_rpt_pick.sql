SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[adm_rpt_pick] @process_ctrl_num varchar(32)
as
BEGIN
 declare @max_stat char(1), @order int

 select @order = 0

 create table #torder (
 h_order_no int,
 h_ext int,
 h_status char(1),
 h_location varchar(10) null,
 h_last_picked_dt datetime
 )
 create index #to1 on #torder(h_order_no, h_ext)


 declare @x int, @y int, @backflag char(1)

 CREATE TABLE #tpick (
 x_status char(1),
 x_order_no int,
 x_order_ext int,
 x_line_no int, 
 x_part_no varchar(30), 
 x_location varchar(10), 
 x_uom char(2), 
 x_ordered decimal(20,8), 
 x_shipped decimal(20,8),
 x_conv_factor decimal(20,8), 
 x_price decimal(20,8), 
 x_lb_tracking char(1), 
 x_printed char(1), 
 i_bin_no varchar(12) NULL, 
 i_uom char(2) NULL, 
 i_in_stock decimal(20,8), 
 i_commit_ed decimal(20,8), 
 i_status char(1) NULL,
 l_lot_ser varchar(25) NULL, 
 l_bin_no varchar(12) NULL, 
 l_qty decimal(20,8) NULL, 
 l_uom_qty decimal(20,8) NULL, 
 c_printed char(1), 
 x_note varchar(255) NULL, 
 x_description varchar(100) NULL, 
 i_description varchar(100) NULL ,

 k_msg varchar(200) NULL ,
 k_flag char(1) NULL ,
 x_type char(1) NULL , 
 x_display_line int NULL,
 o_masked_phone varchar(100) NULL,
 x_organization_id varchar(30)
)

create index #tp3 on #tpick(x_order_no,x_order_ext,x_line_no)
create index #tp1 on #tpick(x_type)
create index #tp2 on #tpick(i_status, x_part_no, x_location)

 CREATE TABLE #tkit (
 k_order_no int,
 k_order_ext int,
 k_line_no int, 
 k_part_no varchar(30), 
 k_description varchar(255) NULL, 
 k_uom char(2) NULL, 
 k_qty decimal(20,8))

create index #tk1 on #tkit (k_order_no, k_order_ext, k_line_no)

  insert #torder 
  (h_order_no, h_ext, h_status, h_location, h_last_picked_dt)
  select o.order_no, o.ext, o.status, o.location, o.last_picked_dt
  from orders_all o
  where o.sopick_ctrl_num = @process_ctrl_num

 INSERT #tpick (
 x_status,
 x_order_no,
 x_order_ext,

 x_line_no ,
 x_part_no , x_location ,
 x_uom , x_ordered ,
 x_shipped , x_conv_factor , x_price ,
 x_lb_tracking , x_printed ,
 i_bin_no , i_uom ,
 i_in_stock , i_commit_ed ,
 i_status , l_lot_ser ,
 l_bin_no , l_qty ,
 l_uom_qty , c_printed ,

 x_note ,
 x_description , i_description ,
 k_msg , k_flag ,
 x_type,
 x_display_line,
 x_organization_id)
 SELECT 
 t.h_status,
 ord_list.order_no,
 ord_list.order_ext,
 ord_list.line_no ,
 ord_list.part_no ,ord_list.location ,
 ord_list.uom ,ord_list.ordered ,
 ord_list.shipped ,ord_list.conv_factor ,ord_list.price ,
 case when ord_list.part_type = 'C' then 'N' else ord_list.lb_tracking end ,
 ord_list.printed ,
 '' ,inv_master.uom ,
 0 ,0 ,
 isnull(inv_master.status,'Z') ,lot_bin_ship.lot_ser ,
 lot_bin_ship.bin_no ,lot_bin_ship.qty ,
 lot_bin_ship.uom_qty ,ord_list.printed ,
 ord_list.note ,
 substring(ord_list.description,1,100) ,
 substring(inv_master.description,1,100) ,
 NULL ,isnull(inv_master.status,'Z') ,
 ord_list.part_type, ord_list.display_line,
 ord_list.organization_id
 FROM ord_list
 left outer join inv_master (nolock) on ( ord_list.part_no = inv_master.part_no ) 
 left outer join lot_bin_ship (nolock) on ( ord_list.part_no = lot_bin_ship.part_no) and 
 ( ord_list.location = lot_bin_ship.location) and 
 ( ord_list.line_no = lot_bin_ship.line_no) and 
 ( ord_list.order_no = lot_bin_ship.tran_no) and 
 ( ord_list.order_ext = lot_bin_ship.tran_ext) 
 join #torder t (nolock) on (ord_list.order_no = t.h_order_no) and
   (ord_list.order_ext = t.h_ext) and ( ord_list.picked_dt = t.h_last_picked_dt )
 WHERE ord_list.status between 'P' AND 'R' 
ORDER BY ord_list.location ASC, 
 ord_list.line_no ASC 

 UPDATE #tpick SET i_bin_no = inventory.bin_no,
 i_in_stock = inventory.in_stock,
 i_commit_ed = inventory.commit_ed
 FROM inventory (nolock)
 WHERE part_no = #tpick.x_part_no and
 location = #tpick.x_location and (x_type in ('P','C'))

 INSERT #tkit (
 k_order_no, k_order_ext,
 k_line_no , k_part_no , 
 k_description , k_uom , 
 k_qty ) 
 SELECT x_order_no, x_order_ext, x_line_no , w.part_no ,
 i.description , i.uom ,
 w.qty
 FROM #tpick, what_part w (nolock), inv_master i (nolock)
 WHERE 
 #tpick.x_part_no = w.asm_no and  w.part_no = i.part_no and
 #tpick.i_status = 'K' and i.status <> 'R' and                                           -- rduke 10/16/00 SCR 22552
 w.active <= 'B' and w.fixed = 'Y' and 
 ( w.location = #tpick.x_location OR w.location = 'ALL' )

 INSERT #tkit (
 k_order_no, k_order_ext,
 k_line_no , k_part_no , 
 k_description , k_uom , 
 k_qty ) 
 SELECT 
 x_order_no, x_order_ext,
 x_line_no , w.part_no ,
 i.description , i.uom ,
 ( w.qty * 
  case when x_shipped = 0 then x_ordered else x_shipped end * x_conv_factor )		-- mls 6/19/00 SCR 23014
											-- mls 8/25/00 SCR 23938
 FROM #tpick, what_part w, inv_master i
 WHERE 
 #tpick.x_part_no = w.asm_no and  w.part_no = i.part_no and
 #tpick.i_status = 'K' and i.status <> 'R' and                                          -- rduke 10/16/00 SCR 22552
 w.active <= 'B' and w.fixed <> 'Y' and 
	 ( w.location = #tpick.x_location OR w.location = 'ALL' )

 INSERT #tkit (
 k_order_no, k_order_ext,
 k_line_no , k_part_no , 
 k_description , k_uom , 
 k_qty ) 
 SELECT 
 x_order_no, x_order_ext,
 x_line_no , k.part_no ,
 i.description , i.uom ,
 (k.qty_per * 
  case when k.shipped = 0 then k.ordered else k.shipped end * k.conv_factor)		-- mls 6/19/00 SCR 23014
											-- mls 8/25/00 SCR 23938
 FROM #tpick, ord_list_kit k, inv_master i
 WHERE k.order_no = #tpick.x_order_no and k.order_ext = #tpick.x_order_ext and 	
 #tpick.x_line_no = k.line_no and k.part_no=i.part_no

 INSERT #tpick (
 x_status,
 x_order_no,
 x_order_ext,
 x_line_no ,
 x_part_no , x_location ,
 x_uom , x_ordered ,
 x_shipped , x_conv_factor , x_price ,
 x_lb_tracking , x_printed ,
 i_bin_no , i_uom ,
 i_in_stock , i_commit_ed ,
 i_status , l_lot_ser ,
 l_bin_no , l_qty ,
 l_uom_qty , c_printed ,
 x_note ,
 x_description , i_description ,
 k_msg , k_flag ,
 x_type,
 x_display_line,
 x_organization_id)
 SELECT 
 x_status,
 k_order_no,
 k_order_ext,
 k_line_no ,										-- rduke 10/16/00 SCR 22552
 x_part_no , x_location ,								-- mls 5/25/05 SCR 34804
 k_uom , x_ordered ,									-- rduke 10/16/00 SCR 22552
 x_shipped , x_conv_factor , x_price ,
 x_lb_tracking , x_printed ,
 i_bin_no , i_uom ,
 i_in_stock , i_commit_ed ,
 i_status , l_lot_ser ,									-- mls 5/25/05 SCR 34804
 l_bin_no , l_qty ,
 k_qty , c_printed ,
 x_note ,
 x_description , i_description ,
 k_uom+' '+convert(varchar(30),k_part_no)+' '+ substring(k_description,1,100) ,         -- rduke 10/16/00 SCR 22552
 'N', 'P',
 #tpick.x_display_line,
 #tpick.x_organization_id
 FROM #tpick, #tkit
 WHERE #tpick.x_line_no = #tkit.k_line_no 
  and #tpick.x_order_no = #tkit.k_order_no and #tpick.x_order_ext = #tkit.k_order_ext


declare @mask varchar(100), @phone varchar(50), @orig_mask varchar(100)
declare @pos int, @x_order_no int, @x_order_ext int
select @orig_mask = isnull((select mask from masktbl (nolock)
  where lower(mask_name) = 'phone number mask'),'(###) ###-#### Ext. ####')


DECLARE pickcursor CURSOR LOCAL FOR
SELECT distinct x_order_no, x_order_ext
from #tpick
OPEN pickcursor
FETCH NEXT FROM pickcursor INTO @x_order_no, @x_order_ext

While @@FETCH_STATUS = 0
begin
select @phone = isnull((select isnull(phone,'')
from orders_all where order_no = @x_order_no and ext = @x_order_ext),'')
if @phone != ''
begin
  select @mask = @orig_mask
  select @mask = replace(@mask,'!','#')
  select @mask = replace(@mask,'@','#')
  select @mask = replace(@mask,'?','#')

  while @phone != ''
  begin
    select @pos = charindex('#',@mask)

    if @pos > 0
      select @mask = stuff(@mask,@pos,1,substring(@phone,1,1))
    else
      select @mask = @mask + substring(@phone,1,1)

    select @phone = ltrim(substring(@phone,2,100))
  end
end
if @pos > 0
  select @mask = substring(@mask,1,@pos)

update #tpick
set o_masked_phone = @mask
where x_order_no = @x_order_no and x_order_ext = @x_order_ext
FETCH NEXT FROM pickcursor INTO @x_order_no, @x_order_ext
end

close pickcursor
deallocate pickcursor


 SELECT 'D', o.order_no , o.ext ,
 x_status , o.cust_code ,
 o.date_entered , o.req_ship_date ,
 o.sch_ship_date , o.ship_to_name ,
 o.ship_to_add_1 , o.ship_to_add_2 ,
 o.ship_to_add_3 , o.ship_to_add_4 ,

 o.ship_to_add_5 ,  o.ship_to_city, o.ship_to_state, o.ship_to_zip, o.ship_to_country ,
 o.ship_to_region, isnull(o.phone,'') , o.freight ,
 o.cust_po , o.terms ,
 o.routing , o.fob ,
 o.salesperson , a.customer_name ,
 a.addr1 , a.addr2 ,
 a.addr3 , a.addr4 ,
 a.addr5 , a.addr6, a.country ,
 a.city, a.state, a.postal_code, a.contact_name, a.inv_comment_code,
 o.attention , 
 x_display_line ,
 x_part_no , x_location ,
 x_uom , x_ordered ,
 x_shipped , x_price ,
 x_lb_tracking , x_printed ,
 i_bin_no , i_uom ,
 i_in_stock , i_commit_ed ,
 i_status , isnull(l_lot_ser,'') ,
 l_bin_no , l_qty ,
 l_uom_qty , 
 o.special_instr , x_note ,
 x_description , i_description ,
 isnull(case when x_lb_tracking = 'Y' then x_uom+'  Bin: '+convert(char(12),l_bin_no)+'  Lot: '+l_lot_ser
 else k_msg end, '') , x_type ,
 isnull(o.back_ord_flag,'0'),							-- skk 05/25/00 mshipto
 isnull(o.load_no,0),		
 x_line_no,

datalength(rtrim(replace(cast(x_ordered  as varchar(40)),'0',' '))) - 
charindex('.',cast(x_ordered  as varchar(40))),	-- ordered qty precision
datalength(rtrim(replace(cast(x_shipped  as varchar(40)),'0',' '))) - 
charindex('.',cast(x_shipped  as varchar(40))),	-- shipped qty precision
datalength(rtrim(replace(cast(x_price as varchar(40)),'0',' '))) - 
charindex('.',cast(x_price as varchar(40))),		-- price precision
datalength(rtrim(replace(cast(x_ordered  as varchar(40)),'0',' '))) - 
charindex('.',cast(x_ordered  as varchar(40))), -- lot qty precision

isnull(v.ship_via_name,o.routing),
replicate (' ',11 - datalength(convert(varchar(11),o.order_no))) + convert(varchar(11),o.order_no) + '.' +
replicate (' ',5 - datalength(convert(varchar(5),o.ext))) + convert(varchar(5),o.ext),
o_masked_phone,  -- o_masked_phone


'.',
',',
case when @order = 0 -- order by order_no
then replicate (' ',11 - datalength(convert(varchar(11),o.order_no))) + convert(varchar(11),o.order_no) + '.' +
replicate (' ',5 - datalength(convert(varchar(5),o.ext))) + convert(varchar(5),o.ext)
else x_location end,
case when @order = 0 -- order by order_no
then x_location
else replicate (' ',11 - datalength(convert(varchar(11),o.order_no))) + convert(varchar(11),o.order_no) + '.' +
replicate (' ',5 - datalength(convert(varchar(5),o.ext))) + convert(varchar(5),o.ext) end,
0,
@order,
isnull((select min(n.note_no) from notes n (nolock) where n.code_type = 'O' and n.code = o.order_no and n.pick = 'Y'),-1),
o.who_entered,
#tpick.x_organization_id,
isnull(a.extended_name, a.customer_name) -- extended_name
 FROM #tpick 
join orders_all o (nolock) on o.order_no = #tpick.x_order_no and o.ext = #tpick.x_order_ext
join adm_cust_all a (nolock) on o.cust_code = a.customer_code 
left outer join arshipv v (nolock) on v.ship_via_code = o.routing
--ORDER BY x_order_no, x_order_ext, x_location, x_display_line,x_line_no, i_status, l_bin_no, l_uom_qty
END


GO
GRANT EXECUTE ON  [dbo].[adm_rpt_pick] TO [public]
GO
