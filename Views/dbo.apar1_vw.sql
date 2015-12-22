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





CREATE VIEW [dbo].[apar1_vw] AS
SELECT 
	arcust.customer_code,
	customer_open_amount=aractcus.amt_balance,
	apvend.vendor_code,
	vendor_open_amount=apactvnd.amt_balance,
	difference=ABS(aractcus.amt_balance - apactvnd.amt_balance),

	x_customer_open_amount=aractcus.amt_balance,
	x_vendor_open_amount=apactvnd.amt_balance,
	x_difference=ABS(aractcus.amt_balance - apactvnd.amt_balance)

	
FROM 	arcust
		LEFT OUTER JOIN aractcus ON (arcust.customer_code = aractcus.customer_code) 
		LEFT OUTER JOIN apactvnd ON (arcust.vendor_code   = apactvnd.vendor_code),
	apvend
WHERE
	arcust.vendor_code   =  apvend.vendor_code
AND	arcust.customer_code =  apvend.customer_code
  	  
  	  
 
/**/                                              
GO
GRANT REFERENCES ON  [dbo].[apar1_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[apar1_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[apar1_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[apar1_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[apar1_vw] TO [public]
GO
