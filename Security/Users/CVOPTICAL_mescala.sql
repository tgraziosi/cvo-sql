IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\mescala')
CREATE LOGIN [CVOPTICAL\mescala] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\mescala] FOR LOGIN [CVOPTICAL\mescala] WITH DEFAULT_SCHEMA=[CVOPTICAL\mescala]
GO