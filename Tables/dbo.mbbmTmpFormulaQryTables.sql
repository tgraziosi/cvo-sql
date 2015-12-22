CREATE TABLE [dbo].[mbbmTmpFormulaQryTables]
(
[TimeStamp] [timestamp] NOT NULL,
[Spid] [int] NOT NULL,
[FormulaKey] [dbo].[mbbmudtFormulaKey] NOT NULL,
[Sequence] [smallint] NOT NULL,
[TableSequence] [int] NOT NULL,
[Alias] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[TableSpec] [varchar] (256) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[LinkedServer] [smallint] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[mbbmTmpFormulaQryTables] ADD CONSTRAINT [PK_mbbmTmpFormulaQryTables] PRIMARY KEY CLUSTERED  ([Spid], [FormulaKey], [Sequence], [TableSequence]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[mbbmTmpFormulaQryTables] ADD CONSTRAINT [FK_mbbmTmpFormulaQryTables] FOREIGN KEY ([Spid], [FormulaKey], [Sequence]) REFERENCES [dbo].[mbbmTmpFormulaQry] ([Spid], [FormulaKey], [Sequence])
GO
GRANT REFERENCES ON  [dbo].[mbbmTmpFormulaQryTables] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmTmpFormulaQryTables] TO [Analytics]
GO
GRANT INSERT ON  [dbo].[mbbmTmpFormulaQryTables] TO [Analytics]
GO
GRANT DELETE ON  [dbo].[mbbmTmpFormulaQryTables] TO [Analytics]
GO
GRANT UPDATE ON  [dbo].[mbbmTmpFormulaQryTables] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmTmpFormulaQryTables] TO [public]
GO
GRANT INSERT ON  [dbo].[mbbmTmpFormulaQryTables] TO [public]
GO
GRANT DELETE ON  [dbo].[mbbmTmpFormulaQryTables] TO [public]
GO
GRANT UPDATE ON  [dbo].[mbbmTmpFormulaQryTables] TO [public]
GO
