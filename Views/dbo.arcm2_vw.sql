SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

create view [dbo].[arcm2_vw] as
	select
		address_name,		 
		customer_code, 		
		doc_ctrl_num, 		     
		trx_ctrl_num, 		
		org_id,			
		pyt_void_flag = case pyt_void_flag
			when 0 then 'No'
			when 1 then 'Yes'
		end,			
		pyt_posted_flag = case pyt_posted_flag
			when 0 then 'No'
			when 1 then 'Yes'
		end,			
		pyt_hold_flag = case pyt_hold_flag
			when 0 then 'No'
			when 1 then 'Yes'
		end,			
		date_doc,		
		invoice_no,		
		inv_posted_flag = case inv_posted_flag
			when 0 then 'No'
			when 1 then 'Yes'
		end,			
		inv_hold_flag = case inv_hold_flag
			when 0 then 'No'
			when 1 then 'Yes'
		end,									
					
		nat_cur_code,		
		payment_amt,		 
					
		amt_write_off,		
					
					
		amt_disc_taken,		
					
		payment_desc,		

		x_date_doc=date_doc,		
		x_payment_amt=payment_amt,		 
		x_amt_write_off=amt_write_off,		
		x_amt_disc_taken=amt_disc_taken		
	from
		arcm2_tmp2_vw
	UNION				
	select
		address_name,		 
		customer_code, 		
		doc_ctrl_num, 		     
		trx_ctrl_num, 		
		org_id,			
		pyt_void_flag = case pyt_void_flag
			when 0 then 'No'
			when 1 then 'Yes'
		end,			
		pyt_posted_flag = case pyt_posted_flag
			when 0 then 'No'
			when 1 then 'Yes'
		end,			
		pyt_hold_flag = case pyt_hold_flag
			when 0 then 'No'
			when 1 then 'Yes'
		end,			
		date_doc,		
		invoice_no,	 	
		inv_posted_flag = case inv_posted_flag
			when 0 then 'No'
			when 1 then 'Yes'
		end,			
		inv_hold_flag = case inv_hold_flag
			when 0 then 'No'
			when 1 then 'Yes'
		end,									
		nat_cur_code,		
					
		payment_amt,		 
					
		amt_write_off,		
					
					
		amt_disc_taken,		
					
		payment_desc,		

		x_date_doc=date_doc,		
		x_payment_amt=payment_amt,		 
		x_amt_write_off=amt_write_off,		
		x_amt_disc_taken=amt_disc_taken		

	from
		arcm2_tmp4_vw
	UNION				
	select
		address_name,		 
		customer_code, 		
		doc_ctrl_num, 		     
		trx_ctrl_num, 		
		org_id,			
		pyt_void_flag = case pyt_void_flag
			when 0 then 'No'
			when 1 then 'Yes'
		end,			
		pyt_posted_flag = case pyt_posted_flag
			when 0 then 'No'
			when 1 then 'Yes'
		end,			
		pyt_hold_flag = case pyt_hold_flag
			when 0 then 'No'
			when 1 then 'Yes'
		end,			
		date_doc,		
		invoice_no,	 	
		inv_posted_flag = case inv_posted_flag
			when 0 then 'No'
			when 1 then 'Yes'
		end,			
		inv_hold_flag = case inv_hold_flag
			when 0 then 'No'
			when 1 then 'Yes'
		end,									
		nat_cur_code,		
					
		payment_amt,		 
					
		amt_write_off,		
					
					
		amt_disc_taken,		
					
		payment_desc,		

		x_date_doc=date_doc,		
		x_payment_amt=payment_amt,		 
		x_amt_write_off=amt_write_off,		
		x_amt_disc_taken=amt_disc_taken		

	from
		arcm2_tmp5_vw

GO
GRANT REFERENCES ON  [dbo].[arcm2_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[arcm2_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[arcm2_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[arcm2_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[arcm2_vw] TO [public]
GO
