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



























CREATE VIEW [dbo].[ibvendaccess_vw]
AS

	SELECT
		a.organization_id,
		v.address_name,
		a.vendor_code,
		v.pay_to_code,
		v.contact_name,
		v.contact_phone,
		v.branch_code,
		v.vend_class_code,
		v.nat_cur_code,
		v.open_balance,
		v.credit_limit,
		v.avail_credit_amt,
		v.status_code,
		v.x_open_balance,
		v.x_credit_limit,
		v.x_avail_credit_amt
	FROM
		sm_vendors_access_co_2_vw a INNER JOIN apvn3_vw v ON a.vendor_code = v.vendor_code
GO
GRANT REFERENCES ON  [dbo].[ibvendaccess_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[ibvendaccess_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[ibvendaccess_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[ibvendaccess_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[ibvendaccess_vw] TO [public]
GO
