SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

            
create view [dbo].[amasset_org_vw] as 
select 	 
		ast.timestamp,
		ast.company_id,
		ast.asset_ctrl_num,
		ast.activity_state,
		ast.co_asset_id,
		ast.co_trx_id,
		ast.posting_flag,
		ast.asset_description,
		ast.is_new,
		ast.original_cost,
		ast.acquisition_date, 
		ast.placed_in_service_date, 
		ast.original_in_service_date, 
		ast.disposition_date, 
		ast.service_units,
		ast.orig_quantity,
		ast.rem_quantity,
		ast.category_code,
		ast.status_code,
		ast.asset_type_code,
		ast.employee_code,
		ast.location_code,
		ast.owner_code,
		ast.business_usage,
		ast.personal_usage,
		ast.investment_usage,
		ast.account_reference_code,
		ast.tag,
		ast.note_id,
		ast.user_field_id,
		ast.is_pledged,
		ast.lease_type,
		ast.is_property,
		ast.depr_overridden,
		ast.linked,
		ast.parent_id,
		ast.num_children,
		ast.last_modified_date, 
		ast.modified_by,
		ast.policy_number,
		ast.depreciated,
		ast.is_imported, 
                ast.org_id
from 	amasset ast,amOrganization_vw org
where 	ast.org_id = org.org_id




GO
GRANT REFERENCES ON  [dbo].[amasset_org_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[amasset_org_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[amasset_org_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[amasset_org_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[amasset_org_vw] TO [public]
GO
