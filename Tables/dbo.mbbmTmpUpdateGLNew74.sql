CREATE TABLE [dbo].[mbbmTmpUpdateGLNew74]
(
[Acct] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Acct_Dim1] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[PerEnd] [int] NOT NULL,
[NetChange] [float] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[mbbmTmpUpdateGLNew74] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmTmpUpdateGLNew74] TO [Analytics]
GO
GRANT INSERT ON  [dbo].[mbbmTmpUpdateGLNew74] TO [Analytics]
GO
GRANT DELETE ON  [dbo].[mbbmTmpUpdateGLNew74] TO [Analytics]
GO
GRANT UPDATE ON  [dbo].[mbbmTmpUpdateGLNew74] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmTmpUpdateGLNew74] TO [public]
GO
GRANT INSERT ON  [dbo].[mbbmTmpUpdateGLNew74] TO [public]
GO
GRANT DELETE ON  [dbo].[mbbmTmpUpdateGLNew74] TO [public]
GO
GRANT UPDATE ON  [dbo].[mbbmTmpUpdateGLNew74] TO [public]
GO
