SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_rpt_xferpack] @process_ctrl_num varchar(32) as
begin

exec ('  SELECT  dbo.xfers_from.xfer_no ,
           dbo.xfers_from.from_loc ,
           dbo.xfers_from.to_loc ,
           dbo.xfers_from.req_ship_date ,
           dbo.xfers_from.sch_ship_date ,
           dbo.xfers_from.date_shipped ,
           dbo.xfers_from.date_entered ,
           dbo.xfers_from.req_no ,
           dbo.xfers_from.who_entered ,
           dbo.xfers_from.status ,
           dbo.xfers_from.attention ,
           dbo.xfers_from.phone ,
           dbo.xfers_from.routing ,
           dbo.xfers_from.special_instr ,
           dbo.xfers_from.fob ,
           dbo.xfers_from.freight ,
           dbo.xfers_from.printed ,
           dbo.xfers_from.label_no ,
           dbo.xfers_from.no_cartons ,
           dbo.xfers_from.who_shipped ,
           dbo.xfers_from.date_printed ,
           dbo.xfers_from.who_picked ,
           dbo.xfers_from.to_loc_name ,
           dbo.xfers_from.to_loc_addr1 ,
           dbo.xfers_from.to_loc_addr2 ,
           dbo.xfers_from.to_loc_addr3 ,
           dbo.xfers_from.to_loc_addr4 ,
           dbo.xfers_from.to_loc_addr5 ,
           dbo.xfers_from.no_pallets ,
           dbo.xfers_from.shipper_no ,
           dbo.xfers_from.shipper_name ,
           dbo.xfers_from.shipper_addr1 ,
           dbo.xfers_from.shipper_addr2 ,
           dbo.xfers_from.shipper_city ,
           dbo.xfers_from.shipper_state ,
           dbo.xfers_from.shipper_zip ,
           dbo.xfers_from.cust_code ,
           dbo.xfers_from.freight_type ,
           dbo.xfers_from.note ,
           dbo.xfers_from.rec_no ,
           dbo.xfer_list.line_no ,
           dbo.xfer_list.part_no ,
           dbo.xfer_list.description ,
           dbo.xfer_list.ordered ,
           dbo.xfer_list.shipped ,
           dbo.xfer_list.comment ,
           dbo.xfer_list.uom ,
           dbo.xfer_list.conv_factor ,
           dbo.locations_all.name ,
           dbo.locations_all.addr1 ,
           dbo.locations_all.addr2 ,
           dbo.locations_all.addr3 ,
           dbo.locations_all.addr4 ,
           dbo.locations_all.addr5 ,
           dbo.inv_master.rpt_uom ,
           dbo.inv_master.conv_factor,
	   isnull(v.ship_via_name,xfers_from.routing),
		   isnull(dbo.xfers_from.back_ord_flag,0) x_back_ord_flag,
		isnull(dbo.xfer_list.back_ord_flag,0) l_back_ord_flag,
		isnull((select bo.xfer_no from xfers_from bo where bo.orig_xfer_no = 
		 xfers_from.orig_xfer_no and bo.orig_xfer_ext = (xfers_from.orig_xfer_ext + 1)),-1) bo_xfer_no
        FROM dbo.xfers_from
        join dbo.xfer_list (nolock) on ( dbo.xfers_from.xfer_no = dbo.xfer_list.xfer_no )
        left outer join dbo.locations_all (nolock) on ( dbo.xfers_from.from_loc = dbo.locations_all.location)
        join dbo.inv_master (nolock) on ( dbo.xfer_list.part_no = dbo.inv_master.part_no )
        left outer join arshipv v (nolock) on ( v.ship_via_code = xfers_from.routing )
        WHERE xfers_from.xfer_no = ' + @process_ctrl_num)
end
GO
GRANT EXECUTE ON  [dbo].[adm_rpt_xferpack] TO [public]
GO
