IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\akahen')
CREATE LOGIN [CVOPTICAL\akahen] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\akahen] FOR LOGIN [CVOPTICAL\akahen] WITH DEFAULT_SCHEMA=[CVOPTICAL\akahen]
GO
