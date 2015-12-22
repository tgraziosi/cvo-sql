CREATE TABLE [dbo].[status]
(
[timestamp] [timestamp] NOT NULL,
[process_key] [smallint] NOT NULL,
[user_id] [smallint] NOT NULL,
[form_title] [char] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[status] [char] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[completion] [smallint] NOT NULL,
[error_flag] [smallint] NOT NULL,
[update_flag] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [status_ind_0] ON [dbo].[status] ([process_key], [user_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[status] TO [public]
GO
GRANT SELECT ON  [dbo].[status] TO [public]
GO
GRANT INSERT ON  [dbo].[status] TO [public]
GO
GRANT DELETE ON  [dbo].[status] TO [public]
GO
GRANT UPDATE ON  [dbo].[status] TO [public]
GO
