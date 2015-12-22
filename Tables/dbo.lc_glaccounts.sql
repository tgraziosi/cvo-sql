CREATE TABLE [dbo].[lc_glaccounts]
(
[timestamp] [timestamp] NOT NULL,
[account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[lc_glaccounts] TO [public]
GO
GRANT SELECT ON  [dbo].[lc_glaccounts] TO [public]
GO
GRANT INSERT ON  [dbo].[lc_glaccounts] TO [public]
GO
GRANT DELETE ON  [dbo].[lc_glaccounts] TO [public]
GO
GRANT UPDATE ON  [dbo].[lc_glaccounts] TO [public]
GO
