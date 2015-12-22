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



























CREATE VIEW [dbo].[ibcustaccess_vw] AS

	SELECT
		acc.organization_id,
		cus.address_name,
		cus.customer_code,
		cus.contact_name,
		cus.contact_phone,
		cus.territory_code,
		cus.price_code,
		cus.nat_cur_code,
		cus.open_balance,
		cus.amt_on_acct,
		cus.net_balance,
		cus.credit_limit,
		cus.avail_credit_amt,
		cus.date_opened,
		cus.status_code,
		cus.shipped_flag,
		x_open_balance = cus.open_balance,
		x_amt_on_acct = cus.amt_on_acct,
		x_net_balance = cus.net_balance,
		x_credit_limit =cus. credit_limit,
		x_avail_credit_amt = cus.avail_credit_amt,
		x_date_opened = cus.date_opened
	FROM sm_customers_access_co_2_vw acc INNER JOIN arcus_vw cus ON acc.customer_code = cus.customer_code	
/**/                                              
GO
GRANT REFERENCES ON  [dbo].[ibcustaccess_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[ibcustaccess_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[ibcustaccess_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[ibcustaccess_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[ibcustaccess_vw] TO [public]
GO
