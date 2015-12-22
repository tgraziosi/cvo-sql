SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 25/11/2013 - Fix rounding issue  
CREATE PROCEDURE [dbo].[cc_select_order_det_sp] @order_no int, @ord_ext int  
  
AS  
  
CREATE TABLE #ord_list  
( order_no int,  
 order_ext int,  
 status char(1),  
 status_description varchar(50),  
 part_no varchar(32),  
 description varchar(255),  
 price  decimal(20,8),  
 ordered decimal(20,8),  
 shipped decimal(20,8),  
 discount decimal(20,8),  
 net decimal(20,8),  
 total_tax  decimal(20,8),  
 line_no int)  
  
  
  
 INSERT #ord_list(order_no, order_ext, status, status_description,  part_no, description, price, ordered, shipped, discount, net, total_tax, line_no )  
 SELECT  order_no,   
  order_ext,    
  status,  
  'status_description' =   
  CASE UPPER( status )  
   WHEN 'A' THEN 'A - Hold for Quote'  
   WHEN 'B' THEN 'B - Both a credit and price hold'  
   WHEN 'C' THEN 'C - Credit Hold'  
   WHEN 'E' THEN 'E - EDI'  
   WHEN 'H' THEN 'H - Price Hold'  
   WHEN 'M' THEN 'M - Blanket Order(parent)'  
   WHEN 'N' THEN 'N - New'  
   WHEN 'P' THEN 'P - Open/Picked'  
   WHEN 'Q' THEN 'Q - Open/Printed'  
   WHEN 'R' THEN 'R - Ready/Posting'  
   WHEN 'S' THEN 'S - Shipped/Posted'  
   WHEN 'T' THEN 'T - Shipped/Transferred'  
   WHEN 'V' THEN 'V - Void'  
   WHEN 'X' THEN 'X - Voided/Cancel Quote'  
   ELSE ''  
  END,   
  part_no,  
  description,  
  'price' = STR(curr_price,30,2),  
  ordered,  
  shipped,  
  'discount' = (curr_price * discount / 100 ),  
  'net' = 0,  
  total_tax,  
  line_no  
 FROM  ord_list  
 WHERE order_no = @order_no  
 AND order_ext = @ord_ext  
 AND ( ordered > 0 OR shipped > 0 )  
 ORDER BY order_no, order_ext, line_no  
  
  
 INSERT #ord_list(order_no, order_ext, status, status_description,  part_no, description, price, ordered, shipped, discount, net, total_tax, line_no )  
 SELECT  order_no,   
  order_ext,    
  status,  
  'status_description' =   
  CASE UPPER( status )  
   WHEN 'A' THEN 'A - Hold for Quote'  
   WHEN 'B' THEN 'B - Both a credit and price hold'  
   WHEN 'C' THEN 'C - Credit Hold'  
   WHEN 'E' THEN 'E - EDI'  
   WHEN 'H' THEN 'H - Price Hold'  
   WHEN 'M' THEN 'M - Blanket Order(parent)'  
   WHEN 'N' THEN 'N - New'  
   WHEN 'P' THEN 'P - Open/Picked'  
   WHEN 'Q' THEN 'Q - Open/Printed'  
   WHEN 'R' THEN 'R - Ready/Posting'  
   WHEN 'S' THEN 'S - Shipped/Posted'  
   WHEN 'T' THEN 'T - Shipped/Transferred'  
   WHEN 'V' THEN 'V - Void'  
   WHEN 'X' THEN 'X - Voided/Cancel Quote'  
   ELSE ''  
  END,   
  part_no,  
  description,  
  'price' = STR(curr_price,30,2),  
  cr_ordered,  
  cr_shipped,  
  'discount' = (curr_price * discount / 100 ),  
  'net' = 0,  
  total_tax,  
  line_no  
 FROM  ord_list  
 WHERE order_no = @order_no  
 AND order_ext = @ord_ext  
 AND ( cr_ordered > 0 OR cr_shipped > 0 )  
 ORDER BY order_no, order_ext, line_no  
  
  
  
 UPDATE #ord_list  
 SET status_description = ISNULL( hold_reason, 'A - Hold for Quote' )  
 FROM #ord_list o, orders_all a  
 WHERE o.status = 'A'  
 AND o.order_no = a.order_no  
 AND o.order_ext = a.ext  
  
 UPDATE #ord_list  
-- v1.0 SET net = l.shipped * ( l.curr_price - (l.curr_price * l.discount / 100 )) + l.total_tax  
 SET net = l.shipped * l.curr_price - ROUND((l.shipped * ( l.curr_price - (l.curr_price * l.discount / 100))),2) + l.total_tax  -- v1.0
 FROM #ord_list o, ord_list l  
 WHERE o.status IN ( 'R', 'S', 'T' )  
 AND l.cr_shipped = 0  
 AND o.order_no = l.order_no  
 AND o.order_ext = l.order_ext  
 AND o.line_no = l.line_no    
 AND UPPER( o.status ) IN ( SELECT UPPER( status_code ) FROM cc_ord_status WHERE use_flag = 1 )   
 AND void = 'N'   

  
 UPDATE #ord_list  
-- v1.0 SET net = l.ordered * ( l.curr_price - (l.curr_price * l.discount / 100 )) + l.total_tax  
 SET net = l.ordered * l.curr_price - ROUND((l.ordered * (l.curr_price - (l.curr_price * l.discount / 100))),2) + l.total_tax  -- v1.0
 FROM #ord_list o, ord_list l  
 WHERE o.status NOT IN ( 'R', 'S', 'T' )  
 AND l.cr_ordered = 0  
 AND o.order_no = l.order_no  
 AND o.order_ext = l.order_ext  
 AND o.line_no = l.line_no    
 AND UPPER( o.status ) IN ( SELECT UPPER( status_code ) FROM cc_ord_status WHERE use_flag = 1 )   
 AND void = 'N'   
  

 UPDATE #ord_list  
-- v1.0 SET net = (l.cr_shipped * ( l.curr_price - (l.curr_price * l.discount / 100 )) + l.total_tax) * -1,  	       
 SET net = (l.cr_shipped * l.curr_price - ROUND((l.cr_shipped * (l.curr_price - (l.curr_price * l.discount / 100))),2) + l.total_tax) * -1,  -- v1.0
 price = o.price * -1,   
 discount = o.discount * -1,   
 total_tax = o.total_tax * -1  
 FROM #ord_list o, ord_list l  
 WHERE o.status IN ( 'R', 'S', 'T' )  
 AND l.cr_shipped != 0  
 AND o.order_no = l.order_no  
 AND o.order_ext = l.order_ext  
 AND o.line_no = l.line_no  
 AND UPPER( o.status ) IN ( SELECT UPPER( status_code ) FROM cc_ord_status WHERE use_flag = 1 )   
 AND void = 'N'   
  
 UPDATE #ord_list  
-- v1.0 SET net = (l.cr_ordered * ( l.curr_price - (l.curr_price * l.discount / 100 )) + l.total_tax) * -1,  
 SET net = (l.cr_ordered * l.curr_price - ROUND(( l.cr_ordered * (l.curr_price - (l.curr_price * l.discount / 100))),2) + l.total_tax) * -1,  -- v1.0
 price = o.price * -1,   
 discount = o.discount * -1,   
 total_tax = o.total_tax * -1  
 FROM #ord_list o, ord_list l  
 WHERE o.status NOT IN ( 'R', 'S', 'T' )  
 AND l.cr_ordered != 0  
 AND o.order_no = l.order_no  
 AND o.order_ext = l.order_ext  
 AND o.line_no = l.line_no  
 AND UPPER( o.status ) IN ( SELECT UPPER( status_code ) FROM cc_ord_status WHERE use_flag = 1 )   
 AND void = 'N'   

  
--SELECT sum(net) from #ord_list  
SELECT order_no, order_ext, status_description,  part_no, description,   
price, ordered, shipped, discount, net, total_tax FROM #ord_list  
  
  
GO
GRANT EXECUTE ON  [dbo].[cc_select_order_det_sp] TO [public]
GO
