IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\DKoulermos')
CREATE LOGIN [CVOPTICAL\DKoulermos] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\DKoulermos] FOR LOGIN [CVOPTICAL\DKoulermos] WITH DEFAULT_SCHEMA=[CVOPTICAL\DKoulermos]
GO