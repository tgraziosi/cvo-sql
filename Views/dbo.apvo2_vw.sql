SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

create view [dbo].[apvo2_vw] as
  select
	voucher_no,			
	org_id,				
	sequence_id,  						
	location_code, 						
	item_code,                          
	line_desc,                          
	qty_ordered,                        
	qty_received,                       
	unit_code,                          
	nat_cur_code,                		
	unit_price,                         
	amt_discount,             			
	amt_freight,               			
	amt_tax,                   			
	amt_misc,                  			
	amt_extended,                       
	rec_company_code,					
	cast(gl_exp_acct as varchar(36)) as gl_exp_acct,	
	reference_code,						
	code_1099,                          
	tax_code,                  			
  	vendor_code,                   		
  	date_applied,
	po_ctrl_num,

	x_qty_ordered=qty_ordered, 
	x_qty_received=qty_received, 
	x_unit_price=unit_price, 
	x_amt_discount=amt_discount, 			
	x_amt_freight=amt_freight, 			
	x_amt_tax=amt_tax, 			
	x_amt_misc=amt_misc, 			
	x_amt_extended=amt_extended, 
 	x_date_applied=date_applied


  from
  	apvo2_posted_vw

  UNION 	

  select 

	voucher_no,				
	org_id,					
	sequence_id,  				
	location_code, 				
	item_code,                          
	line_desc,                          
	qty_ordered,                        
	qty_received,                       
	unit_code,                          
	nat_cur_code,                		
	unit_price,                         
	amt_discount,             			
	amt_freight,               			
	amt_tax,                   			
	amt_misc,                  			
	amt_extended,                       
	rec_company_code,					
	cast(gl_exp_acct as varchar(36)) as gl_exp_acct,	
	reference_code,						
	code_1099,                          
	tax_code,                  			
  	vendor_code,                   		
 	date_applied,
	po_ctrl_num,

	x_qty_ordered=qty_ordered, 
	x_qty_received=qty_received, 
	x_unit_price=unit_price, 
	x_amt_discount=amt_discount, 			
	x_amt_freight=amt_freight, 			
	x_amt_tax=amt_tax, 			
	x_amt_misc=amt_misc, 			
	x_amt_extended=amt_extended, 
 	x_date_applied=date_applied


  from
  	apvo2_unpost_vw

GO
GRANT REFERENCES ON  [dbo].[apvo2_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[apvo2_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[apvo2_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[apvo2_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[apvo2_vw] TO [public]
GO
