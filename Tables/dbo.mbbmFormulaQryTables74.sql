CREATE TABLE [dbo].[mbbmFormulaQryTables74]
(
[TimeStamp] [timestamp] NOT NULL,
[HostCompany] [dbo].[mbbmudtCompanyCode] NOT NULL,
[FormulaType] [dbo].[mbbmudtFormulaType] NOT NULL,
[FormulaOwnerType] [tinyint] NOT NULL,
[FormulaOwnerID] [int] NOT NULL,
[FormulaKey] [dbo].[mbbmudtFormulaKey] NOT NULL,
[Sequence] [smallint] NOT NULL,
[TableSequence] [int] NOT NULL,
[Alias] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[TableSpec] [varchar] (256) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[LinkedServer] [smallint] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[mbbmFormulaQryTables74] ADD CONSTRAINT [PK_mbbmFormulaQryTables74] PRIMARY KEY CLUSTERED  ([HostCompany], [FormulaType], [FormulaOwnerType], [FormulaOwnerID], [FormulaKey], [Sequence], [TableSequence]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[mbbmFormulaQryTables74] ADD CONSTRAINT [FK_mbbmFormulaQryTables74] FOREIGN KEY ([HostCompany], [FormulaType], [FormulaOwnerType], [FormulaOwnerID], [FormulaKey], [Sequence]) REFERENCES [dbo].[mbbmFormulaQry74] ([HostCompany], [FormulaType], [FormulaOwnerType], [FormulaOwnerID], [FormulaKey], [Sequence])
GO
EXEC sp_bindrule N'[dbo].[mbbmrulFormulaType]', N'[dbo].[mbbmFormulaQryTables74].[FormulaType]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmFormulaQryTables74].[FormulaType]'
GO
GRANT REFERENCES ON  [dbo].[mbbmFormulaQryTables74] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmFormulaQryTables74] TO [Analytics]
GO
GRANT INSERT ON  [dbo].[mbbmFormulaQryTables74] TO [Analytics]
GO
GRANT DELETE ON  [dbo].[mbbmFormulaQryTables74] TO [Analytics]
GO
GRANT UPDATE ON  [dbo].[mbbmFormulaQryTables74] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmFormulaQryTables74] TO [public]
GO
GRANT INSERT ON  [dbo].[mbbmFormulaQryTables74] TO [public]
GO
GRANT DELETE ON  [dbo].[mbbmFormulaQryTables74] TO [public]
GO
GRANT UPDATE ON  [dbo].[mbbmFormulaQryTables74] TO [public]
GO
