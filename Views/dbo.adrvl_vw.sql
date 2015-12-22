SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create view [dbo].[adrvl_vw] as

select 
	rtv_no,
	line_no ,
	location ,
	part_no ,
	description,
	
	unit_measure,
	unit_cost,

	returned = qty_ordered ,	
	reason_code ,
	bin_no,
	lot_ser,
	account_no,
	vend_sku,

	x_rtv_no=rtv_no,
	x_line_no=line_no ,
	x_unit_cost=unit_cost,

	x_returned = qty_ordered 	

	
	
from rtv_list

 
GO
GRANT REFERENCES ON  [dbo].[adrvl_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[adrvl_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[adrvl_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[adrvl_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[adrvl_vw] TO [public]
GO
