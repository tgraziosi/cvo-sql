SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE VIEW [dbo].[mbbmvwBudget]
AS
SELECT  HostCompany	= company_code,
	BudgetCode	= budget_code,
	Description	= budget_description
FROM	glbud, glco
GO
GRANT REFERENCES ON  [dbo].[mbbmvwBudget] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmvwBudget] TO [Analytics]
GO
GRANT INSERT ON  [dbo].[mbbmvwBudget] TO [Analytics]
GO
GRANT DELETE ON  [dbo].[mbbmvwBudget] TO [Analytics]
GO
GRANT UPDATE ON  [dbo].[mbbmvwBudget] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmvwBudget] TO [public]
GO
GRANT INSERT ON  [dbo].[mbbmvwBudget] TO [public]
GO
GRANT DELETE ON  [dbo].[mbbmvwBudget] TO [public]
GO
GRANT UPDATE ON  [dbo].[mbbmvwBudget] TO [public]
GO
