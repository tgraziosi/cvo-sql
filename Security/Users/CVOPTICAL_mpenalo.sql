IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\mpenalo')
CREATE LOGIN [CVOPTICAL\mpenalo] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\mpenalo] FOR LOGIN [CVOPTICAL\mpenalo] WITH DEFAULT_SCHEMA=[CVOPTICAL\mpenalo]
GO
