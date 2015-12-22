CREATE TABLE [dbo].[gl_regime]
(
[timestamp] [timestamp] NOT NULL,
[regime] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[regime_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [gl_regime_0] ON [dbo].[gl_regime] ([regime]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[gl_regime] TO [public]
GO
GRANT SELECT ON  [dbo].[gl_regime] TO [public]
GO
GRANT INSERT ON  [dbo].[gl_regime] TO [public]
GO
GRANT DELETE ON  [dbo].[gl_regime] TO [public]
GO
GRANT UPDATE ON  [dbo].[gl_regime] TO [public]
GO
