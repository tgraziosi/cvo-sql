IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\ikashtelyan')
CREATE LOGIN [CVOPTICAL\ikashtelyan] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\ikashtelyan] FOR LOGIN [CVOPTICAL\ikashtelyan] WITH DEFAULT_SCHEMA=[CVOPTICAL\ikashtelyan]
GO
