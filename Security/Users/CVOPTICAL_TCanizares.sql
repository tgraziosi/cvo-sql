IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\TCanizares')
CREATE LOGIN [CVOPTICAL\TCanizares] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\TCanizares] FOR LOGIN [CVOPTICAL\TCanizares] WITH DEFAULT_SCHEMA=[CVOPTICAL\TCanizares]
GO
