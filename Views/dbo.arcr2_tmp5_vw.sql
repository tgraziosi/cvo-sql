SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

create view [dbo].[arcr2_tmp5_vw] as
 select 
	t2.address_name,
	t3.org_id,	 
	t2.customer_code, 	
	t1.doc_ctrl_num, 	 
	t1.trx_ctrl_num, 	
	pyt_void_flag=0,	
	pyt_posted_flag=0,	
	pyt_hold_flag=0,	
	t1.date_doc,		
	invoice_no=t3.doc_ctrl_num,	
						
	inv_posted_flag=0,	
	inv_hold_flag=t3.hold_flag,	
												
	t3.nat_cur_code,	
						
	payment_amt=t1.amt_payment,		
						 
						
	amt_write_off=NULL,		
						
						
						
	t1.amt_disc_taken,	
						
	payment_desc=t1.trx_desc		
						

 from
 arinptmp t1, armaster t2, arinpchg t3
 where 
	t3.customer_code = t2.customer_code
 and 	t2.address_type = 0
 and	t3.trx_type in (2021,2031)		
						
 and 	t1.trx_ctrl_num = t3.trx_ctrl_num
GO
GRANT REFERENCES ON  [dbo].[arcr2_tmp5_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[arcr2_tmp5_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[arcr2_tmp5_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[arcr2_tmp5_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[arcr2_tmp5_vw] TO [public]
GO
