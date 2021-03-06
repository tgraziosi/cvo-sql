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




                                              

CREATE  VIEW [dbo].[InBranAcct] AS

SELECT account_code , 
account_description ,
account_type,         
new_flag,             
seg1_code,            
seg2_code,            
seg3_code,            
seg4_code,            
consol_detail_flag,   
consol_type,          
active_date,          
inactive_date,        
inactive_flag,        
currency_code,        
revaluate_flag,       
rate_type_home,       
rate_type_oper,       
org_id,               
ib_flag,              
company_code    
FROM InterBranchAccts

/**/                                              
GO
GRANT REFERENCES ON  [dbo].[InBranAcct] TO [public]
GO
GRANT SELECT ON  [dbo].[InBranAcct] TO [public]
GO
GRANT INSERT ON  [dbo].[InBranAcct] TO [public]
GO
GRANT DELETE ON  [dbo].[InBranAcct] TO [public]
GO
GRANT UPDATE ON  [dbo].[InBranAcct] TO [public]
GO
