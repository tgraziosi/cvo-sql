CREATE TABLE [dbo].[distlist]
(
[timestamp] [timestamp] NOT NULL,
[dl_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [dist_idx_0] ON [dbo].[distlist] ([dl_name]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[distlist] TO [public]
GO
GRANT SELECT ON  [dbo].[distlist] TO [public]
GO
GRANT INSERT ON  [dbo].[distlist] TO [public]
GO
GRANT DELETE ON  [dbo].[distlist] TO [public]
GO
GRANT UPDATE ON  [dbo].[distlist] TO [public]
GO
