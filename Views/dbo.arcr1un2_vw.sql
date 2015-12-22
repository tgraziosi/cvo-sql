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






CREATE view [dbo].[arcr1un2_vw] as
  select 
  	gl_trx_id="",		
	t3.org_id,
	t2.address_name,	 
	t2.customer_code, 	
	t3.doc_desc,		
	t1.doc_ctrl_num, 	
	t1.trx_ctrl_num,
	void_flag='No',		 
	hold_flag='No',		
	posted_flag='No',		
	payment_amt=t1.amt_payment, 	
				
	t1.date_doc,		
	t3.date_applied,	
	t3.nat_cur_code,	
	deposit_num="",		
	t1.payment_code,	
	date_posted=NULL	
  from 
	arinptmp t1 (nolock), armaster t2 (nolock) , arinpchg t3 (nolock)
  where 
	t1.customer_code = t2.customer_code
  and 	t2.address_type = 0
  and	t3.trx_type in (2031) 	
  and 	t3.trx_ctrl_num = t1.trx_ctrl_num


/**/                                              

GO
GRANT REFERENCES ON  [dbo].[arcr1un2_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[arcr1un2_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[arcr1un2_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[arcr1un2_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[arcr1un2_vw] TO [public]
GO
