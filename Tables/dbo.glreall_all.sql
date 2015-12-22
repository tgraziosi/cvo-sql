CREATE TABLE [dbo].[glreall_all]
(
[timestamp] [timestamp] NOT NULL,
[journal_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[journal_type] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[journal_description] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_entered] [int] NOT NULL,
[date_posted] [int] NOT NULL,
[date_last_applied] [int] NOT NULL,
[batch_code] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[hold_flag] [smallint] NOT NULL,
[posted_flag] [smallint] NOT NULL,
[based_type] [smallint] NOT NULL,
[budget_code] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[nonfin_budget_code] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[intercompany_flag] [smallint] NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[interbranch_flag] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [glreall_all_ind_1] ON [dbo].[glreall_all] ([journal_ctrl_num]) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [glreall_all_ind_0] ON [dbo].[glreall_all] ([journal_type], [journal_description], [date_entered]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [glreall_all_ind_2] ON [dbo].[glreall_all] ([posted_flag], [date_entered]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[glreall_all] TO [public]
GO
GRANT SELECT ON  [dbo].[glreall_all] TO [public]
GO
GRANT INSERT ON  [dbo].[glreall_all] TO [public]
GO
GRANT DELETE ON  [dbo].[glreall_all] TO [public]
GO
GRANT UPDATE ON  [dbo].[glreall_all] TO [public]
GO
