CREATE TABLE [dbo].[glpost]
(
[posted_flag] [int] NOT NULL,
[user_id] [smallint] NOT NULL,
[process_id] [int] NOT NULL,
[start_time] [datetime] NOT NULL,
[end_time] [datetime] NOT NULL,
[start_date_jul] [int] NOT NULL,
[end_date_jul] [int] NOT NULL,
[start_time_jul] [int] NOT NULL,
[end_time_jul] [int] NOT NULL,
[no_trans] [int] NOT NULL,
[no_details] [int] NOT NULL,
[checked_flag] [smallint] NOT NULL,
[completed_flag] [smallint] NOT NULL,
[batch_proc_flag] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [glpost_ind_0] ON [dbo].[glpost] ([posted_flag], [start_time]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[glpost] TO [public]
GO
GRANT SELECT ON  [dbo].[glpost] TO [public]
GO
GRANT INSERT ON  [dbo].[glpost] TO [public]
GO
GRANT DELETE ON  [dbo].[glpost] TO [public]
GO
GRANT UPDATE ON  [dbo].[glpost] TO [public]
GO
