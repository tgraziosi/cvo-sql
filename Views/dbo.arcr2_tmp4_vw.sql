SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

create view [dbo].[arcr2_tmp4_vw] as
 select 
	t2.address_name,	
	t3.org_id, 
	t2.customer_code, 	
	t1.doc_ctrl_num, 	 
	t1.trx_ctrl_num, 	
	pyt_void_flag=0,	
	pyt_posted_flag=0,	
	pyt_hold_flag=t3.hold_flag,	
						
	t3.date_doc,		
	invoice_no=t1.apply_to_num,	
						 
	inv_posted_flag=t4.posted_flag,		
						
	inv_hold_flag=0,							
	t3.nat_cur_code,	
	payment_amt=t1.amt_applied,		
						
	amt_write_off=t1.amt_max_wr_off,	
						
						
	t1.amt_disc_taken,	
						
	payment_desc=t1.line_desc		
						
	
 from 
	arinppdt t1, armaster t2, arcr2_tmp3_vw t3, artrx_inv_vw t4
 where 
	t2.customer_code = t3.customer_code
 and 	t2.address_type = 0
 and 	t1.trx_type in (2111) 	
								
 and 	t1.doc_ctrl_num 	= t3.doc_ctrl_num
 and	t1.trx_ctrl_num		= t3.trx_ctrl_num
 and 	t1.apply_to_num 	= t4.doc_ctrl_num
 and	t3.payment_type in (1,2)	
 
GO
GRANT REFERENCES ON  [dbo].[arcr2_tmp4_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[arcr2_tmp4_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[arcr2_tmp4_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[arcr2_tmp4_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[arcr2_tmp4_vw] TO [public]
GO
