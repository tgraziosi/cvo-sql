CREATE TABLE [dbo].[rpt_cmpurge]
(
[cash_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type] [smallint] NOT NULL,
[date_applied] [int] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_cmpurge] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_cmpurge] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_cmpurge] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_cmpurge] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_cmpurge] TO [public]
GO
