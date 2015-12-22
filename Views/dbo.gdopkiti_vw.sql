SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO








                                                

CREATE VIEW [dbo].[gdopkiti_vw]
AS
SELECT  dbo.ord_list_kit.order_no,
	dbo.ord_list_kit.order_ext,
	dbo.ord_list_kit.line_no,
	dbo.ord_list.part_no AS kit_no, 
	dbo.ord_list_kit.ordered,
	dbo.ord_list_kit.part_no,
	dbo.ord_list_kit.description,
	dbo.orders.sch_ship_date,
	dbo.ord_list_kit.qty_per,
	dbo.ord_list_kit.qty_per * dbo.ord_list_kit.ordered AS kiq_ordered,
	dbo.ord_list_kit.qty_per * dbo.ord_list_kit.shipped AS kiq_shipped,
	dbo.lot_bin_ship.lot_ser,
	dbo.lot_bin_ship.qty,
	dbo.orders.status,
	dbo.orders.cust_code,

	x_sch_ship_date = ((datediff(day, '01/01/1900', dbo.orders.sch_ship_date) + 693596)) + (datepart(hh,dbo.orders.sch_ship_date)*.01 + datepart(mi,dbo.orders.sch_ship_date)*.0001 + datepart(ss,dbo.orders.sch_ship_date)*.000001)

FROM	dbo.ord_list_kit LEFT OUTER JOIN
	dbo.ord_list ON dbo.ord_list_kit.order_no = dbo.ord_list.order_no AND dbo.ord_list_kit.order_ext = dbo.ord_list.order_ext 
	AND dbo.ord_list_kit.line_no = dbo.ord_list.line_no 
	LEFT OUTER JOIN	dbo.orders ON dbo.ord_list_kit.order_no = dbo.orders.order_no 
	AND dbo.ord_list_kit.order_ext = dbo.orders.ext 
	LEFT OUTER JOIN	dbo.lot_bin_ship ON dbo.ord_list_kit.order_no = dbo.lot_bin_ship.tran_no 
	AND dbo.ord_list_kit.order_ext = dbo.lot_bin_ship.tran_ext 
	AND dbo.ord_list_kit.part_no = dbo.lot_bin_ship.part_no 
	AND dbo.ord_list_kit.line_no = dbo.lot_bin_ship.line_no
WHERE	(dbo.ord_list.part_no > '0')
                                              
GO
GRANT REFERENCES ON  [dbo].[gdopkiti_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[gdopkiti_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[gdopkiti_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[gdopkiti_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[gdopkiti_vw] TO [public]
GO
