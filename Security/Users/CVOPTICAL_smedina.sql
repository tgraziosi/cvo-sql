IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\smedina')
CREATE LOGIN [CVOPTICAL\smedina] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\smedina] FOR LOGIN [CVOPTICAL\smedina] WITH DEFAULT_SCHEMA=[CVOPTICAL\smedina]
GO
