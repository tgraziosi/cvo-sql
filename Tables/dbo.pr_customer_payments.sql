CREATE TABLE [dbo].[pr_customer_payments]
(
[contract_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[void_flag] [int] NOT NULL,
[check_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amount] [float] NOT NULL,
[rate_type_home] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate_type_oper] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate_home] [float] NOT NULL,
[rate_oper] [float] NOT NULL,
[home_amount] [float] NOT NULL,
[oper_amount] [float] NOT NULL,
[userid] [int] NOT NULL,
[date_entered] [int] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[pr_customer_payments] TO [public]
GO
GRANT SELECT ON  [dbo].[pr_customer_payments] TO [public]
GO
GRANT INSERT ON  [dbo].[pr_customer_payments] TO [public]
GO
GRANT DELETE ON  [dbo].[pr_customer_payments] TO [public]
GO
GRANT UPDATE ON  [dbo].[pr_customer_payments] TO [public]
GO
