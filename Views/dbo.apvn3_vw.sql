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



  
  

  

CREATE VIEW [dbo].[apvn3_vw] as 

SELECT 	
	 		t1.address_name, 			
	 	 	t1.vendor_code,	
			t1.pay_to_code,				
	 		t1.contact_name, 		
	 		t1.contact_phone, 			 		
	 		t1.branch_code,				 	
	 		t1.vend_class_code, 			 		
	 		t1.nat_cur_code,			 		
	 
			open_balance = isnull(t2.amt_balance , 0.0), 
	 							
	 		t1.credit_limit,	

			avail_credit_amt = isnull(
				t1.limit_by_home * ( t1.credit_limit - isnull(t2.amt_balance , 0.0)) +
	                        (1 - t1.limit_by_home) * ( t1.credit_limit - isnull(t2.amt_balance_oper , 0.0)), 0.0),
			t3.status_code,

			x_open_balance = isnull(t2.amt_balance , 0.0), 
	 							
	 		x_credit_limit=t1.credit_limit,	

			x_avail_credit_amt = isnull(
				t1.limit_by_home * ( t1.credit_limit - isnull(t2.amt_balance , 0.0)) +
	 (1 - t1.limit_by_home) * ( t1.credit_limit - isnull(t2.amt_balance_oper , 0.0)), 0.0)

	 	FROM 
	 		apmaster t1, 
	 		apactvnd t2,
	 		apstat 	t3
	 
 
	 	WHERE 
	 		(t1.vendor_code = t2.vendor_code) 
	 		AND (t1.status_type = t3.status_type)
	 		AND t1.address_type = 0 
	 
GO
GRANT REFERENCES ON  [dbo].[apvn3_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[apvn3_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[apvn3_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[apvn3_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[apvn3_vw] TO [public]
GO
