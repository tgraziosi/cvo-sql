IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\ghayes')
CREATE LOGIN [CVOPTICAL\ghayes] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\ghayes] FOR LOGIN [CVOPTICAL\ghayes] WITH DEFAULT_SCHEMA=[CVOPTICAL\ghayes]
GO