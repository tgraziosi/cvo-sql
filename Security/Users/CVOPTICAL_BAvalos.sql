IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\BAvalos')
CREATE LOGIN [CVOPTICAL\BAvalos] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\BAvalos] FOR LOGIN [CVOPTICAL\BAvalos] WITH DEFAULT_SCHEMA=[CVOPTICAL\BAvalos]
GO
