IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'CVOPTICAL\ESzczerba')
CREATE LOGIN [CVOPTICAL\ESzczerba] FROM WINDOWS
GO
CREATE USER [CVOPTICAL\ESzczerba] FOR LOGIN [CVOPTICAL\ESzczerba] WITH DEFAULT_SCHEMA=[CVOPTICAL\ESzczerba]
GO