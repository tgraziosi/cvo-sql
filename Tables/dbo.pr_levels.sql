CREATE TABLE [dbo].[pr_levels]
(
[contract_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[part_class_flag] [int] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_category] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[level] [int] NOT NULL,
[from_range] [float] NOT NULL,
[to_range] [float] NOT NULL,
[rebate] [float] NOT NULL,
[rebate_percent_flag] [int] NOT NULL,
[date_entered] [int] NOT NULL,
[userid] [int] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[pr_levels] TO [public]
GO
GRANT SELECT ON  [dbo].[pr_levels] TO [public]
GO
GRANT INSERT ON  [dbo].[pr_levels] TO [public]
GO
GRANT DELETE ON  [dbo].[pr_levels] TO [public]
GO
GRANT UPDATE ON  [dbo].[pr_levels] TO [public]
GO
