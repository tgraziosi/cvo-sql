CREATE TABLE [dbo].[mbbmTmpFormulaLines]
(
[TimeStamp] [timestamp] NOT NULL,
[Spid] [int] NOT NULL,
[FormulaKey] [dbo].[mbbmudtFormulaKey] NOT NULL,
[Sequence] [smallint] NOT NULL,
[OpenParen] [dbo].[mbbmudtYesNo] NOT NULL,
[LineType] [tinyint] NOT NULL,
[Year] [dbo].[mbbmudtYear] NOT NULL,
[FromPeriodType] [dbo].[mbbmudtPeriodType] NOT NULL,
[FromPeriodNo] [smallint] NOT NULL,
[ThruPeriodType] [dbo].[mbbmudtPeriodType] NOT NULL,
[ThruPeriodNo] [smallint] NOT NULL,
[BalanceType] [tinyint] NOT NULL,
[BalanceTypeCode] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[CompanyCode] [dbo].[mbbmudtCompanyCode] NULL,
[Currency] [dbo].[mbbmudtCurrencyCode] NOT NULL,
[HomeNatural] [dbo].[mbbmudtHomeNatural] NOT NULL,
[ValuationMethod] [dbo].[mbbmudtValMethod] NOT NULL,
[Constant] [float] NOT NULL,
[FromAcct] [dbo].[mbbmudtAccountCode] NOT NULL,
[ThruAcct] [dbo].[mbbmudtAccountCode] NOT NULL,
[CloseParen] [dbo].[mbbmudtYesNo] NOT NULL,
[Operation] [dbo].[mbbmudtOperation] NOT NULL,
[ReferenceType] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ReferenceValue] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[mbbmTmpFormulaLines] ADD CONSTRAINT [CK_mbbmTmpFormulaLines_LinTyp] CHECK (([LineType]=(6) OR [LineType]=(5) OR [LineType]=(4) OR [LineType]=(3) OR [LineType]=(2) OR [LineType]=(1) OR [LineType]=(0)))
GO
ALTER TABLE [dbo].[mbbmTmpFormulaLines] ADD CONSTRAINT [PK_mbbmTmpFormulaLines] PRIMARY KEY CLUSTERED  ([Spid], [FormulaKey], [Sequence]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[mbbmTmpFormulaLines] ADD CONSTRAINT [FK_mbbmTmpFormulaLines] FOREIGN KEY ([Spid], [FormulaKey]) REFERENCES [dbo].[mbbmTmpFormula] ([Spid], [FormulaKey])
GO
EXEC sp_bindrule N'[dbo].[mbbmrulYesNo]', N'[dbo].[mbbmTmpFormulaLines].[OpenParen]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmTmpFormulaLines].[OpenParen]'
GO
EXEC sp_bindrule N'[dbo].[mbbmrulYear]', N'[dbo].[mbbmTmpFormulaLines].[Year]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmTmpFormulaLines].[Year]'
GO
EXEC sp_bindrule N'[dbo].[mbbmrulPeriodType]', N'[dbo].[mbbmTmpFormulaLines].[FromPeriodType]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmTmpFormulaLines].[FromPeriodType]'
GO
EXEC sp_bindrule N'[dbo].[mbbmrulPeriodType]', N'[dbo].[mbbmTmpFormulaLines].[ThruPeriodType]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmTmpFormulaLines].[ThruPeriodType]'
GO
EXEC sp_bindrule N'[dbo].[mbbmrulHomeNatural]', N'[dbo].[mbbmTmpFormulaLines].[HomeNatural]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmTmpFormulaLines].[HomeNatural]'
GO
EXEC sp_bindrule N'[dbo].[mbbmrulValMethod]', N'[dbo].[mbbmTmpFormulaLines].[ValuationMethod]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef3]', N'[dbo].[mbbmTmpFormulaLines].[ValuationMethod]'
GO
EXEC sp_bindrule N'[dbo].[mbbmrulYesNo]', N'[dbo].[mbbmTmpFormulaLines].[CloseParen]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmTmpFormulaLines].[CloseParen]'
GO
EXEC sp_bindrule N'[dbo].[mbbmrulOperation]', N'[dbo].[mbbmTmpFormulaLines].[Operation]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmTmpFormulaLines].[Operation]'
GO
GRANT REFERENCES ON  [dbo].[mbbmTmpFormulaLines] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmTmpFormulaLines] TO [Analytics]
GO
GRANT INSERT ON  [dbo].[mbbmTmpFormulaLines] TO [Analytics]
GO
GRANT DELETE ON  [dbo].[mbbmTmpFormulaLines] TO [Analytics]
GO
GRANT UPDATE ON  [dbo].[mbbmTmpFormulaLines] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmTmpFormulaLines] TO [public]
GO
GRANT INSERT ON  [dbo].[mbbmTmpFormulaLines] TO [public]
GO
GRANT DELETE ON  [dbo].[mbbmTmpFormulaLines] TO [public]
GO
GRANT UPDATE ON  [dbo].[mbbmTmpFormulaLines] TO [public]
GO
