SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2007 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2007 Epicor Software Corporation, 2007    
                  All Rights Reserved                    
*/                                                






    


CREATE VIEW [dbo].[apcash_default_vw] AS
 SELECT TOP 1 cash_acct_code = ISNULL( ( SELECT default_cash_acct 
					FROM apco a INNER JOIN apcash_sec_vw b ON (a.default_cash_acct = b.cash_acct_code 
					and b.cash_acct_code in (select account_code from glchart_vw)
					) ),cash_acct_code  )
FROM apcash_sec_vw 
WHERE cash_acct_code in (select account_code from glchart_vw)







/**/                                              
GO
GRANT REFERENCES ON  [dbo].[apcash_default_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[apcash_default_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[apcash_default_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[apcash_default_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[apcash_default_vw] TO [public]
GO
