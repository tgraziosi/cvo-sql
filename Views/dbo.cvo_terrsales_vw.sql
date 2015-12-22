SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[cvo_terrsales_vw]        
AS
SELECT             
t1.order_no,         
t1.order_ext,         
dbo.ord_list.line_no,         
t1.cust_code,         
Name = (CASE WHEN 1=1 then (select address_name from armaster_all where customer_code=t1.cust_code and address_type=0)
ELSE '' END),
cast(t1.part_no as varchar) AS part_no,         
convert(varchar,dbo.orders.invoice_no) AS invoice_no,         
--dbo.orders.ship_to_name,         
--dbo.orders.cust_po,         
--inv.category,         -- CVO        
--inv.type_code,         -- CVO        
--dbo.ord_list.part_type,         
--dbo.shippers.ordered,         
--dbo.shippers.shipped,         
--price = CASE      
-- WHEN orders_invoice.doc_ctrl_num > 'CRN' THEN dbo.shippers.price       
-- ELSE dbo.shippers.price*-1      
-- END,         
--cost = CASE      
-- WHEN orders_invoice.doc_ctrl_num > 'CRN' THEN dbo.shippers.cost       
-- ELSE dbo.shippers.cost*-1      
-- END,           
--item_gp = CASE      
-- WHEN orders_invoice.doc_ctrl_num > 'CRN' THEN (dbo.shippers.price - dbo.shippers.cost) / dbo.shippers.price * 100       
-- ELSE ((dbo.shippers.price - dbo.shippers.cost) / dbo.shippers.price * 100)*-1      
-- END,      
--dbo.lot_bin_ship.bin_no,    -- CVO does not use Serial #'s        
qty = CASE      
 WHEN orders_invoice.doc_ctrl_num > 'CRN' THEN dbo.lot_bin_ship.qty       
 ELSE dbo.lot_bin_ship.qty*-1      
 END,              
CAST(t1.date_shipped as datetime) AS date_shipped,         
t1.ship_to_region,
--dbo.ord_list.description,         
--dbo.shippers.cust_code,         
t1.location,         
--dbo.orders_invoice.doc_ctrl_num,         
--dbo.ord_list.reference_code,        
 x_date_shipped = (datediff(day, '01/01/1900', t1.date_shipped ) + 693596)        
                   + (datepart(hh,t1.date_shipped)*.01         
                   + datepart(mi,t1.date_shipped)*.0001         
                   + datepart(ss,t1.date_shipped)*.000001),      
x_type = CASE      
 WHEN   orders_invoice.doc_ctrl_num > 'CRN' THEN 'I'      
 ELSE 'C'      
END      
FROM dbo.shippers t1 (NOLOCK)         
INNER JOIN dbo.orders (NOLOCK) ON t1.order_no = dbo.orders.order_no AND t1.order_ext = dbo.orders.ext         
INNER JOIN dbo.ord_list (NOLOCK) ON t1.order_no = dbo.ord_list.order_no AND        
         t1.order_ext = dbo.ord_list.order_ext AND        
         t1.line_no = dbo.ord_list.line_no      -- CVO FIX        
INNER JOIN inv_master inv (NOLOCK) ON t1.part_no = inv.part_no        
INNER JOIN dbo.orders_invoice (NOLOCK) ON t1.order_no = dbo.orders_invoice.order_no AND         
            t1.order_ext = dbo.orders_invoice.order_ext         
LEFT OUTER JOIN dbo.lot_bin_ship (NOLOCK) ON t1.order_no = dbo.lot_bin_ship.tran_no AND         
         t1.order_ext = dbo.lot_bin_ship.tran_ext AND        
         t1.line_no = dbo.lot_bin_ship.line_no   -- CVO FIX        
WHERE        
 --(dbo.orders_invoice.doc_ctrl_num > 'CRN') AND      
 (t1.price > 0)        
union all    
SELECT             
t2.order_no,         
t2.ext,         
dbo.cvo_ord_list_hist.line_no,         
t2.cust_code,         
Name = (CASE WHEN 1=1 then (select address_name from armaster_all where customer_code=t2.cust_code and address_type=0)
ELSE '' END),
cast(dbo.cvo_ord_list_hist.part_no as varchar) AS part_no,         
CAST(t2.invoice_no AS VARCHAR) INVOICE_NO,         
--dbo.cvo_orders_all_hist.ship_to_name,         
--dbo.cvo_orders_all_hist.cust_po,         
--inv.category,         -- CVO        
--inv.type_code,         -- CVO        
--dbo.cvo_ord_list_hist.part_type,         
--dbo.cvo_ord_list_hist.ordered,         
--dbo.cvo_ord_list_hist.shipped,         
--price = CASE      
-- WHEN cvo_orders_all_hist.type= 'I' THEN dbo.cvo_ord_list_hist.price       
-- ELSE dbo.cvo_ord_list_hist.price*-1      
-- END,         
--cost = CASE      
-- WHEN cvo_orders_all_hist.type= 'I' THEN dbo.cvo_ord_list_hist.cost       
-- ELSE dbo.cvo_ord_list_hist.cost*-1      
-- END,           
--item_gp = CASE      
-- WHEN cvo_orders_all_hist.type= 'I' THEN (dbo.cvo_ord_list_hist.price - dbo.cvo_ord_list_hist.cost) / dbo.cvo_ord_list_hist.price * 100       
-- ELSE ((dbo.cvo_ord_list_hist.price - dbo.cvo_ord_list_hist.cost) / dbo.cvo_ord_list_hist.price * 100)*-1      
-- END,      
--'',--dbo.cvo_ord_list_hist.bin_no,    -- CVO does not use Serial #'s        
qty = CASE      
 WHEN t2.type= 'I' THEN dbo.cvo_ord_list_hist.shipped       
 ELSE dbo.cvo_ord_list_hist.shipped*-1      
 END,              
CAST(t2.date_shipped as datetime) AS date_shipped,  
ISNULL(t2.ship_to_region,'') SHIP_TO_REGION,
-- ship_to_region = (select territory_code from cvo_territoryxref where SCODE=t2.salesperson),
--dbo.cvo_ord_list_hist.description,         
--dbo.cvo_orders_all_hist.cust_code,         
ISNULL(t2.location,'') LOCATION,         
--'',--dbo.cvo_orders_all_hist.doc_ctrl_num,         
--dbo.cvo_ord_list_hist.reference_code,        
 x_date_shipped = (datediff(day, '01/01/1900', t2.date_shipped ) + 693596)        
                   + (datepart(hh,t2.date_shipped)*.01         
                   + datepart(mi,t2.date_shipped)*.0001         
                   + datepart(ss,t2.date_shipped)*.000001),      
x_type = CASE      
 WHEN   t2.type= 'I' THEN 'I'      
 ELSE 'C'      
END      
FROM dbo.cvo_orders_all_hist t2(NOLOCK) --ON dbo.shippers.order_no = dbo.cvo_orders_all_hist.order_no AND dbo.shippers.order_ext = dbo.cvo_orders_all_hist.ext         
INNER JOIN dbo.cvo_ord_list_hist (NOLOCK) ON t2.order_no = dbo.cvo_ord_list_hist.order_no AND        
         t2.ext = dbo.cvo_ord_list_hist.order_ext --AND        
         --dbo.cvo_orders_all_hist.line_no = dbo.cvo_ord_list_hist.line_no      -- CVO FIX        
--INNER JOIN inv_master inv (NOLOCK) ON cvo_ord_list_hist.part_no = inv.part_no        
WHERE        
 --(dbo.cvo_orders_all_hist_invoice.doc_ctrl_num > 'CRN') AND      
 (dbo.cvo_ord_list_hist.price > 0)            
    
--select * from orders
GO
GRANT REFERENCES ON  [dbo].[cvo_terrsales_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_terrsales_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_terrsales_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_terrsales_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_terrsales_vw] TO [public]
GO
