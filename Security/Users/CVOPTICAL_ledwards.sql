IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\ledwards')
CREATE LOGIN [CVOPTICAL\ledwards] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\ledwards] FOR LOGIN [CVOPTICAL\ledwards] WITH DEFAULT_SCHEMA=[CVOPTICAL\ledwards]
GO
