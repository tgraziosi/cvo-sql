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
CREATE VIEW [dbo].[ampurasset_rpt_vw]
AS
SELECT 
 	pu.co_asset_id,
 	pu.company_id,
 	pu.asset_ctrl_num,
	pu.asset_description,
 	pu.activity_state,
	pu.mass_maintenance_id,
        pu.mass_description,
 	pu.comment,
	pu.date_created,
	pu.user_name,
	pu.acquisition_date,
	pu.disposition_date,
	pu.original_cost,
	pu.lp_fiscal_period_end,
	pu.lp_accum_depr,
	pu.lp_current_cost,
	pu.updated_by,
	datediff( day, '01/01/1900', date_created) + 693596 as date_created_jul,
	datediff( day, '01/01/1900', acquisition_date) + 693596 as acquisition_date_jul,
	datediff( day, '01/01/1900', disposition_date) + 693596 as disposition_date_jul
FROM 	ampurge_vw pu


/**/                                              
GO
GRANT REFERENCES ON  [dbo].[ampurasset_rpt_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[ampurasset_rpt_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[ampurasset_rpt_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[ampurasset_rpt_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[ampurasset_rpt_vw] TO [public]
GO
