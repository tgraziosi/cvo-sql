IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\HCao')
CREATE LOGIN [CVOPTICAL\HCao] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\HCao] FOR LOGIN [CVOPTICAL\HCao] WITH DEFAULT_SCHEMA=[CVOPTICAL\HCao]
GO