IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\bkellam')
CREATE LOGIN [CVOPTICAL\bkellam] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\bkellam] FOR LOGIN [CVOPTICAL\bkellam] WITH DEFAULT_SCHEMA=[CVOPTICAL\bkellam]
GO
