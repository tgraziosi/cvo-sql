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











CREATE VIEW [dbo].[apchecks_vw] AS

SELECT doc_ctrl_num, cash_acct_code, payment_code
FROM appyhdr

UNION

SELECT doc_ctrl_num, cash_acct_code, payment_code
FROM apvchdr
/**/                                              
GO
GRANT REFERENCES ON  [dbo].[apchecks_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[apchecks_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[apchecks_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[apchecks_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[apchecks_vw] TO [public]
GO
