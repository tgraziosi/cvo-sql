IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\dcotto')
CREATE LOGIN [CVOPTICAL\dcotto] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\dcotto] FOR LOGIN [CVOPTICAL\dcotto] WITH DEFAULT_SCHEMA=[CVOPTICAL\dcotto]
GO
