CREATE TABLE [dbo].[rpt_ib_recon]
(
[record_type] [int] NULL,
[journal_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ib_trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trx_type] [int] NULL,
[ib_trx_desc] [nvarchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_applied] [int] NULL,
[from_org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[to_org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[amount] [decimal] (20, 8) NOT NULL,
[total_dr] [decimal] (20, 8) NOT NULL,
[total_cr] [decimal] (20, 8) NOT NULL,
[total] [decimal] (20, 8) NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_ib_recon] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_ib_recon] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_ib_recon] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_ib_recon] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_ib_recon] TO [public]
GO
