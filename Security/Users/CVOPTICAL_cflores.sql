IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\cflores')
CREATE LOGIN [CVOPTICAL\cflores] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\cflores] FOR LOGIN [CVOPTICAL\cflores] WITH DEFAULT_SCHEMA=[CVOPTICAL\cflores]
GO
