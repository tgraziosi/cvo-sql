SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

-- select * from CVO_mstpk_vw where order_no = 12780 12658

CREATE view [dbo].[CVO_mstpk_vw] 
as
select
	o.order_no,
	o.ext,
	isnull(j.order_no, 0) as orders_in_pack,
	case when m.pack_no is null then 'NO' else 'YES' end as is_pack,
	isnull(m.pack_no,0) as pack_no,
	isnull(m.carton_no,0)as carton_no,
	isnull(c.carton_type,'NONE')as carton_type,
	o.cust_code,
	o.date_shipped,
	j.freight as invoice_freight,
	isnull(c.carrier_code, '')as carrier_code,
	isnull(c.cs_tracking_no, '') as cs_tracking_no,
	isnull(c.cs_published_freight,0) as cs_published_freight
from
	orders o (nolock)
	left outer join tdc_carton_tx c (nolock) on o.order_no = c.order_no and o.ext = c.order_ext
	left outer join tdc_master_pack_ctn_tbl m (nolock) on m.carton_no = c.carton_no
	left outer join tdc_master_pack_ctn_tbl z (nolock) on m.pack_no = z.pack_no
	left outer join tdc_carton_tx t (nolock) on z.carton_no = t.carton_no
	left outer join orders j (nolock) on j.order_no = t.order_no and  j.ext = t.order_ext



GO
GRANT REFERENCES ON  [dbo].[CVO_mstpk_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_mstpk_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_mstpk_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_mstpk_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_mstpk_vw] TO [public]
GO
