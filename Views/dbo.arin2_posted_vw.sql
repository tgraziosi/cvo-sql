SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[arin2_posted_vw] as
  select 
  	artrx.customer_code,
	artrxcdt.doc_ctrl_num,
	artrxcdt.trx_ctrl_num,
	artrxcdt.org_id,
	sequence_id,  
	location_code, 
	item_code,     
	line_desc,     
	qty_ordered,   
	qty_shipped,   
	unit_code,     
	unit_price,    
	qty_returned,        
	artrxcdt.tax_code,       
	gl_rev_acct,
	discount_amt,   
	disc_prc_flag,    
	extended_price,
	artrx.nat_cur_code,
	artrx.date_applied   
  from 
	artrxcdt artrxcdt, artrx artrx
  where
	artrxcdt.trx_ctrl_num = artrx.trx_ctrl_num
	and	artrx.trx_type <= 2031  	
	and artrx.order_ctrl_num = ''
UNION
  select 
  	artrx.customer_code,
	artrxcdt.doc_ctrl_num,
	artrxcdt.trx_ctrl_num,
	artrxcdt.org_id,
	ol.line_no as sequence_id,  
	ol.location as location_code, 
	ol.part_no as item_code,     
	ol.description as line_desc,
	ol.ordered as qty_ordered,   
	ol.shipped as qty_shipped,   
	ol.uom as unit_code,     
	ol.price as unit_price,    
	ol.cr_shipped as qty_returned,        
	artrxcdt.tax_code,       
	ol.gl_rev_acct as gl_rev_acct,
	ol.discount as discount_amt,   
	disc_prc_flag,    
	ol.shipped * (ol.price - ol.discount) as extended_price,
	artrx.nat_cur_code,
	artrx.date_applied   
  from 
	artrxcdt artrxcdt, artrx artrx
	LEFT OUTER JOIN orders_invoice oi 
		 ON SUBSTRING(artrx.doc_ctrl_num,1,10) = oi.doc_ctrl_num
	LEFT OUTER JOIN ord_list ol ON oi.order_no = ol.order_no AND oi.order_ext = ol.order_ext
  where
	artrxcdt.trx_ctrl_num = artrx.trx_ctrl_num
	and	artrx.trx_type <= 2031  	
	and artrx.order_ctrl_num > ' '


GO
GRANT SELECT ON  [dbo].[arin2_posted_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[arin2_posted_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[arin2_posted_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[arin2_posted_vw] TO [public]
GO
