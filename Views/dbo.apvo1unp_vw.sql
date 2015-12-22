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




create view [dbo].[apvo1unp_vw] as

 select 
	t2.address_name,				 
	t2.vendor_code,					
	voucher_no=t1.trx_ctrl_num, 	
	approval_flag = case t1.approval_flag
		when 0 then 'No'
		when 1 then 'Yes'
	end,													
	hold_flag = case t1.hold_flag
		when 0 then 'No'
		when 1 then 'Yes'
	end,					
	posted_flag='No',					
	t1.nat_cur_code,				
	t1.amt_net, 					
	amt_paid=t1.amt_paid,			
	amt_open=t1.amt_net - t1.amt_paid, 
	t1.date_doc, 					
	t1.date_applied,				
	t1.date_due,					
	t1.date_discount,				
	invoice_no=t1.doc_ctrl_num, 	
	t1.po_ctrl_num, 				
 	gl_trx_id="",
	t1.batch_code					

 from 
	apinpchg t1, apmaster t2
 where 
	t1.vendor_code = t2.vendor_code 
	and t2.address_type = 0
	and t1.trx_type in (4091)

/**/                                              
GO
GRANT REFERENCES ON  [dbo].[apvo1unp_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[apvo1unp_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[apvo1unp_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[apvo1unp_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[apvo1unp_vw] TO [public]
GO
