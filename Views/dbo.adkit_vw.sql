SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create view [dbo].[adkit_vw] as

select 
	parent_item = p.asm_no ,
	p.seq_no,
	comp_item = p.part_no ,
	m.description ,
	status = p.active,
	status_desc = 
		CASE p.active
			WHEN 'A' THEN 'Active'
			WHEN 'B' THEN 'Pending Inactive'
			WHEN 'F' THEN 'Feature'
			WHEN 'M' THEN 'By Product'
			WHEN 'T' THEN 'Alternate'
			WHEN 'U' THEN 'Pending Active'
			WHEN 'V' THEN 'Inactive'
			ELSE ''
		END,
	
	p.uom,
	p.qty,
	p.plan_pcs,
	p.lag_qty,
	p.location,
	p.cost_pct,
	p.fixed,
	fixed_desc=
			CASE p.fixed
			WHEN 'Y' THEN 'Use qty once for production'
			WHEN 'N' THEN 'Use qty for each item produced'
			ELSE ''
		END,
	cell=
			CASE p.constrain
			WHEN 'N' THEN 'Just print item on pick list'
			WHEN 'Y' THEN 'Include build plan for item on pick list'
			ELSE ''
		END,
	print_desc = 
			CASE p.bench_stock
			WHEN 'N' THEN 'Print on Work Ticket'
			WHEN 'Y' THEN 'Do Not Print on Work Ticket'
			ELSE ''
		END,

	x_qty=p.qty,
	x_plan_pcs=p.plan_pcs,
	x_lag_qty=p.lag_qty,
	x_cost_pct=p.cost_pct

	

from
	what_part p, inv_master m
where p.part_no = m.part_no

 
GO
GRANT REFERENCES ON  [dbo].[adkit_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[adkit_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[adkit_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[adkit_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[adkit_vw] TO [public]
GO
