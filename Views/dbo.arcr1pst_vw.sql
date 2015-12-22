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





CREATE view [dbo].[arcr1pst_vw] as
  select 
  	t1.gl_trx_id,		
	t1.org_id,		
	t2.address_name,	 
	t2.customer_code, 	
 	t1.doc_desc,		
	t1.doc_ctrl_num, 	
	t1.trx_ctrl_num, 
	void_flag = case t1.void_flag
		when 0 then 'No'
		when 1 then 'Yes'
	end,		 
	hold_flag='No',		
	posted_flag = case t1.posted_flag
		when 0 then 'No'
		when 1 then 'Yes'
	end,		
	payment_amt=t1.amt_net, 		
				
	t1.date_doc,		
	t1.date_applied,	
	t1.nat_cur_code,	
	t1.deposit_num,		
	t1.payment_code,	
	t1.date_posted		
  from 
	artrx t1 (nolock) join armaster t2 (nolock) on t1.customer_code = t2.customer_code
  where 
--	t1.customer_code = t2.customer_code
--	and 
	t1.trx_type in (2111) 
	and t1.payment_type in (1) 	
					
					
					
					
					
	and t2.address_type = 0

/**/                                              

GO
GRANT REFERENCES ON  [dbo].[arcr1pst_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[arcr1pst_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[arcr1pst_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[arcr1pst_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[arcr1pst_vw] TO [public]
GO
