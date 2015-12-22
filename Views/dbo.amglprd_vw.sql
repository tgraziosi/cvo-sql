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

CREATE view [dbo].[amglprd_vw] as
SELECT period_end_date period_end_1, period_end_date period_end_2, period_description
FROM glprd

/**/                                              
GO
GRANT REFERENCES ON  [dbo].[amglprd_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[amglprd_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[amglprd_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[amglprd_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[amglprd_vw] TO [public]
GO
