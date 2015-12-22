CREATE TABLE [dbo].[gl_indicator]
(
[timestamp] [timestamp] NOT NULL,
[indicator] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[indicator_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [gl_indicator_0] ON [dbo].[gl_indicator] ([indicator]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[gl_indicator] TO [public]
GO
GRANT SELECT ON  [dbo].[gl_indicator] TO [public]
GO
GRANT INSERT ON  [dbo].[gl_indicator] TO [public]
GO
GRANT DELETE ON  [dbo].[gl_indicator] TO [public]
GO
GRANT UPDATE ON  [dbo].[gl_indicator] TO [public]
GO
