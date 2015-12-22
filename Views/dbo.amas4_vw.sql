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





CREATE VIEW [dbo].[amas4_vw] AS
SELECT 
	co_asset_id,
	account_code,
	up_to_date = case up_to_date
		when 0 then 'No'
		when 1 then 'Yes'
		end,
	account_type_description,
	date_last_modified=last_modified_date,

	x_date_last_modified=last_modified_date


	
FROM 
	amastact amastact, amacctyp amacctyp
WHERE
	amastact.account_type_id = amacctyp.account_type
  	  
 
/**/                                              
GO
GRANT REFERENCES ON  [dbo].[amas4_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[amas4_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[amas4_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[amas4_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[amas4_vw] TO [public]
GO
