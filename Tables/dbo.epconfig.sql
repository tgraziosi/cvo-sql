CREATE TABLE [dbo].[epconfig]
(
[timestamp] [timestamp] NOT NULL,
[path_index] [int] NOT NULL IDENTITY(1, 1),
[outpath] [varchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[inpath] [varchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [epconfig_ind_0] ON [dbo].[epconfig] ([path_index]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[epconfig] TO [public]
GO
GRANT SELECT ON  [dbo].[epconfig] TO [public]
GO
GRANT INSERT ON  [dbo].[epconfig] TO [public]
GO
GRANT DELETE ON  [dbo].[epconfig] TO [public]
GO
GRANT UPDATE ON  [dbo].[epconfig] TO [public]
GO
