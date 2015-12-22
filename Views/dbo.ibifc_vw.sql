SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2002 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2002 Epicor Software Corporation, 2002    
                  All Rights Reserved                    
*/                                                

CREATE VIEW [dbo].[ibifc_vw] AS
	SELECT  CONVERT(varchar(36),id) id,
		date_entered,
		date_applied,
		t.description trx_type_desc,
 		i.controlling_org_id,
             	i.detail_org_id,
	        CONVERT(float,amount) amount,
                currency_code,
 		recipient_code,
	        originator_code,
                tax_payable_code,
                tax_expense_code,
		tx.tax_code,
                state_flag,
  		link1,
		link2,
		link3,
		hold_flag,
		hold_desc
	FROM ibifc i
		INNER JOIN ibtrxtype t
			ON i.trx_type = t.trx_type
		LEFT JOIN OrganizationOrganizationTrx tx
			ON i.controlling_org_id = tx.controlling_org_id
			AND i.detail_org_id = tx.detail_org_id
			AND i.trx_type = tx.trx_type
	WHERE i.state_flag = -1 OR i.state_flag = -4
/**/                                              
GO
GRANT REFERENCES ON  [dbo].[ibifc_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[ibifc_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[ibifc_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[ibifc_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[ibifc_vw] TO [public]
GO
