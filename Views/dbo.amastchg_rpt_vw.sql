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

CREATE VIEW [dbo].[amastchg_rpt_vw] (co_asset_id, field_type, apply_date, old_value, new_value, last_modified_date, modified_by, apply_date_jul, last_modified_date_jul)
 AS
SELECT co_asset_id, field_type, apply_date, old_value, new_value, last_modified_date, modified_by,
		datediff( day, '01/01/1900', apply_date) + 693596, datediff( day, '01/01/1900', last_modified_date) + 693596
FROM amastchg
/**/                                              
GO
GRANT REFERENCES ON  [dbo].[amastchg_rpt_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[amastchg_rpt_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[amastchg_rpt_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[amastchg_rpt_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[amastchg_rpt_vw] TO [public]
GO
