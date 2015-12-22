CREATE TABLE [dbo].[mbbmVer]
(
[TimeStamp] [timestamp] NOT NULL,
[Major] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Minor] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SheetVersion] [int] NOT NULL,
[SPRevision] [int] NOT NULL,
[GLVersion] [float] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[mbbmVer] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmVer] TO [Analytics]
GO
GRANT INSERT ON  [dbo].[mbbmVer] TO [Analytics]
GO
GRANT DELETE ON  [dbo].[mbbmVer] TO [Analytics]
GO
GRANT UPDATE ON  [dbo].[mbbmVer] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmVer] TO [public]
GO
GRANT INSERT ON  [dbo].[mbbmVer] TO [public]
GO
GRANT DELETE ON  [dbo].[mbbmVer] TO [public]
GO
GRANT UPDATE ON  [dbo].[mbbmVer] TO [public]
GO
