IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\blemay')
CREATE LOGIN [CVOPTICAL\blemay] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\blemay] FOR LOGIN [CVOPTICAL\blemay] WITH DEFAULT_SCHEMA=[CVOPTICAL\blemay]
GO
