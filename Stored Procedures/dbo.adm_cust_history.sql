SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 31/08/2012 - Specify if the part did not ship on the order history tab  
  
CREATE PROCEDURE [dbo].[adm_cust_history] @cust_code varchar(20), @part_no varchar(30)  
as  
  
select o.order_no,min(o.ext),l.location,l.part_no,l.ordered,l.uom,l.curr_price,  
       g.currency_mask, o.cust_code, l.price_type, l.conv_factor, o.date_entered,  
       CASE o.status WHEN 'A' THEN 'User Hold'  
       WHEN 'B' THEN 'Credit/Price Hold'  
       WHEN 'C' THEN 'Credit Hold'  
       WHEN 'E' THEN 'EDI'  
       WHEN 'H' THEN 'Price Hold'  
       WHEN 'L' THEN 'Multiple Shiptos'  
       WHEN 'M' THEN 'Blanket'  
       WHEN 'N' THEN 'New'  
       WHEN 'P' THEN CASE WHEN MAX(l.shipped) = 0 THEN 'Open/UnPicked' ELSE 'Open/Picked' END
       WHEN 'Q' THEN 'Open/Printed'  
       WHEN 'R' THEN CASE WHEN MAX(l.shipped) = 0 THEN 'Zero Shipped/Ready/Posting' ELSE 'Ready/Posting' END 
       WHEN 'S' THEN CASE WHEN MAX(l.shipped) = 0 THEN 'Zero Shipped/Posted' ELSE 'Shipped/Posted' END  
       WHEN 'T' THEN CASE WHEN MAX(l.shipped) = 0 THEN 'Zero Shipped/Transfered to AR' ELSE 'Shipped/Transfered to AR' END  
       WHEN 'V' THEN 'Void'  
       WHEN 'X' THEN 'Void/Cancelled Quote'  
       END AS status  
from orders_all o, ord_list l, glcurr_vw g  
where o.order_no = l.order_no and o.ext = l.order_ext  
and o.curr_key = g.currency_code  and o.type != 'C'  
and o.cust_code like @cust_code and l.part_no like @part_no  
group by o.order_no, l.location, l.part_no, l.ordered, l.uom, l.curr_price,  
g.currency_mask, o.cust_code, l.price_type, l.conv_factor,o.date_entered, o.status  
  
GO
GRANT EXECUTE ON  [dbo].[adm_cust_history] TO [public]
GO
