IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\nmaldarella')
CREATE LOGIN [CVOPTICAL\nmaldarella] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\nmaldarella] FOR LOGIN [CVOPTICAL\nmaldarella] WITH DEFAULT_SCHEMA=[CVOPTICAL\nmaldarella]
GO
