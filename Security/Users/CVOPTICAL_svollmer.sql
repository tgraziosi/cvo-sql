IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\svollmer')
CREATE LOGIN [CVOPTICAL\svollmer] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\svollmer] FOR LOGIN [CVOPTICAL\svollmer] WITH DEFAULT_SCHEMA=[CVOPTICAL\svollmer]
GO
