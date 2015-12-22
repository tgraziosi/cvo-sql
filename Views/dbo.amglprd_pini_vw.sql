SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2006 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2006 Epicor Software Corporation, 2006    
                  All Rights Reserved                    
*/                                                


CREATE VIEW [dbo].[amglprd_pini_vw] as
SELECT (period_start_date) period_start_date
FROM glprd 
WHERE period_end_date = (select max(period_end_date) from glco)
/**/                                              
GO
GRANT REFERENCES ON  [dbo].[amglprd_pini_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[amglprd_pini_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[amglprd_pini_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[amglprd_pini_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[amglprd_pini_vw] TO [public]
GO
