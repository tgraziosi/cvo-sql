SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE view [dbo].[CVO_dd_min_line_vw] as
-- used in bglog_source views
select 
dd.order_no,
dd.ext,
min(dd.line_no) as min_line,
dd.trx_ctrl_num
from cvo_debit_promo_customer_det dd (nolock)
join orders_invoice i (nolock) on dd.order_no = i.order_no and dd.ext = i.order_ext
group by dd.order_no, dd.ext, dd.trx_ctrl_num




GO
GRANT REFERENCES ON  [dbo].[CVO_dd_min_line_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_dd_min_line_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_dd_min_line_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_dd_min_line_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_dd_min_line_vw] TO [public]
GO
