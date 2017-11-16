SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 28/09/2017 - #1634 - Transfer Updates  

-- EXEC adm_rpt_xferform '1648'
-- EXEC adm_rpt_xferform '1648~1650'
  
CREATE PROC [dbo].[adm_rpt_xferform] @process_ctrl_num varchar(32) 
AS  
BEGIN  

	-- v1.0 Start
	DECLARE	@start_no	varchar(15),
			@end_no		varchar(15),
			@pos		int

	SET @start_no = ''
	SET @end_no = ''

	SET @pos = CHARINDEX('=',@process_ctrl_num)

	IF (@pos > 0)
	BEGIN
		SET @start_no = LEFT(@process_ctrl_num,(@pos -1))
		SET @end_no = RIGHT(@process_ctrl_num,(LEN(@process_ctrl_num) - @pos))
	END
	ELSE
	BEGIN
		SET @start_no = @process_ctrl_num
		SET @end_no = @process_ctrl_num
	END
	-- v1.0 End
 
	exec (' SELECT  xfers.xfer_no ,  
					xfers.from_loc ,  
					xfers.to_loc ,  
					xfers.req_ship_date ,  
					xfers.sch_ship_date ,  
					xfers.date_shipped ,  
					xfers.date_entered ,  
					xfers.req_no ,  
					xfers.who_entered ,  
					xfers.status ,  
					xfers.attention ,  
					xfers.phone ,  
					xfers.routing ,  
					xfers.special_instr ,  
					xfers.fob ,  
					xfers.freight ,  
					xfers.printed ,  
					xfers.label_no ,  
					xfers.no_cartons ,  
					xfers.who_shipped ,  
					xfers.date_printed ,  
					xfers.who_picked ,  
					xfers.to_loc_name ,  
					xfers.to_loc_addr1 ,  
					xfers.to_loc_addr2 ,  
					xfers.to_loc_addr3 ,  
					xfers.to_loc_addr4 ,  
					xfers.to_loc_addr5 ,  
					xfers.no_pallets ,  
					xfers.shipper_no ,  
					xfers.shipper_name ,  
					xfers.shipper_addr1 ,  
					xfers.shipper_addr2 ,  
					xfers.shipper_city ,  
					xfers.shipper_state ,  
					xfers.shipper_zip ,  
					xfers.cust_code ,  
					xfers.freight_type ,  
					xfers.note ,  
					xfers.rec_no ,  
					xfer_list.xfer_no ,  
					xfer_list.line_no ,  
					xfer_list.from_loc ,  
					xfer_list.to_loc ,  
					xfer_list.part_no ,  
					xfer_list.description ,  
					xfer_list.time_entered ,  
					xfer_list.ordered ,  
					xfer_list.shipped ,  
					xfer_list.comment ,  
					xfer_list.status ,  
					xfer_list.cost ,  
					xfer_list.com_flag ,  
					xfer_list.who_entered ,  
					xfer_list.temp_cost ,  
					xfer_list.uom ,  
					xfer_list.conv_factor ,  
					xfer_list.std_cost ,  
					xfer_list.from_bin ,  
					xfer_list.to_bin ,  
					xfer_list.lot_ser ,  
					xfer_list.date_expires ,  
					xfer_list.lb_tracking ,  
					xfer_list.labor ,  
					xfer_list.direct_dolrs ,  
					xfer_list.ovhd_dolrs ,  
					xfer_list.util_dolrs ,  
					xfer_list.display_line,  
					xfer_list.qty_rcvd,  
					xfer_list.reference_code,  
					xfer_list.adj_code,  
					xfer_list.amt_variance,  
					locations.location ,  
					locations.name ,  
					locations.addr1 ,  
					locations.addr2 ,  
					locations.addr3 ,  
					locations.addr4 ,  
					locations.phone ,  
					locations.addr5,  
					isnull(v.ship_via_name,xfers.routing),  
					isnull(f.description,xfers.freight_type),  
					isnull((select min(note_no) from notes n where n.code = convert(varchar(11),xfers.xfer_no)  
					and n.code_type = ''X'' and n.form = ''Y''),-1),  
					isnull(dbo.xfers.back_ord_flag,0) x_back_ord_flag,  
					isnull(dbo.xfer_list.back_ord_flag,0) l_back_ord_flag,  
					isnull((select bo.xfer_no from xfers bo where bo.orig_xfer_no =   
					xfers.orig_xfer_no and bo.orig_xfer_ext = (xfers.orig_xfer_ext + 1)),-1) bo_xfer_no  
			FROM	xfers   
			join	xfer_list on xfers.xfer_no = xfer_list.xfer_no  
			left outer join locations on xfers.from_loc = locations.location  
			left outer join arshipv v on v.ship_via_code = xfers.routing  
			left outer join dbo.freight_type f on f.kys = xfers.freight_type 
			where	xfers.xfer_no >= ' + @start_no + ' and xfers.xfer_no <= ' + @end_no )  
END
GO
GRANT EXECUTE ON  [dbo].[adm_rpt_xferform] TO [public]
GO
