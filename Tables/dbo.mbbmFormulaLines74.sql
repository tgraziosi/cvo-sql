CREATE TABLE [dbo].[mbbmFormulaLines74]
(
[TimeStamp] [timestamp] NOT NULL,
[HostCompany] [dbo].[mbbmudtCompanyCode] NOT NULL,
[FormulaType] [dbo].[mbbmudtFormulaType] NOT NULL,
[FormulaOwnerType] [tinyint] NOT NULL,
[FormulaOwnerID] [int] NOT NULL,
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
ALTER TABLE [dbo].[mbbmFormulaLines74] ADD CONSTRAINT [CK_mbbmFormulaLines74_LineType] CHECK (([LineType]=(6) OR [LineType]=(5) OR [LineType]=(4) OR [LineType]=(3) OR [LineType]=(2) OR [LineType]=(1) OR [LineType]=(0)))
GO
ALTER TABLE [dbo].[mbbmFormulaLines74] ADD CONSTRAINT [PK_mbbmFormulaLines74] PRIMARY KEY CLUSTERED  ([HostCompany], [FormulaType], [FormulaOwnerType], [FormulaOwnerID], [FormulaKey], [Sequence]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[mbbmFormulaLines74] ADD CONSTRAINT [FK_mbbmFormulaLines74] FOREIGN KEY ([HostCompany], [FormulaType], [FormulaOwnerType], [FormulaOwnerID], [FormulaKey]) REFERENCES [dbo].[mbbmFormula74] ([HostCompany], [FormulaType], [FormulaOwnerType], [FormulaOwnerID], [FormulaKey])
GO
EXEC sp_bindrule N'[dbo].[mbbmrulFormulaType]', N'[dbo].[mbbmFormulaLines74].[FormulaType]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmFormulaLines74].[FormulaType]'
GO
EXEC sp_bindrule N'[dbo].[mbbmrulYesNo]', N'[dbo].[mbbmFormulaLines74].[OpenParen]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmFormulaLines74].[OpenParen]'
GO
EXEC sp_bindrule N'[dbo].[mbbmrulYear]', N'[dbo].[mbbmFormulaLines74].[Year]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmFormulaLines74].[Year]'
GO
EXEC sp_bindrule N'[dbo].[mbbmrulPeriodType]', N'[dbo].[mbbmFormulaLines74].[FromPeriodType]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmFormulaLines74].[FromPeriodType]'
GO
EXEC sp_bindrule N'[dbo].[mbbmrulPeriodType]', N'[dbo].[mbbmFormulaLines74].[ThruPeriodType]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmFormulaLines74].[ThruPeriodType]'
GO
EXEC sp_bindrule N'[dbo].[mbbmrulHomeNatural]', N'[dbo].[mbbmFormulaLines74].[HomeNatural]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmFormulaLines74].[HomeNatural]'
GO
EXEC sp_bindrule N'[dbo].[mbbmrulValMethod]', N'[dbo].[mbbmFormulaLines74].[ValuationMethod]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef3]', N'[dbo].[mbbmFormulaLines74].[ValuationMethod]'
GO
EXEC sp_bindrule N'[dbo].[mbbmrulYesNo]', N'[dbo].[mbbmFormulaLines74].[CloseParen]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmFormulaLines74].[CloseParen]'
GO
EXEC sp_bindrule N'[dbo].[mbbmrulOperation]', N'[dbo].[mbbmFormulaLines74].[Operation]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmFormulaLines74].[Operation]'
GO
GRANT REFERENCES ON  [dbo].[mbbmFormulaLines74] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmFormulaLines74] TO [Analytics]
GO
GRANT INSERT ON  [dbo].[mbbmFormulaLines74] TO [Analytics]
GO
GRANT DELETE ON  [dbo].[mbbmFormulaLines74] TO [Analytics]
GO
GRANT UPDATE ON  [dbo].[mbbmFormulaLines74] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmFormulaLines74] TO [public]
GO
GRANT INSERT ON  [dbo].[mbbmFormulaLines74] TO [public]
GO
GRANT DELETE ON  [dbo].[mbbmFormulaLines74] TO [public]
GO
GRANT UPDATE ON  [dbo].[mbbmFormulaLines74] TO [public]
GO
