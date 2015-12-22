SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[povchgen_vw]
   AS SELECT	match_ctrl_num,   
	vendor_code,  
	vendor_remit_to, 
	vendor_invoice_no,    
	date_match,  
	tolerance_hold_flag,
	tolerance_approval_flag,
	validated_flag, 
	vendor_invoice_date, 
	invoice_receive_date, 
	apply_date,  
	aging_date,  
	due_date,    
	discount_date, 
	amt_net,                                               
	amt_discount,                                          
	amt_tax,                                               
	amt_freight,                                           
	amt_misc,                                              
	amt_due,                                               
	match_posted_flag, 
	amt_tax_included,                                      
	trx_ctrl_num,     
	nat_cur_code,
	rate_type_home,
	rate_type_oper,
	rate_home,
	rate_oper                                             
FROM	epmchhdr 
WHERE	match_posted_flag = 0
AND	( ( tolerance_hold_flag = 0 ) OR tolerance_approval_flag = 1  ) 
AND	( validated_flag = 1 )

	
GO
GRANT REFERENCES ON  [dbo].[povchgen_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[povchgen_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[povchgen_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[povchgen_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[povchgen_vw] TO [public]
GO
