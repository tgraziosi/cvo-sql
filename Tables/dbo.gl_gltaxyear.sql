CREATE TABLE [dbo].[gl_gltaxyear]
(
[timestamp] [timestamp] NOT NULL,
[ykey] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[year_begin] [int] NOT NULL,
[year_end] [int] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [gl_gltaxyear_0] ON [dbo].[gl_gltaxyear] ([ykey]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[gl_gltaxyear] TO [public]
GO
GRANT SELECT ON  [dbo].[gl_gltaxyear] TO [public]
GO
GRANT INSERT ON  [dbo].[gl_gltaxyear] TO [public]
GO
GRANT DELETE ON  [dbo].[gl_gltaxyear] TO [public]
GO
GRANT UPDATE ON  [dbo].[gl_gltaxyear] TO [public]
GO
