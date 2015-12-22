CREATE TABLE [dbo].[mbbmPlanSheetSections]
(
[TimeStamp] [timestamp] NOT NULL,
[RevisionID] [int] NOT NULL,
[SectionKey] [dbo].[mbbmudtSubBudgetKey] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[mbbmPlanSheetSections] ADD CONSTRAINT [PK_mbbmPlanSheetSections] PRIMARY KEY CLUSTERED  ([RevisionID], [SectionKey]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[mbbmPlanSheetSections] ADD CONSTRAINT [FK_mbbmPlanSheetSections_RvID] FOREIGN KEY ([RevisionID]) REFERENCES [dbo].[mbbmPlanSheetRev74] ([RevisionID])
GO
GRANT REFERENCES ON  [dbo].[mbbmPlanSheetSections] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmPlanSheetSections] TO [Analytics]
GO
GRANT INSERT ON  [dbo].[mbbmPlanSheetSections] TO [Analytics]
GO
GRANT DELETE ON  [dbo].[mbbmPlanSheetSections] TO [Analytics]
GO
GRANT UPDATE ON  [dbo].[mbbmPlanSheetSections] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmPlanSheetSections] TO [public]
GO
GRANT INSERT ON  [dbo].[mbbmPlanSheetSections] TO [public]
GO
GRANT DELETE ON  [dbo].[mbbmPlanSheetSections] TO [public]
GO
GRANT UPDATE ON  [dbo].[mbbmPlanSheetSections] TO [public]
GO
