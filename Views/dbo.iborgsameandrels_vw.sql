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




























CREATE VIEW [dbo].[iborgsameandrels_vw]
AS
	SELECT DISTINCT r.controlling_org_id, r.detail_org_id, o.organization_name 
	FROM 	oorel_vw r,	iborganization_zoom_vw o  
	WHERE	r.detail_org_id = o.org_id
	
	UNION 	
	SELECT DISTINCT org_id as controlling_org_id, org_id AS detail_org_id , OrganizationName AS organization_name
		FROM  IB_Organization_vw 
GO
GRANT REFERENCES ON  [dbo].[iborgsameandrels_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[iborgsameandrels_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[iborgsameandrels_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[iborgsameandrels_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[iborgsameandrels_vw] TO [public]
GO
