IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\gmileva')
CREATE LOGIN [CVOPTICAL\gmileva] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\gmileva] FOR LOGIN [CVOPTICAL\gmileva] WITH DEFAULT_SCHEMA=[CVOPTICAL\gmileva]
GO
