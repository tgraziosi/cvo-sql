SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[apdefaultcashacct_sec_vw] AS

	select a.default_cash_acct from apco a, apcash_sec_vw b
	where a.default_cash_acct = b.cash_acct_code
GO
GRANT REFERENCES ON  [dbo].[apdefaultcashacct_sec_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[apdefaultcashacct_sec_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[apdefaultcashacct_sec_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[apdefaultcashacct_sec_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[apdefaultcashacct_sec_vw] TO [public]
GO
