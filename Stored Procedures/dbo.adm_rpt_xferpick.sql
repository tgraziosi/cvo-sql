SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_rpt_xferpick] @process_ctrl_num varchar(32) as
begin

create table #temp (xfer_no int, status char(1))

exec ('insert #temp
select distinct xfer_no, status
from xfers_from x
where status between ''P'' and  ''S'' and pick_ctrl_num = ''' + @process_ctrl_num + '''')

exec ('
  SELECT  x.xfer_no ,
           x.from_loc ,
           x.to_loc ,
           x.date_shipped ,
           x.date_entered ,
           x.req_no ,
           x.attention ,
           x.phone ,
           x.routing ,
           x.special_instr ,
           x.freight ,
           x.to_loc_name ,
           x.to_loc_addr1 ,
           x.to_loc_addr2 ,
           x.to_loc_addr3 ,
           x.to_loc_addr4 ,
           x.to_loc_addr5 ,
           x.cust_code ,
           x.no_pallets ,
           x.sch_ship_date ,
           x.req_ship_date ,
           x.freight_type ,
           l.line_no ,
           l.lot_ser ,
           l.from_bin ,
           l.part_no ,
           l.description ,
           l.shipped ,
           l.uom ,
           l.comment ,
           l.ordered ,
           l.conv_factor ,
           lo.name ,
           lo.addr1 ,
           lo.addr2 ,
           lo.addr3 ,
           lo.addr4 ,
           lo.addr5 ,
           a.customer_name ,
           b.lot_ser ,
           b.uom_qty ,
           b.bin_no ,
           i.rpt_uom ,
           i.conv_factor ,
           x.status,
	   isnull(v.ship_via_name,x.routing),
	   isnull(f.description,x.freight_type),
	   isnull(a.extended_name, a.customer_name) -- extended_name
        FROM xfers_from x 
	join #temp t on t.xfer_no = x.xfer_no
	join xfer_list l on l.xfer_no = x.xfer_no
	left outer join locations_all lo on x.from_loc = lo.location
	left outer join adm_cust_all a on x.cust_code = a.customer_code
	left outer join lot_bin_xfer b on ( l.xfer_no = b.tran_no) and ( l.line_no = b.line_no) and
          ( l.part_no = b.part_no) and ( l.from_loc = b.location)
	left outer join arshipv v on v.ship_via_code = x.routing
	left outer join freight_type f on f.kys = x.freight_type
        left outer join inv_master i on i.part_no = l.part_no ')


  UPDATE dbo.xfers_from  
     SET status = case when status < 'Q' then 'Q' else status end, 
	    printed = 'Y', date_printed = getdate()		
   WHERE dbo.xfers_from.pick_ctrl_num = @process_ctrl_num  
  
end
GO
GRANT EXECUTE ON  [dbo].[adm_rpt_xferpick] TO [public]
GO
