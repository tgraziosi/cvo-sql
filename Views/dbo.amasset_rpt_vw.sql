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

CREATE VIEW [dbo].[amasset_rpt_vw] 
    AS
SELECT 	timestamp, 	company_id, 	asset_ctrl_num, 
	activity_state, co_asset_id, 	co_trx_id, 
	posting_flag, 	asset_description, is_new, 
	original_cost, 	
	datediff( day, '01/01/1900', acquisition_date) + 693596 acquisition_date,
	datediff( day, '01/01/1900', placed_in_service_date) + 693596 placed_in_service_date,
	datediff( day, '01/01/1900', original_in_service_date) + 693596 original_in_service_date,
	datediff( day, '01/01/1900', disposition_date) + 693596 disposition_date,
	service_units, 	orig_quantity, 	rem_quantity, 
	category_code, 	status_code, 	asset_type_code, 
	employee_code, 	location_code, 	owner_code, 
	business_usage, personal_usage, investment_usage, 
	account_reference_code, 	tag, 	note_id, 
	user_field_id, 	is_pledged, 	lease_type, 
	is_property, 	depr_overridden, linked, 
	parent_id, 	num_children, 	
	datediff( day, '01/01/1900', last_modified_date) + 693596  last_modified_date,
	modified_by, 	policy_number, 	depreciated, 
	is_imported, 	org_id
FROM amasset


/**/                                              
GO
GRANT REFERENCES ON  [dbo].[amasset_rpt_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[amasset_rpt_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[amasset_rpt_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[amasset_rpt_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[amasset_rpt_vw] TO [public]
GO
