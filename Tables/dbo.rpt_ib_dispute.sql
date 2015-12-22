CREATE TABLE [dbo].[rpt_ib_dispute]
(
[controlling_org_id] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[detail_org_id] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[org_id] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[dispute_flag] [int] NOT NULL,
[dispute_code] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[journal_ctrl_num] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ib_trx_ctrl_num] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type] [int] NOT NULL,
[date_applied] [datetime] NOT NULL,
[account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amount] [decimal] (20, 8) NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_ib_dispute] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_ib_dispute] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_ib_dispute] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_ib_dispute] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_ib_dispute] TO [public]
GO
