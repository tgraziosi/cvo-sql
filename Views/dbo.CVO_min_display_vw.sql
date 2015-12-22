SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE view [dbo].[CVO_min_display_vw] as

select 
l.order_no,
l.order_ext,
min(l.display_line) as min_line
from ord_list l (nolock)
join orders_invoice i (nolock) on l.order_no = i.order_no and l.order_ext = i.order_ext
group by l.order_no, l.order_ext


GO
GRANT REFERENCES ON  [dbo].[CVO_min_display_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_min_display_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_min_display_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_min_display_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_min_display_vw] TO [public]
GO
