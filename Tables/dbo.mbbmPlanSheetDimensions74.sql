CREATE TABLE [dbo].[mbbmPlanSheetDimensions74]
(
[TimeStamp] [timestamp] NOT NULL,
[RevisionID] [int] NOT NULL,
[Axis] [tinyint] NOT NULL,
[Member] [tinyint] NOT NULL,
[TierCode] [dbo].[mbbmudtDimensionCode] NOT NULL,
[GroupCode] [dbo].[mbbmudtDimensionCode] NOT NULL,
[Code] [dbo].[mbbmudtDimensionCode] NOT NULL,
[FromValue] [varchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ThruValue] [varchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Mask] [varchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Length] [int] NOT NULL,
[Flags] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[mbbmPlanSheetDimensions74] ADD CONSTRAINT [PK_mbbmPlanSheetDimensions74] PRIMARY KEY CLUSTERED  ([RevisionID], [Axis], [Member], [Code]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[mbbmPlanSheetDimensions74] ADD CONSTRAINT [FK_mbbmPlanSheetDimensions74_RevisionID] FOREIGN KEY ([RevisionID]) REFERENCES [dbo].[mbbmPlanSheetRev74] ([RevisionID])
GO
GRANT REFERENCES ON  [dbo].[mbbmPlanSheetDimensions74] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmPlanSheetDimensions74] TO [Analytics]
GO
GRANT INSERT ON  [dbo].[mbbmPlanSheetDimensions74] TO [Analytics]
GO
GRANT DELETE ON  [dbo].[mbbmPlanSheetDimensions74] TO [Analytics]
GO
GRANT UPDATE ON  [dbo].[mbbmPlanSheetDimensions74] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmPlanSheetDimensions74] TO [public]
GO
GRANT INSERT ON  [dbo].[mbbmPlanSheetDimensions74] TO [public]
GO
GRANT DELETE ON  [dbo].[mbbmPlanSheetDimensions74] TO [public]
GO
GRANT UPDATE ON  [dbo].[mbbmPlanSheetDimensions74] TO [public]
GO
