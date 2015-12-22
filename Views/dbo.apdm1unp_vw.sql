SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2002 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2002 Epicor Software Corporation, 2002    
                  All Rights Reserved                    
*/                                                




create view [dbo].[apdm1unp_vw]  as
  select 
	t2.vendor_name,		 
	t2.vendor_code,		
	t1.pay_to_code,		
	debit_memo_no=t1.trx_ctrl_num, 	
				
	org_id,			
	posted_flag = 'No',	
	hold_flag = case t1.hold_flag
		when 0 then 'No'
		when 1 then 'Yes'
	end,			
	t1.nat_cur_code,	
	t1.amt_net, 		
	gl_trx_id="",								
	t1.date_doc, 		
	t1.date_applied,	
	t1.po_ctrl_num,		
				
				
	t1.doc_ctrl_num		
				
				

  from 
	apinpchg t1, apvend t2
  where (t1.vendor_code = t2.vendor_code) 
	and t1.trx_type in (4092)		
/**/                                              
GO
GRANT REFERENCES ON  [dbo].[apdm1unp_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[apdm1unp_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[apdm1unp_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[apdm1unp_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[apdm1unp_vw] TO [public]
GO
