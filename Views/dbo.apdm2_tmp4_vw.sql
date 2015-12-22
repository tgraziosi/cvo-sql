SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

create view [dbo].[apdm2_tmp4_vw] as
  select 
	t2.vendor_name,		 
	t2.vendor_code, 	
	debit_memo_no=t1.doc_ctrl_num, 	
						
	t3.org_id,		
	pyt_posted_flag=1,	
	pyt_hold_flag=0,	
	t1.date_doc,		
	voucher_no=t3.trx_ctrl_num,	
						     
	vo_posted_flag=t3.posted_flag,		
						
	vo_hold_flag=t3.hold_flag,		
												
	vo_approval_flag=t3.approval_flag,
						
	t3.nat_cur_code,	
	payment_amt=t3.amt_paid,		
						
	t1.amt_disc_taken,	
						
	payment_desc=t1.trx_desc		
						
	
  from
    apinptmp t1, apvend t2, apinpchg t3
  where 
	t3.vendor_code = t2.vendor_code
  and	t3.trx_type in (4091) 	
  and 	t1.payment_type in (3)
  and 	t1.trx_ctrl_num = t3.trx_ctrl_num
  
GO
GRANT SELECT ON  [dbo].[apdm2_tmp4_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[apdm2_tmp4_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[apdm2_tmp4_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[apdm2_tmp4_vw] TO [public]
GO
