SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

create view [dbo].[apvo2_unpost_vw] as
  select                

	voucher_no=apinpcdt.trx_ctrl_num,
	apinpcdt.org_id,		
	sequence_id,  			
	apinpcdt.location_code, 	
	item_code,                      
	line_desc,                      
	qty_ordered,                    
	qty_received,                       
	unit_code,                          
	apinpchg.nat_cur_code,              
	unit_price,                         
	apinpcdt.amt_discount,              
	apinpcdt.amt_freight,               
	apinpcdt.amt_tax,                   
	apinpcdt.amt_misc,                  
	amt_extended,                       
	rec_company_code=ISNULL(NULLIF(new_rec_company_code,''), rec_company_code),
					
	gl_exp_acct=ISNULL(NULLIF(new_gl_exp_acct,''), gl_exp_acct),
					
	reference_code=ISNULL(NULLIF(new_reference_code,''), reference_code),
					
	code_1099,                          
	apinpcdt.tax_code,                  
  	apinpchg.vendor_code,                
	apinpchg.date_applied,
	apinpcdt.po_ctrl_num
  from 
	apinpcdt apinpcdt, apinpchg apinpchg
  where
		apinpcdt.trx_ctrl_num = apinpchg.trx_ctrl_num
  and	apinpchg.trx_type = 4091    	
GO
GRANT SELECT ON  [dbo].[apvo2_unpost_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[apvo2_unpost_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[apvo2_unpost_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[apvo2_unpost_vw] TO [public]
GO
