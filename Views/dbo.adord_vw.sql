SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[adord_vw] as
-- tag - 1/18/2012 - add nolock on tables
-- tag - 5/21/2012 - add qty ordered and shipped per KM request
SELECT
	orders.order_no ,
	orders.ext ,
	orders.cust_code,
	orders.ship_to ,
	orders.ship_to_name ,
	orders.location ,	
	orders.cust_po ,
	orders.routing,
	orders.fob,
	orders.attention,
	orders.tax_id,
	orders.terms,
	arc.credit_limit,							-- v2.0
	orders.hold_reason,							-- T McGrady	NOV.29.2010
	orders.curr_key,
	orders.salesperson,							-- T McGrady	NOV.29.2010
	orders.ship_to_region AS Territory,			-- T McGrady	NOV.29.2010
	orders.total_amt_order ,
	total_tax =orders.tot_ord_tax ,
	total_discount=orders.tot_ord_disc ,
	freight=orders.tot_ord_freight,
-- tag - 5/21/2012 - add qty ordered and shipped per KM request
	qty_ordered = (select sum(ordered-cr_ordered) from ord_list ol (nolock) where
		orders.order_no = ol.order_no and orders.ext = ol.order_ext),
	qty_shipped = (select sum(shipped-cr_shipped) from ord_list ol (nolock) where
		orders.order_no = ol.order_no and orders.ext = ol.order_ext),
	orders.total_invoice ,
	orders.invoice_no ,
	orders_invoice.doc_ctrl_num,
	date_invoice = orders.invoice_date ,
	orders.date_entered ,
	date_sch_ship = orders.sch_ship_date ,
	orders.date_shipped ,		
	orders.status , 
	status_desc = 
		CASE orders.status
			WHEN 'A' THEN 'User Hold'
			WHEN 'B' THEN 'Both a credit and price hold'
			WHEN 'C' THEN 'Credit Hold'
			WHEN 'E' THEN 'EDI'
			WHEN 'H' THEN 'Price Hold'
			WHEN 'M' THEN 'Blanket Order(parent)'
			WHEN 'N' THEN 'New'
			WHEN 'P' THEN 'Open/Picked'
			WHEN 'Q' THEN 'Open/Printed'
			WHEN 'R' THEN 'Ready/Posting'
			WHEN 'S' THEN 'Shipped/Posted'
			WHEN 'T' THEN 'Shipped/Transferred'
			WHEN 'V' THEN 'Void'
			WHEN 'X' THEN 'Voided/Cancel Quote'
			ELSE ''
		END, 
	orders.who_entered,
--	orders.blanket,
--	blanket_desc=
--			CASE orders.blanket
--			WHEN 'N' THEN 'No'
--			WHEN 'Y' THEN 'Yes'
--			ELSE ''
--		END,
	shipped_flag =
			CASE orders.status
			WHEN 'A' THEN 'No'
			WHEN 'B' THEN 'No'
			WHEN 'C' THEN 'No'
			WHEN 'E' THEN 'No'
			WHEN 'H' THEN 'No'
			WHEN 'M' THEN 'No'
			WHEN 'N' THEN 'No'
			WHEN 'P' THEN 'No'
			WHEN 'Q' THEN 'No'
			WHEN 'R' THEN 'Yes'
			WHEN 'S' THEN 'Yes'
			WHEN 'T' THEN 'Yes'
			WHEN 'V' THEN 'No'
			WHEN 'X' THEN 'No'
			ELSE ''
		END,
	orders.orig_no,
	orders.orig_ext,
	CASE multiple_flag 
		WHEN 'Y' THEN 'Yes' 
		WHEN 'N' THEN 'No' 
		ELSE 'No' END multiple_ship_to,
-- 	Ctel_Order_Num = ISNULL(EAI_ord_xref.FO_order_no, ' '),
	orders.user_category	-- TAG 12/1/2011 - add order type (rx,st, etc.)
FROM	orders orders (nolock)
	LEFT OUTER JOIN orders_invoice orders_invoice (nolock) ON ( orders.order_no = orders_invoice.order_no
                                      AND  orders.ext = orders_invoice.order_ext  ) 
--    LEFT OUTER JOIN EAI_ord_xref EAI_ord_xref (nolock) ON ( orders.order_no = EAI_ord_xref.BO_order_no  )
	LEFT JOIN arcust arc (NOLOCK) ON orders.cust_code = arc.customer_code
WHERE 	orders.type = 'I'
GO
GRANT REFERENCES ON  [dbo].[adord_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[adord_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[adord_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[adord_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[adord_vw] TO [public]
GO
