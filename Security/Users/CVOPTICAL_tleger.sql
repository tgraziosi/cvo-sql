IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\tleger')
CREATE LOGIN [CVOPTICAL\tleger] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\tleger] FOR LOGIN [CVOPTICAL\tleger] WITH DEFAULT_SCHEMA=[CVOPTICAL\tleger]
GO
