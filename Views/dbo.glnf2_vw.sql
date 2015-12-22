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





CREATE VIEW [dbo].[glnf2_vw] AS
SELECT 
	nonfin_budget_code,
	cast(account_code as varchar(36)) as account_code,
	date_period_end= period_end_date,
	unit_of_measure,
	quantity,
	ytd_quantity,

	x_date_period_end= period_end_date,
	x_quantity=quantity,
	x_ytd_quantity=ytd_quantity

	
FROM 
	glnofind
  	  
 
/**/                                              
GO
GRANT REFERENCES ON  [dbo].[glnf2_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[glnf2_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[glnf2_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[glnf2_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[glnf2_vw] TO [public]
GO
