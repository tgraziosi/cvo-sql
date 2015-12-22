IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\slachenmeyer')
CREATE LOGIN [CVOPTICAL\slachenmeyer] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\slachenmeyer] FOR LOGIN [CVOPTICAL\slachenmeyer] WITH DEFAULT_SCHEMA=[CVOPTICAL\slachenmeyer]
GO
