SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create view [dbo].[admgl_vw] as

select 
	prod_no ,
	seq_no, 
	location,
	part_no,
	description,
	uom,
	plan_qty,
	used_qty,
	plan_pcs,
	produced_pcs=pieces,
	scrap_pcs,
	status,
	status_desc = 
		CASE status
			WHEN 'H' THEN 'Hold/Edit Job'
			WHEN 'N' THEN 'Open/New'
			WHEN 'P' THEN 'Open/Picked'
			WHEN 'Q' THEN 'Open/Printed'
			WHEN 'R' THEN 'Complete/QC Hold'
			WHEN 'S' THEN 'Complete'
			WHEN 'V' THEN 'Void'
			ELSE ''
		END, 
	prod_ext, 

	x_prod_no=prod_no ,
	x_plan_qty=plan_qty,
	x_used_qty=used_qty,
	x_plan_pcs=plan_pcs,
	x_produced_pcs=pieces,
	x_scrap_pcs=scrap_pcs,
	x_prod_ext=prod_ext

from
	prod_list
where direction=-1

 
GO
GRANT REFERENCES ON  [dbo].[admgl_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[admgl_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[admgl_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[admgl_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[admgl_vw] TO [public]
GO
