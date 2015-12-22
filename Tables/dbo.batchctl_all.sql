CREATE TABLE [dbo].[batchctl_all]
(
[timestamp] [timestamp] NULL,
[batch_ctrl_num] [char] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[batch_description] [char] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[start_date] [int] NOT NULL,
[start_time] [int] NOT NULL,
[completed_date] [int] NOT NULL,
[completed_time] [int] NOT NULL,
[control_number] [int] NOT NULL,
[control_total] [float] NOT NULL,
[actual_number] [int] NOT NULL,
[actual_total] [float] NOT NULL,
[batch_type] [smallint] NOT NULL,
[document_name] [char] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[hold_flag] [smallint] NOT NULL,
[posted_flag] [smallint] NOT NULL,
[void_flag] [smallint] NOT NULL,
[selected_flag] [smallint] NOT NULL,
[number_held] [int] NOT NULL,
[date_applied] [int] NOT NULL,
[date_posted] [int] NOT NULL,
[time_posted] [int] NOT NULL,
[start_user] [char] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[completed_user] [char] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[posted_user] [char] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[company_code] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[selected_user_id] [smallint] NULL,
[process_group_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[page_fill_1] [char] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[page_fill_2] [char] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[page_fill_3] [char] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[page_fill_4] [char] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[page_fill_5] [char] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[page_fill_6] [char] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[page_fill_7] [char] (84) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[page_fill_8] [char] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [batchctl_all_ind_0] ON [dbo].[batchctl_all] ([batch_ctrl_num]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [batchctl_all_ind_2] ON [dbo].[batchctl_all] ([posted_flag], [batch_ctrl_num], [batch_type], [completed_date], [hold_flag], [number_held]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [batchctl_all_ind_1] ON [dbo].[batchctl_all] ([posted_flag], [selected_user_id], [selected_flag], [batch_ctrl_num]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [batchctl_all_ind_3] ON [dbo].[batchctl_all] ([process_group_num]) WITH (FILLFACTOR=80) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[batchctl_all] TO [public]
GO
GRANT INSERT ON  [dbo].[batchctl_all] TO [public]
GO
GRANT DELETE ON  [dbo].[batchctl_all] TO [public]
GO
GRANT UPDATE ON  [dbo].[batchctl_all] TO [public]
GO
