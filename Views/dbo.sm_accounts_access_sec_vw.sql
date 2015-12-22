SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
 CREATE VIEW [dbo].[sm_accounts_access_sec_vw] AS SELECT DISTINCT a.account_code 
						       FROM glchart a 
GO
GRANT REFERENCES ON  [dbo].[sm_accounts_access_sec_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[sm_accounts_access_sec_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[sm_accounts_access_sec_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[sm_accounts_access_sec_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[sm_accounts_access_sec_vw] TO [public]
GO
