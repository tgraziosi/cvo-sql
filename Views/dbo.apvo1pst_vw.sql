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




create view [dbo].[apvo1pst_vw] as

 select 
	address_name=t2.vendor_name,				 
	t2.vendor_code,					
	voucher_no=t1.trx_ctrl_num, 	
	approval_flag='No',													
	hold_flag='No',					
	posted_flag='Yes',					
	nat_cur_code=t1.currency_code,				
	t1.amt_net, 					
	amt_paid=t1.amt_paid_to_date,	
	amt_open=t1.amt_net - t1.amt_paid_to_date, 
	t1.date_doc, 					
	t1.date_applied,				
	t1.date_due,					
	t1.date_discount,				
	invoice_no=t1.doc_ctrl_num, 	
	t1.po_ctrl_num, 				
 	gl_trx_id=t1.journal_ctrl_num,
	t1.batch_code				

 from 
	apvohdr t1, apvend t2
 where 
	t1.vendor_code = t2.vendor_code 
/**/                                              
GO
GRANT REFERENCES ON  [dbo].[apvo1pst_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[apvo1pst_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[apvo1pst_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[apvo1pst_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[apvo1pst_vw] TO [public]
GO
