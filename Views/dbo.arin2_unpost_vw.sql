SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[arin2_unpost_vw] as
  select                
  	arinpchg.customer_code,
	arinpchg.doc_ctrl_num,
	arinpchg.trx_ctrl_num,
	arinpcdt.org_id,
	sequence_id,  
	arinpcdt.location_code, 
	item_code,     
	line_desc,     
	qty_ordered,   
	qty_shipped,   
	unit_code,     
	unit_price,    
	qty_returned,        
	arinpcdt.tax_code,       
	gl_rev_acct,
	discount_amt,   
	disc_prc_flag,    
	extended_price,
	arinpchg.nat_cur_code,
	arinpchg.date_applied

  from 
	arinpcdt arinpcdt, arinpchg arinpchg
  where
	arinpcdt.trx_ctrl_num = arinpchg.trx_ctrl_num
	and	arinpchg.trx_type <= 2031   
	and arinpchg.order_ctrl_num = ''
UNION
  select 
  	arinpchg.customer_code,
	arinpcdt.doc_ctrl_num,
	arinpcdt.trx_ctrl_num,
	arinpcdt.org_id,
	ol.line_no as sequence_id,  
	ol.location as location_code, 
	ol.part_no as item_code,     
	ol.description as line_desc,
	ol.ordered as qty_ordered,   
	ol.shipped as qty_shipped,   
	ol.uom as unit_code,     
	ol.price as unit_price,    
	ol.cr_shipped as qty_returned,        
	arinpcdt.tax_code,       
	ol.gl_rev_acct as gl_rev_acct,
	ol.discount as discount_amt,   
	disc_prc_flag,    
	ol.shipped * (ol.price - ol.discount) as extended_price,
	arinpchg.nat_cur_code,
	arinpchg.date_applied   
  from 
	arinpcdt arinpcdt, arinpchg arinpchg
	LEFT OUTER JOIN orders_invoice oi 
		 ON SUBSTRING(arinpchg.doc_ctrl_num,1,10) = oi.doc_ctrl_num
	LEFT OUTER JOIN ord_list ol ON oi.order_no = ol.order_no AND oi.order_ext = ol.order_ext
  where
	arinpcdt.trx_ctrl_num = arinpchg.trx_ctrl_num
	and	arinpchg.trx_type <= 2031  	
	and arinpchg.order_ctrl_num > ' '
 	


GO
GRANT SELECT ON  [dbo].[arin2_unpost_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[arin2_unpost_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[arin2_unpost_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[arin2_unpost_vw] TO [public]
GO
