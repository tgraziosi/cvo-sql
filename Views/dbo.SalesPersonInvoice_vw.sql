SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE View [dbo].[SalesPersonInvoice_vw] 
-- 8/30/2012 - tag - collapse installment invoices to one line and add framesshipped
AS
select salesperson,
territory,
cust_code,
ship_to,
name,
cb.order_no,
cb.ext,
left(invoice_no,7) as invoice_no, -- to collapse installment invoices
Convert(datetime,dateadd(d,DATESHIPPED-711858,'1/1/1950'),101) As dateshipped,
OrderType, 
promo_id, 
level,
-- tag 082812 add pcs shipped 
ISNULL( (select sum(shipped)-sum(cr_shipped) 
 from ord_list ol (nolock)
 inner join inv_master i (nolock) on ol.part_no = i.part_no
 where cb.order_no = ol.order_no and cb.ext = ol.order_ext
	and i.type_code in ('FRAME','SUN') ), 0) as FramesShipped,
-- end tag 082812
type,
sum(amount) as amount, 
[comm%] AS comm_percentage, 
sum([comm$]) AS comm_amount, 
loc, 
salesperson_name, 
hiredate, 
draw_amount

-- FROM CVO_commission_bldr_vw cb (nolock)
FROM CVO_commission_bldr_r2_vw cb (nolock)

group by
salesperson,
territory,
cust_code,
ship_to,
name,
cb.order_no,
cb.ext,
left(invoice_no,7), -- to collapse installment invoices
Convert(datetime,dateadd(d,DATESHIPPED-711858,'1/1/1950'),101),
OrderType, 
promo_id, 
level,
type,
[comm%], 
loc, 
salesperson_name, 
hiredate, 
draw_amount



GO
GRANT SELECT ON  [dbo].[SalesPersonInvoice_vw] TO [public]
GO
