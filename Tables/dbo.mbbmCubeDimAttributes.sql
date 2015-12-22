CREATE TABLE [dbo].[mbbmCubeDimAttributes]
(
[TimeStamp] [timestamp] NOT NULL,
[HostCompany] [dbo].[mbbmudtCompanyCode] NOT NULL,
[CubeName] [dbo].[mbbmudtOLAPCubeName] NOT NULL,
[Dimension] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Attribute] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[PublishMethod] [dbo].[mbbmudtPublishMethod] NOT NULL,
[MemberNameType] [dbo].[mbbmudtMemberNameType] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[mbbmCubeDimAttributes] ADD CONSTRAINT [PK_mbbmCubeDimAttributes] UNIQUE NONCLUSTERED  ([HostCompany], [CubeName], [Dimension], [Attribute]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[mbbmCubeDimAttributes] ADD CONSTRAINT [FK_mbbmCubeDimAttributes_Cube] FOREIGN KEY ([HostCompany], [CubeName]) REFERENCES [dbo].[mbbmCubes75] ([HostCompany], [Name])
GO
EXEC sp_bindrule N'[dbo].[mbbmrulPublishMethod]', N'[dbo].[mbbmCubeDimAttributes].[PublishMethod]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmCubeDimAttributes].[PublishMethod]'
GO
EXEC sp_bindrule N'[dbo].[mbbmrulMemberNameType]', N'[dbo].[mbbmCubeDimAttributes].[MemberNameType]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmCubeDimAttributes].[MemberNameType]'
GO
GRANT REFERENCES ON  [dbo].[mbbmCubeDimAttributes] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmCubeDimAttributes] TO [Analytics]
GO
GRANT INSERT ON  [dbo].[mbbmCubeDimAttributes] TO [Analytics]
GO
GRANT DELETE ON  [dbo].[mbbmCubeDimAttributes] TO [Analytics]
GO
GRANT UPDATE ON  [dbo].[mbbmCubeDimAttributes] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmCubeDimAttributes] TO [public]
GO
GRANT INSERT ON  [dbo].[mbbmCubeDimAttributes] TO [public]
GO
GRANT DELETE ON  [dbo].[mbbmCubeDimAttributes] TO [public]
GO
GRANT UPDATE ON  [dbo].[mbbmCubeDimAttributes] TO [public]
GO
