IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\lmagnano')
CREATE LOGIN [CVOPTICAL\lmagnano] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\lmagnano] FOR LOGIN [CVOPTICAL\lmagnano] WITH DEFAULT_SCHEMA=[CVOPTICAL\lmagnano]
GO
