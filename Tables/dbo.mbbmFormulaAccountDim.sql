CREATE TABLE [dbo].[mbbmFormulaAccountDim]
(
[TimeStamp] [timestamp] NOT NULL,
[HostCompany] [dbo].[mbbmudtCompanyCode] NOT NULL,
[FormulaType] [dbo].[mbbmudtFormulaType] NOT NULL,
[FormulaOwnerType] [tinyint] NOT NULL,
[FormulaOwnerID] [int] NOT NULL,
[FormulaKey] [dbo].[mbbmudtFormulaKey] NOT NULL,
[Sequence] [smallint] NOT NULL,
[AccountDim] [dbo].[mbbmudtDimensionCode] NOT NULL,
[FromValue] [dbo].[mbbmudtAccountCode] NOT NULL,
[ThruValue] [dbo].[mbbmudtAccountCode] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[mbbmFormulaAccountDim] ADD CONSTRAINT [PK_mbbmFormulaAccountDim] PRIMARY KEY CLUSTERED  ([HostCompany], [FormulaType], [FormulaOwnerType], [FormulaOwnerID], [FormulaKey], [Sequence], [AccountDim]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[mbbmFormulaAccountDim] ADD CONSTRAINT [FK_mbbmFormulaAccountDim] FOREIGN KEY ([HostCompany], [FormulaType], [FormulaOwnerType], [FormulaOwnerID], [FormulaKey], [Sequence]) REFERENCES [dbo].[mbbmFormulaLines74] ([HostCompany], [FormulaType], [FormulaOwnerType], [FormulaOwnerID], [FormulaKey], [Sequence])
GO
EXEC sp_bindrule N'[dbo].[mbbmrulFormulaType]', N'[dbo].[mbbmFormulaAccountDim].[FormulaType]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmFormulaAccountDim].[FormulaType]'
GO
GRANT REFERENCES ON  [dbo].[mbbmFormulaAccountDim] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmFormulaAccountDim] TO [Analytics]
GO
GRANT INSERT ON  [dbo].[mbbmFormulaAccountDim] TO [Analytics]
GO
GRANT DELETE ON  [dbo].[mbbmFormulaAccountDim] TO [Analytics]
GO
GRANT UPDATE ON  [dbo].[mbbmFormulaAccountDim] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmFormulaAccountDim] TO [public]
GO
GRANT INSERT ON  [dbo].[mbbmFormulaAccountDim] TO [public]
GO
GRANT DELETE ON  [dbo].[mbbmFormulaAccountDim] TO [public]
GO
GRANT UPDATE ON  [dbo].[mbbmFormulaAccountDim] TO [public]
GO
