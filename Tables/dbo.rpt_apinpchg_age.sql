CREATE TABLE [dbo].[rpt_apinpchg_age]
(
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_aging] [int] NOT NULL,
[date_due] [int] NOT NULL,
[date_applied] [int] NOT NULL,
[amt_due] [float] NOT NULL,
[symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_apinpchg_age] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_apinpchg_age] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_apinpchg_age] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_apinpchg_age] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_apinpchg_age] TO [public]
GO
