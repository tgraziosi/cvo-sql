SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

create view [dbo].[arin2_vw] as
  select
  	customer_code, 
	doc_ctrl_num,
	trx_ctrl_num,
	org_id,
	sequence_id,  
	location_code, 
	item_code,     
	line_desc,     
	qty_ordered,   
	qty_shipped,   
	qty_returned,        
	unit_code,     
	unit_price,    
	tax_code,       
	gl_rev_acct,
	discount_amt,   
	disc_prc_flag = case disc_prc_flag
		when 0 then 'No'
		when 1 then 'Yes'
	end,    
	extended_price,
	nat_cur_code,
	date_applied,

	x_sequence_id=sequence_id, 
	x_qty_ordered=qty_ordered, 
	x_qty_shipped=qty_shipped, 
	x_qty_returned=qty_returned, 
	x_unit_price=unit_price, 
	x_discount_amt=discount_amt, 
	x_extended_price=extended_price,
	x_date_applied=date_applied

  from
  	arin2_posted_vw

  UNION 	
  select 
  	customer_code, 
	doc_ctrl_num,
	trx_ctrl_num,
	org_id,
	sequence_id,  
	location_code, 
	item_code,     
	line_desc,     
	qty_ordered,   
	qty_shipped,   
	qty_returned,        
	unit_code,     
	unit_price,    
	tax_code,       
	gl_rev_acct,
	discount_amt,   
	disc_prc_flag = case disc_prc_flag
		when 0 then 'No'
		when 1 then 'Yes'
	end,    
	extended_price,
	nat_cur_code,
	date_applied,

	x_sequence_id=sequence_id, 
	x_qty_ordered=qty_ordered, 
	x_qty_shipped=qty_shipped, 
	x_qty_returned=qty_returned, 
	x_unit_price=unit_price, 
	x_discount_amt=discount_amt, 
	x_extended_price=extended_price,
	x_date_applied=date_applied

  from
  	arin2_unpost_vw

GO
GRANT REFERENCES ON  [dbo].[arin2_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[arin2_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[arin2_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[arin2_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[arin2_vw] TO [public]
GO
