CREATE TABLE [dbo].[gl_gltaxprd]
(
[timestamp] [timestamp] NOT NULL,
[ykey] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[period_start_date] [int] NOT NULL,
[period_end_date] [int] NOT NULL,
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [gl_gltaxprd_0] ON [dbo].[gl_gltaxprd] ([ykey], [period_start_date]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[gl_gltaxprd] TO [public]
GO
GRANT SELECT ON  [dbo].[gl_gltaxprd] TO [public]
GO
GRANT INSERT ON  [dbo].[gl_gltaxprd] TO [public]
GO
GRANT DELETE ON  [dbo].[gl_gltaxprd] TO [public]
GO
GRANT UPDATE ON  [dbo].[gl_gltaxprd] TO [public]
GO
