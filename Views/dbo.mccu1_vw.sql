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





CREATE VIEW [dbo].[mccu1_vw] AS
SELECT 
	currency_code,
	description,
	symbol,
	currency_mask,
	rounding_factor,
	curr_precision,

	x_rounding_factor=rounding_factor,
	x_curr_precision=curr_precision

	
FROM 
	CVO_Control..mccurr
  	  
 
/**/                                              
GO
GRANT REFERENCES ON  [dbo].[mccu1_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[mccu1_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[mccu1_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[mccu1_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[mccu1_vw] TO [public]
GO
