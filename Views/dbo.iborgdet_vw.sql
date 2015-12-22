SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2002 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2002 Epicor Software Corporation, 2002    
                  All Rights Reserved                    
*/                                                



























CREATE VIEW [dbo].[iborgdet_vw]
AS
	SELECT 
		organization_id,
		organization_name,
		addr1,
		addr2,
		addr3,
		addr4,
		addr5,
		addr6,
		city,
		state,
		postal_code,
		c.description as country,
		create_date,
		create_username,
		last_change_date,
		last_change_username
	FROM
		Organization o LEFT JOIN gl_country c ON o.country = c.country_code
	WHERE
		region_flag = 0
/**/                                              
GO
GRANT REFERENCES ON  [dbo].[iborgdet_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[iborgdet_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[iborgdet_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[iborgdet_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[iborgdet_vw] TO [public]
GO
