IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\mherrera')
CREATE LOGIN [CVOPTICAL\mherrera] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\mherrera] FOR LOGIN [CVOPTICAL\mherrera] WITH DEFAULT_SCHEMA=[CVOPTICAL\mherrera]
GO
