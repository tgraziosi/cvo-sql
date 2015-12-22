CREATE TABLE [dbo].[adm_post_history]
(
[timestamp] [timestamp] NOT NULL,
[post_id] [int] NOT NULL IDENTITY(1, 1),
[post_type] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[post_description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[post_filter] [varchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[user_nm] [nvarchar] (256) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__adm_post___user___73911072] DEFAULT (user_name()),
[host_nm] [nvarchar] (256) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__adm_post___host___748534AB] DEFAULT (host_name()),
[batch_cnt] [int] NOT NULL,
[start_time] [datetime] NOT NULL CONSTRAINT [DF__adm_post___start__757958E4] DEFAULT (getdate()),
[end_time] [datetime] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [adm_post_history2] ON [dbo].[adm_post_history] ([post_type], [start_time]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[adm_post_history] TO [public]
GO
GRANT SELECT ON  [dbo].[adm_post_history] TO [public]
GO
GRANT INSERT ON  [dbo].[adm_post_history] TO [public]
GO
GRANT DELETE ON  [dbo].[adm_post_history] TO [public]
GO
GRANT UPDATE ON  [dbo].[adm_post_history] TO [public]
GO
