CREATE TABLE [dbo].[rpt_alloc]
(
[allocation_no] [int] NULL,
[apply_dt] [datetime] NULL,
[lc_expense_amt] [float] NULL,
[lc_expense_acct] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[amt_extended] [float] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_alloc] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_alloc] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_alloc] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_alloc] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_alloc] TO [public]
GO
