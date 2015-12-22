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



























CREATE VIEW [dbo].[custbyuser_vw]
AS
SELECT 
	a.user_name,
	address_name,
	a.customer_code,
	contact_name,
	contact_phone,
	territory_code,
	price_code,
	nat_cur_code,
	open_balance,
	amt_on_acct,
	net_balance,
	credit_limit,
	avail_credit_amt,
	date_opened,
	status_code,
	shipped_flag,
	x_open_balance,
	x_amt_on_acct,
	x_net_balance,
	x_credit_limit,
	x_avail_credit_amt,
	x_date_opened  
FROM 
	sm_customers_access_2_vw a INNER JOIN arcus_vw v ON a.customer_code = v.customer_code
/**/                                              
GO
GRANT REFERENCES ON  [dbo].[custbyuser_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[custbyuser_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[custbyuser_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[custbyuser_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[custbyuser_vw] TO [public]
GO
