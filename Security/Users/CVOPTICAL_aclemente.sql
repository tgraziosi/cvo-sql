IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\aclemente')
CREATE LOGIN [CVOPTICAL\aclemente] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\aclemente] FOR LOGIN [CVOPTICAL\aclemente] WITH DEFAULT_SCHEMA=[CVOPTICAL\aclemente]
GO
