IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\epitest3')
CREATE LOGIN [CVOPTICAL\epitest3] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\epitest3] FOR LOGIN [CVOPTICAL\epitest3] WITH DEFAULT_SCHEMA=[CVOPTICAL\epitest3]
GO
