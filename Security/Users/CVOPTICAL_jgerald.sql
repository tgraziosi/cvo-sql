IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\jgerald')
CREATE LOGIN [CVOPTICAL\jgerald] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\jgerald] FOR LOGIN [CVOPTICAL\jgerald] WITH DEFAULT_SCHEMA=[CVOPTICAL\jgerald]
GO
