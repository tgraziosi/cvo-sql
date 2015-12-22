CREATE TABLE [dbo].[rpt_arcbtrxage]
(
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[apply_to_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[apply_trx_type] [smallint] NULL,
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[amount] [float] NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ref_id] [int] NULL,
[symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_arcbtrxage] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_arcbtrxage] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_arcbtrxage] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_arcbtrxage] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_arcbtrxage] TO [public]
GO
