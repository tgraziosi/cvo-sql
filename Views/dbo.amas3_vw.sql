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





CREATE VIEW [dbo].[amas3_vw] AS
SELECT 
	co_asset_id,
	co_asset_book_id,
	book_code,
	orig_salvage_value,
	date_placed_in_service=placed_in_service_date,
	date_last_posted_depr=last_posted_depr_date,

	x_orig_salvage_value=orig_salvage_value,
	x_date_placed_in_service=placed_in_service_date,
	x_date_last_posted_depr=last_posted_depr_date


	
FROM 
	amastbk
  	  
 
/**/                                              
GO
GRANT REFERENCES ON  [dbo].[amas3_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[amas3_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[amas3_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[amas3_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[amas3_vw] TO [public]
GO
