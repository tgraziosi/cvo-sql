IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\BLitzky')
CREATE LOGIN [CVOPTICAL\BLitzky] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\BLitzky] FOR LOGIN [CVOPTICAL\BLitzky] WITH DEFAULT_SCHEMA=[CVOPTICAL\BLitzky]
GO