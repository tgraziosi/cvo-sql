CREATE TABLE [dbo].[gl_stat_manner]
(
[timestamp] [timestamp] NOT NULL,
[stat_manner] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[stat_manner_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [gl_stat_manner_0] ON [dbo].[gl_stat_manner] ([stat_manner]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[gl_stat_manner] TO [public]
GO
GRANT SELECT ON  [dbo].[gl_stat_manner] TO [public]
GO
GRANT INSERT ON  [dbo].[gl_stat_manner] TO [public]
GO
GRANT DELETE ON  [dbo].[gl_stat_manner] TO [public]
GO
GRANT UPDATE ON  [dbo].[gl_stat_manner] TO [public]
GO
