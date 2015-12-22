CREATE TABLE [dbo].[gl_harbour]
(
[timestamp] [timestamp] NOT NULL,
[harbour] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[harbour_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [gl_harbour_0] ON [dbo].[gl_harbour] ([harbour]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[gl_harbour] TO [public]
GO
GRANT SELECT ON  [dbo].[gl_harbour] TO [public]
GO
GRANT INSERT ON  [dbo].[gl_harbour] TO [public]
GO
GRANT DELETE ON  [dbo].[gl_harbour] TO [public]
GO
GRANT UPDATE ON  [dbo].[gl_harbour] TO [public]
GO
