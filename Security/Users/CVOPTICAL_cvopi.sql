IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\cvopi')
CREATE LOGIN [CVOPTICAL\cvopi] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\cvopi] FOR LOGIN [CVOPTICAL\cvopi] WITH DEFAULT_SCHEMA=[CVOPTICAL\cvopi]
GO