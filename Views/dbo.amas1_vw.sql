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





CREATE VIEW [dbo].[amas1_vw] AS
SELECT 
	org_id,
	co_asset_id,
	asset_ctrl_num,
	asset_description,
	asset_type_code,
	activity_state = case activity_state
		when  0   then 'Active'
		when  1   then 'To be Disp.'
		when  2   then 'Inactive'
		when  100 then 'Add'
		when  101 then 'Disposed'
		end,
	is_new = case is_new
		when  0 then 'No'
		when  1 then 'Yes'
		end,
	is_pledged = case is_pledged
		when 0 then 'No'
		when 1 then 'Yes'
		end,
	is_property = case is_property
		when 0 then 'No'
		when 1 then 'Yes'
		end,
	depreciated = case depreciated
		when  0 then 'No'
		when  1 then 'Yes'
		end,
	is_imported = case is_imported
		when  0 then 'No'
		when  1 then 'Yes'
		end,
	lease_type = case lease_type
		when  1 then 'Not Leased'
		when  2 then 'Capital Lease'
		when  3 then 'Operating Lease'
		end,
	original_cost,
	orig_quantity,
	date_acquisition = acquisition_date,
	date_placed_in_service = placed_in_service_date,
	date_disposition = disposition_date,
	category_code,
	account_reference_code,
	policy_number,		
	key_1 = convert(varchar(20),co_asset_id),

	x_original_cost=original_cost,
	x_orig_quantity=orig_quantity,
	x_date_acquisition = isnull(datediff( day, '01/01/1900', acquisition_date) + 693596,0),
	x_date_placed_in_service = isnull(datediff( day, '01/01/1900', placed_in_service_date) + 693596,0),
	x_date_disposition = isnull(datediff( day, '01/01/1900', disposition_date) ,0)


	
FROM 
	amasset
	WHERE dbo.sm_organization_access_fn(org_id) = 1
  	  
 
/**/                                              
GO
GRANT REFERENCES ON  [dbo].[amas1_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[amas1_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[amas1_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[amas1_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[amas1_vw] TO [public]
GO
