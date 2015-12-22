CREATE TABLE [dbo].[mbbmFormulaPubQry]
(
[TimeStamp] [timestamp] NOT NULL,
[HostCompany] [dbo].[mbbmudtCompanyCode] NOT NULL,
[FormulaType] [dbo].[mbbmudtFormulaType] NOT NULL,
[FormulaOwnerType] [tinyint] NOT NULL,
[FormulaOwnerID] [int] NOT NULL,
[FormulaKey] [dbo].[mbbmudtFormulaKey] NOT NULL,
[Sequence] [smallint] NOT NULL,
[DimCode] [dbo].[mbbmudtDimensionCode] NOT NULL,
[FromValue] [varchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ThruValue] [varchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[AllValues] [dbo].[mbbmudtYesNo] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[mbbmFormulaPubQry] ADD CONSTRAINT [PK_mbbmFormulaPubQry] PRIMARY KEY CLUSTERED  ([HostCompany], [FormulaType], [FormulaOwnerType], [FormulaOwnerID], [FormulaKey], [Sequence], [DimCode]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[mbbmFormulaPubQry] ADD CONSTRAINT [FK_mbbmFormulaPubQry] FOREIGN KEY ([HostCompany], [FormulaType], [FormulaOwnerType], [FormulaOwnerID], [FormulaKey], [Sequence]) REFERENCES [dbo].[mbbmFormulaLines74] ([HostCompany], [FormulaType], [FormulaOwnerType], [FormulaOwnerID], [FormulaKey], [Sequence])
GO
EXEC sp_bindrule N'[dbo].[mbbmrulFormulaType]', N'[dbo].[mbbmFormulaPubQry].[FormulaType]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmFormulaPubQry].[FormulaType]'
GO
EXEC sp_bindrule N'[dbo].[mbbmrulYesNo]', N'[dbo].[mbbmFormulaPubQry].[AllValues]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmFormulaPubQry].[AllValues]'
GO
GRANT REFERENCES ON  [dbo].[mbbmFormulaPubQry] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmFormulaPubQry] TO [Analytics]
GO
GRANT INSERT ON  [dbo].[mbbmFormulaPubQry] TO [Analytics]
GO
GRANT DELETE ON  [dbo].[mbbmFormulaPubQry] TO [Analytics]
GO
GRANT UPDATE ON  [dbo].[mbbmFormulaPubQry] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmFormulaPubQry] TO [public]
GO
GRANT INSERT ON  [dbo].[mbbmFormulaPubQry] TO [public]
GO
GRANT DELETE ON  [dbo].[mbbmFormulaPubQry] TO [public]
GO
GRANT UPDATE ON  [dbo].[mbbmFormulaPubQry] TO [public]
GO
