CREATE TABLE [dbo].[pr_accumulator]
(
[contract_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[accumulator] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_entered] [int] NOT NULL,
[userid] [int] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[pr_accumulator] TO [public]
GO
GRANT SELECT ON  [dbo].[pr_accumulator] TO [public]
GO
GRANT INSERT ON  [dbo].[pr_accumulator] TO [public]
GO
GRANT DELETE ON  [dbo].[pr_accumulator] TO [public]
GO
GRANT UPDATE ON  [dbo].[pr_accumulator] TO [public]
GO
