IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\djaramillo')
CREATE LOGIN [CVOPTICAL\djaramillo] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\djaramillo] FOR LOGIN [CVOPTICAL\djaramillo] WITH DEFAULT_SCHEMA=[CVOPTICAL\djaramillo]
GO
