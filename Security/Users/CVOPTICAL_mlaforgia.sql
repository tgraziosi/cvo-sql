IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\mlaforgia')
CREATE LOGIN [CVOPTICAL\mlaforgia] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\mlaforgia] FOR LOGIN [CVOPTICAL\mlaforgia] WITH DEFAULT_SCHEMA=[CVOPTICAL\mlaforgia]
GO