IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\ntrinh')
CREATE LOGIN [CVOPTICAL\ntrinh] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\ntrinh] FOR LOGIN [CVOPTICAL\ntrinh] WITH DEFAULT_SCHEMA=[CVOPTICAL\ntrinh]
GO
