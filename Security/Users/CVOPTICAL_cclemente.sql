IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\cclemente')
CREATE LOGIN [CVOPTICAL\cclemente] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\cclemente] FOR LOGIN [CVOPTICAL\cclemente] WITH DEFAULT_SCHEMA=[CVOPTICAL\cclemente]
GO
