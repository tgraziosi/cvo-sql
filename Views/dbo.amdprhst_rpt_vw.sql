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
CREATE VIEW [dbo].[amdprhst_rpt_vw]
 AS
SELECT 
	co_asset_book_id,
	effective_date,
	last_modified_date,
	modified_by,
	posting_flag,
	depr_rule_code,
	limit_rule_code,
	salvage_value,
	catch_up_diff,
	end_life_date,
	switch_to_sl_date,
	datediff( day, '01/01/1900', effective_date) + 693596 as effective_date_jul
FROM amdprhst


/**/                                              
GO
GRANT REFERENCES ON  [dbo].[amdprhst_rpt_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[amdprhst_rpt_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[amdprhst_rpt_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[amdprhst_rpt_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[amdprhst_rpt_vw] TO [public]
GO
