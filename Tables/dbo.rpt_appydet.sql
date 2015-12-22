CREATE TABLE [dbo].[rpt_appydet]
(
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vo_amt_applied] [float] NOT NULL,
[vo_amt_disc_taken] [float] NOT NULL,
[gain_home] [float] NOT NULL,
[gain_oper] [float] NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_appydet] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_appydet] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_appydet] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_appydet] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_appydet] TO [public]
GO
