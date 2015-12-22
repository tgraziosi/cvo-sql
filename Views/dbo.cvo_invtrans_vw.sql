SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[cvo_invtrans_vw] as 

select g.tran_no, g.tran_ext, g.trx_type, g.tran_date, g.part_no, 
	   i.type_code, g.tran_qty, lb.location, lb.bin_no, lb.qty, lb.direction, lb.who
From inv_master i (nolock)
inner join in_gltrxdet g (nolock) on i.part_no = g.part_no 
inner join lot_bin_tran lb (nolock) on lb.part_no = g.part_no and lb.tran_no = g.tran_no and lb.tran_ext = g.tran_ext and lb.location = g.location and lb.line_no = g.tran_line
where 1=1
-- and g.apply_date >= '07/16/2014 06:05'
and i.lb_tracking = 'y'
-- and lb.bin_no = 'rr putaway'
and g.line_descr = 'inv_acct'
--and lb.part_no = 'bcgcolink5316'
---and lb.location = '001'
-- and trx_type <> 's'
-- order by tran_no


GO
GRANT REFERENCES ON  [dbo].[cvo_invtrans_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_invtrans_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_invtrans_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_invtrans_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_invtrans_vw] TO [public]
GO
