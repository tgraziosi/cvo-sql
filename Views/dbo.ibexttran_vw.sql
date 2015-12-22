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


CREATE VIEW [dbo].[ibexttran_vw] AS
	SELECT  id,
		trx_type_desc,
 		controlling_org_id,
             	detail_org_id,
		date_entered,
		date_applied,
	        amount,
                currency_code,
 		CONVERT (varchar(32),recipient_code)  recipient_code,
		CONVERT (varchar(32),originator_code)  originator_code,
 		CONVERT (varchar(32),tax_payable_code)  tax_payable_code,
		CONVERT (varchar(32),tax_expense_code)  tax_expense_code,
		tax_code,
		CONVERT (varchar(1024),link1)  link1,
		CONVERT (varchar(1024),link2)  link2,
		CONVERT (varchar(1024),link3)  link3,
		hold_flag = CASE hold_flag 
				WHEN 1 THEN 'Yes'
			    	ELSE 'No' END,
		hold_desc,
		x_date_entered = DATEDIFF( day, '01/01/1900', date_entered) + 693596,
		x_date_applied = DATEDIFF( day, '01/01/1900', date_applied) + 693596

	FROM ibifc_vw
GO
GRANT REFERENCES ON  [dbo].[ibexttran_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[ibexttran_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[ibexttran_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[ibexttran_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[ibexttran_vw] TO [public]
GO
