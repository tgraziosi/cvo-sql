IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\lpaccione')
CREATE LOGIN [CVOPTICAL\lpaccione] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\lpaccione] FOR LOGIN [CVOPTICAL\lpaccione] WITH DEFAULT_SCHEMA=[CVOPTICAL\lpaccione]
GO
