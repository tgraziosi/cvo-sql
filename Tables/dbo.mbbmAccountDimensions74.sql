CREATE TABLE [dbo].[mbbmAccountDimensions74]
(
[HostCompany] [dbo].[mbbmudtCompanyCode] NOT NULL,
[Dimension_Num] [int] NOT NULL,
[Dimension_Code] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Dimension_Mask] [dbo].[mbbmudtAccountCode] NOT NULL,
[Description] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Dimension_Active] [dbo].[mbbmudtYesNo] NOT NULL,
[TimeStamp] [timestamp] NOT NULL,
[UpdatedBy] [dbo].[mbbmudtUser] NOT NULL,
[UpdatedTime] [dbo].[mbbmudtTagDate] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[mbbmAccountDimensions74] ADD CONSTRAINT [PK_mbbmAccountDimensions74] UNIQUE NONCLUSTERED  ([HostCompany], [Dimension_Code]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[mbbmAccountDimensions74] ADD CONSTRAINT [UK_mbbmAccountDimensions74] UNIQUE NONCLUSTERED  ([HostCompany], [Dimension_Num]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[mbbmrulYesNo]', N'[dbo].[mbbmAccountDimensions74].[Dimension_Active]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmAccountDimensions74].[Dimension_Active]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefEmpty]', N'[dbo].[mbbmAccountDimensions74].[UpdatedBy]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdefDate]', N'[dbo].[mbbmAccountDimensions74].[UpdatedTime]'
GO
GRANT REFERENCES ON  [dbo].[mbbmAccountDimensions74] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmAccountDimensions74] TO [Analytics]
GO
GRANT INSERT ON  [dbo].[mbbmAccountDimensions74] TO [Analytics]
GO
GRANT DELETE ON  [dbo].[mbbmAccountDimensions74] TO [Analytics]
GO
GRANT UPDATE ON  [dbo].[mbbmAccountDimensions74] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmAccountDimensions74] TO [public]
GO
GRANT INSERT ON  [dbo].[mbbmAccountDimensions74] TO [public]
GO
GRANT DELETE ON  [dbo].[mbbmAccountDimensions74] TO [public]
GO
GRANT UPDATE ON  [dbo].[mbbmAccountDimensions74] TO [public]
GO
