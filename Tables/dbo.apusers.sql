CREATE TABLE [dbo].[apusers]
(
[timestamp] [timestamp] NOT NULL,
[user_id] [smallint] NOT NULL,
[user_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_max] [float] NOT NULL,
[manager_level] [smallint] NOT NULL,
[alt_mgr_level] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [apusers_ind_0] ON [dbo].[apusers] ([user_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[apusers] TO [public]
GO
GRANT SELECT ON  [dbo].[apusers] TO [public]
GO
GRANT INSERT ON  [dbo].[apusers] TO [public]
GO
GRANT DELETE ON  [dbo].[apusers] TO [public]
GO
GRANT UPDATE ON  [dbo].[apusers] TO [public]
GO
