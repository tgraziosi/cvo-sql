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





CREATE VIEW [dbo].[mccu2_vw] AS
SELECT 
	from_currency,
	to_currency,
	rate_type,
	default_valid_for_days,
	tolerance,
	divide_flag = case
		when divide_flag = 1 then 'Divide'
		when divide_flag = 0 then 'Multiply'
		end,	
	inactive_flag = case
		when inactive_flag = 0 then 'Yes'
		when inactive_flag = 1 then 'No'
		end,
	override_flag = case
		when override_flag = 0 then 'No'
		when override_flag = 1 then 'Yes'
		end,

	x_default_valid_for_days=default_valid_for_days

	
FROM 
	CVO_Control..mccurate
  	  
 
/**/                                              
GO
GRANT REFERENCES ON  [dbo].[mccu2_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[mccu2_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[mccu2_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[mccu2_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[mccu2_vw] TO [public]
GO
