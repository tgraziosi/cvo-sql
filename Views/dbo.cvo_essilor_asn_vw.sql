SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[cvo_essilor_asn_vw] AS 

SELECT i.upc_code UPC, o.cust_po PO, SUM(ol.shipped) QTY, o.order_no, o.invoice_no, DATEADD(dd, DATEDIFF(dd, 0, o.date_shipped), 0) date_shipped
FROM orders o
JOIN ord_list ol ON ol.order_no = o.order_no AND ol.order_ext = o.ext

JOIN inv_master i ON i.part_no = ol.part_no

WHERE o.status BETWEEN 'r' AND 't'

GROUP BY i.upc_code,
         o.cust_po,
         o.order_no,
         o.invoice_no,
         DATEADD(dd, DATEDIFF(dd, 0, o.date_shipped), 0) 

GO
GRANT SELECT ON  [dbo].[cvo_essilor_asn_vw] TO [public]
GO
