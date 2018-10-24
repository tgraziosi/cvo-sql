SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 31/08/2012 - Specify if the part did not ship on the order history tab  
  
CREATE PROCEDURE [dbo].[adm_cust_history] @cust_code varchar(20), @part_no varchar(30)  
as  
begin
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
       ELSE ''
       END AS status  
from dbo.orders_all o (nolock)
join dbo.ord_list l (NOLOCK) ON l.order_no = o.order_no AND l.order_ext = o.ext
join dbo.glcurr_vw g (nolock) ON g.currency_code = o.curr_key
where o.type <> 'C'  
and o.cust_code = @cust_code and l.part_no = @part_no  
group by o.order_no, l.location, l.part_no, l.ordered, l.uom, l.curr_price,  
g.currency_mask, o.cust_code, l.price_type, l.conv_factor,o.date_entered, o.status  

end  
GO
GRANT EXECUTE ON  [dbo].[adm_cust_history] TO [public]
GO
