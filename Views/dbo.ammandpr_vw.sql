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

CREATE VIEW [dbo].[ammandpr_vw] 
 AS
SELECT 
timestamp,          
co_asset_book_id, 
datediff( day, '01/01/1900', fiscal_period_end) + 693596 fiscal_period_end,                                       
datediff( day, '01/01/1900', last_modified_date) + 693596 last_modified_date,                                       
modified_by, 
posting_flag,
depr_expense                                          
FROM ammandpr
/**/                                              
GO
GRANT REFERENCES ON  [dbo].[ammandpr_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[ammandpr_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[ammandpr_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[ammandpr_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[ammandpr_vw] TO [public]
GO
