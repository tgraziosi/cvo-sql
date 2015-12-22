CREATE TABLE [dbo].[pr_contracts]
(
[contract_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[start_date] [int] NOT NULL,
[end_date] [int] NOT NULL,
[grace_days] [int] NOT NULL,
[status] [int] NOT NULL,
[type] [int] NOT NULL,
[amount_paid_to_date_home] [float] NULL,
[amount_paid_to_date_oper] [float] NULL,
[amount_accrued_home] [float] NULL,
[amount_accrued_oper] [float] NULL,
[date_entered] [int] NOT NULL,
[userid] [int] NOT NULL,
[all_parts_flag] [int] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[pr_contracts] TO [public]
GO
GRANT SELECT ON  [dbo].[pr_contracts] TO [public]
GO
GRANT INSERT ON  [dbo].[pr_contracts] TO [public]
GO
GRANT DELETE ON  [dbo].[pr_contracts] TO [public]
GO
GRANT UPDATE ON  [dbo].[pr_contracts] TO [public]
GO
