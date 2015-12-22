SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[gdsol2_vw]
AS
SELECT     dbo.adodl_vw.order_no, dbo.adodl_vw.order_ext, dbo.adodl_vw.line_no, dbo.adodl_vw.location, dbo.adodl_vw.part_no, dbo.adodl_vw.description, 
                      dbo.adodl_vw.uom, dbo.adodl_vw.ordered, dbo.adodl_vw.shipped, dbo.adodl_vw.price, dbo.adodl_vw.ext_price, dbo.ord_list.status, 
                      dbo.orders.sch_ship_date, dbo.orders.req_ship_date, dbo.orders.forwarder_key,
		      x_req_ship_date = (datediff(day, '01/01/1900', dbo.orders.req_ship_date) + 693596)
                              + (datepart(hh,dbo.orders.req_ship_date)*.01 
                              + datepart(mi,dbo.orders.req_ship_date)*.0001 
                              + datepart(ss,dbo.orders.req_ship_date)*.000001),
		      x_sch_ship_date = (datediff(day, '01/01/1900', dbo.orders.sch_ship_date) + 693596)
                              + (datepart(hh,dbo.orders.sch_ship_date)*.01 
                              + datepart(mi,dbo.orders.sch_ship_date)*.0001 
                              + datepart(ss,dbo.orders.sch_ship_date)*.000001)
FROM         dbo.adodl_vw LEFT OUTER JOIN
                      dbo.orders ON dbo.adodl_vw.order_no = dbo.orders.order_no AND dbo.adodl_vw.order_ext = dbo.orders.ext LEFT OUTER JOIN
                      dbo.ord_list ON dbo.adodl_vw.ordered > dbo.ord_list.shipped AND dbo.adodl_vw.order_no = dbo.ord_list.order_no AND 
                      dbo.adodl_vw.order_ext = dbo.ord_list.order_ext AND dbo.adodl_vw.line_no = dbo.ord_list.line_no
WHERE     (dbo.ord_list.status = '=') AND (dbo.adodl_vw.shipped < dbo.adodl_vw.ordered) OR
                      (dbo.ord_list.status = 'N') OR
                      (dbo.ord_list.status = 'P') OR
                      (dbo.ord_list.status = 'Q') OR
                      (dbo.ord_list.status = 'R')  
GO
GRANT REFERENCES ON  [dbo].[gdsol2_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[gdsol2_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[gdsol2_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[gdsol2_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[gdsol2_vw] TO [public]
GO
