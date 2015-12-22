SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create view [dbo].[cvo_ord_list_hist_promo_vw] as 

select
o.user_def_fld3 as promo_id,
o.user_def_fld9 as promo_level,
o.order_no as Order_num,
o.ext,
d.*
from
	cvo_orders_all_hist o
	inner join
	cvo_ord_list_hist d on (o.order_no=d.order_no and o.ext = d.order_ext)
where o.user_def_fld3 is not null and ( d.part_no like 'CVZ%' or d.part_no like 'MEZ%' )
GO
GRANT SELECT ON  [dbo].[cvo_ord_list_hist_promo_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_ord_list_hist_promo_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_ord_list_hist_promo_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_ord_list_hist_promo_vw] TO [public]
GO
