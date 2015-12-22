CREATE TABLE [dbo].[spmsgs]
(
[timestamp] [timestamp] NOT NULL,
[process_key] [smallint] NOT NULL,
[user_id] [smallint] NOT NULL,
[status] [char] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [spmsgs_ind_0] ON [dbo].[spmsgs] ([process_key], [user_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[spmsgs] TO [public]
GO
GRANT SELECT ON  [dbo].[spmsgs] TO [public]
GO
GRANT INSERT ON  [dbo].[spmsgs] TO [public]
GO
GRANT DELETE ON  [dbo].[spmsgs] TO [public]
GO
GRANT UPDATE ON  [dbo].[spmsgs] TO [public]
GO
