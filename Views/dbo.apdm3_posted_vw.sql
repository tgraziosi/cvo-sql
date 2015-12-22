SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

create view [dbo].[apdm3_posted_vw] as
  select
  	apdmhdr.vendor_code, 
	debit_memo_no=apdmdet.trx_ctrl_num,
	apdmdet.org_id,
	sequence_id,  
	location_code, 
	item_code,     
	line_desc,     
	qty_received,   
	unit_code,     
	unit_price,    
	qty_returned,        
	apdmdet.tax_code,       
	gl_exp_acct,
	apdmdet.amt_discount,   
	amt_extended,
	nat_cur_code=apdmhdr.currency_code,
	apdmhdr.date_applied

  from 
	apdmdet apdmdet, apdmhdr apdmhdr
  where
	apdmdet.trx_ctrl_num = apdmhdr.trx_ctrl_num
GO
GRANT SELECT ON  [dbo].[apdm3_posted_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[apdm3_posted_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[apdm3_posted_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[apdm3_posted_vw] TO [public]
GO
