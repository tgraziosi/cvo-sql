SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

create view [dbo].[arcm3_posted_vw] as
  select
  	artrx.customer_code, 
	artrxcdt.doc_ctrl_num,
	artrxcdt.org_id,
	sequence_id,  
	location_code, 
	item_code,     
	line_desc,     
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
  and	artrx.trx_type = 2032  	
GO
GRANT SELECT ON  [dbo].[arcm3_posted_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[arcm3_posted_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[arcm3_posted_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[arcm3_posted_vw] TO [public]
GO
