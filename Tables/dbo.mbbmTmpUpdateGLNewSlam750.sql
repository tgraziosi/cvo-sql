CREATE TABLE [dbo].[mbbmTmpUpdateGLNewSlam750]
(
[Acct] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Acct_Dim1] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[CompanyCode] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[UserID] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[PerEnd] [int] NOT NULL,
[NetChange] [float] NOT NULL,
[Status] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IDX_mbbmTmpUpdateGLNewSlam750] ON [dbo].[mbbmTmpUpdateGLNewSlam750] ([CompanyCode], [UserID]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[mbbmTmpUpdateGLNewSlam750] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmTmpUpdateGLNewSlam750] TO [Analytics]
GO
GRANT INSERT ON  [dbo].[mbbmTmpUpdateGLNewSlam750] TO [Analytics]
GO
GRANT DELETE ON  [dbo].[mbbmTmpUpdateGLNewSlam750] TO [Analytics]
GO
GRANT UPDATE ON  [dbo].[mbbmTmpUpdateGLNewSlam750] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmTmpUpdateGLNewSlam750] TO [public]
GO
GRANT INSERT ON  [dbo].[mbbmTmpUpdateGLNewSlam750] TO [public]
GO
GRANT DELETE ON  [dbo].[mbbmTmpUpdateGLNewSlam750] TO [public]
GO
GRANT UPDATE ON  [dbo].[mbbmTmpUpdateGLNewSlam750] TO [public]
GO
