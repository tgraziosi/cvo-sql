IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\lpinto')
CREATE LOGIN [CVOPTICAL\lpinto] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\lpinto] FOR LOGIN [CVOPTICAL\lpinto] WITH DEFAULT_SCHEMA=[CVOPTICAL\lpinto]
GO