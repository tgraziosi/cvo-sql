CREATE TABLE [dbo].[gl_bundesland]
(
[timestamp] [timestamp] NOT NULL,
[bundesland] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[bundesland_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [gl_bundesland_0] ON [dbo].[gl_bundesland] ([bundesland]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[gl_bundesland] TO [public]
GO
GRANT SELECT ON  [dbo].[gl_bundesland] TO [public]
GO
GRANT INSERT ON  [dbo].[gl_bundesland] TO [public]
GO
GRANT DELETE ON  [dbo].[gl_bundesland] TO [public]
GO
GRANT UPDATE ON  [dbo].[gl_bundesland] TO [public]
GO
