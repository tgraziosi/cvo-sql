IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\CKaye')
CREATE LOGIN [CVOPTICAL\CKaye] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\ckaye] FOR LOGIN [CVOPTICAL\CKaye] WITH DEFAULT_SCHEMA=[CVOPTICAL\ckaye]
GO
