SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[sm_accounts_access]
AS
		SELECT DISTINCT account_code 
		FROM sm_accounts_access_sec_vw

GO
GRANT REFERENCES ON  [dbo].[sm_accounts_access] TO [public]
GO
GRANT SELECT ON  [dbo].[sm_accounts_access] TO [public]
GO
GRANT INSERT ON  [dbo].[sm_accounts_access] TO [public]
GO
GRANT DELETE ON  [dbo].[sm_accounts_access] TO [public]
GO
GRANT UPDATE ON  [dbo].[sm_accounts_access] TO [public]
GO
