CREATE TABLE [dbo].[mbbmPlanColSet]
(
[TimeStamp] [timestamp] NOT NULL,
[RevisionID] [int] NOT NULL,
[ColSetKey] [dbo].[mbbmudtGroupKey] NOT NULL,
[Description] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[mbbmPlanColSet] ADD CONSTRAINT [PK_mbbmPlanColSet] PRIMARY KEY CLUSTERED  ([RevisionID], [ColSetKey]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[mbbmPlanColSet] ADD CONSTRAINT [FK_mbbmPlanColSet_RevisionID] FOREIGN KEY ([RevisionID]) REFERENCES [dbo].[mbbmPlanSheetRev74] ([RevisionID])
GO
GRANT REFERENCES ON  [dbo].[mbbmPlanColSet] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmPlanColSet] TO [Analytics]
GO
GRANT INSERT ON  [dbo].[mbbmPlanColSet] TO [Analytics]
GO
GRANT DELETE ON  [dbo].[mbbmPlanColSet] TO [Analytics]
GO
GRANT UPDATE ON  [dbo].[mbbmPlanColSet] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmPlanColSet] TO [public]
GO
GRANT INSERT ON  [dbo].[mbbmPlanColSet] TO [public]
GO
GRANT DELETE ON  [dbo].[mbbmPlanColSet] TO [public]
GO
GRANT UPDATE ON  [dbo].[mbbmPlanColSet] TO [public]
GO
