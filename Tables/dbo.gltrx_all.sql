CREATE TABLE [dbo].[gltrx_all]
(
[timestamp] [timestamp] NOT NULL,
[journal_type] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[journal_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[journal_description] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_entered] [int] NOT NULL,
[date_applied] [int] NOT NULL,
[recurring_flag] [smallint] NOT NULL,
[repeating_flag] [smallint] NOT NULL,
[reversing_flag] [smallint] NOT NULL,
[hold_flag] [smallint] NOT NULL,
[posted_flag] [smallint] NOT NULL,
[date_posted] [int] NOT NULL,
[source_batch_code] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[batch_code] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[type_flag] [smallint] NOT NULL,
[intercompany_flag] [smallint] NOT NULL,
[company_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[app_id] [int] NOT NULL,
[home_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[document_1] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type] [smallint] NOT NULL,
[user_id] [smallint] NOT NULL,
[source_company_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[process_group_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[oper_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[interbranch_flag] [smallint] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [perf_ind01] ON [dbo].[gltrx_all] ([batch_code]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [gltrx_all_ind_3] ON [dbo].[gltrx_all] ([date_applied], [journal_ctrl_num], [journal_type], [posted_flag]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [gltrx_all_ind_0] ON [dbo].[gltrx_all] ([journal_ctrl_num]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [gltrx_all_ind_1] ON [dbo].[gltrx_all] ([journal_type], [journal_description], [date_entered]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [gltrx_all_ind_4] ON [dbo].[gltrx_all] ([org_id], [journal_ctrl_num], [posted_flag], [interbranch_flag]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [perf_ind02] ON [dbo].[gltrx_all] ([posted_flag], [process_group_num]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [gltrx_all_ind_2] ON [dbo].[gltrx_all] ([process_group_num]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[gltrx_all] TO [public]
GO
GRANT SELECT ON  [dbo].[gltrx_all] TO [public]
GO
GRANT INSERT ON  [dbo].[gltrx_all] TO [public]
GO
GRANT DELETE ON  [dbo].[gltrx_all] TO [public]
GO
GRANT UPDATE ON  [dbo].[gltrx_all] TO [public]
GO
