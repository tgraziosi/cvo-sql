SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

create view [dbo].[apdm2_tmp2_vw] as
  select 
	t2.vendor_name,		 
	t2.vendor_code, 	
	t3.debit_memo_no, 	
	t3.org_id,		
	pyt_posted_flag=1,	
	pyt_hold_flag=0,	
	t3.date_doc,		
	voucher_no=t1.apply_to_num,	
						 
	vo_posted_flag=t4.posted_flag,		
						       
	vo_hold_flag=0,								
	vo_approval_flag=0,	
	t3.nat_cur_code,	
	payment_amt=t1.amt_applied,		
						
	t1.amt_disc_taken,	
	payment_desc=t1.line_desc		
						
	
  from 
	appydet t1, apvend t2, apdmhdr_vw t3, apvohdr_vw t4
  where 
	t2.vendor_code 			= t3.vendor_code
	and t1.apply_to_num	 	= t3.apply_to_num
	and t3.vendor_code 		= t3.vendor_code     
	and t3.apply_to_num  		= t4.voucher_no
GO
GRANT SELECT ON  [dbo].[apdm2_tmp2_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[apdm2_tmp2_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[apdm2_tmp2_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[apdm2_tmp2_vw] TO [public]
GO
