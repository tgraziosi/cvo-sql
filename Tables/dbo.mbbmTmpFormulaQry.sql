CREATE TABLE [dbo].[mbbmTmpFormulaQry]
(
[TimeStamp] [timestamp] NOT NULL,
[Spid] [int] NOT NULL,
[FormulaKey] [dbo].[mbbmudtFormulaKey] NOT NULL,
[Sequence] [smallint] NOT NULL,
[DataSourceType] [smallint] NULL,
[Connect] [image] NOT NULL,
[QueryOptions] [int] NULL,
[Advanced] [tinyint] NOT NULL,
[Query] [image] NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[mbbmTmpFormulaQry] ADD CONSTRAINT [PK_mbbmTmpFormulaQry] PRIMARY KEY CLUSTERED  ([Spid], [FormulaKey], [Sequence]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[mbbmTmpFormulaQry] ADD CONSTRAINT [FK_mbbmTmpFormulaQry] FOREIGN KEY ([Spid], [FormulaKey], [Sequence]) REFERENCES [dbo].[mbbmTmpFormulaLines] ([Spid], [FormulaKey], [Sequence])
GO
GRANT REFERENCES ON  [dbo].[mbbmTmpFormulaQry] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmTmpFormulaQry] TO [Analytics]
GO
GRANT INSERT ON  [dbo].[mbbmTmpFormulaQry] TO [Analytics]
GO
GRANT DELETE ON  [dbo].[mbbmTmpFormulaQry] TO [Analytics]
GO
GRANT UPDATE ON  [dbo].[mbbmTmpFormulaQry] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmTmpFormulaQry] TO [public]
GO
GRANT INSERT ON  [dbo].[mbbmTmpFormulaQry] TO [public]
GO
GRANT DELETE ON  [dbo].[mbbmTmpFormulaQry] TO [public]
GO
GRANT UPDATE ON  [dbo].[mbbmTmpFormulaQry] TO [public]
GO
