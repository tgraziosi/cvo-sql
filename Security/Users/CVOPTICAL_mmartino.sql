IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\mmartino')
CREATE LOGIN [CVOPTICAL\mmartino] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\mmartino] FOR LOGIN [CVOPTICAL\mmartino] WITH DEFAULT_SCHEMA=[CVOPTICAL\mmartino]
GO
