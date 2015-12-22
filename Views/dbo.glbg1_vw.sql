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





CREATE VIEW [dbo].[glbg1_vw] AS
SELECT 
	budget_code,
	budget_description,
	rate_type,
	date_period_end=glco.period_end_date,

	x_date_period_end=glco.period_end_date

FROM 
	glbud, glco
	
  	  
 
/**/                                              
GO
GRANT REFERENCES ON  [dbo].[glbg1_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[glbg1_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[glbg1_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[glbg1_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[glbg1_vw] TO [public]
GO
