IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\javalos')
CREATE LOGIN [CVOPTICAL\javalos] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\javalos] FOR LOGIN [CVOPTICAL\javalos] WITH DEFAULT_SCHEMA=[CVOPTICAL\javalos]
GO
