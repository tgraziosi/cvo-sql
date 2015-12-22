CREATE TABLE [dbo].[rpt_arreconsum]
(
[account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[journal_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_applied] [datetime] NULL,
[ar_activity] [float] NOT NULL,
[gl_activity] [float] NOT NULL,
[journal_description] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_arreconsum] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_arreconsum] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_arreconsum] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_arreconsum] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_arreconsum] TO [public]
GO
