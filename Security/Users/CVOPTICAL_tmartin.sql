IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\tmartin')
CREATE LOGIN [CVOPTICAL\tmartin] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\tmartin] FOR LOGIN [CVOPTICAL\tmartin] WITH DEFAULT_SCHEMA=[CVOPTICAL\tmartin]
GO
