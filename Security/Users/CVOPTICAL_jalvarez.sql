IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\jalvarez')
CREATE LOGIN [CVOPTICAL\jalvarez] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\jalvarez] FOR LOGIN [CVOPTICAL\jalvarez] WITH DEFAULT_SCHEMA=[CVOPTICAL\jalvarez]
GO
