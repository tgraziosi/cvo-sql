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

CREATE VIEW [dbo].[amglprd2_vw] as
SELECT period_start_date period_end_1, period_end_date period_end_2, period_description
FROM glprd
/**/                                              
GO
GRANT REFERENCES ON  [dbo].[amglprd2_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[amglprd2_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[amglprd2_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[amglprd2_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[amglprd2_vw] TO [public]
GO
