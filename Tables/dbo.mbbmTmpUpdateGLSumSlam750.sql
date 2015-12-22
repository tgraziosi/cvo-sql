CREATE TABLE [dbo].[mbbmTmpUpdateGLSumSlam750]
(
[SequenceID] [int] NULL,
[Acct] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Acct_Dim1] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[PerEnd] [int] NOT NULL,
[NetChange] [float] NOT NULL,
[EndBal] [float] NULL,
[CompanyCode] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[UserID] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Status] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[mbbmTmpUpdateGLSumSlam750] ADD CONSTRAINT [PK__mbbmTmpUpdateGLS__74B74343] PRIMARY KEY CLUSTERED  ([UserID], [CompanyCode], [Status], [Acct], [PerEnd], [Acct_Dim1]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[mbbmTmpUpdateGLSumSlam750] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmTmpUpdateGLSumSlam750] TO [Analytics]
GO
GRANT INSERT ON  [dbo].[mbbmTmpUpdateGLSumSlam750] TO [Analytics]
GO
GRANT DELETE ON  [dbo].[mbbmTmpUpdateGLSumSlam750] TO [Analytics]
GO
GRANT UPDATE ON  [dbo].[mbbmTmpUpdateGLSumSlam750] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmTmpUpdateGLSumSlam750] TO [public]
GO
GRANT INSERT ON  [dbo].[mbbmTmpUpdateGLSumSlam750] TO [public]
GO
GRANT DELETE ON  [dbo].[mbbmTmpUpdateGLSumSlam750] TO [public]
GO
GRANT UPDATE ON  [dbo].[mbbmTmpUpdateGLSumSlam750] TO [public]
GO
