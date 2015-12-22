SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[cvo_Invoice_Audit_vw] as 
select distinct ia.order_no, ia.order_ext, ia.customer_code, ia.ship_to, ia.invoice_no, 
ia.order_total, ia.order_value, ia.discount_value, ia.tax_value, ia.freight_value,  
o.total_invoice, o.gross_sales,o.total_discount,o.total_tax,
o.freight, o.status, o.invoice_date,
BG = (SELECT buying_group FROM CVO_orders_all WHERE order_no = o.order_no 
		AND ext = o.ext),
MP = isnull((select top 1 pack_no from tdc_carton_tx c (nolock) 
	left outer join tdc_master_pack_ctn_tbl m (nolock) on m.carton_no = c.carton_no
	where o.order_no = c.order_no and o.ext = c.order_ext),0)
From cvo_invoice_audit ia (nolock), orders o (nolock)
Where ia.order_no = o.order_no and ia.order_ext = o.ext
and (ia.tax_value <> total_tax 
or ia.freight_value <> o.freight)
and o.invoice_date is not null


--select * from orders where order_no = 1380992
GO
GRANT SELECT ON  [dbo].[cvo_Invoice_Audit_vw] TO [public]
GO
