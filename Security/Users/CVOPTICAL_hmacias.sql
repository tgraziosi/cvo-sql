IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\hmacias')
CREATE LOGIN [CVOPTICAL\hmacias] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\hmacias] FOR LOGIN [CVOPTICAL\hmacias] WITH DEFAULT_SCHEMA=[CVOPTICAL\hmacias]
GO