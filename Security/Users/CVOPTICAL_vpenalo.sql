IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\vpenalo')
CREATE LOGIN [CVOPTICAL\vpenalo] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\vpenalo] FOR LOGIN [CVOPTICAL\vpenalo] WITH DEFAULT_SCHEMA=[CVOPTICAL\vpenalo]
GO
