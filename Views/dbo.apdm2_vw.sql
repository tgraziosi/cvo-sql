SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

create view [dbo].[apdm2_vw] as
	select
		vendor_name,		 
		vendor_code, 		
		debit_memo_no, 		
		org_id,			
		pyt_posted_flag = case pyt_posted_flag
			when 0 then 'No'
			when 1 then 'Yes'
		end,	
		pyt_hold_flag = case pyt_hold_flag
			when 0 then 'No'
			when 1 then 'Yes'
		end,		
		voucher_no,			
		vo_posted_flag = case vo_posted_flag
			when 0 then 'No'
			when 1 then 'Yes'
		end,		
		vo_hold_flag = case vo_hold_flag
			when 0 then 'No'
			when 1 then 'Yes'
		end,								
		vo_approval_flag = case vo_approval_flag
			when 0 then 'No'
			when 1 then 'Yes'
		end,	
		date_doc,			
		nat_cur_code,		
		payment_amt,		 
							
		amt_disc_taken,		
							
		payment_desc,		

		x_date_doc=date_doc,			
		x_payment_amt=payment_amt,		 
							
		x_amt_disc_taken=amt_disc_taken		


	from
		apdm2_tmp2_vw

	UNION				
	select
		vendor_name,		 
		vendor_code, 		
		debit_memo_no, 		
		org_id,			
		pyt_posted_flag = case pyt_posted_flag
			when 0 then 'No'
			when 1 then 'Yes'
		end,	
		pyt_hold_flag = case pyt_posted_flag
			when 0 then 'No'
			when 1 then 'Yes'
		end,		
		voucher_no,			
		vo_posted_flag = case vo_posted_flag
			when 0 then 'No'
			when 1 then 'Yes'
		end,		
		vo_hold_flag = case vo_hold_flag
			when 0 then 'No'
			when 1 then 'Yes'
		end,								
		vo_approval_flag = case vo_approval_flag
			when 0 then 'No'
			when 1 then 'Yes'
		end,	
		date_doc,			
		nat_cur_code,		
		payment_amt,		 
							
		amt_disc_taken,		
							
		payment_desc,		

		x_date_doc=date_doc,			
		x_payment_amt=payment_amt,		 
							
		x_amt_disc_taken=amt_disc_taken		


	from
		apdm2_tmp4_vw

	UNION				
	select
		vendor_name,		 
		vendor_code, 		
		debit_memo_no, 		
		org_id,			
		pyt_posted_flag = case pyt_posted_flag
			when 0 then 'No'
			when 1 then 'Yes'
		end,	
		pyt_hold_flag = case pyt_hold_flag
			when 0 then 'No'
			when 1 then 'Yes'
		end,		
		voucher_no,			
		vo_posted_flag = case vo_posted_flag
			when 0 then 'No'
			when 1 then 'Yes'
		end,		
		vo_hold_flag = case vo_hold_flag
			when 0 then 'No'
			when 1 then 'Yes'
		end,								
		vo_approval_flag = case vo_approval_flag
			when 0 then 'No'
			when 1 then 'Yes'
		end,	
		date_doc,			
		nat_cur_code,		
		payment_amt,		 
							
		amt_disc_taken,		
							
		payment_desc,		

		x_date_doc=date_doc,			
		x_payment_amt=payment_amt,		 
							
		x_amt_disc_taken=amt_disc_taken		

	from
		apdm2_tmp5_vw

GO
GRANT REFERENCES ON  [dbo].[apdm2_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[apdm2_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[apdm2_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[apdm2_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[apdm2_vw] TO [public]
GO
