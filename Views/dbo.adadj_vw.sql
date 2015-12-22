SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


create view [dbo].[adadj_vw] as

select 
	i.location_from ,
	i.part_no ,
	m.description,
	i.issue_no ,
	date_issue = i.issue_date ,
	i.code ,
	i.qty ,
	cost = i.avg_cost+i.direct_dolrs+i.ovhd_dolrs+i.util_dolrs,
	ext_cost = (i.avg_cost+i.direct_dolrs+i.ovhd_dolrs+i.util_dolrs) * i.qty,
	lb_tracking_desc=
		CASE i.lb_tracking 
			WHEN 'N' THEN 'No'
			WHEN 'Y' THEN 'Yes'
			ELSE ''
		END,
	direction,
	transfer_flag = 
		CASE i.direction
			WHEN 1 THEN 'In'
			WHEN -1 THEN 'Out'
			ELSE ''
		END,

	x_issue_no = convert(decimal,i.issue_no),
	x_date_issue = ((datediff(day, '01/01/1900', i.issue_date) + 693596)) + (datepart(hh,i.issue_date)*.01 + datepart(mi,i.issue_date)*.0001 + datepart(ss,i.issue_date)*.000001),
	x_qty=i.qty ,
	x_cost = i.avg_cost+i.direct_dolrs+i.ovhd_dolrs+i.util_dolrs,
	x_ext_cost = (i.avg_cost+i.direct_dolrs+i.ovhd_dolrs+i.util_dolrs) * i.qty


from issues_all i, inv_master m
where i.part_no = m.part_no

                                             
GO
GRANT REFERENCES ON  [dbo].[adadj_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[adadj_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[adadj_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[adadj_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[adadj_vw] TO [public]
GO
