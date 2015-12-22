CREATE TABLE [dbo].[pr_customer_class]
(
[contract_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[price_class] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void] [int] NOT NULL,
[amount_paid_to_date_home] [float] NULL,
[amount_accrued_home] [float] NULL,
[amount_paid_to_date_oper] [float] NULL,
[amount_accrued_oper] [float] NULL,
[date_entered] [int] NOT NULL,
[userid] [int] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[pr_customer_class] TO [public]
GO
GRANT SELECT ON  [dbo].[pr_customer_class] TO [public]
GO
GRANT INSERT ON  [dbo].[pr_customer_class] TO [public]
GO
GRANT DELETE ON  [dbo].[pr_customer_class] TO [public]
GO
GRANT UPDATE ON  [dbo].[pr_customer_class] TO [public]
GO
