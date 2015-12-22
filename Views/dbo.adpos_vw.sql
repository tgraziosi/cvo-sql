SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[adpos_vw] as
select   
 convert(varchar(10), p.po_key) 'po_key',       
 p.vendor_no,  
 a.address_name vendor_name,  
 p.ship_to_no ,  
 p.ship_name,  
 p.location ,  
 p.buyer ,  
 p.prod_no ,  
 p.ship_via ,  
  p.fob ,  
 p.terms ,  
 p.curr_key ,  
 p.tax_code,  
 p.attn,
 p.note,  
 p.total_amt_order,  
 p.total_tax,  
  
 p.date_of_order,  
 p.date_order_due,  
   
 p.status ,  
 
 status_desc =   
  CASE p.status + p.void    
   WHEN 'ON' THEN 'Open'  
   WHEN 'HN' THEN 'Hold'  
   WHEN 'CV' THEN 'Void'  
   WHEN 'CN' THEN 'Closed'  
--   WHEN 'V' THEN 'Void'  pre-SCR 28228 KJC Jan 24 2002  
   ELSE ''  
  END,   
  
 p.who_entered,  
 print_status=   
  CASE p.printed  
   WHEN 'H' THEN 'Do Not Print'  
   WHEN 'N' THEN 'Print With Next Batch'  
   WHEN 'P' THEN 'Re-print with next batch'  
   WHEN 'Y' THEN 'Printed'  
   ELSE ''  
  END,   
  
 p.blanket,  
 blanket_desc=  
  CASE p.blanket  
   WHEN 'Y' THEN 'Yes'  
   WHEN 'N' THEN 'No'  
   ELSE ''  
  END,  
 qty_ordered=
	CASE 
	WHEN 1=1 THEN (select SUM(qty_ordered) from pur_list where po_no=p.po_no)
	ELSE 0
	END,
qty_received=
	CASE 
	WHEN 1=1 THEN (select SUM(qty_received) from pur_list where po_no=p.po_no)
	ELSE 0
	END,
(SELECT 
      CASE 
         WHEN SUM((qty_ordered - qty_received) * curr_cost) <  0 THEN 0
         ELSE SUM((qty_ordered - qty_received) * curr_cost)
      END
      From pur_list pl
      Where pl.po_no = p.po_key
      Group By pl.po_no)AS po_open_value,
  
 x_po_key = p.po_key ,  
 x_prod_no = p.prod_no ,  
 x_total_amt_order = p.total_amt_order,  
 x_total_tax = p.total_tax,  
 x_date_of_order = ((datediff(day, '01/01/1900', p.date_of_order) + 693596)) + (datepart(hh,p.date_of_order)*.01 + datepart(mi,p.date_of_order)*.0001 + datepart(ss,p.date_of_order)*.000001),  
 x_date_order_due = ((datediff(day, '01/01/1900', p.date_order_due) + 693596)) + (datepart(hh,p.date_order_due)*.01 + datepart(mi,p.date_order_due)*.0001 + datepart(ss,p.date_order_due)*.000001)
 
from 
apmaster_all a INNER JOIN purchase_all p
ON
a.vendor_code = p.vendor_no
GO
GRANT REFERENCES ON  [dbo].[adpos_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[adpos_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[adpos_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[adpos_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[adpos_vw] TO [public]
GO
