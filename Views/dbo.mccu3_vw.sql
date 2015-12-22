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





CREATE VIEW [dbo].[mccu3_vw] AS
SELECT 
	to_currency,
	from_currency,
	rate_type,
	buy_rate,
	date_valid_from = convert_date,
	valid_for_days,
	date_valid_to = convert_date + valid_for_days,

	x_buy_rate=buy_rate,
	x_date_valid_from = convert_date,
	x_valid_for_days=valid_for_days,
	x_date_valid_to = convert_date + valid_for_days


FROM 
	CVO_Control..mccurtdt
  	  
 
/**/                                              
GO
GRANT REFERENCES ON  [dbo].[mccu3_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[mccu3_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[mccu3_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[mccu3_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[mccu3_vw] TO [public]
GO
