CREATE TABLE [dbo].[mbbmPlanHfc]
(
[TimeStamp] [timestamp] NOT NULL,
[RevisionID] [int] NOT NULL,
[CellType] [tinyint] NOT NULL,
[Section] [tinyint] NOT NULL,
[Line] [tinyint] NOT NULL,
[Text] [varchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[FontName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[FontSize] [float] NOT NULL,
[FontAttrib] [smallint] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[mbbmPlanHfc] ADD CONSTRAINT [PK_mbbmPlanHfc] PRIMARY KEY CLUSTERED  ([RevisionID], [CellType], [Section], [Line]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[mbbmPlanHfc] ADD CONSTRAINT [FK_mbbmPlanHfc_RevisionID] FOREIGN KEY ([RevisionID]) REFERENCES [dbo].[mbbmPlanSheetRev74] ([RevisionID])
GO
GRANT REFERENCES ON  [dbo].[mbbmPlanHfc] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmPlanHfc] TO [Analytics]
GO
GRANT INSERT ON  [dbo].[mbbmPlanHfc] TO [Analytics]
GO
GRANT DELETE ON  [dbo].[mbbmPlanHfc] TO [Analytics]
GO
GRANT UPDATE ON  [dbo].[mbbmPlanHfc] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmPlanHfc] TO [public]
GO
GRANT INSERT ON  [dbo].[mbbmPlanHfc] TO [public]
GO
GRANT DELETE ON  [dbo].[mbbmPlanHfc] TO [public]
GO
GRANT UPDATE ON  [dbo].[mbbmPlanHfc] TO [public]
GO
