IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\LCieri')
CREATE LOGIN [CVOPTICAL\LCieri] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\LCieri] FOR LOGIN [CVOPTICAL\LCieri] WITH DEFAULT_SCHEMA=[CVOPTICAL\LCieri]
GO
