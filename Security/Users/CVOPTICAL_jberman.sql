IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\jberman')
CREATE LOGIN [CVOPTICAL\jberman] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\jberman] FOR LOGIN [CVOPTICAL\jberman] WITH DEFAULT_SCHEMA=[CVOPTICAL\jberman]
GO
