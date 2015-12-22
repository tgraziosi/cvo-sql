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



  
  


  

CREATE VIEW [dbo].[apcash_pyadj_vw] as 

select  b.cash_acct_code, b.bank_name , vendor_code, doc_ctrl_num  from appmtpst_vw a, apcash b 
where a.cash_acct_code = b.cash_acct_code and isnull(a.cash_acct_code,'') <> ''
group by b.cash_acct_code,  b.bank_name, a.vendor_code, a.doc_ctrl_num
/**/                                              
GO
GRANT REFERENCES ON  [dbo].[apcash_pyadj_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[apcash_pyadj_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[apcash_pyadj_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[apcash_pyadj_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[apcash_pyadj_vw] TO [public]
GO
