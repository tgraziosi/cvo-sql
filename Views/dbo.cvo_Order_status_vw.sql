SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/* tag 11/30/2011 - New view for Customer Order Status Query*/
/* tag 2/20/2012 - Add Global ship to information */
CREATE VIEW [dbo].[cvo_Order_status_vw]
AS
select 
-- top 100
O.ORDER_NO, 
o.ext, 
o.date_entered, 
o.date_shipped, 
o.status,
status_desc =         
  CASE o.status        
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
   WHEN 'X' THEN 'Void'        
   ELSE '' 
  END,         
isnull(o.cust_po,'') as Cust_po,
o.ship_to_name,
o.ship_to_add_1,
o.ship_to_add_2,
o.ship_to_add_3,
o.ship_to_add_4,
o.ship_to_city,
o.ship_to_state,
o.ship_to_zip,
isnull(o.sold_to,'') as Global_ship_to,
isnull(o.sold_to_addr1,'') as Global_name,
--o.total_amt_order,
 total_amt_order = 
	case o.status
		when 'T' then o.gross_sales
		else  o.total_amt_order
		end,
--o.freight,
 freight=
	case o.status
		when 'T' then freight
		else o.tot_ord_freight
		end,        
--o.total_tax,
 total_tax =
	case o.status
		when 'T' then total_tax
		else o.tot_ord_tax
		end,  
isnull(c.carrier_code,isnull(o.routing,'')) as carrier,
isnull(c.cs_tracking_no,'') as tracking
from orders_all o 
--join ord_list od 
--on o.order_no = od.order_no and o.ext = od.order_ext
left outer join tdc_carton_tx c on o.order_no = c.order_no and o.ext = c.order_ext
where o.status <> 'V' and o.void = 'N' and (c.void=0 or c.void is null) and o.type='I'
GO
GRANT REFERENCES ON  [dbo].[cvo_Order_status_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_Order_status_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_Order_status_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_Order_status_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_Order_status_vw] TO [public]
GO
