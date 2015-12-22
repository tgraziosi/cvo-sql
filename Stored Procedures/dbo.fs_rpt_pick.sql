SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_rpt_pick] @i_no int, @i_ext int, @pcppf int AS 
BEGIN

-- mls 4/21/00 SCR 22718 - rewrote procedure to improve performance

 declare @x int, @y int, @backflag char(1)

 CREATE TABLE #tpick (
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
 x_display_line int
)
 CREATE TABLE #tkit (
 k_line_no int, 
 k_part_no varchar(30), 
 k_description varchar(255) NULL, 
 k_uom char(2) NULL, 
 k_qty decimal(20,8))

 
 INSERT #tpick (

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
 x_display_line )
 SELECT 
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
 ord_list.part_type, ord_list.display_line
 FROM ord_list
 left outer join inv_master (nolock) on ( ord_list.part_no = inv_master.part_no ) 
 left outer join lot_bin_ship (nolock) on ( ord_list.part_no = lot_bin_ship.part_no) and 
 ( ord_list.location = lot_bin_ship.location) and 
 ( ord_list.line_no = lot_bin_ship.line_no) and 
 ( ord_list.order_no = lot_bin_ship.tran_no) and 
 ( ord_list.order_ext = lot_bin_ship.tran_ext) 
 WHERE ( ord_list.order_no = @i_no ) AND 
 ( ord_list.order_ext = @i_ext ) AND 
 ord_list.status between 'N' AND 'R' 
ORDER BY ord_list.location ASC, 
 ord_list.line_no ASC 

 UPDATE #tpick SET i_bin_no = inventory.bin_no,
 i_in_stock = inventory.in_stock,
 i_commit_ed = inventory.commit_ed
 FROM inventory (nolock)
 WHERE part_no = #tpick.x_part_no and
 location = #tpick.x_location and (x_type in ('P','C'))

 INSERT #tkit (
 k_line_no , k_part_no , 
 k_description , k_uom , 
 k_qty ) 
 SELECT x_line_no , w.part_no ,
 i.description , i.uom ,
 w.qty
 FROM #tpick, what_part w (nolock), inv_master i (nolock)
 WHERE 
 #tpick.x_part_no = w.asm_no and  w.part_no = i.part_no and
 #tpick.i_status = 'K' and i.status <> 'R' and                                           -- rduke 10/16/00 SCR 22552
 w.active <= 'B' and w.fixed = 'Y' and 
 ( w.location = #tpick.x_location OR w.location = 'ALL' )

 INSERT #tkit (
 k_line_no , k_part_no , 
 k_description , k_uom , 
 k_qty ) 
 SELECT x_line_no , w.part_no ,
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
 k_line_no , k_part_no , 
 k_description , k_uom , 
 k_qty ) 
 SELECT x_line_no , k.part_no ,
 i.description , i.uom ,
 (k.qty_per * 
  case when k.shipped = 0 then k.ordered else k.shipped end * k.conv_factor)		-- mls 6/19/00 SCR 23014
											-- mls 8/25/00 SCR 23938
 FROM #tpick, ord_list_kit k, inv_master i
 WHERE k.order_no = @i_no and k.order_ext = @i_ext and 	
 #tpick.x_line_no = k.line_no and k.part_no=i.part_no

 INSERT #tpick (
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
 x_display_line )
 SELECT 
 k_line_no ,										-- rduke 10/16/00 SCR 22552
 k_part_no , x_location ,								-- rduke 10/16/00 SCR 22552
 k_uom , x_ordered ,									-- rduke 10/16/00 SCR 22552
 x_shipped , x_conv_factor , x_price ,
 x_lb_tracking , x_printed ,
 i_bin_no , i_uom ,
 i_in_stock , i_commit_ed ,
 'Z' , l_lot_ser ,									-- rduke 10/16/00 SCR 22552								
 l_bin_no , l_qty ,
 k_qty , c_printed ,
 x_note ,
 x_description , i_description ,
 k_uom+' '+convert(varchar(30),k_part_no)+' '+ substring(k_description,1,100) ,         -- rduke 10/16/00 SCR 22552
 'N', 'P',
 #tpick.x_display_line
 FROM #tpick, #tkit
 WHERE #tpick.x_line_no = #tkit.k_line_no 

 SELECT o.order_no , o.ext ,
 o.status , o.cust_code ,
 o.date_entered , o.req_ship_date ,
 o.sch_ship_date , o.ship_to_name ,
 o.ship_to_add_1 , o.ship_to_add_2 ,
 o.ship_to_add_3 , o.ship_to_add_4 ,

 o.ship_to_add_5 ,	 o.ship_to_country ,
 o.phone , o.freight ,
 o.cust_po , o.terms ,
 o.routing , o.fob ,
 o.salesperson , a.customer_name ,
 a.addr1 , a.addr2 ,
 a.addr3 , a.addr4 ,
 a.addr5 , a.country ,
 o.attention , o.phone ,		-- mls 10/3/01 SCR 27641
					-- mcruz SCR24724 needed for Picking Slip
 x_display_line ,
 x_part_no , x_location ,
 x_uom , x_ordered ,
 x_shipped , x_price ,
 x_lb_tracking , x_printed ,
 i_bin_no , i_uom ,
 i_in_stock , i_commit_ed ,
 i_status , l_lot_ser ,
 l_bin_no , l_qty ,
 l_uom_qty , c_printed ,
 o.special_instr , x_note ,
 x_description , i_description ,
 case when x_lb_tracking = 'Y' then x_uom+'  Bin: '+convert(char(12),l_bin_no)+'  Lot: '+l_lot_ser
 else k_msg end , x_type ,
 isnull(o.back_ord_flag,'0'),							-- skk 05/25/00 mshipto
 isnull(o.load_no,0),							-- mls 12/6/01
 @pcppf pcppf,
case when isnull(a.check_extendedname_flag,0) = 1 then a.extended_name else a.customer_name end -- extended_name
 FROM #tpick , orders_all o (nolock), adm_cust_all a (nolock)
where o.order_no = @i_no and o.ext = @i_ext and o.cust_code = a.customer_code 
ORDER BY x_location, x_display_line,x_line_no, i_status, l_bin_no, l_uom_qty
END

GO
GRANT EXECUTE ON  [dbo].[fs_rpt_pick] TO [public]
GO
