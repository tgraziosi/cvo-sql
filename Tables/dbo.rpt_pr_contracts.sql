CREATE TABLE [dbo].[rpt_pr_contracts]
(
[contract_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[start_date] [datetime] NOT NULL,
[end_date] [datetime] NOT NULL,
[grace_days] [int] NOT NULL,
[status] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[type] [int] NOT NULL,
[amt_paid] [float] NULL,
[amt_accrued] [float] NULL,
[userid] [int] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_pr_contracts] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_pr_contracts] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_pr_contracts] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_pr_contracts] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_pr_contracts] TO [public]
GO
