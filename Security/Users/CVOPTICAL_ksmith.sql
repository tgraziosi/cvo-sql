IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\ksmith')
CREATE LOGIN [CVOPTICAL\ksmith] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\ksmith] FOR LOGIN [CVOPTICAL\ksmith] WITH DEFAULT_SCHEMA=[CVOPTICAL\ksmith]
GO
