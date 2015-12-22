SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create view [dbo].[adtxl_vw] as

select 
	xfer_no ,
	line_no ,
	from_loc ,
	to_loc , 
	part_no , 
	description ,
	uom , 
	ordered , 
	shipped ,
	from_bin ,
	to_bin , 
	status ,
	status_desc = 
		CASE status
			WHEN 'O' THEN 'Open'
			WHEN 'N' THEN 'New'
			WHEN 'P' THEN 'Open/Picked'
			WHEN 'Q' THEN 'Open/Printed'
			WHEN 'R' THEN 'Shipped'
			WHEN 'S' THEN 'Shipped/Received'
			WHEN 'V' THEN 'Void'
			ELSE ''
		END, 
	who_entered ,
	lb_tracking_desc =
			CASE lb_tracking
			WHEN 'N' THEN 'No'
			WHEN 'Y' THEN 'Yes'
			ELSE ''
		END,

	x_xfer_no=xfer_no ,
	x_line_no=line_no ,
	x_ordered=ordered , 
	x_shipped=shipped 

 
from xfer_list

 
GO
GRANT REFERENCES ON  [dbo].[adtxl_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[adtxl_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[adtxl_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[adtxl_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[adtxl_vw] TO [public]
GO
