CREATE TABLE [dbo].[gl_department]
(
[timestamp] [timestamp] NOT NULL,
[department] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[department_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [gl_department_0] ON [dbo].[gl_department] ([department]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[gl_department] TO [public]
GO
GRANT SELECT ON  [dbo].[gl_department] TO [public]
GO
GRANT INSERT ON  [dbo].[gl_department] TO [public]
GO
GRANT DELETE ON  [dbo].[gl_department] TO [public]
GO
GRANT UPDATE ON  [dbo].[gl_department] TO [public]
GO
