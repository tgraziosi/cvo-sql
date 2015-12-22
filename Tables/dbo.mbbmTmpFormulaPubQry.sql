CREATE TABLE [dbo].[mbbmTmpFormulaPubQry]
(
[TimeStamp] [timestamp] NOT NULL,
[Spid] [int] NOT NULL,
[FormulaKey] [dbo].[mbbmudtFormulaKey] NOT NULL,
[Sequence] [smallint] NOT NULL,
[DimCode] [dbo].[mbbmudtDimensionCode] NOT NULL,
[FromValue] [varchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ThruValue] [varchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[AllValues] [dbo].[mbbmudtYesNo] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[mbbmTmpFormulaPubQry] ADD CONSTRAINT [PK_mbbmTmpFormulaPubQry] PRIMARY KEY CLUSTERED  ([Spid], [FormulaKey], [Sequence], [DimCode]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[mbbmTmpFormulaPubQry] ADD CONSTRAINT [FK_mbbmTmpFormulaPubQry] FOREIGN KEY ([Spid], [FormulaKey], [Sequence]) REFERENCES [dbo].[mbbmTmpFormulaLines] ([Spid], [FormulaKey], [Sequence])
GO
EXEC sp_bindrule N'[dbo].[mbbmrulYesNo]', N'[dbo].[mbbmTmpFormulaPubQry].[AllValues]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmTmpFormulaPubQry].[AllValues]'
GO
GRANT REFERENCES ON  [dbo].[mbbmTmpFormulaPubQry] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmTmpFormulaPubQry] TO [Analytics]
GO
GRANT INSERT ON  [dbo].[mbbmTmpFormulaPubQry] TO [Analytics]
GO
GRANT DELETE ON  [dbo].[mbbmTmpFormulaPubQry] TO [Analytics]
GO
GRANT UPDATE ON  [dbo].[mbbmTmpFormulaPubQry] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmTmpFormulaPubQry] TO [public]
GO
GRANT INSERT ON  [dbo].[mbbmTmpFormulaPubQry] TO [public]
GO
GRANT DELETE ON  [dbo].[mbbmTmpFormulaPubQry] TO [public]
GO
GRANT UPDATE ON  [dbo].[mbbmTmpFormulaPubQry] TO [public]
GO
