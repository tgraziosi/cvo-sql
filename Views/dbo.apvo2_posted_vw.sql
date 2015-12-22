SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

create view [dbo].[apvo2_posted_vw] as

  select 
	voucher_no=apvodet.trx_ctrl_num,	
					
	apvodet.org_id,			
	sequence_id,  			
	apvodet.location_code, 		
	item_code,                      
	line_desc,                      
	qty_ordered,                    
	qty_received,                   
	unit_code,                      
	nat_cur_code=apvohdr.currency_code,             
					
	unit_price,                     
	apvodet.amt_discount,		
	apvodet.amt_freight,            
	apvodet.amt_tax,                
	apvodet.amt_misc,               
	amt_extended,                   
	rec_company_code,		
	gl_exp_acct,			
	reference_code,			
	code_1099,                      
	apvodet.tax_code,               
  	apvohdr.vendor_code,               
	apvohdr.date_applied,
	apvodet.po_ctrl_num

  from 
	apvodet apvodet, apvohdr apvohdr
  where
	apvodet.trx_ctrl_num = apvohdr.trx_ctrl_num
GO
GRANT SELECT ON  [dbo].[apvo2_posted_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[apvo2_posted_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[apvo2_posted_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[apvo2_posted_vw] TO [public]
GO
