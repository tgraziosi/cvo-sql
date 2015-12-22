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



























CREATE VIEW [dbo].[vendbyuser_vw]
AS

	SELECT
		v.user_name,
		address_name,
		v.vendor_code,
		pay_to_code,
		contact_name,
		contact_phone,
		branch_code,
		vend_class_code,
		nat_cur_code,
		open_balance,
		credit_limit,
		avail_credit_amt,
		status_code,
		x_open_balance,
		x_credit_limit,
		x_avail_credit_amt
	FROM
		sm_vendors_access_2_vw v INNER JOIN apvn3_vw o ON v.vendor_code = o.vendor_code
/**/                                              
GO
GRANT REFERENCES ON  [dbo].[vendbyuser_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[vendbyuser_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[vendbyuser_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[vendbyuser_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[vendbyuser_vw] TO [public]
GO
