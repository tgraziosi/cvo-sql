IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\epitest7')
CREATE LOGIN [CVOPTICAL\epitest7] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\epitest7] FOR LOGIN [CVOPTICAL\epitest7] WITH DEFAULT_SCHEMA=[CVOPTICAL\epitest7]
GO
