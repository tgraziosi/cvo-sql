SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

create view [dbo].[admfg_vw] as

select 
	l.prod_no ,
	l.location ,
	l.part_no ,
	l.description,
	p.prod_type,
	type_desc = 
		CASE p.prod_type
			WHEN 'B' THEN 'Batch Production'
			WHEN 'J' THEN 'Job Production'
			WHEN 'G' THEN 'Agent Production'
			WHEN 'M' THEN 'Normal Production'
			WHEN 'R' THEN 'Routed Production'
			WHEN 'X' THEN 'Configurator Production'
			WHEN 'V' THEN 'Void'
			ELSE ''
		END, 

	l.plan_qty,
	qty_produced=l.used_qty,
	l.scrap_pcs,
	p.shift,
	p.staging_area,
	p.est_no,
	date_sch = p.sch_date,
	date_prod = p.prod_date ,
	lb_tracking_desc=
		CASE l.lb_tracking
			WHEN 'Y' THEN 'Yes'
			WHEN 'N' THEN 'No'
			ELSE ''
		END, 
	discrete=
		CASE p.sch_flag
			WHEN 'D' THEN 'Discrete'
			WHEN 'P' THEN 'Regular Production'
			ELSE ''
		END, 
	p.status ,
	
	status_desc = 
		CASE p.status
			WHEN 'H' THEN 'Hold/Edit Job'
			WHEN 'N' THEN 'Open/New'
			WHEN 'P' THEN 'Open/Picked'
			WHEN 'Q' THEN 'Open/Printed'
			WHEN 'R' THEN 'Complete/QC Hold'
			WHEN 'S' THEN 'Complete'
			WHEN 'V' THEN 'Void'
			ELSE ''
		END, 
	p.who_entered ,
	p.prod_ext, 

	x_prod_no = convert(decimal,l.prod_no),
	x_plan_qty = l.plan_qty,
	x_qty_produced = l.used_qty,
	x_scrap_pcs = l.scrap_pcs,
	x_shift = p.shift,
	x_est_no = p.est_no,
	x_date_sch = ((datediff(day, '01/01/1900', p.sch_date) + 693596)) + (datepart(hh,p.sch_date)*.01 + datepart(mi,p.sch_date)*.0001 + datepart(ss,p.sch_date)*.000001),
	x_date_prod = ((datediff(day, '01/01/1900', p.prod_date) + 693596)) + (datepart(hh,p.prod_date)*.01 + datepart(mi,p.prod_date)*.0001 + datepart(ss,p.prod_date)*.000001),
	x_prod_ext = p.prod_ext 

from
	produce_all p, prod_list l
where p.prod_no=l.prod_no and l.direction=1
and p.prod_ext = l.prod_ext
 
GO
GRANT REFERENCES ON  [dbo].[admfg_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[admfg_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[admfg_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[admfg_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[admfg_vw] TO [public]
GO
