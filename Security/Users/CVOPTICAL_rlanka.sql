IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\rlanka')
CREATE LOGIN [CVOPTICAL\rlanka] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\rlanka] FOR LOGIN [CVOPTICAL\rlanka] WITH DEFAULT_SCHEMA=[CVOPTICAL\rlanka]
GO
