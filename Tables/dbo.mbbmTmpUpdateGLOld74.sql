CREATE TABLE [dbo].[mbbmTmpUpdateGLOld74]
(
[SequenceID] [int] NULL,
[Acct] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Acct_Dim1] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[PerEnd] [int] NOT NULL,
[NetChange] [float] NOT NULL,
[EndBal] [float] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[mbbmTmpUpdateGLOld74] ADD CONSTRAINT [PK__mbbmTmpUpdateGLO__70E6B25F] PRIMARY KEY CLUSTERED  ([Acct], [Acct_Dim1], [PerEnd]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[mbbmTmpUpdateGLOld74] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmTmpUpdateGLOld74] TO [Analytics]
GO
GRANT INSERT ON  [dbo].[mbbmTmpUpdateGLOld74] TO [Analytics]
GO
GRANT DELETE ON  [dbo].[mbbmTmpUpdateGLOld74] TO [Analytics]
GO
GRANT UPDATE ON  [dbo].[mbbmTmpUpdateGLOld74] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmTmpUpdateGLOld74] TO [public]
GO
GRANT INSERT ON  [dbo].[mbbmTmpUpdateGLOld74] TO [public]
GO
GRANT DELETE ON  [dbo].[mbbmTmpUpdateGLOld74] TO [public]
GO
GRANT UPDATE ON  [dbo].[mbbmTmpUpdateGLOld74] TO [public]
GO
