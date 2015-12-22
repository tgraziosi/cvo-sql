CREATE TABLE [dbo].[rpt_apaprdfd]
(
[timestamp] [timestamp] NOT NULL,
[exp_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_min] [float] NOT NULL,
[approval_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[curr_precision] [smallint] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_apaprdfd] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_apaprdfd] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_apaprdfd] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_apaprdfd] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_apaprdfd] TO [public]
GO
