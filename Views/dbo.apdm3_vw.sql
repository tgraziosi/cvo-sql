SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

create view [dbo].[apdm3_vw] as
  select
  	vendor_code, 
	debit_memo_no,
	org_id,
	sequence_id,  
	location_code, 
	item_code,     
	line_desc,     
	qty_received,   
	qty_returned,        
	unit_code,     
	unit_price,    
	tax_code,       
	gl_exp_acct,
	amt_discount,   
	amt_extended,
	nat_cur_code,
	date_applied, 

	x_sequence_id=sequence_id, 
	x_qty_received=qty_received, 
	x_unit_price=unit_price, 
	x_qty_returned=qty_returned, 
	x_amt_discount=amt_discount, 
	x_amt_extended=amt_extended,
	x_date_applied=date_applied
   
  from
  	apdm3_posted_vw

  UNION 	
  select 
  	vendor_code, 
	debit_memo_no,
	org_id,
	sequence_id,  
	location_code, 
	item_code,     
	line_desc,     
	qty_received,   
	qty_returned,        
	unit_code,     
	unit_price,    
	tax_code,       
	gl_exp_acct,
	amt_discount,   
	amt_extended,
	nat_cur_code,
	date_applied, 

	x_sequence_id=sequence_id, 
	x_qty_received=qty_received, 
	x_unit_price=unit_price, 
	x_qty_returned=qty_returned, 
	x_amt_discount=amt_discount, 
	x_amt_extended=amt_extended,
	x_date_applied=date_applied

  from
  	apdm3_unpost_vw

GO
GRANT REFERENCES ON  [dbo].[apdm3_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[apdm3_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[apdm3_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[apdm3_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[apdm3_vw] TO [public]
GO
