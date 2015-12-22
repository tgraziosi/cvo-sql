SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[amimpast_vw] 
AS 

SELECT 
	timestamp,
	company_id,
	asset_ctrl_num,
	activity_state,
	co_asset_id,
	co_trx_id,
	posting_flag,
	asset_description,
	is_new,
	original_cost,
	acquisition_date, 
	placed_in_service_date, 
	original_in_service_date, 
	disposition_date, 
	service_units,
	orig_quantity,
	rem_quantity,
	category_code,
	status_code,
	asset_type_code,
	employee_code,
	location_code,
	owner_code,
	business_usage,
	personal_usage,
	investment_usage,
	account_reference_code,
	tag,
	note_id,
	user_field_id,
	is_pledged,
	lease_type,
	is_property,
	depr_overridden,
	linked,
	parent_id,
	num_children,
	last_modified_date, 
	modified_by,
	policy_number,
	depreciated,
	is_imported 
FROM 	amasset 
WHERE 	is_imported 	= 1
AND		activity_state 	= 100 

GO
GRANT REFERENCES ON  [dbo].[amimpast_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[amimpast_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[amimpast_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[amimpast_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[amimpast_vw] TO [public]
GO
