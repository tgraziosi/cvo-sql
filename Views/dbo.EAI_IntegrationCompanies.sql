SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
create view [dbo].[EAI_IntegrationCompanies] as select AppName, CompanyName, DDID from CVO_Control..EAI_IntegrationCompanies
GO
GRANT SELECT ON  [dbo].[EAI_IntegrationCompanies] TO [public]
GO
GRANT INSERT ON  [dbo].[EAI_IntegrationCompanies] TO [public]
GO
GRANT DELETE ON  [dbo].[EAI_IntegrationCompanies] TO [public]
GO
GRANT UPDATE ON  [dbo].[EAI_IntegrationCompanies] TO [public]
GO
