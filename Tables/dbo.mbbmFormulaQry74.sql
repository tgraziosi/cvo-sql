CREATE TABLE [dbo].[mbbmFormulaQry74]
(
[TimeStamp] [timestamp] NOT NULL,
[HostCompany] [dbo].[mbbmudtCompanyCode] NOT NULL,
[FormulaType] [dbo].[mbbmudtFormulaType] NOT NULL,
[FormulaOwnerType] [tinyint] NOT NULL,
[FormulaOwnerID] [int] NOT NULL,
[FormulaKey] [dbo].[mbbmudtFormulaKey] NOT NULL,
[Sequence] [smallint] NOT NULL,
[DataSourceType] [smallint] NULL,
[Connect] [image] NOT NULL,
[QueryOptions] [int] NULL,
[Advanced] [tinyint] NOT NULL,
[Query] [image] NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[mbbmFormulaQry74] ADD CONSTRAINT [PK_mbbmFormulaQry74] PRIMARY KEY CLUSTERED  ([HostCompany], [FormulaType], [FormulaOwnerType], [FormulaOwnerID], [FormulaKey], [Sequence]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[mbbmFormulaQry74] ADD CONSTRAINT [FK_mbbmFormulaQry74] FOREIGN KEY ([HostCompany], [FormulaType], [FormulaOwnerType], [FormulaOwnerID], [FormulaKey], [Sequence]) REFERENCES [dbo].[mbbmFormulaLines74] ([HostCompany], [FormulaType], [FormulaOwnerType], [FormulaOwnerID], [FormulaKey], [Sequence])
GO
EXEC sp_bindrule N'[dbo].[mbbmrulFormulaType]', N'[dbo].[mbbmFormulaQry74].[FormulaType]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmFormulaQry74].[FormulaType]'
GO
GRANT REFERENCES ON  [dbo].[mbbmFormulaQry74] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmFormulaQry74] TO [Analytics]
GO
GRANT INSERT ON  [dbo].[mbbmFormulaQry74] TO [Analytics]
GO
GRANT DELETE ON  [dbo].[mbbmFormulaQry74] TO [Analytics]
GO
GRANT UPDATE ON  [dbo].[mbbmFormulaQry74] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmFormulaQry74] TO [public]
GO
GRANT INSERT ON  [dbo].[mbbmFormulaQry74] TO [public]
GO
GRANT DELETE ON  [dbo].[mbbmFormulaQry74] TO [public]
GO
GRANT UPDATE ON  [dbo].[mbbmFormulaQry74] TO [public]
GO
