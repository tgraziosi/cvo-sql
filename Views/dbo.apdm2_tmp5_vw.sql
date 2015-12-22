SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

create view [dbo].[apdm2_tmp5_vw] as
  select 
	t2.vendor_name,		 
	t2.vendor_code, 	
	debit_memo_no=t1.trx_ctrl_num, 	
						
	t1.org_id,		
	pyt_posted_flag=0,	
	pyt_hold_flag=t1.hold_flag,	
						
	t1.date_doc,		
	voucher_no=t1.apply_to_num,	
						     
	vo_posted_flag=t4.posted_flag,		
						
	vo_hold_flag=0,								
	vo_approval_flag=0,	
	t1.nat_cur_code,	
	payment_amt=t1.amt_net,		
						
	amt_disc_taken=t1.amt_discount,	
						
	payment_desc=t1.doc_desc		
						
	
  from 
	apinpchg t1, apvend t2, apvohdr_vw t4
  where 
	t1.vendor_code = t2.vendor_code
  and 	t1.trx_type in (4092) 
  and	t1.apply_to_num <> "" 
  and 	t1.apply_to_num 	= t4.voucher_no
  and 	t1.vendor_code 		= t4.vendor_code
  
GO
GRANT SELECT ON  [dbo].[apdm2_tmp5_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[apdm2_tmp5_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[apdm2_tmp5_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[apdm2_tmp5_vw] TO [public]
GO
