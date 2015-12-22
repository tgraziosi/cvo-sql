SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



create view [dbo].[prodcost_vw] as
select	l.prod_no  ,
	l.prod_ext  ,
	l.line_no  ,
	l.seq_no  ,
	l.part_no  ,
	l.location  ,
	l.description  ,
	l.uom ,
	l.plan_qty  ,
	l.used_qty  ,
	l.lb_tracking  ,
	l.bench_stock  ,
	l.status  ,
	l.constrain ,
	l.part_type ,
	l.direction ,
	l.cost_pct ,
	isnull(sum(c.cost*c.qty),0) 'cost' ,
	isnull(sum(c.labor*c.qty),0) 'labor' ,
	isnull(sum(c.direct_dolrs*c.qty),0) 'direct_dolrs'  ,
	isnull(sum(c.ovhd_dolrs*c.qty),0) 'ovhd_dolrs'  ,
	isnull(sum(c.util_dolrs*c.qty),0) 'util_dolrs' ,
	isnull(sum(c.qty),0) 'qty' 
from prod_list l, prod_list_cost c
where l.prod_no=c.prod_no and l.prod_ext=c.prod_ext and
      l.line_no=c.line_no
group by l.prod_no  ,
	l.prod_ext  ,
	l.line_no  ,
	l.seq_no  ,
	l.part_no  ,
	l.location  ,
	l.description  ,
	l.uom,
	l.plan_qty  ,
	l.used_qty  ,
	l.lb_tracking  ,
	l.bench_stock  ,
	l.status  ,
	l.constrain ,
	l.part_type ,
	l.direction ,
	l.cost_pct


GO
GRANT REFERENCES ON  [dbo].[prodcost_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[prodcost_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[prodcost_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[prodcost_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[prodcost_vw] TO [public]
GO
