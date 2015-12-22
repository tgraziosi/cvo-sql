CREATE TABLE [dbo].[mbbmTmpFormulaAccountDim]
(
[TimeStamp] [timestamp] NOT NULL,
[Spid] [int] NOT NULL,
[FormulaKey] [dbo].[mbbmudtFormulaKey] NOT NULL,
[Sequence] [smallint] NOT NULL,
[AccountDim] [dbo].[mbbmudtDimensionCode] NOT NULL,
[FromValue] [dbo].[mbbmudtAccountCode] NOT NULL,
[ThruValue] [dbo].[mbbmudtAccountCode] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[mbbmTmpFormulaAccountDim] ADD CONSTRAINT [PK_mbbmTmpFormulaAccountDim] PRIMARY KEY CLUSTERED  ([Spid], [FormulaKey], [Sequence], [AccountDim]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[mbbmTmpFormulaAccountDim] ADD CONSTRAINT [FK_mbbmTmpFormulaAccountDim] FOREIGN KEY ([Spid], [FormulaKey], [Sequence]) REFERENCES [dbo].[mbbmTmpFormulaLines] ([Spid], [FormulaKey], [Sequence])
GO
GRANT REFERENCES ON  [dbo].[mbbmTmpFormulaAccountDim] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmTmpFormulaAccountDim] TO [Analytics]
GO
GRANT INSERT ON  [dbo].[mbbmTmpFormulaAccountDim] TO [Analytics]
GO
GRANT DELETE ON  [dbo].[mbbmTmpFormulaAccountDim] TO [Analytics]
GO
GRANT UPDATE ON  [dbo].[mbbmTmpFormulaAccountDim] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmTmpFormulaAccountDim] TO [public]
GO
GRANT INSERT ON  [dbo].[mbbmTmpFormulaAccountDim] TO [public]
GO
GRANT DELETE ON  [dbo].[mbbmTmpFormulaAccountDim] TO [public]
GO
GRANT UPDATE ON  [dbo].[mbbmTmpFormulaAccountDim] TO [public]
GO
