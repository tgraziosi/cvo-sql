IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\csquillante')
CREATE LOGIN [CVOPTICAL\csquillante] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\csquillante] FOR LOGIN [CVOPTICAL\csquillante] WITH DEFAULT_SCHEMA=[CVOPTICAL\csquillante]
GO
