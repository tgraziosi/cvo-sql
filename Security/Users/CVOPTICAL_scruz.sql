IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\scruz')
CREATE LOGIN [CVOPTICAL\scruz] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\scruz] FOR LOGIN [CVOPTICAL\scruz] WITH DEFAULT_SCHEMA=[CVOPTICAL\scruz]
GO
