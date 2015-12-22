SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE VIEW [dbo].[gdserial_vw]
AS

--v1.1 - tag - remove qualification on price > 0

SELECT     
dbo.shippers.order_no, 
dbo.shippers.order_ext, 
dbo.ord_list.line_no, 
dbo.orders.invoice_no, 
dbo.orders.ship_to_name, 
dbo.orders.cust_po, 
inv.category,									-- CVO
inv.type_code,									-- CVO
dbo.shippers.part_no, 
dbo.ord_list.part_type, 
dbo.shippers.ordered, 
dbo.shippers.shipped, 
dbo.shippers.price, 
dbo.shippers.cost, 
(dbo.shippers.price - dbo.shippers.cost) / dbo.shippers.price * 100 AS item_gp, 
dbo.lot_bin_ship.bin_no,				-- CVO does not use Serial #'s
dbo.lot_bin_ship.qty, 
dbo.shippers.date_shipped, 
dbo.ord_list.description, 
dbo.shippers.cust_code, 
dbo.shippers.location, 
dbo.orders_invoice.doc_ctrl_num, 
dbo.ord_list.reference_code,
	x_date_shipped = (datediff(day, '01/01/1900', shippers.date_shipped ) + 693596)
                   + (datepart(hh,shippers.date_shipped)*.01 
                   + datepart(mi,shippers.date_shipped)*.0001 
                   + datepart(ss,shippers.date_shipped)*.000001)
FROM dbo.shippers (NOLOCK) 
INNER JOIN dbo.orders (NOLOCK) ON dbo.shippers.order_no = dbo.orders.order_no AND dbo.shippers.order_ext = dbo.orders.ext 
INNER JOIN dbo.ord_list (NOLOCK) ON dbo.shippers.order_no = dbo.ord_list.order_no AND
						   dbo.shippers.order_ext = dbo.ord_list.order_ext AND
						   dbo.shippers.line_no = dbo.ord_list.line_no						-- CVO FIX
INNER JOIN inv_master inv (NOLOCK) ON shippers.part_no = inv.part_no
INNER JOIN dbo.orders_invoice (NOLOCK) ON dbo.shippers.order_no = dbo.orders_invoice.order_no AND 
            dbo.shippers.order_ext = dbo.orders_invoice.order_ext 
LEFT OUTER JOIN dbo.lot_bin_ship (NOLOCK) ON dbo.shippers.order_no = dbo.lot_bin_ship.tran_no AND 
									dbo.shippers.order_ext = dbo.lot_bin_ship.tran_ext AND
									dbo.shippers.line_no = dbo.lot_bin_ship.line_no			-- CVO FIX
WHERE
	(dbo.orders_invoice.doc_ctrl_num > 'CRN') 
--v1.1 - remove qualification on price > 0
AND (dbo.shippers.price > 0)
GO
GRANT REFERENCES ON  [dbo].[gdserial_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[gdserial_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[gdserial_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[gdserial_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[gdserial_vw] TO [public]
GO
