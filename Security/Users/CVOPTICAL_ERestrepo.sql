IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\ERestrepo')
CREATE LOGIN [CVOPTICAL\ERestrepo] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\ERestrepo] FOR LOGIN [CVOPTICAL\ERestrepo] WITH DEFAULT_SCHEMA=[CVOPTICAL\ERestrepo]
GO
