IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\mbarney')
CREATE LOGIN [CVOPTICAL\mbarney] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\mbarney] FOR LOGIN [CVOPTICAL\mbarney] WITH DEFAULT_SCHEMA=[CVOPTICAL\mbarney]
GO