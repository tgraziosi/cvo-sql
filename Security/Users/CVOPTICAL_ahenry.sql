IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\ahenry')
CREATE LOGIN [CVOPTICAL\ahenry] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\ahenry] FOR LOGIN [CVOPTICAL\ahenry] WITH DEFAULT_SCHEMA=[CVOPTICAL\ahenry]
GO
