SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/                                                

CREATE PROCEDURE [dbo].[amOrganization_vwAll_sp] 
( 
	@org_id smOrgId
) 
AS 

SELECT 
	timestamp,
	organization_id,
	organization_name,
	active_flag,
	outline_num,
	branch_account_number,
	new_flag,
	convert(char(8), create_date, 112),
	create_username,
	convert(char(8), last_change_date, 112),
	last_change_username,
	addr1,
	addr2,
	addr3,
	addr4,
	addr5,
	addr6,
	city,
	state,
	postal_code,
	country,
	tax_id_num,
	region_flag
FROM 	amOrganization_vw 
WHERE 	org_id 			= @org_id 
ORDER BY 
	org_id
RETURN @@error 
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[amOrganization_vwAll_sp] TO [public]
GO
