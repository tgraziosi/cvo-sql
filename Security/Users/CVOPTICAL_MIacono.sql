IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\MIacono')
CREATE LOGIN [CVOPTICAL\MIacono] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\MIacono] FOR LOGIN [CVOPTICAL\MIacono] WITH DEFAULT_SCHEMA=[CVOPTICAL\MIacono]
GO
