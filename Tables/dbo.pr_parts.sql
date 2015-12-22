CREATE TABLE [dbo].[pr_parts]
(
[contract_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void] [int] NOT NULL,
[amount_paid_to_date_home] [float] NOT NULL,
[amount_accrued_home] [float] NOT NULL,
[amount_paid_to_date_oper] [float] NOT NULL,
[amount_accrued_oper] [float] NOT NULL,
[percent_flag] [int] NOT NULL,
[date_entered] [int] NOT NULL,
[userid] [int] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[pr_parts] TO [public]
GO
GRANT SELECT ON  [dbo].[pr_parts] TO [public]
GO
GRANT INSERT ON  [dbo].[pr_parts] TO [public]
GO
GRANT DELETE ON  [dbo].[pr_parts] TO [public]
GO
GRANT UPDATE ON  [dbo].[pr_parts] TO [public]
GO
