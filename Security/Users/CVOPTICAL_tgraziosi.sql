IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\tgraziosi')
CREATE LOGIN [CVOPTICAL\tgraziosi] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\tgraziosi] FOR LOGIN [CVOPTICAL\tgraziosi] WITH DEFAULT_SCHEMA=[CVOPTICAL\tgraziosi]
GO