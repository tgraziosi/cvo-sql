CREATE TABLE [dbo].[rpt_amsusacct]
(
[account_type] [char] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[suspense_account] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_amsusacct] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_amsusacct] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_amsusacct] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_amsusacct] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_amsusacct] TO [public]
GO
