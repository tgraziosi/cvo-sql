SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

create view [dbo].[arcm2_tmp5_vw] as
  select 
	t2.address_name,	 
	t2.customer_code, 	
	t1.doc_ctrl_num, 	     
	t1.trx_ctrl_num, 	
	t1.org_id,		
	pyt_void_flag=0,	
	pyt_posted_flag=0,	
	pyt_hold_flag=t1.hold_flag,	
				
	t1.date_doc,		
	invoice_no=t1.apply_to_num,	
				     
	inv_posted_flag=t4.posted_flag,		
				
	inv_hold_flag=0,							
	t1.nat_cur_code,	
	payment_amt=t1.amt_net,	
	amt_write_off=t1.amt_write_off_given,	
				
				
	amt_disc_taken=t1.amt_discount_taken,	
				
	payment_desc=t1.doc_desc		
				
	
  from 
	arinpchg t1, armaster t2, artrx_inv_vw t4
  where 
	t1.customer_code = t2.customer_code
  and 	t2.address_type = 0
  and 	t1.trx_type in (2032) 
  and	t1.apply_to_num <> "" 
  and	t1.printed_flag = 1
  and 	t1.apply_to_num 	= t4.doc_ctrl_num
  and 	t1.customer_code 	= t4.customer_code
  
GO
GRANT SELECT ON  [dbo].[arcm2_tmp5_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[arcm2_tmp5_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[arcm2_tmp5_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[arcm2_tmp5_vw] TO [public]
GO
