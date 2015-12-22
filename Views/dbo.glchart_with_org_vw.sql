SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE VIEW [dbo].[glchart_with_org_vw] AS SELECT  (SELECT organization_id FROM Organization_all WHERE outline_num = '1') org_id , account_code , account_description, account_type from glchart 
GO
GRANT REFERENCES ON  [dbo].[glchart_with_org_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[glchart_with_org_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[glchart_with_org_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[glchart_with_org_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[glchart_with_org_vw] TO [public]
GO
